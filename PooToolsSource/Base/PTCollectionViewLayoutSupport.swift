//
//  PTCollectionViewLayoutSupport.swift
//  PooTools
//
//  English: Keep pure layout cache keys outside the collection-view facade.
//  Español: Mantiene las claves puras de caché de diseño fuera de la fachada de colección.
//  中文：将纯布局缓存键从 CollectionView 门面中独立出来。
//

import UIKit

struct PTCollectionDiffThreshold {
    static let smallItem = 200
    static let mediumItem = 500
    static let largeItem = 1_000
}

struct PTCollectionWaterfallCache {
    var items: [NSCollectionLayoutGroupCustomItem] = []
    var contentHeight: CGFloat = 0
}

struct PTCollectionWaterfallCacheKey: Hashable {
    let section: Int
    let width: CGFloat
    let version: Int
    let layoutRevision: UInt64

    init(section: Int, width: CGFloat, version: Int, layoutRevision: UInt64 = 0) {
        self.section = section
        self.width = width
        self.version = version
        self.layoutRevision = layoutRevision
    }
}
