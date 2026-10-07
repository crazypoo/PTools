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
                kind: PTCollectionUpdateKind = .structure,
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
        PTNSLogConsole("[PTCollection] id=\(operationID) kind=\(kind.rawValue) operation=\(operation) state=\(state) time=\(now) elapsed=\(elapsed) pending=\(pendingCount) snapshot=\(metrics.sections)/\(metrics.items) sections=[\(sectionText)] items=[\(itemText)] reconfigured=[\(reconfiguredText)]")
        if state == "finish" {
            operationStartTimes.removeValue(forKey: operationID)
        }
        #endif
    }
}

// English: Trace the Provider → Configure → Visible UI chain in DEBUG builds.
// Español: Traza la cadena Provider → Configure → UI visible en compilaciones DEBUG.
// 中文：在 DEBUG 构建中追踪 Provider → Configure → 可见 UI 的完整链路。
@MainActor
final class PTCollectionCellConfigurationDiagnostics {
    private var requestedItemIDs: Set<String> = []
    private var visibleRequestedItemIDs: Set<String> = []
    private var configuredItemIDs: Set<String> = []
    private var visibleConfiguredItemIDs: Set<String> = []

    func request(_ identifiers: [PTRowIdentifier], visible: [PTRowIdentifier] = []) {
        #if DEBUG
        requestedItemIDs.formUnion(identifiers.map(\.rawValue))
        visibleRequestedItemIDs.formUnion(visible.map(\.rawValue))
        #endif
    }

    func provider(operationID: UInt64?, rowID: PTRowIdentifier, indexPath: IndexPath) {
        #if DEBUG
        PTNSLogConsole("[PTCollection] provider=enter operation=\(operationID.map { String($0) } ?? "none") rowID=\(rowID.rawValue) indexPath=\(indexPath.section)-\(indexPath.item)")
        #endif
    }

    // English: Record the model identity seen by a provider or visible-cell fast path.
    // Español: Registra la identidad del modelo observada por el provider o la ruta rápida visible.
    // 中文：记录 Provider 或可见 Cell 快速路径实际读取到的模型身份。
    func fingerprint(operationID: UInt64?, row: PTRows, indexPath: IndexPath, phase: String) {
        #if DEBUG
        let modelID = row.dataModel.map { String(describing: ObjectIdentifier($0)) } ?? "none"
        PTNSLogConsole("[PTCollection] fingerprint phase=\(phase) operation=\(operationID.map { String($0) } ?? "none") rowID=\(row.diffId) rowObject=\(ObjectIdentifier(row)) dataModel=\(modelID) diffHash=\(row.diffHash) indexPath=\(indexPath.section)-\(indexPath.item)")
        #endif
    }

    func configure(operationID: UInt64?, rowID: PTRowIdentifier, indexPath: IndexPath, cell: UICollectionViewCell, visible: Bool) {
        #if DEBUG
        configuredItemIDs.insert(rowID.rawValue)
        if visible { visibleConfiguredItemIDs.insert(rowID.rawValue) }
        PTNSLogConsole("[PTCollection] configure=exit operation=\(operationID.map { String($0) } ?? "none") rowID=\(rowID.rawValue) indexPath=\(indexPath.section)-\(indexPath.item) cell=\(String(describing: type(of: cell))) visible=\(visible)")
        #endif
    }

    func finish(operationID: UInt64?, kind: PTCollectionUpdateKind) {
        #if DEBUG
        guard kind == .content else { return }
        let missing = visibleRequestedItemIDs.subtracting(visibleConfiguredItemIDs)
        if !missing.isEmpty {
            PTNSLogConsole("[PTCollection] content refresh produced no visible cell configuration operation=\(operationID.map { String($0) } ?? "none") missing=\(missing.sorted())")
        }
        requestedItemIDs.removeAll(keepingCapacity: true)
        visibleRequestedItemIDs.removeAll(keepingCapacity: true)
        configuredItemIDs.removeAll(keepingCapacity: true)
        visibleConfiguredItemIDs.removeAll(keepingCapacity: true)
        #endif
    }
}
