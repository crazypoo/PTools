//
//  PTBaseViewController.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import ZXNavigationBar
import FDFullscreenPopGesture
import LXFProtocolTool
import SJAttributesStringMaker
import FloatingPanel

@objc public enum VCStatusBarChangeStatusType : Int
{
    case Dark
    case Light
    case Auto
}

@objcMembers
open class PTBaseViewController: ZXNavigationBarController {


    open override var prefersStatusBarHidden:Bool
    {
        return StatusBarManager.shared.isHidden
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle
    {
        return StatusBarManager.shared.style
    }
    
    open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation
    {
        return StatusBarManager.shared.animation
    }
    
    deinit {
        PTLocalConsoleFunction.share.pNSLog("[\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())]===已被释放")
        self.removeFromSuperStatusBar()
    }
    
    @objc open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        PTLocalConsoleFunction.share.pNSLog("加载==============================\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())）")
        if self.presentationController != nil
        {
            self.zx_leftClickedBlock { itenBtn in
                self.viewDismiss()
            }
        }
    }
    
    @objc override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        PTLocalConsoleFunction.share.pNSLog("离开==============================\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())）")
    }
    
    @objc override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    public convenience init(hideBaseNavBar: Bool) {
        self.init()
        self.zx_hideBaseNavBar = hideBaseNavBar
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
        // Do any additional setup after loading the view.
        self.edgesForExtendedLayout = []
        self.definesPresentationContext = true
        
        self.view.backgroundColor = PTAppBaseConfig.share.viewControllerBaseBackgroundColor
    }
    
    /// 拦截返回上一页
    /// - Parameter popBlock: 是否允许放回上一页
    open func openPopIntercept(popBlock:@escaping ((_ viewController:ZXNavigationBarController,_ popBlockFrom:ZXNavPopBlockFrom)->(Bool))) {
        //因FDFullscreenPopGesture默认会在控制器即将展示时显示系统导航栏，与ZXNavigationBar共同使用时会造成系统导航栏出现一下又马上消失，因此需要以下设置
        self.fd_prefersNavigationBarHidden = true
        //当您通过zx_handlePopBlock拦截侧滑返回手势时，请设置fd_interactivePopDisabled为YES以关闭FDFullscreenPopGesture在当前控制器的全屏返回手势，否则无法拦截。
        self.fd_interactivePopDisabled = true
                
        self.zx_handlePopBlock = popBlock
    }

    @available(iOS 13.0, *)
    open func changeStatusBar(type:VCStatusBarChangeStatusType)
    {
        switch type {
        case .Auto:
            StatusBarManager.shared.style = UITraitCollection.current.userInterfaceStyle == .dark ? .lightContent : .darkContent
            setNeedsStatusBarAppearanceUpdate()
        case .Dark:
            StatusBarManager.shared.style = .lightContent
            setNeedsStatusBarAppearanceUpdate()
        case .Light:
            StatusBarManager.shared.style = .darkContent
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    open func switchOrientation(isFullScreen:Bool)
    {
        AppDelegateEXFunction.share.isFullScreen = isFullScreen
        
        if #available(iOS 16.0, *)
        {
            setNeedsUpdateOfPrefersPointerLocked()
            guard let scence = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            let orientation:UIInterfaceOrientationMask = isFullScreen ? .landscape : .portrait
            let geometryPreferencesIOS = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: orientation)
            scence.requestGeometryUpdate(geometryPreferencesIOS) { error in
                PTLocalConsoleFunction.share.pNSLog("强制\(isFullScreen ? "横屏" : "竖屏")错误:\(error)")
            }
        }
        else
        {
            let oriention:UIDeviceOrientation = isFullScreen ? .landscapeRight : .portrait
            UIDevice.current.setValue(oriention.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *)
        {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection)
            {
                StatusBarManager.shared.style = UITraitCollection.current.userInterfaceStyle == .dark ? .lightContent : .darkContent
                setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
}

extension PTBaseViewController:UIGestureRecognizerDelegate
{
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        false
    }
}

extension PTBaseViewController:LXFEmptyDataSetable
{
    //添加emptydataset
    /// 设置无数据空页面
    open func showEmptyDataSet(currentScroller:UIScrollView) {
        self.lxf_EmptyDataSet(currentScroller) { () -> ([LXFEmptyDataSetAttributeKeyType : Any]) in
            return [
                .tipStr : "",
                .tipColor : UIColor.black,
                .verticalOffset : 0,
                .tipImage : UIImage()
            ]
        }
    }
    
    open func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControl.State) -> NSAttributedString! {
        return NSAttributedString()
    }
}

extension PTBaseViewController
{
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if UIApplication.applicationEnvironment() != .appStore
        {
            let uidebug:Bool = App_UI_Debug_Bool
            UserDefaults.standard.set(!uidebug, forKey: LocalConsole.ConsoleDebug)
            if uidebug
            {
                if PTDevFunction.share.mn_PFloatingButton != nil
                {
                    PTDevFunction.share.lab_btn_release()
                }
                else
                {
                    PTDevFunction.GobalDevFunction_close()
                }
            }
            else
            {
                if #available(iOS 13.0, *)
                {
                    let vc = PTDebugViewController.init(hideBaseNavBar: false)
                    PTUtils.getCurrentVC().navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
}

extension PTBaseViewController:FloatingPanelControllerDelegate
{
    open func floatingPanel(_ fpc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        let layout = PTFloatPanelLayout()
        return layout
    }
}
