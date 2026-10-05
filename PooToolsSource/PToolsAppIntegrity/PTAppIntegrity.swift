// English: Real App Attest and DeviceCheck capability adapter; no fake success is returned.
// Español: Adaptador real de App Attest y DeviceCheck; nunca devuelve un éxito falso.
// 中文：真实的 App Attest 与 DeviceCheck 能力适配器，不伪造成功结果。

import Foundation
#if canImport(DeviceCheck)
import DeviceCheck
#endif

public enum PTAppIntegrityCapability: Sendable, Equatable {
    case unsupported
    case appAttest
    case deviceCheck
}

public enum PTAppIntegrityError: Error, Sendable, Equatable {
    case unsupported
    case unavailable
    case failed(String)
    case invalidChallenge
    case challengeReplayed
    case keyUnavailable
}

public struct PTAppAttestKey: Sendable, Equatable, Codable {
    public let keyID: String
    public let createdAt: Date
    public let environment: String

    public init(keyID: String, createdAt: Date = .now, environment: String = "production") {
        self.keyID = keyID
        self.createdAt = createdAt
        self.environment = environment
    }
}

public struct PTAttestationRequest: Sendable, Equatable, Codable {
    public let keyID: String
    public let clientDataHash: Data

    public init(keyID: String, clientDataHash: Data) {
        self.keyID = keyID
        self.clientDataHash = clientDataHash
    }
}

public struct PTAttestationResult: Sendable, Equatable, Codable {
    public let key: PTAppAttestKey
    public let attestation: Data

    public init(key: PTAppAttestKey, attestation: Data) {
        self.key = key
        self.attestation = attestation
    }
}

public struct PTAssertionRequest: Sendable, Equatable, Codable {
    public let keyID: String
    public let clientDataHash: Data
    public let challenge: PTAppIntegrityChallenge

    public init(keyID: String,
                clientDataHash: Data,
                challenge: PTAppIntegrityChallenge) {
        self.keyID = keyID
        self.clientDataHash = clientDataHash
        self.challenge = challenge
    }
}

public struct PTAssertionResult: Sendable, Equatable, Codable {
    public let keyID: String
    public let challenge: PTAppIntegrityChallenge
    public let assertion: Data

    public init(keyID: String,
                challenge: PTAppIntegrityChallenge,
                assertion: Data) {
        self.keyID = keyID
        self.challenge = challenge
        self.assertion = assertion
    }
}

public struct PTDeviceCheckToken: Sendable, Equatable, Codable {
    public let token: Data
    public let createdAt: Date

    public init(token: Data, createdAt: Date = .now) {
        self.token = token
        self.createdAt = createdAt
    }
}

public struct PTIntegrityErrorContext: Sendable, Equatable, Codable {
    public let operation: String
    public let keyID: String?
    public let challengeID: String?
    public let message: String

    public init(operation: String,
                keyID: String? = nil,
                challengeID: String? = nil,
                message: String) {
        self.operation = operation
        self.keyID = keyID
        self.challengeID = challengeID
        self.message = message
    }
}

public struct PTAppIntegrityChallenge: Codable, Sendable, Equatable {
    public let identifier: String
    public let nonce: Data
    public let expiresAt: Date

    public init(identifier: String = UUID().uuidString,
                nonce: Data,
                expiresAt: Date) {
        self.identifier = identifier
        self.nonce = nonce
        self.expiresAt = expiresAt
    }

    public func isValid(at date: Date = .now) -> Bool { date < expiresAt && !nonce.isEmpty }
}

public struct PTAppIntegrityPayload: Codable, Sendable, Equatable {
    public let keyID: String
    public let challenge: PTAppIntegrityChallenge
    public let artifact: Data

    public init(keyID: String, challenge: PTAppIntegrityChallenge, artifact: Data) {
        self.keyID = keyID
        self.challenge = challenge
        self.artifact = artifact
    }
}

public protocol PTAppIntegrityKeyStore: Sendable {
    func keyID() async throws -> String?
    func save(keyID: String) async throws
    func removeKey() async throws
}

// English: Store only the non-secret App Attest key identifier in UserDefaults; the key stays in the system service.
// Español: Guarda solo el identificador no secreto de App Attest en UserDefaults; la clave permanece en el servicio del sistema.
// 中文：只把非敏感的 App Attest key ID 存入 UserDefaults，真正的密钥仍由系统服务保管。
public actor PTUserDefaultsAppIntegrityKeyStore: PTAppIntegrityKeyStore {
    private let storageKey: String

    public init(storageKey: String = "PTools.AppIntegrity.keyID") {
        self.storageKey = storageKey
    }

    public func keyID() async throws -> String? {
        UserDefaults.standard.string(forKey: storageKey)
    }

    public func save(keyID: String) async throws {
        UserDefaults.standard.set(keyID, forKey: storageKey)
    }

    public func removeKey() async throws {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}

public actor PTAppIntegrityChallengeLedger {
    private var consumedIdentifiers: Set<String> = []

    public init() {}

    public func consume(_ challenge: PTAppIntegrityChallenge,
                        now: Date = .now) throws {
        guard challenge.isValid(at: now) else { throw PTAppIntegrityError.invalidChallenge }
        guard consumedIdentifiers.insert(challenge.identifier).inserted else {
            throw PTAppIntegrityError.challengeReplayed
        }
    }
}

public protocol PTAppIntegrityChallengeProvider: Sendable {
    func challenge() async throws -> PTAppIntegrityChallenge
}

public protocol PTAppIntegrityUploader: Sendable {
    func upload(_ payload: PTAppIntegrityPayload) async throws
}

public struct PTNetworkIntegrityAdapter: PTAppIntegrityUploader {
    public let endpoint: URL
    public let session: URLSession

    public init(endpoint: URL, session: URLSession = .shared) {
        self.endpoint = endpoint
        self.session = session
    }

    public func upload(_ payload: PTAppIntegrityPayload) async throws {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(payload)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw PTAppIntegrityError.failed("Integrity upload failed")
        }
    }
}

