//
//  UITableView+PTEX.swift
//  PooTools_Example
//
//  Created by jax on 2022/9/5.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public extension UITableView {
    
    //MARK: 獲取Cell在Window的位置
    ///獲取Cell在Window的位置
    @objc func cellInWindow(cellFrame:CGRect) -> CGRect {
        let cellInCollectionViewRect = self.convert(cellFrame, to: self)
        let cellRectInWindow = self.convert(cellInCollectionViewRect, to: AppWindows!)
        return cellRectInWindow
    }
    
    /**
        Get last index path for special section.
     
     - parameter section: Section for which need get last row.
     */
    func indexPathForLastRow(inSection section: Int) -> IndexPath? {
        guard numberOfSections > 0, section >= 0 else { return nil }
        guard numberOfRows(inSection: section) > 0 else {
            return IndexPath(row: 0, section: section)
        }
        return IndexPath(row: numberOfRows(inSection: section) - 1, section: section)
    }

    /**
        Total count of rows.
     */
    func numberOfRows() -> Int {
        var section = 0
        var rowCount = 0
        while section < numberOfSections {
            rowCount += numberOfRows(inSection: section)
            section += 1
        }
        return rowCount
    }
}

