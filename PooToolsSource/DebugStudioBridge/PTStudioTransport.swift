// Explicit HTTPS-only paired push transport. No proxy interception or URLProtocol hooks.
import Foundation
import CryptoKit
import Security

public protocol PTStudioTransport: Sendable {
    func send(_ events: [PTStudioEnvelope]) async throws -> PTStudioAcknowledgement
    func close() async
}

public struct PTStudioPairingCredentials: Codable, Sendable, Equatable {
    public let bearerToken: String
    public let leafCertificateSHA256: Data

    /// Convenience for pasting the Mac UI's 64-character leaf SHA-256 fingerprint.
    /// This does not waive system TLS trust: the developer must trust the Mac CA first.
    public init(bearerToken: String, leafCertificateSHA256Hex: String) throws {
        let hex = leafCertificateSHA256Hex.trimmingCharacters(in: .whitespacesAndNewlines)
        guard hex.utf8.count == 64 else { throw PTStudioBridgeError.invalidCredentials }
        let characters = Array(hex)
        var digest = Data()
        for offset in stride(from: 0, to: 64, by: 2) {
            guard let byte = UInt8(String(characters[offset...offset + 1]), radix: 16) else {
                throw PTStudioBridgeError.invalidCredentials
            }
            digest.append(byte)
        }
        try self.init(bearerToken: bearerToken, leafCertificateSHA256: digest)
    }

    public init(bearerToken: String, leafCertificateSHA256: Data) throws {
        guard bearerToken.utf8.count >= 24, leafCertificateSHA256.count == 32 else {
            throw PTStudioBridgeError.invalidCredentials
        }
        self.bearerToken = bearerToken
        self.leafCertificateSHA256 = leafCertificateSHA256
    }
}

public enum PTStudioPairingKeychain {
    // Called only after a user has explicitly approved pairing on both devices.
    // Never write tokens to UserDefaults, diagnostics, or source-controlled files.
    public static func save(_ credentials: PTStudioPairingCredentials, account: String) throws {
        let data = try JSONEncoder().encode(credentials)
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: "com.ptools.debug.studio",
                                    kSecAttrAccount as String: account]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        guard SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess else {
            throw PTStudioBridgeError.invalidCredentials
        }
    }

    public static func load(account: String) -> PTStudioPairingCredentials? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: "com.ptools.debug.studio",
                                    kSecAttrAccount as String: account,
                                    kSecReturnData as String: true,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return try? JSONDecoder().decode(PTStudioPairingCredentials.self, from: data)
    }

    public static func revoke(account: String) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: "com.ptools.debug.studio",
                                    kSecAttrAccount as String: account]
        SecItemDelete(query as CFDictionary)
    }
}

private final class PTStudioCertificatePinDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    private let expectedSHA256: Data

    init(expectedSHA256: Data) { self.expectedSHA256 = expectedSHA256 }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust,
              SecTrustEvaluateWithError(trust, nil),
              let leaf = SecTrustGetCertificateAtIndex(trust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        let digest = Data(SHA256.hash(data: SecCertificateCopyData(leaf) as Data))
        guard digest == expectedSHA256 else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}

public struct PTStudioBatch: Codable, Sendable {
    public let schemaVersion: Int
    public let events: [PTStudioEnvelope]
    public init(events: [PTStudioEnvelope]) {
        self.schemaVersion = PTStudioEnvelope.currentSchemaVersion
        self.events = events
    }
}

public actor PTStudioHTTPSPushTransport: PTStudioTransport {
    private let endpoint: URL
    private let bearerToken: String
    private let session: URLSession
    private var closed = false

    /// The collector must provide a real trusted TLS certificate; leaf pinning adds a second check.
    /// The server must verify bearer authorization, short-lived nonce and timestamp, and dedupe eventIDs.
    public init(endpoint: URL, credentials: PTStudioPairingCredentials) throws {
        guard endpoint.scheme?.lowercased() == "https", endpoint.host != nil,
              endpoint.user == nil, endpoint.password == nil,
              endpoint.fragment == nil else { throw PTStudioBridgeError.unsupportedScheme }
        self.endpoint = endpoint
        self.bearerToken = credentials.bearerToken
        let config = URLSessionConfiguration.ephemeral
        config.httpShouldSetCookies = false
        config.httpCookieAcceptPolicy = .never
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        // Do not register the application's custom URLProtocol classes on this session.
        config.protocolClasses = []
        self.session = URLSession(configuration: config,
                                  delegate: PTStudioCertificatePinDelegate(expectedSHA256: credentials.leafCertificateSHA256),
                                  delegateQueue: nil)
    }

    public func send(_ events: [PTStudioEnvelope]) async throws -> PTStudioAcknowledgement {
        guard !closed, !events.isEmpty else { throw PTStudioBridgeError.transportRejected }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(PTStudioBatch(events: events))
        // Bounded at 2 MiB so 24 events with both 16 KiB previews cannot deadlock retry.
        guard data.count <= 2 * 1024 * 1024 else { throw PTStudioBridgeError.transportRejected }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("1", forHTTPHeaderField: "X-PTStudio-Internal")
        request.setValue("Bearer " + bearerToken, forHTTPHeaderField: "Authorization")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-PTStudio-Nonce")
        request.setValue(String(Int(Date().timeIntervalSince1970)), forHTTPHeaderField: "X-PTStudio-Sent-At")
        let (responseData, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw PTStudioBridgeError.transportRejected
        }
        guard (200..<300).contains(http.statusCode) else {
            throw PTStudioBridgeError.serverStatus(http.statusCode)
        }
        guard responseData.count <= 16 * 1024 else {
            throw PTStudioBridgeError.transportRejected
        }
        return try JSONDecoder().decode(PTStudioAcknowledgement.self, from: responseData)
    }

    public func close() {
        guard !closed else { return }
        closed = true
        session.invalidateAndCancel()
    }
}
