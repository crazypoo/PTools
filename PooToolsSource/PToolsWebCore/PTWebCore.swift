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
    public let maxPayloadBytes: Int
    public let allowedNavigationSchemes: Set<String>
    public let legacyPromptEnabled: Bool
    public init(allowedMethods: Set<String> = [],
                allowedOrigins: Set<String> = [],
                mainFrameOnly: Bool = true,
                timeout: Duration = .seconds(15),
                maxPayloadBytes: Int = 1_048_576,
                allowedNavigationSchemes: Set<String> = ["https", "http"],
                legacyPromptEnabled: Bool = false) {
        self.allowedMethods = allowedMethods
        self.allowedOrigins = allowedOrigins
        self.mainFrameOnly = mainFrameOnly
        self.timeout = timeout
        self.maxPayloadBytes = max(1, maxPayloadBytes)
        self.allowedNavigationSchemes = allowedNavigationSchemes
        self.legacyPromptEnabled = legacyPromptEnabled
    }
}

public enum PTWebBridgeError: Error, Sendable, Equatable {
    case methodNotAllowed
    case originNotAllowed
    case invalidPayload
    case timedOut
    case unavailable
    case payloadTooLarge
    case navigationNotAllowed
    case legacyPromptDisabled
}

public typealias PTWebHandler = @MainActor @Sendable (PTWebRequest) async throws -> PTWebResponse

// English: Bootstrap exposes one Promise-based App namespace and never trusts page input by default.
// Español: El bootstrap expone un namespace App basado en Promise y no confía en la entrada de la página por defecto.
// 中文：Bootstrap 提供基于 Promise 的 App 命名空间，默认不信任页面输入。
public struct PTWebScriptBootstrap: Sendable, Equatable {
    public let methods: Set<String>
    public init(methods: Set<String> = []) { self.methods = methods }

    public func source() -> String {
        let bridgeNames = methods.sorted().map { name in
            let literal = Self.literal(name)
            return "\(literal): (encodedPayload) => window.webkit.messageHandlers.PToolsBridge.postMessage({method: \(literal), payload: encodedPayload})"
        }.joined(separator: ",")
        let appNames = methods.sorted().map { name in
            let literal = Self.literal(name)
            return "\(literal): (payload) => window.PToolsBridge[\(literal)](encode(payload)).then((response) => response && response.payload !== undefined ? decode(response.payload) : response)"
        }.joined(separator: ",")
        // English: Keep a raw bridge for native calls and a JSON Promise facade for page code.
        // Español: Mantén un puente crudo para llamadas nativas y una fachada Promise JSON para la página.
        // 中文：同时保留原生调用使用的底层桥接，以及页面代码使用的 JSON Promise 门面。
        return """
        (() => {
          const encode = (value) => {
            const bytes = new TextEncoder().encode(JSON.stringify(value ?? null));
            let binary = '';
            bytes.forEach((byte) => { binary += String.fromCharCode(byte); });
            return btoa(binary);
          };
          const decode = (value) => {
            const binary = atob(value);
            const bytes = Uint8Array.from(binary, (character) => character.charCodeAt(0));
            return JSON.parse(new TextDecoder().decode(bytes));
          };
          window.PToolsBridge = Object.assign(window.PToolsBridge || {}, {\(bridgeNames)});
          window.App = Object.assign(window.App || {}, {\(appNames)});
        })();
        """
    }

    private static func literal(_ value: String) -> String {
        let encoded = (try? JSONEncoder().encode(value)) ?? Data("\"\"".utf8)
        return String(data: encoded, encoding: .utf8) ?? "\"\""
    }
}
