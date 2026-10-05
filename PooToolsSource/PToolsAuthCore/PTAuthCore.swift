// English: Foundation-only authentication contracts with explicit Sendable values.
// Español: Contratos de autenticación solo de Foundation con valores Sendable explícitos.
// 中文：仅依赖 Foundation 的认证契约，使用明确的 Sendable 值类型。

import Foundation

public struct PTAuthToken: Codable, Hashable, Sendable {
    public let accessToken: String
    public let refreshToken: String?
    public let tokenType: String
    public let expiresAt: Date?

    public init(accessToken: String,
                refreshToken: String? = nil,
                tokenType: String = "Bearer",
                expiresAt: Date? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
        self.expiresAt = expiresAt
    }

    public var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt <= .now
    }
}

public struct PTAuthSession: Codable, Hashable, Sendable {
    public let userID: String
    public let token: PTAuthToken

    public init(userID: String, token: PTAuthToken) {
        self.userID = userID
        self.token = token
    }
}

public enum PTAuthState: Sendable, Equatable {
    case signedOut
    case signedIn(PTAuthSession)
}

public enum PTAuthError: Error, Sendable, Equatable {
    case missingToken
    case refreshUnavailable
    case refreshFailed(String)
    case credentialStoreFailed
    case invalidResponse
    case cancelled
}

public protocol PTAuthCredentialStore: Sendable {
    func loadToken() async throws -> PTAuthToken?
    func saveToken(_ token: PTAuthToken) async throws
    func removeToken() async throws
}

public protocol PTAuthRemoteProvider: Sendable {
    func refresh(token: PTAuthToken) async throws -> PTAuthToken
}

public struct PTAuthRefreshRequest: Sendable, Equatable {
    public let token: PTAuthToken
    public init(token: PTAuthToken) { self.token = token }
}

public struct PTAuthPKCEConfiguration: Sendable, Equatable {
    public let clientID: String
    public let authorizationURL: URL
    public let redirectURL: URL
    public let scopes: [String]
    public init(clientID: String, authorizationURL: URL, redirectURL: URL, scopes: [String] = []) {
        self.clientID = clientID
        self.authorizationURL = authorizationURL
        self.redirectURL = redirectURL
        self.scopes = scopes
    }
}

public enum PTAuthProviderKind: String, Sendable, Codable {
    case oauthPKCE
    case apple
    case passkey
}

// English: Providers expose authentication capabilities without coupling the session actor to UIKit or AuthenticationServices.
// Español: Los proveedores exponen capacidades de autenticación sin acoplar el actor de sesión a UIKit ni AuthenticationServices.
// 中文：Provider 暴露认证能力，但不让会话 actor 耦合 UIKit 或 AuthenticationServices。
public struct PTAuthAuthorizationRequest: Sendable, Equatable {
    public let provider: PTAuthProviderKind
    public let state: String
    public let nonce: String?
    public let codeVerifier: String?

    public init(provider: PTAuthProviderKind,
                state: String,
                nonce: String? = nil,
                codeVerifier: String? = nil) {
        self.provider = provider
        self.state = state
        self.nonce = nonce
        self.codeVerifier = codeVerifier
    }
}

public protocol PTAuthProvider: Sendable {
    var kind: PTAuthProviderKind { get }
    func authenticate(using request: PTAuthAuthorizationRequest) async throws -> PTAuthSession
}
