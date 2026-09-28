// English: Scene-bound host coordinator for URLs, activities and notification routes.
// Español: Coordinador ligado a la escena para URLs, actividades y rutas de notificaciones.
// 中文：面向多 Scene 的 URL、Activity 与通知路由宿主协调器。

import UIKit
#if SWIFT_PACKAGE
import PToolsDeepLink
import PToolsRouteCore
#endif

@MainActor
public final class PTRouteHostCoordinator {
    public static let shared = PTRouteHostCoordinator()

    public let router: PooToolsRouter
    public var deepLinkConfiguration: PTDeepLinkConfiguration

    private var pendingRequests: [ObjectIdentifier: [PTRouteRequest]] = [:]

    public init(router: PooToolsRouter = .shared,
                deepLinkConfiguration: PTDeepLinkConfiguration = .init()) {
        self.router = router
        self.deepLinkConfiguration = deepLinkConfiguration
    }

    @discardableResult
    public func handle(url: URL, in scene: UIWindowScene) async throws -> PTRouteResult? {
        let request = try PTDeepLinkParser.request(from: url, configuration: deepLinkConfiguration)
        return try await handle(request: request, in: scene)
    }

    @discardableResult
    public func handle(userActivity: NSUserActivity, in scene: UIWindowScene) async throws -> PTRouteResult? {
        let request = try PTDeepLinkParser.request(from: userActivity,
                                                   configuration: deepLinkConfiguration)
        return try await handle(request: request, in: scene)
    }

    // English: Spotlight keeps its source marker while sharing the same Scene-bound route pipeline.
    // Español: Spotlight conserva su marcador de origen y comparte el mismo pipeline ligado a la escena.
    // 中文：Spotlight 保留来源标记，同时复用同一套 Scene 路由流水线。
    @discardableResult
    public func handle(spotlightActivity: NSUserActivity,
                       in scene: UIWindowScene) async throws -> PTRouteResult? {
        let request = try PTDeepLinkParser.request(fromSpotlight: spotlightActivity,
                                                   configuration: deepLinkConfiguration)
        return try await handle(request: request, in: scene)
    }

    // English: Push and notification adapters pass typed routes here instead of a global key window.
    // Español: Los adaptadores de push y notificaciones pasan rutas tipadas aquí sin usar una key window global.
    // 中文：推送和通知适配器在这里传入类型化路由，不访问全局 key window。
    @discardableResult
    public func handle(notificationRoute: PTRouteRequest,
                       in scene: UIWindowScene) async throws -> PTRouteResult? {
        try await handle(request: notificationRoute.with(source: .notification), in: scene)
    }

    @discardableResult
    public func handle(request: PTRouteRequest, in scene: UIWindowScene) async throws -> PTRouteResult? {
        guard let context = presentationContext(for: scene), isReady(scene) else {
            enqueue(request, for: scene)
            return nil
        }
        return try await router.open(request, context: context)
    }

    public func resume(scene: UIWindowScene) async {
        guard isReady(scene), presentationContext(for: scene) != nil else { return }
        guard let requests = pendingRequests.removeValue(forKey: ObjectIdentifier(scene)),
              let context = presentationContext(for: scene) else { return }
        for request in requests {
            _ = try? await router.open(request, context: context)
        }
    }

    public func context(for scene: UIWindowScene) -> PTRoutePresentationContext {
        presentationContext(for: scene) ?? PTRoutePresentationContext(windowScene: scene)
    }

    public func clearPendingRequests(for scene: UIWindowScene) {
        pendingRequests[ObjectIdentifier(scene)] = nil
    }

    private func enqueue(_ request: PTRouteRequest, for scene: UIWindowScene) {
        pendingRequests[ObjectIdentifier(scene), default: []].append(request)
    }

    private func isReady(_ scene: UIWindowScene) -> Bool {
        scene.activationState == .foregroundActive || scene.activationState == .foregroundInactive
    }

    private func presentationContext(for scene: UIWindowScene) -> PTRoutePresentationContext? {
        guard let window = scene.windows.first(where: \.isKeyWindow) ??
                scene.windows.first(where: { !$0.isHidden && $0.alpha > 0 && $0.rootViewController != nil }) else {
            return nil
        }
        let navigationController = (window.rootViewController as? UINavigationController) ??
            window.rootViewController?.navigationController
        return PTRoutePresentationContext(windowScene: scene,
                                          window: window,
                                          navigationController: navigationController)
    }
}
