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
    case unknown
    case anonymous
    case authenticating
    case authenticated(PTAuthSession)
    case refreshing(PTAuthSession)
    case expired(PTAuthSession)
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
    case invalidCallback
    case stateMismatch
    case nonceMismatch
    case unsupportedProvider
    case unauthorized
    case sessionChanged
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
    public let nonce: String?

    public init(clientID: String,
                authorizationURL: URL,
                redirectURL: URL,
                scopes: [String] = [],
                nonce: String? = nil) {
        self.clientID = clientID
        self.authorizationURL = authorizationURL
        self.redirectURL = redirectURL
        self.scopes = scopes
        self.nonce = nonce
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

public struct PTAuthCallback: Sendable, Equatable {
    public let code: String
    public let state: String
    public let nonce: String?

    public init(code: String, state: String, nonce: String? = nil) {
        self.code = code
        self.state = state
        self.nonce = nonce
    }
}

public struct PTAuthNetworkRequest: Sendable, Equatable {
    public let url: URL
    public let method: String
    public let headers: [String: String]
    public let body: Data?
    public let isRefreshRequest: Bool

    public init(url: URL,
                method: String = "GET",
                headers: [String: String] = [:],
                body: Data? = nil,
                isRefreshRequest: Bool = false) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.isRefreshRequest = isRefreshRequest
    }
}

public struct PTAuthNetworkResponse: Sendable, Equatable {
    public let statusCode: Int
    public let headers: [String: String]
    public let body: Data

    public init(statusCode: Int, headers: [String: String] = [:], body: Data = Data()) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }
}

public protocol PTAuthNetworkAdapter: Sendable {
    func send(_ request: PTAuthNetworkRequest) async throws -> PTAuthNetworkResponse
}

// English: Network owns transport; this credential contract owns only token lookup and refresh.
// Español: Network posee el transporte; este contrato de credenciales solo posee la lectura y renovación del token.
// 中文：Network 只负责传输；这个凭据契约只负责读取和刷新令牌。
public protocol PTNetworkCredentialProvider: Sendable {
    func currentToken() async throws -> PTAuthToken?
    func refreshToken() async throws -> PTAuthToken
    func authorizationDidExpire() async
}

public enum PTNetworkAuthorizationDecision: Sendable, Equatable {
    case authorized
    case replayed
    case expired
}

public struct PTOAuthPKCETokenExchangeRequest: Sendable, Equatable {
    public let callback: PTAuthCallback
    public let clientID: String
    public let redirectURL: URL
    public let codeVerifier: String

    public init(callback: PTAuthCallback,
                clientID: String,
                redirectURL: URL,
                codeVerifier: String) {
        self.callback = callback
        self.clientID = clientID
        self.redirectURL = redirectURL
        self.codeVerifier = codeVerifier
    }
}

public struct PTAuthRetryPolicy: Sendable, Equatable {
    public let maxUnauthorizedReplay: Int
    public init(maxUnauthorizedReplay: Int = 1) {
        self.maxUnauthorizedReplay = max(0, maxUnauthorizedReplay)
    }
}

public struct PTAuthPKCEChallenge: Sendable, Equatable {
    public let verifier: String
    public let challenge: String
    public let state: String

    public init(verifier: String, challenge: String, state: String) {
        self.verifier = verifier
        self.challenge = challenge
        self.state = state
    }
}

public enum PTAuthCapability: String, Sendable, Equatable {
    case apple
    case passkey
}

public protocol PTAuthProvider: Sendable {
    var kind: PTAuthProviderKind { get }
    func authenticate(using request: PTAuthAuthorizationRequest) async throws -> PTAuthSession
}
