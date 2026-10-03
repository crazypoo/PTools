//
//  PTRouterResolver.swift
//  PooTools
//
//  English: Resolve route metadata into a validated view controller before navigation.
//  Español: Resuelve los metadatos de ruta en un controlador validado antes de navegar.
//  中文：在执行跳转前，将路由元数据解析为经过校验的控制器。
//

import UIKit

@MainActor
enum PTRouterResolver {
    static func makeViewController(_ viewControllerType: UIViewController.Type,
                                   queries: [String: Sendable]) throws -> UIViewController {
        if let routableType = viewControllerType as? PTRoutableController.Type {
            guard let viewController = routableType.init(routerParams: queries) as? UIViewController else {
                throw PTRouterError.initializationFailed
            }
            return viewController
        }

        let viewController = viewControllerType.init()
        _ = viewController.setPropertyParameter(queries)
        return viewController
    }

    static func resolve(urlString: String,
                        response: PTRouter.RouteResponse) throws -> (UIViewController, PTJumpType, [String: Sendable]) {
        guard let pattern = response.pattern else {
            throw PTRouterError.notFound(url: urlString)
        }
        guard let viewControllerType = NSClassFromString(pattern.classString) as? UIViewController.Type else {
            PTRouter.shareInstance.logcat?(urlString, .logError, "解析类名失败: \(pattern.classString)")
            throw PTRouterError.invalidClass(className: pattern.classString)
        }

        let viewController = try makeViewController(viewControllerType, queries: response.queries)
        let jumpType = PTRouter.routeJumpType(from: response.queries)
        return (viewController, jumpType, response.queries)
    }
}
