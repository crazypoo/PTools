//
//  PTAppBaseConfig.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import Kingfisher

@objcMembers
public class PTAppBaseConfig: NSObject {
    public static let share = PTAppBaseConfig()
    
    //MARK: App的全局加載圖片的底圖
    ///App的全局加載圖片的底圖
    public var defaultPlaceholderImage:UIImage = UIImage()
    //MARK: App的全局邊距
    ///App的全局邊距
    public var defaultViewSpace:CGFloat = CGFloat.ScaleW(w: 10)
    
    //MARK: App的全局背景顏色
    ///App的全局背景顏色
    public var viewControllerBaseBackgroundColor:UIColor = UIColor(hexString:"#eeeff4")!
    
    //MARK: App全局的导航栏返回按钮
    ///App全局的导航栏返回按钮
    public var viewControllerBackItemImage:UIImage = UIImage(systemName: "chevron.left")!
    public var navTitleFont:UIFont = .appfont(size: 24)
    
    //MARK: 权限请求配置
    public var permissionTitleFont:UIFont = .appfont(size: 16,bold:true)
    public var permissionTitleColor:UIColor = .black
    public var permissionSubtitleFont:UIFont = .appfont(size: 14)
    public var permissionSubtitleColor:UIColor = .black
    public var permissionDeniedColor:UIColor = .red
    public var permissionAuthorizedButtonFont:UIFont = .appfont(size: 14)
    public var permissionCellTitleFont:UIFont = .appfont(size: 14)
    public var permissionCellTitleTextColor:UIColor = .black
    public var permissionCellSubtitleFont:UIFont = .appfont(size: 12)
    public var permissionCellSubtitleTextColor:UIColor = .black
    
    //MARK: Collection
    public var decorationBackgroundColor:UIColor = UIColor.white
    public var decorationBackgroundCornerRadius:CGFloat = CGFloat.ScaleW(w: 10)
    public var baseCellHeight:CGFloat = CGFloat.ScaleW(w: 54)
    
    //MARK: ScreenShot
    public var screenShotShare:Any = UIImage(systemName: "square.and.pencil") as Any
    public var screenShotFeedback:Any = UIImage(systemName: "square.and.arrow.up") as Any

    //MARK: SDWebImage的加载失误图片方式(全局控制)
    ///SDWebImage的加载失误图片方式(全局控制)
    public func gobalWebImageLoadOption()->KingfisherOptionsInfo {
        PTDevFunction.gobalWebImageLoadOption()
    }
}
