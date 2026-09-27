// English: Typed, Sendable storage contracts shared by all PTools storage backends.
// Español: Contratos de almacenamiento tipados y Sendable compartidos por todos los backends de PTools.
// 中文：所有 PTools 存储后端共享的类型化、Sendable 存储契约。

import Foundation

public struct PTStorageKey<Value: Codable & Sendable>: Hashable, Sendable {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct PTStorageNamespace: Codable, Hashable, Sendable {
    public let module: String
    public let feature: String
    public let account: String?
    public let environment: String?

    public init(module: String,
                feature: String,
                account: String? = nil,
                environment: String? = nil) {
        self.module = module
        self.feature = feature
        self.account = account
        self.environment = environment
    }

    public func scopedKey(_ key: String) -> String {
        [module, feature, account, environment, key]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ".")
    }
}

public enum PTStorageError: Error, Sendable, Equatable {
    case invalidKey
    case encodingFailed
    case decodingFailed
    case unavailable
    case migrationFailed(String)
}

public protocol PTStorageBackend: Sendable {
    func data(for key: String) async throws -> Data?
    func set(_ data: Data, for key: String) async throws
    func removeValue(for key: String) async throws
}

public struct PTStorageMigrationContext: Sendable {
    public let namespace: PTStorageNamespace
    public let fromVersion: Int
    public let toVersion: Int
    public let read: @Sendable (String) async throws -> Data?
    public let write: @Sendable (String, Data) async throws -> Void
    public let remove: @Sendable (String) async throws -> Void

    public init(namespace: PTStorageNamespace,
                fromVersion: Int,
                toVersion: Int,
                read: @escaping @Sendable (String) async throws -> Data?,
                write: @escaping @Sendable (String, Data) async throws -> Void,
                remove: @escaping @Sendable (String) async throws -> Void) {
        self.namespace = namespace
        self.fromVersion = fromVersion
        self.toVersion = toVersion
        self.read = read
        self.write = write
        self.remove = remove
    }
}

public protocol PTStorageMigration: Sendable {
    var identifier: String { get }
    var fromVersion: Int { get }
    var toVersion: Int { get }
    func migrate(using context: PTStorageMigrationContext) async throws
}
