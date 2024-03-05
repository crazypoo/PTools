//
//  UIViewController+PTSheetEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/5.
//  Copyright © 2024 crazypoo. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

extension UIViewController {
    public var sheetViewController: PTSheetViewController? {
        var parent = self.parent
        while let currentParent = parent {
            if let sheetViewController = currentParent as? PTSheetViewController {
                return sheetViewController
            } else {
                parent = currentParent.parent
            }
        }
        return nil
    }
}

#endif
