import Foundation

/// Reusable, UIKit-free metadata source for local and remote Debug presentations.
/// It does not return file contents, full URLs, key values, or sandbox root paths.
public struct PTDebugInventoryRecord: Sendable, Equatable, Codable {
    public let identity: String
    public let name: String
    public let area: String
    public let kind: String
    public let bytes: Int
    public let directory: Bool
}

public struct PTDebugPreferenceRecord: Sendable, Equatable, Codable {
    public let key: String
    public let type: String
}

public enum PTDebugInventoryCore {
    public static func files(databasesOnly: Bool = false,
                             maximum: Int = 500) -> [PTDebugInventoryRecord] {
        let manager = FileManager.default
        let roots: [(String, FileManager.SearchPathDirectory)] = [
            ("Documents", .documentDirectory),
            ("Caches", .cachesDirectory),
            ("Application Support", .applicationSupportDirectory)
        ]
        let limit = max(1, min(maximum, 500))
        var output: [PTDebugInventoryRecord] = []
        for (area, folder) in roots {
            guard let root = manager.urls(for: folder, in: .userDomainMask).first else { continue }
            let values = (try? manager.contentsOfDirectory(
                at: root, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
                options: [.skipsHiddenFiles])) ?? []
            for item in values {
                if output.count == limit { return output }
                if databasesOnly && !["db", "sqlite", "sqlite3"]
                    .contains(item.pathExtension.lowercased()) { continue }
                let data = try? item.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                output.append(PTDebugInventoryRecord(
                    identity: area + "/" + String(output.count),
                    name: item.lastPathComponent, area: area,
                    kind: databasesOnly ? "database" : "file",
                    bytes: data?.fileSize ?? 0, directory: data?.isDirectory ?? false))
            }
        }
        return output
    }

    public static func defaults(maximum: Int = 400) -> [PTDebugPreferenceRecord] {
        let withheld = ["token", "secret", "password", "cookie", "auth",
                        "key", "credential", "email", "phone", "address", "session"]
        let dictionary = UserDefaults.standard.dictionaryRepresentation()
        let keys = dictionary.keys.sorted().filter { key in
            !withheld.contains(where: { key.lowercased().contains($0) })
        }.prefix(max(1, min(maximum, 400)))
        return keys.map { key in
            PTDebugPreferenceRecord(
                key: key,
                type: dictionary[key].map { String(describing: Swift.type(of: $0)) }
                    ?? "Unknown")
        }
    }
}
