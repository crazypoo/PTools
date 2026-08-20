//
//  PTCollectionViewTypes.swift
//  PooTools
//
//  Public value types used by PTCollectionView's layout and update pipeline.
//

import UIKit

struct LayoutCacheKey: Hashable {
    let section: Int
    let width: CGFloat
    let version: Int
}

struct HeightCacheKey: Hashable {
    let id: String
    let width: CGFloat
}

public enum PTDiffAnimation {
    case none
    case fade
    case right
    case left
    case top
    case bottom
    case automatic
    case `default`
}

public enum CornerPosition {
    case single, top, middle, bottom
}
