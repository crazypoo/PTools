// English: Main-actor route execution for UIKit without a global key-window lookup.
// Español: Ejecución de rutas en MainActor para UIKit sin buscar una key window global.
// 中文：面向 UIKit 的 MainActor 路由执行，不依赖全局 key window 查找。

import UIKit
#if SWIFT_PACKAGE
import PToolsDeepLink
import PToolsRouteCore
#endif

@MainActor
public final class PTRoutePresentationContext {
    public weak var windowScene: UIWindowScene?
    public weak var window: UIWindow?
    public weak var navigationController: UINavigationController?

    public init(windowScene: UIWindowScene? = nil,
                window: UIWindow? = nil,
                navigationController: UINavigationController? = nil) {
        self.windowScene = windowScene
        self.window = window
        self.navigationController = navigationController
    }
}

@MainActor
public final class PooToolsRouter {
    public static let shared = PooToolsRouter()

    public typealias Handler = @MainActor @Sendable (PTRouteRequest,
                                                     PTRoutePresentationContext?) async throws -> PTRouteResult

    private var handlers: [PTRouteID: Handler] = [:]
    private var middlewares: [any PTRouteMiddleware] = []
    private let maximumRedirects = 8

    public init() {}

    public func register(_ route: PTRouteID, handler: @escaping Handler) {
        handlers[route] = handler
    }

    public func unregister(_ route: PTRouteID) {
        handlers[route] = nil
    }

    public func addMiddleware(_ middleware: any PTRouteMiddleware) {
        middlewares.append(middleware)
    }

    public func open(_ request: PTRouteRequest,
                     context: PTRoutePresentationContext? = nil) async throws -> PTRouteResult {
        var current = request
        var visited = Set<PTRouteRequest>()
        for _ in 0...maximumRedirects {
            guard visited.insert(current).inserted else { throw PTRouteError.redirectLoop }
            let result = try await execute(current, index: 0, context: context)
            guard case .redirected(let next) = result else { return result }
            current = next
        }
        throw PTRouteError.redirectLoop
    }

    public func open(_ url: URL,
                     configuration: PTDeepLinkConfiguration = .init(),
                     context: PTRoutePresentationContext? = nil) async throws -> PTRouteResult {
        try await open(PTDeepLinkParser.request(from: url, configuration: configuration), context: context)
    }

    public func open(_ userActivity: NSUserActivity,
                     configuration: PTDeepLinkConfiguration = .init(),
                     context: PTRoutePresentationContext? = nil) async throws -> PTRouteResult {
        try await open(PTDeepLinkParser.request(from: userActivity, configuration: configuration), context: context)
    }

    private func execute(_ request: PTRouteRequest,
                         index: Int,
                         context: PTRoutePresentationContext?) async throws -> PTRouteResult {
        if index < middlewares.count {
            let middleware = middlewares[index]
            return try await middleware.handle(request: request) { [weak self] next in
                guard let self else { throw PTRouteError.invalidRequest }
                return try await self.execute(next, index: index + 1, context: context)
            }
        }

        guard let handler = handlers[request.route.id] else {
            throw PTRouteError.noHandler(request.route.id)
        }
        return try await handler(request, context)
    }
}

public typealias PTRouter2 = PooToolsRouter
