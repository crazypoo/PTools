//
//  PTCustomHTTPProtocol.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import SwiftDate

protocol PTCustomHTTPProtocolDelegate: AnyObject {
    func customHTTPProtocol(_ proto: PTCustomHTTPProtocol, didReceive response: URLResponse)
    func customHTTPProtocol(_ proto: PTCustomHTTPProtocol, didReceive data: Data)
    func customHTTPProtocolDidFinishLoading(_ proto: PTCustomHTTPProtocol)
    func customHTTPProtocol(_ proto: PTCustomHTTPProtocol, didFailWithError error: Error)
}

final class PTCustomHTTPProtocol: URLProtocol, @unchecked Sendable {
    private static let requestProperty = "com.custom.http.protocol"
    nonisolated(unsafe) static var classDelegate: PTCustomHTTPProtocolDelegate?
    private var delegate: PTCustomHTTPProtocolDelegate? { PTCustomHTTPProtocol.classDelegate }
    
    struct UncheckedSendableBox<T>: @unchecked Sendable {
        let value: T
        
        init(_ value: T) {
            self.value = value
        }
    }
    
    class func clearCache() {
        URLCache.customHttp.removeAllCachedResponses()
    }

    class func start() {
        URLProtocol.registerClass(self)
    }

    class func stop() {
        URLProtocol.unregisterClass(self)
    }

    private class func checkNetworkEnableSynchronously() -> Bool {
        // 如果当前恰好已经在主线程，直接读取，避免死锁
        if Thread.isMainThread {
            // MainActor.assumeIsolated 是 Swift 6 提供的安全逃生舱口
            // 它告诉编译器：“我保证现在已经在主线程了，请允许我读取主线程数据”
            return MainActor.assumeIsolated {
                return PTNetworkHelper.shared.isNetworkEnable
            }
        } else {
            // 如果在后台网络线程，则同步派发到主线程去获取结果
            return DispatchQueue.main.sync {
                // 此时已经切换到了主线程，再次使用 assumeIsolated 放行编译器检查
                return MainActor.assumeIsolated {
                    return PTNetworkHelper.shared.isNetworkEnable
                }
            }
        }
    }

    private class func canServeRequest(_ request: URLRequest) -> Bool {
        guard checkNetworkEnableSynchronously() else { return false }
        if property(forKey: requestProperty, in: request) != nil { return false }

        if let scheme = request.url?.scheme?.lowercased(), scheme == "http" || scheme == "https" {
            return true
        }
        return false
    }

    override class func canInit(with request: URLRequest) -> Bool {
        canServeRequest(request)
    }

