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
        let result = FileManager.pt.removefolder(folderPath: FileManager.pt.homeDirectory() + "/Library/SplashBoard")
        if !result.isSuccess {
            PTNSLogConsole("Failed to delete launch screen cache: \(result.error)",levelType: .error,loggerType: .uiApplication)
        }
    }
    
    //MARK: 獲取軟件的開髮狀態
    ///獲取軟件的開髮狀態
    class func applicationEnvironment() -> Environment {
        UIApplication.shared.inferredEnvironment_PT
    }
    
    class func applicationEnvironmentAsync() async -> Environment {
        // 在主線程異步更新 environment
        return await withCheckedContinuation { continuation in
            PTGCDManager.gcdMain {
                let environment = UIApplication.shared.inferredEnvironment_PT
                continuation.resume(returning: environment)
            }
        }
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
    
    var currentWindows:[UIWindow]? {
        return connectedScenes
            .compactMap { $0 as? UIWindowScene }
        // ❗ 不再只限制 foregroundActive
            .filter { $0.activationState != .background }
            .first?
            .windows
    }
    
    var currentWindow: UIWindow? {
        // 1️⃣ 先按你原逻辑找 keyWindow
        if let keyWindow = currentWindows?.first(where: { $0.isKeyWindow }) {
            return keyWindow
        }

        // 2️⃣ 如果没有 keyWindow，取当前 scene 的第一个 window
        if let firstWindow = currentWindows?.first {
            return firstWindow
        }

        // 3️⃣ 最后 fallback 到你原来的 sceneDelegate 逻辑
        return PTWindowSceneDelegate.sceneDelegate()?.window
    }
        
    // MARK: - 内部缓存机制 (核心优化部分)
    /// 使用私有结构体和静态常量来缓存应用信息，确保高开销的 I/O 操作只执行一次
    private struct AppInfoCache {
        
        static let inferredEnvironment: Environment = {
            #if DEBUG
            return .debug
            #elseif targetEnvironment(simulator)
            return .debug
            #else
            // 检查是否包含内嵌的 provision 文件 (TestFlight)
            if Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") != nil {
                return .testFlight
            }

            guard let appStoreReceiptUrl = Bundle.main.appStoreReceiptURL else {
                return .debug
            }

            let receiptPath = appStoreReceiptUrl.lastPathComponent.lowercased()
            if receiptPath == "sandboxreceipt" {
                return .testFlight
            }

            if appStoreReceiptUrl.path.lowercased().contains("simulator") {
                return .debug
            }

            return .appStore
            #endif
        }()
        
        static let displayName: String? = {
            return Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        }()
        
        static let buildNumber: String? = {
            return Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
        }()
        
        static let version: String? = {
            return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        }()
    }

    // MARK: - 公开属性 (API 保持不变)
    var inferredEnvironment_PT: Environment {
        return AppInfoCache.inferredEnvironment
    }

    var displayName_PT: String? {
        return AppInfoCache.displayName
    }

    var buildNumber_PT: String? {
        return AppInfoCache.buildNumber
    }

    var version_PT: String? {
        return AppInfoCache.version
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
            PTNSLogConsole("you can change this app's icon",levelType: PTLogMode,loggerType: .uiApplication)
        } else {
            PTNSLogConsole("you can not change this app's icon",levelType: PTLogMode,loggerType: .uiApplication)
            return
        }
        
        UIApplication.shared.setAlternateIconName(name) { error in
            if error != nil {
                UIViewController.gobal_drop(title: error.debugDescription)

            }
            PTNSLogConsole("The alternate icon's name is \(String(describing: name))",levelType: PTLogMode,loggerType: .uiApplication)
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
        return AppWindows?.safeAreaInsets.top ?? 0
    }
}