public actor PTAppIntegrityService {
    private let keyStore: any PTAppIntegrityKeyStore
    private let challengeLedger: PTAppIntegrityChallengeLedger
    #if canImport(DeviceCheck)
    private let appAttest = DCAppAttestService.shared
    private let deviceCheck = DCDevice.current
    #endif

    public init(keyStore: any PTAppIntegrityKeyStore = PTUserDefaultsAppIntegrityKeyStore(),
                challengeLedger: PTAppIntegrityChallengeLedger = .init()) {
        self.keyStore = keyStore
        self.challengeLedger = challengeLedger
    }

    public nonisolated var capability: PTAppIntegrityCapability {
        #if canImport(DeviceCheck)
        if DCAppAttestService.shared.isSupported { return .appAttest }
        if DCDevice.current.isSupported { return .deviceCheck }
        #endif
        return .unsupported
    }

    public func currentKey() async throws -> PTAppAttestKey? {
        guard let keyID = try await keyStore.keyID() else { return nil }
        return PTAppAttestKey(keyID: keyID)
    }

    public func resetKey() async throws {
        try await keyStore.removeKey()
    }

    #if canImport(DeviceCheck)
    public func generateKey() async throws -> String {
        guard appAttest.isSupported else { throw PTAppIntegrityError.unsupported }
        let keyID: String = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            appAttest.generateKey { keyID, error in
                if let error { continuation.resume(throwing: PTAppIntegrityError.failed(error.localizedDescription)) }
                else if let keyID { continuation.resume(returning: keyID) }
                else { continuation.resume(throwing: PTAppIntegrityError.unavailable) }
            }
        }
        try? await keyStore.save(keyID: keyID)
        return keyID
    }

    #endif

    public func storedKeyID() async throws -> String? {
        try await keyStore.keyID()
    }

    #if canImport(DeviceCheck)

    public func rotateKey() async throws -> String {
        try? await keyStore.removeKey()
        return try await generateKey()
    }

    public func attest(keyID: String, clientDataHash: Data) async throws -> Data {
        guard appAttest.isSupported else { throw PTAppIntegrityError.unsupported }
        return try await withCheckedThrowingContinuation { continuation in
            appAttest.attestKey(keyID, clientDataHash: clientDataHash) { attestation, error in
                if let error { continuation.resume(throwing: PTAppIntegrityError.failed(error.localizedDescription)) }
                else if let attestation { continuation.resume(returning: attestation) }
                else { continuation.resume(throwing: PTAppIntegrityError.unavailable) }
            }
        }
    }

    public func assertion(keyID: String, clientDataHash: Data) async throws -> Data {
        guard appAttest.isSupported else { throw PTAppIntegrityError.unsupported }
        return try await withCheckedThrowingContinuation { continuation in
            appAttest.generateAssertion(keyID, clientDataHash: clientDataHash) { assertion, error in
                if let error { continuation.resume(throwing: PTAppIntegrityError.failed(error.localizedDescription)) }
                else if let assertion { continuation.resume(returning: assertion) }
                else { continuation.resume(throwing: PTAppIntegrityError.unavailable) }
            }
        }
    }

    public func deviceCheckToken() async throws -> Data {
        guard deviceCheck.isSupported else { throw PTAppIntegrityError.unsupported }
        return try await withCheckedThrowingContinuation { continuation in
            deviceCheck.generateToken { token, error in
                if let error { continuation.resume(throwing: PTAppIntegrityError.failed(error.localizedDescription)) }
                else if let token { continuation.resume(returning: token) }
                else { continuation.resume(throwing: PTAppIntegrityError.unavailable) }
            }
        }
    }
    #endif

    public func assert(challenge: PTAppIntegrityChallenge,
                       artifact: Data,
                       keyID: String? = nil) async throws -> PTAppIntegrityPayload {
        try await challengeLedger.consume(challenge)
        let resolvedKeyID: String?
        if let keyID {
            resolvedKeyID = keyID
        } else {
            resolvedKeyID = try await keyStore.keyID()
        }
        guard let keyID = resolvedKeyID else {
            throw PTAppIntegrityError.keyUnavailable
        }
        return PTAppIntegrityPayload(keyID: keyID, challenge: challenge, artifact: artifact)
    }
}
