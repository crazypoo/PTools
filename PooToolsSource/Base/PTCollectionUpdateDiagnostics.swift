//
//  PTCollectionUpdateDiagnostics.swift
//  PooTools
//
//  English: Trace collection updates in DEBUG without affecting Release behavior.
//  Español: Traza las actualizaciones de la colección en DEBUG sin afectar a Release.
//  中文：仅在 DEBUG 追踪列表更新，不改变 Release 行为。
//

import Foundation

@MainActor
final class PTCollectionUpdateDiagnostics {
    typealias SnapshotMetrics = @MainActor () -> (sections: Int, items: Int)

    private let snapshotMetrics: SnapshotMetrics
    private var operationStartTimes: [UInt64: TimeInterval] = [:]

    init(snapshotMetrics: @escaping SnapshotMetrics) {
        self.snapshotMetrics = snapshotMetrics
    }

    func record(operationID: UInt64,
                operation: String,
                state: String,
                pendingCount: Int,
                sections: [Int] = [],
                items: [IndexPath] = [],
                reconfiguredItems: [IndexPath] = []) {
        #if DEBUG
        let now = Date().timeIntervalSinceReferenceDate
        if state == "enqueue" {
            operationStartTimes[operationID] = now
        }
        let elapsed = operationStartTimes[operationID].map { now - $0 } ?? 0
        let metrics = snapshotMetrics()
        let sectionText = sections.map(String.init).joined(separator: ",")
        let itemText = items.map { "\($0.section)-\($0.item)" }.joined(separator: ",")
        let reconfiguredText = reconfiguredItems.map { "\($0.section)-\($0.item)" }.joined(separator: ",")
        PTNSLogConsole("[PTCollection] id=\(operationID) operation=\(operation) state=\(state) time=\(now) elapsed=\(elapsed) pending=\(pendingCount) snapshot=\(metrics.sections)/\(metrics.items) sections=[\(sectionText)] items=[\(itemText)] reconfigured=[\(reconfiguredText)]")
        if state == "finish" {
            operationStartTimes.removeValue(forKey: operationID)
        }
        #endif
    }
}