    override class func canInit(with task: URLSessionTask) -> Bool {
        guard let request = task.currentRequest else { return false }
        return canServeRequest(request)
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    // 状态属性（由于声明了 @unchecked Sendable，我们需要确保对其修改都在 threadOperator 内）
    private var session: URLSession?
    private var dataTask: URLSessionDataTask?
    private var cachePolicy: URLCache.StoragePolicy = .notAllowed
    private var data: Data = .init()
    private var didRetry = false
    private var didReceiveData = false
    private var startTime = Date()
    private var endTime: Date?
    private var response: HTTPURLResponse?
    private var error: Error?
    private var prevUrl: URL?
    private var prevStartTime: Date?

    private var threadOperator: PTThreadOperator?

    private func use(_ cache: CachedURLResponse) {
        // 1. 🌟 局部变量提取：在当前线程，把主线程回调需要用到的对象和数据提前剥离出来。
        // 因为 classDelegate 被标记为 nonisolated(unsafe)，在这里直接读取是完全合规的。
        let currentDelegate = PTCustomHTTPProtocol.classDelegate
        
        // 将引用类型的 proto 参数准备好，由于我们要传 self 过去，
        // 为了防止编译器在 MainActor 闭包里对 self 进行二次检查，我们使用之前写好的 UncheckedSendableBox 包装它。
        let protoBox = UncheckedSendableBox(self)
        let responseData = cache.data
        let urlResponse = cache.response
        
        // 2. 🌟 开启主线程任务：闭包内部“只认数据，不认 self”，完美绕过编译器的 Task-isolated 拦截。
        Task { @MainActor in
            // 安全解包提取出来的局部代理
            guard let delegate = currentDelegate else { return }
            
            // 从安全的盒子中拿出实例作为参数传给代理
            let safeProto = protoBox.value
            
            delegate.customHTTPProtocol(safeProto, didReceive: urlResponse)
            delegate.customHTTPProtocol(safeProto, didReceive: responseData)
            delegate.customHTTPProtocolDidFinishLoading(safeProto)
        }
        
        // 3. 底层系统的 client 回调留在当前非隔离线程直接同步执行
        client?.urlProtocol(self, didReceive: cache.response, cacheStoragePolicy: .allowed)
        client?.urlProtocol(self, didLoad: cache.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func startLoading() {
        guard let mutableRequest = (request as NSObject).mutableCopy() as? NSMutableURLRequest else {
            fatalError("Can not convert to NSMutableURLRequest")
        }
        
        URLProtocol.setProperty(true, forKey: PTCustomHTTPProtocol.requestProperty, in: mutableRequest)
        
        // 🌟 设计思路：在进入 Task 之前，将可变的非 Sendable 类型转换为不可变的、线程安全的结构体值类型
        let safeRequestToLaunch = mutableRequest as URLRequest
        
        Task { await PTNetworkSpeedMonitor.shared.addUploadSpeed(0) }

        // 1. 优先校验静态资源持久化大文件缓存
        if let cache = URLCache.customHttp.validCache(for: request) {
            use(cache)
            PTNSLogConsole("Use disk cache for \(request.url?.lastPathComponent ?? "")")
            return
        }
        
        // 2. 桥接打通业务网络模块的 Actor 内存/磁盘缓存
        let cachePolicyRaw = request.allHTTPHeaderFields?["cachePolicy"] ?? ""
        if cachePolicyRaw == PTNetworkCachePolicy.cacheOnly.rawValue ||
           cachePolicyRaw == PTNetworkCachePolicy.cacheElseNetwork.rawValue {
            
            let originalRequest = request
            
            // 🌟 核心修复：使用你之前定义的 UncheckedSendableBox 将非 Sendable 的 self 包装起来
            let selfBox = UncheckedSendableBox(self)
            
            // 异步等待读取 Actor 缓存（跨边界读取数据天然安全）
            Task { @MainActor in
                if let hitBusinessCacheData = await NetworkCache.shared.read(request: originalRequest) {
                    let fakeResponse = HTTPURLResponse(url: originalRequest.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: originalRequest.allHTTPHeaderFields)!
                    let cachedResp = CachedURLResponse(response: fakeResponse, data: hitBusinessCacheData)
                    
                    // 🌟 在 MainActor 保护下，从盒子中取出 self 安全调用内部方法
                    selfBox.value.use(cachedResp)
                    PTNSLogConsole("Use Business API Cache for \(originalRequest.url?.path ?? "")")
                } else {
                    // 🌟 同样从盒子中取出 self 发起实际网络请求
                    selfBox.value.startActualNetworkRequest(with: safeRequestToLaunch)
                }
            }
        } else {
            startActualNetworkRequest(with: safeRequestToLaunch)
        }
    }

    // 🌟 Swift 6 升级: 提取原本在 startLoading 尾部的实际网络请求逻辑
    private func startActualNetworkRequest(with request: URLRequest) {
        threadOperator = PTThreadOperator()
        startTime = Date()
        prevUrl = request.url
        prevStartTime = startTime
        
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        dataTask = session?.dataTask(with: request)
        dataTask?.resume()
    }
    
    override func stopLoading() {
        // 🌟 核心重构：整个生命周期方法在当前线程同步执行，完全不套用任何外层 Task
        dataTask?.cancel()
        if let task = dataTask {
            task.cancel()
            dataTask = nil
        }

        guard PTCustomHTTPProtocol.checkNetworkEnableSynchronously() else { return }

        // 🌟 在当前线程同步组装数据，直接读取属性，完全没有“闭包捕获 self”的场景，天然安全
        let model = PTHttpModel()
        model.url = request.url
        model.method = request.httpMethod
        model.mimeType = response?.mimeType

        if let requestBody = request.httpBody {
            model.requestData = requestBody
        } else if let requestBodyStream = request.httpBodyStream {
            model.requestData = requestBodyStream.toData()
        }

        if let httpResponse = response {
            model.statusCode = "\(httpResponse.statusCode)"
        }

        model.responseData = data
        model.size = data.formattedSize()
        model.isImage = (response?.mimeType?.contains("image")) ?? false

        // 耗时精准计算
        let startTimeDouble = startTime.timeIntervalSince1970
        let endTimeDouble = Date().timeIntervalSince1970
        let durationDouble = abs(endTimeDouble - startTimeDouble)
        model.totalDuration = String(format: "%.4f (s)", durationDouble)

        model.startTime = startTime.dateFormat(formatString: "yyyy-MM-dd HH:mm:ss")
        model.endTime = Date().dateFormat(formatString: "yyyy-MM-dd HH:mm:ss")

        model.errorDescription = error?.localizedDescription
        model.errorLocalizedDescription = error?.localizedDescription
        model.requestHeaderFields = request.allHTTPHeaderFields

        if let response = response {
            model.responseHeaderFields = response.allHeaderFields.convertKeysToString()
            model.responseHeaderFields?.updateValue(getCachePolicy(value: request.cachePolicy.rawValue), forKey: "Cache-Policy")
        }

        if let responseDate = model.endTime {
            model.responseHeaderFields?.updateValue(responseDate, forKey: "Response-Date")
        }

        if let urlString = model.url?.absoluteString {
            let lowercasedURL = urlString.lowercased()
            if ["png", "jpg", "gif", "jpeg"].contains(where: { lowercasedURL.hasSuffix(".\($0)") }) {
                model.isImage = true
            }
        }

        model.requestId = request.requestId
        
        let finalModel = PTErrorHelper.handle(error, model: model)
        
        // 🌟 隔离提取法：将需要跨线程传递的干净数据单独提取为常量
        let modelToSave = finalModel
        let isSuccess = finalModel.isSuccess
        
        // 🌟 仅仅将最后的存储与通知放入 Task，闭包里没有任何一个地方用到 self
        Task { @MainActor in
            if PTHttpDatasource.shared.addHttpRequest(modelToSave) {
                // 通知刷新 UI，安全的切回到 MainActor
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("reloadHttp_PooTools"), object: isSuccess)
                }
            }
        }
    }

    private func getCachePolicy(value: UInt?) -> String {
        switch value {
        case 0: return "useProtocolCachePolicy"
        case 1: return "reloadIgnoringLocalCacheData"
        case 2: return "returnCacheDataElseLoad"
        case 3: return "returnCacheDataDontLoad"
        case 4: return "reloadIgnoringLocalAndRemoteCacheData"
        case 5: return "reloadRevalidatingCacheData"
        default: return "reloadIgnoringCacheData"
        }
    }

    private func canRetry(error: NSError) -> Bool {
        guard error.code == Int(CFNetworkErrors.cfurlErrorNetworkConnectionLost.rawValue),
              !didRetry,
              !didReceiveData else {
            return false
        }
        PTNSLogConsole("Retry download...")
        return true
    }
}

// MARK: - URLSessionDataDelegate 代理实现 (依赖调度器切回目标线程)
// MARK: - URLSessionDataDelegate 代理实现 (修复 Actor 并发调用)
extension PTCustomHTTPProtocol: URLSessionDataDelegate {
    
