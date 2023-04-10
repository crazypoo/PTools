//
//  Application+PTEX.swift
//  PooTools_Example
//
//  Created by jax on 2022/9/30.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

extension UIApplication: PTProtocolCompatible { }

public extension PTProtocol where Base: UIApplication {
    //MARK: 获取应用的location
    ///获取应用的location
    static var currentApplicationLocal:String {
        let locale:NSLocale = NSLocale.current as NSLocale
        let countryCode = locale.object(forKey: NSLocale.Key.countryCode)
        let usLocale = NSLocale.init(localeIdentifier: "en_US")
        let country = usLocale.displayName(forKey: NSLocale.Key.countryCode, value: countryCode!)
        return country!
    }
    
    /*! @brief iOS更换App图标
     * @attention 此方法必须在info.plist中添加Icon files (iOS 5)字段，k&vCFBundleAlternateIcons ={IconName={CFBundleIconFiles =(IconName);UIPrerenderedIcon = 0;};};CFBundlePrimaryIcon={CFBundleIconFiles=(AppIcon20x20,AppIcon29x29,AppIcon40x40,AppIcon60x60);};
     */
    //MARK: iOS更换App图标
    ///iOS更换App图标
    static func changeAppIcon(with name:String? = nil) {
        if UIApplication.shared.supportsAlternateIcons {
            PTNSLogConsole("you can change this app's icon")
        } else {
            PTNSLogConsole("you can not change this app's icon")
            return
        }
        
        UIApplication.shared.setAlternateIconName(name) { error in
            if error != nil {
                UIViewController.gobal_drop(title: error.debugDescription)

            }
            PTNSLogConsole("The alternate icon's name is \(String(describing: name))")
        }
    }
    
    //MARK: 类似iPhone点击了Home键
    ///类似iPhone点击了Home键
    static func likeTapHome() {
        PTGCDManager.gcdMain {
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
        }
    }
}

@available(iOSApplicationExtension, unavailable)
public extension UIApplication {
    var statusBarHeight: CGFloat {
        if let window = UIApplication.shared.windows.first {
            return window.safeAreaInsets.top
        } else {
            return 0
        }
    }
}
