//
//  PTBaseViewController.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif
import FDFullscreenPopGesture
import SwifterSwift
import AttributedString
import Photos
import SnapKit
import SafeSFSymbols

public typealias PTScreenShotImageHandle = (PTScreenShotActionType,UIImage) -> Void
public typealias PTScreenShotOnlyGetImageHandle = (UIImage?) -> Void

public enum PTScreenShotActionType {
    case Share,Feedback,Edit
}

@objc public enum VCStatusBarChangeStatusType : Int {
    case Dark,Light,Auto
}

#if POOTOOLS_NAVBARCONTROLLER
@objcMembers
open class PTBaseViewController: ZXNavigationBarController {
    deinit {
        PTNSLogConsole("[\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())]===已被释放",levelType: PTLogMode,loggerType: .ViewCycle)
        removeFromSuperStatusBar()
    }
        
    //MARK: 拦截返回上一页
    ///拦截返回上一页
    /// - Parameter popBlock: 是否允许放回上一页
    @objc open func openPopIntercept(popBlock: @escaping (_ viewController:ZXNavigationBarController, _ popBlockFrom:ZXNavPopBlockFrom)-> Bool) {
        //因FDFullscreenPopGesture默认会在控制器即将展示时显示系统导航栏，与ZXNavigationBar共同使用时会造成系统导航栏出现一下又马上消失，因此需要以下设置
        self.fd_prefersNavigationBarHidden = true
        //当您通过zx_handlePopBlock拦截侧滑返回手势时，请设置fd_interactivePopDisabled为YES以关闭FDFullscreenPopGesture在当前控制器的全屏返回手势，否则无法拦截。
        self.fd_interactivePopDisabled = true
        
        self.zx_handlePopBlock = popBlock
    }
}
#else
@objcMembers
open class PTBaseViewController: UIViewController {
            
    deinit {
        PTNSLogConsole("[\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())]===已被释放",levelType: PTLogMode,loggerType: .ViewCycle)
        removeFromSuperStatusBar()
    }
}
#endif

/**
    抽出两个Controller同样用到的地方
 */
extension PTBaseViewController {
    fileprivate struct AssociatedKeys {
        static var emptyViewConfigCallBack = 992
        static var screenShotActionCallBack = 991
        static var screenShotAlertCallBack = 990
        static var screenShotOnlyGetImageCallBack = 989
        static var floatingScreenSpace = 988
    }
    
    //MARK: 是否隱藏StatusBar
    ///是否隱藏StatusBar
    open override var prefersStatusBarHidden:Bool {
        StatusBarManager.shared.isHidden
    }
    
    //MARK: 設置StatusBar樣式
    ///設置StatusBar樣式
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        StatusBarManager.shared.style
    }
    
    //MARK: 設置StatusBar動畫
    ///設置StatusBar動畫
    open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        StatusBarManager.shared.animation
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        PTNSLogConsole("加载==============================\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())）",levelType: PTLogMode,loggerType: .ViewCycle)
#if POOTOOLS_NAVBARCONTROLLER
        if presentationController != nil {
            self.zx_leftClickedBlock { itenBtn in
                self.viewDismiss()
            }
        }
#endif
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        PTNSLogConsole("离开==============================\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())）",levelType: PTLogMode,loggerType: .ViewCycle)
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if #available(iOS 18.0, *) {
            /*
            该方式在以下方法中自动生效。

            UIView：draw()、layoutSubviews()、updateConstraints()。
            UIViewController：viewWillLayoutSubviews()、viewDidLayoutSubviews()、updateViewConstraints()、updateContentUnavailableConfiguration()。
             */
            baseTraitCollectionDidChange(style:traitCollection.userInterfaceStyle)
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    //MARK: 是否隱藏NavBar
    ///是否隱藏NavBar
    public convenience init(hideBaseNavBar: Bool) {
        self.init()
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_hideBaseNavBar = hideBaseNavBar
#else
        navigationController?.navigationBar.isHidden = hideBaseNavBar
#endif
    }
        
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
        // Do any additional setup after loading the view.
        edgesForExtendedLayout = []
        definesPresentationContext = true
        
        view.backgroundColor = PTAppBaseConfig.share.viewControllerBaseBackgroundColor
        
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_navTitleColor = PTAppBaseConfig.share.navTitleTextColor
        self.zx_navTitleFont = PTAppBaseConfig.share.navTitleFont
#else
        navigationController?.hidesBarsOnSwipe = PTAppBaseConfig.share.hidesBarsOnSwipe
