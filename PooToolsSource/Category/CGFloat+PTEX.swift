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
    //MARK: 獲取屏幕寬度
    ///獲取屏幕寬度
    static let kSCREEN_WIDTH = kSCREEN_SIZE.width
    
    //MARK: 獲取屏幕高度
    ///獲取屏幕高度
    static let kSCREEN_HEIGHT = kSCREEN_SIZE.height
    
    //MARK: 等比例调整
    ///等比例调整
    /// - Returns: CGFloat
    static func ScaleW(w:CGFloat)->CGFloat
    {
        let width:CGFloat = w * self.kSCREEN_WIDTH/375
        return width
    }

    //MARK: 獲取導航欄Bar高度
    ///獲取導航欄Bar高度
    static let kNavBarHeight:CGFloat = 44
    
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
            return isXModel ? 44 : 20
        }
    }
    
    //MARK: 獲取導航欄總高度
    ///獲取導航欄總高度
    static let kNavBarHeight_Total:CGFloat = CGFloat.kNavBarHeight + CGFloat.statusBarHeight()

    //MARK: Tabbar安全高度
    ///Tabbar安全高度
    static let kTabbarSaveAreaHeight:CGFloat = isXModel ? 34 : 0
    //MARK: Tabbar高度
    ///Tabbar高度
    static let kTabbarHeight:CGFloat = 49
    //MARK: Tabbar總高度
    ///Tabbar總高度
    static let kTabbarHeight_Total = CGFloat.kTabbarSaveAreaHeight + CGFloat.kTabbarHeight

}
