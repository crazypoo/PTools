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
    @objc func cellInWindow(cellFrame:CGRect)->CGRect {
        let cellInCollectionViewRect = self.convert(cellFrame, to: self)
        let cellRectInWindow = self.convert(cellInCollectionViewRect, to: AppWindows!)
        return cellRectInWindow
    }
}

