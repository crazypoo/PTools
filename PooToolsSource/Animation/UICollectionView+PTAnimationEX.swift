//
//  UICollectionView+PTAnimationEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/26.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public extension UICollectionView {
    var orderedVisibleCells:[UICollectionViewCell] {
        indexPathsForVisibleItems.sorted().compactMap({
            cellForItem(at: $0)
        })
    }
    
    func visibleCells(in section: Int) -> [UICollectionViewCell] {
        visibleCells.filter({
            indexPath(for: $0)?.section == section
        })
    }
}
