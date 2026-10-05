// English: Foundation-only contracts for the Swift 6 SQLite database layer.
// Español: Contratos solo de Foundation para la capa SQLite Swift 6.
// 中文：Swift 6 SQLite 数据库层的 Foundation-only 契约。

import Foundation

public enum PTDatabaseValue: Sendable, Equatable, Codable {
    case null
    case integer(Int64)
    case real(Double)
    case text(String)
    case blob(Data)
    case boolean(Bool)
    case date(Date)
    case decimal(String)

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let value = try? container.decode(Bool.self) { self = .boolean(value) }
        else if let value = try? container.decode(Int64.self) { self = .integer(value) }
        else if let value = try? container.decode(Double.self) { self = .real(value) }
        else if let value = try? container.decode(String.self) { self = .text(value) }
        else { throw PTDatabaseError.invalidValue }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .integer(let value): try container.encode(value)
        case .real(let value): try container.encode(value)
        case .text(let value): try container.encode(value)
        case .blob(let value): try container.encode(value.base64EncodedString())
        case .boolean(let value): try container.encode(value)
        case .date(let value): try container.encode(value.timeIntervalSince1970)
        case .decimal(let value): try container.encode(value)
        }
    }
}

public struct PTDatabaseRow: Sendable, Equatable {
    public let values: [String: PTDatabaseValue]

    public init(values: [String: PTDatabaseValue] = [:]) { self.values = values }
    public subscript(_ column: String) -> PTDatabaseValue? { values[column] }
}

public struct PTDatabaseQuery: Sendable, Equatable {
    public let sql: String
    public let arguments: [PTDatabaseValue]

    public init(_ sql: String, arguments: [PTDatabaseValue] = []) {
        self.sql = sql
        self.arguments = arguments
    }
}

public struct PTDatabaseStatementDescriptor: Sendable, Equatable {
    public let name: String
    public let query: PTDatabaseQuery
    public init(name: String, query: PTDatabaseQuery) {
        self.name = name
        self.query = query
    }
}

public enum PTDatabaseTransactionMode: String, Sendable, Codable {
    case deferred
    case immediate
    case exclusive
}

public struct PTDatabaseSchemaVersion: Sendable, Equatable, Codable {
    public let value: Int
    public init(_ value: Int) { self.value = max(0, value) }
}

public struct PTDatabaseMigrationPlan: Sendable, Equatable {
    public let migrations: [PTDatabaseMigration]
    public let destructive: Bool
    public let backupPolicy: PTDatabaseMigrationBackupPolicy

    public init(migrations: [PTDatabaseMigration],
                destructive: Bool = false,
                backupPolicy: PTDatabaseMigrationBackupPolicy = .none) {
        self.migrations = migrations
        self.destructive = destructive
        self.backupPolicy = backupPolicy
    }
}

public enum PTDatabaseMigrationBackupPolicy: Sendable, Equatable {
    case none
    case beforeMigration(URL)
}

// English: Runtime SQLite settings are immutable and applied when the actor opens the handle.
// Español: La configuración de SQLite es inmutable y se aplica al abrir el handle del actor.
// 中文：SQLite 运行时配置是不可变值，并在 actor 打开句柄时应用。
public struct PTDatabaseRuntimeConfiguration: Sendable, Equatable, Codable {
    public enum JournalMode: String, Sendable, Codable {
        case wal
        case delete
        case truncate
        case memory
        case off
    }

    public enum SynchronousMode: String, Sendable, Codable {
        case off
        case normal
        case full
        case extra
    }

    public enum CheckpointPolicy: String, Sendable, Codable {
        case never
        case beforeBackup
    }

    public let foreignKeysEnabled: Bool
    public let journalMode: JournalMode
    public let synchronousMode: SynchronousMode
    public let busyTimeoutMilliseconds: Int32
    public let checkpointPolicy: CheckpointPolicy
    public let checkpointOnBackup: Bool

