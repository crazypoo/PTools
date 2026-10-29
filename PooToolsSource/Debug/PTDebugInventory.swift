import Foundation
#if SWIFT_PACKAGE
import PToolsDebugInventoryCore
#endif

/// Compatibility value type retained for existing Debug and Studio consumers.
public struct PTDebugInventoryItem: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let source: String
    public let kind: String
    public let byteCount: Int
    public let isDirectory: Bool
}

/// Debug UI adapter: the Foundation-only provider owns filesystem enumeration.
public enum PTDebugFileInventory {
    public static func list(databasesOnly: Bool = false,
                            maximum: Int = 500) -> [PTDebugInventoryItem] {
        PTDebugInventoryCore.files(databasesOnly: databasesOnly, maximum: maximum).map {
            PTDebugInventoryItem(id: $0.identity, name: $0.name, source: $0.area,
                                 kind: $0.kind, byteCount: $0.bytes, isDirectory: $0.directory)
        }
    }
}

public struct PTDebugDefaultMetadata: Sendable, Equatable {
    public let key: String
    public let type: String
}

public enum PTDebugDefaultsInventory {
    public static func list(maximum: Int = 400) -> [PTDebugDefaultMetadata] {
        PTDebugInventoryCore.defaults(maximum: maximum).map {
            PTDebugDefaultMetadata(key: $0.key, type: $0.type)
        }
    }
}
