//
//  Network.swift
//  MiniChatSwift
//
//  Created by 林勇彬 on 2022/5/21.
//  Copyright © 2022 九州所想. All rights reserved.
//

import UIKit
import Alamofire
import KakaJSON
import Network

public let NetWorkNoError = NSError(domain: "PT Network no network".localized(), code: 99999999996)
public let NetWorkJsonExplainError = NSError(domain: "PT Network json fail".localized(), code: 99999999998)
public let NetWorkModelExplainError = NSError(domain: "PT Network model fail".localized(), code: 99999999999)
public let NetWorkDownloadError = NSError(domain: "PT Network download fail".localized(), code: 99999999997)
public let NetWorkCheckIPError = NSError(domain: "IP address error", code: 99999999995)

public let AppTestMode = "PT App network environment test".localized()
public let AppCustomMode = "PT App network environment custom".localized()
public let AppDisMode = "PT App network environment distribution".localized()

public enum NetWorkStatus: Int {
    case unknown
    case notReachable
    case wwan
    case wifi
    case requiresConnection
    case wiredEthernet
    case loopback
    case other
    
    public static func valueName(type:NetWorkStatus) -> String {
        switch type {
        case .unknown:
            "PT App network status unknow".localized()
        case .notReachable:
            "PT App network status disconnect".localized()
        case .wwan:
            "2,3,4G,5G"
        case .wifi:
            "WIFI"
        case .requiresConnection:
            "RequiresConnection"
        case .wiredEthernet:
            "WiredEthernet"
        case .loopback:
            "loopback"
        case .other:
            "Other"
        }
    }
}

public enum NetWorkEnvironment: Int {
    case Development
    case Test
    case Distribution
    
    public static func valueName(type:NetWorkEnvironment) -> String {
        switch type {
        case .Development:
            "PT App network environment custom".localized()
        case .Test:
            "PT App network environment test".localized()
        case .Distribution:
            "PT App network environment distribution".localized()
        }
    }
}

public typealias NetWorkStatusBlock = (_ NetWorkStatus: String, _ NetWorkEnvironment: String,_ NetworkStatusType:NetworkReachabilityManager.NetworkReachabilityStatus) -> Void
public typealias UploadProgress = (_ progress: Progress) -> Void
public typealias FileDownloadProgress = (_ bytesRead:Int64,_ totalBytesRead:Int64,_ progress:Double)->()
public typealias FileDownloadSuccess = (_ reponse:AFDownloadResponse<Data>)->()
public typealias FileDownloadFail = (_ error:Error?)->()

public var PTBaseURLMode:NetWorkEnvironment {
    guard let sliderValue = PTCoreUserDefultsWrapper.AppServiceIdentifier else { return .Distribution }
    if sliderValue == "1" {
        return .Distribution
    } else if sliderValue == "2" {
        return .Test
    } else if sliderValue == "3" {
        return .Development
    }
    return .Distribution
}

public var PTSocketURLMode:NetWorkEnvironment {
    guard let sliderValue = PTCoreUserDefultsWrapper.AppSocketServiceIdentifier else { return .Distribution }
    if sliderValue == "1" {
        return .Distribution
    } else if sliderValue == "2" {
        return .Test
    } else if sliderValue == "3" {
        return .Development
    }
    return .Distribution
}

// MARK: - 网络运行状态监听
@objcMembers
public class PTNetWorkStatus {
    
    public static let shared = PTNetWorkStatus()
    /// 当前网络环境状态
    private var currentNetWorkStatus: NetWorkStatus = .wifi
    /// 当前运行环境状态
    private var currentEnvironment: NetWorkEnvironment = .Test
    
    private let monitor = NWPathMonitor()

    public var reachabilityManager = Alamofire.NetworkReachabilityManager(host: "www.google.com")
    
