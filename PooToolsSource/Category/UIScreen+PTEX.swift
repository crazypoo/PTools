//
//  UIScreen+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 9/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public extension UIScreen {
    
    //MARK: 獲取屏幕的Size
    /// 獲取屏幕的Size
    static var size: CGSize {
        UIScreen.main.bounds.size
    }
    
    //MARK: 獲取豎屏的尺寸
    ///獲取豎屏的尺寸
    static var portraitSize: CGSize {
        CGSize(width: UIScreen.main.nativeBounds.width / UIScreen.main.nativeScale,
                height: UIScreen.main.nativeBounds.height / UIScreen.main.nativeScale)
    }
    
    static var hasRoundedCorners = UIScreen.main.value(forKey: "_" + "display" + "Corner" + "Radius") as! CGFloat > 0
}