    func urlSession(_: URLSession, task _: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        let handlerBox = UncheckedSendableBox(completionHandler)
        threadOperator?.execute { [weak self] in
            guard let self = self else { return }
            PTNSLogConsole("willPerformHTTPRedirection")
            self.client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
            self.response = response
            handlerBox.value(request)
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        let handlerBox = UncheckedSendableBox(completionHandler)
        threadOperator?.execute { [weak self] in
            guard let self = self else { return }
            
            if let httpResponse = response as? HTTPURLResponse, let originalRequest = dataTask.originalRequest {
                // 接入刚重构的合规缓存判决类
                self.cachePolicy = PTCacheStoragePolicy.cacheStoragePolicy(for: originalRequest, and: httpResponse)
            }
            
            self.delegate?.customHTTPProtocol(self, didReceive: response)
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: self.cachePolicy)
            self.response = response as? HTTPURLResponse
            self.endTime = Date()
                        
            // 测速模块上行速度统计 (安全解包)
            if let safeEndTime = self.endTime {
                let elapsedTime = safeEndTime.timeIntervalSince(self.startTime)
                guard elapsedTime > 0 else {
                    handlerBox.value(.allow)
                    return
                }
                
                // 🌟 修复：用 Task 包装 Actor 的方法调用
                if let requestBody = dataTask.currentRequest?.httpBody {
                    let uploadSpeed = Double(requestBody.count) / elapsedTime
                    Task { await PTNetworkSpeedMonitor.shared.addUploadSpeed(uploadSpeed) }
                } else if let urlString = dataTask.currentRequest?.url?.absoluteString,
                          let stringData = urlString.data(using: .utf8) {
                    let uploadSpeed = Double(stringData.count) / elapsedTime
                    Task { await PTNetworkSpeedMonitor.shared.addUploadSpeed(uploadSpeed) }
                }
            }
            handlerBox.value(.allow)
        }
    }

