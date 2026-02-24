//
//  PTTestTabbarViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 20/1/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
import SafeSFSymbols

class PTTestTabbarViewController: PTBaseTabBarViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let vc = PTFuncNameViewController()
        let mainNav = PTBaseNavControl(rootViewController: vc)
        
        let sideContent = PTSideController()
        let homeVC = PTSideMenuControl(contentViewController: mainNav, menuViewController: sideContent)
        
        let home = PTTabBarItemConfig(title: "首页", content: PTTabBarImageContent(normal: UIImage(named: "image_aircondition_gray")!, selected: UIImage(named: "DemoImage")!),viewController: homeVC)
        
        let yoVC = PTTabBarTestOneViewController()
        let yoNav = PTBaseNavControl(rootViewController: yoVC)
        let yo = PTTabBarItemConfig(title: "11111111", content: PTTabBarLottieContent(normal: "https://assets8.lottiefiles.com/packages/lf20_hp09atmh.json"), viewController: yoNav)

        configure(items: [home,yo])

        ptCustomBar.willSelectIndex = { index in
            PTNSLogConsole("\(index)")
        }
        ptCustomBar.shouldSelectIndex = { index in
            PTNSLogConsole("should\(index)")
//            if index == 1 {
//                return false
//            }
            return true
        }
        ptCustomBar.didTapCenter = {
            PTNSLogConsole("123123123123123123123123")
        }
        ptCustomBar.didSelectIndex = { [weak self] index in
            self?.selectedIndex = index
        }

        ptCustomBar.select(0)
    }
        
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
        let aaaaaa = PTTabBarBigImageContent(normal: UIImage(named: "image_aircondition_gray")!)//PTTabBarBigLottieContent(normal: "camera")
        ptCustomBar.setup(configs: items,layoutStyle: .centerRaised,centerContent: aaaaaa)
        ptCustomBar.badge(index: 0,badgeValue: 10)
    }
}
