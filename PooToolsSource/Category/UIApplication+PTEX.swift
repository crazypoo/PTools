//
//  UIApplication+EX.swift
//  Diou
//
//  Created by ken lam on 2021/10/18.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import SwifterSwift

extension UIApplication: PTProtocolCompatible { }

public extension UIApplication {
    @objc func clearLaunchScreenCache() {
        do {
            try FileManager.default.removeItem(atPath: NSHomeDirectory()+"/Library/SplashBoard")
        } catch {
            PTNSLogConsole("Failed to delete launch screen cache: \(error)",levelType: .Error,loggerType: .UIApplication)
        }
    }
    
    //MARK: 獲取軟件的開髮狀態
    ///獲取軟件的開髮狀態
    class func applicationEnvironment() -> Environment {
        var environment: Environment!
        PTGCDManager.gcdMain {
            environment = UIApplication.shared.inferredEnvironment
        }
        return environment
    }

    /// Overrides the user interface style adopted by all windows in all connected scenes.
    /// - Parameter userInterfaceStyle: The user interface style adopted by all windows in all connected scenes.
    func override(_ userInterfaceStyle: UIUserInterfaceStyle) {
        for connectedScene in connectedScenes {
            if let scene = connectedScene as? UIWindowScene {
                scene.windows.override(userInterfaceStyle)
            }
        }
    }
}

public extension PTPOP where Base: UIApplication {
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
            PTNSLogConsole("you can change this app's icon",levelType: PTLogMode,loggerType: .UIApplication)
        } else {
            PTNSLogConsole("you can not change this app's icon",levelType: PTLogMode,loggerType: .UIApplication)
            return
        }
        
        UIApplication.shared.setAlternateIconName(name) { error in
            if error != nil {
                UIViewController.gobal_drop(title: error.debugDescription)

            }
            PTNSLogConsole("The alternate icon's name is \(String(describing: name))",levelType: PTLogMode,loggerType: .UIApplication)
        }
    }
    
    //MARK: 类似iPhone点击了Home键
    ///类似iPhone点击了Home键
    static func likeTapHome() {
        PTGCDManager.gcdMain {
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
        }
    }
    
    /// app定位区域
    static var localizations: String? {
        guard let weakInfoDictionary = Bundle.main.infoDictionary, let content = weakInfoDictionary[String(kCFBundleLocalizationsKey)] else {
            return nil
        }
        return (content as! String)
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
