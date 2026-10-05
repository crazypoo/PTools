// English: Foundation-only Web bridge contracts with explicit security policy values.
// Español: Contratos solo de Foundation para Web Bridge con políticas de seguridad explícitas.
// 中文：带明确安全策略值类型的 Web Bridge Foundation-only 契约。

import Foundation

public struct PTWebMethod: Hashable, Sendable, Codable {
    public let name: String
    public init(_ name: String) { self.name = name }
}

public struct PTWebRequest: Sendable, Codable {
    public let method: PTWebMethod
    public let payload: Data
    public let requestID: UUID
    public init(method: PTWebMethod, payload: Data = Data(), requestID: UUID = UUID()) {
        self.method = method; self.payload = payload; self.requestID = requestID
    }
}

public struct PTWebResponse: Sendable, Codable {
    public let requestID: UUID
    public let payload: Data
    public init(requestID: UUID, payload: Data = Data()) { self.requestID = requestID; self.payload = payload }
}

public struct PTWebSecurityPolicy: Sendable, Equatable {
    public let allowedMethods: Set<String>
    public let allowedOrigins: Set<String>
    public let mainFrameOnly: Bool
    public let timeout: Duration
    public init(allowedMethods: Set<String> = [],
                allowedOrigins: Set<String> = [],
                mainFrameOnly: Bool = true,
                timeout: Duration = .seconds(15)) {
        self.allowedMethods = allowedMethods
        self.allowedOrigins = allowedOrigins
        self.mainFrameOnly = mainFrameOnly
        self.timeout = timeout
    }
}

public enum PTWebBridgeError: Error, Sendable, Equatable {
    case methodNotAllowed
    case originNotAllowed
    case invalidPayload
    case timedOut
    case unavailable
}

public typealias PTWebHandler = @MainActor @Sendable (PTWebRequest) async throws -> PTWebResponse
