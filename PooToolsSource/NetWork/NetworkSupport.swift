// English: Keep retry, cache, reachability, and upload support outside the Network facade.
// Español: Mantiene el reintento, la caché, la conectividad y la carga fuera de la fachada Network.
// 中文：将重试、缓存、网络状态和上传支撑代码从 Network 门面中独立出来。

import Foundation
@preconcurrency import Alamofire
import Network
import CoreTelephony
import SwifterSwift

/// 🌟 步骤 1：标记为 @unchecked Sendable。
/// 这告诉编译器：“虽然我内部有 var，但我会通过加锁的方式自己保证线程安全，请允许我跨线程传递。”
public final class NetworkReachability: @unchecked Sendable {
    
    public static let shared = NetworkReachability()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "network.reachability")
    
    // 🌟 步骤 2：引入互斥锁，用于保护共享数据的读写
    private let lock = NSLock()
    
    // 🌟 步骤 3：将真实的数据隐藏起来
    private var _isReachable: Bool = true
    private var _isExpensive: Bool = false
    
    // 🌟 步骤 4：对外暴露计算属性。每次读取时都加锁，保证读取时不会发生正在写入的情况。
    public var isReachable: Bool {
        lock.withLock {
            return _isReachable
        }
    }
    
    public var isExpensive: Bool {
        lock.withLock {
            return _isExpensive
        }
    }
    
    private init() {
        // NWPathMonitor 的回调是在我们指定的 queue (后台线程) 中触发的
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            // 🌟 步骤 5：在写入数据时同样加锁，确保写入操作的原子性和安全性
            self.lock.withLock {
                self._isReachable = (path.status == .satisfied)
                self._isExpensive = path.isExpensive
            }
        }
        monitor.start(queue: queue)
    }
}

// 🌟 内部极轻量级状态码映射模型（取代消耗性能的 JSONSerialization 字典转换）
struct PTNetworkStatusModel: Decodable {
    let code: Int?
    let msg: String?
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
    
