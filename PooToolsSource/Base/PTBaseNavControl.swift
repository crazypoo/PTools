//
//  PTBaseNavControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/6/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif

#if POOTOOLS_NAVBARCONTROLLER
@objcMembers
open class PTBaseNavControl: ZXNavigationBarNavigationController {
        
    open override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        clearSubStatusBars(isUpdate: false)
        pushStatusBars(for: viewControllers)
        super.setViewControllers(viewControllers, animated: animated)
    }
    
    public func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        .portrait
    }
    
    /// 修改导航栏返回按钮
    open override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        
        if viewControllers.count > 0 {
            let backBtn = UIButton.init(type: .custom)
            backBtn.setImage(PTAppBaseConfig.share.viewControllerBackItemImage, for: .normal)
            backBtn.bounds = CGRect.init(x: 0, y: 0, width: 34, height: 34)
            backBtn.addActionHandlers { seder in
                self.back()
            }
            let leftItem = UIBarButtonItem.init(customView: backBtn)
            viewController.navigationItem.leftBarButtonItem = leftItem
            viewController.hidesBottomBarWhenPushed = true
        }
        topViewController?.addSubStatusBar(for: viewController)
        super.pushViewController(viewController, animated: animated)
    }
    
    open override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        
        // iOS13 默认 UIModalPresentationAutomatic 模式，所以要判断处理一下
        if #available(iOS 13.0, *) {
            // 当 modalPresentationStyle == .automatic , 才需要处理.
            // 如果不加这个判断,可能会导致 present 出来是一个黑色背景的界面. 比如, 做背景半透明的弹窗的时候.
            if viewControllerToPresent.modalPresentationStyle == .automatic {
                viewControllerToPresent.modalPresentationStyle = .fullScreen
            }
        }
        super.present(viewControllerToPresent, animated: flag, completion: completion)
#if POOTOOLS_DEBUG
        SwizzleTool().swizzleDidAddSubview {
            // Configure console window.
            let lcm = LocalConsole.shared
            if lcm.isVisiable {
                PTUtils.fetchWindow()!.bringSubviewToFront(lcm.consoleViewController.view)
            }
        }
#endif
    }
    
    @objc func back() {
        self.popViewController(animated: true)
    }
    
    open override var childForStatusBarStyle: UIViewController? {
        /**
         自定义UINavigationController，需要重写childForStatusBarStyle。
         否则preferredStatusBarStyle不执行。
         */
        topViewController
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.zx_disableFullScreenGesture = false
    }
    
    // MARK: Lifecycle
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationBar.isTranslucent = true
        pushStatusBars(for: viewControllers)
        interactivePopGestureRecognizer?.delegate = self
        delegate = self
        
        view.backgroundColor = PTAppBaseConfig.share.viewControllerBaseBackgroundColor
        
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
                StatusBarManager.shared.style = previousTraitCollection.userInterfaceStyle == .dark ? .lightContent : .darkContent
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
}

// MARK: - 左滑手势返回
extension PTBaseNavControl: UIGestureRecognizerDelegate,UINavigationControllerDelegate {
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if viewControllers.count == 1 {
            return false
        }
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        /******处理右滑手势与scrollview手势冲突*******/
        gestureRecognizer is UIScreenEdgePanGestureRecognizer
    }
}

#else
@objcMembers
open class PTBaseNavControl: UINavigationController {
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        PTBaseNavControl.GobalNavControl(nav: self)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        view.backgroundColor = PTAppBaseConfig.share.viewControllerBaseBackgroundColor
        
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
                StatusBarManager.shared.style = previousTraitCollection.userInterfaceStyle == .dark ? .lightContent : .darkContent
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
}

extension PTBaseNavControl:UIGestureRecognizerDelegate {
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        false
    }
}

#endif

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
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                StatusBarManager.shared.style = UITraitCollection.current.userInterfaceStyle == .dark ? .lightContent : .darkContent
                setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    
    public class func GobalNavControl(nav:UINavigationController,
                              textColor:UIColor? = PTAppBaseConfig.share.navTitleTextColor,
                              navColor:UIColor? = PTAppBaseConfig.share.viewControllerBaseBackgroundColor) {
        let colors:UIColor? = navColor
        let textColors:UIColor? = textColor
        
        //修改导航栏文字颜色字号
        let attrs = [NSAttributedString.Key.foregroundColor: textColors, NSAttributedString.Key.font: PTAppBaseConfig.share.navTitleFont]
        
        let images = UIColor.clear.createImageWithColor()
        if #available(iOS 15.0, *) {
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.backgroundColor = colors
            navigationBarAppearance.titleTextAttributes = attrs as [NSAttributedString.Key : Any]
            navigationBarAppearance.shadowImage = images
            navigationBarAppearance.setBackIndicatorImage(colors!.createImageWithColor(), transitionMaskImage: colors!.createImageWithColor())
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
        } else {
            /// 去掉导航栏底部黑线。需要同时设置shadowImage 和 setBackgroundImage
            nav.navigationBar.shadowImage = images
            nav.navigationItem.leftBarButtonItem?.tintColor = textColors
            /// 导航栏背景图片
            nav.navigationController?.navigationBar.backgroundColor = colors
            nav.navigationController?.navigationBar.setBackgroundImage(colors!.createImageWithColor(), for: .default)
            
            nav.navigationBar.apply(gradient: [colors!])
            
            /// 修改UINavigationBar上各个item的文字、图形的颜色
            nav.navigationBar.tintColor = textColors
            
            nav.navigationBar.titleTextAttributes = attrs as [NSAttributedString.Key : Any]
        }
    }
}
