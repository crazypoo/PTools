//
//  CGFloat+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public extension CGFloat
{
    //MARK: 等比例调整
    static func ScaleW(w:CGFloat)->CGFloat
    {
        let width:CGFloat = w * kSCREEN_WIDTH/375
        return width
    }
    
    //MARK: 獲取StatusBar的高度
    ///獲取StatusBar的高度
    /// - Returns: CGFloat
    static func statusBarHeight()->CGFloat
    {
        if #available(iOS 13.0, *)
        {
            let window = UIApplication.shared.windows.first
            let statusBarFrame = window?.windowScene?.statusBarManager?.statusBarFrame
            return statusBarFrame?.height ?? 0
        }
        else
        {
            return kStatusBarHeight
        }
    }
}
