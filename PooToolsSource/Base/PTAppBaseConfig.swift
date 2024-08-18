//
//  PTAppBaseConfig.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import Kingfisher
import SafeSFSymbols

@objcMembers
public class PTAppBaseConfig: NSObject {
    public static let share = PTAppBaseConfig()
    
    //MARK: App的全局加載圖片的底圖
    ///App的全局加載圖片的底圖
    open var defaultPlaceholderImage:UIImage = UIImage()
    ///没有获取到图片
    open var defaultEmptyImage:UIImage = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_placeholder")
    //MARK: App的全局邊距
    ///App的全局邊距
    open var defaultViewSpace:CGFloat = CGFloat.ScaleW(w: 10)
    
    //MARK: App的全局背景顏色
    ///App的全局背景顏色
    open var viewControllerBaseBackgroundColor:UIColor = PTDarkModeOption.colorLightDark(lightColor: UIColor(hexString:"#eeeff4")!, darkColor: .black)
    open var viewDefaultTextColor:UIColor = PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)

    //MARK: App全局的导航栏返回按钮
    ///App全局的导航栏返回按钮
    open var viewControllerBackItemImage:UIImage = UIImage(.chevron.left)
    open var navTitleFont:UIFont = .appfont(size: 24)
    open var navTitleTextColor:UIColor = PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)
    open var navBackgroundColor:UIColor = PTDarkModeOption.colorLightDark(lightColor: UIColor(hexString:"#eeeff4")!, darkColor: .black)
    open var hidesBarsOnSwipe:Bool = false
    
    //MARK: 权限请求配置
    open var permissionTitleFont:UIFont = .appfont(size: 16,bold:true)
    open var permissionTitleColor:UIColor = .black
    open var permissionSubtitleFont:UIFont = .appfont(size: 14)
    open var permissionSubtitleColor:UIColor = .black
    open var permissionDeniedColor:UIColor = .red
    open var permissionNotSupportColor:UIColor = .lightGray
    open var permissionAuthorizedButtonFont:UIFont = .appfont(size: 14)
    open var permissionCellTitleFont:UIFont = .appfont(size: 14)
    open var permissionCellTitleTextColor:UIColor = .black
    open var permissionCellSubtitleFont:UIFont = .appfont(size: 12)
    open var permissionCellSubtitleTextColor:UIColor = .black
    
    //MARK: Collection
    open var decorationBackgroundColor:UIColor = UIColor.white
    open var decorationBackgroundCornerRadius:CGFloat = CGFloat.ScaleW(w: 10)
    open var baseCellHeight:CGFloat = CGFloat.ScaleW(w: 54)
    open var baseCellBackgroundColor:UIColor = PTDarkModeOption.colorLightDark(lightColor: .white, darkColor: .Black25PercentColor)
    //MARK: ScreenShot
    open var screenShotShare:Any = UIImage(.square.andPencil) as Any
    open var screenShotFeedback:Any = UIImage(.square.andArrowUp) as Any

    //MARK: App的隐私连接
    open var privacyURL:String = "https://www.qq.com"
    open var privacyNameFont:UIFont = .appfont(size: 13)

    //MARK: SDWebImage的加载失误图片方式(全局控制)
    ///SDWebImage的加载失误图片方式(全局控制)
    open var loadImageRetryMaxCount:Int = 3
    open var loadImageRetryInerval:TimeInterval = 2
    public func gobalWebImageLoadOption(maxCount:Int = PTAppBaseConfig.share.loadImageRetryMaxCount,retryInterval:TimeInterval = PTAppBaseConfig.share.loadImageRetryInerval) -> KingfisherOptionsInfo {
#if DEBUG
        PTDevFunction.gobalWebImageLoadOption()
#else
        return [KingfisherOptionsInfoItem.cacheOriginalImage,KingfisherOptionsInfoItem.backgroundDecode,KingfisherOptionsInfoItem.retryStrategy(DelayRetryStrategy(maxRetryCount: maxCount, retryInterval: .seconds(retryInterval)))]
#endif
    }
    
    //MARK: 在AppStore上用来检测更新的AppID
    open var appID:String = ""
    
    //MARK: FloatingPanelViewController顶部站位大小
    open var fpcSurfaceShadowBaseSize:CGSize = CGSize(width: 0, height: 16)
}
