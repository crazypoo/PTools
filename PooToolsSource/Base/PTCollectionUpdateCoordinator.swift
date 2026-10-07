//
//  PTCollectionUpdateCoordinator.swift
//  PooTools
//
//  English: Serialize collection operations while building snapshots at execution time.
//  Español: Serializa las operaciones de la colección y construye los snapshots al ejecutarlas.
//  中文：串行化列表更新操作，并在真正执行时构建快照。
//

import Foundation
import UIKit

#if canImport(PToolsCore)
import PToolsCore
#endif

@MainActor
final class PTCollectionUpdateCoordinator {
    typealias Completion = @MainActor () -> Void
    typealias OperationBody = @MainActor (@escaping Completion) -> Void

    private final class PendingOperation {
        let id: UInt64
        let name: String
        let body: OperationBody

        init(id: UInt64, name: String, body: @escaping OperationBody) {
            self.id = id
            self.name = name
            self.body = body
        }
    }

    private final class CompletionGate {
        var completed = false
    }

    private var pendingOperations: [PendingOperation] = []
    private var nextOperationID: UInt64 = 0
    private var isExecuting = false
    private var processScheduled = false
    private let diagnostics: PTCollectionUpdateDiagnostics

    init(diagnostics: PTCollectionUpdateDiagnostics) {
        self.diagnostics = diagnostics
    }

    var pendingOperationCount: Int {
        pendingOperations.count + (isExecuting ? 1 : 0)
    }

    func enqueue(name: String,
                 sections: [Int] = [],
                 items: [IndexPath] = [],
                 reconfiguredItems: [IndexPath] = [],
                 body: @escaping OperationBody) {
        nextOperationID &+= 1
        let operation = PendingOperation(id: nextOperationID, name: name, body: body)
        pendingOperations.append(operation)
        diagnostics.record(operationID: operation.id,
                           operation: name,
                           state: "enqueue",
                           pendingCount: pendingOperationCount,
                           sections: sections,
                           items: items,
                           reconfiguredItems: reconfiguredItems)
        scheduleProcessing()
    }

    private func scheduleProcessing() {
        guard !isExecuting, !processScheduled else { return }
        processScheduled = true
        PTMainActorBridge.perform { [weak self] in
            guard let self else { return }
            self.processScheduled = false
            self.processNextIfNeeded()
        }
    }

    private func processNextIfNeeded() {
        guard !isExecuting, let operation = pendingOperations.first else { return }
        pendingOperations.removeFirst()
        isExecuting = true
        diagnostics.record(operationID: operation.id,
                           operation: operation.name,
                           state: "execute",
                           pendingCount: pendingOperationCount)

        let gate = CompletionGate()
        let finish: Completion = { [weak self, gate] in
            guard !gate.completed else { return }
            gate.completed = true
            guard let self else { return }
            self.isExecuting = false
            self.diagnostics.record(operationID: operation.id,
                                    operation: operation.name,
                                    state: "finish",
                                    pendingCount: self.pendingOperationCount)
            self.scheduleProcessing()
        }
        operation.body(finish)
    }
}
