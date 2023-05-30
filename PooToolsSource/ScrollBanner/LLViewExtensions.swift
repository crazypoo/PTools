//
//  LLViewExtensions.swift
//  LLCycleScrollView
//
//  Created by LvJianfeng on 2016/11/22.
//  Copyright © 2016年 LvJianfeng. All rights reserved.
//

import UIKit

// MARK: Frame
extension UIView {
    public var ll_x: CGFloat {
        get {
            self.frame.origin.x
        }
        set(value) {
            self.frame = CGRect(x: value, y: ll_y, width: ll_w, height: ll_h)
        }
    }
    
    public var ll_y: CGFloat {
        get {
            self.frame.origin.y
        }
        set(value) {
            self.frame = CGRect(x: ll_x, y: value, width: ll_w, height: ll_h)
        }
    }
    
    public var ll_w: CGFloat {
        get {
            self.frame.size.width
        } set(value) {
            self.frame = CGRect(x: ll_x, y: ll_y, width: value, height: ll_h)
        }
    }
    
    public var ll_h: CGFloat {
        get {
            self.frame.size.height
        } set(value) {
            self.frame = CGRect(x: ll_x, y: ll_y, width: ll_w, height: value)
        }
    }
}
