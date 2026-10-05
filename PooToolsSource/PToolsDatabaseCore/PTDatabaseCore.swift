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
    public init(migrations: [PTDatabaseMigration], destructive: Bool = false) {
        self.migrations = migrations
        self.destructive = destructive
    }
}

public struct PTDatabaseBackupDescriptor: Sendable, Equatable, Codable {
    public let url: URL
    public let createdAt: Date
    public let byteCount: Int64
    public init(url: URL, createdAt: Date = .now, byteCount: Int64 = 0) {
        self.url = url
        self.createdAt = createdAt
        self.byteCount = max(0, byteCount)
    }
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

public protocol PTDatabaseBackend: Sendable {
    func execute(_ query: PTDatabaseQuery) async throws
    func query(_ query: PTDatabaseQuery) async throws -> [PTDatabaseRow]
}

public struct PTDatabaseMigration: Sendable, Equatable {
    public let version: Int
    public let statements: [String]

    public init(version: Int, statements: [String]) {
        self.version = version
        self.statements = statements
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
    case backupFailed(String)
    case restoreFailed(String)
    case decodingFailed(String)
    case closed
}
