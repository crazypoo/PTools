// English: Typed, vendor-neutral configuration and feature-flag infrastructure for iOS 17+.
// Español: Infraestructura de configuración y feature flags tipada y neutral frente a proveedores para iOS 17+.
// 中文：面向 iOS 17+ 的类型化、与厂商无关的配置和功能开关基础设施。

import Foundation

#if SWIFT_PACKAGE
import PToolsStorage
import PToolsStorageCore
#endif

public enum PTConfigurationEnvironment: String, Codable, Hashable, Sendable {
    case development
    case staging
    case production
}

public struct PTConfigKey<Value: Codable & Sendable>: Sendable {
    public let name: String
    public let defaultValue: Value

    public init(name: String, defaultValue: Value) {
        self.name = name
        self.defaultValue = defaultValue
    }
}

public enum PTConfigurationSource: String, Codable, Hashable, Sendable, CaseIterable {
    case defaults
    case bundle
    case environment
    case localOverride
    case remote
    case debugOverride
}

public enum PTFeatureFlagState: String, Codable, Hashable, Sendable {
    case enabled
    case disabled
    case conditional
    case unknown
}

public enum PTConfigurationCondition: Codable, Hashable, Sendable {
    case environment(PTConfigurationEnvironment)
    case minimumOSVersion(String)
    case minimumAppVersion(String)
    case locale(String)
    case deviceFamily(String)

    fileprivate func matches(_ context: PTConfigurationContext) -> Bool {
        switch self {
        case .environment(let value):
            return value == context.environment
        case .minimumOSVersion(let value):
            return PTConfigurationCondition.isVersion(PTConfigurationCondition.version(context.osVersion),
                                                      atLeast: PTConfigurationCondition.version(value))
        case .minimumAppVersion(let value):
            return PTConfigurationCondition.isVersion(PTConfigurationCondition.version(context.appVersion),
                                                      atLeast: PTConfigurationCondition.version(value))
        case .locale(let value):
            return context.locale.caseInsensitiveCompare(value) == .orderedSame
        case .deviceFamily(let value):
            return context.deviceFamily.caseInsensitiveCompare(value) == .orderedSame
        }
    }

    private static func version(_ value: String) -> [Int] {
        value.split(separator: ".").map { Int($0) ?? 0 }
    }

    private static func isVersion(_ lhs: [Int], atLeast rhs: [Int]) -> Bool {
        let count = max(lhs.count, rhs.count)
        for index in 0..<count {
            let left = index < lhs.count ? lhs[index] : 0
            let right = index < rhs.count ? rhs[index] : 0
            if left != right { return left > right }
        }
        return true
    }
}

public struct PTFeatureFlagDefinition: Codable, Hashable, Sendable {
    public let name: String
    public let defaultState: PTFeatureFlagState
    public let conditions: [PTConfigurationCondition]
    public let targeting: PTConfigurationTargeting?

    public init(name: String,
                defaultState: PTFeatureFlagState = .unknown,
                conditions: [PTConfigurationCondition] = [],
                targeting: PTConfigurationTargeting? = nil) {
        self.name = name
        self.defaultState = defaultState
        self.conditions = conditions
        self.targeting = targeting
    }

    fileprivate func evaluate(in context: PTConfigurationContext) -> PTFeatureFlagState {
        guard defaultState == .conditional else { return defaultState }
        let conditionsMatch = conditions.allSatisfy { $0.matches(context) }
        let targetingMatches = targeting?.matches(context) ?? true
        return conditionsMatch && targetingMatches ? .enabled : .disabled
    }
}

public struct PTConfigurationContext: Codable, Hashable, Sendable {
    public let environment: PTConfigurationEnvironment
    public let appVersion: String
    public let buildNumber: String
    public let osVersion: String
    public let deviceFamily: String
    public let locale: String

    public init(environment: PTConfigurationEnvironment = .production,
                appVersion: String = "0",
                buildNumber: String = "0",
                osVersion: String = ProcessInfo.processInfo.operatingSystemVersionString,
                deviceFamily: String = "unknown",
                locale: String = Locale.current.identifier) {
        self.environment = environment
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.osVersion = osVersion
        self.deviceFamily = deviceFamily
        self.locale = locale
    }
}

public struct PTConfigurationSnapshot: Codable, Hashable, Sendable {
    public let context: PTConfigurationContext
    public let values: [String: Data]
    public let sources: [String: PTConfigurationSource]
    public let flags: [String: PTFeatureFlagState]
    public let createdAt: Date

