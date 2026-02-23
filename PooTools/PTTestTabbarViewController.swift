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

    private let customTabBar = PTTabBarView()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTabBar()
        
        let vc = PTFuncNameViewController()
        let mainNav = PTBaseNavControl(rootViewController: vc)
        
        let sideContent = PTSideController()
        let homeVC = PTSideMenuControl(contentViewController: mainNav, menuViewController: sideContent)
        
        let home = PTTabBarItemConfig(title: "首页", content: PTTabBarImageContent(normal: UIImage(named: "image_aircondition_gray")!, selected: UIImage(named: "DemoImage")!),viewController: homeVC)
        
        let yoVC = PTTabBarTestOneViewController()
        let yoNav = PTBaseNavControl(rootViewController: yoVC)
        let yo = PTTabBarItemConfig(title: "11111111", content: PTTabBarLottieContent(normal: "https://assets8.lottiefiles.com/packages/lf20_hp09atmh.json"), viewController: yoNav)

        configure(items: [home,yo])

        customTabBar.select(0)
        
        if #available(iOS 26.0, *) {
            // iOS26新增，向下滚动时，只显示第一个与UISearchTab的图标，中间显示辅助UITabAccessory
            self.tabBarMinimizeBehavior = .onScrollDown
        }
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
    
    private func setupTabBar() {
        tabBar.isHidden = true

        view.addSubview(customTabBar)
        customTabBar.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(CGFloat.kTabbarHeight_Total)
        }

        customTabBar.willSelectIndex = { index in
            PTNSLogConsole("\(index)")
        }
        customTabBar.shouldSelectIndex = { index in
            PTNSLogConsole("should\(index)")
//            if index == 1 {
//                return false
//            }
            return true
        }
        customTabBar.didTapCenter = {
            PTNSLogConsole("123123123123123123123123")
        }
        customTabBar.didSelectIndex = { [weak self] index in
            self?.selectedIndex = index
        }
    }

    func configure(items: [PTTabBarItemConfig]) {
        viewControllers = items.map { $0.viewController }
        let aaaaaa = PTTabBarBigImageContent(normal: UIImage(named: "image_aircondition_gray")!)
        customTabBar.setup(configs: items,layoutStyle: .normal,centerContent: aaaaaa)
        customTabBar.badge(index: 0,badgeValue: 10)
    }
}
