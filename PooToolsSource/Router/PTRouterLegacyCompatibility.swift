// English: Keeps the 5.x service-registration and redirect APIs source-compatible while the route core stays focused.
// Español: Mantiene compatibles las APIs 5.x de servicios y redirecciones mientras el núcleo de rutas permanece enfocado.
// 中文：保留 5.x 服务注册和重定向 API 的源码兼容性，同时让路由核心保持单一职责。

import Foundation

public extension PTRouter {
    // English: Register a Sendable service creator through the compatibility facade.
    // Español: Registra un creador de servicio Sendable mediante la fachada de compatibilidad.
    // 中文：通过兼容外观注册 Sendable 服务创建器。
    class func registerService(named: String, creator: @escaping @Sendable () -> (Any & Sendable)) {
        Task {
            await PTRouterServiceManager.shared.registerService(named: named, creator: creator)
        }
    }

    class func registerService(named: String, instance: Any & Sendable) {
        Task {
            await PTRouterServiceManager.shared.registerService(named: named, instance: instance)
        }
    }

    class func registerService(named: String, lazyCreator: @escaping @autoclosure @Sendable () -> (Any & Sendable)) {
        let safeCreator: @Sendable () -> (Any & Sendable) = lazyCreator
        Task {
            await PTRouterServiceManager.shared.registerService(named: named, creator: safeCreator)
        }
    }

    class func registerService<Service: Sendable>(_ service: Service.Type,
                                                   creator: @escaping @Sendable () -> Service) {
        Task {
            await PTRouterServiceManager.shared.registerService(service, creator: creator)
        }
    }

    class func registerService<Service: Sendable>(_ service: Service.Type,
                                                   lazyCreator: @escaping @autoclosure @Sendable () -> Service) {
        let safeCreator: @Sendable () -> Service = lazyCreator
        Task {
            await PTRouterServiceManager.shared.registerService(service, creator: safeCreator)
        }
    }

    class func registerService<Service: Sendable>(_ service: Service.Type, instance: Service) {
        Task {
            await PTRouterServiceManager.shared.registerService(service, instance: instance)
        }
    }

    @MainActor
    @discardableResult
    class func createService(named: String, shouldCache: Bool = true) async -> (Any & Sendable)? {
        await PTRouterServiceManager.shared.createService(named: named)
    }

    @discardableResult
    class func createService<Service: Sendable>(_ service: Service.Type) async -> Service? {
        await PTRouterServiceManager.shared.getService(service)
    }

    @MainActor
    @discardableResult
    class func getService(named: String) async -> (Any & Sendable)? {
        await PTRouterServiceManager.shared.getService(named: named)
    }

    @discardableResult
    class func getService<Service: Sendable>(_ service: Service.Type) async -> Service? {
        await PTRouterServiceManager.shared.getService(service)
    }

    class func routeJump(vcName: String, scheme: String) async {
        let relocationMap: NSDictionary = ["routerType": 2, "className": vcName, "path": scheme]
        do {
            let data = try JSONSerialization.data(withJSONObject: relocationMap, options: [])
            let routeReMapInfo = try JSONDecoder().decode(PTRouterInfo.self, from: data)
            PTRouterManager.addRelocationHandle(routerMapList: [routeReMapInfo])
        } catch {
            PTNSLogConsole("路由重定向配置失败: \(error)", levelType: .error, loggerType: .router)
            return
        }

        Task {
            do {
                _ = try await PTRouter.openURL(scheme)
            } catch {
                PTNSLogConsole("\(error)")
            }
        }
    }
}
