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
import CoreTelephony
import Photos
#if SWIFT_PACKAGE
import ptools
import PooToolsLoading
#endif
#if canImport(PToolsCore)
import PToolsCore
#endif
#if canImport(PToolsModelCore)
import PToolsModelCore
#endif
#if SWIFT_PACKAGE
import PToolsNetworkModelCore
#endif
#if SWIFT_PACKAGE
import PToolsModelLegacyKakaJSON
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

    // English: Typed categories keep the new executor independent from Alamofire error types.
    // Español: Las categorías tipadas mantienen el nuevo ejecutor independiente de los errores de Alamofire.
    // 中文：类型化分类让新的执行器不依赖 Alamofire 错误类型。
    case transport(domain: String, code: Int, message: String)
    case timeout
    case cancelled
    case httpStatus(code: Int, body: Data?)
    case decode(String)
    case encode(String)
    case cache(String)
    case authentication(String)
    case unknown(String)
    
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
        case .transport(_, _, let message): return message
        case .timeout: return "PT Network request timed out"
        case .cancelled: return "PT Network request cancelled"
        case .httpStatus(let code, _): return "PT Network HTTP status \(code)"
        case .decode(let message): return "PT Network decode failed: \(message)"
        case .encode(let message): return "PT Network encode failed: \(message)"
        case .cache(let message): return "PT Network cache failed: \(message)"
        case .authentication(let message): return "PT Network authentication failed: \(message)"
        case .unknown(let message): return message
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
        case .transport(_, let code, _): return code
        case .timeout: return NSURLErrorTimedOut
        case .cancelled: return NSURLErrorCancelled
        case .httpStatus(let code, _): return code
        case .decode: return 9999999910
        case .encode: return 9999999911
        case .cache: return 9999999912
        case .authentication: return 9999999913
        case .unknown: return 9999999914
        }
    }
    
    /// 错误域
    public static var errorDomain: String {
        return "com.pt.network.error"
    }

    public static func typed(from error: Error) -> PTNetworkError {
        if let error = error as? PTNetworkError { return error }
        if let urlError = error as? URLError {
            if urlError.code == .cancelled { return .cancelled }
            if urlError.code == .timedOut { return .timeout }
            return .transport(domain: NSURLErrorDomain,
                              code: urlError.errorCode,
                              message: urlError.localizedDescription)
        }
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            if nsError.code == NSURLErrorCancelled { return .cancelled }
            if nsError.code == NSURLErrorTimedOut { return .timeout }
            return .transport(domain: nsError.domain,
                              code: nsError.code,
                              message: nsError.localizedDescription)
        }
        return .unknown(nsError.localizedDescription)
    }
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
    let downloadSessionLock = NSLock()
    var storedDownloadSession: Session?

    // English: Freeze transport construction values while keeping request environment values dynamic.
    // Español: Congela los valores de construcción del transporte y mantiene dinámico el entorno de solicitudes.
    // 中文：冻结传输层构造参数，同时保留请求环境参数的动态性。
    let sessionConfiguration: PTNetworkSessionConfiguration
    let protocolClasses: [AnyClass]
    // English: Providers supply per-request values while the session configuration remains immutable.
    // Español: Los proveedores suministran valores por solicitud mientras la configuración de sesión permanece inmutable.
    // 中文：Provider 提供每次请求的动态值，同时保持 Session 配置不可变。
    let credentialProvider: (any PTCredentialProvider)?
    let headerProvider: (any PTRequestHeaderProvider)?
    let endpointResolver: (any PTEndpointResolver)?
    private let authRefreshProvider: (any PTNetworkAuthRefreshProvider)?
    private let authRefreshCoordinator = PTNetworkAuthRefreshCoordinator()

    // English: New instances snapshot their configuration and plugins; the legacy singleton remains available.
    // Español: Las nuevas instancias capturan su configuración y plugins; el singleton heredado sigue disponible.
    // 中文：新实例会固定初始配置和插件；旧单例入口继续可用。
    public init(configuration: PTNetworkConfig = PTNetworkConfig(),
                plugins: [NetworkPlugin] = [PTNetworkCachePlugin()],
                protocolClasses: [AnyClass] = [],
                credentialProvider: (any PTCredentialProvider)? = nil,
                headerProvider: (any PTRequestHeaderProvider)? = nil,
                endpointResolver: (any PTEndpointResolver)? = nil,
                authRefreshProvider: (any PTNetworkAuthRefreshProvider)? = nil) {
        _config = configuration
        _plugins = plugins
        sessionConfiguration = PTNetworkSessionConfiguration(configuration: configuration)
        self.protocolClasses = protocolClasses
        self.credentialProvider = credentialProvider
        self.headerProvider = headerProvider
        self.endpointResolver = endpointResolver
        self.authRefreshProvider = authRefreshProvider
    }

    public var plugins: [NetworkPlugin] {
        get {
            pluginsLock.withLock { _plugins }
        }
        set {
            pluginsLock.withLock { _plugins = newValue }
        }
    }

    // English: New code can inspect a stable plugin snapshot without mutating the legacy property.
    // Español: El código nuevo puede inspeccionar una instantánea estable sin mutar la propiedad heredada.
    // 中文：新代码可以读取稳定的插件快照，不必修改旧的可变属性。
    public var pluginRegistry: PTNetworkPluginRegistry {
        PTNetworkPluginRegistry(plugins: plugins)
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
    let store = DownloadStore()
    
    private let configLock = NSLock()
    private var _config = PTNetworkConfig()
    
    // 通过 Bundle 底层特征判断是否是 App Store 环境。
    // Determina si el paquete pertenece al entorno de App Store mediante una característica del Bundle.
    // Use Bundle 的底层特征判断当前是否为 App Store 环境。
    static let isAppStoreEnvironment: Bool = {
#if DEBUG
        return false
#else
        if Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" {
            return false
        }
        // 业界标准方案：App Store 正式包在苹果后台处理后，会剥离 embedded.mobileprovision 文件。
        // 而 TestFlight、AdHoc 或企业包都会保留这个文件。我们通过判断这个文件是否存在来区分。
        let hasProvision = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") != nil
        return !hasProvision
#endif
    }()

    /// 测试包（Debug、TestFlight、AdHoc）允许输出响应调试信息，App Store 包不输出响应内容。
    static var shouldLogResponseDetails: Bool {
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
    private static func makeSession(configuration configurationSnapshot: PTNetworkSessionConfiguration,
                                    protocolClasses: [AnyClass]) -> Session {
        let urlConfiguration = URLSessionConfiguration.default
        urlConfiguration.timeoutIntervalForRequest = configurationSnapshot.requestTimeout
        urlConfiguration.timeoutIntervalForResource = configurationSnapshot.resourceTimeout
        urlConfiguration.waitsForConnectivity = configurationSnapshot.waitsForConnectivity
        urlConfiguration.requestCachePolicy = .useProtocolCachePolicy
        if !protocolClasses.isEmpty {
            var protocols = urlConfiguration.protocolClasses ?? []
            protocols.insert(contentsOf: protocolClasses, at: 0)
            urlConfiguration.protocolClasses = protocols
        }
        urlConfiguration.urlCache = URLCache(memoryCapacity: configurationSnapshot.memoryCapacity,
                                             diskCapacity: configurationSnapshot.diskCapacity)
        return Session(configuration: urlConfiguration, interceptor: RetryHandler(configuration: configurationSnapshot))
    }

    // English: Keep the session internal so the upload extension uses the same instance-owned session.
    // Español: Mantiene la sesión interna para que la extensión de carga use la sesión de la instancia propietaria.
    // 中文：将 Session 保持为模块内可见，让上传扩展使用实例自己的 Session。
    var session: Session {
        sessionLock.lock()
        defer { sessionLock.unlock() }
        if let storedSession { return storedSession }
        let newSession = Self.makeSession(configuration: sessionConfiguration,
                                          protocolClasses: protocolClasses)
        storedSession = newSession
        return newSession
    }
    
    @available(*, deprecated, message: "Use PTNetworkHUDPlugin in the UI integration layer")
    public var hud:PTHudView?
    @MainActor public var hudConfig : PTHudConfig {
        let hudConfig = PTHudConfig.share
        hudConfig.hudColors = [.gray,.gray]
        hudConfig.lineWidth = 4
        return hudConfig
    }
    
    @available(*, deprecated, message: "Use PTNetworkHUDPlugin in the UI integration layer")
    public func hudShow()  {
        Task { @MainActor in
            let _ = Network.share.hudConfig
            if self.hud == nil {
                self.hud = PTHudView()
                self.hud?.hudShow()
            }
        }
    }
    
    @available(*, deprecated, message: "Use PTNetworkHUDPlugin in the UI integration layer")
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
                let url_debug:String = PTCoreUserDefaultsWrapper.shared.AppRequestUrl
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
                let url_debug:String = PTCoreUserDefaultsWrapper.shared.AppSocketUrl
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
    
    // English: Keep response normalization internal so legacy and typed fixtures can verify the same boundary.
    // Español: Mantiene la normalización de respuestas interna para que los fixtures heredados y tipados verifiquen el mismo límite.
    // 中文：将响应归一化保持为 internal，让旧版和类型化夹具验证同一个边界。
    /// 🌟 内部通用预处理：脱离外壳保护、Pretty 输出与截断盾
    internal static func validateAndPreprocessResponse<T>(_ snapshot: PTNetworkResponseSnapshot) throws -> (PTBaseStructModel<T>, String) {
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
        
        return (result, rawJsonString)
    }
    
    static func prepareRequestHeaders(header: HTTPHeaders?,
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
    
    static func createURLRequest(urlStr: URLConvertible, needGobal: Bool) async throws -> String {
        let original = try urlStr.asURL().absoluteString
        if original.hasPrefix("http") { return original }
        let globalURL = needGobal ? await Network.globalURL() : ""
        return globalURL + original
    }

    // MARK: - ================= 5. 底层核心执行引擎 =================

    /// 所有非上传请求共用的执行边界：插件、mock、取消、去重和错误日志
    /// 在这里完成，避免 URL 参数请求和 Body 请求各自维护一套生命周期。
    internal class func execute(url: String,
                                request: URLRequest,
                                uploadBody: Data? = nil) async throws -> PTNetworkResponseSnapshot {
        try await Network.share.executeRequest(url: url, request: request, uploadBody: uploadBody)
    }

    internal func executeRequest(url: String,
                                 request: URLRequest,
                                 uploadBody: Data? = nil) async throws -> PTNetworkResponseSnapshot {
        var request = request
        let pluginSnapshot = plugins
        let configurationSnapshot = config
        for plugin in pluginSnapshot {
            await plugin.willSend(&request)
        }

        if request.isCacheMiss {
            throw PTNetworkError.cache("cacheOnly 没有可用缓存 / cacheOnly has no usable entry / cacheOnly no tiene una entrada utilizable")
        }

        if request.isMock,
           let cached = await NetworkCache.shared.readEntry(request: request) {
            let snapshot = PTNetworkResponseSnapshot(url: url,
                                                     data: cached.data,
                                                     metadata: PTResponseMetadata(statusCode: cached.statusCode,
                                                                                  headers: cached.headers))
            Network.logResponseSnapshot(snapshot)
            return snapshot
        }

        let policy = request.dedupPolicy
        let finalRequest = request
        let transport: @Sendable () async throws -> PTNetworkResponseSnapshot = { [weak self] in
            guard let self else { throw PTNetworkError.cancelled }
            return try await self.performTransport(url: url,
                                                   request: finalRequest,
                                                   uploadBody: uploadBody,
                                                   plugins: pluginSnapshot,
                                                   configuration: configurationSnapshot)
        }
        let realRequest: @Sendable () async throws -> PTNetworkResponseSnapshot = { [weak self] in
            guard let self else { throw PTNetworkError.cancelled }
            let response = try await transport()
            guard !self.isAuthenticationFailure(response),
                  let provider = self.authRefreshProvider,
                  finalRequest.value(forHTTPHeaderField: "PT-Auth-Retry") != "1" else {
                return response
            }

            let token = try await self.authRefreshCoordinator.refresh(using: provider)
            self.updateUserToken(token)
            var replayRequest = finalRequest
            replayRequest.setValue("1", forHTTPHeaderField: "PT-Auth-Retry")
            if replayRequest.value(forHTTPHeaderField: "token") != nil {
                replayRequest.setValue(token, forHTTPHeaderField: "token")
            }
            if replayRequest.value(forHTTPHeaderField: "Authorization") != nil {
                replayRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            return try await self.performTransport(url: url,
                                                   request: replayRequest,
                                                   uploadBody: uploadBody,
                                                   plugins: pluginSnapshot,
                                                   configuration: configurationSnapshot)
        }
        return try await RequestDeduplicator.shared.executeRaw(
            request: finalRequest,
            policy: policy,
            task: realRequest)
    }

    private func performTransport(url: String,
                                  request: URLRequest,
                                  uploadBody: Data?,
                                  plugins: [NetworkPlugin],
                                  configuration: PTNetworkConfig) async throws -> PTNetworkResponseSnapshot {
        let session = self.session
        let dataTask = uploadBody.map {
            session.upload($0, with: request).serializingData()
        } ?? session.request(request).serializingData()
        let response = await withTaskCancellationHandler(operation: {
            await dataTask.response
        }, onCancel: {
            dataTask.cancel()
        })
        try Task.checkCancellation()

        for plugin in plugins {
            await plugin.didReceive(response.result, request: request, response: response.response)
        }
        await NetworkCache.shared.cleanIfNeeded(configuration: configuration)

        switch response.result {
        case .success(let data):
            if response.response?.statusCode == 304,
               let cached = await NetworkCache.shared.readEntry(request: request) {
                var headers = cached.headers
                response.response?.allHeaderFields.forEach { key, value in
                    headers[String(describing: key)] = String(describing: value)
                }
                let snapshot = PTNetworkResponseSnapshot(url: url,
                                                         data: cached.data,
                                                         metadata: PTResponseMetadata(statusCode: cached.statusCode ?? 200,
                                                                                      headers: headers))
                Network.logResponseSnapshot(snapshot)
                return snapshot
            }
            let snapshot = Network.responseSnapshot(url: url, response: response.response, data: data)
            Network.logResponseSnapshot(snapshot)
            return snapshot
        case .failure(let error):
            if request.cachePolicyType == .networkElseCache,
               let cached = await NetworkCache.shared.readEntry(request: request) {
                return PTNetworkResponseSnapshot(url: url,
                                                  data: cached.data,
                                                  metadata: PTResponseMetadata(statusCode: cached.statusCode,
                                                                               headers: cached.headers))
            }
            Network.logRequestFailure(url: url, error: error)
            throw error
        }
    }

    private func isAuthenticationFailure(_ snapshot: PTNetworkResponseSnapshot) -> Bool {
        if snapshot.metadata.statusCode == 401 { return true }
        guard let data = snapshot.data,
              let status = try? JSONDecoder().decode(PTNetworkStatusModel.self, from: data) else {
            return false
        }
        return status.code == 401
    }

    private func updateUserToken(_ token: String) {
        configLock.withLock { _config.userToken = token }
    }

    /// Compatibility executor for the old KakaJSON/Any APIs. It deliberately
    /// does not enter the Sendable deduplication pool; raw `Any` stays inside
    /// this legacy boundary and cannot leak into the modern executor.
    internal class func executeLegacy(url: String,
                                      request: URLRequest,
                                      uploadBody: Data? = nil) async throws -> PTNetworkResponseSnapshot {
        try await Network.share.executeLegacyRequest(url: url, request: request, uploadBody: uploadBody)
    }

    // English: Keep the legacy transport seam internal so iOS compatibility fixtures can verify the real URLSession path.
    // Español: Mantiene interna la costura de transporte heredada para que los fixtures iOS verifiquen la ruta real de URLSession.
    // 中文：保留旧传输边界为 internal，让 iOS 兼容夹具可以验证真实 URLSession 路径。
    internal func executeLegacyRequest(url: String,
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
            let snapshot = Network.responseSnapshot(url: url, response: nil, data: mockData)
            Network.logResponseSnapshot(snapshot)
            return snapshot
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
            let snapshot = Network.responseSnapshot(url: url, response: response.response, data: data)
            Network.logResponseSnapshot(snapshot)
            return snapshot
        case .failure(let error):
            Network.logRequestFailure(url: url, error: error)
            throw error
        }
    }

}
