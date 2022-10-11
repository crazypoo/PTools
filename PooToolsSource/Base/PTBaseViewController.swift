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
public class PTBaseViewController: ZXNavigationBarController {

    //MARK: NAV
    public var navItemSize: CGFloat = 30
    public var navBarBackgroundColor: UIColor = UIColor.white
    public var navLineView: Bool = true
    public var navTitleFont: UIFont = .appfont(size: 18,bold: true)
    public var navBackImage: UIImage = UIImage(named: "DemoImage")!
    
    //MARK: 空数据
    public var tipString: String = ""
    public var tipColor: UIColor = UIColor.black
    public var verticalOffSet: CGFloat = 0
    public var tipImage: UIImage = UIImage(named: "icon_clear")!
    public var buttonTitleAtt: NSAttributedString  {
        let attrText = NSAttributedString.sj.makeText { (make) in
            make.append(NSLocalizedString("点击刷新", comment: "")).font(.appfont(size: 15)).textColor(.black).underLine { (style) in
                style.style = .single
            }
        }
        return attrText
    }


    public override var prefersStatusBarHidden:Bool
    {
        return StatusBarManager.shared.isHidden
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle
    {
        return StatusBarManager.shared.style
    }
    
    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation
    {
        return StatusBarManager.shared.animation
    }
    
    deinit {
        PTLocalConsoleFunction.share.pNSLog("[\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())]===已被释放")
        self.removeFromSuperStatusBar()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        PTLocalConsoleFunction.share.pNSLog("加载==============================\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())）")
        if self.presentationController != nil
        {
            self.zx_leftClickedBlock { itenBtn in
                self.viewDismiss()
            }
        }
        
        let vcCounts = self.navigationController?.viewControllers.count ?? 0
        if vcCounts > 1 || self.presentingViewController != nil {
            //设置统一返回按钮图片
            self.zx_navLeftBtn?.setImage(self.navBackImage, for: .normal)
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        PTLocalConsoleFunction.share.pNSLog("离开==============================\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())）")
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    convenience init(hideBaseNavBar: Bool) {
        self.init()
        self.zx_hideBaseNavBar = hideBaseNavBar
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
        // Do any additional setup after loading the view.
        self.edgesForExtendedLayout = []
        self.definesPresentationContext = true
        
        self.zx_navItemSize = self.navItemSize
        self.zx_navBarBackgroundColor = self.navBarBackgroundColor
        self.zx_navLineView?.isHidden = self.navLineView
        self.zx_navTitleFont = self.navTitleFont
    }
    
    /// 拦截返回上一页
    /// - Parameter popBlock: 是否允许放回上一页
    func openPopIntercept(popBlock:@escaping ((_ viewController:ZXNavigationBarController,_ popBlockFrom:ZXNavPopBlockFrom)->(Bool))) {
        //因FDFullscreenPopGesture默认会在控制器即将展示时显示系统导航栏，与ZXNavigationBar共同使用时会造成系统导航栏出现一下又马上消失，因此需要以下设置
        self.fd_prefersNavigationBarHidden = true
        //当您通过zx_handlePopBlock拦截侧滑返回手势时，请设置fd_interactivePopDisabled为YES以关闭FDFullscreenPopGesture在当前控制器的全屏返回手势，否则无法拦截。
        self.fd_interactivePopDisabled = true
                
        self.zx_handlePopBlock = popBlock
    }

    @available(iOS 13.0, *)
    public func changeStatusBar(type:VCStatusBarChangeStatusType)
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
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
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
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        false
    }
}

extension PTBaseViewController:LXFEmptyDataSetable
{
    //添加emptydataset
    /// 设置无数据空页面
    public func showEmptyDataSet(currentScroller:UIScrollView) {
        self.lxf_EmptyDataSet(currentScroller) { () -> ([LXFEmptyDataSetAttributeKeyType : Any]) in
            return [
                .tipStr : self.tipString,
                .tipColor : self.tipColor,
                .verticalOffset : self.verticalOffSet,
                .tipImage : self.tipImage
            ]
        }
    }
    
    public func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControl.State) -> NSAttributedString! {
        return self.buttonTitleAtt
    }
}

extension PTBaseViewController
{
    public func devFunction()
    {
        
    }
    
    public override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if UIApplication.applicationEnvironment() != .appStore
        {
            let uidebug:Bool = App_UI_Debug_Bool
            UserDefaults.standard.set(!uidebug, forKey: LocalConsole.ConsoleDebug)
            if uidebug
            {
                self.devFunction()
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
    public func floatingPanel(_ fpc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        let layout = PTFloatPanelLayout()
        return layout
    }
}
