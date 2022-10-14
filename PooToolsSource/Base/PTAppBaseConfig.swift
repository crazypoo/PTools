//
//  PTAppBaseConfig.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SDWebImage

@objcMembers
public class PTAppBaseConfig: NSObject {
    public static let share = PTAppBaseConfig()
    
    public var defaultPlaceholderImage:UIImage = UIImage()
    public var defaultViewSpace:CGFloat = CGFloat.ScaleW(w: 10)
    
    //MARK:
    public var viewControllerBaseBackgroundColor:UIColor = .lightGray
    
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
    
    //MARK:SDWebImage的加载失误图片方式(全局控制)
    ///SDWebImage的加载失误图片方式(全局控制)
    public func gobalWebImageLoadOption()->SDWebImageOptions
    {
        #if DEBUG
        let userDefaults = UserDefaults.standard.value(forKey: "sdwebimage_option")
        let devServer:Bool = userDefaults == nil ? true : (userDefaults as! Bool)
        if devServer
        {
            return .retryFailed
        }
        else
        {
            return .lowPriority
        }
        #else
        return .retryFailed
        #endif
    }

    class open func registerDefaultsFromSettingsBundle()
    {
        if let settingsBundle = Bundle.main.path(forResource: "Settings", ofType: "bundle")
        {
            let settings = NSDictionary.init(contentsOfFile: settingsBundle.nsString.appendingPathComponent("Root.plist"))
            let prefernces = settings!["PreferenceSpecifiers"] as! [NSDictionary]
            let defaultsToRegister = NSMutableDictionary.init(capacity: prefernces.count)
            for prefSpecification in prefernces
            {
                if let key :String = prefSpecification["Key"] as? String
                {
                    defaultsToRegister[key] = prefSpecification["DefaultValue"]
                }
            }
            UserDefaults.standard.register(defaults: defaultsToRegister as! [String : Any])
        }
        else
        {
            UserDefaults.standard.setValue(nil, forKey: "AppServiceIdentifier")
            PTLocalConsoleFunction.share.pNSLog("没有发现Settings.bundle")
        }
    }
}
