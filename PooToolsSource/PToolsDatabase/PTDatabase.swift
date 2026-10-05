// English: Actor-isolated SQLite3 database implementation with typed bindings and migrations.
// Español: Implementación SQLite3 aislada por actor con bindings tipados y migraciones.
// 中文：使用 actor 隔离、类型化绑定和迁移的 SQLite3 数据库实现。

import Foundation
import SQLite3
#if SWIFT_PACKAGE
import PToolsDatabaseCore
#endif

public protocol PTDatabaseMigrationStep: Sendable {
    var fromVersion: Int { get }
    var toVersion: Int { get }
    var isDestructive: Bool { get }
    func migrate(using database: PTDatabase) async throws
}

public extension PTDatabaseMigrationStep {
    var isDestructive: Bool { false }
}

public struct PTDatabaseMigrationResult: Sendable, Equatable {
    public let appliedVersions: [Int]
    public let finalSchemaVersion: Int
    public let backup: PTDatabaseBackupDescriptor?

    public init(appliedVersions: [Int],
                finalSchemaVersion: Int,
                backup: PTDatabaseBackupDescriptor? = nil) {
        self.appliedVersions = appliedVersions
        self.finalSchemaVersion = finalSchemaVersion
        self.backup = backup
    }
}

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
    public let configuration: PTDatabaseRuntimeConfiguration
    private var handle: PTSQLiteHandle?
    private var observers: [UUID: AsyncStream<PTDatabaseChange>.Continuation] = [:]
    private var observationObservers: [UUID: (table: String?, continuation: AsyncStream<PTDatabaseObservation>.Continuation)] = [:]

    public static func open(url: URL,
                            configuration: PTDatabaseRuntimeConfiguration = .init()) async throws -> PTDatabase {
        try PTDatabase(fileURL: url, configuration: configuration)
    }

    public init(fileURL: URL? = nil,
                configuration: PTDatabaseRuntimeConfiguration = .init()) throws {
        let url = fileURL ?? URL(fileURLWithPath: ":memory:")
        self.fileURL = url
        self.configuration = configuration
        self.handle = try Self.openHandle(for: url, configuration: configuration)
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

    // English: Fetch one bounded page and one look-ahead row without loading the full result set.
    // Español: Obtiene una página limitada y una fila de adelanto sin cargar todo el resultado.
    // 中文：使用一条预读记录获取有界分页，避免一次性加载完整结果集。
    public func page(_ request: PTDatabaseQuery,
                    offset: Int = 0,
                    limit: Int = 50) throws -> PTDatabasePage<PTDatabaseRow> {
        let safeOffset = max(0, offset)
        let safeLimit = min(max(1, limit), 1_000)
        let baseSQL = request.sql.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ";")))
        let paged = PTDatabaseQuery("SELECT * FROM (\(baseSQL)) AS ptools_page LIMIT ? OFFSET ?",
                                    arguments: request.arguments + [.integer(Int64(safeLimit + 1)), .integer(Int64(safeOffset))])
        var values = try query(paged)
        let hasMore = values.count > safeLimit
        if hasMore { values.removeLast() }
        return PTDatabasePage(values: values, offset: safeOffset, limit: safeLimit, hasMore: hasMore)
    }

    public func pageDecoded<Value: Decodable & Sendable>(_ request: PTDatabaseQuery,
                                                         as type: Value.Type,
                                                         offset: Int = 0,
                                                         limit: Int = 50) throws -> PTDatabasePage<Value> {
        let rows = try page(request, offset: offset, limit: limit)
        let values = try rows.values.map { row -> Value in
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
        return PTDatabasePage(values: values, offset: rows.offset, limit: rows.limit, hasMore: rows.hasMore)
    }

    public func page<Value: Sendable>(_ request: PTDatabaseQuery,
                                      decoder: PTDatabaseRowDecoder<Value>,
                                      offset: Int = 0,
                                      limit: Int = 50) throws -> PTDatabasePage<Value> {
        let rows = try page(request, offset: offset, limit: limit)
        return PTDatabasePage(values: try rows.values.map(decoder.decode),
                              offset: rows.offset,
                              limit: rows.limit,
                              hasMore: rows.hasMore)
    }

    public func pageModels<Model: Decodable & Sendable>(_ request: PTDatabaseQuery,
                                                        as type: Model.Type,
                                                        offset: Int = 0,
                                                        limit: Int = 50) throws -> PTDatabasePage<Model> {
        try pageDecoded(request, as: type, offset: offset, limit: limit)
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
        try migrate(migrations, allowDestructive: false)
    }

    private func migrate(_ migrations: [PTDatabaseMigration], allowDestructive: Bool) throws {
        let current = try schemaVersion()
        guard allowDestructive || migrations.allSatisfy({ !$0.isDestructive }) else {
            throw PTDatabaseError.migrationFailed(0, "Destructive migration requires an explicit migration plan")
        }
        let pending = try Self.validate(migrations: migrations, currentVersion: current)
        for migration in pending {
            let migrationStartVersion = try schemaVersion()
            do {
                try execute(PTDatabaseQuery("BEGIN IMMEDIATE TRANSACTION"))
                for statement in migration.statements { try execute(PTDatabaseQuery(statement)) }
                try execute(PTDatabaseQuery("PRAGMA user_version = \(migration.version)"))
                try execute(PTDatabaseQuery("COMMIT"))
                publish(.migrated(toVersion: migration.version), table: nil)
            } catch {
                try? execute(PTDatabaseQuery("ROLLBACK"))
                // English: Verify that a failed migration did not advance the schema version.
                // Español: Verifica que una migración fallida no haya avanzado la versión del esquema.
                // 中文：确认失败迁移没有推进 schema version，保护后续重试。
                if (try? schemaVersion()) != migrationStartVersion {
                    throw PTDatabaseError.migrationFailed(migration.version,
                                                         "Migration failure changed schema version")
                }
                throw PTDatabaseError.migrationFailed(migration.version, String(describing: error))
            }
        }
    }

    public func migrate(_ plan: PTDatabaseMigrationPlan) throws {
        if plan.destructive == false, plan.migrations.contains(where: \.isDestructive) {
            throw PTDatabaseError.migrationFailed(0, "Destructive migration requires explicit opt-in")
        }
        if case .beforeMigration(let destination) = plan.backupPolicy {
            _ = try backup(to: destination)
        }
        try migrate(plan.migrations, allowDestructive: plan.destructive)
    }

    public func migrate(steps: [any PTDatabaseMigrationStep],
                        destructive: Bool = false,
                        backupTo backupURL: URL? = nil) async throws -> PTDatabaseMigrationResult {
        let descriptors = steps.map {
            PTDatabaseMigration(fromVersion: $0.fromVersion,
                                toVersion: $0.toVersion,
                                statements: [],
                                isDestructive: $0.isDestructive)
        }
        let current = try schemaVersion()
        if !destructive, descriptors.contains(where: \.isDestructive) {
            throw PTDatabaseError.migrationFailed(0, "Destructive migration requires explicit opt-in")
        }
        let validation = try PTDatabaseMigrationValidator.validate(descriptors, currentVersion: current)
        let backup = try backupURL.map { try backup(to: $0) }
        let byVersion = steps.reduce(into: [Int: any PTDatabaseMigrationStep]()) { result, step in
            result[step.toVersion] = step
        }
        var applied: [Int] = []
        for version in validation.pendingVersions {
            guard let step = byVersion[version] else {
                throw PTDatabaseError.migrationFailed(version, "Migration step is missing")
            }
            let startVersion = try schemaVersion()
            do {
                try await transaction { database in
                    try await step.migrate(using: database)
                    try await database.execute("PRAGMA user_version = \(version)")
                }
                applied.append(version)
                publish(.migrated(toVersion: version), table: nil)
            } catch {
                if (try? schemaVersion()) != startVersion {
                    throw PTDatabaseError.migrationFailed(version, "Migration failure changed schema version")
                }
                throw PTDatabaseError.migrationFailed(version, String(describing: error))
            }
        }
        return PTDatabaseMigrationResult(appliedVersions: applied,
                                         finalSchemaVersion: try schemaVersion(),
                                         backup: backup)
    }

    public func validateMigrations(_ migrations: [PTDatabaseMigration]) throws {
        _ = try Self.validate(migrations: migrations, currentVersion: schemaVersion())
    }

    public func schemaVersion() throws -> Int {
        guard let row = try query(PTDatabaseQuery("PRAGMA user_version")).first,
              case .integer(let value) = row.values.values.first else { return 0 }
        return Int(value)
    }

    public func runtimeSnapshot() throws -> PTDatabaseRuntimeSnapshot {
        PTDatabaseRuntimeSnapshot(sqliteVersion: try scalarText("SELECT sqlite_version()"),
                                  journalMode: try scalarText("PRAGMA journal_mode"),
                                  synchronousMode: try scalarText("PRAGMA synchronous"),
                                  foreignKeysEnabled: try scalarInteger("PRAGMA foreign_keys") != 0,
                                  schemaVersion: try schemaVersion())
    }

    public func close() {
        handle = nil
    }

    public func reopen() throws {
        guard handle == nil else { return }
        handle = try Self.openHandle(for: fileURL, configuration: configuration)
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

    // English: SQLite's integrity check is part of the public restore and backup contract.
    // Español: La comprobación de integridad de SQLite forma parte del contrato público de backup y restore.
    // 中文：SQLite 完整性检查是公开备份与恢复契约的一部分。
    public func integrityCheck() throws -> PTDatabaseIntegrityReport {
        let rows = try query(PTDatabaseQuery("PRAGMA integrity_check"))
        let result: String
        if let first = rows.first, case .text(let value) = first.values.values.first {
            result = value
        } else {
            result = ""
        }
        return PTDatabaseIntegrityReport(passed: result.caseInsensitiveCompare("ok") == .orderedSame,
                                         result: result,
                                         schemaVersion: try schemaVersion())
    }

    @discardableResult
    public func backup(to destination: URL) throws -> PTDatabaseBackupDescriptor {
        guard let handle else { throw PTDatabaseError.closed }
        if configuration.checkpointPolicy == .beforeBackup {
            try execute("PRAGMA wal_checkpoint(FULL)")
        }
        let parent = destination.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        let temporary = parent.appendingPathComponent(".\(destination.lastPathComponent).\(UUID().uuidString).tmp")
        let source = handle.pointer
        var target: OpaquePointer?
        guard sqlite3_open_v2(temporary.path, &target, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK,
              let target else {
            throw PTDatabaseError.backupFailed(message())
        }
        defer {
            sqlite3_close(target)
            try? FileManager.default.removeItem(at: temporary)
        }
        guard let backup = sqlite3_backup_init(target, "main", source, "main") else {
            throw PTDatabaseError.backupFailed(String(cString: sqlite3_errmsg(target)))
        }
        let result = sqlite3_backup_step(backup, -1)
        let finish = sqlite3_backup_finish(backup)
        guard result == SQLITE_DONE, finish == SQLITE_OK else {
            throw PTDatabaseError.backupFailed(String(cString: sqlite3_errmsg(target)))
        }
        guard let report = try? Self.integrityReport(for: temporary), report.passed else {
            throw PTDatabaseError.backupFailed("Backup integrity check failed")
        }
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: temporary, to: destination)
        let byteCount = (try? FileManager.default.attributesOfItem(atPath: destination.path)[.size] as? NSNumber)?.int64Value ?? 0
        return PTDatabaseBackupDescriptor(url: destination,
                                          byteCount: byteCount,
                                          schemaVersion: report.schemaVersion,
                                          integrityPassed: report.passed)
    }

    public func restore(from source: URL, policy: PTDatabaseRestorePolicy = .replaceExisting) throws {
        guard fileURL.path != ":memory:", FileManager.default.fileExists(atPath: source.path) else {
            throw PTDatabaseError.restoreFailed("Source database is unavailable")
        }
        if policy == .failIfExisting, FileManager.default.fileExists(atPath: fileURL.path) {
            throw PTDatabaseError.restoreFailed("Destination database already exists")
        }
        let parent = fileURL.deletingLastPathComponent()
        let staged = parent.appendingPathComponent(".\(fileURL.lastPathComponent).\(UUID().uuidString).restore")
        do {
            try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: source, to: staged)
            let report = try Self.integrityReport(for: staged)
            guard report.passed else { throw PTDatabaseError.integrityCheckFailed(report.result) }
            close()
            let replacement = fileURL.appendingPathExtension("previous")
            if FileManager.default.fileExists(atPath: replacement.path) { try? FileManager.default.removeItem(at: replacement) }
            if FileManager.default.fileExists(atPath: fileURL.path) { try FileManager.default.moveItem(at: fileURL, to: replacement) }
            do {
                try FileManager.default.moveItem(at: staged, to: fileURL)
            } catch {
                if FileManager.default.fileExists(atPath: replacement.path) {
                    try? FileManager.default.moveItem(at: replacement, to: fileURL)
                }
                throw error
            }
            do {
                handle = try Self.openHandle(for: fileURL, configuration: configuration)
            } catch {
                close()
                try? FileManager.default.removeItem(at: fileURL)
                if FileManager.default.fileExists(atPath: replacement.path) {
                    try? FileManager.default.moveItem(at: replacement, to: fileURL)
                }
                handle = try? Self.openHandle(for: fileURL, configuration: configuration)
                throw error
            }
            try? FileManager.default.removeItem(at: replacement)
            publish(.restored, table: nil)
        } catch {
            try? FileManager.default.removeItem(at: staged)
            throw PTDatabaseError.restoreFailed(String(describing: error))
        }
    }

    private static func openHandle(for url: URL,
                                   configuration: PTDatabaseRuntimeConfiguration = .init()) throws -> PTSQLiteHandle {
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
        sqlite3_busy_timeout(candidate, configuration.busyTimeoutMilliseconds)
        do {
            try apply(configuration, to: candidate)
        } catch {
            sqlite3_close(candidate)
            throw error
        }
        return PTSQLiteHandle(pointer: candidate)
    }

    private static func apply(_ configuration: PTDatabaseRuntimeConfiguration,
                              to pointer: OpaquePointer) throws {
        let foreignKeys = configuration.foreignKeysEnabled ? "ON" : "OFF"
        let statements = [
            "PRAGMA foreign_keys = \(foreignKeys)",
            "PRAGMA journal_mode = \(configuration.journalMode.rawValue)",
            "PRAGMA synchronous = \(configuration.synchronousMode.rawValue)"
        ]
        for sql in statements {
            guard sqlite3_exec(pointer, sql, nil, nil, nil) == SQLITE_OK else {
                throw PTDatabaseError.openFailed(String(cString: sqlite3_errmsg(pointer)))
            }
        }
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

    private func scalarText(_ sql: String) throws -> String {
        guard let row = try query(sql).first,
              let value = row.values.values.first else { return "" }
        switch value {
        case .text(let value): return value
        case .integer(let value): return String(value)
        case .real(let value): return String(value)
        default: return ""
        }
    }

    private func scalarInteger(_ sql: String) throws -> Int64 {
        guard let row = try query(sql).first,
              let value = row.values.values.first else { return 0 }
        switch value {
        case .integer(let value): return value
        case .real(let value): return Int64(value)
        case .text(let value): return Int64(value) ?? 0
        default: return 0
        }
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

    private static func validate(migrations: [PTDatabaseMigration], currentVersion: Int) throws -> [PTDatabaseMigration] {
        _ = try PTDatabaseMigrationValidator.validate(migrations, currentVersion: currentVersion)
        return migrations.sorted { $0.toVersion < $1.toVersion }.filter { $0.toVersion > currentVersion }
    }

    private static func integrityReport(for url: URL) throws -> PTDatabaseIntegrityReport {
        var pointer: OpaquePointer?
        guard sqlite3_open_v2(url.path, &pointer, SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK,
              let pointer else {
            throw PTDatabaseError.openFailed("Unable to open database for integrity check")
        }
        defer { sqlite3_close(pointer) }
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(pointer, "PRAGMA integrity_check", -1, &statement, nil) == SQLITE_OK,
              let statement else {
            throw PTDatabaseError.integrityCheckFailed("Unable to prepare integrity check")
        }
        defer { sqlite3_finalize(statement) }
        guard sqlite3_step(statement) == SQLITE_ROW,
              let value = sqlite3_column_text(statement, 0) else {
            throw PTDatabaseError.integrityCheckFailed("No integrity result")
        }
        let result = String(cString: value)
        var versionStatement: OpaquePointer?
        var version = 0
        if sqlite3_prepare_v2(pointer, "PRAGMA user_version", -1, &versionStatement, nil) == SQLITE_OK,
           let versionStatement {
            defer { sqlite3_finalize(versionStatement) }
            if sqlite3_step(versionStatement) == SQLITE_ROW { version = Int(sqlite3_column_int64(versionStatement, 0)) }
        }
        return PTDatabaseIntegrityReport(passed: result.caseInsensitiveCompare("ok") == .orderedSame,
                                         result: result,
                                         schemaVersion: version)
    }
}
