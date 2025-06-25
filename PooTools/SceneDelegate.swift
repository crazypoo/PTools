//
//  SceneDelegate.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2025/6/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit
import Alamofire

class SceneDelegate: PTWindowSceneDelegate {
    var permissionStatic = PTPermissionStatic.share

    var guideHud:PTGuidePageHUD?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let scene = (scene as? UIWindowScene) else { return }
        let vc = PTFuncNameViewController()
        let mainNav = PTBaseNavControl(rootViewController: vc)
        
        let sideContent = PTSideController()
        let sideMeniController = PTSideMenuControl(contentViewController: mainNav, menuViewController: sideContent)

        makeKeyAndVisible(in: scene, viewController: sideMeniController, tint: .white)
        
        PTGCDManager.gcdMain(block: {
            //"http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg"
            PTLaunchAdMonitor.share.showAd(path: "http://img.t.sinajs.cn/t35/style/images/common/face/ext/normal/7a/shenshou_thumb.gif", onView: self.window!, timeInterval: 10, param: ["123":"https://www.qq.com"],skipFont: .appfont(size: 14), ltdString: "Copyright (c) \(Date().year) 111111.\n All rights reserved.",comNameFont: .appfont(size: 10), timeUp:  {
                let guideModel = PTGuidePageModel()
                guideModel.mainView = self.window!
                guideModel.imageArrays = ["DemoImage.png","http://img.t.sinajs.cn/t35/style/images/common/face/ext/normal/7a/shenshou_thumb.gif","image_aircondition_gray.png","DemoImage.png","DemoImage.png","DemoImage.png","http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg"]
                guideModel.tapHidden = false
                guideModel.forwardImage = "DemoImage"
                guideModel.backImage = "DemoImage"
                guideModel.pageControlTintColor = .gray
                guideModel.pageControl = .pageControl(type: .system)
                guideModel.skipShow = true
                
                if self.guideHud == nil {
                    self.guideHud = PTGuidePageHUD(viewModel: guideModel)
                    self.guideHud!.animationTime = 1.5
                    self.guideHud!.adHadRemove = {
                        
                    }
                    self.guideHud!.guideShow()
                }
            })
        })
        
        registerRotation()
        
        PTGCDManager.gcdBackground {
            let locationAlways = PTPermissionModel()
            locationAlways.type = .location(access: .always)
            locationAlways.desc = "我们有需要长时间使用你的定位信息,来在网络测速的时候在地图上大概显示你IP所属位置"
            
            let locationWhen = PTPermissionModel()
            locationWhen.type = .location(access: .whenInUse)
            locationWhen.desc = "我们有需要的时候使用你的定位信息,来在网络测速的时候在地图上大概显示你IP所属位置"

            let camera = PTPermissionModel()
            camera.type = .camera
            camera.desc = "我们需要使用你的照相机,来实现拍照后图片编辑功能"

            let mic = PTPermissionModel()
            mic.type = .microphone
            mic.desc = "我们需要访问你的麦克风,来实现视频拍摄和编辑功能"

            let photo = PTPermissionModel()
            photo.type = .photoLibrary
            photo.desc = "我们需要访问你的相册和照片,来使用图片的编辑功能"
            
            self.permissionStatic.permissionModels = [locationAlways,locationWhen,camera,mic,photo]

            SceneDelegate.debugSet()
            
            PTSideMenuControl.preferences.basic.direction = .right
            PTSideMenuControl.preferences.basic.menuWidth = 240
            PTSideMenuControl.preferences.basic.defaultCacheKey = "0"
            StatusBarManager.shared.style = PTDarkModeOption.isLight ? .darkContent : .lightContent
            PTDarkModeOption.defaultDark()
        }
        
        PTNSLogConsole("我有料>>>>>:\(PTCheckFWords.share.haveFWord(str:"半刺刀"))")
        PTGCDManager.gcdMain {
            let networkShare = PTNetWorkStatus.shared
            PTNSLogConsole(">>>>>>>>>>>>>>\("Test".localized())")
            networkShare.reachabilityManager = Alamofire.NetworkReachabilityManager(host: "www.google.com")
            networkShare.obtainDataFromLocalWhenNetworkUnconnected { state in
                PTNSLogConsole(">>>>>>>>>>>>>>>>>>>>>>>>>>\(state)")
            }
            networkShare.netWork { state in
                PTNSLogConsole("network:>>>>>>>>>>>>>>>>>>>>\(state)")
            }
        }
        
#if POOTOOLS_ROUTER
        registerRouter()
#endif
    }
    
    //MARK: Debug setting
    @MainActor class func debugSet() {
//#if DEBUG
        let lcm = LocalConsole.shared
        lcm.isVisiable = PTCoreUserDefultsWrapper.AppDebugMode
//#endif
        switch UIApplication.shared.inferredEnvironment {
        case .appStore,.testFlight:
            break
        default:
            PTDebugFunction.registerDefaultsFromSettingsBundle()
        }
    }
    
    public func registerRotation(changeCallBack:((_ orientationMask: UIInterfaceOrientationMask) -> ())? = nil) {
        PTRotationManager.shared.isLockOrientationWhenDeviceOrientationDidChange = false
        PTRotationManager.shared.isLockLandscapeWhenDeviceOrientationDidChange = false
        PTRotationManager.shared.orientationMaskDidChange = changeCallBack
    }
}
