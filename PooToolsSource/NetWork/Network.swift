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

    // English: Freeze transport construction values while keeping request environment values dynamic.
    // Español: Congela los valores de construcción del transporte y mantiene dinámico el entorno de solicitudes.
    // 中文：冻结传输层构造参数，同时保留请求环境参数的动态性。
    private let sessionConfiguration: PTNetworkSessionConfiguration
    private let protocolClasses: [AnyClass]
    // English: Providers supply per-request values while the session configuration remains immutable.
    // Español: Los proveedores suministran valores por solicitud mientras la configuración de sesión permanece inmutable.
    // 中文：Provider 提供每次请求的动态值，同时保持 Session 配置不可变。
    private let credentialProvider: (any PTCredentialProvider)?
    private let headerProvider: (any PTRequestHeaderProvider)?
    private let endpointResolver: (any PTEndpointResolver)?

    // English: New instances snapshot their configuration and plugins; the legacy singleton remains available.
    // Español: Las nuevas instancias capturan su configuración y plugins; el singleton heredado sigue disponible.
    // 中文：新实例会固定初始配置和插件；旧单例入口继续可用。
    public init(configuration: PTNetworkConfig = PTNetworkConfig(),
                plugins: [NetworkPlugin] = [PTNetworkCachePlugin()],
                protocolClasses: [AnyClass] = [],
                credentialProvider: (any PTCredentialProvider)? = nil,
                headerProvider: (any PTRequestHeaderProvider)? = nil,
                endpointResolver: (any PTEndpointResolver)? = nil) {
        _config = configuration
        _plugins = plugins
        sessionConfiguration = PTNetworkSessionConfiguration(configuration: configuration)
        self.protocolClasses = protocolClasses
        self.credentialProvider = credentialProvider
        self.headerProvider = headerProvider
        self.endpointResolver = endpointResolver
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
    
    static func logRequestFailure(url: String, error: AFError) {
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

    static func responseSnapshot(url: String,
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
                                             cachePolicy: PTNetworkCachePolicy?) async throws -> PTNetworkRequestContext {
        let originalURL = try urlStr.asURL().absoluteString
        let configuration = config
        let environment = PTNetworkRequestEnvironment(configuration: configuration)
        let url: String
        if let endpointResolver {
            url = try await endpointResolver.resolve(endpoint: originalURL, environment: environment).absoluteString
        } else if originalURL.hasPrefix("http") || !needGobal {
            url = originalURL
        } else {
            url = environment.serverAddress + originalURL
        }
        var headers = Self.prepareRequestHeaders(header: header,
                                                  jsonRequest: jsonRequest,
                                                  cachePolicy: cachePolicy,
                                                  configuration: configuration)
        if let headerProvider {
            let dynamicHeaders = await headerProvider.headers()
            for (key, value) in dynamicHeaders where headers[key] == nil {
                headers[key] = value
            }
        }
        if let credentialProvider,
           headers["token"] == nil,
           let credential = await credentialProvider.credential(),
           !credential.isEmpty {
            headers["token"] = credential
            headers["device"] = "iOS"
        }
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
        let context = try await makeInstanceRequestContext(urlStr: urlStr,
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
    private static func makeDownloadSession(configuration configurationSnapshot: PTNetworkSessionConfiguration,
                                            protocolClasses: [AnyClass]) -> Session {
        let urlConfiguration = URLSessionConfiguration.default
        urlConfiguration.timeoutIntervalForRequest = configurationSnapshot.downloadRequestTimeout
        urlConfiguration.timeoutIntervalForResource = configurationSnapshot.resourceTimeout
        urlConfiguration.httpMaximumConnectionsPerHost = 6
        if !protocolClasses.isEmpty {
            var protocols = urlConfiguration.protocolClasses ?? []
            protocols.insert(contentsOf: protocolClasses, at: 0)
            urlConfiguration.protocolClasses = protocols
        }
        return Session(configuration: urlConfiguration)
    }

    private var downloadSession: Session {
        downloadSessionLock.lock()
        defer { downloadSessionLock.unlock() }
        if let storedDownloadSession { return storedDownloadSession }
        let newSession = Self.makeDownloadSession(configuration: sessionConfiguration,
                                                  protocolClasses: protocolClasses)
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
        let store: DownloadStore
        var request: DownloadRequest?
        var resumeData: Data?
        
        private var progressHandlers: [FileDownloadProgress] = []
        private var successHandlers: [FileDownloadSuccess] = []
        private var failHandlers: [FileDownloadFail] = []
        private var lastProgressTime: CFTimeInterval = 0
        private(set) var isDownloading: Bool = false
        
        init(url: String,
             destination: @escaping @Sendable (URL, HTTPURLResponse) -> (URL, DownloadRequest.Options),
             store: DownloadStore) {
            self.url = url
            self.destination = destination
            self.store = store
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
                    await store.remove(self.url)
                }
                for cb in currentFails { Task { @MainActor in cb(error) } }
            } else {
                await store.remove(self.url)
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
                task = DownloadTask(url: fileUrl, destination: dest, store: store)
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
