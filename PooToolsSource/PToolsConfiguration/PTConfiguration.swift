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

    public init(name: String,
                defaultState: PTFeatureFlagState = .unknown,
                conditions: [PTConfigurationCondition] = []) {
        self.name = name
        self.defaultState = defaultState
        self.conditions = conditions
    }

    fileprivate func evaluate(in context: PTConfigurationContext) -> PTFeatureFlagState {
        guard defaultState == .conditional else { return defaultState }
        return conditions.allSatisfy { $0.matches(context) } ? .enabled : .disabled
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
    public let flags: [String: PTFeatureFlagState]
    public let createdAt: Date

    public init(context: PTConfigurationContext,
                values: [String: Data] = [:],
                flags: [String: PTFeatureFlagState] = [:],
                createdAt: Date = .now) {
        self.context = context
        self.values = values
        self.flags = flags
        self.createdAt = createdAt
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

    public func isEnabled(_ name: String) -> Bool {
        flagState(for: name) == .enabled
    }
}

public enum PTConfigurationError: Error, Codable, Hashable, Sendable {
    case invalidKey
    case encodingFailed(String)
    case decodingFailed(String)
    case remoteProviderFailed
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
        for source in [PTConfigurationSource.defaults,
                       .bundle,
                       .environment,
                       .localOverride,
                       .remote,
                       .debugOverride] {
            for (key, value) in layers[source] ?? [:] {
                resolved[key] = value
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
