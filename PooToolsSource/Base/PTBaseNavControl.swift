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
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        let mask = visibleViewController?.supportedInterfaceOrientations ?? .portrait
        return mask
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        PTBaseNavControl.GobalNavControl(nav: self)
        PTNavigationBarManager.shared.bind(to: self)
        PTNavigationBarManager.shared.installIfNeeded(in: self)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()        
        pushStatusBars(for: viewControllers)
        PTNavigationBarManager.shared.bind(to: self)
        PTNavigationBarManager.shared.installIfNeeded(in: self)
        // Do any additional setup after loading the view.
        view.backgroundColor = PTAppBaseConfig.share.viewControllerBaseBackgroundColor
        
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _: UITraitCollection) in
            let style = self.traitCollection.userInterfaceStyle
            StatusBarManager.shared.style = style == .dark ? .lightContent : .darkContent
            self.baseTraitCollectionDidChange(style: style)
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    open func baseTraitCollectionDidChange(style:UIUserInterfaceStyle) { }
    
    open override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        clearSubStatusBars(isUpdate: false)
        pushStatusBars(for: viewControllers)
        super.setViewControllers(viewControllers, animated: animated)
    }
    
    @objc open func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        navigationController.visibleViewController?.supportedInterfaceOrientations ?? .portrait
    }
    
    /// 修改导航栏返回按钮
    open override func pushViewController(_ viewController: UIViewController, animated: Bool) {
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
        if viewControllers.count > 1 {
            popViewController(animated: true)
        } else if self.presentingViewController != nil {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    open override var childForStatusBarStyle: UIViewController? {
        /**
         自定义UINavigationController，需要重写childForStatusBarStyle。
         否则preferredStatusBarStyle不执行。
         */
        visibleViewController
    }
    
    open override var childForStatusBarHidden: UIViewController? {
        visibleViewController
    }
    
}

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
    
    public class func GobalNavControl(nav:UINavigationController,
                                      textColor:UIColor? = nil,
                                      navColor:UIColor = .clear) {
        let colors:UIColor = navColor
        let textColors:UIColor = textColor ?? PTAppBaseConfig.share.navTitleTextColor
        
        //修改导航栏文字颜色字号
        let attrs = [NSAttributedString.Key.foregroundColor: textColors, NSAttributedString.Key.font: PTAppBaseConfig.share.navTitleFont]
        
        let images = UIColor.clear.createImageWithColor()
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithTransparentBackground()
        navigationBarAppearance.backgroundEffect = nil
        navigationBarAppearance.backgroundColor = colors
        navigationBarAppearance.titleTextAttributes = attrs as [NSAttributedString.Key : Any]
        // English: Keep UIKit large-title text styling aligned with the custom navigation container.
        // Español: Mantiene el estilo del título grande de UIKit alineado con el contenedor de navegación personalizado.
        // 中文：让 UIKit 原生大标题文字样式与自定义导航容器保持一致。
        navigationBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: textColors,
            .font: PTAppBaseConfig.share.navLargeTitleFont
        ]
        navigationBarAppearance.shadowImage = images
        navigationBarAppearance.setBackIndicatorImage(colors.createImageWithColor(), transitionMaskImage: colors.createImageWithColor())
        nav.navigationBar.scrollEdgeAppearance = navigationBarAppearance
        nav.navigationBar.standardAppearance = navigationBarAppearance
        nav.navigationBar.compactScrollEdgeAppearance = navigationBarAppearance
        nav.navigationBar.tintColor = textColors
        nav.topViewController?.navigationItem.leftBarButtonItem?.tintColor = textColors

        let toolBarAppearance = UIToolbarAppearance()
        toolBarAppearance.backgroundColor = colors
        nav.toolbar.scrollEdgeAppearance = toolBarAppearance
        nav.toolbar.standardAppearance = toolBarAppearance
        nav.toolbar.compactScrollEdgeAppearance = toolBarAppearance
        nav.toolbar.isTranslucent = false
    }
}
