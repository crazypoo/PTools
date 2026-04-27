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

public enum PTNetworkError: Error, LocalizedError, CustomNSError {
    case noNetwork
    case checkIPFail
    case downloadFail
    case jsonExplainFail
    case modelExplainFail
    
    case dataEmpty
    case htmlResponse(String)
    case uploadDataError(String)

    // MARK: - 1. LocalizedError (提供给界面展示的文本提示)
    public var errorDescription: String? {
        switch self {
        case .noNetwork:        return "PT Network no network".localized()
        case .checkIPFail:      return "IP address error"
        case .downloadFail:     return "PT Network download fail".localized()
        case .jsonExplainFail:  return "PT Network json fail".localized()
        case .modelExplainFail: return "PT Network model fail".localized()
            
            // 🌟 新增的描述
        case .dataEmpty:              return "Data empty"
        case .htmlResponse(let html): return html
        case .uploadDataError(let msg): return msg
        }
    }
    
    // MARK: - 2. CustomNSError (保留原有的自定义错误码，向下兼容)
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
        }
    }
    
    // 统一的错误 Domain，方便在控制台过滤和排查日志
    public static var errorDomain: String {
        return "com.pt.network.error"
    }
}

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
public typealias FileDownloadSuccess = (_ reponse:AFDownloadResponse<URL?>) -> ()
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

// MARK: - 网络运行状态监听
// 🌟 1. 同样移除 @objcMembers，使用 final 提升性能
public final class PTNetWorkStatus: @unchecked Sendable {
    
    public static let shared = PTNetWorkStatus()
    
    // 统一只保留一个监听队列，避免重复开销
    private let queue = DispatchQueue(label: "pt.network.status.monitor")
    private let ctNetworkInfo = CTTelephonyNetworkInfo()
    
    // 私有化初始化
    private init() {}
    
    // 保留你原本判断蜂窝网络类型的逻辑 (这里不变，只是去掉了隐式 self)
    private func getCellularType() -> NetworkCellularType {
        let radioAccess: String
        guard let id = ctNetworkInfo.dataServiceIdentifier else { return .ALL }
        guard let ra = ctNetworkInfo.serviceCurrentRadioAccessTechnology?[id] else { return .ALL }
        radioAccess = ra

        if radioAccess == CTRadioAccessTechnologyNRNSA || radioAccess == CTRadioAccessTechnologyNR {
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
            return .Cellular4G
        }
    }
    
