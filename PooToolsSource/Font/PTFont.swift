//
//  PTFont.swift
//
// English: Immutable font metadata stays Sendable; UIKit construction remains on MainActor.
// Español: Los metadatos inmutables de fuente son Sendable; la construcción UIKit queda en MainActor.
// 中文：不可变字体元数据保持 Sendable，UIKit 字体构造固定在 MainActor。
//

import UIKit

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

public extension PTFont {
    @MainActor
    func uiFont(size: CGFloat) -> UIFont? {
        UIFont(name: postScriptName, size: size)
    }

    @MainActor
    func isAvailable(size: CGFloat = 12) -> Bool {
        uiFont(size: size) != nil
    }
}

