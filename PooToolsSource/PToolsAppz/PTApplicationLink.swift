// English: Native application-link contracts with deterministic URL construction and typed fallback behavior.
// Español: Contratos nativos de enlaces de aplicaciones con construcción determinista de URL y fallback tipado.
// 中文：提供原生应用链接契约、确定性的 URL 构建和类型化的降级行为。

import Foundation

/// A Foundation-only, immutable path used to build an external application URL.
/// Un camino inmutable basado solo en Foundation para construir una URL de aplicación externa.
/// 仅依赖 Foundation 的不可变路径，用于构建外部应用 URL。
public struct PTApplicationPath: Sendable, Equatable, Hashable {
    public var pathComponents: [String]
    public var queryParameters: [String: String]

    public init(pathComponents: [String] = [], queryParameters: [String: String] = [:]) {
        self.pathComponents = pathComponents
        self.queryParameters = queryParameters
    }

    public var queryItems: [URLQueryItem] {
        queryParameters.keys.sorted().map { key in
            URLQueryItem(name: key, value: queryParameters[key])
        }
    }

    /// Builds a URL without mutating the input URL or relying on dictionary order.
    /// Construye una URL sin mutar la URL de entrada ni depender del orden del diccionario.
    /// 构建 URL 时不修改输入 URL，也不依赖字典遍历顺序。
    public func appending(to baseURL: URL) -> URL? {
        guard baseURL.scheme != nil else { return nil }

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        var remainingComponents = pathComponents

        if components?.host == nil, let firstComponent = remainingComponents.first {
            components?.host = firstComponent
            remainingComponents.removeFirst()
        }

        if !remainingComponents.isEmpty {
            let appendedPath = remainingComponents
                .filter { !$0.isEmpty }
                .joined(separator: "/")
            let existingPath = components?.path ?? ""
            let prefix = existingPath.hasSuffix("/") || existingPath.isEmpty ? existingPath : existingPath + "/"
            components?.path = prefix + appendedPath
        }

        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        return components?.url
    }

    public func appending(to baseURLString: String) -> URL? {
        guard let baseURL = URL(string: baseURLString) else { return nil }
        return appending(to: baseURL)
    }

    // Compatibility spelling retained for the former Appz API.
    // Se conserva esta forma por compatibilidad con la API anterior de Appz.
    // 保留旧 Appz API 的方法命名，确保兼容已有调用方。
    public func appendToURL(_ baseURLString: String) -> URL? {
        appending(to: baseURLString)
    }
}

/// URL paths for the native application and the web fallback.
/// Rutas URL para la aplicación nativa y el fallback web.
/// 原生应用和网页降级入口使用的 URL 路径。
public struct PTApplicationActionPaths: Sendable, Equatable, Hashable {
    public var app: PTApplicationPath
    public var web: PTApplicationPath

    public init(app: PTApplicationPath = .init(), web: PTApplicationPath = .init()) {
        self.app = app
        self.web = web
    }
}

/// A typed application specification that can be supplied by a host app.
/// Una especificación tipada de aplicación que puede proporcionar la aplicación anfitriona.
/// 宿主应用可以提供的类型化应用规格。
public protocol PTExternalApplication {
    associatedtype ActionType: PTExternalApplicationAction

    var scheme: String { get }
    var fallbackURL: String { get }
    var appStoreId: String { get }
}

/// An action that describes both native and web paths.
/// Una acción que describe las rutas nativa y web.
/// 同时描述原生和网页路径的动作。
public protocol PTExternalApplicationAction {
    var paths: PTApplicationActionPaths { get }
}

/// Namespaced descriptors for the built-in application catalog.
/// Descriptores agrupados para el catálogo de aplicaciones integrado.
/// 内置应用目录的命名空间描述器。
public struct Applications {}

// Former Appz names remain source-compatible while the implementation is owned by PTools.
// Los nombres anteriores de Appz siguen siendo compatibles mientras PTools posee la implementación.
// 旧 Appz 类型名继续保持源码兼容，但实现归 PTools 所有。
public typealias Path = PTApplicationPath
public typealias ActionPaths = PTApplicationActionPaths
public typealias ExternalApplication = PTExternalApplication
public typealias ExternalApplicationAction = PTExternalApplicationAction