    public init(foreignKeysEnabled: Bool = true,
                journalMode: JournalMode = .wal,
                synchronousMode: SynchronousMode = .normal,
                busyTimeoutMilliseconds: Int32 = 5_000,
                checkpointOnBackup: Bool = true,
                checkpointPolicy: CheckpointPolicy? = nil) {
        self.foreignKeysEnabled = foreignKeysEnabled
        self.journalMode = journalMode
        self.synchronousMode = synchronousMode
        self.busyTimeoutMilliseconds = max(0, busyTimeoutMilliseconds)
        self.checkpointPolicy = checkpointPolicy ?? (checkpointOnBackup ? .beforeBackup : .never)
        self.checkpointOnBackup = self.checkpointPolicy == .beforeBackup
    }
}

public struct PTDatabaseBackupDescriptor: Sendable, Equatable, Codable {
    public let url: URL
    public let createdAt: Date
    public let byteCount: Int64
    public let schemaVersion: Int
    public let integrityPassed: Bool
    public init(url: URL,
                createdAt: Date = .now,
                byteCount: Int64 = 0,
                schemaVersion: Int = 0,
                integrityPassed: Bool = true) {
        self.url = url
        self.createdAt = createdAt
        self.byteCount = max(0, byteCount)
        self.schemaVersion = max(0, schemaVersion)
        self.integrityPassed = integrityPassed
    }
}

public struct PTDatabaseRuntimeSnapshot: Sendable, Equatable, Codable {
    public let sqliteVersion: String
    public let journalMode: String
    public let synchronousMode: String
    public let foreignKeysEnabled: Bool
    public let schemaVersion: Int

    public init(sqliteVersion: String,
                journalMode: String,
                synchronousMode: String,
                foreignKeysEnabled: Bool,
                schemaVersion: Int) {
        self.sqliteVersion = sqliteVersion
        self.journalMode = journalMode
        self.synchronousMode = synchronousMode
        self.foreignKeysEnabled = foreignKeysEnabled
        self.schemaVersion = max(0, schemaVersion)
    }
}

public struct PTDatabaseIntegrityReport: Sendable, Equatable, Codable {
    public let passed: Bool
    public let result: String
    public let schemaVersion: Int
    public init(passed: Bool, result: String, schemaVersion: Int) {
        self.passed = passed
        self.result = result
        self.schemaVersion = max(0, schemaVersion)
    }
}

public enum PTDatabaseRestoreVerification: Sendable, Equatable {
    case integrityCheck
    case skip
}

public enum PTDatabaseRestorePolicy: Sendable, Equatable {
    case replaceExisting
    case failIfExisting
}

public struct PTDatabaseObservation: Sendable, Equatable {
    public let table: String?
    public let change: PTDatabaseChange
    public init(table: String? = nil, change: PTDatabaseChange) {
        self.table = table
        self.change = change
    }
}

public struct PTDatabasePage<Value: Sendable>: Sendable {
    public let values: [Value]
    public let offset: Int
    public let limit: Int
    public let hasMore: Bool
    public init(values: [Value], offset: Int, limit: Int, hasMore: Bool) {
        self.values = values
        self.offset = offset
        self.limit = limit
        self.hasMore = hasMore
    }
}

public struct PTDatabaseSort: Sendable, Equatable {
    public let column: String
    public let descending: Bool
    public init(column: String, descending: Bool = false) {
        self.column = column
        self.descending = descending
    }
}

public struct PTDatabasePredicate: Sendable, Equatable {
    public let sql: String
    public let arguments: [PTDatabaseValue]
    public init(sql: String, arguments: [PTDatabaseValue] = []) {
        self.sql = sql
        self.arguments = arguments
    }
}

// English: A closure-free row decoder keeps model mapping optional and independent from PTModel.
// Español: Un decodificador de filas sin dependencias mantiene el mapeo de modelos opcional e independiente de PTModel.
// 中文：无闭包依赖的行解码器让模型映射保持可选，并与 PTModel 解耦。
public struct PTDatabaseRowDecoder<Value: Sendable>: Sendable {
    private let decodeValue: @Sendable (PTDatabaseRow) throws -> Value

