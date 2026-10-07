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
    // English: Carry layout invalidation with the coalesced content batch instead of losing a caller's request.
    // Español: Conserva la invalidación del layout junto con el lote de contenido combinado.
    // 中文：将布局失效标记和合并后的内容批次一起传递，避免丢失调用方请求。
    typealias ContentBody = @MainActor (Set<Int>, Set<IndexPath>, Bool, @escaping Completion) -> Void

    private final class PendingOperation {
        let id: UInt64
        let name: String
        let kind: PTCollectionUpdateKind
        var body: OperationBody?
        var contentBody: ContentBody?
        var sections: Set<Int>
        var items: Set<IndexPath>
        var invalidatesLayout: Bool
        var completions: [Completion] = []

        init(id: UInt64,
             name: String,
             kind: PTCollectionUpdateKind,
             body: OperationBody? = nil,
             contentBody: ContentBody? = nil,
             sections: Set<Int> = [],
             items: Set<IndexPath> = [],
             invalidatesLayout: Bool = false) {
            self.id = id
            self.name = name
            self.kind = kind
            self.body = body
            self.contentBody = contentBody
            self.sections = sections
            self.items = items
            self.invalidatesLayout = invalidatesLayout
        }
    }

    private final class CompletionGate {
        var completed = false
    }

    private var pendingOperations: [PendingOperation] = []
    private var nextOperationID: UInt64 = 0
    private var isExecuting = false
    private let diagnostics: PTCollectionUpdateDiagnostics

    private(set) var activeOperationID: UInt64?
    private(set) var activeOperationKind: PTCollectionUpdateKind?

    init(diagnostics: PTCollectionUpdateDiagnostics) {
        self.diagnostics = diagnostics
    }

    var pendingOperationCount: Int {
        pendingOperations.count + (isExecuting ? 1 : 0)
    }

    func enqueue(name: String,
                 kind: PTCollectionUpdateKind = .structure,
                 sections: [Int] = [],
                 items: [IndexPath] = [],
                 reconfiguredItems: [IndexPath] = [],
                 body: @escaping OperationBody) {
        nextOperationID &+= 1
        let operation = PendingOperation(id: nextOperationID,
                                         name: name,
                                         kind: kind,
                                         body: body,
                                         sections: Set(sections),
                                         items: Set(items))
        pendingOperations.append(operation)
        diagnostics.record(operationID: operation.id,
                           operation: name,
                           kind: kind,
                           state: "enqueue",
                           pendingCount: pendingOperationCount,
                           sections: sections,
                           items: items,
                           reconfiguredItems: reconfiguredItems)
        processNextIfNeeded()
    }

    // English: Coalesce content refreshes before they reach Diffable, while structure remains strictly serialized.
    // Español: Agrupa los refrescos de contenido antes de llegar a Diffable y mantiene la estructura estrictamente serializada.
    // 中文：在进入 Diffable 前合并内容刷新，同时保持结构更新严格串行。
    func enqueueContent(name: String,
                        sections: [Int] = [],
                        items: [IndexPath] = [],
                        invalidateLayout: Bool = false,
                        body: @escaping ContentBody,
                        completion: Completion? = nil) {
        let sectionSet = Set(sections)
        let itemSet = Set(items)
        if let pendingIndex = pendingOperations.indices.last,
           pendingOperations[pendingIndex].kind == .content {
            let operation = pendingOperations[pendingIndex]
            operation.sections.formUnion(sectionSet)
            operation.items.formUnion(itemSet)
            operation.invalidatesLayout = operation.invalidatesLayout || invalidateLayout
            // English: All content APIs share the same stable-ID batch body; keep the first body when merging.
            // Español: Todas las API de contenido comparten el mismo cuerpo por IDs; conserva el primero al combinar.
            // 中文：所有内容 API 共用稳定 ID 批处理逻辑，合并时保留第一个 body。
            if operation.contentBody == nil {
                operation.contentBody = body
            }
            if let completion { operation.completions.append(completion) }
            diagnostics.record(operationID: operation.id,
                               operation: operation.name,
                               kind: .content,
                               state: "coalesce",
                               pendingCount: pendingOperationCount,
                               sections: Array(operation.sections),
                               items: Array(operation.items))
            processNextIfNeeded()
            return
        }

        nextOperationID &+= 1
        let operation = PendingOperation(id: nextOperationID,
                                         name: name,
                                         kind: .content,
                                         contentBody: body,
                                         sections: sectionSet,
                                         items: itemSet,
                                         invalidatesLayout: invalidateLayout)
        if let completion { operation.completions.append(completion) }
        pendingOperations.append(operation)
        diagnostics.record(operationID: operation.id,
                           operation: name,
                           kind: .content,
                           state: "enqueue",
                           pendingCount: pendingOperationCount,
                           sections: sections,
                           items: items)
        processNextIfNeeded()
    }

    private func processNextIfNeeded() {
        guard !isExecuting, let operation = pendingOperations.first else { return }
        pendingOperations.removeFirst()
        isExecuting = true
        activeOperationID = operation.id
        activeOperationKind = operation.kind
        diagnostics.record(operationID: operation.id,
                           operation: operation.name,
                           kind: operation.kind,
                           state: "execute",
                           pendingCount: pendingOperationCount)

        let gate = CompletionGate()
        let finish: Completion = { [weak self, gate] in
            guard !gate.completed else { return }
            gate.completed = true
            guard let self else { return }
            self.isExecuting = false
            self.activeOperationID = nil
            self.activeOperationKind = nil
            self.diagnostics.record(operationID: operation.id,
                                    operation: operation.name,
                                    kind: operation.kind,
                                    state: "finish",
                                    pendingCount: self.pendingOperationCount)
            operation.completions.forEach { $0() }
            self.processNextIfNeeded()
        }
        if let contentBody = operation.contentBody {
            contentBody(operation.sections, operation.items, operation.invalidatesLayout, finish)
        } else {
            operation.body?(finish)
        }
    }
}
