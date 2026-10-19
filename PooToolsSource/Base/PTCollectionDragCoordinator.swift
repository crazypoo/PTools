//
//  PTCollectionDragCoordinator.swift
//  PooTools
//
// English: Keep drag lifecycle bookkeeping out of PTCollectionView's data mutation code.
// Español: Mantiene el seguimiento del ciclo de arrastre fuera de la mutación de datos de PTCollectionView.
// 中文：将拖放生命周期记录从 PTCollectionView 数据变更代码中分离。
//

import UIKit

@MainActor
final class PTCollectionDragCoordinator {
    private(set) var sessionID: String?
    private(set) var sourceRowIDs: [PTRowIdentifier] = []
    private(set) var sourceIndexPaths: [IndexPath] = []
    private(set) var isLocalSession = false

    func begin(sourceRowIDs: [PTRowIdentifier],
               sourceIndexPaths: [IndexPath],
               isLocalSession: Bool,
               emit: (PTCollectionDragPhase, PTCollectionDragOutcome, IndexPath?, IndexPath?) -> Void) {
        sessionID = UUID().uuidString
        self.sourceRowIDs = sourceRowIDs
        self.sourceIndexPaths = sourceIndexPaths
        self.isLocalSession = isLocalSession
        emit(.began, .pending, nil, nil)
    }

    func update(phase: PTCollectionDragPhase,
                outcome: PTCollectionDragOutcome = .pending,
                proposed: IndexPath? = nil,
                final: IndexPath? = nil,
                emit: (PTCollectionDragPhase, PTCollectionDragOutcome, IndexPath?, IndexPath?) -> Void) {
        guard sessionID != nil else { return }
        emit(phase, outcome, proposed, final)
    }

    func end(phase: PTCollectionDragPhase,
             outcome: PTCollectionDragOutcome,
             proposed: IndexPath? = nil,
             final: IndexPath? = nil,
             emit: (PTCollectionDragPhase, PTCollectionDragOutcome, IndexPath?, IndexPath?) -> Void) {
        guard sessionID != nil else { return }
        emit(phase, outcome, proposed, final)
        sessionID = nil
        sourceRowIDs = []
        sourceIndexPaths = []
        isLocalSession = false
    }
}

