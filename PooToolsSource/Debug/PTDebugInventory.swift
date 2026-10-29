import Foundation

/// Shared, Foundation-only Debug inventory values. Local file UIs and Studio
/// consume one metadata policy rather than duplicating directory enumeration.
public struct PTDebugInventoryItem: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let source: String
    public let kind: String
    public let byteCount: Int
    public let isDirectory: Bool
}

/// Read-only bounded file metadata inventory. No file contents or full paths
/// are exposed over Studio. The allowlist contains only app sandbox locations.
public enum PTDebugFileInventory {
    public static func list(databasesOnly: Bool = false, maximum: Int = 500) -> [PTDebugInventoryItem] {
        let manager = FileManager.default
        let roots: [(name: String, directory: FileManager.SearchPathDirectory)] = [
            ("Documents", .documentDirectory),
            ("Caches", .cachesDirectory),
            ("Application Support", .applicationSupportDirectory)
        ]
        var results: [PTDebugInventoryItem] = []
        let limit = max(1, min(maximum, 500))
        for root in roots {
            guard let url = manager.urls(for: root.directory, in: .userDomainMask).first else { continue }
            let files = (try? manager.contentsOfDirectory(
                at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
                options: [.skipsHiddenFiles])) ?? []
            for file in files {
                if results.count >= limit { return results }
                let ext = file.pathExtension.lowercased()
                if databasesOnly && !["db", "sqlite", "sqlite3"].contains(ext) { continue }
                let metadata = try? file.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                // Never send full sandbox paths, stable file URLs, or actual contents.
                results.append(PTDebugInventoryItem(
                    id: root.name + "/" + String(results.count),
                    name: file.lastPathComponent, source: root.name,
                    kind: databasesOnly ? "database" : "file",
                    byteCount: metadata?.fileSize ?? 0,
                    isDirectory: metadata?.isDirectory ?? false))
            }
        }
        return results
    }
}

/// Inventory is metadata-only. A secret key is not returned even as a label.
public struct PTDebugDefaultMetadata: Sendable, Equatable {
    public let key: String
    public let type: String
}

public enum PTDebugDefaultsInventory {
    private static let withheld = [
        "token", "secret", "password", "cookie", "auth", "key",
        "credential", "email", "phone", "address", "session"
    ]
    public static func list(maximum: Int = 400) -> [PTDebugDefaultMetadata] {
        let dictionary = UserDefaults.standard.dictionaryRepresentation()
        return Array(dictionary.keys.sorted().filter { key in
            !withheld.contains(where: { key.lowercased().contains($0) })
        }.prefix(max(1, min(maximum, 400)))).map { key in
            PTDebugDefaultMetadata(key: key, type: dictionary[key].map {
                String(describing: Swift.type(of: $0))
            } ?? "Unknown")
        }
    }
}
