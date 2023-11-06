//
//  AppDelegate.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 1/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import IQKeyboardManager
#if DEBUG
import YCSymbolTracker
#endif
#if canImport(FLEX)
import FLEX
#endif
#if canImport(InAppViewDebugger)
import InAppViewDebugger
#endif
#if canImport(HyperionCore)
import HyperionCore
#endif
#if canImport(netfox)
import netfox
#endif

/// 服务路由
public let serivceHost = "scheme://services?"

/// web跳转路由
public let webRouterUrl = "scheme://webview/home"

@main
class AppDelegate: UIResponder,UIApplicationDelegate {
    
    var window: UIWindow?
    var devFunction:PTDevFunction = PTDevFunction()
    private var maskView : PTDevMaskView?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
//        var debugDevice = false
//        let buglyConfig = BuglyConfig()
//        #if DEBUG
//        debugDevice = true
//        buglyConfig.debugMode = true
//        #endif
//        buglyConfig.channel = "iOS"
//        buglyConfig.blockMonitorEnable = true
//        buglyConfig.blockMonitorTimeout = 2
//        buglyConfig.consolelogEnable = false
//        buglyConfig.viewControllerTrackingEnable = false
//        Bugly.start(withAppId: BuglyAppKey,
//                    developmentDevice: debugDevice,
//                    config: buglyConfig)

        PTDebugFunction.registerDefaultsFromSettingsBundle()

        IQKeyboardManager.shared().isEnabled = true
        IQKeyboardManager.shared().keyboardDistanceFromTextField = 50
        
        PTRotationManager.share.interfaceOrientationMask = .portrait
        
        PTRouter.lazyRegisterRouterHandle { url ,userInfo in
            PTRouter.injectRouterServiceConfig(webRouterUrl, serivceHost)
            return PTRouterManager.addGloableRouter([".Zola"], url, userInfo)
        }
        PTRouterManager.registerServices()
        PTRouter.logcat { url, logType, errorMsg in
            PTNSLogConsole("PTRouter: logMsg- \(url) \(logType.rawValue) \(errorMsg)")
        }
        
        PTAppBaseConfig.share.defaultPlaceholderImage = "🖼️".emojiToImage(emojiFont: .appfont(size: 44))
#if DEBUG
        let filePath = NSTemporaryDirectory().appending("/demo.order")
        YCSymbolTracker.exportSymbols(filePath: filePath)

        window = TouchInspectorWindow(frame: UIScreen.main.bounds)
        (window as! TouchInspectorWindow).showTouches = devFunction.touchesType
        (window as! TouchInspectorWindow).showHitTesting = devFunction.touchesTestHit
#else
        window = UIWindow.init(frame: UIScreen.main.bounds)
#endif
        
        let vc = PTFuncNameViewController()
        let mainNav = PTBaseNavControl(rootViewController: vc)
        window!.rootViewController = mainNav
        window!.makeKeyAndVisible()
        
        PTLaunchAdMonitor.showAt(path: ["http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg"], onView: self.window!, timeInterval: 10, param: ["123":"https://www.qq.com"], year: "2023", skipFont: .appfont(size: 14), comName: "1111", comNameFont: .appfont(size: 10)) {
            PTNSLogConsole("广告消失了")
        }
        
#if canImport(netfox)
        NFX.sharedInstance().start()
#endif
        devFunction.createLabBtn()
        devFunction.flex = {
            if FLEXManager.shared.isHidden {
                FLEXManager.shared.showExplorer()
            } else {
                FLEXManager.shared.hideExplorer()
            }
        }
        devFunction.inApp = {
            InAppViewDebugger.present()
        }
        devFunction.flexBool = { show in
            if show {
                FLEXManager.shared.showExplorer()
            } else {
                FLEXManager.shared.hideExplorer()
            }
        }
        devFunction.HyperioniOS = {
            HyperionManager.sharedInstance().attach(to: self.window)
            HyperionManager.sharedInstance().togglePluginDrawer()
        }
        devFunction.TestHitShow = { show in
            if self.window is TouchInspectorWindow {
                (self.window as! TouchInspectorWindow).showHitTesting = show
            }
        }
        devFunction.TestHitTouchesShow = { show in
            if self.window is TouchInspectorWindow {
                (self.window as! TouchInspectorWindow).showTouches = show
            }
        }
        devFunction.FoxNet = {
#if canImport(netfox)
            if NFX.sharedInstance().isStarted() {
                NFX.sharedInstance().show()
            }
#endif
        }
        devFunction.goToAppDevVC = {
            let vc = PTDebugViewController()
            let nav = PTBaseNavControl(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            PTUtils.getCurrentVC().present(nav, animated: true)
        }
                        
        let guideModel = PTGuidePageModel()
        guideModel.mainView = self.window!
        guideModel.imageArrays = ["DemoImage.png","http://img.t.sinajs.cn/t35/style/images/common/face/ext/normal/7a/shenshou_thumb.gif","image_aircondition_gray.png","DemoImage.png","DemoImage.png","DemoImage.png","http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg"]
        guideModel.tapHidden = true
        guideModel.forwardImage = "DemoImage"
        guideModel.backImage = "DemoImage"
        guideModel.pageControl = true
        guideModel.skipShow = true
        
        let guideHud = PTGuidePageHUD(viewModel: guideModel)
        guideHud.animationTime = 1.5
        guideHud.adHadRemove = {
            
        }
        guideHud.guideShow()
        return true
    }
}

extension AppDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        PTRotationManager.share.interfaceOrientationMask
    }
    
    @objc class func appDelegate() -> AppDelegate? {
        UIApplication.shared.delegate as? AppDelegate
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        PSecurityStrategy.addBlurEffect()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        PSecurityStrategy.removeBlurEffect()
    }
}

