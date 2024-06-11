//
//  UIPageControl+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 25/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import UIKit

public typealias PageControlTouchedBlock = (_ sender:UIPageControl) -> Void

public extension UIPageControl {
    private struct AssociatedKeys {
        static var UIPageControlBlockKey = 998
    }
    
    @objc func addPageControlHandlers(handler:@escaping PageControlTouchedBlock) {
        objc_setAssociatedObject(self, &AssociatedKeys.UIPageControlBlockKey, handler, .OBJC_ASSOCIATION_COPY)
        addTarget(self, action: #selector(actionTouched(sender:)), for: .valueChanged)
    }
    
    @objc func actionTouched(sender:UIPageControl) {
        let block:PageControlTouchedBlock = objc_getAssociatedObject(self, &AssociatedKeys.UIPageControlBlockKey) as! PageControlTouchedBlock
        block(sender)
    }

}
