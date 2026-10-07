//
//  PTCollectionModelStore.swift
//  PooTools
//
//  English: Keep mutable collection content separate from the identity-only Diffable snapshot.
//  Español: Mantiene el contenido mutable separado del snapshot Diffable basado solo en identidad.
//  中文：将可变列表内容与纯身份 Diffable 快照分离。
//

import Foundation

// English: The MainActor store is the single mutable content source for PTCollectionView.
// Español: El store de MainActor es la única fuente mutable de contenido de PTCollectionView.
// 中文：MainActor ModelStore 是 PTCollectionView 唯一的可变内容源。
@MainActor
final class PTCollectionModelStore {
    private var sectionOrder: [PTSectionIdentifier] = []
    private var sections: [PTSectionIdentifier: PTSection] = [:]
    private var rowOrder: [PTSectionIdentifier: [PTRowIdentifier]] = [:]
    private var rows: [PTRowIdentifier: PTRows] = [:]

    func replace(_ models: [PTSection]) {
        sectionOrder = models.map { PTSectionIdentifier($0.identifier) }
        sections.removeAll(keepingCapacity: true)
        rowOrder.removeAll(keepingCapacity: true)
        rows.removeAll(keepingCapacity: true)

        for section in models {
            let sectionID = PTSectionIdentifier(section.identifier)
            sections[sectionID] = section
            let identifiers = (section.rows ?? []).map { row -> PTRowIdentifier in
                let rowID = PTRowIdentifier(row.diffId)
                rows[rowID] = row
                return rowID
            }
            rowOrder[sectionID] = identifiers
            refreshSectionRows(for: sectionID)
        }
    }

    // English: Replace mutable row values while preserving section order and stable identities.
    // Español: Reemplaza los valores mutables de las filas y conserva el orden de las secciones y sus identidades estables.
    // 中文：更新可变 Row 内容，同时保留 Section 顺序和稳定身份。
    func update(rows updatedRows: [PTRows]) {
        for row in updatedRows {
            rows[PTRowIdentifier(row.diffId)] = row
        }
        refreshSectionRows()
    }

    func update(row: PTRows) {
        update(rows: [row])
    }

    func update(section: PTSection) {
        let sectionID = PTSectionIdentifier(section.identifier)
        sections[sectionID] = section
        if !sectionOrder.contains(sectionID) {
            sectionOrder.append(sectionID)
        }
        let identifiers = (section.rows ?? []).map { row -> PTRowIdentifier in
            let rowID = PTRowIdentifier(row.diffId)
            rows[rowID] = row
            return rowID
        }
        rowOrder[sectionID] = identifiers
        refreshSectionRows(for: sectionID)
    }

    func updateItemContent(at indexPath: IndexPath, using row: PTRows) {
        guard sectionOrder.indices.contains(indexPath.section) else { return }
        let sectionID = sectionOrder[indexPath.section]
        guard rowOrder[sectionID]?.indices.contains(indexPath.item) == true,
              rowOrder[sectionID]?[indexPath.item] == PTRowIdentifier(row.diffId) else { return }
        update(row: row)
    }

    func insert(rows insertedRows: [PTRows], in sectionID: PTSectionIdentifier, at index: Int?) {
        guard sections[sectionID] != nil else { return }
        let newIDs = insertedRows.map { row -> PTRowIdentifier in
            let rowID = PTRowIdentifier(row.diffId)
            rows[rowID] = row
            return rowID
        }
        var current = rowOrder[sectionID] ?? []
        let insertionIndex = min(max(index ?? current.count, 0), current.count)
        current.insert(contentsOf: newIDs, at: insertionIndex)
        rowOrder[sectionID] = current
        refreshSectionRows(for: sectionID)
    }

    func insert(sections insertedSections: [PTSection], at index: Int?) {
        let insertionIndex = min(max(index ?? sectionOrder.count, 0), sectionOrder.count)
        for (offset, section) in insertedSections.enumerated() {
            let sectionID = PTSectionIdentifier(section.identifier)
            if !sectionOrder.contains(sectionID) {
                sectionOrder.insert(sectionID, at: min(insertionIndex + offset, sectionOrder.count))
            }
            update(section: section)
        }
    }

