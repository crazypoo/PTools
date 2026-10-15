//
//  PTCollectionSkeletonDiagnostics.swift
//  PooTools
//
// English: Expose structure-only diagnostics without leaking rows or business data.
// Español: Expone diagnósticos estructurales sin filtrar filas ni datos de negocio.
// 中文：只提供结构诊断，不泄露 Row 或业务数据。
//

import UIKit

@MainActor
public struct PTSkeletonDiagnosticsSnapshot: Sendable {
    public let isRequested: Bool
    public let isVisible: Bool
    public let itemCount: Int
    public let sectionCount: Int
    public let animationStyle: String
    public let generation: UInt64

    public init(isRequested: Bool,
                isVisible: Bool,
                itemCount: Int,
                sectionCount: Int,
                animationStyle: String,
                generation: UInt64) {
        self.isRequested = isRequested
        self.isVisible = isVisible
        self.itemCount = itemCount
        self.sectionCount = sectionCount
        self.animationStyle = animationStyle
        self.generation = generation
    }
}

extension PTCollectionView {
    public var skeletonDiagnostics: PTSkeletonDiagnosticsSnapshot {
        let configuration = activeSkeletonConfiguration
        return PTSkeletonDiagnosticsSnapshot(isRequested: presentationCoordinator.skeletonRequested,
                                             isVisible: isSkeletonVisible,
                                             itemCount: activeSkeletonItemCount ?? viewConfig.skeletonItemCount,
                                             sectionCount: configuration?.sections?.count ?? 0,
                                             animationStyle: configuration?.animation.style.rawValue ?? "none",
                                             generation: presentationCoordinator.generation)
    }
}
