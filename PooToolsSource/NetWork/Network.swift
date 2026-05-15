//
//  Network.swift
//  MiniChatSwift
//
//  Created by 林勇彬 on 2022/5/21.
//  Copyright © 2022 九州所想. All rights reserved.
//

import UIKit
import Alamofire
import Network
import SwifterSwift
import CoreTelephony
import Photos
import SmartCodable
import KakaJSON

public enum PTNetworkError: Error, LocalizedError, CustomNSError {
    case noNetwork
    case checkIPFail
    case downloadFail
    case jsonExplainFail
    case modelExplainFail
    
    case dataEmpty
    case htmlResponse(String)
    case uploadDataError(String)
    case businessError(code: Int, msg: String)
    
    @MainActor public var errorDescription: String? {
        switch self {
        case .noNetwork:        return "PT Network no network".localized()
        case .checkIPFail:      return "IP address error"
        case .downloadFail:     return "PT Network download fail".localized()
        case .jsonExplainFail:  return "PT Network json fail".localized()
        case .modelExplainFail: return "PT Network model fail".localized()
            
        case .dataEmpty:              return "Data empty"
        case .htmlResponse(let html): return html
        case .uploadDataError(let msg): return msg
        case .businessError(_, let msg): return msg
        }
    }
    
    public var errorCode: Int {
        switch self {
        case .checkIPFail:      return 99999999995
        case .noNetwork:        return 99999999996
        case .downloadFail:     return 99999999997
        case .jsonExplainFail:  return 99999999998
        case .modelExplainFail: return 99999999999
            
        case .dataEmpty:        return 9999999901
        case .htmlResponse:     return 9999999902
        case .uploadDataError:  return 666
        case .businessError(let code, _): return code
        }
    }
    
    public static var errorDomain: String {
        return "com.pt.network.error"
    }
}

@MainActor public let AppTestMode = "PT App network environment test".localized()
@MainActor public let AppCustomMode = "PT App network environment custom".localized()
@MainActor public let AppDisMode = "PT App network environment distribution".localized()

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
    
    @MainActor public static func valueName(type:NetWorkStatus) -> String {
        switch type {
        case .unknown:            return "PT App network status unknow".localized()
        case .notReachable:       return "PT App network status disconnect".localized()
        case .wwan(let subType):  return subType.rawValue
        case .wifi:               return "WIFI"
        case .requiresConnection: return "RequiresConnection"
        case .wiredEthernet:      return "WiredEthernet"
        case .loopback:           return "loopback"
        case .other:              return "Other"
        case .checking:           return "Checking"
        }
    }
}

public enum NetWorkEnvironment : Int {
    case Development
    case Test
    case Distribution
    
    @MainActor public static func valueName(type:NetWorkEnvironment) -> String {
        switch type {
        case .Development:  return "PT App network environment custom".localized()
        case .Test:         return "PT App network environment test".localized()
        case .Distribution: return "PT App network environment distribution".localized()
        }
    }
}

public typealias NetWorkStatusBlock = (_ NetWorkStatus: NetWorkStatus, _ NetWorkEnvironment: NetWorkEnvironment) -> Void
public typealias UploadProgress = (_ progress: Progress) -> Void
public typealias FileDownloadProgress = (_ bytesRead:Int64,_ totalBytesRead:Int64,_ progress:Double) -> ()
public typealias FileDownloadSuccess = (_ reponse:AFDownloadResponse<URL?>) -> ()
public typealias FileDownloadFail = (_ error:Error?) -> ()

public var PTBaseURLMode:NetWorkEnvironment {
    guard let sliderValue = PTCoreUserDefultsWrapper.AppServiceIdentifier else { return .Distribution }
    if sliderValue == "1" { return .Distribution }
    else if sliderValue == "2" { return .Test }
    else if sliderValue == "3" { return .Development }
    return .Distribution
}

public var PTSocketURLMode:NetWorkEnvironment {
    guard let sliderValue = PTCoreUserDefultsWrapper.AppSocketServiceIdentifier else { return .Distribution }
    if sliderValue == "1" { return .Distribution }
    else if sliderValue == "2" { return .Test }
    else if sliderValue == "3" { return .Development }
    return .Distribution
}

public final class NetworkReachability {
    public static let shared = NetworkReachability()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "network.reachability")
    
    private(set) var isReachable: Bool = true
    private(set) var isExpensive: Bool = false
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isReachable = (path.status == .satisfied)
            self?.isExpensive = path.isExpensive
        }
        monitor.start(queue: queue)
    }
}

public final class PTNetWorkStatus: @unchecked Sendable {
    public static let shared = PTNetWorkStatus()
    private let queue = DispatchQueue(label: "pt.network.status.monitor")
    private let ctNetworkInfo = CTTelephonyNetworkInfo()
    
    private init() {}
    
    private func getCellularType() -> NetworkCellularType {
        let radioAccess: String
        guard let id = ctNetworkInfo.dataServiceIdentifier else { return .ALL }
        guard let ra = ctNetworkInfo.serviceCurrentRadioAccessTechnology?[id] else { return .ALL }
        radioAccess = ra

        if radioAccess == CTRadioAccessTechnologyNRNSA || radioAccess == CTRadioAccessTechnologyNR {
            return .Cellular5G
        }

        switch radioAccess {
        case CTRadioAccessTechnologyGPRS, CTRadioAccessTechnologyEdge, CTRadioAccessTechnologyCDMA1x:
            return .Cellular2G
        case CTRadioAccessTechnologyWCDMA, CTRadioAccessTechnologyHSDPA, CTRadioAccessTechnologyHSUPA,
             CTRadioAccessTechnologyCDMAEVDORev0, CTRadioAccessTechnologyCDMAEVDORevA, CTRadioAccessTechnologyCDMAEVDORevB,
             CTRadioAccessTechnologyeHRPD:
            return .Cellular3G
        case CTRadioAccessTechnologyLTE:
            return .Cellular4G
        default:
            return .Cellular4G
        }
    }
    
    public var statusStream: AsyncStream<NetWorkStatus> {
        AsyncStream { continuation in
            let monitor = NWPathMonitor()
            monitor.pathUpdateHandler = { [weak self] path in
                guard let self = self else { return }
                let status: NetWorkStatus
                if path.status == .satisfied {
                    if path.usesInterfaceType(.wifi) { status = .wifi }
                    else if path.usesInterfaceType(.cellular) { status = .wwan(type: self.getCellularType()) }
                    else if path.usesInterfaceType(.wiredEthernet) { status = .wiredEthernet }
                    else if path.usesInterfaceType(.loopback) { status = .loopback }
                    else if path.usesInterfaceType(.other) { status = .other }
                    else if path.isExpensive { status = .checking }
                    else { status = .unknown }
                } else if path.status == .unsatisfied { status = .notReachable }
                else if path.status == .requiresConnection { status = .requiresConnection }
                else { status = .unknown }
                
                continuation.yield(status)
            }
            monitor.start(queue: self.queue)
            continuation.onTermination = { @Sendable _ in
                monitor.cancel()
                PTNSLogConsole("🌐 网络监听已自动销毁", levelType: PTLogMode, loggerType: .network)
            }
        }
    }
}

extension Error {
    var isNetworkError: Bool {
        if let afError = self as? AFError {
            switch afError {
            case .sessionTaskFailed(let underlyingError as NSError):
                return underlyingError.domain == NSURLErrorDomain
            default: return false
            }
        }
        return (self as NSError).domain == NSURLErrorDomain
    }
}

// MARK: - ================= 3. 拦截器、配置与去重池 =================

