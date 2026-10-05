// English: Actor-isolated SQLite3 database implementation with typed bindings and migrations.
// Español: Implementación SQLite3 aislada por actor con bindings tipados y migraciones.
// 中文：使用 actor 隔离、类型化绑定和迁移的 SQLite3 数据库实现。

import Foundation
import SQLite3
#if SWIFT_PACKAGE
import PToolsDatabaseCore
#endif

// English: This narrow wrapper owns one SQLite C handle and closes it exactly once.
// Español: Este wrapper estrecho posee un handle C de SQLite y lo cierra exactamente una vez.
// 中文：这个窄范围包装器独占一个 SQLite C handle，并保证只关闭一次。
private final class PTSQLiteHandle: @unchecked Sendable {
    let pointer: OpaquePointer
    init(pointer: OpaquePointer) { self.pointer = pointer }
    deinit { sqlite3_close(pointer) }
}

public actor PTDatabase {
    private static let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    public let fileURL: URL
    private var handle: PTSQLiteHandle?
    private var observers: [UUID: AsyncStream<PTDatabaseChange>.Continuation] = [:]
    private var observationObservers: [UUID: (table: String?, continuation: AsyncStream<PTDatabaseObservation>.Continuation)] = [:]

    public static func open(url: URL) async throws -> PTDatabase {
        try PTDatabase(fileURL: url)
    }

    public init(fileURL: URL? = nil) throws {
        let url = fileURL ?? URL(fileURLWithPath: ":memory:")
        self.fileURL = url
        self.handle = try Self.openHandle(for: url)
    }

    public func execute(_ query: PTDatabaseQuery) throws {
        let statement = try prepare(query.sql)
        defer { sqlite3_finalize(statement) }
        try bind(query.arguments, to: statement)
        let result = sqlite3_step(statement)
        guard result == SQLITE_DONE else { throw PTDatabaseError.executeFailed(message()) }
        publish(.executed(sql: query.sql), table: Self.tableName(in: query.sql))
    }

    public func execute(_ sql: String, arguments: [PTDatabaseValue] = []) throws {
        try execute(PTDatabaseQuery(sql, arguments: arguments))
    }

    @discardableResult
    public func insert(_ query: PTDatabaseQuery) throws -> Int64 {
        try execute(query)
        guard let handle else { throw PTDatabaseError.closed }
        return sqlite3_last_insert_rowid(handle.pointer)
    }

    public func query(_ query: PTDatabaseQuery) throws -> [PTDatabaseRow] {
        let statement = try prepare(query.sql)
        defer { sqlite3_finalize(statement) }
        try bind(query.arguments, to: statement)
        var rows: [PTDatabaseRow] = []
        while true {
            let result = sqlite3_step(statement)
            if result == SQLITE_DONE { break }
            guard result == SQLITE_ROW else { throw PTDatabaseError.queryFailed(message()) }
            rows.append(readRow(from: statement))
        }
        return rows
    }

    public func query(_ sql: String, arguments: [PTDatabaseValue] = []) throws -> [PTDatabaseRow] {
        try query(PTDatabaseQuery(sql, arguments: arguments))
    }

    public func queryDecoded<Value: Decodable & Sendable>(_ request: PTDatabaseQuery,
                                                          as type: Value.Type) throws -> [Value] {
        try query(request).map { row in
            let object = row.values.reduce(into: [String: Any]()) { result, item in
                result[item.key] = jsonValue(item.value)
            }
            guard JSONSerialization.isValidJSONObject(object) else {
                throw PTDatabaseError.decodingFailed("Invalid row")
            }
            do {
                return try JSONDecoder().decode(type, from: JSONSerialization.data(withJSONObject: object))
            } catch {
                throw PTDatabaseError.decodingFailed(String(describing: error))
            }
        }
    }

    public func queryModels<Value: Decodable & Sendable>(_ type: Value.Type,
                                                         sql: String,
                                                         arguments: [PTDatabaseValue] = []) throws -> [Value] {
        try queryDecoded(PTDatabaseQuery(sql, arguments: arguments), as: type)
    }

    public func withTransaction<T: Sendable>(_ queries: [PTDatabaseQuery], returning value: @autoclosure () -> T) throws -> T {
        try execute(PTDatabaseQuery("BEGIN IMMEDIATE TRANSACTION"))
        do {
            for query in queries { try execute(query) }
            try execute(PTDatabaseQuery("COMMIT"))
            return value()
        } catch {
            try? execute(PTDatabaseQuery("ROLLBACK"))
            throw PTDatabaseError.transactionFailed(String(describing: error))
        }
    }

    public func transaction<T: Sendable>(mode: PTDatabaseTransactionMode = .immediate,
                                         _ operation: @Sendable (PTDatabase) async throws -> T) async throws -> T {
        let begin = "BEGIN \(mode.rawValue.uppercased()) TRANSACTION"
        try execute(PTDatabaseQuery(begin))
        do {
            let result = try await operation(self)
            try execute(PTDatabaseQuery("COMMIT"))
            return result
        } catch {
            try? execute(PTDatabaseQuery("ROLLBACK"))
            throw PTDatabaseError.transactionFailed(String(describing: error))
        }
    }

    public func migrate(_ migrations: [PTDatabaseMigration]) throws {
        let current = try schemaVersion()
        for migration in migrations.sorted(by: { $0.version < $1.version }) where migration.version > current {
            do {
                try execute(PTDatabaseQuery("BEGIN IMMEDIATE TRANSACTION"))
                for statement in migration.statements { try execute(PTDatabaseQuery(statement)) }
                try execute(PTDatabaseQuery("PRAGMA user_version = \(migration.version)"))
                try execute(PTDatabaseQuery("COMMIT"))
                publish(.migrated(toVersion: migration.version), table: nil)
            } catch {
                try? execute(PTDatabaseQuery("ROLLBACK"))
                throw PTDatabaseError.migrationFailed(migration.version, String(describing: error))
            }
        }
    }

    public func migrate(_ plan: PTDatabaseMigrationPlan) throws {
        if plan.destructive == false, plan.migrations.contains(where: { $0.statements.contains { $0.localizedCaseInsensitiveContains("DROP TABLE") } }) {
            throw PTDatabaseError.migrationFailed(0, "Destructive migration requires explicit opt-in")
        }
        try migrate(plan.migrations)
    }

    public func schemaVersion() throws -> Int {
        guard let row = try query(PTDatabaseQuery("PRAGMA user_version")).first,
              case .integer(let value) = row.values.values.first else { return 0 }
        return Int(value)
    }

    public func changes() -> AsyncStream<PTDatabaseChange> {
        let id = UUID()
        return AsyncStream { continuation in
            observers[id] = continuation
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { await self?.removeObserver(id) }
            }
        }
    }

    public func observe(table: String? = nil) -> AsyncStream<PTDatabaseObservation> {
        let id = UUID()
        return AsyncStream { continuation in
            observationObservers[id] = (table, continuation)
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { await self?.removeObservation(id) }
            }
        }
    }

    @discardableResult
    public func backup(to destination: URL) throws -> PTDatabaseBackupDescriptor {
        guard let handle else { throw PTDatabaseError.closed }
        let source = handle.pointer
        var target: OpaquePointer?
        guard sqlite3_open_v2(destination.path, &target, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil) == SQLITE_OK,
              let target else {
            throw PTDatabaseError.backupFailed(message())
        }
        defer { sqlite3_close(target) }
        guard let backup = sqlite3_backup_init(target, "main", source, "main") else {
            throw PTDatabaseError.backupFailed(String(cString: sqlite3_errmsg(target)))
        }
        let result = sqlite3_backup_step(backup, -1)
        let finish = sqlite3_backup_finish(backup)
        guard result == SQLITE_DONE, finish == SQLITE_OK else {
            throw PTDatabaseError.backupFailed(String(cString: sqlite3_errmsg(target)))
        }
        let byteCount = (try? FileManager.default.attributesOfItem(atPath: destination.path)[.size] as? NSNumber)?.int64Value ?? 0
        return PTDatabaseBackupDescriptor(url: destination, byteCount: byteCount)
    }

    public func restore(from source: URL, policy: PTDatabaseRestorePolicy = .replaceExisting) throws {
        guard fileURL.path != ":memory:", FileManager.default.fileExists(atPath: source.path) else {
            throw PTDatabaseError.restoreFailed("Source database is unavailable")
        }
        if policy == .failIfExisting, FileManager.default.fileExists(atPath: fileURL.path) {
            throw PTDatabaseError.restoreFailed("Destination database already exists")
        }
        close()
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            try FileManager.default.copyItem(at: source, to: fileURL)
            handle = try Self.openHandle(for: fileURL)
            publish(.restored, table: nil)
        } catch {
            throw PTDatabaseError.restoreFailed(String(describing: error))
        }
    }

    private static func openHandle(for url: URL) throws -> PTSQLiteHandle {
        if url.path != ":memory:" {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
        }
        var candidate: OpaquePointer?
        let result = sqlite3_open_v2(url.path, &candidate, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil)
        guard result == SQLITE_OK, let candidate else {
            let error = candidate.map { String(cString: sqlite3_errmsg($0)) } ?? "SQLite open failed"
            if let candidate { sqlite3_close(candidate) }
            throw PTDatabaseError.openFailed(error)
        }
        sqlite3_busy_timeout(candidate, 5_000)
        return PTSQLiteHandle(pointer: candidate)
    }

    private func close() {
        handle = nil
    }

    private func prepare(_ sql: String) throws -> OpaquePointer {
        guard let handle else { throw PTDatabaseError.closed }
        var statement: OpaquePointer?
        let result = sqlite3_prepare_v2(handle.pointer, sql, -1, &statement, nil)
        guard result == SQLITE_OK, let statement else { throw PTDatabaseError.prepareFailed(message()) }
        return statement
    }

    private func bind(_ values: [PTDatabaseValue], to statement: OpaquePointer) throws {
        for (offset, value) in values.enumerated() {
            let index = Int32(offset + 1)
            let result: Int32
            switch value {
            case .null: result = sqlite3_bind_null(statement, index)
            case .integer(let value): result = sqlite3_bind_int64(statement, index, value)
            case .real(let value): result = sqlite3_bind_double(statement, index, value)
            case .boolean(let value): result = sqlite3_bind_int64(statement, index, value ? 1 : 0)
            case .date(let value): result = sqlite3_bind_double(statement, index, value.timeIntervalSince1970)
            case .decimal(let value):
                result = value.withCString { pointer in
                    sqlite3_bind_text(statement, index, pointer, -1, Self.sqliteTransient)
                }
            case .text(let value):
                result = value.withCString { pointer in
                    sqlite3_bind_text(statement, index, pointer, -1, Self.sqliteTransient)
                }
            case .blob(let value):
                result = value.withUnsafeBytes { bytes in
                    sqlite3_bind_blob(statement, index, bytes.baseAddress, Int32(value.count), Self.sqliteTransient)
                }
            }
            guard result == SQLITE_OK else { throw PTDatabaseError.bindFailed(message()) }
        }
    }

    private func readRow(from statement: OpaquePointer) -> PTDatabaseRow {
        let count = sqlite3_column_count(statement)
        var values: [String: PTDatabaseValue] = [:]
        for index in 0..<count {
            guard let namePointer = sqlite3_column_name(statement, index) else { continue }
            let name = String(cString: namePointer)
            values[name] = readValue(from: statement, index: index)
        }
        return PTDatabaseRow(values: values)
    }

    private func readValue(from statement: OpaquePointer, index: Int32) -> PTDatabaseValue {
        switch sqlite3_column_type(statement, index) {
        case SQLITE_INTEGER: return .integer(sqlite3_column_int64(statement, index))
        case SQLITE_FLOAT: return .real(sqlite3_column_double(statement, index))
        case SQLITE_TEXT:
            guard let pointer = sqlite3_column_text(statement, index) else { return .null }
            return .text(String(cString: pointer))
        case SQLITE_BLOB:
            guard let pointer = sqlite3_column_blob(statement, index) else { return .blob(Data()) }
            return .blob(Data(bytes: pointer, count: Int(sqlite3_column_bytes(statement, index))))
        default: return .null
        }
    }

    private func jsonValue(_ value: PTDatabaseValue) -> Any {
        switch value {
        case .null: return NSNull()
        case .integer(let value): return value
        case .real(let value): return value
        case .text(let value): return value
        case .blob(let value): return value.base64EncodedString()
        case .boolean(let value): return value
        case .date(let value): return value.timeIntervalSince1970
        case .decimal(let value): return value
        }
    }

    private func message() -> String {
        guard let handle else { return "SQLite database is closed" }
        return String(cString: sqlite3_errmsg(handle.pointer))
    }

    private func publish(_ change: PTDatabaseChange, table: String?) {
        observers.values.forEach { $0.yield(change) }
        let observation = PTDatabaseObservation(table: table, change: change)
        observationObservers.values.forEach { observer in
            guard observer.table == nil || observer.table == table else { return }
            observer.continuation.yield(observation)
        }
    }

    private func removeObserver(_ id: UUID) { observers[id] = nil }
    private func removeObservation(_ id: UUID) { observationObservers[id] = nil }

    private static func tableName(in sql: String) -> String? {
        let tokens = sql.split { $0 == " " || $0 == "\n" || $0 == "\t" || $0 == "(" }
        guard let operation = tokens.first?.uppercased() else { return nil }
        let candidates: [String]
        switch operation {
        case "INSERT": candidates = tokens.count > 2 ? [String(tokens[2])] : []
        case "UPDATE": candidates = tokens.count > 1 ? [String(tokens[1])] : []
        case "DELETE": candidates = tokens.count > 2 ? [String(tokens[2])] : []
        case "CREATE": candidates = tokens.count > 2 ? [String(tokens[2])] : []
        default: candidates = []
        }
        return candidates.first?.trimmingCharacters(in: CharacterSet(charactersIn: "`\";"))
    }
}