    public init(context: PTConfigurationContext,
                values: [String: Data] = [:],
                sources: [String: PTConfigurationSource] = [:],
                flags: [String: PTFeatureFlagState] = [:],
                createdAt: Date = .now) {
        self.context = context
        self.values = values
        self.sources = sources
        self.flags = flags
        self.createdAt = createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        context = try container.decode(PTConfigurationContext.self, forKey: .context)
        values = try container.decode([String: Data].self, forKey: .values)
        sources = try container.decodeIfPresent([String: PTConfigurationSource].self, forKey: .sources) ?? [:]
        flags = try container.decodeIfPresent([String: PTFeatureFlagState].self, forKey: .flags) ?? [:]
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
    }

    private enum CodingKeys: String, CodingKey {
        case context, values, sources, flags, createdAt
    }

    public func value<Value: Codable & Sendable>(for key: PTConfigKey<Value>) throws -> Value {
        guard let data = values[key.name] else { return key.defaultValue }
        do {
            return try JSONDecoder().decode(Value.self, from: data)
        } catch {
            throw PTConfigurationError.decodingFailed(key.name)
        }
    }

    public func flagState(for name: String) -> PTFeatureFlagState {
        flags[name] ?? .unknown
    }

    public func source(for key: String) -> PTConfigurationSource? {
        sources[key]
    }

    public func isEnabled(_ name: String) -> Bool {
        flagState(for: name) == .enabled
    }

    public func isKillSwitchActive(_ name: String) -> Bool {
        guard let data = values["kill-switch.\(name)"],
              let active = try? JSONDecoder().decode(Bool.self, from: data) else { return false }
        return active
    }
}

public enum PTConfigurationError: Error, Codable, Hashable, Sendable {
    case invalidKey
    case encodingFailed(String)
    case decodingFailed(String)
    case remoteProviderFailed
    case remoteHTTPStatus(Int)
    case killSwitchActive(String)
    case signedConfigurationExpired
    case signatureInvalid
}

// English: Targeting values are evaluated before a feature becomes visible to the caller.
// Español: Los valores de targeting se evalúan antes de exponer una feature al caller.
// 中文：功能开关对调用方可见前，先统一评估这些定向条件。
public struct PTConfigurationTargeting: Codable, Hashable, Sendable {
    public let environment: PTConfigurationEnvironment?
    public let minimumAppVersion: String?
    public let minimumBuildNumber: Int?
    public let locale: String?
    public let deviceFamily: String?
    public let percentage: Int?
    public let stableIdentifier: String?

    public init(environment: PTConfigurationEnvironment? = nil,
                minimumAppVersion: String? = nil,
                minimumBuildNumber: Int? = nil,
                locale: String? = nil,
                deviceFamily: String? = nil,
                percentage: Int? = nil,
                stableIdentifier: String? = nil) {
        self.environment = environment
        self.minimumAppVersion = minimumAppVersion
        self.minimumBuildNumber = minimumBuildNumber
        self.locale = locale
        self.deviceFamily = deviceFamily
        self.percentage = percentage
        self.stableIdentifier = stableIdentifier
    }

    public func matches(_ context: PTConfigurationContext) -> Bool {
        if let environment, environment != context.environment { return false }
        if let minimumAppVersion,
           !PTConfigurationVersion.isAtLeast(context.appVersion, minimumAppVersion) { return false }
        if let minimumBuildNumber,
           (Int(context.buildNumber) ?? 0) < minimumBuildNumber { return false }
        if let locale,
           context.locale.caseInsensitiveCompare(locale) != .orderedSame { return false }
        if let deviceFamily,
           context.deviceFamily.caseInsensitiveCompare(deviceFamily) != .orderedSame { return false }
        if let percentage {
            let key = stableIdentifier ?? context.appVersion + ":" + context.buildNumber
            let hash = key.utf8.reduce(UInt64(0)) { ($0 &* 31) &+ UInt64($1) }
            if Int(hash % 100) >= min(max(percentage, 0), 100) { return false }
        }
        return true
    }
}

public enum PTConfigurationVersion {
    public static func isAtLeast(_ lhs: String, _ rhs: String) -> Bool {
        let left = lhs.split(separator: ".").map { Int($0) ?? 0 }
        let right = rhs.split(separator: ".").map { Int($0) ?? 0 }
        for index in 0..<max(left.count, right.count) {
            let l = index < left.count ? left[index] : 0
            let r = index < right.count ? right[index] : 0
            if l != r { return l > r }
        }
        return true
    }
}

public protocol PTConfigurationProvider: Sendable {
    func values(for context: PTConfigurationContext) async throws -> [String: Data]
}

