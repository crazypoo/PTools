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
@MainActor public var serivceHost = "scheme://services?"

/// web跳转路由
@MainActor public var webRouterUrl = "scheme://webview/home"

@MainActor
open class PTAppWindowsDelegate: PTAppDelegate {
    
    open var isFullScreen:Bool = false

    // English: Create the application window in the scene supplied by UIKit.
    // Español: Crea la ventana de la aplicación en la escena proporcionada por UIKit.
    // 中文：在 UIKit 提供的场景中创建应用窗口。
    public func makeKeyAndVisible(in scene: UIWindowScene,
                                  createViewControllerHandler: () -> UIViewController,
                                  tint: UIColor) {
        window = PTUIKitRuntimeHooks.makeApplicationWindow?(scene)
            ?? UIWindow(windowScene: scene)
        window?.tintColor = tint
        window?.rootViewController = createViewControllerHandler()
        window?.makeKeyAndVisible()
    }

    // English: Keep the view-controller convenience overload tied to the same explicit scene path.
    // Español: Mantén la sobrecarga conveniente del controlador ligada a la misma ruta de escena explícita.
    // 中文：让控制器便捷重载同样走明确场景的创建路径。
    public func makeKeyAndVisible(in scene: UIWindowScene,
                                  viewController: UIViewController,
                                  tint: UIColor) {
        makeKeyAndVisible(in: scene, createViewControllerHandler: {
            viewController
        }, tint: tint)
    }

    public func makeKeyAndVisible(createViewControllerHandler: () -> UIViewController, tint: UIColor) {
        if let scene = PTSceneContext.activeWindow()?.windowScene
            ?? PTSceneContext.connectedWindowScenes().first(where: {
                $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive
            }) {
            makeKeyAndVisible(in: scene,
                              createViewControllerHandler: createViewControllerHandler,
                              tint: tint)
            return
        }

        // English: A window without a connected scene cannot be presented yet; keep a compatibility placeholder.
        // Español: Una ventana sin escena conectada aún no puede presentarse; conserva un marcador compatible.
        // 中文：没有已连接场景的窗口暂时无法显示，保留兼容占位窗口。
        window = UIWindow(frame: .zero)
        window?.tintColor = tint
        window?.rootViewController = createViewControllerHandler()
    }

    public func makeKeyAndVisible(viewController: UIViewController, tint: UIColor) {
        makeKeyAndVisible(createViewControllerHandler: {
            viewController
        }, tint: tint)
    }
    
    public func createDevFunction() {
        let environment = UIApplication.shared.inferredEnvironment_PT
        switch environment {
        case .appStore,.testFlight:
            break
        default:
            PTUIKitRuntimeHooks.restoreConsoleState?()
        }
    }
    
    public func registerRotation(changeCallBack:((_ orientationMask: UIInterfaceOrientationMask) -> ())? = nil) {
        PTRotationManager.shared.isLockOrientationWhenDeviceOrientationDidChange = false
        PTRotationManager.shared.isLockLandscapeWhenDeviceOrientationDidChange = false
        PTRotationManager.shared.orientationMaskDidChange = changeCallBack
    }
    
#if POOTOOLS_ROUTER
    public func registerRouter(PrifxArray:[String]? = [".Jax"]) {
        // 1. 基础配置
//        PTRouter.shareInstance.webPath = webRouterUrl // 原 webRouterUrl
        // ⚠️ serviceHost 概念已经被 PTServiceActionMapper 彻底淘汰，无需再配置！

        // 2. 日志监听 (保留你的原味，去掉了 .rawValue 因为现在可以利用 CustomStringConvertible)
//        PTRouter.shareInstance.logcat { url, logType, errorMsg in
//            PTNSLogConsole("PTRouter: logMsg- \(url) \(logType) \(errorMsg)", levelType: .notice, loggerType: .router)
//        }

        // ---------------------------------------------------------
        // 下面是用来替代原先 loadRouterClass 和 registerServices 的现代做法
        // ---------------------------------------------------------

        // 3. 显式注册页面路由 (搭配全新的正则引擎)
        // 以后每写一个新页面，在这里（或对应的业务模块入口）注册一行即可
//        PTRouter.addRouterItem("scheme://home", classString: "MyApp.HomeViewController")
//        PTRouter.addRouterItem("scheme://goods/:id", classString: "MyApp.GoodsDetailVC") // 支持正则动态参数

        // 4. 显式注册本地强类型服务
//        PTRouterServiceManager.shared.registerService(UserServiceProtocol.self) {
//            return UserServiceImpl()
//        }
//        
        // 5. 显式注册需要暴露给 H5/外部组件 的动态调用动作
//        PTServiceActionMapper.shared.register(protocolName: "User", methodName: "getUserInfo") { param, _ in
//            guard let userService = PTRouterServiceManager.shared.getService(UserServiceProtocol.self) else { return nil }
//            return userService.getUserInfo(id: param as? String ?? "")
//        }
//        
        // 6.  注册异步拦截器
//        PTRouter.addAsyncInterceptor(LoginInterceptor())
    }
#endif

    public func createSettingBundle() {
        let environment = UIApplication.shared.inferredEnvironment_PT
        switch environment {
        case .appStore,.testFlight:
            break
        default:
            PTUIKitRuntimeHooks.settingsBundleHandler?()
        }
    }
    
    public func faceOrientationMask(app:UIApplication,
                                    windos:UIWindow) -> UIInterfaceOrientationMask {
        if isFullScreen {
            return .landscape
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
        return PTRotationManager.shared.orientationMask(for: window?.windowScene)
    }
}
#endif
