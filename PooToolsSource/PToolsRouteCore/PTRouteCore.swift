// English: UIKit-free route values shared by deep links, notifications and routers.
// Español: Valores de rutas sin UIKit compartidos por deep links, notificaciones y routers.
// 中文：供深链、通知和路由器共享的不依赖 UIKit 的路由值类型。

import Foundation

public struct PTRouteID: RawRepresentable, Codable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

public enum PTRouteSource: String, Codable, Sendable, Hashable {
    case internalCall
    case urlScheme
    case universalLink
    case userActivity
    case spotlight
    case notification
    case appIntent
    case unknown
}

public enum PTRouteParameter: Codable, Hashable, Sendable {
    case string(String)
    case integer(Int64)
    case double(Double)
    case boolean(Bool)
    case url(URL)
    case json(Data)

    private enum CodingKeys: String, CodingKey { case kind, string, integer, double, boolean, url, json }
    private enum Kind: String, Codable { case string, integer, double, boolean, url, json }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .string(let value):
            try container.encode(Kind.string, forKey: .kind)
            try container.encode(value, forKey: .string)
        case .integer(let value):
            try container.encode(Kind.integer, forKey: .kind)
            try container.encode(value, forKey: .integer)
        case .double(let value):
            try container.encode(Kind.double, forKey: .kind)
            try container.encode(value, forKey: .double)
        case .boolean(let value):
            try container.encode(Kind.boolean, forKey: .kind)
            try container.encode(value, forKey: .boolean)
        case .url(let value):
            try container.encode(Kind.url, forKey: .kind)
            try container.encode(value, forKey: .url)
        case .json(let value):
            try container.encode(Kind.json, forKey: .kind)
            try container.encode(value, forKey: .json)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .string: self = .string(try container.decode(String.self, forKey: .string))
        case .integer: self = .integer(try container.decode(Int64.self, forKey: .integer))
        case .double: self = .double(try container.decode(Double.self, forKey: .double))
        case .boolean: self = .boolean(try container.decode(Bool.self, forKey: .boolean))
        case .url: self = .url(try container.decode(URL.self, forKey: .url))
        case .json: self = .json(try container.decode(Data.self, forKey: .json))
        }
    }
}

public struct PTRoute: Codable, Hashable, Sendable {
    public let id: PTRouteID
    public let pathComponents: [String]

    public init(id: PTRouteID, pathComponents: [String] = []) {
        self.id = id
        self.pathComponents = pathComponents
    }
}

public struct PTRouteRequest: Codable, Hashable, Sendable {
    public let route: PTRoute
    public let parameters: [String: PTRouteParameter]
    public let source: PTRouteSource

    public init(route: PTRoute,
                parameters: [String: PTRouteParameter] = [:],
                source: PTRouteSource = .internalCall) {
        self.route = route
        self.parameters = parameters
        self.source = source
    }

    // English: Re-tag a normalized request when it crosses a system entry point.
    // Español: Vuelve a etiquetar una solicitud normalizada al cruzar un punto de entrada del sistema.
    // 中文：标准化请求进入系统入口时重新标记其来源。
    public func with(source: PTRouteSource) -> PTRouteRequest {
        PTRouteRequest(route: route, parameters: parameters, source: source)
    }
}

public enum PTRouteResult: Sendable, Equatable {
    case completed
    case handled(Data?)
    case redirected(PTRouteRequest)
}

public enum PTRouteError: Error, Sendable, Equatable {
    case invalidRequest
    case noHandler(PTRouteID)
    case redirectLoop
    case unauthorized
    case failed(String)
}

public protocol PTRouteMiddleware: Sendable {
    func handle(request: PTRouteRequest,
                next: @escaping @Sendable (PTRouteRequest) async throws -> PTRouteResult) async throws -> PTRouteResult
}
