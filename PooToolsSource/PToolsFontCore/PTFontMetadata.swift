//
//  PTFontMetadata.swift
//
// English: Keep immutable font metadata in a Foundation-only target so catalog tests do not require UIKit.
// Español: Mantiene los metadatos inmutables de fuentes en un target basado solo en Foundation para no requerir UIKit en las pruebas del catálogo.
// 中文：将不可变字体元数据放入 Foundation-only target，让目录测试不依赖 UIKit。
//

import Foundation

public struct PTFont: Hashable, Sendable, Codable {
    public let postScriptName: String
    public let familyName: String
    public let introducedIOS: String?

    public init(postScriptName: String,
                familyName: String,
                introducedIOS: String? = nil) {
        self.postScriptName = postScriptName
        self.familyName = familyName
        self.introducedIOS = introducedIOS
    }
}
