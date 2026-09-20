// English: Keep the Network architecture contracts separate from the legacy request facade.
// Español: Mantiene los contratos de arquitectura de Network separados de la fachada de solicitudes heredada.
// 中文：将 Network 架构契约与旧版请求门面分离。

import Foundation

// English: Session values are captured once; changing Network.config does not rebuild an existing session.
// Español: Los valores de sesión se capturan una vez; cambiar Network.config no reconstruye una sesión existente.
// 中文：Session 配置只在初始化时捕获一次，修改 Network.config 不会重建已有 Session。
public struct PTNetworkSessionConfiguration: Equatable, Sendable {
    public let requestTimeout: TimeInterval
    public let downloadRequestTimeout: TimeInterval
    public let resourceTimeout: TimeInterval
    public let waitsForConnectivity: Bool
    public let memoryCapacity: Int
    public let diskCapacity: Int
    public let retryTimes: Int
    public let retryDelay: TimeInterval
    public let retryAPIStatusCode: Int

    public init(requestTimeout: TimeInterval = 20,
                downloadRequestTimeout: TimeInterval = 5,
                resourceTimeout: TimeInterval = 3600,
                waitsForConnectivity: Bool = true,
                memoryCapacity: Int = 20 * 1024 * 1024,
                diskCapacity: Int = 100 * 1024 * 1024,
                retryTimes: Int = 3,
                retryDelay: TimeInterval = 1.5,
                retryAPIStatusCode: Int = 502) {
        self.requestTimeout = max(0, requestTimeout)
        self.downloadRequestTimeout = max(0, downloadRequestTimeout)
        self.resourceTimeout = max(0, resourceTimeout)
        self.waitsForConnectivity = waitsForConnectivity
        self.memoryCapacity = max(0, memoryCapacity)
        self.diskCapacity = max(0, diskCapacity)
        self.retryTimes = max(0, retryTimes)
        self.retryDelay = max(0, retryDelay)
        self.retryAPIStatusCode = retryAPIStatusCode
    }

    public init(configuration: PTNetworkConfig) {
        self.init(requestTimeout: configuration.requestTimeout,
                  downloadRequestTimeout: configuration.downloadRequestTimeout,
                  resourceTimeout: configuration.resourceTimeout,
                  waitsForConnectivity: configuration.waitsForConnectivity,
                  retryTimes: configuration.retryTimes,
                  retryDelay: configuration.retryDelay,
                  retryAPIStatusCode: configuration.retryAPIStatusCode)
    }
}

// English: Providers supply dynamic request values without mutating session construction state.
// Español: Los proveedores suministran valores dinámicos sin mutar el estado de construcción de la sesión.
// 中文：Provider 提供动态请求值，但不修改 Session 的构造状态。
public protocol PTCredentialProvider: Sendable {
    func credential() async -> String?
}

public protocol PTRequestHeaderProvider: Sendable {
    func headers() async -> [String: String]
}

public protocol PTEndpointResolver: Sendable {
    func resolve(endpoint: String, environment: PTNetworkRequestEnvironment) async throws -> URL
}

// English: HUD presentation belongs to an outer UI adapter instead of the transport layer.
// Español: La presentación del HUD pertenece a un adaptador UI externo y no a la capa de transporte.
// 中文：HUD 展示由外层 UI 适配器负责，不属于传输层。
@MainActor
public protocol PTNetworkHUDPlugin: AnyObject, Sendable {
    func show()
    func hide()
}

// English: The registry exposes an immutable plugin snapshot for a Network instance.
// Español: El registro expone una instantánea inmutable de plugins para una instancia de Network.
// 中文：插件注册表为每个 Network 实例提供不可变插件快照。
public struct PTNetworkPluginRegistry: Sendable {
    private let values: [NetworkPlugin]

    public init(plugins: [NetworkPlugin] = []) {
        self.values = plugins
    }

    public func snapshot() -> [NetworkPlugin] {
        values
    }
}

