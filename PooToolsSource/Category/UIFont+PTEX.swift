//
//  UIFont+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

//MARK: 全局统一字体
public extension UIFont
{
    class func appfont(size:CGFloat,bold:Bool? = false)-> UIFont
    {
        if !bold!
        {
            return UIFont.systemFont(ofSize: CGFloat.ScaleW(w: size))
        }
        else
        {
            return UIFont.boldSystemFont(ofSize: CGFloat.ScaleW(w: size))
        }
    }
    
    @objc class func oc_appFont(size:CGFloat,bold:Bool)->UIFont
    {
        return self.appfont(size: size,bold: bold)
    }
    
    @objc class func appCustomFont(size:CGFloat,customFont:String? = nil)-> UIFont
    {
        return UIFont.init(name: customFont!, size: CGFloat.ScaleW(w: size))!
    }
}
