//
//  UISlider+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 15/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public typealias SliderBlock = (_ sender:UISlider) -> Void

public extension UISlider {
    
    private struct AssociatedKeys {
        static var UISliderBlockKey = 998
    }

    @objc func addSliderAction(handler:@escaping SliderBlock) {
        objc_setAssociatedObject(self, &AssociatedKeys.UISliderBlockKey, handler, .OBJC_ASSOCIATION_COPY)
        addTarget(self, action: #selector(actionValue(sender:)), for: .valueChanged)
    }
    
    @objc func actionValue(sender:UISlider) {
        let block:SliderBlock = objc_getAssociatedObject(self, &AssociatedKeys.UISliderBlockKey) as! SliderBlock
        block(sender)
    }
}
