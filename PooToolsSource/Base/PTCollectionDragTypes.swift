//
//  PTCollectionDragTypes.swift
//  PooTools
//
// English: Typed drag lifecycle values for local and external collection interactions.
// Español: Valores tipados del ciclo de vida de arrastrar para interacciones locales y externas.
// 中文：为本地和外部列表拖放交互提供类型化生命周期值。
//

import UIKit

public enum PTCollectionDragPhase: String, Sendable {
    case began
    case entered
    case moved
    case exited
    case dropRequested
    case dropRejected
    case dropCommitted
    case cancelled
    case ended
}

public enum PTCollectionDragOutcome: String, Sendable {
    case pending
    case committed
    case rejected
    case cancelled
    case failed
}

@MainActor
public struct PTCollectionDragContext {
    public let sessionID: String
    public let phase: PTCollectionDragPhase
    public let outcome: PTCollectionDragOutcome
    public let sourceRowIDs: [PTRowIdentifier]
    public let sourceLogicalIndexPaths: [IndexPath]
    public let proposedDestination: IndexPath?
    public let finalDestination: IndexPath?
    public let isLocalSession: Bool

    public init(sessionID: String,
                phase: PTCollectionDragPhase,
                outcome: PTCollectionDragOutcome,
                sourceRowIDs: [PTRowIdentifier],
                sourceLogicalIndexPaths: [IndexPath],
                proposedDestination: IndexPath?,
                finalDestination: IndexPath?,
                isLocalSession: Bool) {
        self.sessionID = sessionID
        self.phase = phase
        self.outcome = outcome
        self.sourceRowIDs = sourceRowIDs
        self.sourceLogicalIndexPaths = sourceLogicalIndexPaths
        self.proposedDestination = proposedDestination
        self.finalDestination = finalDestination
        self.isLocalSession = isLocalSession
    }
}