// English: PTNetworkRequest is the transport-neutral request contract for new integrations.
// Español: PTNetworkRequest es el contrato de solicitud neutral al transporte para nuevas integraciones.
// 中文：PTNetworkRequest 是面向新集成的传输无关请求契约。
public struct PTNetworkRequest: Sendable, Hashable {
    public let url: URL
    public let method: String
    public let headers: [String: String]
    public let body: Data?
    public let cachePolicy: PTNetworkCachePolicy
    public let cacheExpiration: TimeInterval
    public let deduplication: PTNetworkDedupPolicy

    public init(url: URL,
                method: String = "GET",
                headers: [String: String] = [:],
                body: Data? = nil,
                cachePolicy: PTNetworkCachePolicy = .cacheElseNetwork,
                cacheExpiration: TimeInterval = 300,
                deduplication: PTNetworkDedupPolicy = .identical) {
        self.url = url
        self.method = method.uppercased()
        self.headers = headers
        self.body = body
        self.cachePolicy = cachePolicy
        self.cacheExpiration = max(0, cacheExpiration)
        self.deduplication = deduplication
    }
}

// English: PTNetworkResponse contains only immutable values returned by the canonical executor.
// Español: PTNetworkResponse solo contiene valores inmutables devueltos por el ejecutor canónico.
// 中文：PTNetworkResponse 只包含统一执行器返回的不可变值。
public struct PTNetworkResponse: Sendable {
    public let request: PTNetworkRequest
    public let statusCode: Int?
    public let headers: [String: String]
    public let data: Data?

    public init(request: PTNetworkRequest,
                statusCode: Int?,
                headers: [String: String],
                data: Data?) {
        self.request = request
        self.statusCode = statusCode
        self.headers = headers
        self.data = data
    }
}

// English: A refresh provider is the only authentication capability the transport layer needs to know.
// Español: El proveedor de renovación es la única capacidad de autenticación que necesita conocer el transporte.
// 中文：刷新 Provider 是传输层唯一需要了解的认证能力。
public protocol PTNetworkAuthRefreshProvider: Sendable {
    func refreshToken() async throws -> String
}

// English: One in-flight refresh is shared by all requests that receive an authentication failure.
// Español: Una sola renovación en vuelo es compartida por todas las solicitudes con fallo de autenticación.
// 中文：所有遇到认证失败的请求共享同一个进行中的刷新任务。
public actor PTNetworkAuthRefreshCoordinator {
    private var refreshTask: Task<String, Error>?

    public init() {}

    public func refresh(using provider: any PTNetworkAuthRefreshProvider) async throws -> String {
        if let refreshTask { return try await refreshTask.value }
        let task = Task { try await provider.refreshToken() }
        refreshTask = task
        defer { refreshTask = nil }
        return try await task.value
    }
}

// English: The executor is the typed facade over the existing Network transport pipeline.
// Español: El ejecutor es la fachada tipada sobre el pipeline de transporte Network existente.
// 中文：执行器是现有 Network 传输管线之上的类型化门面。
public actor PTNetworkExecutor {
    public static let shared = PTNetworkExecutor(network: .share)
    private let network: Network

    public init(network: Network = .share) {
        self.network = network
    }

    public func execute(_ request: PTNetworkRequest) async throws -> PTNetworkResponse {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method
        request.headers.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
        urlRequest.cachePolicyType = request.cachePolicy
        urlRequest.cacheExpire = request.cacheExpiration
        urlRequest.dedupPolicy = request.deduplication
        urlRequest.httpBody = request.body

        do {
            let snapshot = try await network.executeRequest(url: request.url.absoluteString,
                                                             request: urlRequest,
                                                             uploadBody: nil)
            if let statusCode = snapshot.metadata.statusCode,
               !(200..<300).contains(statusCode),
               statusCode != 304 {
                throw PTNetworkError.httpStatus(code: statusCode, body: snapshot.data)
            }
            return PTNetworkResponse(request: request,
                                     statusCode: snapshot.metadata.statusCode,
                                     headers: snapshot.metadata.headers,
                                     data: snapshot.data)
        } catch let error as PTNetworkError {
            throw error
        } catch {
            throw PTNetworkError.typed(from: error)
        }
    }
}
