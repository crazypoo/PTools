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
            let environment = UIApplication.shared.inferredEnvironment_PT

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
            let environment = UIApplication.shared.inferredEnvironment_PT
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
//        // 1. 基础配置
//        PTRouter.shareInstance.webPath = "scheme://webview/home" // 原 webRouterUrl
//        // ⚠️ serviceHost 概念已经被 PTServiceActionMapper 彻底淘汰，无需再配置！
//
//        // 2. 日志监听 (保留你的原味，去掉了 .rawValue 因为现在可以利用 CustomStringConvertible)
//        PTRouter.shareInstance.logcat { url, logType, errorMsg in
//            PTNSLogConsole("PTRouter: logMsg- \(url) \(logType) \(errorMsg)", levelType: .notice, loggerType: .router)
//        }
//
//        // ---------------------------------------------------------
//        // 下面是用来替代原先 loadRouterClass 和 registerServices 的现代做法
//        // ---------------------------------------------------------
//
//        // 3. 显式注册页面路由 (搭配全新的正则引擎)
//        // 以后每写一个新页面，在这里（或对应的业务模块入口）注册一行即可
//        PTRouter.addRouterItem("scheme://home", classString: "MyApp.HomeViewController")
//        PTRouter.addRouterItem("scheme://goods/:id", classString: "MyApp.GoodsDetailVC") // 支持正则动态参数
//
//        // 4. 显式注册本地强类型服务
//        PTRouterServiceManager.shared.registerService(UserServiceProtocol.self) {
//            return UserServiceImpl()
//        }
//        
//        // 5. 显式注册需要暴露给 H5/外部组件 的动态调用动作
//        PTServiceActionMapper.shared.register(protocolName: "User", methodName: "getUserInfo") { param, _ in
//            guard let userService = PTRouterServiceManager.shared.getService(UserServiceProtocol.self) else { return nil }
//            return userService.getUserInfo(id: param as? String ?? "")
//        }
//        
//        // 6. (新增福利) 注册异步拦截器
//        PTRouter.addAsyncInterceptor(LoginInterceptor())
    }
#endif

    public func createSettingBundle() {
        Task {
            let environment = UIApplication.shared.inferredEnvironment_PT
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
