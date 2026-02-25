//
//  SceneDelegate.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 23/2/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit

class SceneDelegate: PTWindowSceneDelegate {
    
    var guideHud:PTGuidePageHUD?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let scene = (scene as? UIWindowScene) else { return }
        makeKeyAndVisible(in: scene, viewController: PTTestTabbarViewController(), tint: .white)
        let _ = LocalConsole.shared
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        PSecurityStrategy.addBlurEffect()
        
        //"http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg"
        
        if let window = AppWindows {
            let adModel = PTLaunchADModel()
            adModel.image = "http://img.t.sinajs.cn/t35/style/images/common/face/ext/normal/7a/shenshou_thumb.gif"
            adModel.time = 10
            adModel.tapURL = ["123":"https://www.qq.com"]
            
            PTLaunchAdMonitor.share.showAd(adModels: [adModel], onView: window,skipFont: .appfont(size: 14), ltdString: "Copyright (c) \(Date().year) 111111.\n All rights reserved.",comNameFont: .appfont(size: 10), timeUp:  {
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

        }

    }
}
