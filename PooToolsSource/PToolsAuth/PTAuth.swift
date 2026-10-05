// English: Actor-based authentication service with single-flight token refresh.
// Español: Servicio de autenticación basado en actor con refresh de token single-flight.
// 中文：基于 actor 的认证服务，确保令牌刷新 single-flight。

import Foundation
import CryptoKit
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
#if SWIFT_PACKAGE
import PToolsAuthCore
import PToolsStorage
import PToolsStorageCore
#endif

public actor PTKeychainAuthCredentialStore: PTAuthCredentialStore {
    private let storage: PTKeychainStorage
    private let key: String

    public init(service: String = "PooTools.Auth", key: String = "token") {
        storage = PTKeychainStorage(service: service)
        self.key = key
    }

    public func loadToken() async throws -> PTAuthToken? {
        guard let data = try await storage.data(for: key) else { return nil }
        return try JSONDecoder().decode(PTAuthToken.self, from: data)
    }

    public func saveToken(_ token: PTAuthToken) async throws {
        try await storage.set(JSONEncoder().encode(token), for: key)
    }

    public func removeToken() async throws { try await storage.removeValue(for: key) }
}

public actor PTAuthRefreshCoordinator {
    private var inFlight: Task<PTAuthToken, Error>?

    public init() {}

    public func refresh(token: PTAuthToken, using provider: any PTAuthRemoteProvider) async throws -> PTAuthToken {
        if let inFlight { return try await inFlight.value }
        let task = Task { try await provider.refresh(token: token) }
        inFlight = task
        defer { inFlight = nil }
        return try await task.value
    }

    public func cancel() {
        inFlight?.cancel()
        inFlight = nil
    }
}

public actor PTAuthService {
    private let credentialStore: any PTAuthCredentialStore
    private let remoteProvider: (any PTAuthRemoteProvider)?
    private let refreshCoordinator = PTAuthRefreshCoordinator()
    private var session: PTAuthSession?
    private var currentState: PTAuthState = .unknown
    private var stateContinuations: [UUID: AsyncStream<PTAuthState>.Continuation] = [:]
    private var sessionGeneration = 0

    public init(credentialStore: any PTAuthCredentialStore = PTKeychainAuthCredentialStore(),
                remoteProvider: (any PTAuthRemoteProvider)? = nil) {
        self.credentialStore = credentialStore
        self.remoteProvider = remoteProvider
    }

    public func restore(userID: String) async throws -> PTAuthState {
        sessionGeneration &+= 1
        await refreshCoordinator.cancel()
        transition(.anonymous)
        guard let token = try await credentialStore.loadToken() else {
            session = nil
            transition(.signedOut)
            return .signedOut
        }
        let restored = PTAuthSession(userID: userID, token: token)
        session = restored
        let restoredState: PTAuthState = token.isExpired ? .expired(restored) : .authenticated(restored)
        transition(restoredState)
        return restoredState
    }

    public func signIn(_ session: PTAuthSession) async throws {
        sessionGeneration &+= 1
        await refreshCoordinator.cancel()
        transition(.authenticating)
        try await credentialStore.saveToken(session.token)
        self.session = session
        transition(.authenticated(session))
    }

    public func signOut() async throws {
        sessionGeneration &+= 1
        await refreshCoordinator.cancel()
        try await credentialStore.removeToken()
        session = nil
        transition(.signedOut)
    }

    public func state() -> PTAuthState { currentState }

    public func stateStream() -> AsyncStream<PTAuthState> {
        let id = UUID()
        return AsyncStream { continuation in
            stateContinuations[id] = continuation
            continuation.yield(currentState)
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { await self?.removeStateContinuation(id) }
            }
        }
    }

    public func authenticate(using provider: any PTAuthProvider,
                             request: PTAuthAuthorizationRequest) async throws -> PTAuthSession {
        transition(.authenticating)
        do {
            let authenticated = try await provider.authenticate(using: request)
            try await signIn(authenticated)
            return authenticated
        } catch is CancellationError {
            transition(.signedOut)
            throw PTAuthError.cancelled
        } catch {
            transition(.signedOut)
            throw error
        }
    }

    public func validToken() async throws -> PTAuthToken {
        guard let session else { throw PTAuthError.missingToken }
        guard session.token.isExpired else {
            if currentState != .authenticated(session) { transition(.authenticated(session)) }
            return session.token
        }
        let generation = sessionGeneration
        transition(.expired(session))
        guard let remoteProvider else { throw PTAuthError.refreshUnavailable }
        transition(.refreshing(session))
        do {
            let token = try await refreshCoordinator.refresh(token: session.token, using: remoteProvider)
            guard generation == sessionGeneration, self.session == session else {
                throw PTAuthError.sessionChanged
            }
            let updated = PTAuthSession(userID: session.userID, token: token)
            try await credentialStore.saveToken(token)
            self.session = updated
            transition(.authenticated(updated))
            return token
        } catch is CancellationError {
            if generation == sessionGeneration { transition(.expired(session)) }
            throw PTAuthError.cancelled
        } catch let error as PTAuthError {
            if generation == sessionGeneration, currentState != .expired(session) {
                transition(.expired(session))
            }
            throw error
        } catch {
            if generation == sessionGeneration {
                transition(.expired(session))
            }
            throw PTAuthError.refreshFailed(String(describing: error))
        }
    }

    private func transition(_ state: PTAuthState) {
        guard currentState != state else { return }
        currentState = state
        stateContinuations.values.forEach { $0.yield(state) }
    }

    private func removeStateContinuation(_ id: UUID) {
        stateContinuations[id] = nil
    }
}