    public var statusStream: AsyncStream<NetworkStatus> {
        AsyncStream { continuation in
            let monitor = NWPathMonitor()
            monitor.pathUpdateHandler = { [weak self] path in
                guard let self = self else { return }
                let status: NetworkStatus
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

final class RetryHandler: Sendable, RequestInterceptor {
    private let retryLimitSnapshot: Int
    private let baseDelaySnapshot: TimeInterval
    private let statusCodeToRetry: Int
    private let maxDelay: TimeInterval = 8.0
    private let jitter: TimeInterval = 0.4
    
    // English: Snapshot retry settings from the owning Network instance.
    // Español: Captura la configuración de reintentos de la instancia Network propietaria.
    // 中文：从所属 Network 实例快照重试配置。
    init(configuration: PTNetworkSessionConfiguration) {
        retryLimitSnapshot = configuration.retryTimes
        baseDelaySnapshot = configuration.retryDelay
        statusCodeToRetry = configuration.retryAPIStatusCode
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

public struct CacheObject: Codable, Sendable {
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
        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
            ?? FileManager.default.temporaryDirectory.path
        diskPath = path.nsString.appendingPathComponent("PTNetworkCache")
        try? FileManager.default.createDirectory(atPath: diskPath, withIntermediateDirectories: true)
        // English: Bound the in-memory cache so a large response cannot grow without limit.
        // Español: Limita la caché en memoria para que una respuesta grande no crezca sin límite.
        // 中文：限制内存缓存，避免大响应导致缓存无限增长。
        memoryCache.countLimit = 200
        memoryCache.totalCostLimit = 50 * 1024 * 1024
    }
    
    private func cacheKey(_ request: URLRequest) -> String {
        let url = request.url?.absoluteString ?? ""
        let sortedQuery = request.url?.query?.split(separator: "&").sorted().joined(separator: "&") ?? ""
        let rawBody = request.httpBody ?? Data()
        let body = rawBody.sortedJSONData() ?? rawBody
        // English: Partition cached responses by request headers so credentials and content variants never share data.
        // Español: Separa las respuestas almacenadas por cabeceras para que las credenciales y variantes no compartan datos.
        // 中文：按请求头隔离缓存响应，避免不同凭证或内容变体复用数据。
        let headers = (request.allHTTPHeaderFields ?? [:])
            .map { key, value in "\(key.lowercased())=\(value)" }
            .sorted()
            .joined(separator: "\n")
        return (url + sortedQuery + headers + body.base64EncodedString()).md5
    }
    
    func save(data: Data, request: URLRequest, expire: TimeInterval) async {
        let key = cacheKey(request)
        let now = Date().timeIntervalSince1970
        let obj = CacheObject(data: data, expireTime: now + expire, lastAccessTime: now)
        
        guard let encoded = await Self.encode(obj) else { return }
        memoryCache.setObject(encoded as NSData, forKey: key as NSString, cost: encoded.count)
        
        let path = self.diskPath.nsString.appendingPathComponent(key)
        Self.write(encoded, to: path)
    }
    
    func read(request: URLRequest) async -> Data? {
        let key = cacheKey(request)
        let now = Date().timeIntervalSince1970

        if let data = memoryCache.object(forKey: key as NSString) as Data?,
           var obj = await Self.decode(data), obj.expireTime > now {
            obj.lastAccessTime = now
            if let encoded = await Self.encode(obj) {
                memoryCache.setObject(encoded as NSData, forKey: key as NSString, cost: encoded.count)
            }
            return obj.data
        }
        
        let path = (self.diskPath as NSString).appendingPathComponent(key)
        if let data = await Self.readData(from: path),
           var obj = await Self.decode(data), obj.expireTime > now {
            obj.lastAccessTime = now
            if let encoded = await Self.encode(obj) {
                memoryCache.setObject(encoded as NSData, forKey: key as NSString, cost: encoded.count)
                Self.write(encoded, to: path)
            }
            return obj.data
        }
        return nil
    }

    public func clearAll() {
        memoryCache.removeAllObjects()
        try? FileManager.default.removeItem(atPath: diskPath)
        try? FileManager.default.createDirectory(atPath: diskPath, withIntermediateDirectories: true)
    }
    
    public func cleanIfNeeded() {
        // English: Keep the legacy entry point bound to the shared configuration; new code should pass an instance snapshot.
        // Español: Mantiene la entrada heredada vinculada a la configuración compartida; el código nuevo debe pasar una instantánea de instancia.
        // 中文：旧入口继续使用共享配置；新代码应显式传入实例配置快照。
        cleanIfNeeded(configuration: Network.share.config)
    }

    // English: Accept a caller-owned configuration so cache maintenance does not read Network.share.
    // Español: Acepta una configuración del llamador para que el mantenimiento de caché no lea Network.share.
    // 中文：使用调用方传入的配置，缓存维护不再读取 Network.share。
    func cleanIfNeeded(configuration: PTNetworkConfig) {
        let now = Date().timeIntervalSince1970
        guard now - lastCleanTime > configuration.cleanCachePreSec else { return }
        lastCleanTime = now
        let path = diskPath
        let maxDiskSize = configuration.maxDiskSize
        let cleanThreshold = configuration.cleanThreshold
        Task.detached(priority: .background) {
            Self.cleanDisk(at: path,
                           maxDiskSize: maxDiskSize,
                           cleanThreshold: cleanThreshold)
        }
    }
    
    private nonisolated static func cleanDisk(at path: String,
                                              maxDiskSize: Int64,
                                              cleanThreshold: Double) {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: URL(fileURLWithPath: path), includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey], options: .skipsHiddenFiles) else { return }

        var totalSize: Int64 = 0
        var cacheFiles: [(url: URL, size: Int64, lastAccess: Date)] = []

        for fileURL in files {
            autoreleasepool {
                // English: Evict by metadata only. Español: Expulsa solo por metadatos. 中文：仅使用元数据淘汰。
                guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]), let fileSize = values.fileSize, fileSize > 0 else { return }
                let size = Int64(fileSize)
                totalSize += size
                cacheFiles.append((fileURL, size, values.contentModificationDate ?? .distantPast))
            }
        }

        guard maxDiskSize > 0, totalSize > maxDiskSize else { return }
        cacheFiles.sort { $0.lastAccess < $1.lastAccess }
        let targetSize = Int64(Double(maxDiskSize) * min(max(cleanThreshold, 0), 1))

        for file in cacheFiles {
            try? fm.removeItem(at: file.url)
            totalSize -= file.size
            if totalSize <= targetSize { break }
        }
    }

    // English: Keep JSON and file operations off the cache actor while the actor owns only cache state.
    // Español: Mantiene JSON y las operaciones de archivo fuera del actor de caché; el actor solo posee el estado.
    // 中文：让 JSON 和文件操作离开缓存 actor，actor 只负责保护缓存状态。
    private nonisolated static func encode(_ object: CacheObject) async -> Data? {
        await Task.detached(priority: .utility) {
            try? JSONEncoder().encode(object)
        }.value
    }

    // English: Decode cache metadata on a utility executor before updating actor-owned memory state.
    // Español: Decodifica los metadatos de caché en un ejecutor de utilidad antes de actualizar el estado del actor.
    // 中文：在更新 actor 持有的内存状态前，先在 utility 执行器上解码缓存元数据。
    private nonisolated static func decode(_ data: Data) async -> CacheObject? {
        await Task.detached(priority: .utility) {
            try? JSONDecoder().decode(CacheObject.self, from: data)
        }.value
    }

    // English: Read cache files without occupying the actor executor with synchronous file I/O.
    // Español: Lee los archivos de caché sin ocupar el ejecutor del actor con I/O síncrono.
    // 中文：读取缓存文件时不让同步 I/O 占用 actor 执行器。
    private nonisolated static func readData(from path: String) async -> Data? {
        await Task.detached(priority: .utility) {
            try? Data(contentsOf: URL(fileURLWithPath: path))
        }.value
    }

    // English: Persist cache data on a background executor and keep the actor responsive.
    // Español: Persiste los datos de caché en un ejecutor de fondo y mantiene receptivo el actor.
    // 中文：在后台执行器持久化缓存数据，保持 actor 响应。
    private nonisolated static func write(_ data: Data, to path: String) {
        Task.detached(priority: .background) {
            let directory = URL(fileURLWithPath: path).deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try? data.write(to: URL(fileURLWithPath: path))
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
    // English: Expose the default cache adapter so the public Network initializer can use it safely.
    // Español: Expone el adaptador de caché predeterminado para que el inicializador público de Network pueda usarlo de forma segura.
    // 中文：公开默认缓存适配器初始化方法，确保 Network 的公开初始化器可以安全使用。
    public init() {}

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

enum PreparedUploadMedia {
    case data(Data, mimeType: String, fileName: String)
    case fileURL(URL, mimeType: String, fileName: String)
}

// 用于在并发任务组中安全传递图片处理结果的内部结构
struct PreparedImageResult: Sendable {
    let key: String
    let fileName: String
    let mimeType: String
    let data: Data
}

// A response snapshot keeps only Sendable values after Alamofire's callback returns.
// Una instantánea conserva únicamente valores Sendable después del callback de Alamofire.
// 响应快照只在 Alamofire 回调结束后保留 Sendable 值。
struct PTNetworkResponseSnapshot: Sendable {
    let url: String
    let data: Data?
    let metadata: PTResponseMetadata
}

// Upload events cross the stream as immutable snapshots instead of Progress or UIKit objects.
// Los eventos de carga cruzan el stream como instantáneas inmutables, no como Progress ni objetos UIKit.
// 上传事件以不可变快照跨越流，不传递 Progress 或 UIKit 对象。
struct PTNetworkUploadEvent: Sendable {
    let progress: PTProgressSnapshot
    let response: PTNetworkResponseSnapshot?
}