    private func detectNetWork(netWork: @escaping NetWorkStatusBlock) {
        reachabilityManager?.startListening(onUpdatePerforming: { [weak self] (status) in
            guard let weakSelf = self else { return }
            if self?.reachabilityManager?.isReachable ?? false {
                switch status {
                case .notReachable:
                    weakSelf.currentNetWorkStatus = .notReachable
                case .unknown:
                    weakSelf.currentNetWorkStatus = .unknown
                case .reachable(.cellular):
                    weakSelf.currentNetWorkStatus = .wwan
                case .reachable(.ethernetOrWiFi):
                    weakSelf.currentNetWorkStatus = .wifi
                }
            } else {
                weakSelf.currentNetWorkStatus = .notReachable
            }
            
            netWork(NetWorkStatus.valueName(type: weakSelf.currentNetWorkStatus), NetWorkEnvironment.valueName(type: weakSelf.currentEnvironment),status)
        })
    }
    
    ///监听网络运行状态
    public func obtainDataFromLocalWhenNetworkUnconnected(handle:((NetworkReachabilityManager.NetworkReachabilityStatus)->Void)?) {
        detectNetWork { (status, environment,statusType)  in
                        
            PTNSLogConsole(String(format: "PT App current mode".localized(), status,environment),levelType: PTLogMode,loggerType: .Network)

            handle?(statusType)
        }
    }
    
    public func netWork(handle: @escaping (_ status:NetWorkStatus)->Void) {
        PTGCDManager.gcdMain {
            self.monitor.pathUpdateHandler = { path in
                if path.status == .satisfied {
                    if path.usesInterfaceType(.wifi) {
                        handle(.wifi)
                    } else if path.usesInterfaceType(.cellular) {
                        handle(.wwan)
                    } else if path.usesInterfaceType(.wiredEthernet) {
                        handle(.wiredEthernet)
                    } else if path.usesInterfaceType(.loopback) {
                        handle(.loopback)
                    } else if path.usesInterfaceType(.other) {
                        handle(.other)
                    } else {
                        handle(.unknown)
                    }
                } else if path.status == .unsatisfied {
                    handle(.notReachable)
                } else if path.status == .requiresConnection {
                    handle(.requiresConnection)
                } else {
                    handle(.unknown)
                }
            }
            let queue = DispatchQueue.global(qos:.background)
            self.monitor.start(queue: queue)
        }
    }

    
    public func checkNetworkStatusCancel() {
        monitor.cancel()
    }
    
    deinit {
        checkNetworkStatusCancel()
    }
}

extension Error {
    var isNetworkError: Bool {
        if let afError = self as? AFError {
            switch afError {
            case .sessionTaskFailed(let underlyingError as NSError):
                return underlyingError.domain == NSURLErrorDomain
            default:
                return false
            }
        }
        return (self as NSError).domain == NSURLErrorDomain
    }
}

/// 自定義重連邏輯
fileprivate class RetryHandler: @unchecked Sendable ,RequestInterceptor {
    ///默認重連次數3
    let retryLimit = Network.share.retryTimes
    ///默認重連延遲1.5秒
    let retryDelay: TimeInterval = Network.share.retryDelay
    /*
     當服務器502時,或者DomainError時間,就觸發重連
     Network.share.retryAPIStatusCode == 502
     */
    
    public func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        let response = request.task?.response as? HTTPURLResponse
        if request.retryCount < retryLimit && (response?.statusCode == Network.share.retryAPIStatusCode || error.isNetworkError) {
            completion(.retryWithDelay(retryDelay))  // 延遲重連
        } else {
            completion(.doNotRetry)
        }
    }
}

@objcMembers
public class Network: NSObject {
    
    static public let share = Network()
            
    ///网络请求时间
    open var netRequsetTime:TimeInterval = 20
    open var serverAddress:String = ""
    open var serverAddress_dev:String = ""
    open var socketAddress:String = ""
    open var socketAddress_dev:String = ""
    open var userToken:String = ""
    open var retryTimes:Int = 3
    open var retryDelay:TimeInterval = 1.5
    open var retryAPIStatusCode:Int = 502

    open var fileUrl:String = ""
    open var saveFilePath:String = "" // 文件下载保存的路径
    open var cancelledData : Data?//用于停止下载时,保存已下载的部分
    open var downloadRequest:DownloadRequest? //下载请求对象
    open var destination:DownloadRequest.Destination!//下载文件的保存路径
    
    open var progress:FileDownloadProgress?
    open var success:FileDownloadSuccess?
    open var fail:FileDownloadFail?
    
    private var queue:DispatchQueue = DispatchQueue.main

