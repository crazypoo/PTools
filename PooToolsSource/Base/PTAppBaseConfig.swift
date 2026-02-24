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
    public var defaultPlaceholderImage:UIImage = UIImage()
    ///没有获取到图片
    public var defaultEmptyImage:UIImage = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_placeholder")
    ///图片加载的进度条框颜色
    public var loadImageProgressBorderColor:UIColor = .purple
    public var loadImageProgressBorderWidth:CGFloat = 1.5
    public var loadImageShowValueLabel:Bool = false
    public var loadImageShowValueFont:UIFont = .appfont(size: 16)
    public var loadImageShowValueColor:UIColor = .white
    public var loadImageShowValueUniCount:Int = 0
    
    //MARK: App的全局邊距
    ///App的全局邊距
    public var defaultViewSpace:CGFloat = CGFloat.ScaleW(w: 10)
    
    public var navContainerSpacing:CGFloat = CGFloat.ScaleW(w: 8)
    public var navBarButtonSpacing:CGFloat = CGFloat.ScaleW(w: 8)

    //MARK: App的全局背景顏色
    ///App的全局背景顏色
    public var viewControllerBaseBackgroundColor:UIColor = PTDarkModeOption.colorLightDark(lightColor: UIColor(hexString:"#eeeff4")!, darkColor: .black)
    public var viewDefaultTextColor:UIColor = PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)

    //MARK: App全局的导航栏返回按钮
    ///App全局的导航栏返回按钮
    public var navGradientBack26Image:UIImage = UIImage()
    public var navGradientBackImage:UIImage = UIImage()
    public var viewControllerBackItemImage:UIImage = UIImage(.chevron.left)
    public var viewControllerBackDarkItemImage:UIImage = UIImage(.chevron.left)
    public var navTitleFont:UIFont = .appfont(size: 24)
    public var navTitleTextColor:UIColor = PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)
    public var navBackgroundColor:UIColor = PTDarkModeOption.colorLightDark(lightColor: UIColor(hexString:"#eeeff4")!, darkColor: .black)
    public var hidesBarsOnSwipe:Bool = false
    public var navGradientColors:[UIColor] = []
    public var bavTitleContainerHeight:CGFloat = 32
    
    //MARK: 权限请求配置
    public var permissionTitleFont:UIFont = .appfont(size: 16,bold:true)
    public var permissionTitleColor:UIColor = .black
    public var permissionSubtitleFont:UIFont = .appfont(size: 14)
    public var permissionSubtitleColor:UIColor = .black
    public var permissionDeniedColor:UIColor = .red
    public var permissionNotSupportColor:UIColor = .lightGray
    public var permissionAuthorizedButtonFont:UIFont = .appfont(size: 14)
    public var permissionCellTitleFont:UIFont = .appfont(size: 14)
    public var permissionCellTitleTextColor:UIColor = .black
    public var permissionCellSubtitleFont:UIFont = .appfont(size: 12)
    public var permissionCellSubtitleTextColor:UIColor = .black
    
    //MARK: Collection
    public var decorationBackgroundColor:UIColor = UIColor.white
    public var decorationBackgroundCornerRadius:CGFloat = CGFloat.ScaleW(w: 10)
    public var baseCellHeight:CGFloat = CGFloat.ScaleW(w: 54)
    public var baseCellBackgroundColor:UIColor = PTDarkModeOption.colorLightDark(lightColor: .white, darkColor: .Black25PercentColor)
    //MARK: ScreenShot
    public var screenShotShare:Any = UIImage(.square.andPencil) as Any
    public var screenShotFeedback:Any = UIImage(.square.andArrowUp) as Any

    //MARK: App的隐私连接
    public var privacyURL:String = "https://www.qq.com"
    public var privacyNameFont:UIFont = .appfont(size: 13)

    //MARK: SDWebImage的加载失误图片方式(全局控制)
    ///SDWebImage的加载失误图片方式(全局控制)
    public var loadImageRetryMaxCount:Int = 3
    public var loadImageRetryInerval:TimeInterval = 2
    public func gobalWebImageLoadOption(maxCount:Int = PTAppBaseConfig.share.loadImageRetryMaxCount,retryInterval:TimeInterval = PTAppBaseConfig.share.loadImageRetryInerval) -> KingfisherOptionsInfo {
#if POOTOOLS_DEBUG
        PTDevFunction.gobalWebImageLoadOption()
#else
        return [KingfisherOptionsInfoItem.cacheOriginalImage,KingfisherOptionsInfoItem.backgroundDecode,KingfisherOptionsInfoItem.retryStrategy(DelayRetryStrategy(maxRetryCount: maxCount, retryInterval: .seconds(retryInterval)))]
#endif
    }
    
    //MARK: 在AppStore上用来检测更新的AppID
    public var appID:String = ""
    
    //MARK: 錯誤上傳地址
    public var MXMetricKitUploadAddress = ""
    
    public var playerBackItemImage:UIImage = UIImage(.chevron.left)
    public var playerPlayItemPlayImage:UIImage = UIImage(.play)
    public var playerPlayItemPauseImage:UIImage = UIImage(.pause)
    
    public var videoCache:Bool = false
    
    public var tabNormalFont:UIFont = .systemFont(ofSize: 11)
    public var tabSelectedFont:UIFont = .systemFont(ofSize: 11)
    public var tabNormalColor:UIColor = .gray
    public var tabSelectedColor:UIColor = .systemBlue
    public var tabBadgeFont:UIFont = .systemFont(ofSize: 10)
    public var tabBadgeBorderHeight:CGFloat = 1
    public var tabBadgeBorderColor:UIColor = .white
    public var tabTopSpacing:CGFloat = 5
    public var tabContentSpacing:CGFloat = 2
    public var tab26BottomSpacing:CGFloat = 15
    public var tab26Mode:Bool = true
}
