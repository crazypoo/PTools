//
//  PTCollectionPresentationCoordinator.swift
//  PooTools
//
// English: Serialize Empty, Loading, Content, and Skeleton intent on MainActor.
// Español: Serializa la intención de Empty, Loading, Content y Skeleton en MainActor.
// 中文：在 MainActor 上统一仲裁 Empty、Loading、Content 和 Skeleton 意图。
//

import UIKit

@MainActor
final class PTCollectionPresentationCoordinator {
    private(set) var skeletonRequested = false
    private(set) var generation: UInt64 = 0

    func beginSkeleton() -> UInt64 {
        generation &+= 1
        skeletonRequested = true
        return generation
    }

    func endSkeleton() -> UInt64 {
        generation &+= 1
        skeletonRequested = false
        return generation
    }

    func invalidate() {
        generation &+= 1
    }

    func isCurrent(_ token: UInt64) -> Bool {
        token == generation
    }
}
