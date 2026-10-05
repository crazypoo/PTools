// English: Actor-based authentication service with single-flight token refresh.
// Español: Servicio de autenticación basado en actor con refresh de token single-flight.
// 中文：基于 actor 的认证服务，确保令牌刷新 single-flight。

import Foundation
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
}

public actor PTAuthService {
    private let credentialStore: any PTAuthCredentialStore
    private let remoteProvider: (any PTAuthRemoteProvider)?
    private let refreshCoordinator = PTAuthRefreshCoordinator()
    private var session: PTAuthSession?

    public init(credentialStore: any PTAuthCredentialStore = PTKeychainAuthCredentialStore(),
                remoteProvider: (any PTAuthRemoteProvider)? = nil) {
        self.credentialStore = credentialStore
        self.remoteProvider = remoteProvider
    }

    public func restore(userID: String) async throws -> PTAuthState {
        guard let token = try await credentialStore.loadToken() else {
            session = nil
            return .signedOut
        }
        let restored = PTAuthSession(userID: userID, token: token)
        session = restored
        return .signedIn(restored)
    }

    public func signIn(_ session: PTAuthSession) async throws {
        try await credentialStore.saveToken(session.token)
        self.session = session
    }

    public func signOut() async throws {
        try await credentialStore.removeToken()
        session = nil
    }

    public func state() -> PTAuthState { session.map(PTAuthState.signedIn) ?? .signedOut }

    public func validToken() async throws -> PTAuthToken {
        guard let session else { throw PTAuthError.missingToken }
        guard session.token.isExpired else { return session.token }
        guard let remoteProvider else { throw PTAuthError.refreshUnavailable }
        do {
            let token = try await refreshCoordinator.refresh(token: session.token, using: remoteProvider)
            let updated = PTAuthSession(userID: session.userID, token: token)
            try await credentialStore.saveToken(token)
            self.session = updated
            return token
        } catch let error as PTAuthError {
            throw error
        } catch {
            throw PTAuthError.refreshFailed(String(describing: error))
        }
    }
}
