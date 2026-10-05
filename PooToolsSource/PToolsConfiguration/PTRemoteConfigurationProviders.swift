// English: ETag-aware remote configuration providers reusing the existing configuration store.
// Español: Proveedores remotos de configuración conscientes de ETag que reutilizan el store existente.
// 中文：复用现有配置 Store、支持 ETag 的远程配置 Provider。

import Foundation

public struct PTHTTPConfigurationProvider: PTConfigurationProvider {
    public let endpoint: URL
    public let session: URLSession
    public let timeout: Duration
    public let cacheTTL: Duration
    private let state: PTConfigurationHTTPState

    public init(endpoint: URL,
                session: URLSession = .shared,
                timeout: Duration = .seconds(15),
                cacheTTL: Duration = .zero,
                state: PTConfigurationHTTPState = .init()) {
        self.endpoint = endpoint
        self.session = session
        self.timeout = timeout
        self.cacheTTL = cacheTTL
        self.state = state
    }

    public func values(for context: PTConfigurationContext) async throws -> [String: Data] {
        if cacheTTL > .zero, let cached = await state.freshValues(for: cacheTTL) { return cached }
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = Self.seconds(timeout)
        request.setValue(context.environment.rawValue, forHTTPHeaderField: "X-PTools-Environment")
        if let etag = await state.etag { request.setValue(etag, forHTTPHeaderField: "If-None-Match") }
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode == 304 {
            return await state.cachedValues ?? [:]
        }
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw PTConfigurationError.remoteProviderFailed
        }
        let values = try decodeValues(data)
        await state.update(etag: http.value(forHTTPHeaderField: "ETag"), values: values)
        return values
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
    fileprivate private(set) var cachedValues: [String: Data]?
    private var cachedAt: ContinuousClock.Instant?
    public init() {}
    fileprivate func update(etag: String?, values: [String: Data]) {
        self.etag = etag
        cachedValues = values
        cachedAt = .now
    }

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
