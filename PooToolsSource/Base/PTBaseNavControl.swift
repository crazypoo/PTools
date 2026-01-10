//
//  PTBaseNavControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/6/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
open class PTBaseNavControl: UINavigationController {
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        PTBaseNavControl.GobalNavControl(nav: self)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if #available(iOS 18.0, *) {
            baseTraitCollectionDidChange(style:traitCollection.userInterfaceStyle)
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationBar.isTranslucent = true
        pushStatusBars(for: viewControllers)
        interactivePopGestureRecognizer?.delegate = self
        delegate = self
        // Do any additional setup after loading the view.
        view.backgroundColor = PTAppBaseConfig.share.viewControllerBaseBackgroundColor
        
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
                StatusBarManager.shared.style = previousTraitCollection.userInterfaceStyle == .dark ? .lightContent : .darkContent
                self.baseTraitCollectionDidChange(style:previousTraitCollection.userInterfaceStyle)
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    
    open func baseTraitCollectionDidChange(style:UIUserInterfaceStyle) { }
    
    open override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        clearSubStatusBars(isUpdate: false)
        pushStatusBars(for: viewControllers)
        super.setViewControllers(viewControllers, animated: animated)
    }
    
    @objc open func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        .portrait
    }
    
    /// 修改导航栏返回按钮
    open override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        
        if viewControllers.count > 0 {
            let backBtn = UIButton(type: .custom)
            backBtn.setImage(PTAppBaseConfig.share.viewControllerBackItemImage, for: .normal)
            backBtn.bounds = CGRect.init(x: 0, y: 0, width: 24, height: 24)
            backBtn.addActionHandlers { seder in
                self.back()
            }
            let leftItem = UIBarButtonItem(customView: backBtn)
            viewController.navigationItem.leftBarButtonItem = leftItem
            viewController.hidesBottomBarWhenPushed = true
        }
        topViewController?.addSubStatusBar(for: viewController)
        super.pushViewController(viewController, animated: animated)
    }
    
    open override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        
        // iOS13 默认 UIModalPresentationAutomatic 模式，所以要判断处理一下
        // 当 modalPresentationStyle == .automatic , 才需要处理.
        // 如果不加这个判断,可能会导致 present 出来是一个黑色背景的界面. 比如, 做背景半透明的弹窗的时候.
        if viewControllerToPresent.modalPresentationStyle == .automatic {
            viewControllerToPresent.modalPresentationStyle = .fullScreen
        }
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
    
    @objc public func back() {
        if self.presentingViewController != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true, nil)
        }
    }
    
    open override var childForStatusBarStyle: UIViewController? {
        /**
         自定义UINavigationController，需要重写childForStatusBarStyle。
         否则preferredStatusBarStyle不执行。
         */
        topViewController
    }
}

extension PTBaseNavControl: UINavigationControllerDelegate {}

extension PTBaseNavControl {
    
    open override var prefersStatusBarHidden: Bool {
        StatusBarManager.shared.isHidden
    }
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        StatusBarManager.shared.style
    }
    open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        StatusBarManager.shared.animation
    }
    
    @available(iOS, introduced: 8.0, deprecated: 17.0,message: "17後不再支持了")
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            StatusBarManager.shared.style = UITraitCollection.current.userInterfaceStyle == .dark ? .lightContent : .darkContent
            baseTraitCollectionDidChange(style:UITraitCollection.current.userInterfaceStyle)
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    public class func GobalNavControl(nav:UINavigationController,
                                      textColor:UIColor = PTAppBaseConfig.share.navTitleTextColor,
                                      navColor:UIColor = .clear) {
        let colors:UIColor = navColor
        let textColors:UIColor = textColor
        
        //修改导航栏文字颜色字号
        let attrs = [NSAttributedString.Key.foregroundColor: textColors, NSAttributedString.Key.font: PTAppBaseConfig.share.navTitleFont]
        
        let images = UIColor.clear.createImageWithColor()
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.backgroundColor = colors
        navigationBarAppearance.titleTextAttributes = attrs as [NSAttributedString.Key : Any]
        navigationBarAppearance.shadowImage = images
        navigationBarAppearance.setBackIndicatorImage(colors.createImageWithColor(), transitionMaskImage: colors.createImageWithColor())
        nav.navigationBar.scrollEdgeAppearance = navigationBarAppearance
        nav.navigationBar.standardAppearance = navigationBarAppearance
        nav.navigationBar.compactScrollEdgeAppearance = navigationBarAppearance
        nav.navigationBar.tintColor = textColor
        nav.navigationItem.leftBarButtonItem?.tintColor = textColors

        let toolBarAppearance = UIToolbarAppearance()
        toolBarAppearance.backgroundColor = colors
        nav.toolbar.scrollEdgeAppearance = toolBarAppearance
        nav.toolbar.standardAppearance = toolBarAppearance
        nav.toolbar.compactScrollEdgeAppearance = toolBarAppearance
        nav.toolbar.isTranslucent = false
    }
}
