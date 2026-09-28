// English: Native storage implementations with one typed actor boundary.
// Español: Implementaciones de almacenamiento nativas con un único límite de actor tipado.
// 中文：基于原生能力并通过单一类型化 actor 边界实现的存储后端。

import Foundation
#if SWIFT_PACKAGE
import PToolsStorageCore
import PooToolsKeyChain
#endif

public actor PTMemoryStorage: PTStorageBackend {
    private var values: [String: Data] = [:]

    public init() {}

    public func data(for key: String) async throws -> Data? { values[key] }

    public func set(_ data: Data, for key: String) async throws {
        guard !key.isEmpty else { throw PTStorageError.invalidKey }
        values[key] = data
    }

    public func removeValue(for key: String) async throws {
        values[key] = nil
    }
}

public actor PTUserDefaultsStorage: PTStorageBackend {
    private let suiteName: String?

    public init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }

    public func data(for key: String) async throws -> Data? {
        defaults.data(forKey: key)
    }

    public func set(_ data: Data, for key: String) async throws {
        guard !key.isEmpty else { throw PTStorageError.invalidKey }
        defaults.set(data, forKey: key)
    }

    public func removeValue(for key: String) async throws {
        defaults.removeObject(forKey: key)
    }

    private var defaults: UserDefaults {
        if let suiteName, let suite = UserDefaults(suiteName: suiteName) {
            return suite
        }
        return .standard
    }
}

