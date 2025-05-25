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
    
    open var isFullScreen:Bool = false
    
#if POOTOOLS_DEBUG
#endif
    public func makeKeyAndVisible(createViewControllerHandler: () -> UIViewController, tint: UIColor) {
#if POOTOOLS_DEBUG
        Task {
            let environment = UIApplication.shared.inferredEnvironment

            switch environment {
            case .appStore,.testFlight:
                window = UIWindow(frame: UIScreen.main.bounds)
            default:
                window = TouchInspectorWindow(frame: UIScreen.main.bounds)
                (window as! TouchInspectorWindow).showTouches = PTCoreUserDefultsWrapper.AppTouchInspectShow
                (window as! TouchInspectorWindow).showHitTesting = PTCoreUserDefultsWrapper.AppTouchInspectShowHits
                window?.tintColor = tint
            }
        }
#else
        window = UIWindow(frame: UIScreen.main.bounds)
#endif
        window?.tintColor = tint
        window?.rootViewController = createViewControllerHandler()
        window?.makeKeyAndVisible()
    }

    public func makeKeyAndVisible(viewController: UIViewController, tint: UIColor) {
        makeKeyAndVisible(createViewControllerHandler: {
            viewController
        }, tint: tint)
    }
    
#if POOTOOLS_DEBUG
    public func createDevFunction() {
        Task {
            let environment = UIApplication.shared.inferredEnvironment
            switch environment {
            case .appStore,.testFlight:
                break
            default:
                let lcm = LocalConsole.shared
                lcm.isVisiable = PTCoreUserDefultsWrapper.AppDebugMode
            }
        }
    }
#endif
    
    public func registerRotation(changeCallBack:((_ orientationMask: UIInterfaceOrientationMask) -> ())? = nil) {
        PTRotationManager.shared.isLockOrientationWhenDeviceOrientationDidChange = false
        PTRotationManager.shared.isLockLandscapeWhenDeviceOrientationDidChange = false
        PTRotationManager.shared.orientationMaskDidChange = changeCallBack
    }
    
#if POOTOOLS_ROUTER
    public func registerRouter(PrifxArray:[String]? = [".Jax"]) {
        PTRouterManager.loadRouterClass(excludeCocoapods: true, useCache: true)
        PTRouter.lazyRegisterRouterHandle { url ,userInfo in
            PTRouter.injectRouterServiceConfig(webRouterUrl, serivceHost)
            return PTRouterManager.addGloableRouter(true, url, userInfo,forceCheckEnable: true)
        }
        PTRouterManager.registerServices(excludeCocoapods: true)
        PTRouter.logcat { url, logType, errorMsg in
            PTNSLogConsole("PTRouter: logMsg- \(url) \(logType.rawValue) \(errorMsg)",levelType: .Notice,loggerType: .Router)
        }
    }
#endif

    public func createSettingBundle() {
        Task {
            let environment = UIApplication.shared.inferredEnvironment
            switch environment {
            case .appStore,.testFlight:
                break
            default:
    #if POOTOOLS_DEBUG
                PTDebugFunction.registerDefaultsFromSettingsBundle()
    #endif
            }
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
    open override class func appDelegate() -> PTAppWindowsDelegate? {
        UIApplication.shared.delegate as? PTAppWindowsDelegate
    }
}

//MARK: 旋转
extension PTAppWindowsDelegate {
    open func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return  PTRotationManager.shared.orientationMask
    }
}
#endif
