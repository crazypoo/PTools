//
//  PT.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 9/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit
import SwifterSwift

/// 服务路由
public var serivceHost = "scheme://services?"

/// web跳转路由
public var webRouterUrl = "scheme://webview/home"

open class PTAppWindowsDelegate: PTAppDelegate {
    
    public var isFullScreen:Bool = false
    
#if POOTOOLS_DEBUG
#endif
    open func makeKeyAndVisible(createViewControllerHandler: () -> UIViewController, tint: UIColor) {
#if POOTOOLS_DEBUG
        if UIApplication.shared.inferredEnvironment != .appStore && UIApplication.shared.inferredEnvironment != .testFlight {
            window = TouchInspectorWindow(frame: UIScreen.main.bounds)
            (window as! TouchInspectorWindow).showTouches = PTCoreUserDefultsWrapper.AppTouchInspectShow
            (window as! TouchInspectorWindow).showHitTesting = PTCoreUserDefultsWrapper.AppTouchInspectShowHits
            window?.tintColor = tint
        } else {
            window = UIWindow.init(frame: UIScreen.main.bounds)
        }
#else
        window = UIWindow.init(frame: UIScreen.main.bounds)
#endif
        window?.tintColor = tint
        window?.rootViewController = createViewControllerHandler()
        window?.makeKeyAndVisible()
    }

    open func makeKeyAndVisible(viewController: UIViewController, tint: UIColor) {
        makeKeyAndVisible(createViewControllerHandler: {
            return viewController
        }, tint: tint)
    }
    
#if POOTOOLS_DEBUG
    open func createDevFunction(flex:PTActionTask? = nil,inApp:PTActionTask? = nil,Hyperion:PTActionTask? = nil,FoxNet:PTActionTask? = nil) {
        if UIApplication.shared.inferredEnvironment != .appStore && UIApplication.shared.inferredEnvironment != .testFlight {
            
            let lcm = LocalConsole.shared
            lcm.isVisible = PTCoreUserDefultsWrapper.AppDebugMode
            lcm.flex = flex
            lcm.watchViews = inApp
            lcm.HyperioniOS = Hyperion
            lcm.FoxNet = FoxNet
        }
    }
#endif
    
#if POOTOOLS_ROTATION
    open func registerRotation() {
        PTRotationManager.share.interfaceOrientationMask = .portrait
    }
#endif
    
#if POOTOOLS_ROUTER
    open func registerRouter(PrifxArray:[String]? = [".Jax"]) {
        PTRouter.lazyRegisterRouterHandle { url ,userInfo in
            PTRouter.injectRouterServiceConfig(webRouterUrl, serivceHost)
            return PTRouterManager.addGloableRouter(PrifxArray!, url, userInfo)
        }
        PTRouterManager.registerServices()
        PTRouter.logcat { url, logType, errorMsg in
            PTNSLogConsole("PTRouter: logMsg- \(url) \(logType.rawValue) \(errorMsg)")
        }
    }
#endif

    open func createSettingBundle() {
        if UIApplication.shared.inferredEnvironment != .appStore && UIApplication.shared.inferredEnvironment != .testFlight {
#if POOTOOLS_DEBUG
            PTDebugFunction.registerDefaultsFromSettingsBundle()
#endif
        }
    }
    
    public func faceOrientationMask(app:UIApplication,
                                    windos:UIWindow) -> UIInterfaceOrientationMask {
        if isFullScreen {
            if #available(iOS 16.0, *) {
                return .landscape
            } else {
                return .landscapeRight
            }
        }
        return .portrait
    }
}

//MARK: 全局参数
extension PTAppWindowsDelegate {
    public override class func appDelegate() -> PTAppWindowsDelegate? {
        UIApplication.shared.delegate as? PTAppWindowsDelegate
    }
}

//MARK: 旋转
extension PTAppWindowsDelegate {
    open func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
#if POOTOOLS_ROTATION
        PTRotationManager.share.interfaceOrientationMask
#else
        return .portrait
#endif
    }
}
#endif