fileprivate class RetryHandler: @unchecked Sendable ,RequestInterceptor {
    private let retryLimitSnapshot: Int
    private let baseDelaySnapshot: TimeInterval
    private let statusCodeToRetry: Int
    private let maxDelay: TimeInterval = 8.0
    private let jitter: TimeInterval = 0.4
    
    init() {
        retryLimitSnapshot = Network.share.config.retryTimes
        baseDelaySnapshot = Network.share.config.retryDelay
        statusCodeToRetry = Network.share.config.retryAPIStatusCode
    }
    
    private func shouldRetry(statusCode: Int?) -> Bool {
        guard let code = statusCode else { return true }
        let retryableStatusCodes: Set<Int> = [408, 425, 429, 500, 502, 503, 504]
        if retryableStatusCodes.contains(code) { return true }
        if code == statusCodeToRetry { return true }
        if (500...599).contains(code) { return true }
        return false
    }
    
    public func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        if let afErr = error as? AFError, afErr.isExplicitlyCancelledError {
            return completion(.doNotRetry)
        }
        if let urlError = error as? URLError, urlError.code == .cancelled {
            return completion(.doNotRetry)
        }
        if !NetworkReachability.shared.isReachable {
            return completion(.doNotRetry)
        }

        let statusCode = (request.task?.response as? HTTPURLResponse)?.statusCode
        let nsError = error as NSError
        let urlErrorCode = URLError.Code(rawValue: nsError.code)
        let isURLErrorDomain = (nsError.domain == NSURLErrorDomain)
        let temporaryURLErrors: Set<URLError.Code> = [.timedOut, .cannotFindHost, .cannotConnectToHost, .networkConnectionLost, .dnsLookupFailed]
        let isTemporaryNetworkIssue = isURLErrorDomain && temporaryURLErrors.contains(urlErrorCode)
        
        let canRetryByError = error.isNetworkError || isTemporaryNetworkIssue
        let canRetryByStatus = shouldRetry(statusCode: statusCode)
        
        guard request.retryCount < retryLimitSnapshot, (canRetryByError || canRetryByStatus) else {
            return completion(.doNotRetry)
        }
        
        let isExpensive = NetworkReachability.shared.isExpensive
        let delay: TimeInterval
        if isExpensive {
            delay = min(baseDelaySnapshot * 2.0, maxDelay)
        } else {
            let nth = max(1, request.retryCount + 1)
            delay = min(baseDelaySnapshot * pow(2.0, Double(nth - 1)) + Double.random(in: 0...jitter), maxDelay)
        }
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

public protocol NetworkPlugin: Sendable {
    func willSend(_ request: inout URLRequest) async
    func didReceive(_ result: Result<Data, AFError>, request: URLRequest, response: HTTPURLResponse?) async
}

public struct CacheObject: Codable {
    let data: Data
    let expireTime: TimeInterval
    var lastAccessTime: TimeInterval
}

public enum PTNetworkCachePolicy:String, Sendable {
    case none
    case cacheOnly
    case networkOnly
    case cacheElseNetwork
    case networkElseCache
}

public actor NetworkCache {
    static let shared = NetworkCache()
    private let memoryCache = NSCache<NSString, NSData>()
    private let diskPath: String
    private var lastCleanTime: TimeInterval = 0
    
    private init() {
        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        diskPath = path.nsString.appendingPathComponent("PTNetworkCache")
        try? FileManager.default.createDirectory(atPath: diskPath, withIntermediateDirectories: true)
    }
    
    private func cacheKey(_ request: URLRequest) -> String {
        let url = request.url?.absoluteString ?? ""
        let sortedQuery = request.url?.query?.split(separator: "&").sorted().joined(separator: "&") ?? ""
        let body = request.httpBody?.sortedJSONData() ?? Data()
        return (url + sortedQuery + body.base64EncodedString()).md5
    }
    
    func save(data: Data, request: URLRequest, expire: TimeInterval) {
        let key = cacheKey(request)
        let now = Date().timeIntervalSince1970
        let obj = CacheObject(data: data, expireTime: now + expire, lastAccessTime: now)
        
        guard let encoded = try? JSONEncoder().encode(obj) else { return }
        memoryCache.setObject(encoded as NSData, forKey: key as NSString)
        
        let path = self.diskPath.nsString.appendingPathComponent(key)
        Task.detached(priority: .background) { try? encoded.write(to: URL(fileURLWithPath: path)) }
    }
    
    func read(request: URLRequest) -> Data? {
        let key = cacheKey(request)
        let now = Date().timeIntervalSince1970

        if let data = memoryCache.object(forKey: key as NSString) as Data?,
           var obj = try? JSONDecoder().decode(CacheObject.self, from: data), obj.expireTime > now {
            obj.lastAccessTime = now
            if let encoded = try? JSONEncoder().encode(obj) {
                memoryCache.setObject(encoded as NSData, forKey: key as NSString)
            }
            return obj.data
        }
        
        let path = (self.diskPath as NSString).appendingPathComponent(key)
        if let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           var obj = try? JSONDecoder().decode(CacheObject.self, from: data), obj.expireTime > now {
            obj.lastAccessTime = now
            if let encoded = try? JSONEncoder().encode(obj) {
                memoryCache.setObject(encoded as NSData, forKey: key as NSString)
                Task.detached(priority: .background) { try? encoded.write(to: URL(fileURLWithPath: path)) }
            }
            return obj.data
        }
        return nil
    }

    public func clearAll() {
        memoryCache.removeAllObjects()
        try? FileManager.default.removeItem(atPath: diskPath)
    }
    
    public func cleanIfNeeded() {
        let now = Date().timeIntervalSince1970
        guard now - lastCleanTime > Network.share.config.cleanCachePreSec else { return }
        lastCleanTime = now
        Task.detached(priority: .background) { self._cleanDisk() }
    }
    
    private nonisolated func _cleanDisk() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: URL(fileURLWithPath: diskPath), includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey], options: .skipsHiddenFiles) else { return }

        var totalSize: Int64 = 0
        var cacheFiles: [(url: URL, size: Int64, lastAccess: TimeInterval)] = []
        let now = Date().timeIntervalSince1970

        for fileURL in files {
            autoreleasepool {
                guard let data = try? Data(contentsOf: fileURL), let obj = try? JSONDecoder().decode(CacheObject.self, from: data) else { return }
                if obj.expireTime < now {
                    try? fm.removeItem(at: fileURL)
                    return
                }
                let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                totalSize += Int64(size)
                cacheFiles.append((fileURL, Int64(size), obj.lastAccessTime))
            }
        }

        if totalSize <= Network.share.config.maxDiskSize { return }
        cacheFiles.sort { $0.lastAccess < $1.lastAccess }
        let targetSize = Int64(Double(Network.share.config.maxDiskSize) * Network.share.config.cleanThreshold)

        for file in cacheFiles {
            try? fm.removeItem(at: file.url)
            totalSize -= file.size
            if totalSize <= targetSize { break }
        }
    }
}

extension URLRequest {
    var cachePolicyType: PTNetworkCachePolicy {
        get {
            let value = value(forHTTPHeaderField: "cachePolicy") ?? PTNetworkCachePolicy.cacheElseNetwork.rawValue
            return PTNetworkCachePolicy(rawValue: value) ?? .cacheElseNetwork
        }
        set { setValue(newValue.rawValue, forHTTPHeaderField: "cachePolicy") }
    }
    
    var cacheExpire: TimeInterval {
        get {
            let value = value(forHTTPHeaderField: "cacheExpire") ?? "300"
            return TimeInterval(value) ?? 300
        }
        set { setValue("\(newValue)", forHTTPHeaderField: "cacheExpire") }
    }
    
    var isMock: Bool {
        get { value(forHTTPHeaderField: "mockResponse") == "true" }
        set { setValue(newValue ? "true" : "false", forHTTPHeaderField: "mockResponse") }
    }
        
    var dedupPolicy: PTNetworkDedupPolicy {
        get {
            let value = value(forHTTPHeaderField: "dedupPolicy") ?? "auto"
            switch value {
            case "none": return .none
            case "identical": return .identical
            default:
                switch cachePolicyType {
                case .none: return .none
                default: return .identical
                }
            }
        }
    }
}

public final class PTNetworkCachePlugin: NetworkPlugin {
    public func willSend(_ request: inout URLRequest) async {
        guard request.httpMethod == "GET" else { return }
        let policy = request.cachePolicyType
        switch policy {
        case .none, .networkOnly: return
        case .cacheOnly, .cacheElseNetwork:
            if let _ = await NetworkCache.shared.read(request: request) { request.isMock = true }
        case .networkElseCache: return
        }
    }
    
