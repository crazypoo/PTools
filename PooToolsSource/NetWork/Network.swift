//
//  Network.swift
//  MiniChatSwift
//
//  Created by 林勇彬 on 2022/5/21.
//  Copyright © 2022 九州所想. All rights reserved.
//

import UIKit
// Alamofire 5 callback types are not fully concurrency-annotated; all
// callbacks are normalized inside Network's request executor.
@preconcurrency import Alamofire
import Network
import SwifterSwift
import CoreTelephony
import Photos
import SmartCodable
import KakaJSON
#if canImport(PToolsCore)
import PToolsCore
#endif
private let PTNetworkLocalizationBundle: Bundle = {
    let mainBundle = Bundle.main
    guard let path = mainBundle.path(forResource: CorePodBundleName, ofType: "bundle"),
          let resourceBundle = Bundle(path: path) else {
        return mainBundle
    }
    return resourceBundle
}()

public enum PTNetworkError: Error, LocalizedError, CustomNSError, Sendable {

    // MARK: - 基础网络错误
    case noNetwork
    case checkIPFail
    case downloadFail
    case jsonExplainFail
    case modelExplainFail
    
    // MARK: - 业务与数据错误
    case dataEmpty
    case htmlResponse(String)
    case uploadDataError(String)
    case businessError(code: Int, msg: String)
    
    // MARK: - LocalizedError 协议实现
    
    /// 错误的本地化描述
    /// 🌟 修复：移除了 @MainActor。
    /// LocalizedError 协议要求此属性是非隔离的 (non-isolated)。
    /// 只要 `.localized()` 扩展没有修改外部状态，它就是线程安全的。
    public var errorDescription: String? {
        switch self {
        case .noNetwork:        return "PT Network no network".localized(tableName: nil, bundle: PTNetworkLocalizationBundle)
        case .checkIPFail:      return "IP address error"
        case .downloadFail:     return "PT Network download fail".localized(tableName: nil, bundle: PTNetworkLocalizationBundle)
        case .jsonExplainFail:  return "PT Network json fail".localized(tableName: nil, bundle: PTNetworkLocalizationBundle)
        case .modelExplainFail: return "PT Network model fail".localized(tableName: nil, bundle: PTNetworkLocalizationBundle)
            
        case .dataEmpty:              return "Data empty"
        case .htmlResponse(let html): return html
        case .uploadDataError(let msg): return msg
        case .businessError(_, let msg): return msg
        }
    }
    
    // MARK: - CustomNSError 协议实现
    
    /// 错误代码
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
    