#endif
        
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
                StatusBarManager.shared.style = previousTraitCollection.userInterfaceStyle == .dark ? .lightContent : .darkContent
                self.baseTraitCollectionDidChange(style:previousTraitCollection.userInterfaceStyle)
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    
    //MARK: 動態更換StatusBar
    ///動態更換StatusBar
    open func changeStatusBar(type:VCStatusBarChangeStatusType) {
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
    
    open func switchOrientation(isFullScreen:Bool) {
        
        PTAppWindowsDelegate.appDelegate()?.isFullScreen = isFullScreen
                
        if #available(iOS 16.0, *) {
            setNeedsUpdateOfPrefersPointerLocked()
            guard let scence = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            let orientation:UIInterfaceOrientationMask = isFullScreen ? .landscape : .portrait
            let geometryPreferencesIOS = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: orientation)
            scence.requestGeometryUpdate(geometryPreferencesIOS) { error in
                PTNSLogConsole("强制\(isFullScreen ? "横屏" : "竖屏")错误:\(error)",levelType: PTLogMode,loggerType: .ViewCycle)
            }
        } else {
            let oriention:UIDeviceOrientation = isFullScreen ? .landscapeRight : .portrait
            UIDevice.current.setValue(oriention.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
    
    @available(iOS, introduced: 8.0, deprecated: 17.0,message: "17後不再支持了")
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            StatusBarManager.shared.style = UITraitCollection.current.userInterfaceStyle == .dark ? .lightContent : .darkContent
            baseTraitCollectionDidChange(style: UITraitCollection.current.userInterfaceStyle)
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    open func baseTraitCollectionDidChange(style:UIUserInterfaceStyle) { }
    
    public func returnFrontVC(completion:PTActionTask? = nil) {
        if presentingViewController != nil {
            dismiss(animated: true, completion: completion)
        } else {
            navigationController?.popViewController(animated: true, completion)
        }
#if POOTOOLS_DEBUG
        if UIApplication.shared.inferredEnvironment != .appStore {
            SwizzleTool().swizzleDidAddSubview {
                // Configure console window.
                let lcm = LocalConsole.shared
                if lcm.isVisiable {
                    if let maskView = lcm.maskView {
                        PTUtils.fetchWindow()!.bringSubviewToFront(maskView)
                    }
                    if let terminal = lcm.terminal {
                        PTUtils.fetchWindow()?.bringSubviewToFront(terminal)
                    }
                }
            }
        }
#endif
    }
    
    //MARK: 截图反馈注册
    ///截图反馈注册
    public func registerScreenShotService() {
        UIScreen.pt.detectScreenShot { type in
            switch type {
            case .Normal:
                PTGCDManager.gcdAfter(time: 1) {
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                    let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                    
                    if let lastAsset = assets.firstObject {
                        if lastAsset.mediaSubtypes == .photoScreenshot {
                            self.getImage(for: lastAsset) { result in
                                if let image = result {
                                    // 在这里使用截图
                                    if self.screenShotHandle != nil {
                                        self.screenShotHandle!(image)
                                    } else {
                                        if self.screenFunc == nil {
                                            self.screenFunc = PTBaseScreenShotAlert(screenShotImage: image,dismiss: {
                                                self.screenFunc = nil
                                            })
                                            
                                            if self.screenShotActionHandle != nil {
                                                self.screenFunc!.actionHandle = self.screenShotActionHandle!
                                            }
                                        }
                                    }
                                } else {
                                    self.screenShotHandle?(nil)
                                }
                            }
                        } else {
                            self.screenShotHandle?(nil)
                        }
                    } else {
                        self.screenShotHandle?(nil)
                    }
                }
            case .Video:
                break
            }
        }
    }
}

extension PTBaseViewController {
    public var emptyDataViewConfig:PTEmptyDataViewConfig? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.emptyViewConfigCallBack, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } get {
            let obj =  objc_getAssociatedObject(self, &AssociatedKeys.emptyViewConfigCallBack)
            guard let config = obj as? PTEmptyDataViewConfig else {
                return nil
            }
            return config
        }
    }
}

//MARK: 空数据的界面展示iOS17之后
@available(iOS 17, *)
extension PTBaseViewController {
        
    public func showEmptyView(task: PTActionTask? = nil) {
        if emptyDataViewConfig != nil {
            let share = PTUnavailableFunction.shared
            share.emptyViewConfig = emptyDataViewConfig!
            share.emptyTap = task
            share.showEmptyView(viewController: self)
        } else {
            assertionFailure("如果使用该功能,则须要设置emptyDataViewConfig")
        }
    }
    
    public func hideEmptyView(task:PTActionTask? = nil) {
        let share = PTUnavailableFunction.shared
        share.hideUnavailableView(viewController: self, task: task)
        task?()
    }
    
    public func emptyViewLoading() {
        let share = PTUnavailableFunction.shared
        share.showEmptyLoadingView(viewController: self)
    }
}

//MARK: 界面截图后,提供分享以及反馈引导操作
extension PTBaseViewController {
        
