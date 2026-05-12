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

final class PTCustomHTTPProtocol: URLProtocol {
    private static let requestProperty = "com.custom.http.protocol"
    static var classDelegate: PTCustomHTTPProtocolDelegate?

    class func clearCache() {
        URLCache.customHttp.removeAllCachedResponses()
    }

    class func start() {
        URLProtocol.registerClass(self)
    }

    class func stop() {
        URLProtocol.unregisterClass(self)
    }

    // 核心判定：是否拦截处理该请求
    private class func canServeRequest(_ request: URLRequest) -> Bool {
        // 🌟 防死锁机制：如果已经被我们标记过，说明是底层转发请求，直接放行，避免无限递归
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

    private var delegate: PTCustomHTTPProtocolDelegate? { PTCustomHTTPProtocol.classDelegate }

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

    // 引入第一步重构的线程调度器
    private var threadOperator: PTThreadOperator?

    // 命中自定义缓存时的直连分发逻辑
    private func use(_ cache: CachedURLResponse) {
        delegate?.customHTTPProtocol(self, didReceive: cache.response)
        client?.urlProtocol(self, didReceive: cache.response, cacheStoragePolicy: .allowed)

        delegate?.customHTTPProtocol(self, didReceive: cache.data)
        client?.urlProtocol(self, didLoad: cache.data)

        delegate?.customHTTPProtocolDidFinishLoading(self)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func startLoading() {
        guard let newRequest = (request as NSObject).mutableCopy() as? NSMutableURLRequest else {
            fatalError("Can not convert to NSMutableURLRequest")
        }
        PTNetworkSpeedMonitor.shared.addUploadSpeed(0)
        URLProtocol.setProperty(true, forKey: PTCustomHTTPProtocol.requestProperty, in: newRequest)

        // 🌟 1. 优先校验静态资源持久化大文件缓存
        if let cache = URLCache.customHttp.validCache(for: request) {
            use(cache)
            PTNSLogConsole("Use disk cache for \(request.url?.lastPathComponent ?? "")")
            return
        }
        
        // 🌟 2. 桥接打通业务网络模块的 Actor 内存/磁盘缓存！
        // 检查业务层请求头是否允许使用缓存
        let cachePolicyRaw = request.allHTTPHeaderFields?["cachePolicy"] ?? ""
        if cachePolicyRaw == PTNetworkCachePolicy.cacheOnly.rawValue ||
           cachePolicyRaw == PTNetworkCachePolicy.cacheElseNetwork.rawValue {
            
            // 跨 Actor 安全读取业务层缓存
            let originalRequest = request
            // 避免阻塞当前线程发起，利用信号量或 Task 快速读取
            var hitBusinessCacheData: Data?
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                hitBusinessCacheData = await NetworkCache.shared.read(request: originalRequest)
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: .now() + 0.05) // 50ms 极速等待内存击穿
            
            if let data = hitBusinessCacheData {
                // 构造合规的本地虚拟成功响应返回给上层 Alamofire
                let fakeResponse = HTTPURLResponse(url: originalRequest.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: originalRequest.allHTTPHeaderFields)!
                let cachedResp = CachedURLResponse(response: fakeResponse, data: data)
                use(cachedResp)
                PTNSLogConsole("Use Business API Cache for \(originalRequest.url?.path ?? "")")
                return
            }
        }

        // 实例化调度器，捕获当前线程上下文
        threadOperator = PTThreadOperator()
        startTime = Date()
        prevUrl = request.url
        prevStartTime = startTime
        
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        dataTask = session?.dataTask(with: newRequest as URLRequest)
        dataTask?.resume()
    }

