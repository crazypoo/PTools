//
//  PTCollectionIdentifiers.swift
//  PooTools
//
//  English: Keep stable collection identities as small Sendable values.
//  Español: Mantiene las identidades estables de la colección como valores Sendable pequeños.
//  中文：将列表稳定身份保持为轻量的 Sendable 值类型。
//

import Foundation

public struct PTSectionIdentifier: Hashable, RawRepresentable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    // English: Keep the legacy property spelling available to migration code.
    // Español: Mantiene disponible el nombre de propiedad heredado para el código de migración.
    // 中文：为迁移代码保留旧版属性名称。
    public var identifier: String { rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

public struct PTRowIdentifier: Hashable, RawRepresentable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    // English: Keep the legacy property spelling available to migration code.
    // Español: Mantiene disponible el nombre de propiedad heredado para el código de migración.
    // 中文：为迁移代码保留旧版属性名称。
    public var diffId: String { rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}
