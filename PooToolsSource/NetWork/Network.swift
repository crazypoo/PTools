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
import SwifterSwift
import CoreTelephony
import Photos

public let NetWorkNoError = NSError(domain: "PT Network no network".localized(), code: 99999999996)
public let NetWorkJsonExplainError = NSError(domain: "PT Network json fail".localized(), code: 99999999998)
public let NetWorkModelExplainError = NSError(domain: "PT Network model fail".localized(), code: 99999999999)
public let NetWorkDownloadError = NSError(domain: "PT Network download fail".localized(), code: 99999999997)
public let NetWorkCheckIPError = NSError(domain: "IP address error", code: 99999999995)

public let AppTestMode = "PT App network environment test".localized()
public let AppCustomMode = "PT App network environment custom".localized()
public let AppDisMode = "PT App network environment distribution".localized()

public enum NetworkCellularType : String {
    case ALL = "Cellular"
    case Cellular2G = "2G"
    case Cellular3G = "3G"
    case Cellular4G = "4G"
    case Cellular5G = "5G"
}

public enum NetWorkStatus {
    case unknown
    case notReachable
    case wwan(type:NetworkCellularType)
    case wifi
    case requiresConnection
    case wiredEthernet
    case loopback
    case other
    case checking
    
    public static func valueName(type:NetWorkStatus) -> String {
        switch type {
        case .unknown:
            "PT App network status unknow".localized()
        case .notReachable:
            "PT App network status disconnect".localized()
        case .wwan(let subType):
             subType.rawValue
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
        case .checking:
            "Checking"
        }
    }
}

public enum NetWorkEnvironment : Int {
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

public typealias NetWorkStatusBlock = (_ NetWorkStatus: NetWorkStatus, _ NetWorkEnvironment: NetWorkEnvironment) -> Void
public typealias UploadProgress = (_ progress: Progress) -> Void
public typealias FileDownloadProgress = (_ bytesRead:Int64,_ totalBytesRead:Int64,_ progress:Double) -> ()
public typealias FileDownloadSuccess = (_ reponse:AFDownloadResponse<Data>) -> ()
public typealias FileDownloadFail = (_ error:Error?) -> ()

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
    