    /// manager
    private static var manager: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Network.share.netRequsetTime
        return Session(configuration: configuration,interceptor: RetryHandler())
    }()
    
    open var hud:PTHudView?
    open var hudConfig : PTHudConfig {
        let hudConfig = PTHudConfig.share
        hudConfig.hudColors = [.gray,.gray]
        hudConfig.lineWidth = 4
        return hudConfig
    }
    
    func hudShow()  {
        PTGCDManager.gcdMain {
            let _ = Network.share.hudConfig
            if self.hud == nil {
                self.hud = PTHudView()
                self.hud!.hudShow()
            }
        }
    }
    
    func hudHide(completion:PTActionTask? = nil) {
        if self.hud != nil {
            self.hud!.hide {
                self.hud = nil
                completion?()
            }
        }
    }
        
    //MARK: 服务器URL
    public class func gobalUrl() -> String {
        if UIApplication.applicationEnvironment() != .appStore {
            PTNSLogConsole("PTBaseURLMode:\(PTBaseURLMode)",levelType: PTLogMode,loggerType: .Network)
            switch PTBaseURLMode {
            case .Development:
                let url_debug:String = PTCoreUserDefultsWrapper.AppRequestUrl
                if url_debug.isEmpty {
                    return Network.share.serverAddress_dev
                } else {
                    return url_debug
                }
            case .Test:
                return Network.share.serverAddress_dev
            case .Distribution:
                return Network.share.serverAddress
            }
        } else {
            return Network.share.serverAddress
        }
    }
    
    //MARK: socket服务器URL
    open class func socketGobalUrl() -> String {
        if UIApplication.applicationEnvironment() != .appStore {
            PTNSLogConsole("PTSocketURLMode:\(PTSocketURLMode)",levelType: PTLogMode,loggerType: .Network)
            switch PTSocketURLMode {
            case .Development:
                let url_debug:String = PTCoreUserDefultsWrapper.AppSocketUrl
                if url_debug.isEmpty {
                    return Network.share.socketAddress_dev
                } else {
                    return url_debug
                }
            case .Test:
                return Network.share.socketAddress_dev
            case .Distribution:
                return Network.share.socketAddress
            }
        } else {
            return Network.share.socketAddress
        }
    }
    
    class public func getIpAddress(url:String = "https://api.ipify.org") async throws -> String {
        var apiHeader = HTTPHeaders.init([:])
        apiHeader["Content-Type"] = "application/json;charset=UTF-8"
        apiHeader["Accept"] = "application/json"

        let model = try await Network.requestApi(needGobal:false,urlStr: url,method: .get,header: apiHeader)
        let ipAddress = String(data: model.resultData!, encoding: .utf8) ?? ""
        return ipAddress
    }
    
    class public func requestIPInfo(ipAddress:String,lang:OSSVoiceEnum = .ChineseSimplified) async throws -> PTIPInfoModel? {
        
        let urlStr1 = "http://ip-api.com/json/\(ipAddress)?lang=\(lang.rawValue)"
        var apiHeader = HTTPHeaders.init([:])
        apiHeader["Content-Type"] = "application/json;charset=UTF-8"
        apiHeader["Accept"] = "application/json"
        let models = try await Network.requestApi(needGobal: false, urlStr: urlStr1,method: .get,header: apiHeader,modelType: PTIPInfoModel.self)
        if let returnModel = models.customerModel as? PTIPInfoModel {
            return returnModel
        }
        return nil
    }
    
    public class func cancelAllNetworkRequest(completingOnQueue queue: DispatchQueue = .main, completion: (@Sendable () -> Void)? = nil) {
        Network.manager.cancelAllRequests(completingOnQueue: queue, completion: completion)
    }
    
    // 封装请求开始日志
    private static func logRequestStart(url: String, parameters: Parameters?, headers: HTTPHeaders, method: HTTPMethod) {
        PTNSLogConsole("🌐❤️1.请求地址 = \(url)\n💛2.参数 = \(parameters?.jsonString() ?? "没有参数")\n💙3.请求头 = \(headers.dictionary.jsonString() ?? "")\n🩷4.请求类型 = \(method.rawValue)🌐", levelType: PTLogMode, loggerType: .Network)
    }

    // 封装请求成功日志
    private static func logRequestSuccess(url: String, jsonStr: String) {
        PTNSLogConsole("🌐接口请求成功回调🌐\n❤️1.请求地址 = \(url)\n💛2.result:\(jsonStr.isEmpty ? "没有数据" : jsonStr)🌐", levelType: PTLogMode, loggerType: .Network)
    }

    // 封装请求失败日志
    private static func logRequestFailure(url: String, error: AFError) {
        PTNSLogConsole("❌接口:\(url)\n🎈----------------------出现错误----------------------🎈\(String(describing: error.errorDescription))❌", levelType: .Error, loggerType: .Network)
    }

    // 封装 token 添加逻辑
    private static func addToken(to headers: HTTPHeaders) -> HTTPHeaders {
        var headers = headers
        let token = Network.share.userToken
        if !token.isEmpty {
            headers["token"] = token
            headers["device"] = "iOS"
        }
        return headers
    }
    
    //JSONEncoding  JSON参数
    //URLEncoding    URL参数
    /// 项目总接口
    /// - Parameters:
    ///   - needGobal:
    ///   - urlStr: url地址
    ///   - method: 方法类型，默认post
    ///   - header:
    ///   - parameters: 请求参数，默认nil
    ///   - modelType: 是否需要传入接口的数据模型，默认nil
    ///   - encoder: 编码方式，默认url编码
    ///   - jsonRequest:
    ///  - Returns: ResponseModel
    class public func requestApi(needGobal:Bool = true,
                                 urlStr:URLConvertible,
                                 method: HTTPMethod = .post,
                                 header:HTTPHeaders? = nil,
                                 parameters: Parameters? = nil,
                                 modelType: Convertible.Type? = nil,
                                 encoder:ParameterEncoding = URLEncoding.default,
                                 jsonRequest:Bool = false) async throws -> PTBaseStructModel {
        let urlStr1 = (needGobal ? Network.gobalUrl() : "") + (try urlStr.asURL().absoluteString)
        guard urlStr1.isURL(), ((try? urlStr.asURL().absoluteString) != nil) else {
            throw AFError.invalidURL(url: "https://www.qq.com")
        }

        // 判断网络是否可用
        guard PTNetWorkStatus.shared.reachabilityManager?.isReachable == true else {
            Network.cancelAllNetworkRequest()
            throw AFError.createURLRequestFailed(error: NetWorkNoError)
        }

        var apiHeader = addToken(to: header ?? HTTPHeaders())
        if jsonRequest {
            apiHeader["Content-Type"] = "application/json;charset=UTF-8"
            apiHeader["Accept"] = "application/json"
        }

        logRequestStart(url: urlStr1, parameters: parameters, headers: apiHeader, method: method)

        return try await withCheckedThrowingContinuation { continuation in
            Network.manager.request(urlStr1, method: method, parameters: parameters, encoding: encoder, headers: apiHeader).responseData { data in
                switch data.result {
                case .success:
                    
                    var requestStruct = PTBaseStructModel()
                    requestStruct.resultData = data.data
                    let jsonStr = data.data?.toDict()?.toJSON() ?? ""
                    if jsonStr.stringIsEmpty() {
                        if let htmlString = data.data?.toString(encoding: .utf8),htmlString.containsHTMLTags() {
                            let error = AFError.createURLRequestFailed(error: NSError(domain: htmlString, code: 99999999993))
                            logRequestFailure(url: urlStr1, error: error)
                            continuation.resume(throwing: error)
                        } else {
                            let error = AFError.createURLRequestFailed(error: NSError(domain: "Data error", code: 99999999992))
                            logRequestFailure(url: urlStr1, error: error)
                            continuation.resume(throwing: error)
                        }
                    } else {
                        logRequestSuccess(url: urlStr1, jsonStr: jsonStr)
                        requestStruct.originalString = jsonStr
                        if let modelType1 = modelType {
                            requestStruct.customerModel = jsonStr.kj.model(type: modelType1)
                        }
                        continuation.resume(returning: requestStruct)
                    }
                case .failure(let error):
                    logRequestFailure(url: urlStr1, error: error)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
        
    /*
     使用方式
     Task {
         do {
             let progressStream = imageUpload(needGobal: true, images: images, path: "/api/project/ossImg")
             for try await (progress, response) in progressStream {
                 if let response = response {
                     // 上传完成，处理响应模型
                     PTNSLogConsole("Upload finished with response: \(response)")
                 } else {
                     // 处理进度更新
                     PTNSLogConsole("Upload progress: \(progress.fractionCompleted)")
                 }
             }
         } catch {
             // 处理错误
             PTNSLogConsole("Upload failed with error: \(error)")
         }
     }
     */
    /// 图片上传接口
    /// - Parameters:
    ///   - needGobal: 是否使用全局URL
    ///   - images: 图片集合
    ///   - path: 路径
    ///   - method: HTTP方法
    ///   - fileKey: 文件键名
    ///   - params: 请求参数
    ///   - header: 请求头部
    ///   - modelType: 模型类型
    ///   - jsonRequest: 是否为JSON请求
    ///   - pngData: 是否使用PNG格式
    /// - Returns: 响应模型
    class public func imageUpload(needGobal: Bool = true,
                                  images: [UIImage]?,
                                  path: URLConvertible,
                                  method: HTTPMethod = .post,
                                  fileKey: [String] = ["images"],
                                  params: [String: String]? = nil,
                                  header: HTTPHeaders? = nil,
                                  modelType: Convertible.Type? = nil,
                                  jsonRequest: Bool = false,
                                  pngData: Bool = true) -> AsyncThrowingStream<(progress: Progress, response: PTBaseStructModel?), Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let pathUrl = (needGobal ? Network.gobalUrl() : "") + (try path.asURL().absoluteString)
                    guard pathUrl.isURL(), ((try? pathUrl.asURL().absoluteString) != nil) else {
                        throw AFError.invalidURL(url: "https://www.qq.com")
                    }

                    // 判断网络是否可用
                    guard PTNetWorkStatus.shared.reachabilityManager?.isReachable == true else {
                        Network.cancelAllNetworkRequest()
                        throw AFError.createURLRequestFailed(error: NetWorkNoError)
                    }

                    var apiHeader = addToken(to: header ?? HTTPHeaders())
                    if jsonRequest {
                        apiHeader["Content-Type"] = "application/json;charset=UTF-8"
                        apiHeader["Accept"] = "application/json"
                    }

                    Network.manager.upload(multipartFormData: { multipartFormData in
                        images?.enumerated().forEach { index, image in
                            if let imgData = pngData ? image.pngData() : image.jpegData(compressionQuality: 0.2) {
                                multipartFormData.append(imgData, withName: fileKey[safe: index] ?? "image", fileName: "image_\(index).png", mimeType: pngData ? "image/png" : "image/jpeg")
                            }
                        }

                        params?.forEach { key, value in
                            multipartFormData.append(Data(value.utf8), withName: key)
                        }
                    }, to: pathUrl, method: method, headers: apiHeader)
                    .uploadProgress { progress in
                        continuation.yield((progress, nil))
                    }
                    .response { response in
                        switch response.result {
                        case .success(_):
                            var requestStruct = PTBaseStructModel()
                            if let htmlString = response.data?.toString(encoding: .utf8),htmlString.containsHTMLTags() {
                                let error = AFError.createUploadableFailed(error: NSError(domain: htmlString, code: 99999999994))
                                logRequestFailure(url: pathUrl, error: error)
                                continuation.finish(throwing: error)
                            } else {
                                let jsonStr = response.data?.toDict()?.toJSON() ?? ""
                                requestStruct.originalString = jsonStr
                                requestStruct.resultData = response.data

                                logRequestSuccess(url: pathUrl, jsonStr: jsonStr)

                                if let modelType = modelType {
                                    requestStruct.customerModel = jsonStr.kj.model(type: modelType)
                                }
                                continuation.yield((Progress(totalUnitCount: 1), requestStruct))
                                continuation.finish()
                            }
                        case .failure(let error):
                            logRequestFailure(url: pathUrl, error: error)
                            continuation.finish(throwing: error)
                        }
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    class open func fileDownLoad(fileUrl:String,saveFilePath:String,queue:DispatchQueue? = DispatchQueue.main,progress:FileDownloadProgress?) async throws -> Data {
        
        await withUnsafeContinuation { continuation in
            let download = Network()
            download.createDownload(fileUrl: fileUrl, saveFilePath: saveFilePath,queue: queue, progress: progress) { reponse in
                continuation.resume(returning: reponse.value!)
            } fail: { error in
                continuation.resume(throwing: error as! Never)
            }
        }
    }

    // 默认主线程
    public func createDownload(fileUrl:String,saveFilePath:String,queue:DispatchQueue? = DispatchQueue.main,progress:FileDownloadProgress?,success:FileDownloadSuccess?, fail:FileDownloadFail?) {
        
        self.fileUrl = fileUrl
        self.saveFilePath = saveFilePath
        self.success = success
        self.progress = progress
        self.fail = fail
        
        if !fileUrl.isURL() || fileUrl.stringIsEmpty() {
            if self.fail != nil {
                self.fail?(AFError.invalidURL(url: "https://www.qq.com"))
            }
            return
        }

        if queue != nil {
            self.queue = queue!
        }
        
        // 配置下载存储路径
        destination = { url , response in
            let saveUrl = URL(fileURLWithPath: saveFilePath)
            return (saveUrl,[.removePreviousFile, .createIntermediateDirectories] )
        }
        // 这里直接就开始下载了
        startDownloadFile()
    }
    
    // 暂停下载
    public func suspendDownload() {
        downloadRequest?.task?.suspend()
    }
    // 取消下载
    public func cancelDownload() {
        downloadRequest?.cancel()
        downloadRequest = nil;
        progress = nil
    }
    
    // 开始下载
    public func startDownloadFile() {
        if cancelledData != nil {
            downloadRequest = AF.download(resumingWith: cancelledData!, to: destination)
            downloadRequest?.downloadProgress { [weak self] (pro) in
                guard let `self` = self else {return}
                PTGCDManager.gcdMain {
                    self.progress?(pro.completedUnitCount,pro.totalUnitCount,pro.fractionCompleted)
                }
            }
            downloadRequest?.responseData(queue: queue, completionHandler: downloadResponse)
            
        } else if downloadRequest != nil {
            downloadRequest?.task?.resume()
        } else {
            downloadRequest = AF.download(fileUrl, to: destination)
            downloadRequest?.downloadProgress { [weak self] (pro) in
                guard let `self` = self else {return}
                PTGCDManager.gcdMain {
                    self.progress?(pro.completedUnitCount,pro.totalUnitCount,pro.fractionCompleted)
                }
            }
            
            downloadRequest?.responseData(queue: queue, completionHandler: downloadResponse)
        }
    }
    
    //根据下载状态处理
    private func downloadResponse(response:AFDownloadResponse<Data>) {
        switch response.result {
        case .success:
            if let data = response.value, data.count > 1000 {
                if success != nil {
                    PTGCDManager.gcdMain {
                        self.success?(response)
                    }
                }
            } else {
                PTGCDManager.gcdMain {
                    self.fail?(NetWorkDownloadError as Error)
                }
            }
        case .failure:
            cancelledData = response.resumeData//意外停止的话,把已下载的数据存储起来
            PTGCDManager.gcdMain {
                self.fail?(response.error)
            }
        }
    }
}

public class NetworkSessionDelegate:NSObject,URLSessionTaskDelegate{
    public func urlSession(_ session:URLSession,task:URLSessionTask,didFinishCollecting metrics: URLSessionTaskMetrics) {
        // 这里处理收集到的 metrics
        PTNSLogConsole("网络任务实例化和完成之间的时间间隔（taskInterval）: \(String(describing: metrics.taskInterval))")
        PTNSLogConsole("网络任务重定向次数（redirectCount）: \(String(describing: metrics.redirectCount))")
        for metric in metrics.transactionMetrics {
            handleTransactionMetric(metric)
        }
    }

    private func handleTransactionMetric(_ metric:URLSessionTaskTransactionMetrics) {

        PTNSLogConsole("----------网络时间方面-----")
        PTNSLogConsole("开始获取资源的时间（fetchStartDate）: \( String(describing: metric.fetchStartDate))")
        PTNSLogConsole("域名解析开始的时间（domainLookupStartDate）: \(String(describing: metric.domainLookupStartDate))")
        PTNSLogConsole("域名解析结束的时间（domainLookupEndDate）: \(String(describing: metric.domainLookupEndDate))")
        PTNSLogConsole("开始建立TCP连接的时间(connectStartDate): \(String(describing: metric.connectStartDate))")
        PTNSLogConsole("完成建立TCP连接的时间(connectEndDate): \(String(describing: metric.connectEndDate))")
        PTNSLogConsole("开始TLS安全握手的时间（secureConnectionStartDate）: \(String(describing: metric.secureConnectionStartDate))")
        PTNSLogConsole("完成TLS安全握手的时间（secureConnectionEndDate）: \(String(describing: metric.secureConnectionEndDate))")
        PTNSLogConsole("请求发送的时间（requestStartDate）: \(String(describing: metric.requestStartDate))")
        PTNSLogConsole("请求结束的时间（requestEndDate）: \(String(describing: metric.requestEndDate))")
        PTNSLogConsole("收到响应的第一个字节的时间（responseStartDate）: \(String(describing: metric.responseStartDate))")
        PTNSLogConsole("收到响应的最后一个字节的时间（responseEndDate）: \(String(describing: metric.responseEndDate))")

        if let domainLookupEndDate = metric.domainLookupEndDate,let domainLookupStartDate = metric.domainLookupStartDate {
            let domainLookupDuration = domainLookupEndDate.timeIntervalSince(domainLookupStartDate)
            PTNSLogConsole("域名解析时长：\(domainLookupDuration * 1000) 秒")
        } else {
            PTNSLogConsole("域名解析时长无法计算")
        }

        if let tcpConnectionEndDate = metric.connectEndDate,let tcpConnectionStartDate = metric.connectStartDate {
            let tcpConnectionDuration = tcpConnectionEndDate.timeIntervalSince(tcpConnectionStartDate)
            PTNSLogConsole("TCP连接时长：\(tcpConnectionDuration) 秒")
        } else {
            PTNSLogConsole("TCP连接时长无法计算")
        }

        if let tlsHandshakeEndDate = metric.secureConnectionEndDate,let tlsHandshakeStartDate = metric.secureConnectionStartDate {
            let tlsHandshakeDuration = tlsHandshakeEndDate.timeIntervalSince(tlsHandshakeStartDate)
            PTNSLogConsole("TLS安全握手时长：\(tlsHandshakeDuration) 秒")
        } else {
            PTNSLogConsole("TLS安全握手时长无法计算")
        }

        if let responseEndDate = metric.responseEndDate,let requestStartDate = metric.requestStartDate {
            let requestResponseDuration = responseEndDate.timeIntervalSince(requestStartDate)
            PTNSLogConsole("请求响应时长【从请求开发到请求结束】：\(requestResponseDuration) 秒")
        } else {
            PTNSLogConsole("请求响应时长无法计算")
        }

        if let connectionEndDate = metric.responseStartDate,let connectionStartDate = metric.responseStartDate {
            let connectionDuration = connectionEndDate.timeIntervalSince(connectionStartDate)
            PTNSLogConsole("响应时长【收到响应的第一个字节的时间到最后一个字节的时间】：\(connectionDuration) 秒")
        } else {
            PTNSLogConsole("响应时长无法计算")
        }

        PTNSLogConsole("----------网络数据监控方面（iOS13+有效）-----")

        PTNSLogConsole("iOS13+发送前编码之前请求体数据的大小(countOfRequestBodyBytesBeforeEncoding):\(metric.countOfRequestBodyBytesBeforeEncoding)")
        PTNSLogConsole("iOS13+发送的请求头字节数(countOfRequestHeaderBytesSent):\(metric.countOfRequestHeaderBytesSent)")
        PTNSLogConsole("iOS13+发送前编码之前请求体数据的大小(countOfResponseBodyBytesAfterDecoding):\(metric.countOfResponseBodyBytesAfterDecoding)")
        PTNSLogConsole("iOS13+传递给代理或完成处理程序的数据的大小(countOfResponseBodyBytesAfterDecoding):\(metric.countOfResponseBodyBytesAfterDecoding)")
        PTNSLogConsole("iOS13+接收的响应体字节数(countOfResponseBodyBytesReceived):\(metric.countOfResponseBodyBytesReceived)")
        PTNSLogConsole("iOS13+接收的响应头字节数(countOfResponseHeaderBytesReceived):\(metric.countOfResponseHeaderBytesReceived)")

        PTNSLogConsole("----------网络协议基础属性方面-----")

        PTNSLogConsole("使用的网络协议名称(networkProtocolName): \(metric.networkProtocolName ?? "Unknown")")

        PTNSLogConsole("iOS13+远程接口的IP地址(remoteAddress): \(String(describing: metric.remoteAddress))")
        PTNSLogConsole("iOS13 +本地接口的 IP 地址(localAddress): \(String(describing: metric.localAddress))")

        PTNSLogConsole("远程接口的端口号(remotePort): \(String(describing: metric.remotePort))")
        PTNSLogConsole("本地接口的端口号(localPort): \(String(describing: metric.localPort))")
        PTNSLogConsole("TLS密码套件(negotiatedTLSCipherSuite): \(String(describing: metric.negotiatedTLSCipherSuite?.rawValue))")
        PTNSLogConsole("TLS协议版本(negotiatedTLSProtocolVersion): \(String(describing: metric.negotiatedTLSProtocolVersion?.rawValue))")
        PTNSLogConsole("连接是否经由蜂窝网络(isCellular): \(metric.isCellular)")
        PTNSLogConsole("连接是否经由高成本接口(isExpensive): \(metric.isExpensive)")
        PTNSLogConsole("连接是否经由受限制的接口(isConstrained): \(metric.isConstrained)")
        PTNSLogConsole("是否使用了代理连接来获取资源(isProxyConnection): \(metric.isProxyConnection)")
        PTNSLogConsole("任务是否使用了重用连接来获取资源(isReusedConnection): \(metric.isReusedConnection)")
        PTNSLogConsole("连接是否成功协商了多路径协议(isMultipath): \(metric.isMultipath)")
        PTNSLogConsole("标识资源的加载方式(resourceFetchType): \(metric.resourceFetchType.rawValue)")
        
        //        case udp = 1 /* Resolution used DNS over UDP. */
        //
        //        case tcp = 2 /* Resolution used DNS over TCP. */
        //
        //        case tls = 3 /* Resolution used DNS over TLS. */
        //
        //        case https = 4 /* Resolution used DNS over HTTPS. */
        switch(metric.domainResolutionProtocol) {
        case.unknown:
            PTNSLogConsole("iOS14+ 域名解析所使用的协议(domainResolutionProtocol): unknown")
            break
        case.udp:
            PTNSLogConsole("iOS14+ 域名解析所使用的协议(domainResolutionProtocol): 表示使用了udp 协议进行域名解析")
            break
        case.tcp:
            PTNSLogConsole("iOS14+ 域名解析所使用的协议(domainResolutionProtocol): 表示使用了tcp 协议进行域名解析")
            break
        case.tls:
            PTNSLogConsole("iOS14+ 域名解析所使用的协议(domainResolutionProtocol):  表示使用了tls协议进行域名解析")
            break
        case.https:
            PTNSLogConsole("iOS14+ 域名解析所使用的协议(domainResolutionProtocol): 表示使用了https 协议进行域名解析")
            break
        @unknown default:
            PTNSLogConsole("iOS14+ 域名解析所使用的协议(domainResolutionProtocol): unknown")
            break
        }

        PTNSLogConsole("request url:\(String(describing: metric.request.url))")
        PTNSLogConsole("request httpMethod:\(String(describing: metric.request.httpMethod))")
        PTNSLogConsole("request timeoutInterval:\(metric.request.timeoutInterval)")
        PTNSLogConsole("-----request allHTTPHeaderFields---\n\(String(describing: metric.request.allHTTPHeaderFields?.debugDescription))\n-----request allHTTPHeaderFields end-----")
        PTNSLogConsole("request httpBody:\(String(describing: metric.request.httpBody))")

        let httpURLResponse:HTTPURLResponse? = metric.response as? HTTPURLResponse ?? nil

        PTNSLogConsole("response statusCode:\(String(describing: httpURLResponse?.statusCode))")
        PTNSLogConsole("-----response allHeaderFields:\n\(String(describing: httpURLResponse?.allHeaderFields))\n-----response allHeaderFields end-----")
    }
}