    public init(_ decode: @escaping @Sendable (PTDatabaseRow) throws -> Value) {
        self.decodeValue = decode
    }

    public func decode(_ row: PTDatabaseRow) throws -> Value {
        try decodeValue(row)
    }
}

public protocol PTDatabaseBackend: Sendable {
    func execute(_ query: PTDatabaseQuery) async throws
    func query(_ query: PTDatabaseQuery) async throws -> [PTDatabaseRow]
}

public struct PTDatabaseMigration: Sendable, Equatable {
    public let fromVersion: Int
    public let toVersion: Int
    public let statements: [String]
    public let isDestructive: Bool

    public var version: Int { toVersion }

    public init(version: Int,
                statements: [String],
                isDestructive: Bool = false) {
        self.fromVersion = max(0, version - 1)
        self.toVersion = max(0, version)
        self.statements = statements
        self.isDestructive = isDestructive
    }

    public init(fromVersion: Int,
                toVersion: Int,
                statements: [String],
                isDestructive: Bool = false) {
        self.fromVersion = max(0, fromVersion)
        self.toVersion = max(0, toVersion)
        self.statements = statements
        self.isDestructive = isDestructive
    }
}

public struct PTDatabaseMigrationValidation: Sendable, Equatable {
    public let currentVersion: Int
    public let targetVersion: Int
    public let pendingVersions: [Int]

    public init(currentVersion: Int, targetVersion: Int, pendingVersions: [Int]) {
        self.currentVersion = max(0, currentVersion)
        self.targetVersion = max(0, targetVersion)
        self.pendingVersions = pendingVersions
    }
}

// English: Validate the migration chain independently from SQLite execution.
// Español: Valida la cadena de migraciones de forma independiente de la ejecución SQLite.
// 中文：将迁移链校验与 SQLite 执行解耦，便于测试缺失和重复迁移。
public enum PTDatabaseMigrationValidator {
    public static func validate(_ migrations: [PTDatabaseMigration],
                                currentVersion: Int) throws -> PTDatabaseMigrationValidation {
        let current = max(0, currentVersion)
        let ordered = migrations.sorted { lhs, rhs in
            lhs.toVersion == rhs.toVersion ? lhs.fromVersion < rhs.fromVersion : lhs.toVersion < rhs.toVersion
        }
        var seen = Set<Int>()
        for migration in ordered {
            guard migration.toVersion > migration.fromVersion else {
                throw PTDatabaseError.downgradeNotAllowed(current: current,
                                                          requested: migration.toVersion)
            }
            guard seen.insert(migration.toVersion).inserted else {
                throw PTDatabaseError.duplicateMigration(migration.toVersion)
            }
        }
        var expected = current
        var pending: [Int] = []
        for migration in ordered where migration.toVersion > current {
            guard migration.fromVersion == expected else {
                throw PTDatabaseError.migrationGap(expected: expected,
                                                   actual: migration.fromVersion)
            }
            expected = migration.toVersion
            pending.append(migration.toVersion)
        }
        return PTDatabaseMigrationValidation(currentVersion: current,
                                             targetVersion: expected,
                                             pendingVersions: pending)
    }
}

public enum PTDatabaseChange: Sendable, Equatable {
    case executed(sql: String)
    case migrated(toVersion: Int)
    case restored
}

public enum PTDatabaseError: Error, Sendable, Equatable {
    case invalidPath
    case invalidValue
    case openFailed(String)
    case prepareFailed(String)
    case bindFailed(String)
    case executeFailed(String)
    case queryFailed(String)
    case transactionFailed(String)
    case migrationFailed(Int, String)
    case migrationGap(expected: Int, actual: Int)
    case duplicateMigration(Int)
    case downgradeNotAllowed(current: Int, requested: Int)
    case backupFailed(String)
    case restoreFailed(String)
    case decodingFailed(String)
    case integrityCheckFailed(String)
    case closed
}