    // 🌟 2. 核心大招：使用 AsyncStream 替代闭包回调
    /// 监听网络状态的异步流
    public var statusStream: AsyncStream<NetWorkStatus> {
        AsyncStream { continuation in
            let monitor = NWPathMonitor()
            
            monitor.pathUpdateHandler = { [weak self] path in
                guard let self = self else { return }
                
                let status: NetWorkStatus
                if path.status == .satisfied {
                    if path.usesInterfaceType(.wifi) {
                        status = .wifi
                    } else if path.usesInterfaceType(.cellular) {
                        status = .wwan(type: self.getCellularType())
                    } else if path.usesInterfaceType(.wiredEthernet) {
                        status = .wiredEthernet
                    } else if path.usesInterfaceType(.loopback) {
                        status = .loopback
                    } else if path.usesInterfaceType(.other) {
                        status = .other
                    } else if path.isExpensive {
                        status = .checking
                    } else {
                        status = .unknown
                    }
                } else if path.status == .unsatisfied {
                    status = .notReachable
                } else if path.status == .requiresConnection {
                    status = .requiresConnection
                } else {
                    status = .unknown
                }
                
                // 将最新状态发送到流中
                continuation.yield(status)
            }
            
            // 启动监听
            monitor.start(queue: self.queue)
            
            // 🌟 3. 自动销毁机制：当外部不再监听 (Task 被取消) 时，自动释放 monitor
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
        retryLimitSnapshot = Network.share.config.retryTimes
        baseDelaySnapshot = Network.share.config.retryDelay
        statusCodeToRetry = Network.share.config.retryAPIStatusCode
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
        // ❌ 1. 主动取消不重试
        if let afErr = error as? AFError, afErr.isExplicitlyCancelledError {
            return completion(.doNotRetry)
        }
        
        // 🚨 新增：拦截底层 URLSession 的取消错误 (-999)
        // 直接安全转换为 URLError 进行判断，避免与下方的 nsError 变量名冲突
        if let urlError = error as? URLError, urlError.code == .cancelled {
            return completion(.doNotRetry)
        }

        // ❌ 2. 无网络直接不重试（🔥关键）
        if !NetworkReachability.shared.isReachable {
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
        ]
        let isTemporaryNetworkIssue = isURLErrorDomain && temporaryURLErrors.contains(urlErrorCode)
        
        let canRetryByError = error.isNetworkError || isTemporaryNetworkIssue
        let canRetryByStatus = shouldRetry(statusCode: statusCode)
        
        // ❌ 3. 超过次数 or 不满足条件
        guard request.retryCount < retryLimitSnapshot, (canRetryByError || canRetryByStatus) else {
            return completion(.doNotRetry)
        }
        
        // ⚠️ 4. 弱网策略（优化体验）
        let isExpensive = NetworkReachability.shared.isExpensive

        let delay: TimeInterval
        
        if isExpensive {
            // 蜂窝网络 → 降低重试频率
            delay = min(baseDelaySnapshot * 2.0, maxDelay)
        } else {
            // WiFi → 正常指数退避
            let nth = max(1, request.retryCount + 1)
            delay = min(
                baseDelaySnapshot * pow(2.0, Double(nth - 1)) +
                Double.random(in: 0...jitter),
                maxDelay
            )
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
    /// 请求发出前
    func willSend(_ request: inout URLRequest) async
    
    /// 收到响应
    func didReceive(_ result: Result<Data, AFError>, request: URLRequest, response: HTTPURLResponse?) async
}

public struct CacheObject: Codable {
    let data: Data
    let expireTime: TimeInterval
    var lastAccessTime: TimeInterval   // ⭐ 新增
}

//private var kCacheDataKey = 888888888

public enum PTNetworkCachePolicy:String, Sendable {
    case none                   // 不缓存
    case cacheOnly              // 只用缓存
    case networkOnly            // 只走网络
    case cacheElseNetwork       // 先缓存再网络（默认推荐）
    case networkElseCache       // 网络失败再用缓存
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
    
    // MARK: - Key
    private func cacheKey(_ request: URLRequest) -> String {
        let url = request.url?.absoluteString ?? ""
        let sortedQuery = request.url?
            .query?
            .split(separator: "&")
            .sorted()
            .joined(separator: "&") ?? ""
        
        let body = request.httpBody?
            .sortedJSONData() ?? Data()

        return (url + sortedQuery + body.base64EncodedString()).md5
    }
    
    // MARK: - Save
    func save(data: Data, request: URLRequest, expire: TimeInterval) {
        let key = cacheKey(request)
        let now = Date().timeIntervalSince1970
        let obj = CacheObject(data: data,
                              expireTime: now + expire,
                              lastAccessTime: now)
        
        guard let encoded = try? JSONEncoder().encode(obj) else { return }
        memoryCache.setObject(encoded as NSData, forKey: key as NSString)
        
        let path = self.diskPath.nsString.appendingPathComponent(key)
        // 💡 异步脱离：让磁盘写入去后台默默执行，绝不阻塞 actor 响应下一个请求
        Task.detached(priority: .background) {
            try? encoded.write(to: URL(fileURLWithPath: path))
        }
    }
    
    // MARK: - Read
    func read(request: URLRequest) -> Data? {
        let key = cacheKey(request)
        let now = Date().timeIntervalSince1970

        // 1. 尝试从内存读取 (极速返回路径)
        if let data = memoryCache.object(forKey: key as NSString) as Data?,
           var obj = try? JSONDecoder().decode(CacheObject.self, from: data),
           obj.expireTime > now {
            
            // 💡 核心修复 1：命中内存缓存时，绝对不要触发 save() 去全量写入磁盘！
            // 只需要更新内存中的 lastAccessTime 即可，避免瞬间产生大量的磁盘 barrier 任务
            obj.lastAccessTime = now
            if let encoded = try? JSONEncoder().encode(obj) {
                memoryCache.setObject(encoded as NSData, forKey: key as NSString)
            }
            return obj.data
        }
        
        // 2. 尝试从磁盘读取
        let path = (self.diskPath as NSString).appendingPathComponent(key)
        if let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           var obj = try? JSONDecoder().decode(CacheObject.self, from: data),
           obj.expireTime > now {
            
            obj.lastAccessTime = now
            if let encoded = try? JSONEncoder().encode(obj) {
                // 同步到内存
                memoryCache.setObject(encoded as NSData, forKey: key as NSString)
                // 脱离更新磁盘访问时间
                Task.detached(priority: .background) {
                    try? encoded.write(to: URL(fileURLWithPath: path))
                }
            }
            return obj.data
        }
        return nil
    }

    // MARK: - Clear
    public func clearAll() {
        memoryCache.removeAllObjects()
        try? FileManager.default.removeItem(atPath: diskPath)
    }
    
    public func cleanIfNeeded() {
        let now = Date().timeIntervalSince1970
        guard now - lastCleanTime > Network.share.config.cleanCachePreSec else { return } // 1分钟最多一次
        lastCleanTime = now
        
        // 保持后台清理，不卡主线程和 actor
        Task.detached(priority: .background) {
            self._cleanDisk()
        }
    }
    
    private nonisolated func _cleanDisk() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: URL(fileURLWithPath: diskPath),
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return }

        var totalSize: Int64 = 0
        var cacheFiles: [(url: URL, size: Int64, lastAccess: TimeInterval)] = []

        let now = Date().timeIntervalSince1970

        for fileURL in files {
            autoreleasepool { // 加入自动释放池，防止内存暴涨
                guard let data = try? Data(contentsOf: fileURL),
                      let obj = try? JSONDecoder().decode(CacheObject.self, from: data) else {
                    return
                }

                // ❌ 1. 先删过期
                if obj.expireTime < now {
                    try? fm.removeItem(at: fileURL)
                    return
                }

                let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                totalSize += Int64(size)

                cacheFiles.append((fileURL, Int64(size), obj.lastAccessTime))
            }
        }

        // ✅ 不超限直接返回
        if totalSize <= Network.share.config.maxDiskSize { return }

        // ❗ LRU：按最后访问时间排序（最旧优先删）
        cacheFiles.sort { $0.lastAccess < $1.lastAccess }

        let targetSize = Int64(Double(Network.share.config.maxDiskSize) * Network.share.config.cleanThreshold)

        for file in cacheFiles {
            try? fm.removeItem(at: file.url)
            totalSize -= file.size

            if totalSize <= targetSize {
                break
            }
        }
    }

}

extension URLRequest {
    
