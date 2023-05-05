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
    static var UIGestureRecognizerBlockKey = "UIGestureRecognizerBlockKey"
    
    @objc convenience init(actionBlock:@escaping TapedBlock) {
        self.init()
        self.addGesActionHandlers(handler: actionBlock)
    }
    
    @objc func addGesActionHandlers(handler:@escaping TapedBlock) {
        objc_setAssociatedObject(self, &UIGestureRecognizer.UIGestureRecognizerBlockKey, handler, .OBJC_ASSOCIATION_COPY)
        self.addTarget(self, action: #selector(self.actionTap(sender:)))
    }
    
    @objc func actionTap(sender:AnyObject) {
        let block:TapedBlock = objc_getAssociatedObject(self, &UIGestureRecognizer.UIGestureRecognizerBlockKey) as! TapedBlock
        block(sender)
    }
}
