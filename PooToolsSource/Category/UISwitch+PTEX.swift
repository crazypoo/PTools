//
//  UISwitch+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/15.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public typealias SwitchBlock = (_ sender:UISwitch) -> Void

public extension UISwitch {
    
    private struct AssociatedKeys {
        static var UISwitchBlockKey = 998
    }
    
    @objc func addSwitchAction(handler:@escaping SwitchBlock) {
        objc_setAssociatedObject(self, &AssociatedKeys.UISwitchBlockKey, handler, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        addTarget(self, action: #selector(actionValue), for: .valueChanged)
    }
    
    @objc private func actionValue() {
        if let block = objc_getAssociatedObject(self, &AssociatedKeys.UISwitchBlockKey) as? SwitchBlock {
            block(self)
        }
    }
}
