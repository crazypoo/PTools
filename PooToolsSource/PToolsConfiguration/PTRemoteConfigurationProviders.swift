// English: ETag-aware remote configuration providers reusing the existing configuration store.
// Español: Proveedores remotos de configuración conscientes de ETag que reutilizan el store existente.
// 中文：复用现有配置 Store、支持 ETag 的远程配置 Provider。

import Foundation
#if SWIFT_PACKAGE
import PToolsStorage
import PToolsStorageCore
#endif

public struct PTConfigurationRetryPolicy: Sendable, Equatable {
    public let maxAttempts: Int
    public let initialDelay: Duration
    public let maxDelay: Duration

    public init(maxAttempts: Int = 3,
                initialDelay: Duration = .milliseconds(250),
                maxDelay: Duration = .seconds(5)) {
        self.maxAttempts = max(1, maxAttempts)
        self.initialDelay = initialDelay
        self.maxDelay = maxDelay
    }
}

public struct PTConfigurationRemoteMetadata: Sendable, Equatable {
    public let statusCode: Int?
    public let etag: String?
    public let lastModified: String?
    public let retryAfter: String?
    public let attemptCount: Int
    public let receivedAt: Date

    public init(statusCode: Int? = nil,
                etag: String? = nil,
                lastModified: String? = nil,
                retryAfter: String? = nil,
                attemptCount: Int = 0,
                receivedAt: Date = .now) {
        self.statusCode = statusCode
        self.etag = etag
        self.lastModified = lastModified
        self.retryAfter = retryAfter
        self.attemptCount = attemptCount
        self.receivedAt = receivedAt
    }
}

public struct PTHTTPConfigurationProvider: PTConfigurationProvider {
    public let endpoint: URL
    public let session: URLSession
    public let timeout: Duration
    public let cacheTTL: Duration
    public let retryPolicy: PTConfigurationRetryPolicy
    private let state: PTConfigurationHTTPState

    public init(endpoint: URL,
                session: URLSession = .shared,
                timeout: Duration = .seconds(15),
                cacheTTL: Duration = .zero,
                retryPolicy: PTConfigurationRetryPolicy = .init(),
                state: PTConfigurationHTTPState = .init()) {
        self.endpoint = endpoint
        self.session = session
        self.timeout = timeout
        self.cacheTTL = cacheTTL
        self.retryPolicy = retryPolicy
        self.state = state
    }

    public func values(for context: PTConfigurationContext) async throws -> [String: Data] {
        if cacheTTL > .zero, let cached = await state.freshValues(for: cacheTTL) { return cached }
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = Self.seconds(timeout)
        request.setValue(context.environment.rawValue, forHTTPHeaderField: "X-PTools-Environment")
        if let etag = await state.etag { request.setValue(etag, forHTTPHeaderField: "If-None-Match") }
        if let lastModified = await state.lastModified {
            request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
        }
        var attempt = 0
        while true {
            attempt += 1
            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw PTConfigurationError.remoteProviderFailed
                }
                let metadata = PTConfigurationRemoteMetadata(statusCode: http.statusCode,
                                                             etag: http.value(forHTTPHeaderField: "ETag"),
                                                             lastModified: http.value(forHTTPHeaderField: "Last-Modified"),
                                                             retryAfter: http.value(forHTTPHeaderField: "Retry-After"),
                                                             attemptCount: attempt)
                await state.update(metadata: metadata)
                if http.statusCode == 304 { return await state.cachedValues ?? [:] }
                if (http.statusCode == 429 || http.statusCode == 503), attempt < retryPolicy.maxAttempts {
                    try await Task.sleep(for: retryDelay(attempt: attempt, serverValue: metadata.retryAfter))
                    continue
                }
                guard (200..<300).contains(http.statusCode) else {
                    throw PTConfigurationError.remoteHTTPStatus(http.statusCode)
                }
                let values = try decodeValues(data)
                await state.update(etag: metadata.etag,
                                   lastModified: metadata.lastModified,
                                   values: values)
                return values
            } catch is CancellationError {
                throw CancellationError()
            } catch let error as PTConfigurationError {
                if attempt >= retryPolicy.maxAttempts { throw error }
                try await Task.sleep(for: retryDelay(attempt: attempt, serverValue: nil))
            } catch {
                if attempt >= retryPolicy.maxAttempts { throw PTConfigurationError.remoteProviderFailed }
                try await Task.sleep(for: retryDelay(attempt: attempt, serverValue: nil))
            }
        }
    }

    private func retryDelay(attempt: Int, serverValue: String?) -> Duration {
        if let seconds = serverValue.flatMap(Double.init), seconds >= 0 {
            return min(.seconds(seconds), retryPolicy.maxDelay)
        }
        let base = seconds(retryPolicy.initialDelay) * pow(2, Double(max(0, attempt - 1)))
        return .seconds(min(base, seconds(retryPolicy.maxDelay)))
    }

    private func seconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds)
            + Double(duration.components.attoseconds) / 1_000_000_000_000_000_000
    }

    private static func seconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1_000_000_000_000_000_000
    }

    private func decodeValues(_ data: Data) throws -> [String: Data] {
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PTConfigurationError.remoteProviderFailed
        }
        return object.reduce(into: [String: Data]()) { result, item in
            if let value = try? JSONSerialization.data(withJSONObject: item.value) { result[item.key] = value }
        }
    }
}