public actor PTConfigurationStore {
    private let context: PTConfigurationContext
    private let provider: (any PTConfigurationProvider)?
    private let storage: PTStorage?
    private var layers: [PTConfigurationSource: [String: Data]]
    private var definitions: [String: PTFeatureFlagDefinition]
    private var currentSnapshot: PTConfigurationSnapshot

    public init(context: PTConfigurationContext = .init(),
                defaults: [String: Data] = [:],
                bundle: [String: Data] = [:],
                environment: [String: Data] = [:],
                localOverrides: [String: Data] = [:],
                flags: [PTFeatureFlagDefinition] = [],
                provider: (any PTConfigurationProvider)? = nil,
                storage: PTStorage? = nil) {
        self.context = context
        self.provider = provider
        self.storage = storage
        self.layers = [
            .defaults: defaults,
            .bundle: bundle,
            .environment: environment,
            .localOverride: localOverrides
        ]
        self.definitions = Dictionary(uniqueKeysWithValues: flags.map { ($0.name, $0) })
        self.currentSnapshot = PTConfigurationSnapshot(context: context)
    }

    public func refresh() async throws -> PTConfigurationSnapshot {
        if let provider {
            do {
                layers[.remote] = try await provider.values(for: context)
            } catch {
                throw PTConfigurationError.remoteProviderFailed
            }
        }

        var resolved: [String: Data] = [:]
        var resolvedSources: [String: PTConfigurationSource] = [:]
        for source in [PTConfigurationSource.defaults,
                       .bundle,
                       .environment,
                       .localOverride,
                       .remote,
            .debugOverride] {
            for (key, value) in layers[source] ?? [:] {
                resolved[key] = value
                resolvedSources[key] = source
            }
        }

        var resolvedFlags: [String: PTFeatureFlagState] = [:]
        for definition in definitions.values {
            if let data = resolved[flagKey(definition.name)],
               let state = try? JSONDecoder().decode(PTFeatureFlagState.self, from: data) {
                resolvedFlags[definition.name] = state == .conditional
                    ? definition.evaluate(in: context)
                    : state
            } else {
                resolvedFlags[definition.name] = definition.evaluate(in: context)
            }
        }

        currentSnapshot = PTConfigurationSnapshot(context: context,
                                                  values: resolved,
                                                  sources: resolvedSources,
                                                  flags: resolvedFlags)
        if let storage {
            try? await storage.set(currentSnapshot,
                                   for: PTStorageKey<PTConfigurationSnapshot>("configuration.snapshot"))
        }
        return currentSnapshot
    }

    public func snapshot() -> PTConfigurationSnapshot {
        currentSnapshot
    }

    public func value<Value: Codable & Sendable>(for key: PTConfigKey<Value>) throws -> Value {
        try currentSnapshot.value(for: key)
    }

    public func value<Value: Codable & Sendable>(for key: PTConfigKey<Value>,
                                                 in snapshot: PTConfigurationSnapshot) throws -> Value {
        try snapshot.value(for: key)
    }

    public func ensureKillSwitchIsInactive(_ name: String,
                                           in snapshot: PTConfigurationSnapshot? = nil) throws {
        let value = snapshot ?? currentSnapshot
        if value.isKillSwitchActive(name) {
            throw PTConfigurationError.killSwitchActive(name)
        }
    }

    public func setLocalOverride<Value: Codable & Sendable>(_ value: Value,
                                                            for key: PTConfigKey<Value>) throws {
        try set(value, for: key, source: .localOverride)
    }

    public func setFlag(_ state: PTFeatureFlagState, name: String,
                       source: PTConfigurationSource = .localOverride) throws {
        guard !name.isEmpty else { throw PTConfigurationError.invalidKey }
        try set(state, for: PTConfigKey(name: flagKey(name), defaultValue: .unknown), source: source)
    }

    public func loadCachedSnapshot() async throws -> PTConfigurationSnapshot? {
        guard let storage,
              let cached = try await storage.value(for: PTStorageKey<PTConfigurationSnapshot>("configuration.snapshot")) else {
            return nil
        }
        currentSnapshot = cached
        return cached
    }

#if DEBUG
    public func setDebugOverride<Value: Codable & Sendable>(_ value: Value,
                                                             for key: PTConfigKey<Value>) throws {
        try set(value, for: key, source: .debugOverride)
    }

    public func resetDebugOverrides() {
        layers[.debugOverride] = nil
    }
#endif

    private func set<Value: Codable & Sendable>(_ value: Value,
                                                for key: PTConfigKey<Value>,
                                                source: PTConfigurationSource) throws {
        guard !key.name.isEmpty else { throw PTConfigurationError.invalidKey }
        do {
            layers[source, default: [:]][key.name] = try JSONEncoder().encode(value)
        } catch {
            throw PTConfigurationError.encodingFailed(key.name)
        }
    }

    private func flagKey(_ name: String) -> String { "flag.\(name)" }
}
