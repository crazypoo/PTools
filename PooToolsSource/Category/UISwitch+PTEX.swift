//
//  UISwitch+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/15.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public typealias SwitchBlock = (_ sender:UISwitch) -> Void

public extension UISwitch
{
    static var UISwitchBlockKey = "UISwitchBlockKey"
    
    @objc func addSwitchAction(handler:@escaping SwitchBlock)
    {
        objc_setAssociatedObject(self, &UISwitch.UISwitchBlockKey, handler, .OBJC_ASSOCIATION_COPY)
        self.addTarget(self, action: #selector(self.actionValue(sender:)), for: .valueChanged)
    }
    
    @objc func actionValue(sender:UISwitch)
    {
        let block:SwitchBlock = objc_getAssociatedObject(self, &UISwitch.UISwitchBlockKey) as! SwitchBlock
        block(sender)
    }
}