public actor PTConfigurationHTTPState {
    fileprivate private(set) var etag: String?
    fileprivate private(set) var lastModified: String?
    fileprivate private(set) var cachedValues: [String: Data]?
    fileprivate private(set) var metadata = PTConfigurationRemoteMetadata()
    private var cachedAt: ContinuousClock.Instant?
    public init() {}
    fileprivate func update(metadata: PTConfigurationRemoteMetadata) {
        self.metadata = metadata
    }

    fileprivate func update(etag: String?, lastModified: String?, values: [String: Data]) {
        self.etag = etag
        self.lastModified = lastModified
        cachedValues = values
        cachedAt = .now
        metadata = PTConfigurationRemoteMetadata(statusCode: 200,
                                                 etag: etag,
                                                 lastModified: lastModified,
                                                 attemptCount: metadata.attemptCount)
    }

    public func remoteMetadata() -> PTConfigurationRemoteMetadata { metadata }

    fileprivate func freshValues(for ttl: Duration) -> [String: Data]? {
        guard let cachedValues, let cachedAt else { return nil }
        return ContinuousClock.now - cachedAt < ttl ? cachedValues : nil
    }
}

public struct PTCachedConfigurationProvider: PTConfigurationProvider {
    public let remote: any PTConfigurationProvider
    public let cache: any PTConfigurationProvider
    public init(remote: any PTConfigurationProvider, cache: any PTConfigurationProvider) {
        self.remote = remote; self.cache = cache
    }
    public func values(for context: PTConfigurationContext) async throws -> [String: Data] {
        do { return try await remote.values(for: context) }
        catch { return try await cache.values(for: context) }
    }
}

public struct PTCompositeConfigurationProvider: PTConfigurationProvider {
    public let providers: [any PTConfigurationProvider]
    public init(providers: [any PTConfigurationProvider]) { self.providers = providers }
    public func values(for context: PTConfigurationContext) async throws -> [String: Data] {
        var merged: [String: Data] = [:]
        for provider in providers { merged.merge(try await provider.values(for: context), uniquingKeysWith: { _, new in new }) }
        return merged
    }
}

public protocol PTSignedConfigurationVerifier: Sendable {
    func verify(values: [String: Data], context: PTConfigurationContext) async throws -> Bool
}

public protocol PTLastKnownGoodStore: Sendable {
    func load(context: PTConfigurationContext) async throws -> [String: Data]?
    func save(_ values: [String: Data], context: PTConfigurationContext) async throws
}

public struct PTStorageLastKnownGoodStore: PTLastKnownGoodStore {
    private let storage: PTStorage
    private let keyPrefix: String

    public init(storage: PTStorage, keyPrefix: String = "configuration.last-known-good") {
        self.storage = storage
        self.keyPrefix = keyPrefix
    }

    public func load(context: PTConfigurationContext) async throws -> [String: Data]? {
        guard let data = try await storage.data(for: key(for: context)) else { return nil }
        return try JSONDecoder().decode([String: Data].self, from: data)
    }

    public func save(_ values: [String: Data], context: PTConfigurationContext) async throws {
        try await storage.set(try JSONEncoder().encode(values), for: key(for: context))
    }

    private func key(for context: PTConfigurationContext) -> String {
        "\(keyPrefix).\(context.environment.rawValue).\(context.deviceFamily)"
    }
}

public struct PTSignedConfigurationEnvelope: Codable, Sendable, Equatable {
    public let values: [String: Data]
    public let signature: Data
    public let keyID: String
    public let issuedAt: Date
    public let expiresAt: Date
    public let version: Int

    public init(values: [String: Data],
                signature: Data,
                keyID: String,
                issuedAt: Date = .distantPast,
                expiresAt: Date = .distantFuture,
                version: Int = 0) {
        self.values = values
        self.signature = signature
        self.keyID = keyID
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
        self.version = max(0, version)
    }