    func urlSession(_ session: URLSession, dataTask task: URLSessionDataTask, didReceive data: Data) {
        threadOperator?.execute { [weak self] in
            guard let self = self else { return }

            var hasAddedData = false
            if self.cachePolicy == .allowed {
                self.data.append(data)
                hasAddedData = true
            }

            self.delegate?.customHTTPProtocol(self, didReceive: data)

            self.client?.urlProtocol(self, didLoad: data)
            self.didReceiveData = true
            
            if self.prevUrl == self.response?.url, self.prevStartTime == self.startTime {
                if !hasAddedData { self.data.append(data) }
            } else {
                self.data = data
            }
            
            self.endTime = Date()
            
            // 测速模块下行速度统计
            if let safeEndTime = self.endTime {
                let elapsedTime = safeEndTime.timeIntervalSince(self.startTime)
                if elapsedTime > 0 {
                    let downloadSpeed = Double(data.count) / elapsedTime
                    // 🌟 修复：用 Task 包装 Actor 的方法调用
                    Task { await PTNetworkSpeedMonitor.shared.addDownloadSpeed(downloadSpeed) }
                }
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        threadOperator?.execute { [weak self] in
            guard let self = self else { return }
            
            if let error = error {
                self.error = error
                if self.canRetry(error: error as NSError), let originalRequest = task.originalRequest {
                    self.didRetry = true
                    self.dataTask = session.dataTask(with: originalRequest)
                    self.dataTask?.resume()
                    return
                }
                self.delegate?.customHTTPProtocol(self, didFailWithError: error)

                self.client?.urlProtocol(self, didFailWithError: error)
                return
            }

            self.delegate?.customHTTPProtocolDidFinishLoading(self)

            self.client?.urlProtocolDidFinishLoading(self)
            
            if self.cachePolicy == .allowed {
                // 🌟 修复：用 Task 包装 Actor 的清理方法调用
                Task { await PTNetworkSpeedMonitor.shared.clearSpeeds() }
                
                // 按需写入本地自定义持久化磁盘缓存
                URLCache.customHttp.storeIfNeeded(for: task, data: self.data)
            }
        }
    }
}

public actor PTNetworkSpeedMonitor {
    
    public static let shared = PTNetworkSpeedMonitor()
    
    // Actor 内部的属性天然是线程安全的，无需再加私有队列保护
    private var downloadSpeeds: [Double] = [0.0]
    private var uploadSpeeds: [Double] = [0.0]
    
    private init() {}
    
    /// 获取当前下载速度记录
    public func getDownloadSpeeds() -> [Double] {
        return downloadSpeeds
    }
    
    /// 获取当前上传速度记录
    public func getUploadSpeeds() -> [Double] {
        return uploadSpeeds
    }
    
    /// 记录当前瞬时下载速度
    public func addDownloadSpeed(_ speed: Double) {
        downloadSpeeds.append(speed)
    }
    
    /// 记录当前瞬时上传速度
    public func addUploadSpeed(_ speed: Double) {
        uploadSpeeds.append(speed)
    }
    
    /// 计算平均下载速度
    public func averageDownloadSpeed() -> Double {
        guard !downloadSpeeds.isEmpty else { return 0.0 }
        return downloadSpeeds.reduce(0, +) / Double(downloadSpeeds.count)
    }
    
    /// 计算平均上传速度
    public func averageUploadSpeed() -> Double {
        guard !uploadSpeeds.isEmpty else { return 0.0 }
        return uploadSpeeds.reduce(0, +) / Double(uploadSpeeds.count)
    }
    
    /// 清理所有测速缓存数据
    public func clearSpeeds() {
        downloadSpeeds.removeAll()
        downloadSpeeds.append(0) // 保留初始值
        
        uploadSpeeds.removeAll()
        uploadSpeeds.append(0)
    }
}
