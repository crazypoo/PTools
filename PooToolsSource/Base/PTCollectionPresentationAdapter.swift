//
//  PTCollectionPresentationAdapter.swift
//  PooTools
//
// English: Map logical rows to bounded physical identities for infinite presentation.
// Español: Mapea filas lógicas a identidades físicas acotadas para la presentación infinita.
// 中文：将逻辑 Row 映射为有界的物理身份，用于无限循环展示。
//

import Foundation

@MainActor
final class PTCollectionPresentationAdapter {
    private(set) var isActive = false
    private(set) var sectionID: PTSectionIdentifier?
    private(set) var logicalRows: [PTRowIdentifier] = []
    private(set) var physicalRows: [PTRowIdentifier] = []
    private(set) var logicalByPhysical: [PTRowIdentifier: PTRowIdentifier] = [:]
    private(set) var physicalByLogical: [PTRowIdentifier: [PTRowIdentifier]] = [:]
    private(set) var logicalIndexByPhysical: [PTRowIdentifier: Int] = [:]
    private(set) var physicalIndexByID: [PTRowIdentifier: Int] = [:]
    private(set) var initialPhysicalIndex = 0
    private(set) var currentLogicalPage = 0
    private(set) var projectionUsesThreeCopies = false
    private(set) var lastError: PTCollectionScrollError?
    private var generation: UInt64 = 0

    var logicalPageCount: Int { logicalRows.count }

    func reset() {
        isActive = false
        sectionID = nil
        logicalRows = []
        physicalRows = []
        logicalByPhysical = [:]
        physicalByLogical = [:]
        logicalIndexByPhysical = [:]
        physicalIndexByID = [:]
        initialPhysicalIndex = 0
        currentLogicalPage = 0
        projectionUsesThreeCopies = false
        lastError = nil
    }

    func configure(sections: [PTSection],
                   configuration: PTCollectionScrollConfiguration) -> Result<PTCollectionIDSnapshot, PTCollectionScrollError> {
        reset()
        guard configuration.style.isInfinite else {
            return .success(snapshot(for: sections))
        }

        guard sections.count == 1 else {
            let error = PTCollectionScrollError.invalidConfiguration("无限循环只支持一个 Section")
            lastError = error
            return .failure(error)
        }
        guard let section = sections.first,
              let rows = section.rows,
              !rows.isEmpty else {
            return .success(snapshot(for: sections))
        }
        guard rows.count >= 2 else {
            // English: A single item has no meaningful loop and remains a normal one-item presentation.
            // Español: Un solo elemento no tiene un ciclo significativo y conserva una presentación normal.
            // 中文：单个元素没有实际循环意义，保持普通单元素展示。
            return .success(snapshot(for: sections))
        }

        var seen = Set<String>()
        for row in rows {
            guard !row.diffId.isEmpty, seen.insert(row.diffId).inserted else {
                let error = PTCollectionScrollError.legacyProviderNotLoopSafe
                lastError = error
                return .failure(error)
            }
        }

        sectionID = PTSectionIdentifier(section.identifier)
        logicalRows = rows.map { PTRowIdentifier($0.diffId) }
        isActive = true
        currentLogicalPage = min(configuration.paging.initialPage, max(0, logicalRows.count - 1))
        let projectedCount = logicalRows.count.multipliedReportingOverflow(by: 3)
        projectionUsesThreeCopies = !projectedCount.overflow && projectedCount.partialValue <= configuration.infinite.maxProjectedItems
        buildProjection(around: currentLogicalPage,
                        configuration: configuration)
        return .success(snapshot(for: sections))
    }

    func snapshot(for sections: [PTSection]) -> PTCollectionIDSnapshot {
        var snapshot = PTCollectionIDSnapshot()
        guard isActive,
              let sectionID,
              let section = sections.first(where: { $0.identifier == sectionID.rawValue }) else {
            snapshot.appendSections(sections)
            for section in sections {
                if let rows = section.rows, !rows.isEmpty {
                    snapshot.appendItems(rows, toSection: section)
                }
            }
            return snapshot
        }
        snapshot.appendSections([sectionID])
        if !physicalRows.isEmpty {
            snapshot.appendItems(physicalRows, toSection: sectionID)
        }
        return snapshot
    }

    func logicalID(for physicalID: PTRowIdentifier) -> PTRowIdentifier {
        logicalByPhysical[physicalID] ?? physicalID
    }

    func logicalIndex(for physicalID: PTRowIdentifier) -> Int? {
        logicalIndexByPhysical[physicalID]
    }

    func physicalID(for logicalPage: Int) -> PTRowIdentifier? {
        guard !logicalRows.isEmpty else { return nil }
        let page = ((logicalPage % logicalRows.count) + logicalRows.count) % logicalRows.count
        return physicalByLogical[logicalRows[page]]?.first
    }

    func physicalIndex(for logicalPage: Int) -> Int? {
        guard !logicalRows.isEmpty else { return nil }
        let page = ((logicalPage % logicalRows.count) + logicalRows.count) % logicalRows.count
        let candidates = physicalByLogical[logicalRows[page]] ?? []
        return candidates.compactMap { physicalIndexByID[$0] }
            .min { abs($0 - initialPhysicalIndex) < abs($1 - initialPhysicalIndex) }
    }

    func logicalPage(for physicalIndex: Int) -> Int? {
        guard physicalRows.indices.contains(physicalIndex) else { return nil }
        return logicalIndexByPhysical[physicalRows[physicalIndex]]
    }

    func shouldRebind(physicalIndex: Int) -> Bool {
        guard isActive, !projectionUsesThreeCopies, physicalRows.count == 7 else { return false }
        return physicalIndex <= 1 || physicalIndex >= physicalRows.count - 2
    }

    func rebind(around logicalPage: Int,
                configuration: PTCollectionScrollConfiguration) -> Bool {
        guard isActive, !projectionUsesThreeCopies else { return false }
        let page = logicalRows.isEmpty ? 0 : ((logicalPage % logicalRows.count) + logicalRows.count) % logicalRows.count
        guard page != currentLogicalPage || physicalRows.isEmpty else { return false }
        currentLogicalPage = page
        buildProjection(around: page, configuration: configuration)
        return true
    }

    private func buildProjection(around logicalPage: Int,
                                 configuration: PTCollectionScrollConfiguration) {
        generation &+= 1
        physicalRows.removeAll(keepingCapacity: true)
        logicalByPhysical.removeAll(keepingCapacity: true)
        physicalByLogical.removeAll(keepingCapacity: true)
        logicalIndexByPhysical.removeAll(keepingCapacity: true)
        physicalIndexByID.removeAll(keepingCapacity: true)

        let count = projectionUsesThreeCopies ? logicalRows.count * 3 : 7
        let start = projectionUsesThreeCopies
            ? logicalRows.count + logicalPage
            : logicalPage - 3
        for offset in 0..<count {
            let logicalIndex = ((start + offset) % logicalRows.count + logicalRows.count) % logicalRows.count
            let logicalID = logicalRows[logicalIndex]
            let physicalID = PTRowIdentifier("__ptools.infinite.\(generation).\(offset).\(logicalID.rawValue)")
            physicalRows.append(physicalID)
            logicalByPhysical[physicalID] = logicalID
            physicalByLogical[logicalID, default: []].append(physicalID)
            logicalIndexByPhysical[physicalID] = logicalIndex
            physicalIndexByID[physicalID] = offset
        }
        initialPhysicalIndex = projectionUsesThreeCopies ? logicalRows.count + logicalPage : 3
    }
}

