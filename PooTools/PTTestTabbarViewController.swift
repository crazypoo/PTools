//
//  PTTestTabbarViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 20/1/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
#if SWIFT_PACKAGE
import PToolsSymbols
#endif
import PooTools

class PTTestTabbarViewController: PTBaseTabBarViewController {
    #if DEBUG
    private var lastAdaptiveDebugSummary = ""
    #endif
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // 🌟 深度 Debug：打印具体类型
        if let selected = self.selectedViewController {
            PTNSLogConsole("【DEBUG】TabBarController 发现选中的 VC 类型是: \(type(of: selected))")
            let mask = selected.supportedInterfaceOrientations
            PTNSLogConsole("【DEBUG】TabBarController 成功读取到的子VC权限: \(mask.rawValue)")
            return mask
        } else {
            PTNSLogConsole("【DEBUG】TabBarController 报错：selectedViewController 是 nil！")
            return .portrait
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let vc = PTFuncNameViewController()
        let mainNav = PTBaseNavControl(rootViewController: vc)
                
        let home = PTTabBarItemConfig(title: "", content: PTTabBarImageContent(normal: "https://assets8.lottiefiles.com/packages/lf20_hp09atmh.json", selected: UIImage(named: "DemoImage")!),viewController: mainNav)
        
        let yoVC = PTTabBarTestOneViewController()
        let yoNav = PTBaseNavControl(rootViewController: yoVC)
        let yo = PTTabBarItemConfig(title: "11111111", content: PTTabBarImageContent(normal: "https://assets8.lottiefiles.com/packages/lf20_hp09atmh.json", selected: "https://assets8.lottiefiles.com/packages/lf20_hp09atmh.json"), viewController: yoNav)

        let yoVC1 = PTTabBarTestOneViewController()
        let yoNav1 = PTBaseNavControl(rootViewController: yoVC1)
        let yo1 = PTTabBarItemConfig(title: "2222", content: PTTabBarImageContent(normal: "https://assets8.lottiefiles.com/packages/lf20_hp09atmh.json", selected: "https://assets8.lottiefiles.com/packages/lf20_hp09atmh.json"), viewController: yoNav1)

        let itemsss = [home,yo,yo1]
        configure(items: itemsss)

        ptCustomBar.willSelectIndex = { index in
            PTNSLogConsole("\(index)")
        }
        ptCustomBar.shouldSelectIndex = { index in
            if index == 1,!PTTestGlobalFunction.shared.isLogin {
                // 🌟 启动 Task，利用我们完美的路由去触发登录流程
                Task {
                    // 触发登录页（自带 NavigationController 且 Modal 出来）
                    // 享受底层 LoginInterceptor 的全套保护机制
                    let _ = try? await PTTypedBuilder<PTTestLoginViewController>(path: "ptools://login")
                        .jumpType(.modal, wrapInNav: true, presentationStyle: .fullScreen, transitionStyle: .coverVertical)
                        .navigation()
                }
                return false
            }
            PTNSLogConsole("should\(index)")
            return true
        }
        ptCustomBar.didTapCenter = {
            PTNSLogConsole("123123123123123123123123")
        }
        ptCustomBar.didSelectIndex = { [weak self] index in
            self?.selectedIndex = index
            self?.selectedViewController = itemsss[index].viewController
        }

        
        ptCustomBar.didDoubleTapIndex = { index in
            PTNSLogConsole("222222222")
        }
        ptCustomBar.select(0)
    }

    #if DEBUG
    // English: Log local scene geometry only when the adaptive-bar layout changes.
    // Español: Registra la geometría local de la escena solo cuando cambia el layout adaptativo.
    // 中文：仅在自适应 Bar 布局变化时记录当前场景的本地几何信息。
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let geometry = adaptiveBarGeometry,
              let window = viewIfLoaded?.window else { return }

        let windowSceneID = window.windowScene?.session.persistentIdentifier ?? "nil"
        let summary = "scene=\(windowSceneID) bounds=\(view.bounds.integral) safe=\(view.safeAreaInsets) "
            + "tabBar=\(tabBar.frame.integral) customBar=\(ptCustomBar.frame.integral) "
            + geometry.debugSummary
        guard summary != lastAdaptiveDebugSummary else { return }
        lastAdaptiveDebugSummary = summary
        PTNSLogConsole("[PTAdaptiveBar][DEBUG] \(summary)")
    }
    #endif
        
    // MARK: 设置UITab
    @available(iOS 18.0, *)
    func configTab(_ viewController:UIViewController,
                   title:String,
                   normalTitleColor:DynamicColor = .black,
                   selectedTitleColor:DynamicColor = .systemBlue,
                   imageName:UIImage,
                   selectedImage:UIImage,
                   identifier:String,
                   badgeValue:String? = nil) -> UITab {
        let tab = UITab(title: title, image:imageName, identifier: identifier) { tab in
            tab.badgeValue = badgeValue
            tab.userInfo = identifier
            let vc = self.configViewController(viewController: viewController, title: title)
            // 设置图片
            vc.tabBarItem.image = imageName.withRenderingMode(.alwaysOriginal)
            vc.tabBarItem.selectedImage = selectedImage.withRenderingMode(.alwaysOriginal)

            return vc
        }
        return tab
    }
    
    override func configure(items: [PTTabBarItemConfig]) {
        super.configure(items: items)
        let aaaaaa = PTTabBarImageContent(normal: "https://assets8.lottiefiles.com/packages/lf20_hp09atmh.json")//PTTabBarBigImageContent(normal: UIImage(named: "image_aircondition_gray")!)//PTTabBarBigLottieContent(normal: "camera")
        ptCustomBar.setup(configs: items,layoutStyle: .centerRaised,centerContent: aaaaaa)
        ptCustomBar.badge(index: 0,badgeValue: "10",badgeCanDrag: true)
        ptCustomBar.badge(index: 1,badgeValue: "10",badgeStyle: .redDot)
        self.centerRaisedSet = true
    }
}