    var cachePolicyType: PTNetworkCachePolicy {
        get {
            let value = value(forHTTPHeaderField: "cachePolicy") ?? PTNetworkCachePolicy.cacheElseNetwork.rawValue
            return PTNetworkCachePolicy(rawValue: value) ?? .cacheElseNetwork
        }
        set {
            setValue(newValue.rawValue, forHTTPHeaderField: "cachePolicy")
        }
    }
    
    var cacheExpire: TimeInterval {
        get {
            let value = value(forHTTPHeaderField: "cacheExpire") ?? "300"
            return TimeInterval(value) ?? 300
        }
        set {
            setValue("\(newValue)", forHTTPHeaderField: "cacheExpire")
        }
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
                    // 自动策略
                    switch cachePolicyType {
                    case .none:
                        return .none
                    default:
                        return .identical
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
        case .none, .networkOnly:
            return
            
        case .cacheOnly, .cacheElseNetwork:
            if let _ = await NetworkCache.shared.read(request: request) {
                request.isMock = true
            }
            
        case .networkElseCache:
            return
        }
    }
    
    public func didReceive(_ result: Result<Data, AFError>,
                    request: URLRequest,
                    response: HTTPURLResponse?) async {
        
        guard case .success(let data) = result else {
            
            // 网络失败 → fallback cache
            if request.cachePolicyType == .networkElseCache,
               let cache = await NetworkCache.shared.read(request: request) {
                
                NotificationCenter.default.post(
                    name: NSNotification.Name("PTNetworkCacheFallback"),
                    object: cache
                )
            }
            return
        }
        
        guard request.httpMethod == "GET" else { return }
        guard request.cachePolicyType != .none else { return }
        
        let expire = request.cacheExpire
        
        await NetworkCache.shared.save(
            data: data,
            request: request,
            expire: expire
        )
    }
}

public enum PTNetworkDedupPolicy : Sendable {
    case none                  // 不去重（默认）
    case identical             // 完全相同才去重（推荐）
    case custom(String)        // 自定义 key
    
