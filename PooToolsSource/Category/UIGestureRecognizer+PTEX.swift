//
//  UIGestureRecognizer+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 5/5/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public typealias TapedBlock = (_ sender:AnyObject) -> Void

public extension UIGestureRecognizer {
    
    private struct AssociatedKeys {
        static var UIGestureRecognizerBlockKey = 998
    }

    @objc convenience init(actionBlock:@escaping TapedBlock) {
        self.init()
        addGesActionHandlers(handler: actionBlock)
    }
    
    @objc func addGesActionHandlers(handler:@escaping TapedBlock) {
        objc_setAssociatedObject(self, &AssociatedKeys.UIGestureRecognizerBlockKey, handler, .OBJC_ASSOCIATION_COPY)
        addTarget(self, action: #selector(actionTap(sender:)))
    }
    
    @objc func actionTap(sender:AnyObject) {
        let block:TapedBlock = objc_getAssociatedObject(self, &AssociatedKeys.UIGestureRecognizerBlockKey) as! TapedBlock
        block(sender)
    }
}