    public var screenShotHandle:PTScreenShotOnlyGetImageHandle? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.screenShotOnlyGetImageCallBack, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } get {
            let obj =  objc_getAssociatedObject(self, &AssociatedKeys.screenShotOnlyGetImageCallBack)
            guard let handle = obj as? PTScreenShotOnlyGetImageHandle else {
                return nil
            }
            return handle
        }
    }

    public var screenShotActionHandle:PTScreenShotImageHandle? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.screenShotActionCallBack, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } get {
            let obj =  objc_getAssociatedObject(self, &AssociatedKeys.screenShotActionCallBack)
            guard let handle = obj as? PTScreenShotImageHandle else {
                return nil
            }
            return handle
        }
    }

    fileprivate var screenFunc:PTBaseScreenShotAlert? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.screenShotAlertCallBack, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } get {
            let obj =  objc_getAssociatedObject(self, &AssociatedKeys.screenShotAlertCallBack)
            guard let handle = obj as? PTBaseScreenShotAlert else {
                return nil
            }
            return handle
        }
    }
        
    func getImage(for asset: PHAsset,finish:@escaping (UIImage?)->Void) {
        asset.convertLivePhotoToImage { result in
            finish(result)
        }
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard let touch = touches.first else {
            return
        }
                
        let touchLocation = touch.location(in: view)
        if screenFunc != nil {
            if !screenFunc!.frame.contains(touchLocation) {
                screenFunc!.dismissAlert()
            }
        }
    }
}

extension PTBaseViewController {
    public func currentPresentToSheet(vc:UIViewController,overlayColor:UIColor = UIColor(white: 0, alpha: 0.25), sizes: [PTSheetSize] = [.intrinsic], options: PTSheetOptions? = nil) {
        UIViewController.currentPresentToSheet(vc: vc,overlayColor: overlayColor,sizes: sizes,options: options)
    }
}

//MARK: ScreenShot的小控件
fileprivate class PTBaseScreenShotAlert:UIView {
                
    let ItemWidth:CGFloat = 88
    let ItemHeight:CGFloat = 164
    
    var dismissTask:PTActionTask?
    
    var actionHandle:PTScreenShotImageHandle?
    
    private var AnimationValue:CGFloat {
        ItemWidth + PTAppBaseConfig.share.defaultViewSpace
    }
    
    private lazy var closeButton : UIButton = {
        let view = UIButton(type: .close)
        view.addActionHandlers { sender in
            self.dismissAlert()
        }
        return view
    }()
    
    lazy var shareImageView:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    private lazy var feedback:PTLayoutButton = {
        let view = self.viewLayoutBtnSet(title: "PT Screen feedback".localized(), image: PTAppBaseConfig.share.screenShotFeedback)
        view.addActionHandlers { sender in
            self.actionHandle?(.Feedback,self.shareImageView.image!)
            self.dismissAlert()
        }
        return view
    }()
    
    private lazy var share:PTLayoutButton = {
        let view = self.viewLayoutBtnSet(title: "PT Screen share".localized(), image: PTAppBaseConfig.share.screenShotShare)
        view.addActionHandlers { sender in
            self.actionHandle?(.Share,self.shareImageView.image!)
            self.dismissAlert()
        }
        return view
    }()

    private lazy var line:UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()

    init(screenShotImage:UIImage,dismiss: PTActionTask? = nil) {
        super.init(frame: CGRect(x: CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace - ItemWidth, y: CGFloat.kSCREEN_HEIGHT - CGFloat.kTabbarHeight_Total - ItemHeight - 15 - CGFloat.kNavBarHeight_Total, width: ItemWidth, height: ItemHeight))
        backgroundColor = .DevMaskColor
        
        dismissTask = dismiss
        
        addSubviews([closeButton,feedback,line,share,shareImageView])
        closeButton.snp.makeConstraints { make in
            make.right.top.equalToSuperview().inset(5)
            make.width.height.equalTo(15)
        }
        
        feedback.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(5)
            make.bottom.equalToSuperview()
            make.height.equalTo(24)
        }
        
        line.snp.makeConstraints { make in
            make.left.right.equalTo(self.feedback)
            make.height.equalTo(1)
            make.top.equalTo(self.feedback.snp.top)
        }
        
        share.snp.makeConstraints { make in
            make.left.right.height.equalTo(self.feedback)
            make.bottom.equalTo(self.line.snp.top)
        }
        
        shareImageView.image = screenShotImage
        shareImageView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(5)
            make.top.equalTo(closeButton.snp.bottom).offset(5)
            make.bottom.equalTo(self.share.snp.top).offset(-5)
        }
        
        PTUtils.getCurrentVC().view.addSubview(self)
        showAlert()
        
        PTGCDManager.gcdMain {
            self.viewCorner(radius: 5,borderWidth: 0,borderColor: .clear)
            self.shareImageView.viewCorner(radius: 5)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showAlert() {
        PTAnimationFunction.animationIn(animationView: self, animationType: .Right, transformValue: AnimationValue)
    }
    
    func dismissAlert() {
        PTAnimationFunction.animationOut(animationView: self, animationType: .Right, toValue: AnimationValue, animation: {
            self.alpha = 0
        }) { ok in
            self.removeFromSuperview()
            self.dismissTask?()
        }
    }
    
    func viewLayoutBtnSet(title:String,image:Any) -> PTLayoutButton {
        let view = PTLayoutButton()
        view.layoutStyle = .leftImageRightTitle
        view.midSpacing = 5
        view.imageSize = CGSize(width: 15, height: 15)
        view.normalTitleFont = .appfont(size: 13)
        view.normalTitle = title
        view.normalTitleColor = .white
        view.layoutLoadImage(contentData: image)
        return view
    }
}
