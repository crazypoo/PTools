//
//  PTModelCombine.swift
//
// English: Combine observation is an optional adapter and never leaks into PTModelCore.
// Español: La observación de Combine es un adaptador opcional y nunca entra en PTModelCore.
// 中文：Combine 观察能力作为可选适配层，不进入 PTModelCore。
//

#if canImport(Combine)
import Combine

@MainActor
public final class PTModelPublishedBox<Model: Sendable>: ObservableObject {
    @Published public private(set) var value: Model

    public init(_ value: Model) {
        self.value = value
    }

    public func replace(with value: Model) {
        self.value = value
    }
}
#endif

#if canImport(Observation)
import Observation

// English: The iOS 17 Observation adapter mirrors the Combine box without leaking Observation into Core.
// Español: El adaptador Observation de iOS 17 refleja el box de Combine sin filtrar Observation al núcleo.
// 中文：iOS 17 Observation 适配器与 Combine Box 对齐，但不让 Observation 进入 Core。
@MainActor
@Observable
public final class PTModelObservationBox<Model: Sendable> {
    public private(set) var value: Model

    public init(_ value: Model) {
        self.value = value
    }

    public func replace(with value: Model) {
        self.value = value
    }
}
#endif