extension PTAuthService: PTNetworkCredentialProvider {
    public func currentToken() async throws -> PTAuthToken? {
        session?.token
    }

    public func refreshToken() async throws -> PTAuthToken {
        try await validToken()
    }

    public func authorizationDidExpire() async {
        if let session {
            transition(.expired(session))
        } else {
            transition(.signedOut)
        }
    }
}

// English: URLSession adapter keeps authorization transport typed and independent from the network module.
// Español: El adaptador URLSession mantiene el transporte de autorización tipado e independiente del módulo de red.
// 中文：URLSession 适配器让认证传输保持类型化，并与 Network 模块解耦。
public struct PTURLSessionAuthNetworkAdapter: PTAuthNetworkAdapter {
    public let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(_ request: PTAuthNetworkRequest) async throws -> PTAuthNetworkResponse {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method
        urlRequest.httpBody = request.body
        request.headers.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
        let (data, response) = try await session.data(for: urlRequest)
        let http = response as? HTTPURLResponse
        return PTAuthNetworkResponse(statusCode: http?.statusCode ?? 0,
                                     headers: (http?.allHeaderFields ?? [:]).reduce(into: [String: String]()) { result, item in
                                         result[String(describing: item.key)] = String(describing: item.value)
                                     },
                                     body: data)
    }
}

// English: Single-flight 401 replay prevents a burst of requests from refreshing the same token repeatedly.
// Español: El replay single-flight de 401 evita refrescar el mismo token muchas veces en una ráfaga.
// 中文：401 single-flight 重放避免并发请求重复刷新同一个令牌。
public actor PTAuthUnauthorizedReplayCoordinator {
    private let policy: PTAuthRetryPolicy
    private var refreshTask: Task<PTAuthToken, Error>?

    public init(policy: PTAuthRetryPolicy = .init()) {
        self.policy = policy
    }

    public func send(_ request: PTAuthNetworkRequest,
                     token: PTAuthToken?,
                     adapter: any PTAuthNetworkAdapter,
                     refresh: @escaping @Sendable () async throws -> PTAuthToken) async throws -> PTAuthNetworkResponse {
        var response = try await adapter.send(Self.authorized(request, token: token))
        guard response.statusCode == 401,
              !request.isRefreshRequest,
              policy.maxUnauthorizedReplay > 0 else { return response }
        let refreshed: PTAuthToken
        if let refreshTask {
            refreshed = try await refreshTask.value
        } else {
            let task = Task { try await refresh() }
            refreshTask = task
            defer { refreshTask = nil }
            refreshed = try await task.value
        }
        response = try await adapter.send(Self.authorized(request, token: refreshed))
        return response
    }

    private static func authorized(_ request: PTAuthNetworkRequest,
                                   token: PTAuthToken?) -> PTAuthNetworkRequest {
        guard let token else { return request }
        var headers = request.headers
        headers["Authorization"] = "\(token.tokenType) \(token.accessToken)"
        return PTAuthNetworkRequest(url: request.url,
                                    method: request.method,
                                    headers: headers,
                                    body: request.body,
                                    isRefreshRequest: request.isRefreshRequest)
    }
}