    func getOptionName() -> String {
        switch self {
        case .none:
            return "none"
        case .identical:
            return "identical"
        case .custom(let string):
            return string
        }
    }
}

public struct RequestKey: Hashable {
    let url: String
    let method: String
    let paramsHash: Int // 改为 Int
    
    init(request: URLRequest) {
        self.url = request.url?.absoluteString ?? ""
        self.method = request.httpMethod ?? ""
        // 直接使用 Data 自身的 hashValue，速度极快，不需要 Base64 和 MD5
        self.paramsHash = request.httpBody?.hashValue ?? 0
    }
}

public actor RequestDeduplicator {
    
    public static let shared = RequestDeduplicator()
    
    private var runningTasks: [RequestKey: Task<PTBaseStructModel, Error>] = [:]
    
    // 初始化方法私有化，保证单例
    private init() {}
    
    public func execute(request: URLRequest,
                        policy: PTNetworkDedupPolicy,
                        task: @escaping @Sendable () async throws -> PTBaseStructModel) async throws -> PTBaseStructModel {
        
        switch policy {
        case .none:
            return try await task()
        default:
            let key = RequestKey(request: request)
            
            // 1. 如果已有相同请求在执行，直接等待它的结果
            if let existingTask = runningTasks[key] {
                return try await existingTask.value
            }
            
            // 2. 创建新任务
            let newTask = Task {
                // 执行网络请求
                return try await task()
            }
            
            // 3. 将任务保存到字典中
            runningTasks[key] = newTask
            
            // 4. 等待任务完成
            defer {
                // 确保无论成功失败，任务完成后都从字典中移除
                runningTasks.removeValue(forKey: key)
            }
            
            return try await newTask.value
        }
    }
}

// 🌟 1. 抽离所有配置项，放入一个轻量级的 Sendable 结构体中
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
    
    public var networkCacheOption: PTNetworkCachePolicy = .cacheOnly
    public var networkCacheEXPTime: String = "600"
    public var networkDudupOption: PTNetworkDedupPolicy = .custom("auto")
    
    public var maxDiskSize: Int64 = 100 * 1024 * 1024  // 100MB
    public var cleanThreshold: Double = 0.7            // 清到70%
    public var cleanCachePreSec: TimeInterval = 60
    
    public init() {} // 提供公开的初始化方法
}

public final class Network: @unchecked Sendable {
    
    static public let share = Network()
            
    public var plugins: [NetworkPlugin] = [PTNetworkCachePlugin()]
    
    private var downloadQueue = DispatchQueue(label: "pt.downloader.queue")

    // 🌟 3. 使用锁来保护配置的读写，实现 100% 的线程安全
    private let configLock = NSLock()
    private var _config = PTNetworkConfig()
    
    /// 统一的线程安全配置入口
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