public actor PTFileStorage: PTStorageBackend {
    public let directoryURL: URL

    public init(directoryURL: URL) {
        self.directoryURL = directoryURL
    }

    public func data(for key: String) async throws -> Data? {
        try ensureDirectory()
        let url = fileURL(for: key)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try Data(contentsOf: url)
    }

    public func set(_ data: Data, for key: String) async throws {
        guard !key.isEmpty else { throw PTStorageError.invalidKey }
        try ensureDirectory()
        // English: Data.atomic replaces the destination after the temporary write completes.
        // Español: Data.atomic reemplaza el destino después de completar la escritura temporal.
        // 中文：Data.atomic 会在临时写入完成后替换目标文件。
        try data.write(to: fileURL(for: key), options: [.atomic])
    }

    public func removeValue(for key: String) async throws {
        let url = fileURL(for: key)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    private func ensureDirectory() throws {
        try FileManager.default.createDirectory(at: directoryURL,
                                                withIntermediateDirectories: true)
    }

    private func fileURL(for key: String) -> URL {
        let encoded = Data(key.utf8).base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")
        return directoryURL.appendingPathComponent(encoded)
    }
}

// English: Use the existing PooTools KeyChain implementation as the single Security boundary.
// Español: Usa la implementación existente de PooTools KeyChain como único límite de Security.
// 中文：复用现有 PooTools KeyChain 实现，保证整个仓库只有一个 Security 边界。
// English: Keep the historical actor as the single Keychain-backed implementation.
// Español: Mantén el actor histórico como la única implementación respaldada por Keychain.
// 中文：保留历史 actor 作为唯一的 Keychain 存储实现。
public actor PTKeychainStorage: PTStorageBackend {
    private let service: String

    public init(service: String) {
        self.service = service
    }

    public func data(for key: String) async throws -> Data? {
        guard !service.isEmpty, !key.isEmpty else { throw PTStorageError.invalidKey }
        guard let encoded = PTKeyChain.getPassword(service: service as NSString,
                                                    account: key as NSString) else { return nil }
        return Data(base64Encoded: encoded)
    }

    public func set(_ data: Data, for key: String) async throws {
        guard !service.isEmpty, !key.isEmpty else { throw PTStorageError.invalidKey }
        let encoded = data.base64EncodedString()
        guard PTKeyChain.saveAccountInfo(service: service as NSString,
                                         account: key as NSString,
                                         password: encoded as NSString) else {
            throw PTStorageError.unavailable
        }
    }

    public func removeValue(for key: String) async throws {
        guard !service.isEmpty, !key.isEmpty else { throw PTStorageError.invalidKey }
        var deleted = false
        PTKeyChain.deleteAccountInfo(service: service as NSString,
                                     account: key as NSString) { success, status in
            deleted = success || status == .itemNotFound
        }
        guard deleted else { throw PTStorageError.unavailable }
    }
}

// English: Expose the canonical adapter spelling without creating a second Security implementation.
// Español: Expone el nombre canónico del adaptador sin crear una segunda implementación de Security.
// 中文：暴露规范的适配器名称，但不创建第二套 Security 实现。
public typealias PTKeychainStorageAdapter = PTKeychainStorage

public actor PTCompositeStorage: PTStorageBackend {
    private let primary: any PTStorageBackend
    private let fallback: (any PTStorageBackend)?

    public init(primary: any PTStorageBackend,
                fallback: (any PTStorageBackend)? = nil) {
        self.primary = primary
        self.fallback = fallback
    }

    public func data(for key: String) async throws -> Data? {
        if let value = try await primary.data(for: key) { return value }
        return try await fallback?.data(for: key)
    }

    public func set(_ data: Data, for key: String) async throws {
        try await primary.set(data, for: key)
    }

    public func removeValue(for key: String) async throws {
        try await primary.removeValue(for: key)
        try await fallback?.removeValue(for: key)
    }
}

public actor PTStorage {
    private let backend: any PTStorageBackend
    public let namespace: PTStorageNamespace
    private var observers: [String: [UUID: AsyncStream<Data?>.Continuation]] = [:]

    public init(namespace: PTStorageNamespace,
                backend: any PTStorageBackend = PTMemoryStorage()) {
        self.namespace = namespace
        self.backend = backend
    }

    public func value<Value: Codable & Sendable>(for key: PTStorageKey<Value>) async throws -> Value? {
        guard let data = try await data(for: key.rawValue) else { return nil }
        do {
            return try JSONDecoder().decode(Value.self, from: data)
        } catch {
            throw PTStorageError.decodingFailed
        }
    }

    public func set<Value: Codable & Sendable>(_ value: Value,
                                               for key: PTStorageKey<Value>) async throws {
        do {
            try await set(try JSONEncoder().encode(value), for: key.rawValue)
        } catch let error as PTStorageError {
            throw error
        } catch {
            throw PTStorageError.encodingFailed
        }
    }

    public func remove<Value>(for key: PTStorageKey<Value>) async throws where Value: Codable & Sendable {
        try await remove(for: key.rawValue)
    }

    public func data(for key: String) async throws -> Data? {
        try await backend.data(for: namespace.scopedKey(key))
    }

    public func set(_ data: Data, for key: String) async throws {
        try await backend.set(data, for: namespace.scopedKey(key))
        notify(key: key, value: data)
    }

    public func remove(for key: String) async throws {
        try await backend.removeValue(for: namespace.scopedKey(key))
        notify(key: key, value: nil)
    }

    public func values(for key: String) async throws -> AsyncStream<Data?> {
        let id = UUID()
        let current = try await data(for: key)
        return AsyncStream { continuation in
            observers[key, default: [:]][id] = continuation
            continuation.yield(current)
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { await self?.removeObserver(id, for: key) }
            }
        }
    }

    public func apply(_ migrations: [any PTStorageMigration], fromVersion: Int) async throws -> Int {
        var version = fromVersion
        for migration in migrations.sorted(by: { $0.fromVersion < $1.fromVersion }) where migration.fromVersion == version {
            let context = PTStorageMigrationContext(
                namespace: namespace,
                fromVersion: migration.fromVersion,
                toVersion: migration.toVersion,
                read: { [self] key in try await data(for: key) },
                write: { [self] key, value in try await set(value, for: key) },
                remove: { [self] key in try await remove(for: key) }
            )
            do {
                try await migration.migrate(using: context)
            } catch {
                throw PTStorageError.migrationFailed(migration.identifier)
            }
            version = migration.toVersion
        }
        return version
    }

    private func notify(key: String, value: Data?) {
        if let continuations = observers[key]?.values {
            for continuation in continuations {
                continuation.yield(value)
            }
        }
    }

    private func removeObserver(_ id: UUID, for key: String) {
        observers[key]?[id] = nil
        if observers[key]?.isEmpty == true { observers[key] = nil }
    }
}
