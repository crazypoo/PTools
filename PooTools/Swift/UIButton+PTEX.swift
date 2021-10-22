//
//  UIButton+BlockEX.swift
//  Diou
//
//  Created by ken lam on 2021/10/9.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit

typealias TouchedBlock = (_ seder:UIButton) -> Void

extension UIButton
{
    static var UIButtonBlockKey = "UIButtonBlockKey"
    
    func addActionHandler(handler:@escaping TouchedBlock)
    {
        objc_setAssociatedObject(self, &UIButton.UIButtonBlockKey, handler, .OBJC_ASSOCIATION_COPY)
        self.addTarget(self, action: #selector(self.actionTouched(sender:)), for: .touchUpInside)
    }
    
    @objc func actionTouched(sender:UIButton)
    {
        let block:TouchedBlock = objc_getAssociatedObject(self, &UIButton.UIButtonBlockKey) as! TouchedBlock
        if block != nil
        {
            block(sender)
        }
    }
}
