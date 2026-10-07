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

// English: Keep the latest mutable models outside the Diffable snapshot without changing legacy APIs.
// Español: Mantiene los modelos mutables más recientes fuera del snapshot Diffable sin cambiar las API heredadas.
// 中文：在不改变旧 API 的前提下，将最新可变模型放在 Diffable 快照之外。
@MainActor
final class PTCollectionModelStore {
    private var sections: [PTSectionIdentifier: PTSection] = [:]
    private var rows: [PTRowIdentifier: PTRows] = [:]

    func replace(_ models: [PTSection]) {
        sections.removeAll(keepingCapacity: true)
        rows.removeAll(keepingCapacity: true)

        for section in models {
            sections[PTSectionIdentifier(section.identifier)] = section
            for row in section.rows ?? [] {
                rows[PTRowIdentifier(row.diffId)] = row
            }
        }
    }

    // English: Replace mutable row values while preserving section order and stable identities.
    // Español: Reemplaza los valores mutables de las filas y conserva el orden de las secciones y sus identidades estables.
    // 中文：更新可变 Row 内容，同时保留 Section 顺序和稳定身份。
    func update(rows updatedRows: [PTRows]) {
        for row in updatedRows {
            rows[PTRowIdentifier(row.diffId)] = row
        }
        for section in sections.values {
            guard let sectionRows = section.rows else { continue }
            section.rows = sectionRows.map { rows[PTRowIdentifier($0.diffId)] ?? $0 }
        }
    }

    func section(for identifier: String) -> PTSection? {
        sections[PTSectionIdentifier(identifier)]
    }

    func row(for identifier: String) -> PTRows? {
        rows[PTRowIdentifier(identifier)]
    }

    func resolvedSection(_ section: PTSection) -> PTSection {
        sections[PTSectionIdentifier(section.identifier)] ?? section
    }

    func resolvedRow(_ row: PTRows) -> PTRows {
        rows[PTRowIdentifier(row.diffId)] ?? row
    }

    func resolvedSections(_ snapshotSections: [PTSection]) -> [PTSection] {
        snapshotSections.map(resolvedSection)
    }

    func resolvedRows(_ snapshotRows: [PTRows]) -> [PTRows] {
        snapshotRows.map(resolvedRow)
    }
}