// English: The authorization adapter is transport-neutral and replays one request at most once.
// Español: El adaptador de autorización es neutral al transporte y repite cada solicitud como máximo una vez.
// 中文：授权适配器与传输层解耦，并且每个请求最多只重放一次。
public actor PTNetworkAuthorizationAdapter {
    private let credentials: any PTNetworkCredentialProvider
    private let policy: PTAuthRetryPolicy
    private var refreshTask: Task<PTAuthToken, Error>?

    public init(credentials: any PTNetworkCredentialProvider,
                policy: PTAuthRetryPolicy = .init()) {
        self.credentials = credentials
        self.policy = policy
    }

    public func send(_ request: PTAuthNetworkRequest,
                     using transport: any PTAuthNetworkAdapter) async throws -> PTAuthNetworkResponse {
        try await sendWithDecision(request, using: transport).response
    }

    public func sendWithDecision(_ request: PTAuthNetworkRequest,
                                 using transport: any PTAuthNetworkAdapter) async throws -> (response: PTAuthNetworkResponse, decision: PTNetworkAuthorizationDecision) {
        let token = try await credentials.currentToken()
        let firstResponse = try await transport.send(Self.authorized(request, token: token))
        guard firstResponse.statusCode == 401,
              !request.isRefreshRequest,
              policy.maxUnauthorizedReplay > 0 else {
            return (firstResponse, .authorized)
        }

        let refreshed: PTAuthToken
        do {
            refreshed = try await refresh()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            await credentials.authorizationDidExpire()
            throw error
        }
        let replayedResponse = try await transport.send(Self.authorized(request, token: refreshed))
        guard replayedResponse.statusCode != 401 else {
            await credentials.authorizationDidExpire()
            return (replayedResponse, .expired)
        }
        return (replayedResponse, .replayed)
    }

    private func refresh() async throws -> PTAuthToken {
        if let refreshTask { return try await refreshTask.value }
        let task = Task { try await credentials.refreshToken() }
        refreshTask = task
        defer { refreshTask = nil }
        return try await task.value
    }

    private static func authorized(_ request: PTAuthNetworkRequest,
                                   token: PTAuthToken?) -> PTAuthNetworkRequest {
        guard let token else { return request }
        var headers = request.headers
        headers["Authorization"] = "\(token.tokenType) \(token.accessToken)"
        return PTAuthNetworkRequest(url: request.url,
                                    method: request.method,
                                    headers: headers,
                                    body: request.body,
                                    isRefreshRequest: request.isRefreshRequest)
    }
}

public enum PTOAuthPKCE {
    public static func makeChallenge(state: String = UUID().uuidString) -> PTAuthPKCEChallenge {
        var generator = SystemRandomNumberGenerator()
        let bytes = (0..<32).map { _ in UInt8.random(in: 0...255, using: &generator) }
        let verifier = Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let digest = SHA256.hash(data: Data(verifier.utf8))
        let challenge = Data(digest).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return PTAuthPKCEChallenge(verifier: verifier, challenge: challenge, state: state)
    }

    public static func validate(callbackURL: URL,
                                expectedState: String,
                                expectedNonce: String? = nil) throws -> PTAuthCallback {
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else { throw PTAuthError.invalidCallback }
        let values = Dictionary(uniqueKeysWithValues: queryItems.compactMap { item -> (String, String)? in
            guard let value = item.value else { return nil }
            return (item.name, value)
        })
        guard let code = values["code"], !code.isEmpty else { throw PTAuthError.invalidCallback }
        guard values["state"] == expectedState else { throw PTAuthError.stateMismatch }
        if let expectedNonce, values["nonce"] != expectedNonce { throw PTAuthError.nonceMismatch }
        return PTAuthCallback(code: code, state: expectedState, nonce: values["nonce"])
    }
}

// English: Generate, validate, and exchange PKCE values without retaining tokens in URLs.
// Español: Genera, valida e intercambia valores PKCE sin retener tokens en las URL.
// 中文：生成、校验并交换 PKCE 值，不把令牌长期放进 URL。
public enum PTOAuthPKCEGenerator {
    public static func makeChallenge(state: String = UUID().uuidString) -> PTAuthPKCEChallenge {
        PTOAuthPKCE.makeChallenge(state: state)
    }
}