    public func didReceive(_ result: Result<Data, AFError>, request: URLRequest, response: HTTPURLResponse?) async {
        guard case .success(let data) = result else {
            if request.cachePolicyType == .networkElseCache, let cache = await NetworkCache.shared.read(request: request) {
                NotificationCenter.default.post(name: NSNotification.Name("PTNetworkCacheFallback"), object: cache)
            }
            return
        }
        guard request.httpMethod == "GET", request.cachePolicyType != .none else { return }
        await NetworkCache.shared.save(data: data, request: request, expire: request.cacheExpire)
    }
}

public enum PTNetworkDedupPolicy : Sendable {
    case none
    case identical
    case custom(String)
    
    func getOptionName() -> String {
        switch self {
        case .none: return "none"
        case .identical: return "identical"
        case .custom(let string): return string
        }
    }
}

public struct RequestKey: Hashable {
    let url: String
    let method: String
    let paramsHash: Int
    
    init(request: URLRequest) {
        self.url = request.url?.absoluteString ?? ""
        self.method = request.httpMethod ?? ""
        self.paramsHash = request.httpBody?.hashValue ?? 0
    }
}

// 🌟 泛型去重管理池：完美闭环跨线程并发与擦除提取
public actor RequestDeduplicator {
    public static let shared = RequestDeduplicator()
    
    // 使用 Any 存储不同泛型类型的 Task
    private var runningTasks: [RequestKey: Any] = [:]
    
    private init() {}
    
    public func execute<T>(
        request: URLRequest,
        policy: PTNetworkDedupPolicy,
        task: @escaping @Sendable () async throws -> PTBaseStructModel<T>
    ) async throws -> PTBaseStructModel<T> {
        
        switch policy {
        case .none: return try await task()
        default:
            let key = RequestKey(request: request)
            
            // 1. 检查是否存在同类型同参数的正在运行任务
            if let existingTask = runningTasks[key] as? Task<PTBaseStructModel<T>, Error> {
                return try await existingTask.value
            }
            
            // 2. 创建新任务
            let newTask = Task { try await task() }
            runningTasks[key] = newTask
            
            // 3. 任务结束后清理现场
            defer { runningTasks.removeValue(forKey: key) }
            
            return try await newTask.value
        }
    }
}

public struct PTNetworkConfig: Sendable {
    public var netRequsetTime: TimeInterval = 20
    public var downloadRequsetTime: TimeInterval = 5
    public var downloadEndTime: TimeInterval = 3600
    
    public var serverAddress: String = ""
    public var serverAddress_dev: String = ""
    public var socketAddress: String = ""
    public var socketAddress_dev: String = ""
    
    public var userToken: String = ""
    public var retryTimes: Int = 3
    public var retryDelay: TimeInterval = 1.5
    public var retryAPIStatusCode: Int = 502
    
    public var networkCacheOption: PTNetworkCachePolicy = .cacheElseNetwork
    public var networkCacheEXPTime: String = "600"
    public var networkDudupOption: PTNetworkDedupPolicy = .custom("auto")
    
    public var maxDiskSize: Int64 = 100 * 1024 * 1024
    public var cleanThreshold: Double = 0.7
    public var cleanCachePreSec: TimeInterval = 60
    public var logMaxCount: Double = 3000

    public init() {}
}

// MARK: - ================= 4. 核心 Network 调度枢纽 =================

public final class Network: @unchecked Sendable {
    static public let share = Network()
    public var plugins: [NetworkPlugin] = [PTNetworkCachePlugin()]
    private var downloadQueue = DispatchQueue(label: "pt.downloader.queue")
    
    private let configLock = NSLock()
    private var _config = PTNetworkConfig()
    
    public var config: PTNetworkConfig {
        get {
            configLock.lock()
            defer { configLock.unlock() }
            return _config
        }
        set {
            configLock.lock()
            _config = newValue
            configLock.unlock()
        }
    }
    
    private lazy var session: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = config.netRequsetTime
        configuration.waitsForConnectivity = true
        configuration.requestCachePolicy = .useProtocolCachePolicy
        var protocols = configuration.protocolClasses ?? []
        protocols.insert(PTCustomHTTPProtocol.self, at: 0)
        configuration.protocolClasses = protocols