    private enum CodingKeys: String, CodingKey {
        case values, signature, keyID, issuedAt, expiresAt, version
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        values = try container.decode([String: Data].self, forKey: .values)
        signature = try container.decode(Data.self, forKey: .signature)
        keyID = try container.decode(String.self, forKey: .keyID)
        issuedAt = try container.decodeIfPresent(Date.self, forKey: .issuedAt) ?? .distantPast
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt) ?? .distantFuture
        version = max(0, try container.decodeIfPresent(Int.self, forKey: .version) ?? 0)
    }
}

public actor PTPersistentLastKnownGoodConfigurationProvider: PTConfigurationProvider {
    private let remote: any PTConfigurationProvider
    private let storage: PTStorage
    private let key: PTStorageKey<[String: Data]>
    private let verifier: (any PTSignedConfigurationVerifier)?

    public init(remote: any PTConfigurationProvider,
                storage: PTStorage,
                key: PTStorageKey<[String: Data]> = .init("configuration.last-known-good"),
                verifier: (any PTSignedConfigurationVerifier)? = nil) {
        self.remote = remote
        self.storage = storage
        self.key = key
        self.verifier = verifier
    }

    public func values(for context: PTConfigurationContext) async throws -> [String: Data] {
        do {
            let values = try await remote.values(for: context)
            if let verifier, try await verifier.verify(values: values, context: context) == false {
                throw PTConfigurationError.remoteProviderFailed
            }
            try? await storage.set(values, for: key)
            return values
        } catch {
            return try await storage.value(for: key) ?? [:]
        }
    }
}

public typealias PTStoredConfigurationProvider = PTPersistentLastKnownGoodConfigurationProvider

public protocol PTSignedConfigurationEnvelopeProvider: Sendable {
    func envelope(for context: PTConfigurationContext) async throws -> PTSignedConfigurationEnvelope
}

// English: Verify an immutable envelope before it can enter the configuration store.
// Español: Verifica un envelope inmutable antes de introducirlo en el store de configuración.
// 中文：签名配置必须先验证不可变 Envelope，才能进入配置 Store。
public struct PTSignedConfigurationProvider: PTConfigurationProvider {
    public let source: any PTSignedConfigurationEnvelopeProvider
    public let verifier: any PTSignedConfigurationVerifier
    public let clock: @Sendable () -> Date

    public init(source: any PTSignedConfigurationEnvelopeProvider,
                verifier: any PTSignedConfigurationVerifier,
                clock: @escaping @Sendable () -> Date = { .now }) {
        self.source = source
        self.verifier = verifier
        self.clock = clock
    }

    public func values(for context: PTConfigurationContext) async throws -> [String: Data] {
        let envelope = try await source.envelope(for: context)
        let now = clock()
        guard now >= envelope.issuedAt, now < envelope.expiresAt else {
            throw PTConfigurationError.signedConfigurationExpired
        }
        guard try await verifier.verify(values: envelope.values, context: context) else {
            throw PTConfigurationError.signatureInvalid
        }
        return envelope.values
    }
}

// English: Keeps the last verified snapshot when a remote response is unavailable or fails signature validation.
// Español: Conserva el último snapshot verificado cuando la respuesta remota no está disponible o falla la firma.
// 中文：远程响应不可用或签名校验失败时，继续使用最后一个已验证快照。
public struct PTLastKnownGoodConfigurationProvider: PTConfigurationProvider {
    public let remote: any PTConfigurationProvider
    public let fallback: any PTConfigurationProvider
    public let verifier: (any PTSignedConfigurationVerifier)?

    public init(remote: any PTConfigurationProvider,
                fallback: any PTConfigurationProvider,
                verifier: (any PTSignedConfigurationVerifier)? = nil) {
        self.remote = remote
        self.fallback = fallback
        self.verifier = verifier
    }

    public func values(for context: PTConfigurationContext) async throws -> [String: Data] {
        do {
            let values = try await remote.values(for: context)
            if let verifier, try await verifier.verify(values: values, context: context) == false {
                throw PTConfigurationError.remoteProviderFailed
            }
            return values
        } catch {
            return try await fallback.values(for: context)
        }
    }
}

public struct PTRolloutAssignment: Sendable, Equatable {
    public let flag: String
    public let enabled: Bool
    public let bucket: Int
    public init(flag: String, stableKey: String, percentage: Int) {
        self.flag = flag
        let hash = stableKey.utf8.reduce(UInt64(0)) { ($0 &* 31) &+ UInt64($1) }
        bucket = Int(hash % 100)
        enabled = bucket < min(max(percentage, 0), 100)
    }
}