    func remove(rows removedRows: [PTRowIdentifier], from sectionID: PTSectionIdentifier) {
        guard var current = rowOrder[sectionID] else { return }
        let removed = Set(removedRows)
        current.removeAll { removed.contains($0) }
        rowOrder[sectionID] = current
        removedRows.forEach { rows.removeValue(forKey: $0) }
        refreshSectionRows(for: sectionID)
    }

    func remove(sections removedSections: [PTSectionIdentifier]) {
        let removed = Set(removedSections)
        sectionOrder.removeAll { removed.contains($0) }
        for sectionID in removedSections {
            rowOrder[sectionID, default: []].forEach { rows.removeValue(forKey: $0) }
            rowOrder.removeValue(forKey: sectionID)
            sections.removeValue(forKey: sectionID)
        }
    }

    func move(row rowID: PTRowIdentifier,
              from sourceSectionID: PTSectionIdentifier,
              to destinationSectionID: PTSectionIdentifier,
              at destinationIndex: Int) {
        guard var sourceRows = rowOrder[sourceSectionID],
              let sourceIndex = sourceRows.firstIndex(of: rowID) else { return }
        sourceRows.remove(at: sourceIndex)
        rowOrder[sourceSectionID] = sourceRows
        var destinationRows = rowOrder[destinationSectionID] ?? []
        let index = min(max(destinationIndex, 0), destinationRows.count)
        destinationRows.insert(rowID, at: index)
        rowOrder[destinationSectionID] = destinationRows
        refreshSectionRows(for: sourceSectionID)
        if sourceSectionID != destinationSectionID {
            refreshSectionRows(for: destinationSectionID)
        }
    }

    func synchronize(with snapshot: PTCollectionIDSnapshot) {
        let snapshotSections = snapshot.sectionIdentifiers
        sectionOrder = snapshotSections
        let liveSections = Set(snapshotSections)
        sections = sections.filter { liveSections.contains($0.key) }
        rowOrder = rowOrder.filter { liveSections.contains($0.key) }
        let liveRows = Set(snapshot.itemIdentifiers)
        rows = rows.filter { liveRows.contains($0.key) }
        for sectionID in snapshotSections {
            rowOrder[sectionID] = snapshot.itemIdentifiers(inSection: sectionID)
            refreshSectionRows(for: sectionID)
        }
    }

    func sectionIdentifiers() -> [PTSectionIdentifier] {
        sectionOrder
    }

    func rowIdentifiers(in sectionID: PTSectionIdentifier) -> [PTRowIdentifier] {
        rowOrder[sectionID] ?? []
    }

    func section(for identifier: String) -> PTSection? {
        section(for: PTSectionIdentifier(identifier))
    }

    func section(for identifier: PTSectionIdentifier) -> PTSection? {
        guard let section = sections[identifier] else { return nil }
        refreshSectionRows(for: identifier)
        return section
    }

    func row(for identifier: String) -> PTRows? {
        row(for: PTRowIdentifier(identifier))
    }

    func row(for identifier: PTRowIdentifier) -> PTRows? {
        rows[identifier]
    }

    func resolvedSection(_ section: PTSection) -> PTSection {
        resolvedSection(PTSectionIdentifier(section.identifier)) ?? section
    }

    func resolvedSection(_ identifier: PTSectionIdentifier) -> PTSection? {
        section(for: identifier)
    }

    func resolvedRow(_ row: PTRows) -> PTRows {
        resolvedRow(PTRowIdentifier(row.diffId)) ?? row
    }

    func resolvedRow(_ identifier: PTRowIdentifier) -> PTRows? {
        rows[identifier]
    }

    func resolvedSections(_ snapshotSections: [PTSectionIdentifier]) -> [PTSection] {
        snapshotSections.compactMap(resolvedSection)
    }

    func resolvedRows(_ snapshotRows: [PTRowIdentifier]) -> [PTRows] {
        snapshotRows.compactMap(resolvedRow)
    }

    private func refreshSectionRows(for identifier: PTSectionIdentifier? = nil) {
        let identifiers = identifier.map { [$0] } ?? sectionOrder
        for sectionID in identifiers {
            guard let section = sections[sectionID] else { continue }
            section.rows = (rowOrder[sectionID] ?? []).compactMap { rows[$0] }
        }
    }
}