/// A host capable of checking and opening URLs.
/// Un host capaz de comprobar y abrir URLs.
/// 能够检查并打开 URL 的宿主。
@MainActor
public protocol PTApplicationCaller {
    func canOpenURL(_ url: URL) -> Bool

    @discardableResult
    func openURL(_ url: URL) -> Bool
}

// Compatibility protocol spelling retained for existing Appz consumers.
// Se conserva el nombre del protocolo por compatibilidad con consumidores de Appz.
// 保留旧协议名称，兼容现有 Appz 使用方。
public typealias ApplicationCaller = PTApplicationCaller

@MainActor
public extension PTApplicationCaller {
    func canOpen<Application: PTExternalApplication>(_ application: Application) -> Bool {
        guard let url = URL(string: application.scheme) else { return false }
        return canOpenURL(url)
    }

    @discardableResult
    func open<Application: PTExternalApplication>(
        _ application: Application,
        action: Application.ActionType,
        promptInstall: Bool = false
    ) -> Bool {
        let nativeURL = action.paths.app.appending(to: application.scheme)
        if let nativeURL, canOpenURL(nativeURL) {
            return openURL(nativeURL)
        }

        if promptInstall,
           !application.appStoreId.isEmpty,
           let appStoreURL = Applications.AppStore.Action.app(id: application.appStoreId).paths.app.appending(to: Applications.AppStore().scheme),
           canOpenURL(appStoreURL) {
            return openURL(appStoreURL)
        }

        guard let fallbackURL = action.paths.web.appending(to: application.fallbackURL) else {
            return false
        }
        return openURL(fallbackURL)
    }
}

/// A modern, descriptor-based application link request.
/// Una solicitud moderna de enlace basada en descriptores.
/// 基于描述器的现代应用链接请求。
public struct PTApplicationLinkRequest: Sendable, Equatable, Hashable {
    public let application: PTApplicationDescriptor
    public let nativePath: PTApplicationPath
    public let webPath: PTApplicationPath

    public init(
        application: PTApplicationDescriptor,
        nativePath: PTApplicationPath = .init(),
        webPath: PTApplicationPath = .init()
    ) {
        self.application = application
        self.nativePath = nativePath
        self.webPath = webPath
    }
}

/// A Sendable descriptor for custom application integrations.
/// Un descriptor Sendable para integraciones con aplicaciones personalizadas.
/// 面向自定义应用集成的 Sendable 描述器。
public struct PTApplicationDescriptor: Sendable, Equatable, Hashable {
    public let identifier: String
    public let scheme: String
    public let fallbackURL: String
    public let appStoreID: String?

    public init(
        identifier: String,
        scheme: String,
        fallbackURL: String,
        appStoreID: String? = nil
    ) {
        self.identifier = identifier
        self.scheme = scheme
        self.fallbackURL = fallbackURL
        self.appStoreID = appStoreID
    }
}

/// A scene-independent link router. The caller remains injected and owned by the host.
/// Un router independiente de Scene; el host inyecta y posee el caller.
/// 与 Scene 无关的链接路由器，由宿主注入并持有 caller。
@MainActor
public final class PTApplicationLinkRouter {
    public let caller: any PTApplicationCaller

    public init(caller: any PTApplicationCaller) {
        self.caller = caller
    }

    @discardableResult
    public func open(_ request: PTApplicationLinkRequest, promptInstall: Bool = false) -> Bool {
        if let nativeURL = request.nativePath.appending(to: request.application.scheme), caller.canOpenURL(nativeURL) {
            return caller.openURL(nativeURL)
        }

        if promptInstall,
           let appStoreID = request.application.appStoreID,
           !appStoreID.isEmpty,
           let appStoreURL = PTApplicationPath(
               pathComponents: ["itunes.apple.com", "app", "id\(appStoreID)"]
           ).appending(to: "itms-apps:") {
            return caller.openURL(appStoreURL)
        }

        guard let fallbackURL = request.webPath.appending(to: request.application.fallbackURL) else {
            return false
        }
        return caller.openURL(fallbackURL)
    }
}