        configuration.urlCache = URLCache(memoryCapacity: 20 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024)
        return Session(configuration: configuration, interceptor: RetryHandler())
    }()
    
    public var hud:PTHudView?
    @MainActor public var hudConfig : PTHudConfig {
        let hudConfig = PTHudConfig.share
        hudConfig.hudColors = [.gray,.gray]
        hudConfig.lineWidth = 4
        return hudConfig
    }
    
    public func hudShow()  {
        Task { @MainActor in
            let _ = Network.share.hudConfig
            if self.hud == nil {
                self.hud = PTHudView()
                self.hud!.hudShow()
            }
        }
    }
    
    @MainActor public func hudHide(completion:PTActionTask? = nil) {
        if let hud = self.hud {
            hud.hide { [weak self] in
                self?.hud = nil
                completion?()
            }
        } else {
            completion?()
        }
    }
    
    @MainActor public class func gobalUrl() async -> String {
        let environment = UIApplication.shared.inferredEnvironment_PT
        if environment != .appStore {
            PTNSLogConsole("PTBaseURLMode:\(PTBaseURLMode)",levelType: PTLogMode,loggerType: .network)
            switch PTBaseURLMode {
            case .Development:
                let url_debug:String = PTCoreUserDefultsWrapper.AppRequestUrl
                return url_debug.isEmpty ? Network.share.config.serverAddress_dev : url_debug
            case .Test:         return Network.share.config.serverAddress_dev
            case .Distribution: return Network.share.config.serverAddress
            }
        } else {
            return Network.share.config.serverAddress
        }
    }
    
    @MainActor public class func socketGobalUrl() async -> String {
        let environment = UIApplication.shared.inferredEnvironment_PT
        if environment != .appStore {
            PTNSLogConsole("PTSocketURLMode:\(PTSocketURLMode)",levelType: PTLogMode,loggerType: .network)
            switch PTSocketURLMode {
            case .Development:
                let url_debug:String = PTCoreUserDefultsWrapper.AppSocketUrl
                return url_debug.isEmpty ? Network.share.config.socketAddress_dev : url_debug
            case .Test:         return Network.share.config.socketAddress_dev
            case .Distribution: return Network.share.config.socketAddress
            }
        } else {
            return Network.share.config.socketAddress
        }
    }
    
    class public func getIpAddress(url:String = "https://api.ipify.org") async throws -> String {
        let urlStr1 = try await createURLRequest(urlStr: url, needGobal: false)
        let apiHeader = prepareRequestHeaders(header: nil, jsonRequest: true)
        let model = try await Network.requestCodableApi(needGobal:false, urlStr: urlStr1, method: .get, header: apiHeader, modelType: PTDummyModel.self)
        return String(data: model.resultData ?? Data(), encoding: .utf8) ?? ""
    }
    
    class public func requestIPInfo(ipAddress:String,lang:OSSVoiceEnum = .ChineseSimplified) async throws -> PTIPInfoModel? {
        let urlStr1 = try await createURLRequest(urlStr: "http://ip-api.com/json/\(ipAddress)?lang=\(lang.rawValue)", needGobal: false)
        let apiHeader = prepareRequestHeaders(header: nil, jsonRequest: true)
        let models = try await Network.requestCodableApi(needGobal: false, urlStr: urlStr1, method: .get, header: apiHeader, modelType: PTIPInfoModel.self)
        return models.customerModel
    }
    
    public class func cancelAllNetworkRequest(completingOnQueue queue: DispatchQueue = .main, completion: (@Sendable () -> Void)? = nil) {
        Network.share.session.cancelAllRequests(completingOnQueue: queue, completion: completion)
    }
    
    private static func logRequestStart(url: String, parameters: Parameters?, headers: HTTPHeaders, method: HTTPMethod) {
        let paramsStr = parameters != nil ? String(describing: parameters!) : "没有参数"
        PTNSLogConsole("🌐❤️1.请求地址 = \(url)\n💛2.参数 = \(paramsStr)\n💙3.请求头 = \(String(describing: headers.dictionary))\n🩷4.请求类型 = \(method.rawValue)🌐", levelType: PTLogMode, loggerType: .network)
    }
    
    private static func logRequestSuccess(url: String, jsonStr: String) {
        let printStr = jsonStr.isEmpty ? "数据为空 (或非JSON格式/被非Debug环境拦截)" : jsonStr
        PTNSLogConsole("🌐接口请求成功回调🌐\n❤️1.请求地址 = \(url)\n💛2.result:\(printStr)🌐", levelType: PTLogMode, loggerType: .network)
    }
    
    private static func logRequestFailure(url: String, error: AFError) {
        PTNSLogConsole("❌接口:\(url)\n🎈----------------------出现错误----------------------🎈\(String(describing: error.errorDescription))❌", levelType: .error, loggerType: .network)
    }
    
    private static func addToken(to headers: HTTPHeaders) -> HTTPHeaders {
        var headers = headers
        let token = Network.share.config.userToken
        if !token.isEmpty {
            headers["token"] = token
            headers["device"] = "iOS"
        }
        return headers
    }
    
    private static func isJSONResponse(_ response: HTTPURLResponse?, data: Data?) -> Bool {
        if response?.mimeType == "application/json" || response?.mimeType == "text/json" { return true }
        if let contentType = response?.value(forHTTPHeaderField: "Content-Type")?.lowercased(), contentType.contains("application/json") { return true }
        return false
    }

    /// 🌟 内部核心日志美化转换工具
    private static func prettyPrintedJSONString(from data: Data) -> String {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .withoutEscapingSlashes])
            return String(data: prettyData, encoding: .utf8) ?? ""
        } catch {
            return String(data: data, encoding: .utf8) ?? ""
        }
    }
    
    /// 🌟 内部通用预处理：脱离外壳保护、Pretty 输出与截断盾
    private static func validateAndPreprocessResponse<T>(url: String, response: HTTPURLResponse?, data: Data?) throws -> (PTBaseStructModel<T>, String) {
        var result = PTBaseStructModel<T>()
        result.resultData = data
        
        guard let data = data, !data.isEmpty else {
            let error = PTNetworkError.dataEmpty
            logRequestFailure(url: url, error: AFError.createURLRequestFailed(error: error))
            throw error
        }
        
        let isMockData = (response == nil)
        if !isMockData && !isJSONResponse(response, data: data) {
            if let html = String(data: data, encoding: .utf8), html.containsHTMLTags() {
                let error = PTNetworkError.htmlResponse(html)
                logRequestFailure(url: url, error: AFError.createURLRequestFailed(error: error))
                throw error
            }
            var originalText = ""
            if UIApplication.shared.inferredEnvironment_PT == .debug { originalText = String(decoding: data, as: UTF8.self) }
            logRequestSuccess(url: url, jsonStr: originalText)
            result.originalString = originalText
            return (result, "")
        }
        
        let rawJsonString = String(data: data, encoding: .utf8) ?? ""
        result.originalString = rawJsonString
        
        if let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            let businessCode = jsonDict["code"] as? Int ?? 200
            let businessMsg = jsonDict["msg"] as? String ?? "Unknown error"
            if businessCode == 401 {
                PTGCDManager.gcdMain { NotificationCenter.default.post(name: NSNotification.Name("PTNetworkTokenExpiredNotification"), object: nil) }
                throw PTNetworkError.businessError(code: businessCode, msg: businessMsg)
            }
        }
        
        if UIApplication.shared.inferredEnvironment_PT != .appStore {
            let prettyStr = prettyPrintedJSONString(from: data)
            let maxLen = Int(Network.share.config.logMaxCount)
            let printStr = prettyStr.count > maxLen ? String(prettyStr.prefix(maxLen)) + "\n\n...[JSON过大，为保护控制台已截断]..." : prettyStr
            logRequestSuccess(url: url, jsonStr: printStr)
        }
        return (result, rawJsonString)
    }

    private static func prepareRequestHeaders(header: HTTPHeaders?, jsonRequest: Bool,cachePolicy: PTNetworkCachePolicy? = nil) -> HTTPHeaders {
        var apiHeader = header ?? HTTPHeaders()
        if jsonRequest {
            apiHeader["Content-Type"] = "application/json;charset=UTF-8"
            apiHeader["Accept"] = "application/json"
        }
        let finalCachePolicy = cachePolicy ?? Network.share.config.networkCacheOption
        apiHeader["cachePolicy"] = finalCachePolicy.rawValue
        apiHeader["cacheExpire"] = Network.share.config.networkCacheEXPTime
        apiHeader["dedupPolicy"] = Network.share.config.networkDudupOption.getOptionName()
        return addToken(to: apiHeader)
    }
    
    private static func createURLRequest(urlStr: URLConvertible, needGobal: Bool) async throws -> String {
        let original = try urlStr.asURL().absoluteString
        if original.hasPrefix("http") { return original }
        let gobalUrl = needGobal ? await Network.gobalUrl() : ""
        return gobalUrl + original
    }
    
    private typealias ResponseParser<T> = @Sendable (_ url: String, _ response: HTTPURLResponse?, _ data: Data?) throws -> PTBaseStructModel<T>
    private typealias UploadResponseParser<T> = @Sendable (_ url: String, _ response: HTTPURLResponse?, _ data: Data?) throws -> PTBaseStructModel<T>
    
    // MARK: - ================= 5. 底层核心执行引擎 =================

    private class func _internalRequestApi<T>(needGobal: Bool, urlStr: URLConvertible, method: HTTPMethod, header: HTTPHeaders?, parameters: Parameters?, cachePolicy: PTNetworkCachePolicy?, encoder: ParameterEncoding, jsonRequest: Bool, parser: @escaping ResponseParser<T>) async throws -> PTBaseStructModel<T> {
        let urlStr1 = try await createURLRequest(urlStr: urlStr, needGobal: needGobal)
        let apiHeader = prepareRequestHeaders(header: header, jsonRequest: jsonRequest, cachePolicy: cachePolicy)
        logRequestStart(url: urlStr1, parameters: parameters, headers: apiHeader, method: method)
        
        let session = Network.share.session
        var urlRequest = try URLRequest(url: urlStr1, method: method, headers: apiHeader)
        urlRequest = try encoder.encode(urlRequest, with: parameters)
        
        for plugin in Network.share.plugins { await plugin.willSend(&urlRequest) }
        
        if urlRequest.isMock {
            if let mockData = await NetworkCache.shared.read(request: urlRequest) { return try parser(urlStr1, nil, mockData) }
        }
        
        let policy: PTNetworkDedupPolicy = (urlRequest.cachePolicyType == .none) ? .none : .identical
        let finalRequest = urlRequest
        
        let realRequest: @Sendable () async throws -> PTBaseStructModel<T> = {
            let dataTask = session.request(finalRequest).serializingData()
            let response = await dataTask.response
            for plugin in Network.share.plugins { await plugin.didReceive(response.result, request: finalRequest, response: response.response) }
            
            switch response.result {
            case .success(let data):   return try parser(urlStr1, response.response, data)
            case .failure(let error):  logRequestFailure(url: urlStr1, error: error); throw error
            }
        }
        return try await RequestDeduplicator.shared.execute(request: urlRequest, policy: policy) { try await realRequest() }
    }

    private class func _internalRequestBodyAPI<T>(needGobal: Bool, urlStr: String, body: Data, header: HTTPHeaders?, method: HTTPMethod, cachePolicy: PTNetworkCachePolicy?, parser: @escaping ResponseParser<T>) async throws -> PTBaseStructModel<T> {
        let urlStr1 = try await createURLRequest(urlStr: urlStr, needGobal: needGobal)
        var newHeader = prepareRequestHeaders(header: header, jsonRequest: false, cachePolicy: cachePolicy)
        if newHeader["Content-Type"] == nil { newHeader["Content-Type"] = "text/plain" }
        
        var dic: [String: Any] = [:]
        if let jsonObject = try? JSONSerialization.jsonObject(with: body, options: []), let dictionary = jsonObject as? [String: Any] { dic = dictionary }
        logRequestStart(url: urlStr1, parameters: dic, headers: newHeader, method: method)
        
        let session = Network.share.session
        var urlRequest = try URLRequest(url: urlStr1, method: method, headers: newHeader)
        urlRequest.httpBody = body
        
        for plugin in Network.share.plugins { await plugin.willSend(&urlRequest) }
        
        if urlRequest.isMock {
            if let mockData = await NetworkCache.shared.read(request: urlRequest) { return try parser(urlStr1, nil, mockData) }
        }
        
        let policy: PTNetworkDedupPolicy = (urlRequest.cachePolicyType == .none) ? .none : .identical
        let finalRequest = urlRequest
        
        let realRequest: @Sendable () async throws -> PTBaseStructModel<T> = {
            let dataTask = session.upload(body, with: finalRequest).serializingData()
            let response = await dataTask.response
            for plugin in Network.share.plugins { await plugin.didReceive(response.result, request: finalRequest, response: response.response) }
            
            switch response.result {
            case .success(let data):   return try parser(urlStr1, response.response, data)
            case .failure(let error):  logRequestFailure(url: urlStr1, error: error); throw error
            }
        }
        return try await RequestDeduplicator.shared.execute(request: urlRequest, policy: policy) { try await realRequest() }
    }
    
    private class func _internalFileUpload<T>(needGobal: Bool, media: Any, path: URLConvertible, method: HTTPMethod, fileKey: String, params: [String: String]?, header: HTTPHeaders?, jsonRequest: Bool, parser: @escaping UploadResponseParser<T>) -> AsyncThrowingStream<(progress: Progress, response: PTBaseStructModel<T>?), Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let pathUrl = try await createURLRequest(urlStr: path, needGobal: needGobal)
                    let apiHeader = prepareRequestHeaders(header: header, jsonRequest: jsonRequest)
                    
                    let session = Network.share.session
                    session.upload(multipartFormData: { multipartFormData in
                        if let phasset = media as? PHAsset {
                            switch phasset.mediaType {
                            case .image:
                                Task {
                                    let image = await phasset.asyncImage()
                                    if let findImage = image {
                                        let canPNG = findImage.pngData() != nil
                                        if let imageData = findImage.pngData() ?? findImage.jpegData(compressionQuality: 0.6) {
                                            let ext = canPNG ? "png" : "jpg"
                                            multipartFormData.append(imageData, withName: fileKey, fileName: "image_\(Int(Date().timeIntervalSince1970)).\(ext)", mimeType: MimeTypeHelper.mimeType(for: ext))
                                        } else { continuation.finish(throwing: PTNetworkError.uploadDataError("Image data error")) }
                                    }
                                }
                            case .video:
                                phasset.converPHAssetToAVURLAsset { urlAsset in
                                    if let url = urlAsset?.url {
                                        let ext = url.pathExtension.lowercased()
                                        multipartFormData.append(url, withName: fileKey, fileName: "video_\(Int(Date().timeIntervalSince1970)).\(ext)", mimeType: MimeTypeHelper.mimeType(for: ext))
                                    } else { continuation.finish(throwing: PTNetworkError.uploadDataError("Video data error")) }
                                }
                            case .audio:
                                phasset.converPHAssetToAVURLAsset { urlAsset in
                                    if let url = urlAsset?.url {
                                        let ext = url.pathExtension.lowercased()
                                        multipartFormData.append(url, withName: fileKey, fileName: "audio_\(Int(Date().timeIntervalSince1970)).\(ext)", mimeType: MimeTypeHelper.mimeType(for: ext))
                                    }
                                }
                            default: continuation.finish(throwing: NSError(domain: "Unknow data error", code: 666))
                            }
                        } else if let findImage = media as? UIImage {
                            let canPNG = findImage.pngData() != nil
                            if let imageData = findImage.pngData() ?? findImage.jpegData(compressionQuality: 0.6) {
                                let ext = canPNG ? "png" : "jpg"
                                multipartFormData.append(imageData, withName: fileKey, fileName: "image_\(Int(Date().timeIntervalSince1970)).\(ext)", mimeType: MimeTypeHelper.mimeType(for: ext))
                            } else { continuation.finish(throwing: NSError(domain: "Image data error", code: 666)) }
                        } else if let findUrl = media as? URL {
                            if findUrl.isFileURL {
                                let uploadURL: URL
                                if findUrl.path.contains("File Provider Storage") || findUrl.path.contains("com.apple.FileProvider") {
                                    let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(findUrl.lastPathComponent)
                                    try? FileManager.default.removeItem(at: tmpURL)
                                    try? FileManager.default.copyItem(at: findUrl, to: tmpURL)
                                    uploadURL = tmpURL
                                } else { uploadURL = findUrl }
                                let ext = uploadURL.pathExtension.lowercased()
                                multipartFormData.append(uploadURL, withName: fileKey, fileName: uploadURL.lastPathComponent, mimeType: MimeTypeHelper.mimeType(for: ext))
                            } else { continuation.finish(throwing: NSError(domain: "Need to down load first", code: 666)) }
                        } else if let findString = media as? String, let findUrl = URL(string: findString) {
                            if findUrl.isFileURL {
                                let uploadURL: URL
                                if findUrl.path.contains("File Provider Storage") || findUrl.path.contains("com.apple.FileProvider") {
                                    let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(findUrl.lastPathComponent)
                                    try? FileManager.default.removeItem(at: tmpURL)
                                    try? FileManager.default.copyItem(at: findUrl, to: tmpURL)
                                    uploadURL = tmpURL
                                } else { uploadURL = findUrl }
                                let ext = uploadURL.pathExtension.lowercased()
                                multipartFormData.append(uploadURL, withName: fileKey, fileName: uploadURL.lastPathComponent, mimeType: MimeTypeHelper.mimeType(for: ext))
                            } else { continuation.finish(throwing: NSError(domain: "Need to down load first", code: 666)) }
                        }
                        
                        params?.forEach { key, value in
                            if let data = value.data(using: .utf8) { multipartFormData.append(data, withName: key) }
                        }
                    }, to: pathUrl, method: method, headers: apiHeader)
                    .uploadProgress { progress in continuation.yield((progress, nil)) }
                    .response { resp in
                        switch resp.result {
                        case .success(_):
                            do {
                                let parsed = try parser(pathUrl, resp.response, resp.data)
                                continuation.yield((Progress(totalUnitCount: 1), parsed))
                                continuation.finish()
                            } catch { continuation.finish(throwing: error) }
                        case .failure(let error):
                            logRequestFailure(url: pathUrl, error: error)
                            continuation.finish(throwing: error)
                        }
                    }
                } catch { continuation.finish(throwing: error) }
            }
        }
    }
    
    private class func _internalImageUpload<T>(needGobal: Bool, images: [UIImage]?, path: URLConvertible, method: HTTPMethod, fileKey: [String], params: [String: String]?, header: HTTPHeaders?, jsonRequest: Bool, pngData: Bool, parser: @escaping UploadResponseParser<T>) -> AsyncThrowingStream<(progress: Progress, response: PTBaseStructModel<T>?), Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let pathUrl = try await createURLRequest(urlStr: path, needGobal: needGobal)
                    let apiHeader = prepareRequestHeaders(header: header, jsonRequest: jsonRequest)
                    
                    let session = Network.share.session
                    session.upload(multipartFormData: { multipartFormData in
                        images?.enumerated().forEach { index, image in
                            autoreleasepool {
                                let data = pngData ? image.pngData() : image.jpegData(compressionQuality: 0.6)
                                guard let imageData = data else { return }
                                let key = fileKey[safe: index] ?? "image"
                                let ext = pngData ? "png" : "jpg"
                                multipartFormData.append(imageData, withName: key, fileName: "image_\(index).\(ext)", mimeType: pngData ? "image/png" : "image/jpeg")
                            }
                        }
                        params?.forEach { key, value in
                            if let data = value.data(using: .utf8) { multipartFormData.append(data, withName: key) }
                        }
                    }, to: pathUrl, method: method, headers: apiHeader)
                    .uploadProgress { progress in continuation.yield((progress, nil)) }
                    .response { resp in
                        switch resp.result {
                        case .success(_):
                            do {
                                let parsed = try parser(pathUrl, resp.response, resp.data)
                                continuation.yield((Progress(totalUnitCount: 1), parsed))
                                continuation.finish()
                            } catch { continuation.finish(throwing: error) }
                        case .failure(let error):
                            logRequestFailure(url: pathUrl, error: error)
                            continuation.finish(throwing: error)
                        }
                    }
                } catch { continuation.finish(throwing: error) }
            }
        }
    }
    
    // MARK: - ================= 6. 🌟 强类型解析层：SmartCodable 暴露接口 =================

    private static func parseCodableResponse<T: SmartCodableX>(url: String, response: HTTPURLResponse?, data: Data?, modelType: T.Type?) throws -> PTBaseStructModel<T> {
        var (result, jsonString) = try validateAndPreprocessResponse(url: url, response: response, data: data) as (PTBaseStructModel<T>, String)
        if !jsonString.isEmpty, let modelType = modelType {
            if let model = modelType.deserialize(from: jsonString) {
                result.customerModel = model
            } else { throw PTNetworkError.modelExplainFail }
        }
        return result
    }

    /// 🌟 便捷重载方法：当接口只返回成功/失败时使用，底层自动代劳传入占位模型
    class public func requestCodableApi(needGobal: Bool = true, urlStr: URLConvertible, method: HTTPMethod = .post, header: HTTPHeaders? = nil, parameters: Parameters? = nil, cachePolicy: PTNetworkCachePolicy? = nil, encoder: ParameterEncoding = URLEncoding.default, jsonRequest: Bool = false) async throws -> PTBaseStructModel<PTDummyModel> {
        return try await self.requestCodableApi(needGobal: needGobal, urlStr: urlStr, method: method, header: header, parameters: parameters, cachePolicy: cachePolicy, modelType: PTDummyModel.self, encoder: encoder, jsonRequest: jsonRequest)
    }

    /// 核心项目调用总接口
    class public func requestCodableApi<T: SmartCodableX>(needGobal: Bool = true, urlStr: URLConvertible, method: HTTPMethod = .post, header: HTTPHeaders? = nil, parameters: Parameters? = nil, cachePolicy: PTNetworkCachePolicy? = nil, modelType: T.Type? = nil, encoder: ParameterEncoding = URLEncoding.default, jsonRequest: Bool = false) async throws -> PTBaseStructModel<T> {
        let typeBox = PTSendableTypeBox(modelType)
        return try await _internalRequestApi(needGobal: needGobal, urlStr: urlStr, method: method, header: header, parameters: parameters, cachePolicy: cachePolicy, encoder: encoder, jsonRequest: jsonRequest) { url, response, data in
            try parseCodableResponse(url: url, response: response, data: data, modelType: typeBox.type)
        }
    }
    
    public class func requestCodableBodyAPI<T: SmartCodableX>(needGobal: Bool = true, urlStr: String, body: Data, header: HTTPHeaders? = nil, method: HTTPMethod = .post,
        cachePolicy: PTNetworkCachePolicy? = nil, modelType: T.Type? = nil) async throws -> PTBaseStructModel<T> {
        let typeBox = PTSendableTypeBox(modelType)
        return try await _internalRequestBodyAPI(needGobal: needGobal, urlStr: urlStr, body: body, header: header, method: method, cachePolicy: cachePolicy) { url, response, data in
            try parseCodableResponse(url: url, response: response, data: data, modelType: typeBox.type)
        }
    }
    
    class public func fileCodableUpload<T: SmartCodableX>(needGobal: Bool = true, media: Any, path: URLConvertible, method: HTTPMethod = .post, fileKey: String = "",
        params: [String: String]? = nil, header: HTTPHeaders? = nil, modelType: T.Type? = nil, jsonRequest: Bool = false) -> AsyncThrowingStream<(progress: Progress, response: PTBaseStructModel<T>?), Error> {
        let typeBox = PTSendableTypeBox(modelType)
        return _internalFileUpload(needGobal: needGobal, media: media, path: path, method: method, fileKey: fileKey, params: params, header: header, jsonRequest: jsonRequest) { url, response, data in
            return try parseCodableResponse(url: url, response: response, data: data, modelType: typeBox.type)
        }
    }
    
    class public func imageCodableUpload<T: SmartCodableX>(needGobal: Bool = true, images: [UIImage]?, path: URLConvertible, method: HTTPMethod = .post, fileKey: [String] = ["images"], params: [String: String]? = nil, header: HTTPHeaders? = nil, modelType: T.Type? = nil, jsonRequest: Bool = false, pngData: Bool = true) -> AsyncThrowingStream<(progress: Progress, response: PTBaseStructModel<T>?), Error> {
        let typeBox = PTSendableTypeBox(modelType)
        return _internalImageUpload(needGobal: needGobal, images: images, path: path, method: method, fileKey: fileKey, params: params, header: header, jsonRequest: jsonRequest, pngData: pngData) { url, response, data in
            return try parseCodableResponse(url: url, response: response, data: data, modelType: typeBox.type)
        }
    }

    // MARK: - ================= 7. ⚠️ 动态兼容层：KakaJSON 旧版保留接口 =================

    private static func parseResponse(url: String, response: HTTPURLResponse?, data: Data?, modelType: Convertible.Type?) throws -> PTBaseStructModel<Any> {
        var (result, jsonString) = try validateAndPreprocessResponse(url: url, response: response, data: data) as (PTBaseStructModel<Any>, String)
        if !jsonString.isEmpty, let modelType = modelType {
            if let model = jsonString.kj.model(modelType) {
                result.customerModel = model
            } else { throw PTNetworkError.modelExplainFail }
        }
        return result
    }

    public class func requestBodyAPI(needGobal: Bool = true, urlStr: String, body: Data, header: HTTPHeaders? = nil, method: HTTPMethod = .post, cachePolicy: PTNetworkCachePolicy? = nil, modelType: Convertible.Type? = nil) async throws -> PTBaseStructModel<Any> {
        let typeBox = PTSendableTypeBox(modelType)
        return try await _internalRequestBodyAPI(needGobal: needGobal, urlStr: urlStr, body: body, header: header, method: method, cachePolicy: cachePolicy) { url, response, data in
            try parseResponse(url: url, response: response, data: data, modelType: typeBox.type)
        }
    }
    
    class public func requestApi(needGobal: Bool = true, urlStr: URLConvertible, method: HTTPMethod = .post, header: HTTPHeaders? = nil, parameters: Parameters? = nil,
        cachePolicy: PTNetworkCachePolicy? = nil, modelType: Convertible.Type? = nil, encoder: ParameterEncoding = URLEncoding.default, jsonRequest: Bool = false) async throws -> PTBaseStructModel<Any> {
        let typeBox = PTSendableTypeBox(modelType)
        return try await _internalRequestApi(needGobal: needGobal, urlStr: urlStr, method: method, header: header, parameters: parameters, cachePolicy: cachePolicy, encoder: encoder, jsonRequest: jsonRequest) { url, response, data in
            try parseResponse(url: url, response: response, data: data, modelType: typeBox.type)
        }
    }
    
    class public func fileUpload(needGobal: Bool = true, media: Any, path: URLConvertible, method: HTTPMethod = .post, fileKey: String = "", params: [String: String]? = nil, header: HTTPHeaders? = nil, modelType: Convertible.Type? = nil, jsonRequest: Bool = false) -> AsyncThrowingStream<(progress: Progress, response: PTBaseStructModel<Any>?), Error> {
        let typeBox = PTSendableTypeBox(modelType)
        return _internalFileUpload(needGobal: needGobal, media: media, path: path, method: method, fileKey: fileKey, params: params, header: header, jsonRequest: jsonRequest) { url, response, data in
            return try parseResponse(url: url, response: response, data: data, modelType: typeBox.type)
        }
    }
    
    class public func imageUpload(needGobal: Bool = true, images: [UIImage]?, path: URLConvertible, method: HTTPMethod = .post, fileKey: [String] = ["images"], params: [String: String]? = nil, header: HTTPHeaders? = nil, modelType: Convertible.Type? = nil, jsonRequest: Bool = false, pngData: Bool = true) -> AsyncThrowingStream<(progress: Progress, response: PTBaseStructModel<Any>?), Error> {
        let typeBox = PTSendableTypeBox(modelType)
        return _internalImageUpload(needGobal: needGobal, images: images, path: path, method: method, fileKey: fileKey, params: params, header: header, jsonRequest: jsonRequest, pngData: pngData) { url, response, data in
            return try parseResponse(url: url, response: response, data: data, modelType: typeBox.type)
        }
    }
    
    // MARK: - ================= 8. 下载引擎与流式控制 =================

    private lazy var downloadSession: Session = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Network.share.config.downloadRequsetTime
        config.timeoutIntervalForResource = Network.share.config.downloadEndTime
        config.httpMaximumConnectionsPerHost = 6
        var protocols = config.protocolClasses ?? []
        protocols.insert(PTCustomHTTPProtocol.self, at: 0)
        config.protocolClasses = protocols
        return Session(configuration: config)
    }()
    
    actor DownloadStore {
        var tasks: [String: DownloadTask] = [:]
        public func get(_ url: String) -> DownloadTask? { tasks[url] }
        func set(_ url: String, task: DownloadTask) { tasks[url] = task }
        func remove(_ url: String) { tasks[url] = nil }
    }
    private let store = DownloadStore()
    
    final class DownloadTask: @unchecked Sendable {
        let url: String
        let destination: @Sendable (URL, HTTPURLResponse) -> (URL, DownloadRequest.Options)
        var request: DownloadRequest?
        var resumeData: Data?
        
        private var progressHandlers: [FileDownloadProgress] = []
        private var successHandlers: [FileDownloadSuccess] = []
        private var failHandlers: [FileDownloadFail] = []
        private var lastProgressTime: CFTimeInterval = 0
        private let lock = NSLock()
        private(set) var isDownloading: Bool = false
        
        init(url: String, destination: @escaping @Sendable (URL, HTTPURLResponse) -> (URL, DownloadRequest.Options)) {
            self.url = url
            self.destination = destination
        }
        
        func appendHandlers(progress: FileDownloadProgress?, success: FileDownloadSuccess?, fail: FileDownloadFail?) {
            lock.lock()
            defer { lock.unlock() }
            if let p = progress { progressHandlers.append(p) }
            if let s = success { successHandlers.append(s) }
            if let f = fail { failHandlers.append(f) }
        }
        
        private func clearHandlers() {
            progressHandlers.removeAll()
            successHandlers.removeAll()
            failHandlers.removeAll()
        }
        
        func start(session: Session) {
            lock.lock()
            if isDownloading { lock.unlock(); return }
            isDownloading = true
            lock.unlock()
            
            if let data = resumeData { request = session.download(resumingWith: data, to: destination) }
            else { request = session.download(url, to: destination) }
            
            request?.downloadProgress(queue: .main) { [weak self] p in
                guard let self = self else { return }
                let now = CACurrentMediaTime()
                if now - self.lastProgressTime > 0.1 || p.isFinished {
                    self.lastProgressTime = now
                    self.lock.lock()
                    let handlers = self.progressHandlers
                    self.lock.unlock()
                    for cb in handlers { cb(p.completedUnitCount, p.totalUnitCount, p.fractionCompleted) }
                }
            }
            
            request?.response { [weak self] resp in
                guard let self = self else { return }
                self.lock.lock()
                self.isDownloading = false
                self.resumeData = nil
                let currentFails = self.failHandlers
                let currentSuccesses = self.successHandlers
                self.clearHandlers()
                self.lock.unlock()
                
                if let error = resp.error {
                    if error.isExplicitlyCancelledError || (error.underlyingError as? URLError)?.code == .cancelled {
                        self.resumeData = resp.resumeData
                    } else { Task { await Network.share.store.remove(self.url) } }
                    currentFails.forEach { $0(error) }
                } else {
                    Task { await Network.share.store.remove(self.url) }
                    currentSuccesses.forEach { $0(resp) }
                }
            }
        }
        
        func suspend() {
            lock.lock()
            isDownloading = false
            lock.unlock()
            request?.cancel { [weak self] data in
                self?.resumeData = data
                self?.request = nil
            }
        }
        
        func cancel() {
            lock.lock()
            isDownloading = false
            lock.unlock()
            request?.cancel()
        }
    }
    
    public func download(fileUrl: String, saveFilePath: String, queue: DispatchQueue? = .main, progress: FileDownloadProgress? = nil, success: FileDownloadSuccess? = nil, fail: FileDownloadFail? = nil) {
        guard fileUrl.isURL(), !fileUrl.stringIsEmpty() else { fail?(AFError.invalidURL(url: "PT URL Error")); return }
        let dest: @Sendable (URL, HTTPURLResponse) -> (URL, DownloadRequest.Options) = { _, _ in
            return (URL(fileURLWithPath: saveFilePath), [.removePreviousFile, .createIntermediateDirectories])
        }
        
        Task {
            let task: DownloadTask
            if let existing = await store.get(fileUrl) {
                task = existing
                task.appendHandlers(progress: progress, success: success, fail: fail)
            } else {
                task = DownloadTask(url: fileUrl, destination: dest)
                task.appendHandlers(progress: progress, success: success, fail: fail)
                await store.set(fileUrl, task: task)
            }
            if !task.isDownloading { task.start(session: downloadSession) }
        }
    }
    
    public func download(fileUrl: String, saveFilePath: String, progress: FileDownloadProgress? = nil) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            self.download(fileUrl: fileUrl, saveFilePath: saveFilePath, queue: nil, progress: progress, success: { response in
                if let fileURL = response.fileURL { continuation.resume(returning: fileURL) }
                else { continuation.resume(throwing: PTNetworkError.downloadFail) }
            }, fail: { error in continuation.resume(throwing: error ?? PTNetworkError.downloadFail) })
        }
    }
    
    public func suspend(fileUrl: String) { Task { await store.get(fileUrl)?.suspend() } }
    public func resume(fileUrl: String)  { Task { if let task = await store.get(fileUrl) { task.start(session: downloadSession) } } }
    public func cancel(fileUrl: String)  { Task { if let task = await store.get(fileUrl) { await store.remove(fileUrl); task.cancel() } } }
    
    /// 🌟 全新现代化的流式下载方法，支持在业务层循环获取进度
    public func downloadAsyncStream(fileUrl: String, saveFilePath: String) -> AsyncThrowingStream<(progress: Double, fileURL: URL?), Error> {
        AsyncThrowingStream { continuation in
            self.download(fileUrl: fileUrl, saveFilePath: saveFilePath, queue: nil) { _, _, progress in
                continuation.yield((progress, nil))
            } success: { response in
                if let fileURL = response.fileURL {
                    continuation.yield((1.0, fileURL))
                    continuation.finish()
                } else { continuation.finish(throwing: PTNetworkError.downloadFail) }
            } fail: { error in continuation.finish(throwing: error ?? PTNetworkError.downloadFail) }
        }
    }
}

