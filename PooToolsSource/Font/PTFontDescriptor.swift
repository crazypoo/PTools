//
//  PTFontDescriptor.swift
//
// English: Runtime discovery adds availability metadata without polluting the generated catalog.
// Español: El descubrimiento en runtime añade disponibilidad sin contaminar el catálogo generado.
// 中文：运行时发现只补充可用性元数据，不污染生成目录。
//

import Foundation

public struct PTFontDescriptor: Hashable, Sendable, Codable {
    public let postScriptName: String
    public let familyName: String
    public let introducedIOS: String?
    public let deprecatedIOS: String?
    public let aliases: [String]

    public init(postScriptName: String,
                familyName: String,
                introducedIOS: String? = nil,
                deprecatedIOS: String? = nil,
                aliases: [String] = []) {
        self.postScriptName = postScriptName
        self.familyName = familyName
        self.introducedIOS = introducedIOS
        self.deprecatedIOS = deprecatedIOS
        self.aliases = aliases
    }
}

