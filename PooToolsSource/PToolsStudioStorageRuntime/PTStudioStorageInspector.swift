import Foundation
import SQLite3
#if SWIFT_PACKAGE
import PToolsStudioProtocolCore
#endif

/// Sandboxed metadata service. Host must explicitly provide allowed roots, keys and databases.
/// Read-only by default; arbitrary paths and raw SQL are never accepted from the Mac.
@MainActor
public final class PTStudioStorageInspector {
    public var permitsDefaultWrites = false
    public let allowedRoot: URL?
    public let allowedDefaultKeys: Set<String>
    public let allowedDatabaseURLs: [URL]
    private let defaults: UserDefaults

    public init(allowedRoot: URL? = nil, allowedDefaultKeys: Set<String> = [],
                allowedDatabaseURLs: [URL] = [], defaults: UserDefaults = .standard) {
        self.allowedRoot = allowedRoot?.standardizedFileURL.resolvingSymlinksInPath()
        self.allowedDefaultKeys = allowedDefaultKeys
        self.allowedDatabaseURLs = allowedDatabaseURLs
        self.defaults = defaults
    }

    public func handle(_ command: PTStudioDiagnosticCommand) -> PTStudioDiagnosticReply {
        guard command.schemaVersion == PTStudioDiagnosticCommand.schemaVersion else {
            return failure(command, "Invalid diagnostic schema")
        }
        switch (command.domain, command.operation) {
        case (.storage, "list"):
            return listFiles(command)
        case (.defaults, "list"):
            return listDefaults(command)
        case (.defaults, "set"):
            return setDefault(command)
        case (.database, "schema"):
            return databaseSchema(command)
        default:
            return failure(command, "Storage operation unavailable")
        }
    }

    private func failure(_ command: PTStudioDiagnosticCommand, _ message: String) -> PTStudioDiagnosticReply {
        .init(id: command.id, sessionID: command.sessionID, success: false, message: message)
    }

    private func listFiles(_ command: PTStudioDiagnosticCommand) -> PTStudioDiagnosticReply {
        guard let root = allowedRoot else { return failure(command, "Host has not granted a sandbox root") }
        let relative = command.arguments["path"] ?? ""
        guard relative.count < 512, !relative.hasPrefix("/"),
              relative.split(separator: "/").allSatisfy({ $0 != ".." && $0 != "." }) else {
            return failure(command, "Invalid relative path")
        }
        let target = root.appendingPathComponent(relative).standardizedFileURL.resolvingSymlinksInPath()
        guard target.path == root.path || target.path.hasPrefix(root.path + "/") else {
            return failure(command, "Path outside permitted root")
        }
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: target, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .isSymbolicLinkKey], options: [])
            let nodes = files.prefix(256).compactMap { url -> PTStudioDiagnosticEntry? in
                let resolved = url.standardizedFileURL.resolvingSymlinksInPath()
                guard resolved.path.hasPrefix(root.path + "/") else { return nil }
                let resource = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .isSymbolicLinkKey])
                guard resource?.isSymbolicLink != true else { return nil }
                let child = relative.isEmpty ? url.lastPathComponent : relative + "/" + url.lastPathComponent
                return .init(id: child, kind: resource?.isDirectory == true ? "folder" : "file",
                             name: url.lastPathComponent, attributes: [
                                "size": String(resource?.fileSize ?? 0),
                                "relativePath": child
                             ])
            }
            return .init(id: command.id, sessionID: command.sessionID, success: true, entries: nodes)
        } catch {
            return failure(command, "Directory unavailable")
        }
    }

    private func listDefaults(_ command: PTStudioDiagnosticCommand) -> PTStudioDiagnosticReply {
        let entries = allowedDefaultKeys.sorted().prefix(256).compactMap { key -> PTStudioDiagnosticEntry? in
            guard let value = defaults.object(forKey: key) else { return nil }
            guard value is String || value is NSNumber else { return nil }
            return .init(id: key, kind: "default", name: key,
                         attributes: ["value": String(describing: value), "type": String(describing: type(of: value))])
        }
        return .init(id: command.id, sessionID: command.sessionID, success: true, entries: entries)
    }

    private func setDefault(_ command: PTStudioDiagnosticCommand) -> PTStudioDiagnosticReply {
        guard permitsDefaultWrites,
              let key = command.targetID, allowedDefaultKeys.contains(key),
              let kind = command.arguments["type"], let value = command.arguments["value"] else {
            return failure(command, "Default write not authorized")
        }
        guard defaults.object(forKey: key) != nil else { return failure(command, "Default key does not exist") }
        switch kind {
        case "string": guard value.count <= 4096 else { return failure(command, "Value too large") }
            defaults.set(value, forKey: key)
        case "bool": guard value == "true" || value == "false" else { return failure(command, "Invalid Bool") }
            defaults.set(value == "true", forKey: key)
        case "integer": guard let v = Int(value) else { return failure(command, "Invalid integer") }
            defaults.set(v, forKey: key)
        case "double": guard let v = Double(value), v.isFinite else { return failure(command, "Invalid number") }
            defaults.set(v, forKey: key)
        default:
            return failure(command, "Unsupported value type")
        }
        return .init(id: command.id, sessionID: command.sessionID, success: true)
    }

    private func databaseSchema(_ command: PTStudioDiagnosticCommand) -> PTStudioDiagnosticReply {
        guard let raw = command.arguments["index"], let index = Int(raw),
              allowedDatabaseURLs.indices.contains(index) else {
            return failure(command, "Database must be selected from host allowlist")
        }
        let url = allowedDatabaseURLs[index].standardizedFileURL.resolvingSymlinksInPath()
        var database: OpaquePointer?
        guard sqlite3_open_v2(url.path, &database, SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX, nil) == SQLITE_OK,
              database != nil else {
            if database != nil { sqlite3_close(database) }
            return failure(command, "Database cannot be opened read-only")
        }
        defer { sqlite3_close(database) }
        var statement: OpaquePointer?
        let query = "SELECT name, type FROM sqlite_master WHERE type IN ('table','view') AND name NOT LIKE 'sqlite_%' ORDER BY name LIMIT 256"
        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK else {
            return failure(command, "Database schema inspection failed")
        }
        defer { sqlite3_finalize(statement) }
        var entries: [PTStudioDiagnosticEntry] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let name = sqlite3_column_text(statement, 0),
                  let kind = sqlite3_column_text(statement, 1) else { continue }
            let tableName = String(cString: name)
            entries.append(.init(id: tableName, kind: String(cString: kind), name: tableName))
        }
        return .init(id: command.id, sessionID: command.sessionID, success: true, entries: entries)
    }
}