// MARK: - ================= 9. 监控探针与耗时剖析 =================

public class NetworkSessionDelegate:NSObject,URLSessionTaskDelegate {
    public func urlSession(_ session:URLSession,task:URLSessionTask,didFinishCollecting metrics: URLSessionTaskMetrics) {
        PTNSLogConsole("网络任务实例化和完成之间的时间间隔（taskInterval）: \(String(describing: metrics.taskInterval))")
        PTNSLogConsole("网络任务重定向次数（redirectCount）: \(String(describing: metrics.redirectCount))")
        for metric in metrics.transactionMetrics { handleTransactionMetric(metric) }
    }

    private func handleTransactionMetric(_ metric:URLSessionTaskTransactionMetrics) {
        PTNSLogConsole("----------网络时间方面-----")
        PTNSLogConsole("开始获取资源的时间（fetchStartDate）: \( String(describing: metric.fetchStartDate))")
        PTNSLogConsole("域名解析开始的时间（domainLookupStartDate）: \(String(describing: metric.domainLookupStartDate))")
        PTNSLogConsole("域名解析结束的时间（domainLookupEndDate）: \(String(describing: metric.domainLookupEndDate))")
        PTNSLogConsole("开始建立TCP连接的时间(connectStartDate): \(String(describing: metric.connectStartDate))")
        PTNSLogConsole("完成建立TCP连接的时间(connectEndDate): \(String(describing: metric.connectEndDate))")
        PTNSLogConsole("开始TLS安全握手的时间（secureConnectionStartDate）: \(String(describing: metric.secureConnectionStartDate))")
        PTNSLogConsole("完成TLS安全握手的时间（secureConnectionEndDate）: \(String(describing: metric.secureConnectionEndDate))")
        PTNSLogConsole("请求发送的时间（requestStartDate）: \(String(describing: metric.requestStartDate))")
        PTNSLogConsole("请求结束的时间（requestEndDate）: \(String(describing: metric.requestEndDate))")
        PTNSLogConsole("收到响应的第一个字节的时间（responseStartDate）: \(String(describing: metric.responseStartDate))")
        PTNSLogConsole("收到响应的最后一个字节的时间（responseEndDate）: \(String(describing: metric.responseEndDate))")

        if let domainLookupEndDate = metric.domainLookupEndDate,let domainLookupStartDate = metric.domainLookupStartDate {
            PTNSLogConsole("域名解析时长：\(domainLookupEndDate.timeIntervalSince(domainLookupStartDate) * 1000) 秒")
        } else { PTNSLogConsole("域名解析时长无法计算") }

        if let tcpConnectionEndDate = metric.connectEndDate,let tcpConnectionStartDate = metric.connectStartDate {
            PTNSLogConsole("TCP连接时长: \(tcpConnectionEndDate.timeIntervalSince(tcpConnectionStartDate) * 1000) 秒")
        } else { PTNSLogConsole("TCP连接时长无法计算") }

        if let tlsHandshakeEndDate = metric.secureConnectionEndDate,let tlsHandshakeStartDate = metric.secureConnectionStartDate {
            PTNSLogConsole("TLS安全握手时长: \(tlsHandshakeEndDate.timeIntervalSince(tlsHandshakeStartDate) * 1000) 秒")
        } else { PTNSLogConsole("TLS安全握手时长无法计算") }

        if let responseEndDate = metric.responseEndDate,let requestStartDate = metric.requestStartDate {
            PTNSLogConsole("请求响应时长【从请求开发到请求结束】：\(responseEndDate.timeIntervalSince(requestStartDate)) 秒")
        } else { PTNSLogConsole("请求响应时长无法计算") }

        if let connectionEndDate = metric.responseStartDate,let connectionStartDate = metric.responseStartDate {
            PTNSLogConsole("响应时长: \(connectionEndDate.timeIntervalSince(connectionStartDate) * 1000) 秒")
        } else { PTNSLogConsole("响应时长无法计算") }

        PTNSLogConsole("----------网络数据监控方面（iOS13+有效）-----")
        PTNSLogConsole("iOS13+发送前编码之前请求体数据的大小(countOfRequestBodyBytesBeforeEncoding):\(metric.countOfRequestBodyBytesBeforeEncoding)")
        PTNSLogConsole("iOS13+发送的请求头字节数(countOfRequestHeaderBytesSent):\(metric.countOfRequestHeaderBytesSent)")
        PTNSLogConsole("iOS13+发送前编码之前请求体数据的大小(countOfResponseBodyBytesAfterDecoding):\(metric.countOfResponseBodyBytesAfterDecoding)")
        PTNSLogConsole("iOS13+传递给代理或完成处理程序的数据的大小(countOfResponseBodyBytesAfterDecoding):\(metric.countOfResponseBodyBytesAfterDecoding)")
        PTNSLogConsole("iOS13+接收的响应体字节数(countOfResponseBodyBytesReceived):\(metric.countOfResponseBodyBytesReceived)")
        PTNSLogConsole("iOS13+接收的响应头字节数(countOfResponseHeaderBytesReceived):\(metric.countOfResponseHeaderBytesReceived)")

        PTNSLogConsole("----------网络协议基础属性方面-----")
        PTNSLogConsole("使用的网络协议名称(networkProtocolName): \(metric.networkProtocolName ?? "Unknown")")
        PTNSLogConsole("iOS13+远程接口的IP地址(remoteAddress): \(String(describing: metric.remoteAddress))")
        PTNSLogConsole("iOS13 +本地接口的 IP 地址(localAddress): \(String(describing: metric.localAddress))")
        PTNSLogConsole("远程接口的端口号(remotePort): \(String(describing: metric.remotePort))")
        PTNSLogConsole("本地接口的端口号(localPort): \(String(describing: metric.localPort))")
        PTNSLogConsole("TLS密码套件(negotiatedTLSCipherSuite): \(String(describing: metric.negotiatedTLSCipherSuite?.rawValue))")
        PTNSLogConsole("TLS协议版本(negotiatedTLSProtocolVersion): \(String(describing: metric.negotiatedTLSProtocolVersion?.rawValue))")
        PTNSLogConsole("连接是否经由蜂窝网络(isCellular): \(metric.isCellular)")
        PTNSLogConsole("连接是否经由高成本接口(isExpensive): \(metric.isExpensive)")
        PTNSLogConsole("连接是否经由受限制的接口(isConstrained): \(metric.isConstrained)")
        PTNSLogConsole("是否使用了代理连接来获取资源(isProxyConnection): \(metric.isProxyConnection)")
        PTNSLogConsole("任务是否使用了重用连接来获取资源(isReusedConnection): \(metric.isReusedConnection)")
        PTNSLogConsole("连接是否成功协商了多路径协议(isMultipath): \(metric.isMultipath)")
        PTNSLogConsole("标识资源的加载方式(resourceFetchType): \(metric.resourceFetchType.rawValue)")
        
        switch(metric.domainResolutionProtocol) {
        case .unknown: PTNSLogConsole("iOS14+ 域名解析所使用的协议(domainResolutionProtocol): unknown")
        case .udp:     PTNSLogConsole("iOS14+ 域名解析所使用的协议(domainResolutionProtocol): 表示使用了udp 协议进行域名解析")
        case .tcp:     PTNSLogConsole("iOS14+ 域名解析所使用的协议(domainResolutionProtocol): 表示使用了tcp 协议进行域名解析")
        case .tls:     PTNSLogConsole("iOS14+ 域名解析所使用的协议(domainResolutionProtocol):  表示使用了tls协议进行域名解析")
        case .https:   PTNSLogConsole("iOS14+ 域名解析所使用的协议(domainResolutionProtocol): 表示使用了https 协议进行域名解析")
        @unknown default: PTNSLogConsole("iOS14+ 域名解析所使用的协议(domainResolutionProtocol): unknown")
        }

        PTNSLogConsole("request url:\(String(describing: metric.request.url))")
        PTNSLogConsole("request httpMethod:\(String(describing: metric.request.httpMethod))")
        PTNSLogConsole("request timeoutInterval:\(metric.request.timeoutInterval)")
        PTNSLogConsole("-----request allHTTPHeaderFields---\n\(String(describing: metric.request.allHTTPHeaderFields?.debugDescription))\n-----request allHTTPHeaderFields end-----")
        PTNSLogConsole("request httpBody:\(String(describing: metric.request.httpBody))")

        let httpURLResponse:HTTPURLResponse? = metric.response as? HTTPURLResponse ?? nil
        PTNSLogConsole("response statusCode:\(String(describing: httpURLResponse?.statusCode))")
        PTNSLogConsole("-----response allHeaderFields:\n\(String(describing: httpURLResponse?.allHeaderFields))\n-----response allHeaderFields end-----")
    }
}
