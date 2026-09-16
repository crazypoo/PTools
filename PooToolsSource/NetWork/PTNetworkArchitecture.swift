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
