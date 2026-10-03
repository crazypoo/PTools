//
//  PTFontCatalog.swift
//
// English: Generated metadata and immutable indexes are the canonical font lookup path.
// Español: Los metadatos generados y los índices inmutables son la ruta canónica de consulta.
// 中文：生成元数据和不可变索引构成规范字体查询入口。
//

import Foundation

public enum PTFontCatalog {
    public static let allFonts: [PTFont] = PTFontCatalogGenerated.allFonts

    private static let postScriptIndex: [String: PTFont] = {
        Dictionary(uniqueKeysWithValues: allFonts.map { ($0.postScriptName, $0) })
    }()

    private static let familyIndex: [String: [PTFont]] = {
        Dictionary(grouping: allFonts, by: \.familyName)
    }()

    public static func font(named postScriptName: String) -> PTFont? {
        postScriptIndex[postScriptName]
    }

    public static func fonts(family familyName: String) -> [PTFont] {
        familyIndex[familyName] ?? []
    }

    public static func contains(postScriptName: String) -> Bool {
        postScriptIndex[postScriptName] != nil
    }
}
