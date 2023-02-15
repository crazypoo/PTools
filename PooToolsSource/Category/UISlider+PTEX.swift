//
//  UISlider+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 15/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public typealias SliderBlock = (_ sender:UISlider) -> Void

public extension UISlider
{
    static var UISliderBlockKey = "UISliderBlockKey"
    
    @objc func addSliderAction(handler:@escaping SliderBlock)
    {
        objc_setAssociatedObject(self, &UISlider.UISliderBlockKey, handler, .OBJC_ASSOCIATION_COPY)
        self.addTarget(self, action: #selector(self.actionValue(sender:)), for: .valueChanged)
    }
    
    @objc func actionValue(sender:UISlider)
    {
        let block:SliderBlock = objc_getAssociatedObject(self, &UISlider.UISliderBlockKey) as! SliderBlock
        block(sender)
    }
}
