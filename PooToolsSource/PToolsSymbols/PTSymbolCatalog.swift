// English: The catalog owns aliases and descriptors; runtime image creation remains in the UIKit adapter.
// Español: El catálogo mantiene alias y descriptores; la creación de imágenes queda en el adaptador UIKit.
// 中文：目录负责别名和描述信息，运行时图片创建由 UIKit 适配层负责。

import Foundation

public enum PTSymbolCatalog {
    public static let catalogVersion = "5.24.0"

    // English: Generated descriptors are kept in a checked-in Swift file for deterministic builds.
    // Español: Los descriptores generados se conservan en Swift versionado para builds deterministas.
    // 中文：生成的描述信息保存在已提交的 Swift 文件中，保证构建可复现。
    public static let allSymbols: [PTSymbolDescriptor] = PTSymbolCatalogGenerated.allSymbols

    // English: Alias resolution is intentionally empty until Apple publishes an authoritative rename.
    // Español: La resolución de alias permanece vacía hasta que Apple publique un renombrado oficial.
    // 中文：在 Apple 发布权威重命名信息前，别名表保持为空，避免伪造迁移关系。
    public static let aliases: [String: String] = [:]

    public static func resolvedNames(for symbol: PTSymbol) -> [String] {
        var names = [symbol.rawValue]
        if let alias = aliases[symbol.rawValue], alias != symbol.rawValue {
            names.append(alias)
        }
        return names
    }
}