public enum PTOAuthCallbackValidator {
    public static func validate(callbackURL: URL,
                                expectedState: String,
                                expectedNonce: String? = nil) throws -> PTAuthCallback {
        try PTOAuthPKCE.validate(callbackURL: callbackURL,
                                 expectedState: expectedState,
                                 expectedNonce: expectedNonce)
    }
}

public struct PTOAuthPKCEProvider: PTAuthProvider {
    public let kind: PTAuthProviderKind = .oauthPKCE
    private let configuration: PTAuthPKCEConfiguration
    private let authorize: @Sendable (URL) async throws -> URL
    private let exchange: @Sendable (PTOAuthPKCETokenExchangeRequest) async throws -> PTAuthSession

    public init(configuration: PTAuthPKCEConfiguration,
                authorize: @escaping @Sendable (URL) async throws -> URL,
                exchange: @escaping @Sendable (PTOAuthPKCETokenExchangeRequest) async throws -> PTAuthSession) {
        self.configuration = configuration
        self.authorize = authorize
        self.exchange = exchange
    }

    public func authenticate(using request: PTAuthAuthorizationRequest) async throws -> PTAuthSession {
        let challenge = PTOAuthPKCEGenerator.makeChallenge(state: request.state)
        let callbackURL = try await authorize(try authorizationURL(challenge: challenge))
        let callback = try PTOAuthCallbackValidator.validate(callbackURL: callbackURL,
                                                             expectedState: challenge.state,
                                                             expectedNonce: configuration.nonce ?? request.nonce)
        let exchangeRequest = PTOAuthPKCETokenExchangeRequest(callback: callback,
                                                              clientID: configuration.clientID,
                                                              redirectURL: configuration.redirectURL,
                                                              codeVerifier: challenge.verifier)
        return try await exchange(exchangeRequest)
    }

    public func authorizationURL(challenge: PTAuthPKCEChallenge) throws -> URL {
        guard var components = URLComponents(url: configuration.authorizationURL,
                                              resolvingAgainstBaseURL: false) else {
            throw PTAuthError.invalidCallback
        }
        var items = components.queryItems ?? []
        items.append(contentsOf: [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: configuration.clientID),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURL.absoluteString),
            URLQueryItem(name: "code_challenge", value: challenge.challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: challenge.state)
        ])
        if !configuration.scopes.isEmpty {
            items.append(URLQueryItem(name: "scope", value: configuration.scopes.joined(separator: " ")))
        }
        if let nonce = configuration.nonce {
            items.append(URLQueryItem(name: "nonce", value: nonce))
        }
        components.queryItems = items
        guard let url = components.url else { throw PTAuthError.invalidCallback }
        return url
    }
}

public protocol PTAppleAuthorizationAdapter: Sendable {
    func authorize(nonce: String) async throws -> PTAuthSession
}

public struct PTAppleAuthProvider: PTAuthProvider {
    public let kind: PTAuthProviderKind = .apple
    private let adapter: any PTAppleAuthorizationAdapter

    public init(adapter: any PTAppleAuthorizationAdapter) {
        self.adapter = adapter
    }

    public func authenticate(using request: PTAuthAuthorizationRequest) async throws -> PTAuthSession {
        guard request.provider == .apple else { throw PTAuthError.unsupportedProvider }
        return try await adapter.authorize(nonce: request.nonce ?? request.state)
    }
}

public protocol PTPasskeyAuthorizationAdapter: Sendable {
    func authorize(request: PTAuthAuthorizationRequest) async throws -> PTAuthSession
}

public struct PTPasskeyProvider: PTAuthProvider {
    public let kind: PTAuthProviderKind = .passkey
    private let adapter: any PTPasskeyAuthorizationAdapter

    public init(adapter: any PTPasskeyAuthorizationAdapter) {
        self.adapter = adapter
    }

    public func authenticate(using request: PTAuthAuthorizationRequest) async throws -> PTAuthSession {
        guard request.provider == .passkey else { throw PTAuthError.unsupportedProvider }
        return try await adapter.authorize(request: request)
    }
}

public struct PTAppleAuthCapability: Sendable {
    public init() {}
    public var isAvailable: Bool {
        #if canImport(AuthenticationServices)
        return true
        #else
        return false
        #endif
    }
}

public struct PTPasskeyCapability: Sendable {
    public init() {}
    public var isAvailable: Bool {
        #if canImport(AuthenticationServices)
        return true
        #else
        return false
        #endif
    }
}
