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
//import Bugly
import TipKit

@main
class AppDelegate: PTAppWindowsDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        if #available(iOS 17.0, *) {
            PTTip.shared.appdelegateTipSet()
        }
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
//        Bugly.start(withAppId: "32b6206a5d",
//                    developmentDevice: debugDevice,
//                    config: buglyConfig)
        
        PTDarkModeOption.defaultDark()
        StatusBarManager.shared.style = PTDarkModeOption.isLight ? .darkContent : .lightContent
        
        createSettingBundle()

        IQKeyboardManager.shared().isEnabled = true
        IQKeyboardManager.shared().keyboardDistanceFromTextField = 50

#if POOTOOLS_ROTATION
        registerRotation()
#endif
        
#if POOTOOLS_ROUTER
        registerRouter()
#endif
        
        PTAppBaseConfig.share.defaultPlaceholderImage = "🖼️".emojiToImage(emojiFont: .appfont(size: 44))
        
        makeKeyAndVisible(createViewControllerHandler: {
            let vc = PTFuncNameViewController()
            let mainNav = PTBaseNavControl(rootViewController: vc)
            return mainNav
        }, tint: .white)
#if DEBUG
        let filePath = NSTemporaryDirectory().appending("/demo.order")
        YCSymbolTracker.exportSymbols(filePath: filePath)
#endif
        
#if canImport(netfox)
        NFX.sharedInstance().start()
#endif
        
//#if DEBUG
        let lcm = LocalConsole.shared
        lcm.isVisible = PTCoreUserDefultsWrapper.AppDebugMode
        lcm.flex = {
#if canImport(FLEX)
            if FLEXManager.shared.isHidden {
                FLEXManager.shared.showExplorer()
            } else {
                FLEXManager.shared.hideExplorer()
            }
#endif
        }
        lcm.HyperioniOS = {
#if canImport(HyperionCore)
            HyperionManager.sharedInstance().attach(to: AppWindows)
            HyperionManager.sharedInstance().togglePluginDrawer()
#endif
        }
        lcm.FoxNet = {
#if canImport(netfox)
            if NFX.sharedInstance().isStarted() {
                NFX.sharedInstance().show()
            }
#endif
        }
        lcm.watchViews = {
#if canImport(InAppViewDebugger)
            InAppViewDebugger.present()
#endif
        }
//        #endif

        PTLaunchAdMonitor.showAt(path: "http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg", onView: self.window!, timeInterval: 10, param: ["123":"https://www.qq.com"], year: "2023", skipFont: .appfont(size: 14), comName: "1111", comNameFont: .appfont(size: 10)) {
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
        }
        
        PTNSLogConsole("我有料>>>>>:\(PTCheckFWords.share.haveFWord(str:"半刺刀"))")
                
        PTNSLogConsole(">>>>>>>>>>>>>>\("Test".localized())")
        XMNetWorkStatus.shared.obtainDataFromLocalWhenNetworkUnconnected { state in
            
        }
        
        
        PTNSLogConsole(">>>>>>>>>>>>>>\(String(describing: OSSVoiceEnum.French.flag))")
        PTNSLogConsole(">>>>>>>>>>>>>>\(PTUtils.getCurrentVC())")

        Task.init {
            do {
//                let mopdel = try await Network.requestIPInfo(ipAddress: "124.127.104.130")
                let mopdel = try await Network.getIpAddress()
                PTNSLogConsole("\(mopdel)")
            } catch {
                PTNSLogConsole("\(error.localizedDescription)")
            }
        }
        
//        PTNSLogConsole(">>>>>>>>>>>>>>>>>>>>>>>>>>>,,,,,\(String(describing: OSSVoiceEnum.ChineseSimplified.flag))")
        
        return true
    }
}

extension AppDelegate {
        
    func applicationWillEnterForeground(_ application: UIApplication) {
        PSecurityStrategy.addBlurEffect()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        PSecurityStrategy.removeBlurEffect()
    }
        
    override class func appDelegate() -> AppDelegate? {
        UIApplication.shared.delegate as? AppDelegate
    }
}

