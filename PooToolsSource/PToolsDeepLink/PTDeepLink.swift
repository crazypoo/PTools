// English: Normalize URL schemes and universal links into Foundation route requests.
// Español: Normaliza esquemas URL y universal links en solicitudes de rutas de Foundation.
// 中文：将 URL Scheme 和 Universal Link 归一化为 Foundation 路由请求。

import Foundation
#if SWIFT_PACKAGE
import PToolsRouteCore
#endif

public struct PTDeepLinkConfiguration: Sendable, Equatable {
    public let schemes: Set<String>
    public let universalLinkHosts: Set<String>

    public init(schemes: Set<String> = [], universalLinkHosts: Set<String> = []) {
        self.schemes = Set(schemes.map { $0.lowercased() })
        self.universalLinkHosts = Set(universalLinkHosts.map { $0.lowercased() })
    }
}

public enum PTDeepLinkError: Error, Sendable, Equatable {
    case invalidURL
    case unsupportedScheme
    case unsupportedHost
    case missingRoute
}

public enum PTDeepLinkParser {
    public static func request(from url: URL,
                               configuration: PTDeepLinkConfiguration = .init()) throws -> PTRouteRequest {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let scheme = components.scheme?.lowercased() else {
            throw PTDeepLinkError.invalidURL
        }

        let isUniversalLink = scheme == "http" || scheme == "https"
        if isUniversalLink {
            if !configuration.universalLinkHosts.isEmpty,
               !configuration.universalLinkHosts.contains(components.host?.lowercased() ?? "") {
                throw PTDeepLinkError.unsupportedHost
            }
        } else if !configuration.schemes.isEmpty && !configuration.schemes.contains(scheme) {
            throw PTDeepLinkError.unsupportedScheme
        }

        var segments: [String] = []
        if !isUniversalLink, let host = components.host, !host.isEmpty {
            segments.append(host)
        }
        segments.append(contentsOf: components.path.split(separator: "/").map(String.init))
        guard let routeName = segments.first, !routeName.isEmpty else {
            throw PTDeepLinkError.missingRoute
        }

        var parameters: [String: PTRouteParameter] = [:]
        for (index, value) in segments.dropFirst().enumerated() {
            parameters["path\(index)"] = parameter(for: value)
        }
        for item in components.queryItems ?? [] {
            guard !item.name.isEmpty, let value = item.value else { continue }
            parameters[item.name] = parameter(for: value)
        }

        let source: PTRouteSource = isUniversalLink ? .universalLink : .urlScheme
        return PTRouteRequest(route: PTRoute(id: PTRouteID(rawValue: routeName),
                                             pathComponents: segments),
                              parameters: parameters,
                              source: source)
    }

    public static func request(from userActivity: NSUserActivity,
                               configuration: PTDeepLinkConfiguration = .init()) throws -> PTRouteRequest {
        if let webpageURL = userActivity.webpageURL {
            return try request(from: webpageURL, configuration: configuration).with(source: .userActivity)
        }
        guard !userActivity.activityType.isEmpty else { throw PTDeepLinkError.missingRoute }
        return PTRouteRequest(route: PTRoute(id: PTRouteID(rawValue: userActivity.activityType)),
                              source: .userActivity)
    }

    public static func request(fromSpotlight spotlightActivity: NSUserActivity,
                               configuration: PTDeepLinkConfiguration = .init()) throws -> PTRouteRequest {
        try request(from: spotlightActivity, configuration: configuration).with(source: .spotlight)
    }

    private static func parameter(for value: String) -> PTRouteParameter {
        if let bool = Bool(value.lowercased()) { return .boolean(bool) }
        if let integer = Int64(value) { return .integer(integer) }
        if let double = Double(value) { return .double(double) }
        if let url = URL(string: value), url.scheme != nil { return .url(url) }
        return .string(value)
    }
}

public struct PTDeepLinkContract: Sendable, Equatable {
    public let configuration: PTDeepLinkConfiguration

    public init(configuration: PTDeepLinkConfiguration) {
        self.configuration = configuration
    }

    public func request(from url: URL) throws -> PTRouteRequest {
        try PTDeepLinkParser.request(from: url, configuration: configuration)
    }

    public func request(from userActivity: NSUserActivity) throws -> PTRouteRequest {
        try PTDeepLinkParser.request(from: userActivity, configuration: configuration)
    }
}