    /// manager
    private lazy var session: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = config.netRequsetTime
        configuration.waitsForConnectivity = true
        configuration.requestCachePolicy = .useProtocolCachePolicy
        configuration.urlCache = URLCache(
            memoryCapacity: 20 * 1024 * 1024,
            diskCapacity: 100 * 1024 * 1024
        )
        return Session(configuration: configuration,
                       interceptor: RetryHandler())
    }()
    
    public var hud:PTHudView?
    public var hudConfig : PTHudConfig {
        let hudConfig = PTHudConfig.share
        hudConfig.hudColors = [.gray,.gray]
        hudConfig.lineWidth = 4
        return hudConfig
    }
    
    public func hudShow()  {
        PTGCDManager.gcdMain {
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
        
    //MARK: 服务器URL
    @MainActor
    public class func gobalUrl() async -> String {
        let environment = UIApplication.shared.inferredEnvironment_PT
        if environment != .appStore {
            PTNSLogConsole("PTBaseURLMode:\(PTBaseURLMode)",levelType: PTLogMode,loggerType: .network)
            switch PTBaseURLMode {
            case .Development:
                let url_debug:String = PTCoreUserDefultsWrapper.AppRequestUrl
                if url_debug.isEmpty {
                    return Network.share.config.serverAddress_dev
                } else {
                    return url_debug
                }
            case .Test:
                return Network.share.config.serverAddress_dev
            case .Distribution:
                return Network.share.config.serverAddress
            }
        } else {
            return Network.share.config.serverAddress
        }
    }
    
    //MARK: socket服务器URL
    @MainActor
    public class func socketGobalUrl() async -> String {
        let environment = UIApplication.shared.inferredEnvironment_PT
        if environment != .appStore {
            PTNSLogConsole("PTSocketURLMode:\(PTSocketURLMode)",levelType: PTLogMode,loggerType: .network)
            switch PTSocketURLMode {
            case .Development:
                let url_debug:String = PTCoreUserDefultsWrapper.AppSocketUrl
                if url_debug.isEmpty {
                    return Network.share.config.socketAddress_dev
                } else {
                    return url_debug
                }
            case .Test:
                return Network.share.config.socketAddress_dev
            case .Distribution:
                return Network.share.config.socketAddress
            }
        } else {
            return Network.share.config.socketAddress
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
        Network.share.session.cancelAllRequests(completingOnQueue: queue, completion: completion)
    }
    
    // MARK: 日志
    private static func logRequestStart(url: String, parameters: Parameters?, headers: HTTPHeaders, method: HTTPMethod) {
        let paramsStr = parameters?.jsonString() ?? "没有参数"
        let headerStr = headers.dictionary.jsonString() ?? ""
        PTNSLogConsole("🌐❤️1.请求地址 = \(url)\n💛2.参数 = \(paramsStr)\n💙3.请求头 = \(headerStr)\n🩷4.请求类型 = \(method.rawValue)🌐", levelType: PTLogMode, loggerType: .network)
    }

    private static func logRequestSuccess(url: String, jsonStr: String) {
        PTNSLogConsole("🌐接口请求成功回调🌐\n❤️1.请求地址 = \(url)\n💛2.result:\(jsonStr.isEmpty ? "没有数据" : jsonStr)🌐", levelType: PTLogMode, loggerType: .network)
    }

    private static func logRequestFailure(url: String, error: AFError) {
        PTNSLogConsole("❌接口:\(url)\n🎈----------------------出现错误----------------------🎈\(String(describing: error.errorDescription))❌", levelType: .error, loggerType: .network)
    }

    // 封装 token 添加逻辑
    private static func addToken(to headers: HTTPHeaders) -> HTTPHeaders {
        var headers = headers
        let token = Network.share.config.userToken
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
            let error = PTNetworkError.dataEmpty
            logRequestFailure(url: url, error: AFError.createURLRequestFailed(error: error))
            throw error
        }
        
        let isMockData = (response == nil)
        
        // 非 JSON 的情况（可能是 HTML 或纯文本）
        if !isMockData && !isJSONResponse(response, data: data) {
            if let html = String(data: data, encoding: .utf8), html.containsHTMLTags() {
                let error = PTNetworkError.htmlResponse(html)
                logRequestFailure(url: url, error: AFError.createURLRequestFailed(error: error))
                throw error
            }
            // 如果不是 HTML，就当作纯文本成功返回（Debug 打印文本）
            var originalText = ""
            switch UIApplication.shared.inferredEnvironment_PT {
            case .debug:
                originalText = prettyJSONString(from: String(decoding: data, as: UTF8.self)) ?? ""
            default:
                originalText = ""
            }
            logRequestSuccess(url: url, jsonStr: originalText)
            result.originalString = originalText
            return result
        }
        
        // JSON 情况
        let jsonString = String(data: data, encoding: .utf8) ?? ""
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
        apiHeader["cachePolicy"] = Network.share.config.networkCacheOption.rawValue
        apiHeader["cacheExpire"] = Network.share.config.networkCacheEXPTime
        apiHeader["dedupPolicy"] = Network.share.config.networkDudupOption.getOptionName()
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

        // ⭐ 优化：直接使用 Alamofire 提供的原生 async/await 接口
        // 这样写天然支持 Swift 的 Task Cancellation，外部取消时内部请求也会安全终止
        let dataTask = AF.upload(body,
                                 to: urlStr1,
                                 method: method,
                                 headers: newHeader).serializingData()
        
        // 等待响应结果
        let response = await dataTask.response
        
        switch response.result {
        case .success(let data):
            // 解析成功的数据
            return try parser(response.response, data)
        case .failure(let error):
            // 打印错误并抛出
            logRequestFailure(url: urlStr1, error: error)
            throw error
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

        let session = Network.share.session
        var urlRequest = try URLRequest(url: urlStr1, method: method, headers: apiHeader)
        urlRequest = try encoder.encode(urlRequest, with: parameters)
        // 👉 插件前置处理
        for plugin in Network.share.plugins {
            await plugin.willSend(&urlRequest)
        }
        
        if urlRequest.isMock {
            if let mockData = await NetworkCache.shared.read(request: urlRequest) {
                let parsed = try parser(nil, mockData)
                return parsed
            }
        }

        // 3. ⭐这里决定去重策略
        let policy: PTNetworkDedupPolicy = {
            switch urlRequest.cachePolicyType {
            case .none:
                return .none
            default:
                return .identical
            }
        }()
        
        // 极致优雅且原生支持 Cancellation 的写法：
        let finalRequest = urlRequest
        let realRequest: @Sendable () async throws -> PTBaseStructModel = {
            let dataTask = session.request(finalRequest).serializingData()
            
            // 拦截插件响应
            let response = await dataTask.response
            let result = response.result
            for plugin in Network.share.plugins {
                await plugin.didReceive(result, request: finalRequest, response: response.response)
            }

            switch result {
            case .success(let data):
                return try parser(response.response, data)
            case .failure(let error):
                logRequestFailure(url: urlStr1, error: error)
                throw error
            }
        }
        
        let result = try await RequestDeduplicator.shared.execute(request: urlRequest,
                                                                  policy: policy) {
            try await realRequest()
        }

        return result
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
                                            let key = fileKey
                                            let ext = canPNG ? "png" : "jpg"
                                            let dateString = Int(Date().timeIntervalSince1970)
                                            let fileName = "image_\(dateString).\(ext)"
                                            let mimeType = MimeTypeHelper.mimeType(for: ext)
                                            multipartFormData.append(imageData, withName: key, fileName: fileName, mimeType: mimeType)
                                        } else {
                                            continuation.finish(throwing: PTNetworkError.uploadDataError("Image data error"))
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
                                        continuation.finish(throwing: PTNetworkError.uploadDataError("Video data error"))
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
        
    /// 图片上传接口 (优化版)
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
                    let session = Network.share.session

                    session.upload(multipartFormData: { multipartFormData in
                        // 使用枚举配合 autoreleasepool 防止大图片同时驻留内存导致 OOM
                        images?.enumerated().forEach { index, image in
                            autoreleasepool {
                                let data = pngData ? image.pngData() : image.jpegData(compressionQuality: 0.6)
                                guard let imageData = data else { return }

                                let key = fileKey[safe: index] ?? "image"
                                let fileName = "image_\(index).\(pngData ? "png" : "jpg")"
                                let mimeType = pngData ? "image/png" : "image/jpeg"

                                multipartFormData.append(imageData, withName: key, fileName: fileName, mimeType: mimeType)
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

    // 自定义 Session，支持总超时
    private lazy var downloadSession: Session = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Network.share.config.downloadRequsetTime
        config.timeoutIntervalForResource = Network.share.config.downloadEndTime
        config.httpMaximumConnectionsPerHost = 6   // 控制并发
        return Session(configuration: config)
    }()
        
    actor DownloadStore {
        var tasks: [String: DownloadTask] = [:]

        public func get(_ url: String) -> DownloadTask? {
            tasks[url]
        }

        func set(_ url: String, task: DownloadTask) {
            tasks[url] = task
        }

        func remove(_ url: String) {
            tasks[url] = nil
        }
    }
    private let store = DownloadStore()

    final class DownloadTask {
        let url: String
        let destination: @Sendable (URL, HTTPURLResponse) -> (URL, DownloadRequest.Options)

        var request: DownloadRequest?
        var resumeData: Data?

        var progressHandlers: [FileDownloadProgress] = []
        var successHandlers: [FileDownloadSuccess] = []
        var failHandlers: [FileDownloadFail] = []

        // 🚨 新增：清理闭包引用，防止二次触发 Continuation
        private func clearHandlers() {
            progressHandlers.removeAll()
            successHandlers.removeAll()
            failHandlers.removeAll()
        }

        private var lastProgressTime: CFTimeInterval = 0

        init(url: String,
             destination: @escaping @Sendable (URL, HTTPURLResponse) -> (URL, DownloadRequest.Options)) {
            self.url = url
            self.destination = destination
        }

        func start(session: Session) {

            if let data = resumeData {
                request = session.download(resumingWith: data, to: destination)
            } else {
                request = session.download(url, to: destination)
            }

            // ✅ 降频 progress（防卡顿关键）
            request?.downloadProgress(queue: .main) { [weak self] p in
                guard let self else { return }

                let now = CACurrentMediaTime()
                guard now - self.lastProgressTime > 0.1 else { return }
                self.lastProgressTime = now

                for cb in self.progressHandlers {
                    cb(p.completedUnitCount, p.totalUnitCount, p.fractionCompleted)
                }
            }

            // ✅ 不用 responseData（避免大文件卡死）
            request?.response { [weak self] resp in
                guard let self else { return }

                self.resumeData = nil

                if let error = resp.error {
                    self.resumeData = resp.resumeData
                    let currentFails = self.failHandlers
                    self.clearHandlers()
                    currentFails.forEach { $0(error) }
                } else {
                    // 🚨 先将回调拷贝出来，然后立即清空原始数组
                    let currentSuccesses = self.successHandlers
                    self.clearHandlers()
                    currentSuccesses.forEach { $0(resp) }
                }
            }
        }

        func suspend() {
            request?.cancel { [weak self] data in
                self?.resumeData = data
                self?.request = nil
            }
        }

        func cancel() {
            request?.cancel()
        }
    }
    
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

        let dest: @Sendable (URL, HTTPURLResponse) -> (URL, DownloadRequest.Options) = { _, _ in
            let saveUrl = URL(fileURLWithPath: saveFilePath)
            return (saveUrl,[.removePreviousFile, .createIntermediateDirectories])
        }

        Task {
            if let existing = await store.get(fileUrl) {
                if let p = progress { existing.progressHandlers.append(p) }
                if let s = success { existing.successHandlers.append(s) }
                if let f = fail { existing.failHandlers.append(f) }
                return
            }

            let task = DownloadTask(url: fileUrl, destination: dest)

            if let p = progress { task.progressHandlers.append(p) }
            if let s = success { task.successHandlers.append(s) }
            if let f = fail { task.failHandlers.append(f) }

            await store.set(fileUrl, task: task)

            task.start(session: downloadSession)
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
        Task {
            await store.get(fileUrl)?.suspend()
        }
    }

    public func resume(fileUrl: String) {
        Task {
            if let task = await store.get(fileUrl) {
                task.start(session: session)
            }
        }
    }

    public func cancel(fileUrl: String) {
        Task {
            let task = await store.get(fileUrl)
            await store.remove(fileUrl)
            task?.cancel()
        }
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