    /// 错误域
    public static var errorDomain: String {
        return "com.pt.network.error"
    }
}

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
private struct PTNetworkStatusModel: Decodable {
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

fileprivate final class RetryHandler: Sendable, RequestInterceptor {
    private let retryLimitSnapshot: Int
    private let baseDelaySnapshot: TimeInterval
    private let statusCodeToRetry: Int
    private let maxDelay: TimeInterval = 8.0
    private let jitter: TimeInterval = 0.4
    
    // English: Snapshot retry settings from the owning Network instance.
    // Español: Captura la configuración de reintentos de la instancia Network propietaria.
    // 中文：从所属 Network 实例快照重试配置。
    init(configuration: PTNetworkConfig) {
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
    
    func save(data: Data, request: URLRequest, expire: TimeInterval) {
        let key = cacheKey(request)
        let now = Date().timeIntervalSince1970
        let obj = CacheObject(data: data, expireTime: now + expire, lastAccessTime: now)
        
        guard let encoded = try? JSONEncoder().encode(obj) else { return }
        memoryCache.setObject(encoded as NSData, forKey: key as NSString, cost: encoded.count)
        
        let path = self.diskPath.nsString.appendingPathComponent(key)
        Task.detached(priority: .background) { try? FileManager.default.createDirectory(at: URL(fileURLWithPath: path).deletingLastPathComponent(), withIntermediateDirectories: true); try? encoded.write(to: URL(fileURLWithPath: path)) }
    }
    
    func read(request: URLRequest) -> Data? {
        let key = cacheKey(request)
        let now = Date().timeIntervalSince1970

        if let data = memoryCache.object(forKey: key as NSString) as Data?,
           var obj = try? JSONDecoder().decode(CacheObject.self, from: data), obj.expireTime > now {
            obj.lastAccessTime = now
            if let encoded = try? JSONEncoder().encode(obj) {
                memoryCache.setObject(encoded as NSData, forKey: key as NSString, cost: encoded.count)
            }
            return obj.data
        }
        
        let path = (self.diskPath as NSString).appendingPathComponent(key)
        if let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           var obj = try? JSONDecoder().decode(CacheObject.self, from: data), obj.expireTime > now {
            obj.lastAccessTime = now
            if let encoded = try? JSONEncoder().encode(obj) {
                memoryCache.setObject(encoded as NSData, forKey: key as NSString, cost: encoded.count)
                Task.detached(priority: .background) { try? encoded.write(to: URL(fileURLWithPath: path)) }
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

private enum PreparedUploadMedia {
    case data(Data, mimeType: String, fileName: String)
    case fileURL(URL, mimeType: String, fileName: String)
}

// 用于在并发任务组中安全传递图片处理结果的内部结构
fileprivate struct PreparedImageResult: Sendable {
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
private struct PTNetworkUploadEvent: Sendable {
    let progress: PTProgressSnapshot
    let response: PTNetworkResponseSnapshot?
}

public final class Network: @unchecked Sendable {
    static public let share = Network()
    private let pluginsLock = NSLock()
    private var _plugins: [NetworkPlugin]

    // English: Session creation is protected so the legacy lazy configuration behavior remains race-free.
    // Español: La creación de sesiones está protegida para conservar sin carreras el comportamiento perezoso heredado.
    // 中文：为 Session 创建加锁，在保证无竞争的同时保留旧的懒加载配置行为。
    private let sessionLock = NSLock()
    private var storedSession: Session?
    private let downloadSessionLock = NSLock()
    private var storedDownloadSession: Session?

    // English: New instances snapshot their configuration and plugins; the legacy singleton remains available.
    // Español: Las nuevas instancias capturan su configuración y plugins; el singleton heredado sigue disponible.
    // 中文：新实例会固定初始配置和插件；旧单例入口继续可用。
    public init(configuration: PTNetworkConfig = PTNetworkConfig(),
                plugins: [NetworkPlugin] = [PTNetworkCachePlugin()]) {
        _config = configuration
        _plugins = plugins
    }

    public var plugins: [NetworkPlugin] {
        get {
            pluginsLock.withLock { _plugins }
        }
        set {
            pluginsLock.withLock { _plugins = newValue }
        }
    }

    // English: Add a plugin atomically while preserving the mutable legacy property.
    // Español: Añade un plugin atómicamente y conserva la propiedad heredada mutable.
    // 中文：以原子方式添加插件，同时保留旧的可变属性。
    public func register(plugin: NetworkPlugin) {
        pluginsLock.withLock {
            _plugins.append(plugin)
        }
    }

    private var downloadQueue = DispatchQueue(label: "pt.downloader.queue")
    
    private let configLock = NSLock()
    private var _config = PTNetworkConfig()
    
    // 通过 Bundle 底层特征判断是否是 App Store 环境。
    // Determina si el paquete pertenece al entorno de App Store mediante una característica del Bundle.
    // Use Bundle 的底层特征判断当前是否为 App Store 环境。
    private static let isAppStoreEnvironment: Bool = {
#if DEBUG
        return false
#else
        // 业界标准方案：App Store 正式包在苹果后台处理后，会剥离 embedded.mobileprovision 文件。
        // 而 TestFlight、AdHoc 或企业包都会保留这个文件。我们通过判断这个文件是否存在来区分。
        let hasProvision = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") != nil
        return !hasProvision
#endif
    }()

    /// 测试包（Debug、TestFlight、AdHoc）允许输出响应调试信息，App Store 包不输出响应内容。
    private static var shouldLogResponseDetails: Bool {
        !isAppStoreEnvironment
    }
    
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

    // English: Expose an immutable request environment for instance-based integrations.
    // Español: Expone un entorno de solicitud inmutable para las integraciones basadas en instancias.
    // 中文：为实例化网络调用提供不可变请求环境快照。
    public var requestEnvironment: PTNetworkRequestEnvironment {
        PTNetworkRequestEnvironment(configuration: config)
    }

    // English: Build the request session from an immutable configuration snapshot.
    // Español: Construye la sesión de solicitudes a partir de una instantánea inmutable de configuración.
    // 中文：使用不可变配置快照创建请求 Session。
    private static func makeSession(configuration configurationSnapshot: PTNetworkConfig) -> Session {
        let urlConfiguration = URLSessionConfiguration.default
        urlConfiguration.timeoutIntervalForRequest = configurationSnapshot.requestTimeout
        urlConfiguration.timeoutIntervalForResource = configurationSnapshot.resourceTimeout
        urlConfiguration.waitsForConnectivity = configurationSnapshot.waitsForConnectivity
        urlConfiguration.requestCachePolicy = .useProtocolCachePolicy
        var protocols = urlConfiguration.protocolClasses ?? []
        protocols.insert(PTCustomHTTPProtocol.self, at: 0)
        urlConfiguration.protocolClasses = protocols
        urlConfiguration.urlCache = URLCache(memoryCapacity: 20 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024)
        return Session(configuration: urlConfiguration, interceptor: RetryHandler(configuration: configurationSnapshot))
    }

    private var session: Session {
        sessionLock.lock()
        defer { sessionLock.unlock() }
        if let storedSession { return storedSession }
        let newSession = Self.makeSession(configuration: config)
        storedSession = newSession
        return newSession
    }
    
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
                self.hud?.hudShow()
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
    
    // English: Resolve the request base URL from the active environment and configuration.
    // Español: Resuelve la URL base de las solicitudes a partir del entorno y la configuración activos.
    // 中文：根据当前环境和配置解析请求基础 URL。
    @MainActor public class func globalURL() async -> String {
        let environment = UIApplication.shared.inferredEnvironment_PT
        if environment != .appStore {
            PTNSLogConsole("PTBaseURLMode:\(PTBaseURLMode)",levelType: PTLogMode,loggerType: .network)
            switch PTBaseURLMode {
            case .Development:
                let url_debug:String = PTCoreUserDefultsWrapper.shared.AppRequestUrl
                return url_debug.isEmpty ? Network.share.config.serverAddress_dev : url_debug
            case .Test:         return Network.share.config.serverAddress_dev
            case .Distribution: return Network.share.config.serverAddress
            }
        } else {
            return Network.share.config.serverAddress
        }
    }
    
    // English: Resolve the socket base URL from the active environment and configuration.
    // Español: Resuelve la URL base del socket a partir del entorno y la configuración activos.
    // 中文：根据当前环境和配置解析 Socket 基础 URL。
    @MainActor public class func socketGlobalURL() async -> String {
        let environment = UIApplication.shared.inferredEnvironment_PT
        if environment != .appStore {
            PTNSLogConsole("PTSocketURLMode:\(PTSocketURLMode)",levelType: PTLogMode,loggerType: .network)
            switch PTSocketURLMode {
            case .Development:
                let url_debug:String = PTCoreUserDefultsWrapper.shared.AppSocketUrl
                return url_debug.isEmpty ? Network.share.config.socketAddress_dev : url_debug
            case .Test:         return Network.share.config.socketAddress_dev
            case .Distribution: return Network.share.config.socketAddress
            }
        } else {
            return Network.share.config.socketAddress
        }
    }
    
    @available(*, deprecated, message: "Use globalURL() instead")
    @MainActor public class func gobalUrl() async -> String {
        await globalURL()
    }

    @available(*, deprecated, message: "Use socketGlobalURL() instead")
    @MainActor public class func socketGobalUrl() async -> String {
        await socketGlobalURL()
    }

    class public func getIpAddress(url:String = "https://api.ipify.org") async throws -> String {
        let urlStr1 = try await createURLRequest(urlStr: url, needGobal: false)
        let apiHeader = prepareRequestHeaders(header: nil, jsonRequest: true)
        let model = try await Network.requestCodableApi(needGobal:false, urlStr: urlStr1, method: .get, header: apiHeader, modelType: PTDummyModel.self)
        return String(data: model.resultData ?? Data(), encoding: .utf8) ?? ""
    }
    
    class public func requestIPInfo(ipAddress:String,lang:OSSVoiceEnum = .ChineseSimplified) async throws -> PTIPInfoModel? {
        guard let snapshot = try await requestIPInfoSnapshot(ipAddress: ipAddress, lang: lang) else {
            return nil
        }
        return await MainActor.run {
            PTIPInfoModel(snapshot: snapshot)
        }
    }

    // Typed IP responses cross the request boundary as immutable values.
    // Las respuestas IP tipadas cruzan el límite de solicitudes como valores inmutables.
    // 类型化 IP 响应以不可变值形式跨越请求边界。
    public class func requestIPInfoSnapshot(ipAddress: String,
                                            lang: OSSVoiceEnum = .ChineseSimplified) async throws -> PTIPInfoSnapshot? {
        let urlStr1 = try await createURLRequest(urlStr: "http://ip-api.com/json/\(ipAddress)?lang=\(lang.rawValue)", needGobal: false)
        let apiHeader = prepareRequestHeaders(header: nil, jsonRequest: true)
        let models = try await Network.requestCodableApi(needGobal: false,
                                                         urlStr: urlStr1,
                                                         method: .get,
                                                         header: apiHeader,
                                                         modelType: PTIPInfoPayload.self)
        return models.customerModel.map(PTIPInfoSnapshot.init(payload:))
    }
    
    public class func cancelAllNetworkRequest(completingOnQueue queue: DispatchQueue = .main, completion: (@Sendable () -> Void)? = nil) {
        Network.share.session.cancelAllRequests(completingOnQueue: queue, completion: completion)
    }
    
    private static func logRequestStart(url: String, parameters: Parameters?, headers: HTTPHeaders, method: HTTPMethod) {
        let paramsStr = requestParametersForLog(parameters)
        let safeHeaders = headers.dictionary.reduce(into: [String: String]()) { result, item in
            let key = item.key.lowercased()
            let isSensitive = key == "authorization" || key.contains("token") || key == "cookie" || key == "set-cookie"
            result[item.key] = isSensitive ? "" : item.value
        }
        PTNSLogConsole("🌐❤️1.请求地址 = \(url)\n💛2.参数 = \(paramsStr)\n💙3.请求头 = \(safeHeaders)\n🩷4.请求类型 = \(method.rawValue)🌐", levelType: PTLogMode, loggerType: .network)
    }

    private static func requestParametersForLog(_ parameters: Parameters?) -> String {
        guard let parameters, !parameters.isEmpty else { return "没有参数" }
        if isAppStoreEnvironment {
            return "已隐藏（参数数量：\(parameters.count)）"
        }
        return sanitizedParameters(parameters)
    }

    private static func sanitizedParameters(_ parameters: Parameters?) -> String {
        guard let parameters, !parameters.isEmpty else { return "没有参数" }
        let sanitized = parameters.reduce(into: [String: String]()) { result, item in
            let key = item.key.lowercased()
            let isSensitive = key == "authorization" || key.contains("token") || key == "cookie" || key == "set-cookie"
            result[item.key] = isSensitive ? "" : String(describing: item.value)
        }
        return String(describing: sanitized)
    }
    
    private static func logRequestSuccess(url: String, jsonStr: String) {
        let printStr = jsonStr.isEmpty ? "数据为空或响应内容不可解析" : jsonStr
        PTNSLogConsole("🌐接口请求成功回调🌐\n❤️1.请求地址 = \(url)\n💛2.result:\(printStr)🌐", levelType: PTLogMode, loggerType: .network)
    }
    
    private static func logRequestFailure(url: String, error: AFError) {
        PTNSLogConsole("❌接口:\(url)\n🎈----------------------出现错误----------------------🎈\(String(describing: error.errorDescription))❌", levelType: .error, loggerType: .network)
    }
    
    private static func addToken(to headers: HTTPHeaders,
                                 configuration: PTNetworkConfig? = nil) -> HTTPHeaders {
        var headers = headers
        let token = (configuration ?? Network.share.config).userToken
        if !token.isEmpty {
            headers["token"] = token
            headers["device"] = "iOS"
        }
        return headers
    }
    
    private static func isJSONResponse(_ metadata: PTResponseMetadata) -> Bool {
        let contentType = metadata.headers.first { key, _ in
            key.caseInsensitiveCompare("Content-Type") == .orderedSame
        }?.value.lowercased() ?? ""
        return contentType.contains("application/json") || contentType.contains("text/json")
    }

    private static func responseSnapshot(url: String,
                                         response: HTTPURLResponse?,
                                         data: Data?) -> PTNetworkResponseSnapshot {
        var headers = [String: String](minimumCapacity: response?.allHeaderFields.count ?? 0)
        response?.allHeaderFields.forEach { key, value in
            headers[String(describing: key)] = String(describing: value)
        }
        let metadata = PTResponseMetadata(statusCode: response?.statusCode,
                                          headers: headers)
        return PTNetworkResponseSnapshot(url: url, data: data, metadata: metadata)
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
    private static func validateAndPreprocessResponse<T>(_ snapshot: PTNetworkResponseSnapshot) throws -> (PTBaseStructModel<T>, String) {
        var result = PTBaseStructModel<T>()
        result.resultData = snapshot.data
        
        guard let data = snapshot.data, !data.isEmpty else {
            let error = PTNetworkError.dataEmpty
            logRequestFailure(url: snapshot.url, error: AFError.createURLRequestFailed(error: error))
            throw error
        }
        
        let isMockData = snapshot.metadata.statusCode == nil
        if !isMockData && !isJSONResponse(snapshot.metadata) {
            if let html = String(data: data, encoding: .utf8), html.containsHTMLTags() {
                let error = PTNetworkError.htmlResponse(html)
                logRequestFailure(url: snapshot.url, error: AFError.createURLRequestFailed(error: error))
                throw error
            }
            var originalText = ""
            if shouldLogResponseDetails {
                originalText = String(decoding: data, as: UTF8.self)
                logRequestSuccess(url: snapshot.url, jsonStr: originalText)
            }
            result.originalString = originalText
            return (result, "")
        }
        
        let rawJsonString = String(data: data, encoding: .utf8) ?? ""
        result.originalString = rawJsonString
        
        if let statusModel = try? JSONDecoder().decode(PTNetworkStatusModel.self, from: data) {
            let businessCode = statusModel.code ?? 200
            let businessMsg = statusModel.msg ?? "Unknown error"
            
            if businessCode == 401 {
                PTGCDManager.shared.runOnMain {
                    NotificationCenter.default.post(name: NSNotification.Name("PTNetworkTokenExpiredNotification"), object: nil)
                }
                throw PTNetworkError.businessError(code: businessCode, msg: businessMsg)
            }
        }
        
        if shouldLogResponseDetails {
            let maxLen = Int(Network.share.config.logMaxCount)
            // 大响应不进入完整 JSON 格式化，避免调试日志制造额外 CPU 和内存峰值。
            let prettyStr: String
            if data.count > maxLen * 4 {
                prettyStr = String(decoding: data.prefix(maxLen), as: UTF8.self)
            } else {
                prettyStr = prettyPrintedJSONString(from: data)
            }
            let printStr = prettyStr.count > maxLen ? String(prettyStr.prefix(maxLen)) + "\n\n...[JSON过大，为保护控制台已截断]..." : prettyStr
            logRequestSuccess(url: snapshot.url, jsonStr: printStr)
        }
        return (result, rawJsonString)
    }
    
    private static func prepareRequestHeaders(header: HTTPHeaders?,
                                              jsonRequest: Bool,
                                              cachePolicy: PTNetworkCachePolicy? = nil,
                                              configuration: PTNetworkConfig? = nil) -> HTTPHeaders {
        var apiHeader = header ?? HTTPHeaders()
        if jsonRequest {
            apiHeader["Content-Type"] = "application/json;charset=UTF-8"
            apiHeader["Accept"] = "application/json"
        }
        let configurationSnapshot = configuration ?? Network.share.config
        let finalCachePolicy = cachePolicy ?? configurationSnapshot.networkCacheOption
        apiHeader["cachePolicy"] = finalCachePolicy.rawValue
        apiHeader["cacheExpire"] = configurationSnapshot.networkCacheExpiration
        apiHeader["dedupPolicy"] = configurationSnapshot.networkDedupOption.getOptionName()
        return addToken(to: apiHeader, configuration: configurationSnapshot)
    }
    
    private static func createURLRequest(urlStr: URLConvertible, needGobal: Bool) async throws -> String {
        let original = try urlStr.asURL().absoluteString
        if original.hasPrefix("http") { return original }
        let globalURL = needGobal ? await Network.globalURL() : ""
        return globalURL + original
    }

    /// Shared value for all request-shaped entry points. The legacy KakaJSON
    /// parser still lives at the boundary, but URL/header construction no
    /// longer has separate implementations for modern and legacy requests.
    private struct PTNetworkRequestContext {
        let url: String
        let method: HTTPMethod
        let headers: HTTPHeaders
    }

    private class func makeRequestContext(urlStr: URLConvertible,
                                          needGobal: Bool,
                                          method: HTTPMethod,
                                          header: HTTPHeaders?,
                                          jsonRequest: Bool,
                                          cachePolicy: PTNetworkCachePolicy?) async throws -> PTNetworkRequestContext {
        let url = try await createURLRequest(urlStr: urlStr, needGobal: needGobal)
        let headers = prepareRequestHeaders(header: header,
                                            jsonRequest: jsonRequest,
                                            cachePolicy: cachePolicy)
        return PTNetworkRequestContext(url: url, method: method, headers: headers)
    }

    // English: Build a context from the instance snapshot so custom Network objects do not fall back to the singleton.
    // Español: Construye el contexto desde la instantánea de la instancia para que las redes personalizadas no vuelvan al singleton.
    // 中文：使用实例快照构建请求上下文，避免自定义 Network 实例回退到单例。
    private func makeInstanceRequestContext(urlStr: URLConvertible,
                                             needGobal: Bool,
                                             method: HTTPMethod,
                                             header: HTTPHeaders?,
                                             jsonRequest: Bool,
                                             cachePolicy: PTNetworkCachePolicy?) throws -> PTNetworkRequestContext {
        let originalURL = try urlStr.asURL().absoluteString
        let configuration = config
        let environment = PTNetworkRequestEnvironment(configuration: configuration)
        let url: String
        if originalURL.hasPrefix("http") || !needGobal {
            url = originalURL
        } else {
            url = environment.serverAddress + originalURL
        }
        let headers = Self.prepareRequestHeaders(header: header,
                                                 jsonRequest: jsonRequest,
                                                 cachePolicy: cachePolicy,
                                                 configuration: configuration)
        return PTNetworkRequestContext(url: url, method: method, headers: headers)
    }

    /// 统一编码 Parameters，避免请求头声明为 JSON 时仍使用默认表单编码。
    private class func encodeParameters(_ parameters: Parameters?,
                                        into request: URLRequest,
                                        encoder: ParameterEncoding,
                                        jsonRequest: Bool) throws -> URLRequest {
        guard let parameters, !parameters.isEmpty else { return request }

        // 显式 JSON 标记或 JSON Content-Type 都表示参数必须进入 JSON body。
        let contentType = request.value(forHTTPHeaderField: "Content-Type")?.lowercased() ?? ""
        let shouldEncodeAsJSON = jsonRequest || contentType.contains("application/json")
        let effectiveEncoder: ParameterEncoding = shouldEncodeAsJSON
            ? JSONEncoding.default
            : encoder
        return try effectiveEncoder.encode(request, with: parameters)
    }
    
    private typealias ResponseParser<T> = @Sendable (_ url: String, _ response: HTTPURLResponse?, _ data: Data?) throws -> PTBaseStructModel<T>
    public typealias UploadResponseParser<T> = @Sendable (String, HTTPURLResponse?, Data?) throws -> PTBaseStructModel<T>
    
    // MARK: - ================= 5. 底层核心执行引擎 =================

    /// 所有非上传请求共用的执行边界：插件、mock、取消、去重和错误日志
    /// 在这里完成，避免 URL 参数请求和 Body 请求各自维护一套生命周期。
    private class func execute(url: String,
                               request: URLRequest,
                               uploadBody: Data? = nil) async throws -> PTNetworkResponseSnapshot {
        try await Network.share.executeRequest(url: url, request: request, uploadBody: uploadBody)
    }

    private func executeRequest(url: String,
                                request: URLRequest,
                                uploadBody: Data? = nil) async throws -> PTNetworkResponseSnapshot {
        var request = request
        let pluginSnapshot = plugins
        let configurationSnapshot = config
        for plugin in pluginSnapshot {
            await plugin.willSend(&request)
        }

        if request.isMock,
           let mockData = await NetworkCache.shared.read(request: request) {
            return Network.responseSnapshot(url: url, response: nil, data: mockData)
        }

        let policy: PTNetworkDedupPolicy = request.cachePolicyType == .none ? .none : .identical
        let finalRequest = request
        let session = self.session
        let realRequest: @Sendable () async throws -> PTNetworkResponseSnapshot = {
            let dataTask = uploadBody.map {
                session.upload($0, with: finalRequest).serializingData()
            } ?? session.request(finalRequest).serializingData()
            let response = await withTaskCancellationHandler(operation: {
                await dataTask.response
            }, onCancel: {
                dataTask.cancel()
            })
            try Task.checkCancellation()

            for plugin in pluginSnapshot {
                await plugin.didReceive(response.result, request: finalRequest, response: response.response)
            }
            await NetworkCache.shared.cleanIfNeeded(configuration: configurationSnapshot)

            switch response.result {
            case .success(let data):
                return Network.responseSnapshot(url: url, response: response.response, data: data)
            case .failure(let error):
                Network.logRequestFailure(url: url, error: error)
                throw error
            }
        }
        return try await RequestDeduplicator.shared.executeRaw(
            request: finalRequest,
            policy: policy,
            task: realRequest)
    }

    /// Compatibility executor for the old KakaJSON/Any APIs. It deliberately
    /// does not enter the Sendable deduplication pool; raw `Any` stays inside
    /// this legacy boundary and cannot leak into the modern executor.
    private class func executeLegacy(url: String,
                                     request: URLRequest,
                                     uploadBody: Data? = nil) async throws -> PTNetworkResponseSnapshot {
        try await Network.share.executeLegacyRequest(url: url, request: request, uploadBody: uploadBody)
    }

    private func executeLegacyRequest(url: String,
                                      request: URLRequest,
                                      uploadBody: Data? = nil) async throws -> PTNetworkResponseSnapshot {
        var request = request
        let pluginSnapshot = plugins
        let configurationSnapshot = config
        for plugin in pluginSnapshot {
            await plugin.willSend(&request)
        }

        if request.isMock,
           let mockData = await NetworkCache.shared.read(request: request) {
            return Network.responseSnapshot(url: url, response: nil, data: mockData)
        }

        let finalRequest = request
        let session = self.session
        let dataTask = uploadBody.map {
            session.upload($0, with: finalRequest).serializingData()
        } ?? session.request(finalRequest).serializingData()
        let response = await withTaskCancellationHandler(operation: {
            await dataTask.response
        }, onCancel: {
            dataTask.cancel()
        })
        try Task.checkCancellation()

        for plugin in pluginSnapshot {
            await plugin.didReceive(response.result, request: finalRequest, response: response.response)
        }
        await NetworkCache.shared.cleanIfNeeded(configuration: configurationSnapshot)

        switch response.result {
        case .success(let data):
            return Network.responseSnapshot(url: url, response: response.response, data: data)
        case .failure(let error):
            Network.logRequestFailure(url: url, error: error)
            throw error
        }
    }

    private class func _internalRequestApi(needGobal: Bool,
                                           urlStr: URLConvertible,
                                           method: HTTPMethod,
                                           header: HTTPHeaders?,
                                           parameters: Parameters?,
                                           cachePolicy: PTNetworkCachePolicy?,
                                           encoder: ParameterEncoding,
                                           jsonRequest: Bool) async throws -> PTNetworkResponseSnapshot {
        let context = try await makeRequestContext(urlStr: urlStr,
                                                   needGobal: needGobal,
                                                   method: method,
                                                   header: header,
                                                   jsonRequest: jsonRequest,
                                                   cachePolicy: cachePolicy)
        logRequestStart(url: context.url, parameters: parameters, headers: context.headers, method: context.method)

        var urlRequest = try URLRequest(url: context.url, method: context.method, headers: context.headers)
        urlRequest = try encodeParameters(parameters,
                                          into: urlRequest,
                                          encoder: encoder,
                                          jsonRequest: jsonRequest)
        return try await execute(url: context.url, request: urlRequest)
    }
    
    private class func _internalRequestBodyAPI(needGobal: Bool,
                                               urlStr: String,
                                               body: Data,
                                               header: HTTPHeaders?,
                                               method: HTTPMethod,
                                               cachePolicy: PTNetworkCachePolicy?) async throws -> PTNetworkResponseSnapshot {
        let context = try await makeRequestContext(urlStr: urlStr,
                                                   needGobal: needGobal,
                                                   method: method,
                                                   header: header,
                                                   jsonRequest: false,
                                                   cachePolicy: cachePolicy)
        var newHeader = context.headers
        if newHeader["Content-Type"] == nil { newHeader["Content-Type"] = "text/plain" }
        
        var dic: [String: any Any & Sendable] = [:]
        if let jsonObject = try? JSONSerialization.jsonObject(with: body, options: []), let dictionary = jsonObject as? [String: any Any & Sendable] { dic = dictionary }
        logRequestStart(url: context.url, parameters: dic, headers: newHeader, method: context.method)
        
        var urlRequest = try URLRequest(url: context.url, method: context.method, headers: newHeader)
        urlRequest.httpBody = body
        return try await execute(url: context.url, request: urlRequest, uploadBody: body)
    }

    private class func _internalLegacyRequestApi(needGobal: Bool,
                                                 urlStr: URLConvertible,
                                                 method: HTTPMethod,
                                                 header: HTTPHeaders?,
                                                 parameters: Parameters?,
                                                 cachePolicy: PTNetworkCachePolicy?,
                                                 encoder: ParameterEncoding,
                                                 jsonRequest: Bool) async throws -> PTNetworkResponseSnapshot {
        let context = try await makeRequestContext(urlStr: urlStr,
                                                   needGobal: needGobal,
                                                   method: method,
                                                   header: header,
                                                   jsonRequest: jsonRequest,
                                                   cachePolicy: cachePolicy)
        logRequestStart(url: context.url, parameters: parameters, headers: context.headers, method: context.method)
        var urlRequest = try URLRequest(url: context.url, method: context.method, headers: context.headers)
        urlRequest = try encodeParameters(parameters,
                                          into: urlRequest,
                                          encoder: encoder,
                                          jsonRequest: jsonRequest)
        return try await executeLegacy(url: context.url, request: urlRequest)
    }

    private class func _internalLegacyRequestBodyAPI(needGobal: Bool,
                                                     urlStr: String,
                                                     body: Data,
                                                     header: HTTPHeaders?,
                                                     method: HTTPMethod,
                                                     cachePolicy: PTNetworkCachePolicy?) async throws -> PTNetworkResponseSnapshot {
        let context = try await makeRequestContext(urlStr: urlStr,
                                                   needGobal: needGobal,
                                                   method: method,
                                                   header: header,
                                                   jsonRequest: false,
                                                   cachePolicy: cachePolicy)
        var newHeader = context.headers
        if newHeader["Content-Type"] == nil { newHeader["Content-Type"] = "text/plain" }
        var dic: [String: any Any & Sendable] = [:]
        if let jsonObject = try? JSONSerialization.jsonObject(with: body, options: []), let dictionary = jsonObject as? [String: any Any & Sendable] { dic = dictionary }
        logRequestStart(url: context.url, parameters: dic, headers: newHeader, method: context.method)
        var urlRequest = try URLRequest(url: context.url, method: context.method, headers: newHeader)
        urlRequest.httpBody = body
        return try await executeLegacy(url: context.url, request: urlRequest, uploadBody: body)
    }

    // English: Canonical instance request entry point using the instance's configuration, session, and plugins.
    // Español: Entrada canónica de solicitudes de instancia que usa la configuración, sesión y plugins de la instancia.
    // 中文：实例化请求的统一入口，始终使用实例自己的配置、Session 和插件。
    public func performCodableRequest<T: SmartCodableX & Sendable>(
        needGobal: Bool = true,
        urlStr: URLConvertible,
        method: HTTPMethod = .post,
        header: HTTPHeaders? = nil,
        parameters: Parameters? = nil,
        cachePolicy: PTNetworkCachePolicy? = nil,
        modelType: T.Type? = nil,
        encoder: ParameterEncoding = URLEncoding.default,
        jsonRequest: Bool = false) async throws -> PTBaseStructModel<T> {
        let context = try makeInstanceRequestContext(urlStr: urlStr,
                                                      needGobal: needGobal,
                                                      method: method,
                                                      header: header,
                                                      jsonRequest: jsonRequest,
                                                      cachePolicy: cachePolicy)
        Self.logRequestStart(url: context.url,
                             parameters: parameters,
                             headers: context.headers,
                             method: context.method)
        var urlRequest = try URLRequest(url: context.url,
                                        method: context.method,
                                        headers: context.headers)
        urlRequest = try Self.encodeParameters(parameters,
                                               into: urlRequest,
                                               encoder: encoder,
                                               jsonRequest: jsonRequest)
        let snapshot = try await executeRequest(url: context.url, request: urlRequest)
        return try Self.parseCodableResponse(snapshot, modelType: modelType)
    }
    
    private struct PTSafeUploadParamsBox: @unchecked Sendable {
        let media: Any
        let path: URLConvertible
    }
    
    private class func _internalFileUpload(needGobal: Bool,
                                            media: Any,
                                            path: URLConvertible,
                                            method: HTTPMethod,
                                            fileKey: String,
                                            params: [String: String]?,
                                            header: HTTPHeaders?,
                                            jsonRequest: Bool
    ) -> AsyncThrowingStream<PTNetworkUploadEvent, Error> {
        let safeBox = PTSafeUploadParamsBox(media: media, path: path)
        
        return AsyncThrowingStream { continuation in
            let cancellation = PTNetworkUploadCancellation()
            let preparationTask = Task {
                do {
                    // 1️⃣ 数据准备阶段
                    let preparedMedia = try await prepareMediaResource(media: safeBox.media)
                    let pathUrl = try await createURLRequest(urlStr: path, needGobal: needGobal)
                    let apiHeader = prepareRequestHeaders(header: header, jsonRequest: jsonRequest)
                    
                    // 2️⃣ 手动构建 MultipartFormData 对象，取代闭包构建法！
                    // 这将消除闭包内捕获局部变量带来的并发安全隐患
                    let multipartData = MultipartFormData()
                    
                    // 填充主文件
                    switch preparedMedia {
                    case .data(let data, let mimeType, let fileName):
                        multipartData.append(data, withName: fileKey, fileName: fileName, mimeType: mimeType)
                    case .fileURL(let url, let mimeType, let fileName):
                        multipartData.append(url, withName: fileKey, fileName: fileName, mimeType: mimeType)
                    }
                    
                    // 填充附加参数
                    params?.forEach { key, value in
                        if let data = value.data(using: .utf8) {
                            multipartData.append(data, withName: key)
                        }
                    }
                    
                    let session = Network.share.session
                    
                    // 3️⃣ 发起请求，并将进度和响应转换为值类型快照。
                    guard !Task.isCancelled else {
                        continuation.finish(throwing: CancellationError())
                        return
                    }

                    let uploadRequest = session.upload(multipartFormData: multipartData, to: pathUrl, method: method, headers: apiHeader)
                        .uploadProgress { @Sendable progress in
                            let snapshot = PTProgressSnapshot(completedUnitCount: progress.completedUnitCount,
                                                               totalUnitCount: progress.totalUnitCount,
                                                               fractionCompleted: progress.fractionCompleted)
                            continuation.yield(PTNetworkUploadEvent(progress: snapshot, response: nil))
                        }
                        .response { @Sendable resp in
                            switch resp.result {
                            case .success(_):
                                let response = responseSnapshot(url: pathUrl,
                                                                 response: resp.response,
                                                                 data: resp.data)
                                let progress = PTProgressSnapshot(completedUnitCount: 1,
                                                                   totalUnitCount: 1,
                                                                   fractionCompleted: 1)
                                continuation.yield(PTNetworkUploadEvent(progress: progress, response: response))
                                continuation.finish()
                            case .failure(let error):
                                logRequestFailure(url: pathUrl, error: error)
                                continuation.finish(throwing: error)
                            }
                        }
                    cancellation.install(request: uploadRequest)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            cancellation.install(preparationTask: preparationTask)
            continuation.onTermination = { @Sendable _ in
                cancellation.cancel()
            }
        }
    }
    
    // 🌟 步骤 3：将媒体处理逻辑提取为一个独立的 async 方法
    private class func prepareMediaResource(media: Any) async throws -> PreparedUploadMedia {
        if let phasset = media as? PHAsset {
            switch phasset.mediaType {
            case .image:
                let image = await phasset.asyncImage()
                guard let findImage = image else { throw PTNetworkError.uploadDataError("Image data error") }
                let canPNG = findImage.pngData() != nil
                guard let imageData = findImage.pngData() ?? findImage.jpegData(compressionQuality: 0.6) else {
                    throw PTNetworkError.uploadDataError("Image data error")
                }
                let ext = canPNG ? "png" : "jpg"
                let fileName = "image_\(Int(Date().timeIntervalSince1970)).\(ext)"
                return .data(imageData, mimeType: MimeTypeHelper.mimeType(for: ext), fileName: fileName)
                
            case .video, .audio:
                // 使用 withCheckedThrowingContinuation 将基于闭包的回调转换为 Swift 的 async/await
                let urlAsset: AVURLAsset = try await withCheckedThrowingContinuation { cont in
                    phasset.converPHAssetToAVURLAsset { asset in
                        if let asset = asset {
                            cont.resume(returning: asset)
                        } else {
                            cont.resume(throwing: PTNetworkError.uploadDataError("Video/Audio data error"))
                        }
                    }
                }
                
                let url = urlAsset.url
                let ext = url.pathExtension.lowercased()
                let prefix = phasset.mediaType == .video ? "video" : "audio"
                let fileName = "\(prefix)_\(Int(Date().timeIntervalSince1970)).\(ext)"
                return .fileURL(url, mimeType: MimeTypeHelper.mimeType(for: ext), fileName: fileName)
                
            default:
                throw PTNetworkError.uploadDataError("Unknown data error")
            }
            
        } else if let findImage = media as? UIImage {
            let canPNG = findImage.pngData() != nil
            guard let imageData = findImage.pngData() ?? findImage.jpegData(compressionQuality: 0.6) else {
                throw PTNetworkError.uploadDataError("Image data error")
            }
            let ext = canPNG ? "png" : "jpg"
            let fileName = "image_\(Int(Date().timeIntervalSince1970)).\(ext)"
            return .data(imageData, mimeType: MimeTypeHelper.mimeType(for: ext), fileName: fileName)
            
        } else if let findUrl = media as? URL {
            return try processUploadFileURL(findUrl)
            
        } else if let findString = media as? String, let findUrl = URL(string: findString) {
            return try processUploadFileURL(findUrl)
            
        } else {
            throw PTNetworkError.uploadDataError("Unsupported media type")
        }
    }
    
    // 🌟 步骤 4：独立处理 FileProvider 沙盒文件的拷贝逻辑
    private class func processUploadFileURL(_ findUrl: URL) throws -> PreparedUploadMedia {
        guard findUrl.isFileURL else {
            throw PTNetworkError.uploadDataError("Need to download first")
        }
        
        let uploadURL: URL
        if findUrl.path.contains("File Provider Storage") || findUrl.path.contains("com.apple.FileProvider") {
            let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(findUrl.lastPathComponent)
            try? FileManager.default.removeItem(at: tmpURL)
            try? FileManager.default.copyItem(at: findUrl, to: tmpURL)
            uploadURL = tmpURL
        } else {
            uploadURL = findUrl
        }
        
        let ext = uploadURL.pathExtension.lowercased()
        let fileName = uploadURL.lastPathComponent
        return .fileURL(uploadURL, mimeType: MimeTypeHelper.mimeType(for: ext), fileName: fileName)
    }
    
    /// 核心：通用多图并发上传引擎 (TaskGroup 高性能版)
    private class func _internalImageUpload(
        needGobal: Bool, images: [UIImage]?, path: URLConvertible, method: HTTPMethod, fileKey: [String], params: [String: String]?,
        header: HTTPHeaders?, jsonRequest: Bool, pngData: Bool
    ) -> AsyncThrowingStream<PTNetworkUploadEvent, Error> {
        
        AsyncThrowingStream { continuation in
            let cancellation = PTNetworkUploadCancellation()
            let preparationTask = Task {
                do {
                    let pathUrl = try await createURLRequest(urlStr: path, needGobal: needGobal)
                    let apiHeader = prepareRequestHeaders(header: header, jsonRequest: jsonRequest)
                    
                    // 🚀 优化点 1：开启 TaskGroup 并行处理所有图片的压缩任务，充分利用多核 CPU
                    var processedImages: [PreparedImageResult] = []
                    
                    // 确保有图片才进行处理
                    if let rawImages = images, !rawImages.isEmpty {
                        processedImages = await withTaskGroup(of: PreparedImageResult?.self) { group in
                            var results: [PreparedImageResult] = []
                            
                            for (index, image) in rawImages.enumerated() {
                                // 将每张图片的压缩分配给独立的并发任务
                                group.addTask {
                                    // 模拟 autoreleasepool 以防单次循环内存堆积
                                    return autoreleasepool {
                                        let data = pngData ? image.pngData() : image.jpegData(compressionQuality: 0.6)
                                        guard let imageData = data else { return nil }
                                        
                                        let key = fileKey[safe: index] ?? "image"
                                        let ext = pngData ? "png" : "jpg"
                                        
                                        return PreparedImageResult(
                                            key: key,
                                            fileName: "image_\(index).\(ext)",
                                            mimeType: pngData ? "image/png" : "image/jpeg",
                                            data: imageData
                                        )
                                    }
                                }
                            }
                            
                            // 收集并发处理完成的结果
                            for await result in group {
                                if let validResult = result {
                                    results.append(validResult)
                                }
                            }
                            return results
                        }
                    }
                    
                    // 🚀 优化点 2：等所有图片都处理成 Data 后，再交给 Alamofire。
                    let session = Network.share.session
                    guard !Task.isCancelled else {
                        continuation.finish(throwing: CancellationError())
                        return
                    }

                    let uploadRequest = session.upload(multipartFormData: { multipartFormData in
                        
                        // 1. 追加已处理好的图片数据
                        for img in processedImages {
                            multipartFormData.append(img.data, withName: img.key, fileName: img.fileName, mimeType: img.mimeType)
                        }
                        
                        // 2. 追加普通文本参数
                        params?.forEach { key, value in
                            if let data = value.data(using: .utf8) {
                                multipartFormData.append(data, withName: key)
                            }
                        }
                        
                    }, to: pathUrl, method: method, headers: apiHeader)
                    .uploadProgress { @Sendable progress in
                        let snapshot = PTProgressSnapshot(completedUnitCount: progress.completedUnitCount,
                                                           totalUnitCount: progress.totalUnitCount,
                                                           fractionCompleted: progress.fractionCompleted)
                        continuation.yield(PTNetworkUploadEvent(progress: snapshot, response: nil))
                    }
                    .response { resp in
                        switch resp.result {
                        case .success(_):
                            let response = responseSnapshot(url: pathUrl,
                                                             response: resp.response,
                                                             data: resp.data)
                            let progress = PTProgressSnapshot(completedUnitCount: 1,
                                                               totalUnitCount: 1,
                                                               fractionCompleted: 1)
                            continuation.yield(PTNetworkUploadEvent(progress: progress, response: response))
                            continuation.finish()
                        case .failure(let error):
                            logRequestFailure(url: pathUrl, error: error)
                            continuation.finish(throwing: error)
                        }
                    }
                    cancellation.install(request: uploadRequest)
                } catch { continuation.finish(throwing: error) }
            }
            cancellation.install(preparationTask: preparationTask)
            continuation.onTermination = { @Sendable _ in
                cancellation.cancel()
            }
        }
    }
    
    // MARK: - ================= 6. 🌟 强类型解析层：SmartCodable 暴露接口 =================
    
    private static func parseCodableResponse<T: SmartCodableX & Sendable>(_ snapshot: PTNetworkResponseSnapshot,
                                                                            modelType: T.Type?) throws -> PTBaseStructModel<T> {
        var (result, jsonString) = try validateAndPreprocessResponse(snapshot) as (PTBaseStructModel<T>, String)
        if !jsonString.isEmpty, let modelType = modelType {
            if let model = modelType.deserialize(from: jsonString) {
                result.customerModel = model
            } else { throw PTNetworkError.modelExplainFail }
        }
        return result
    }

    private static func progressValue(from snapshot: PTProgressSnapshot) -> Progress {
        let total = max(snapshot.totalUnitCount, 1)
        let progress = Progress(totalUnitCount: total)
        progress.completedUnitCount = min(max(snapshot.completedUnitCount, 0), total)
        return progress
    }

    // KakaJSON metatypes are immutable lookup tokens kept only by the legacy adapter.
    // Los metatipos de KakaJSON son tokens inmutables que conserva únicamente el adaptador heredado.
    // KakaJSON 元类型是不可变查找标记，只由旧版兼容适配器持有。
    private struct PTLegacyModelTypeBox: @unchecked Sendable {
        let value: Convertible.Type?
    }

    private static func codableUploadStream<T: SmartCodableX & Sendable>(
        source: AsyncThrowingStream<PTNetworkUploadEvent, Error>,
        modelType: T.Type?
    ) -> AsyncThrowingStream<(progress: Progress, response: PTBaseStructModel<T>?), Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await event in source {
                        let response = try event.response.map {
                            try parseCodableResponse($0, modelType: modelType)
                        }
                        continuation.yield((progressValue(from: event.progress), response))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    @preconcurrency
    private static func legacyUploadStream(
        source: AsyncThrowingStream<PTNetworkUploadEvent, Error>,
        modelType: Convertible.Type?
    ) -> AsyncThrowingStream<(progress: Progress, response: PTBaseStructModel<Any>?), Error> {
        let typeBox = PTLegacyModelTypeBox(value: modelType)
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await event in source {
                        let response = try event.response.map {
                            try parseResponse($0, modelType: typeBox.value)
                        }
                        continuation.yield((progressValue(from: event.progress), response))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// 🌟 便捷重载方法：当接口只返回成功/失败时使用，底层自动代劳传入占位模型
    class public func requestCodableApi(needGobal: Bool = true, urlStr: URLConvertible, method: HTTPMethod = .post, header: HTTPHeaders? = nil, parameters: Parameters? = nil, cachePolicy: PTNetworkCachePolicy? = nil, encoder: ParameterEncoding = URLEncoding.default, jsonRequest: Bool = false) async throws -> PTBaseStructModel<PTDummyModel> {
        return try await self.requestCodableApi(needGobal: needGobal, urlStr: urlStr, method: method, header: header, parameters: parameters, cachePolicy: cachePolicy, modelType: PTDummyModel.self, encoder: encoder, jsonRequest: jsonRequest)
    }
    
    /// 核心项目调用总接口
    class public func requestCodableApi<T: SmartCodableX & Sendable>(needGobal: Bool = true, urlStr: URLConvertible, method: HTTPMethod = .post, header: HTTPHeaders? = nil, parameters: Parameters? = nil, cachePolicy: PTNetworkCachePolicy? = nil, modelType: T.Type? = nil, encoder: ParameterEncoding = URLEncoding.default, jsonRequest: Bool = false) async throws -> PTBaseStructModel<T> {
        let snapshot = try await _internalRequestApi(needGobal: needGobal,
                                                     urlStr: urlStr,
                                                     method: method,
                                                     header: header,
                                                     parameters: parameters,
                                                     cachePolicy: cachePolicy,
                                                     encoder: encoder,
                                                     jsonRequest: jsonRequest)
        return try parseCodableResponse(snapshot, modelType: modelType)
    }
    
    public class func requestCodableBodyAPI<T: SmartCodableX & Sendable>(needGobal: Bool = true, urlStr: String, body: Data, header: HTTPHeaders? = nil, method: HTTPMethod = .post,
                                                                         cachePolicy: PTNetworkCachePolicy? = nil, modelType: T.Type? = nil) async throws -> PTBaseStructModel<T> {
        let snapshot = try await _internalRequestBodyAPI(needGobal: needGobal,
                                                         urlStr: urlStr,
                                                         body: body,
                                                         header: header,
                                                         method: method,
                                                         cachePolicy: cachePolicy)
        return try parseCodableResponse(snapshot, modelType: modelType)
    }
    
    class public func fileCodableUpload<T: SmartCodableX & Sendable>(needGobal: Bool = true, media: Any, path: URLConvertible, method: HTTPMethod = .post, fileKey: String = "",
                                                                     params: [String: String]? = nil, header: HTTPHeaders? = nil, modelType: T.Type? = nil, jsonRequest: Bool = false) -> AsyncThrowingStream<(progress: Progress, response: PTBaseStructModel<T>?), Error> {
        let source = _internalFileUpload(needGobal: needGobal,
                                         media: media,
                                         path: path,
                                         method: method,
                                         fileKey: fileKey,
                                         params: params,
                                         header: header,
                                         jsonRequest: jsonRequest)
        return codableUploadStream(source: source, modelType: modelType)
    }
    
    class public func imageCodableUpload<T: SmartCodableX & Sendable>(needGobal: Bool = true, images: [UIImage]?, path: URLConvertible, method: HTTPMethod = .post, fileKey: [String] = ["images"], params: [String: String]? = nil, header: HTTPHeaders? = nil, modelType: T.Type? = nil, jsonRequest: Bool = false, pngData: Bool = true) -> AsyncThrowingStream<(progress: Progress, response: PTBaseStructModel<T>?), Error> {
        let source = _internalImageUpload(needGobal: needGobal,
                                          images: images,
                                          path: path,
                                          method: method,
                                          fileKey: fileKey,
                                          params: params,
                                          header: header,
                                          jsonRequest: jsonRequest,
                                          pngData: pngData)
        return codableUploadStream(source: source, modelType: modelType)
    }
    
    // MARK: - ================= 7. ⚠️ 动态兼容层：KakaJSON 旧版保留接口 =================
    
    private static func parseResponse(_ snapshot: PTNetworkResponseSnapshot,
                                      modelType: Convertible.Type?) throws -> PTBaseStructModel<Any> {
        var (result, jsonString) = try validateAndPreprocessResponse(snapshot) as (PTBaseStructModel<Any>, String)
        if !jsonString.isEmpty, let modelType = modelType {
            if let model = jsonString.kj.model(modelType) {
                result.customerModel = model
            } else { throw PTNetworkError.modelExplainFail }
        }
        return result
    }
    
    @available(*, deprecated, message: "Use requestCodableBodyAPI(_:body:modelType:) with a Sendable model instead")
    public class func requestBodyAPI(needGobal: Bool = true, urlStr: String, body: Data, header: HTTPHeaders? = nil, method: HTTPMethod = .post, cachePolicy: PTNetworkCachePolicy? = nil, modelType: Convertible.Type? = nil) async throws -> PTBaseStructModel<Any> {
        let snapshot = try await _internalLegacyRequestBodyAPI(needGobal: needGobal,
                                                               urlStr: urlStr,
                                                               body: body,
                                                               header: header,
                                                               method: method,
                                                               cachePolicy: cachePolicy)
        return try parseResponse(snapshot, modelType: modelType)
    }
    
    @available(*, deprecated, message: "Use requestCodableApi(_:modelType:) with a Sendable model instead")
    class public func requestApi(needGobal: Bool = true, urlStr: URLConvertible, method: HTTPMethod = .post, header: HTTPHeaders? = nil, parameters: Parameters? = nil,
                                 cachePolicy: PTNetworkCachePolicy? = nil, modelType: Convertible.Type? = nil, encoder: ParameterEncoding = URLEncoding.default, jsonRequest: Bool = false) async throws -> PTBaseStructModel<Any> {
        let snapshot = try await _internalLegacyRequestApi(needGobal: needGobal,
                                                            urlStr: urlStr,
                                                            method: method,
                                                            header: header,
                                                            parameters: parameters,
                                                            cachePolicy: cachePolicy,
                                                            encoder: encoder,
                                                            jsonRequest: jsonRequest)
        return try parseResponse(snapshot, modelType: modelType)
    }
    
    @available(*, deprecated, message: "Use the Codable upload API with a Sendable model instead")
    class public func fileUpload(needGobal: Bool = true, media: Any, path: URLConvertible, method: HTTPMethod = .post, fileKey: String = "", params: [String: String]? = nil, header: HTTPHeaders? = nil, modelType: Convertible.Type? = nil, jsonRequest: Bool = false) -> AsyncThrowingStream<(progress: Progress, response: PTBaseStructModel<Any>?), Error> {
        let source = _internalFileUpload(needGobal: needGobal,
                                         media: media,
                                         path: path,
                                         method: method,
                                         fileKey: fileKey,
                                         params: params,
                                         header: header,
                                         jsonRequest: jsonRequest)
        return legacyUploadStream(source: source, modelType: modelType)
    }
    
    @available(*, deprecated, message: "Use imageCodableUpload with a Sendable model instead")
    class public func imageUpload(needGobal: Bool = true, images: [UIImage]?, path: URLConvertible, method: HTTPMethod = .post, fileKey: [String] = ["images"], params: [String: String]? = nil, header: HTTPHeaders? = nil, modelType: Convertible.Type? = nil, jsonRequest: Bool = false, pngData: Bool = true) -> AsyncThrowingStream<(progress: Progress, response: PTBaseStructModel<Any>?), Error> {
        let source = _internalImageUpload(needGobal: needGobal,
                                          images: images,
                                          path: path,
                                          method: method,
                                          fileKey: fileKey,
                                          params: params,
                                          header: header,
                                          jsonRequest: jsonRequest,
                                          pngData: pngData)
        return legacyUploadStream(source: source, modelType: modelType)
    }
    
    // MARK: - ================= 8. 下载引擎与流式控制 =================
    
    // English: Build the download session once from the same initialization snapshot.
    // Español: Construye una sola sesión de descarga usando la misma instantánea inicial.
    // 中文：使用同一份初始化快照只创建一次下载 Session。
    private static func makeDownloadSession(configuration configurationSnapshot: PTNetworkConfig) -> Session {
        let urlConfiguration = URLSessionConfiguration.default
        urlConfiguration.timeoutIntervalForRequest = configurationSnapshot.downloadRequestTimeout
        urlConfiguration.timeoutIntervalForResource = configurationSnapshot.resourceTimeout
        urlConfiguration.httpMaximumConnectionsPerHost = 6
        var protocols = urlConfiguration.protocolClasses ?? []
        protocols.insert(PTCustomHTTPProtocol.self, at: 0)
        urlConfiguration.protocolClasses = protocols
        return Session(configuration: urlConfiguration)
    }

    private var downloadSession: Session {
        downloadSessionLock.lock()
        defer { downloadSessionLock.unlock() }
        if let storedDownloadSession { return storedDownloadSession }
        let newSession = Self.makeDownloadSession(configuration: config)
        storedDownloadSession = newSession
        return newSession
    }
    
    actor DownloadStore {
        var tasks: [String: DownloadTask] = [:]
        public func get(_ url: String) -> DownloadTask? { tasks[url] }
        func set(_ url: String, task: DownloadTask) { tasks[url] = task }
        func remove(_ url: String) { tasks[url] = nil }
    }
    private let store = DownloadStore()
    
    // 🌟 核心升级：直接声明为 actor，彻底告别 @unchecked 和 NSLock，编译器自动保证线程绝对安全！
    final actor DownloadTask {
        let url: String
        let destination: @Sendable (URL, HTTPURLResponse) -> (URL, DownloadRequest.Options)
        var request: DownloadRequest?
        var resumeData: Data?
        
        private var progressHandlers: [FileDownloadProgress] = []
        private var successHandlers: [FileDownloadSuccess] = []
        private var failHandlers: [FileDownloadFail] = []
        private var lastProgressTime: CFTimeInterval = 0
        private(set) var isDownloading: Bool = false
        
        init(url: String, destination: @escaping @Sendable (URL, HTTPURLResponse) -> (URL, DownloadRequest.Options)) {
            self.url = url
            self.destination = destination
        }
        
        func appendHandlers(progress: FileDownloadProgress?, success: FileDownloadSuccess?, fail: FileDownloadFail?) {
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
            if isDownloading { return }
            isDownloading = true
            
            if let data = resumeData { request = session.download(resumingWith: data, to: destination) }
            else { request = session.download(url, to: destination) }
            
            // English: Capture Sendable progress values before entering the actor.
            // Español: Captura valores de progreso Sendable antes de entrar en el actor.
            // 中文：在进入 actor 前先捕获 Sendable 进度值。
            request?.downloadProgress(queue: .global()) { [weak self] p in
                guard let self = self else { return }
                let snapshot = PTProgressSnapshot(completedUnitCount: p.completedUnitCount,
                                                   totalUnitCount: p.totalUnitCount,
                                                   fractionCompleted: p.fractionCompleted)
                Task { await self.handleProgress(snapshot) }
            }
            
            request?.response { [weak self] resp in
                guard let self = self else { return }
                Task { await self.handleResponse(resp) }
            }
        }
        
        // English: Process an immutable progress snapshot inside the actor.
        // Español: Procesa una instantánea de progreso inmutable dentro del actor.
        // 中文：在 actor 内处理不可变的进度快照。
        private func handleProgress(_ snapshot: PTProgressSnapshot) {
            let now = CACurrentMediaTime()
            let isFinished = snapshot.totalUnitCount > 0
                && snapshot.completedUnitCount >= snapshot.totalUnitCount
            if now - lastProgressTime > 0.1 || isFinished {
                lastProgressTime = now
                let handlers = progressHandlers
                // English: Rebuild only the legacy scalar callback values on MainActor.
                // Español: Reconstruye solo los valores escalares del callback heredado en MainActor.
                // 中文：只在 MainActor 上重建旧回调需要的标量值。
                for cb in handlers {
                    Task { @MainActor in
                        cb(snapshot.completedUnitCount,
                           snapshot.totalUnitCount,
                           snapshot.fractionCompleted)
                    }
                }
            }
        }
        
        // 🌟 专门处理结束回调的内部方法，运行在 actor 隔离区内
        private func handleResponse(_ resp: AFDownloadResponse<URL?>) async {
            isDownloading = false
            resumeData = nil
            
            let currentFails = failHandlers
            let currentSuccesses = successHandlers
            clearHandlers() // 清空回调防止内存泄漏
            
            if let error = resp.error {
                if error.isExplicitlyCancelledError || (error.underlyingError as? URLError)?.code == .cancelled {
                    resumeData = resp.resumeData
                } else {
                    await Network.share.store.remove(self.url)
                }
                for cb in currentFails { Task { @MainActor in cb(error) } }
            } else {
                await Network.share.store.remove(self.url)
                for cb in currentSuccesses { Task { @MainActor in cb(resp) } }
            }
        }
        
        func suspend() {
            isDownloading = false
            request?.cancel { [weak self] data in
                Task { await self?.saveResumeData(data) }
            }
        }
        
        private func saveResumeData(_ data: Data?) {
            self.resumeData = data
            self.request = nil
        }
        
        func cancel() {
            isDownloading = false
            request?.cancel()
        }
    }
    
    @MainActor public func download(fileUrl: String, saveFilePath: String, queue: DispatchQueue? = .main, progress: FileDownloadProgress? = nil, success: FileDownloadSuccess? = nil, fail: FileDownloadFail? = nil) {
        guard fileUrl.isURL(), !fileUrl.stringIsEmpty() else { fail?(AFError.invalidURL(url: "PT URL Error")); return }
        let dest: @Sendable (URL, HTTPURLResponse) -> (URL, DownloadRequest.Options) = { _, _ in
            return (URL(fileURLWithPath: saveFilePath), [.removePreviousFile, .createIntermediateDirectories])
        }
        
        Task {
            let task: DownloadTask
            if let existing = await store.get(fileUrl) {
                task = existing
                await task.appendHandlers(progress: progress, success: success, fail: fail)
            } else {
                task = DownloadTask(url: fileUrl, destination: dest)
                await task.appendHandlers(progress: progress, success: success, fail: fail)
                await store.set(fileUrl, task: task)
            }
            
            let isDownloading = await task.isDownloading
            if !isDownloading { await task.start(session: downloadSession) }
        }
    }
    
    @MainActor public func download(fileUrl: String, saveFilePath: String, progress: FileDownloadProgress? = nil) async throws -> URL {
        let cancellationBridge = PTDownloadCancellationBridge()
        // English: Keep cancellation outside the MainActor so the compiler and runtime use one clear boundary.
        // Español: Mantiene la cancelación fuera de MainActor para que el compilador y el tiempo de ejecución usen un límite claro.
        // 中文：让取消逻辑保持在 MainActor 之外，使编译器和运行时都只有一个清晰边界。
        return try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                cancellationBridge.install(resumeCancellation: {
                    continuation.resume(throwing: CancellationError())
                })
                self.download(fileUrl: fileUrl, saveFilePath: saveFilePath, queue: nil, progress: progress, success: { response in
                    guard cancellationBridge.finish() else { return }
                    if let fileURL = response.fileURL { continuation.resume(returning: fileURL) }
                    else { continuation.resume(throwing: PTNetworkError.downloadFail) }
                }, fail: { error in
                    guard cancellationBridge.finish() else { return }
                    continuation.resume(throwing: error ?? PTNetworkError.downloadFail)
                })
                cancellationBridge.install(cancelUnderlying: { [weak self] in
                    self?.cancel(fileUrl: fileUrl)
                })
            }
        }, onCancel: {
            cancellationBridge.cancel()
        })
    }
    
    public func suspend(fileUrl: String) { Task { await store.get(fileUrl)?.suspend() } }
    public func resume(fileUrl: String)  { Task { await store.get(fileUrl)?.start(session: downloadSession) } }
    public func cancel(fileUrl: String)  { Task { if let task = await store.get(fileUrl) { await store.remove(fileUrl); await task.cancel() } } }
    
    /// 🌟 全新现代化的流式下载方法，支持在业务层循环获取进度
    public func downloadAsyncStream(fileUrl: String, saveFilePath: String) -> AsyncThrowingStream<(progress: Double, fileURL: URL?), Error> {
        AsyncThrowingStream { continuation in
            Task { @MainActor in
                self.download(fileUrl: fileUrl, saveFilePath: saveFilePath, queue: nil) { _, _, progress in
                    continuation.yield((progress, nil))
                } success: { response in
                    if let fileURL = response.fileURL {
                        continuation.yield((1.0, fileURL))
                        continuation.finish()
                    } else { continuation.finish(throwing: PTNetworkError.downloadFail) }
                } fail: { error in continuation.finish(throwing: error ?? PTNetworkError.downloadFail) }
            }
            continuation.onTermination = { @Sendable _ in
                self.cancel(fileUrl: fileUrl)
            }
        }
    }
}

// MARK: - ================= 9. 监控探针与耗时剖析 =================

public final class NetworkSessionDelegate:NSObject,URLSessionTaskDelegate {
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