    private let ctNetworkInfo = CTTelephonyNetworkInfo()

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
                    weakSelf.currentNetWorkStatus = NetWorkStatus.wwan(type: weakSelf.getCellularType())
                case .reachable(.ethernetOrWiFi):
                    weakSelf.currentNetWorkStatus = .wifi
                }
            } else {
                weakSelf.currentNetWorkStatus = .notReachable
            }
            
            netWork(weakSelf.currentNetWorkStatus, weakSelf.currentEnvironment)
        })
    }
    
    func getCellularType() -> NetworkCellularType {
        let radioAccess: String
        guard let id = self.ctNetworkInfo.dataServiceIdentifier else { return .ALL }
        guard let ra = self.ctNetworkInfo.serviceCurrentRadioAccessTechnology?[id] else { return .ALL }
        radioAccess = ra

        if radioAccess == CTRadioAccessTechnologyNRNSA
            || radioAccess == CTRadioAccessTechnologyNR {
            return .Cellular5G
        }

        switch radioAccess {
        case CTRadioAccessTechnologyGPRS,
            CTRadioAccessTechnologyEdge,
        CTRadioAccessTechnologyCDMA1x:
            return .Cellular2G
        case CTRadioAccessTechnologyWCDMA,
            CTRadioAccessTechnologyHSDPA,
            CTRadioAccessTechnologyHSUPA,
            CTRadioAccessTechnologyCDMAEVDORev0,
            CTRadioAccessTechnologyCDMAEVDORevA,
            CTRadioAccessTechnologyCDMAEVDORevB,
        CTRadioAccessTechnologyeHRPD:
            return .Cellular3G
        case CTRadioAccessTechnologyLTE:
            return .Cellular4G
        default:
            return.Cellular4G
        }
    }
    
    ///监听网络运行状态
    public func obtainDataFromLocalWhenNetworkUnconnected(handle:((NetWorkStatus,NetWorkEnvironment) -> Void)?) {
        detectNetWork { (status, environment)  in
            PTNSLogConsole(String(format: "PT App current mode".localized(), NetWorkStatus.valueName(type: status),NetWorkEnvironment.valueName(type: environment)),levelType: PTLogMode,loggerType: .Network)
            handle?(status,environment)
        }
    }
    
    public func netWork(handle: @escaping (_ status:NetWorkStatus) -> Void) {
        PTGCDManager.gcdMain {
            self.monitor.pathUpdateHandler = { path in
                if path.status == .satisfied {
                    if path.usesInterfaceType(.wifi) {
                        handle(.wifi)
                    } else if path.usesInterfaceType(.cellular) {
                        handle(NetWorkStatus.wwan(type: self.getCellularType()))
                    } else if path.usesInterfaceType(.wiredEthernet) {
                        handle(.wiredEthernet)
                    } else if path.usesInterfaceType(.loopback) {
                        handle(.loopback)
                    } else if path.usesInterfaceType(.other) {
                        handle(.other)
                    } else if path.isExpensive {
                        handle(.checking)
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
    /// 使用 Network.share 的只读快照，避免跨线程读取可变状态
    private let retryLimitSnapshot: Int
    private let baseDelaySnapshot: TimeInterval
    private let statusCodeToRetry: Int
    private let maxDelay: TimeInterval = 8.0
    private let jitter: TimeInterval = 0.4
    
    init() {
        retryLimitSnapshot = Network.share.retryTimes
        baseDelaySnapshot = Network.share.retryDelay
        statusCodeToRetry = Network.share.retryAPIStatusCode
    }
    
    private func shouldRetry(statusCode: Int?) -> Bool {
        guard let code = statusCode else { return true } // 无法获取状态码，视为可重试（可能是网络层错误）
        let retryableStatusCodes: Set<Int> = [408, 425, 429, 500, 502, 503, 504]
        if retryableStatusCodes.contains(code) { return true }
        if code == statusCodeToRetry { return true }
        if (500...599).contains(code) { return true }
        return false
    }
    
    public func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        // 取消/主动停止不重试
        if let afErr = error as? AFError, afErr.isExplicitlyCancelledError {
            return completion(.doNotRetry)
        }
        
        let statusCode = (request.task?.response as? HTTPURLResponse)?.statusCode
        
        // 临时网络问题判定
        let nsError = error as NSError
        let urlErrorCode = URLError.Code(rawValue: nsError.code)
        let isURLErrorDomain = (nsError.domain == NSURLErrorDomain)
        let temporaryURLErrors: Set<URLError.Code> = [
            .timedOut,              // -1001
            .cannotFindHost,        // -1003
            .cannotConnectToHost,   // -1004
            .networkConnectionLost, // -1005
            .dnsLookupFailed,       // -1006
            .notConnectedToInternet // -1009
        ]
        let isTemporaryNetworkIssue = isURLErrorDomain && temporaryURLErrors.contains(urlErrorCode)
        
        let canRetryByError = error.isNetworkError || isTemporaryNetworkIssue
        let canRetryByStatus = shouldRetry(statusCode: statusCode)
        
        guard request.retryCount < retryLimitSnapshot, (canRetryByError || canRetryByStatus) else {
            return completion(.doNotRetry)
        }
        
        // 指数回退 + 抖动
        let nth = max(1, request.retryCount + 1)
        let delay = min(baseDelaySnapshot * pow(2.0, Double(nth - 1)) + Double.random(in: 0...jitter), maxDelay)
        completion(.retryWithDelay(delay))
    }
}

public enum MimeTypeHelper {

    static func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        case "m4v": return "video/x-m4v"
        case "mp3": return "audio/mpeg"
        case "m4a": return "audio/mp4"
        case "aac": return "audio/aac"
        case "wav": return "audio/wav"
        case "caf": return "audio/x-caf"
        case "pdf": return "application/pdf"
        case "zip": return "application/zip"
        default: return "application/octet-stream"
        }
    }
}

public protocol NetworkPlugin {
    
    /// 请求发出前
    func willSend(_ request: inout URLRequest)
    
    /// 收到响应
    func didReceive(_ result: Result<Data, AFError>, response: HTTPURLResponse?)
}

@objcMembers
public class Network: NSObject {
    
    static public let share = Network()
            
    public var plugins: [NetworkPlugin] = []
    
    ///网络请求时间
    open var netRequsetTime:TimeInterval = 20
    open var downloadRequsetTime:TimeInterval = 5
    open var downloadEndTime:TimeInterval = 3600
    open var serverAddress:String = ""
    open var serverAddress_dev:String = ""
    open var socketAddress:String = ""
    open var socketAddress_dev:String = ""
    open var userToken:String = ""
    open var retryTimes:Int = 3
    open var retryDelay:TimeInterval = 1.5
    open var retryAPIStatusCode:Int = 502
    
    private var downloadQueue = DispatchQueue(label: "pt.downloader.queue")

    /// manager
    private func makeSession() -> Session {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = netRequsetTime
        configuration.waitsForConnectivity = true
        configuration.requestCachePolicy = .useProtocolCachePolicy
        configuration.urlCache = URLCache(memoryCapacity: 20 * 1024 * 1024,diskCapacity: 100 * 1024 * 1024)
        return Session(configuration: configuration,
                       interceptor: RetryHandler())
    }
    
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
    
    @MainActor func hudHide(completion:PTActionTask? = nil) {
        if let hud = self.hud {
            hud.hide {
                self.hud = nil
                completion?()
            }
        } else {
            completion?()
        }
    }
        
    //MARK: 服务器URL
    @MainActor
    public class func gobalUrl() async -> String {
        let environment = UIApplication.shared.inferredEnvironment
        if environment != .appStore {
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
    @MainActor
    public class func socketGobalUrl() async -> String {
        let environment = UIApplication.shared.inferredEnvironment
        if environment != .appStore {
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
        let urlStr1 = try await createURLRequest(urlStr: url, needGobal: false)
        let apiHeader = prepareRequestHeaders(header: nil, jsonRequest: true)
        let model = try await Network.requestApi(needGobal:false,urlStr: urlStr1,method: .get,header: apiHeader)
        let ipAddress = String(data: model.resultData!, encoding: .utf8) ?? ""
        return ipAddress
    }
    
    class public func requestIPInfo(ipAddress:String,lang:OSSVoiceEnum = .ChineseSimplified) async throws -> PTIPInfoModel? {
        
        let urlStr1 = try await createURLRequest(urlStr: "http://ip-api.com/json/\(ipAddress)?lang=\(lang.rawValue)", needGobal: false)
        let apiHeader = prepareRequestHeaders(header: nil, jsonRequest: true)
        let models = try await Network.requestApi(needGobal: false, urlStr: urlStr1,method: .get,header: apiHeader,modelType: PTIPInfoModel.self)
        if let returnModel = models.customerModel as? PTIPInfoModel {
            return returnModel
        }
        return nil
    }
    
    public class func cancelAllNetworkRequest(completingOnQueue queue: DispatchQueue = .main, completion: (@Sendable () -> Void)? = nil) {
        Network.share.makeSession().cancelAllRequests(completingOnQueue: queue, completion: completion)
    }
    
    // MARK: 日志
    private static func logRequestStart(url: String, parameters: Parameters?, headers: HTTPHeaders, method: HTTPMethod) {
        let paramsStr = parameters?.jsonString() ?? "没有参数"
        let headerStr = headers.dictionary.jsonString() ?? ""
        PTNSLogConsole("🌐❤️1.请求地址 = \(url)\n💛2.参数 = \(paramsStr)\n💙3.请求头 = \(headerStr)\n🩷4.请求类型 = \(method.rawValue)🌐", levelType: PTLogMode, loggerType: .Network)
    }

    private static func logRequestSuccess(url: String, jsonStr: String) {
        PTNSLogConsole("🌐接口请求成功回调🌐\n❤️1.请求地址 = \(url)\n💛2.result:\(jsonStr.isEmpty ? "没有数据" : jsonStr)🌐", levelType: PTLogMode, loggerType: .Network)
    }

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
    
    // MARK: 统一解析响应数据
    private static func isJSONResponse(_ response: HTTPURLResponse?, data: Data?) -> Bool {
        if response?.mimeType == "application/json" || response?.mimeType == "text/json" {
            return true
        }
        if let contentType = response?.value(forHTTPHeaderField: "Content-Type")?.lowercased(), contentType.contains("application/json") {
            return true
        }
        return false
    }
    
    private static func parseResponse(url: String,
                                      response: HTTPURLResponse?,
                                      data: Data?,
                                      modelType: Convertible.Type?) throws -> PTBaseStructModel {
        var result = PTBaseStructModel()
        result.resultData = data
        
        guard let data = data, !data.isEmpty else {
            let error = AFError.createURLRequestFailed(error: NSError(domain: "Data empty", code: 9999999901))
            logRequestFailure(url: url, error: error)
            throw error
        }
        
        // 非 JSON 的情况（可能是 HTML 或纯文本）
        if !isJSONResponse(response, data: data) {
            if let html = String(data: data, encoding: .utf8), html.containsHTMLTags() {
                let error = AFError.createURLRequestFailed(error: NSError(domain: html, code: 9999999902))
                logRequestFailure(url: url, error: error)
                throw error
            }
            // 如果不是 HTML，就当作纯文本成功返回（Debug 打印文本）
            var originalText = ""
            switch UIApplication.shared.inferredEnvironment {
            case .debug:
                originalText = String(decoding: data, as: UTF8.self)
            default:
                originalText = ""
            }
            logRequestSuccess(url: url, jsonStr: originalText)
            result.originalString = originalText
            return result
        }
        
        // JSON 情况
        let jsonString = data.toDict()?.toJSON() ?? ""
        result.originalString = jsonString
        logRequestSuccess(url: url, jsonStr: jsonString)
        if let modelType {
            result.customerModel = jsonString.kj.model(type: modelType)
        }
        
        return result
    }
    
    fileprivate static func makeResponseParser(url: String, modelType: Convertible.Type?) -> (_ response: HTTPURLResponse?, _ data: Data?) throws -> PTBaseStructModel {
        return { response, data in
            try parseResponse(
                url: url,
                response: response,
                data: data,
                modelType: modelType
            )
        }
    }
    
    private static func prepareRequestHeaders(header: HTTPHeaders?, jsonRequest: Bool) -> HTTPHeaders {
        var apiHeader = header ?? HTTPHeaders()
        if jsonRequest {
            apiHeader["Content-Type"] = "application/json;charset=UTF-8"
            apiHeader["Accept"] = "application/json"
        }
        return addToken(to: apiHeader)
    }

    private static func createURLRequest(urlStr: URLConvertible, needGobal: Bool) async throws -> String {
        let original = try urlStr.asURL().absoluteString
        
        if original.hasPrefix("http") {
            return original   // ✅ 已经是完整 URL
        }
        let gobalUrl = needGobal ? await Network.gobalUrl() : ""
        return gobalUrl + original
    }
    
    /// - Parameters:
    ///   - needGobal:是否全局使用默认
    ///   - urlStr: url地址
    ///   - method: 方法类型，默认post
    ///   - header: 請求頭
    ///   - modelType: 是否需要传入接口的数据模型，默认nil
    ///   - body: 最好utf8
    public class func requestBodyAPI(needGobal:Bool = true,
                                     urlStr:String,
                                     body:Data,
                                     header:HTTPHeaders? = nil,
                                     method:HTTPMethod = .post,
                                     modelType: Convertible.Type? = nil) async throws -> PTBaseStructModel {
        
        let urlStr1 = try await createURLRequest(urlStr: urlStr, needGobal: needGobal)

        let newHeader = header ?? ["Content-Type": "text/plain"]
        
        var dic:[String:Any] = [:]
        
        if let jsonObject = try? JSONSerialization.jsonObject(with: body, options: []),
           let dictionary = jsonObject as? [String: Any] {
            dic = dictionary
        }
        
        logRequestStart(url: urlStr1, parameters: dic, headers: newHeader, method: method)
        
        let parser = makeResponseParser(url: urlStr1, modelType: modelType)

        return try await withCheckedThrowingContinuation { continuation in
            AF.upload(body,
                      to: urlStr1,
                      method: method,
                      headers: newHeader)
            .response { resp in
                switch resp.result {
                case .success(_):
                    do {
                        let parsed = try parser(resp.response,resp.data)
                        continuation.resume(returning: parsed)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    logRequestFailure(url: urlStr1, error: error)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 项目总接口
    class public func requestApi(needGobal:Bool = true,
                                 urlStr:URLConvertible,
                                 method: HTTPMethod = .post,
                                 header:HTTPHeaders? = nil,
                                 parameters: Parameters? = nil,
                                 modelType: Convertible.Type? = nil,
                                 encoder:ParameterEncoding = URLEncoding.default,
                                 jsonRequest:Bool = false) async throws -> PTBaseStructModel {
        let urlStr1 = try await createURLRequest(urlStr: urlStr, needGobal: needGobal)
        let apiHeader = prepareRequestHeaders(header: header, jsonRequest: jsonRequest)
        logRequestStart(url: urlStr1, parameters: parameters, headers: apiHeader, method: method)
        
        let parser = makeResponseParser(url: urlStr1, modelType: modelType)

        let session = Network.share.makeSession()
        var urlRequest = try URLRequest(url: urlStr1, method: method, headers: apiHeader)
        urlRequest = try encoder.encode(urlRequest, with: parameters)
        // 👉 插件前置处理
        Network.share.plugins.forEach {
            $0.willSend(&urlRequest)
        }
        return try await withCheckedThrowingContinuation { continuation in
            session.request(urlRequest).responseData { data in
                let result: Result<Data, AFError> = data.result.map { $0 }
                
                // 👉 插件回调
                Network.share.plugins.forEach {
                    $0.didReceive(result, response: data.response)
                }

                switch data.result {
                case .success:
                    do {
                        let parsed = try parser(data.response,data.data)
                        continuation.resume(returning: parsed)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    logRequestFailure(url: urlStr1, error: error)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
        
    class public func fileUpload(needGobal: Bool = true,
                                 media: Any,
                                 path: URLConvertible,
                                 method: HTTPMethod = .post,
                                 fileKey: String = "",
                                 params: [String: String]? = nil,
                                 header: HTTPHeaders? = nil,
                                 modelType: Convertible.Type? = nil,
                                 jsonRequest: Bool = false) -> AsyncThrowingStream<(progress: Progress, response: PTBaseStructModel?), Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let pathUrl = try await createURLRequest(urlStr: path, needGobal: needGobal)
                    let apiHeader = prepareRequestHeaders(header: header, jsonRequest: jsonRequest)
                    
                    let parser = makeResponseParser(url: pathUrl, modelType: modelType)
                    let session = Network.share.makeSession()
                    session.upload(multipartFormData: { multipartFormData in
                        if let phasset = media as? PHAsset {
                            switch phasset.mediaType {
                            case .image:
                                Task {
                                    let image = await phasset.asyncImage()
                                    if let findImage = image {
                                        let canPNG = findImage.pngData() != nil
                                        if let imageData = findImage.pngData() ?? findImage.jpegData(compressionQuality: 0.6) {
                                            let key = fileKey
                                            let ext = canPNG ? "png" : "jpg"
                                            let dateString = Int(Date().timeIntervalSince1970)
                                            let fileName = "image_\(dateString).\(ext)"
                                            let mimeType = MimeTypeHelper.mimeType(for: ext)
                                            multipartFormData.append(imageData, withName: key, fileName: fileName, mimeType: mimeType)
                                        } else {
                                            continuation.finish(throwing: NSError(domain: "Image data error", code: 666))
                                        }
                                    }
                                }
                            case .video:
                                phasset.converPHAssetToAVURLAsset { urlAsset in
                                    if let url = urlAsset?.url {
                                        let ext = url.pathExtension.lowercased()
                                        let dateString = Int(Date().timeIntervalSince1970)
                                        let fileName = "video_\(dateString).\(ext)"
                                        let mimeType: String = MimeTypeHelper.mimeType(for: ext)
                                        multipartFormData.append(url, withName: fileKey, fileName: fileName, mimeType: mimeType)
                                    } else {
                                        continuation.finish(throwing: NSError(domain: "Video data error", code: 666))
                                    }
                                }
                            case .audio:
                                phasset.converPHAssetToAVURLAsset { urlAsset in
                                    if let url = urlAsset?.url {
                                        let ext = url.pathExtension.lowercased()
                                        let dateString = Int(Date().timeIntervalSince1970)
                                        let fileName = "audio_\(dateString).\(ext)"
                                        let mimeType: String = MimeTypeHelper.mimeType(for: ext)

                                        multipartFormData.append(url, withName: fileKey, fileName: fileName, mimeType: mimeType)
                                    }
                                }
                            default:
                                continuation.finish(throwing: NSError(domain: "Unknow data error", code: 666))
                            }
                        } else if let findImage = media as? UIImage {
                            let canPNG = findImage.pngData() != nil
                            if let imageData = findImage.pngData() ?? findImage.jpegData(compressionQuality: 0.6) {
                                let key = fileKey
                                let ext = canPNG ? "png" : "jpg"
                                let dateString = Int(Date().timeIntervalSince1970)
                                let fileName = "image_\(dateString).\(ext)"
                                let mimeType = MimeTypeHelper.mimeType(for: ext)
                                multipartFormData.append(imageData, withName: key, fileName: fileName, mimeType: mimeType)
                            } else {
                                continuation.finish(throwing: NSError(domain: "Image data error", code: 666))
                            }
                        } else if let findUrl = media as? URL {
                            if findUrl.isFileURL {
                                // fileProvider / iCloud 需要先复制
                                let uploadURL: URL

                                if findUrl.path.contains("File Provider Storage")
                                    || findUrl.path.contains("com.apple.FileProvider") {

                                    let tmpURL = FileManager.default.temporaryDirectory
                                        .appendingPathComponent(findUrl.lastPathComponent)

                                    try? FileManager.default.removeItem(at: tmpURL)
                                    try? FileManager.default.copyItem(at: findUrl, to: tmpURL)

                                    uploadURL = tmpURL
                                } else {
                                    uploadURL = findUrl
                                }

                                let ext = uploadURL.pathExtension.lowercased()
                                let mimeType = MimeTypeHelper.mimeType(for: ext)
                                let fileName = uploadURL.lastPathComponent

                                multipartFormData.append(uploadURL, withName: fileKey, fileName: fileName, mimeType: mimeType)
                            } else {
                                continuation.finish(throwing: NSError(domain: "Need to down load first", code: 666))
                            }
                        } else if let findString = media as? String,let findUrl = URL(string: findString) {
                            if findUrl.isFileURL {
                                // fileProvider / iCloud 需要先复制
                                let uploadURL: URL

                                if findUrl.path.contains("File Provider Storage")
                                    || findUrl.path.contains("com.apple.FileProvider") {

                                    let tmpURL = FileManager.default.temporaryDirectory
                                        .appendingPathComponent(findUrl.lastPathComponent)

                                    try? FileManager.default.removeItem(at: tmpURL)
                                    try? FileManager.default.copyItem(at: findUrl, to: tmpURL)

                                    uploadURL = tmpURL
                                } else {
                                    uploadURL = findUrl
                                }

                                let ext = uploadURL.pathExtension.lowercased()
                                let mimeType = MimeTypeHelper.mimeType(for: ext)
                                let fileName = uploadURL.lastPathComponent

                                multipartFormData.append(uploadURL, withName: fileKey, fileName: fileName, mimeType: mimeType)
                            } else {
                                continuation.finish(throwing: NSError(domain: "Need to down load first", code: 666))
                            }
                        }
                        
                        params?.forEach { key, value in
                            if let data = value.data(using: .utf8) {
                                multipartFormData.append(data, withName: key)
                            }
                        }
                    }, to: pathUrl, method: method, headers: apiHeader)
                    .uploadProgress { progress in
                        continuation.yield((progress, nil))
                    }
                    .response { resp in
                        switch resp.result {
                        case .success(_):
                            do {
                                let parsed = try parser(resp.response,resp.data)
                                continuation.yield((Progress(totalUnitCount: 1), parsed))
                                continuation.finish()
                            } catch {
                                continuation.finish(throwing: error)
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
    
    /// 图片上传接口
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
                    let pathUrl = try await createURLRequest(urlStr: path, needGobal: needGobal)
                    let apiHeader = prepareRequestHeaders(header: header, jsonRequest: jsonRequest)
                    
                    let parser = makeResponseParser(url: pathUrl, modelType: modelType)
                    let session = Network.share.makeSession()

                    session.upload(multipartFormData: { multipartFormData in
                        images?.enumerated().forEach { index, image in
                            let data = pngData ? image.pngData() : image.jpegData(compressionQuality: 0.6)
                            guard let imageData = data else { return }

                            let key = fileKey[safe: index] ?? "image"
                            let fileName = "image_\(index).\(pngData ? "png" : "jpg")"
                            let mimeType = pngData ? "image/png" : "image/jpeg"

                            multipartFormData.append(imageData, withName: key, fileName: fileName, mimeType: mimeType)
                        }

                        params?.forEach { key, value in
                            if let data = value.data(using: .utf8) {
                                multipartFormData.append(data, withName: key)
                            }
                        }
                    }, to: pathUrl, method: method, headers: apiHeader)
                    .uploadProgress { progress in
                        continuation.yield((progress, nil))
                    }
                    .response { resp in
                        switch resp.result {
                        case .success(_):
                            do {
                                let parsed = try parser(resp.response,resp.data)
                                continuation.yield((Progress(totalUnitCount: 1), parsed))
                                continuation.finish()
                            } catch {
                                continuation.finish(throwing: error)
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
    
    class open func videoUpload(needGobal: Bool = true,
                                fileURL: URL,
                                path: URLConvertible,
                                method: HTTPMethod = .post,
                                fileKey: String = "file",
                                params: [String: String]? = nil,
                                header: HTTPHeaders? = nil,
                                modelType: Convertible.Type? = nil,
                                jsonRequest: Bool = false) -> AsyncThrowingStream<(progress: Progress, response: PTBaseStructModel?), Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let pathUrl = try await createURLRequest(urlStr: path, needGobal: needGobal)
                    let apiHeader = prepareRequestHeaders(header: header, jsonRequest: jsonRequest)
                    
                    let parser = makeResponseParser(url: pathUrl, modelType: modelType)
                    let session = Network.share.makeSession()

                    session.upload(multipartFormData: { multipartFormData in
                        multipartFormData.append(fileURL, withName: "file", fileName: "\(fileURL.lastPathComponent).mp4", mimeType: "video/mp4")

                        params?.forEach { key, value in
                            if let data = value.data(using: .utf8) {
                                multipartFormData.append(data, withName: key)
                            }
                        }
                    }, to: pathUrl, method: method, headers: apiHeader)
                    .uploadProgress { progress in
                        continuation.yield((progress, nil))
                    }
                    .response { resp in
                        switch resp.result {
                        case .success(_):
                            do {
                                let parsed = try parser(resp.response,resp.data)
                                continuation.yield((Progress(totalUnitCount: 1), parsed))
                                continuation.finish()
                            } catch {
                                continuation.finish(throwing: error)
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

    // 自定义 Session，支持总超时
    private func makeDownloadSession() -> Session {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Network.share.downloadRequsetTime          // 请求超时时间
        configuration.timeoutIntervalForResource = Network.share.downloadEndTime       // 下载资源最大耗时（秒）
        return Session(configuration: configuration)
    }

    private class DownloadTask {
        let url: String
        let destination: (URL, HTTPURLResponse) -> (URL, DownloadRequest.Options)
        var downloadRequest: DownloadRequest?
        var resumeData: Data?

        var progressClosures: [FileDownloadProgress] = []
        var successClosures: [FileDownloadSuccess] = []
        var failClosures: [FileDownloadFail] = []

        init(url: String, destination: @escaping (URL, HTTPURLResponse) -> (URL, DownloadRequest.Options)) {
            self.url = url
            self.destination = destination
        }

        func start(queue: DispatchQueue? = DispatchQueue.main) {
            if let resumeData = self.resumeData {
                // 断点续传
                downloadRequest = Network.share.makeDownloadSession().download(resumingWith: resumeData, to: destination)
            } else {
                downloadRequest = Network.share.makeDownloadSession().download(url, to: destination)
            }

            downloadRequest?.downloadProgress { [weak self] pro in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    for closure in self.progressClosures {
                        closure(pro.completedUnitCount, pro.totalUnitCount, pro.fractionCompleted)
                    }
                }
            }

            downloadRequest?.responseData(queue: queue!, completionHandler: { [weak self] response in
                guard let self = self else { return }

                // 清理 resumeData
                self.resumeData = nil

                switch response.result {
                case .success( _):
                    DispatchQueue.main.async {
                        for closure in self.successClosures { closure(response) }
                    }
                    Network.share.removeTask(self.url)
                case .failure(let error):
                    // 保存 resumeData
                    self.resumeData = response.resumeData
                    DispatchQueue.main.async {
                        for closure in self.failClosures { closure(error) }
                    }
                }
            })
        }
        
        func suspend() {
            downloadRequest?.cancel { [weak self] data in
                self?.resumeData = data
                self?.downloadRequest = nil
            }
        }

        func resume() {
            start()
        }

        func cancel() {
            downloadRequest?.cancel()
        }
    }

    private var tasks: [String: DownloadTask] = [:]
    private let lock = NSLock()
    
    // MARK: - 下载入口
    public func download(fileUrl: String,
                         saveFilePath: String,
                         queue: DispatchQueue? = DispatchQueue.main,
                         progress: FileDownloadProgress? = nil,
                         success: FileDownloadSuccess? = nil,
                         fail: FileDownloadFail? = nil) {
        guard fileUrl.isURL(), !fileUrl.stringIsEmpty() else {
            fail?(AFError.invalidURL(url: "https://www.qq.com"))
            return
        }

        let dest: (URL, HTTPURLResponse) -> (URL, DownloadRequest.Options) = { _, _ in
            let saveUrl = URL(fileURLWithPath: saveFilePath)
            return (saveUrl,[.removePreviousFile, .createIntermediateDirectories])
        }

        queue?.async {
            self.lock.lock()
            if let task = self.tasks[fileUrl] {
                self.lock.unlock()
                // 已存在任务，添加闭包
                if let p = progress { task.progressClosures.append(p) }
                if let s = success { task.successClosures.append(s) }
                if let f = fail { task.failClosures.append(f) }
                return
            }
            self.lock.unlock()
            // 新任务
            let task = DownloadTask(url: fileUrl, destination: dest)
            if let p = progress { task.progressClosures.append(p) }
            if let s = success { task.successClosures.append(s) }
            if let f = fail { task.failClosures.append(f) }

            self.lock.lock()
            self.tasks[fileUrl] = task
            self.lock.unlock()
            task.start(queue: queue)
        }
    }

    // MARK: - Async/Await
    public func download(fileUrl: String, saveFilePath: String, queue: DispatchQueue? = DispatchQueue.main, progress: FileDownloadProgress? = nil) async throws -> Data? {
        try await withCheckedThrowingContinuation { continuation in
            self.download(fileUrl: fileUrl, saveFilePath: saveFilePath, queue: queue, progress: progress, success: { data in
                continuation.resume(returning: data.resumeData ?? nil)
            }, fail: { error in
                continuation.resume(throwing: error ?? NSError(domain: "PTDownloader", code: -1))
            })
        }
    }

    // MARK: - 暂停 / 恢复 / 取消
    public func suspend(fileUrl: String) {
        self.lock.lock()
        let task = self.tasks[fileUrl]
        self.lock.unlock()
        task?.suspend()
    }

    public func resume(fileUrl: String) {
        self.lock.lock()
        self.tasks[fileUrl]?.resume()
        self.lock.unlock()
    }

    public func cancel(fileUrl: String) {
        self.lock.lock()
        let task = self.tasks[fileUrl]
        self.tasks[fileUrl] = nil
        self.lock.unlock()
        
        task?.cancel()
    }
    
    public func removeTask(_ url: String) {
        self.lock.lock()
        self.tasks[url] = nil
        self.lock.unlock()
    }
}

public class NetworkSessionDelegate:NSObject,URLSessionTaskDelegate{
    public func urlSession(_ session:URLSession,task:URLSessionTask,didFinishCollecting metrics: URLSessionTaskMetrics) {
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
            PTNSLogConsole("TCP连接时长: \(tcpConnectionDuration * 1000) 秒")
        } else {
            PTNSLogConsole("TCP连接时长无法计算")
        }

        if let tlsHandshakeEndDate = metric.secureConnectionEndDate,let tlsHandshakeStartDate = metric.secureConnectionStartDate {
            let tlsHandshakeDuration = tlsHandshakeEndDate.timeIntervalSince(tlsHandshakeStartDate)
            PTNSLogConsole("TLS安全握手时长: \(tlsHandshakeDuration * 1000) 秒")
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
            PTNSLogConsole("响应时长: \(connectionDuration * 1000) 秒")
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
