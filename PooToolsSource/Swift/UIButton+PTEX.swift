//
//  UIButton+BlockEX.swift
//  Diou
//
//  Created by ken lam on 2021/10/9.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit


public typealias TouchedBlock = (_ sender:UIButton) -> Void


public extension UIButton
{
    static var UIButtonBlockKey = "UIButtonBlockKey"
    
    @objc func addActionHandlers(handler:@escaping TouchedBlock)
    {
        objc_setAssociatedObject(self, &UIButton.UIButtonBlockKey, handler, .OBJC_ASSOCIATION_COPY)
        self.addTarget(self, action: #selector(self.actionTouched(sender:)), for: .touchUpInside)
    }
    
    @objc func actionTouched(sender:UIButton)
    {
        let block:TouchedBlock = objc_getAssociatedObject(self, &UIButton.UIButtonBlockKey) as! TouchedBlock
        block(sender)
    }
}