    override func stopLoading() {
        dataTask?.cancel()
        if let task = dataTask {
            task.cancel()
            dataTask = nil
        }

        guard PTNetworkHelper.shared.isNetworkEnable else { return }

        // 🌟 接入第二步重构的模型实体
        let model = PTHttpModel()
        model.url = request.url
        model.method = request.httpMethod
        model.mimeType = response?.mimeType // 使用修正后的标准字段

        if let requestBody = request.httpBody {
            model.requestData = requestBody
        } else if let requestBodyStream = request.httpBodyStream {
            // 兼容宿主应用内部定义的 Input Stream 读取扩展
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
            // 兼容项目内置的字典键转换扩展
            model.responseHeaderFields = response.allHeaderFields.convertKeysToString()
            model.responseHeaderFields?.updateValue(getCachePolicy(value: request.cachePolicy.rawValue), forKey: "Cache-Policy")
        }

        if let responseDate = model.endTime {
            model.responseHeaderFields?.updateValue(responseDate, forKey: "Response-Date")
        }

        // 图片二次校验策略
        if let urlString = model.url?.absoluteString {
            let lowercasedURL = urlString.lowercased()
            if ["png", "jpg", "gif", "jpeg"].contains(where: { lowercasedURL.hasSuffix(".\($0)") }) {
                model.isImage = true
            }
        }

        model.requestId = request.requestId
        
        // 🌟 接入第二步重构的语义化错误清洗器
        let finalModel = PTErrorHelper.handle(error, model: model)
        
        // 🌟 接入第三步重构的线程安全池，存入数据并发送局部刷新通知
        if PTHttpDatasource.shared.addHttpRequest(finalModel) {
            NotificationCenter.default.post(name: NSNotification.Name("reloadHttp_PooTools"), object: finalModel.isSuccess)
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
extension PTCustomHTTPProtocol: URLSessionDataDelegate {
    
    func urlSession(_: URLSession, task _: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        threadOperator?.execute { [weak self] in
            guard let self = self else { return }
            PTNSLogConsole("willPerformHTTPRedirection")
            self.client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
            self.response = response
            completionHandler(request)
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
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
                guard elapsedTime > 0 else { return }
                
                if let requestBody = dataTask.currentRequest?.httpBody {
                    let uploadSpeed = Double(requestBody.count) / elapsedTime
                    PTNetworkSpeedMonitor.shared.addUploadSpeed(uploadSpeed)
                } else if let urlString = dataTask.currentRequest?.url?.absoluteString,
                          let stringData = urlString.data(using: .utf8) {
                    let uploadSpeed = Double(stringData.count) / elapsedTime
                    PTNetworkSpeedMonitor.shared.addUploadSpeed(uploadSpeed)
                }
            }
            completionHandler(.allow)
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
            // 测速模块下行速度统计 (安全接入第一步重构的读写隔离方法)
            if let safeEndTime = self.endTime {
                let elapsedTime = safeEndTime.timeIntervalSince(self.startTime)
                if elapsedTime > 0 {
                    let downloadSpeed = Double(data.count) / elapsedTime
                    PTNetworkSpeedMonitor.shared.addDownloadSpeed(downloadSpeed)
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
                // 🌟 终极修复：使用重构后线程安全的测速数据重置接口，抛弃旧的强制清空数组写法
                PTNetworkSpeedMonitor.shared.clearSpeeds()
                
                // 按需写入本地自定义持久化磁盘缓存
                URLCache.customHttp.storeIfNeeded(for: task, data: self.data)
            }
        }
    }
}

public class PTNetworkSpeedMonitor {
    
    public static let shared = PTNetworkSpeedMonitor()
    
    // 底层真实数据源改为私有属性，避免外部直接操作引发非线程安全问题
    private var _downloadSpeeds: [Double] = []
    private var _uploadSpeeds: [Double] = []
    
    // 核心保护锁：创建一个自定义并发队列用于隔离多线程读写操作
    private let isolationQueue = DispatchQueue(
        label: "com.custom.http.speedMonitorQueue",
        attributes: .concurrent
    )
    
    private init() {}
    
    /// 获取当前下载速度记录（线程安全读取）
    public var downloadSpeeds: [Double] {
        isolationQueue.sync { _downloadSpeeds }
    }
    
    /// 获取当前上传速度记录（线程安全读取）
    public var uploadSpeeds: [Double] {
        isolationQueue.sync { _uploadSpeeds }
    }
    
    /// 记录当前瞬时下载速度（线程安全写入）
    public func addDownloadSpeed(_ speed: Double) {
        // 使用 barrier 标志确保写入操作独占队列，杜绝数据竞争
        isolationQueue.async(flags: .barrier) {
            self._downloadSpeeds.append(speed)
        }
    }
    
    /// 记录当前瞬时上传速度（线程安全写入）
    public func addUploadSpeed(_ speed: Double) {
        isolationQueue.async(flags: .barrier) {
            self._uploadSpeeds.append(speed)
        }
    }
    
    /// 计算平均下载速度（线程安全读取计算）
    public func averageDownloadSpeed() -> Double {
        isolationQueue.sync {
            guard !_downloadSpeeds.isEmpty else { return 0.0 }
            return _downloadSpeeds.reduce(0, +) / Double(_downloadSpeeds.count)
        }
    }
    
    /// 计算平均上传速度（线程安全读取计算）
    public func averageUploadSpeed() -> Double {
        isolationQueue.sync {
            guard !_uploadSpeeds.isEmpty else { return 0.0 }
            return _uploadSpeeds.reduce(0, +) / Double(_uploadSpeeds.count)
        }
    }
    
    /// 清理所有测速缓存数据（线程安全重置）
    public func clearSpeeds() {
        isolationQueue.async(flags: .barrier) {
            self._downloadSpeeds.removeAll()
            // 默认保留一个初始值 0，兼容原底层协议启动逻辑
            self._downloadSpeeds.append(0)
            
            self._uploadSpeeds.removeAll()
            self._uploadSpeeds.append(0)
        }
    }
}
