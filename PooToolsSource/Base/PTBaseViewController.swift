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

public typealias PTScreenShotImageHandle = (PTScreenShotActionType,UIImage) -> Void

public enum PTScreenShotActionType {
    case Share
    case Feedback
}

@objc public enum VCStatusBarChangeStatusType : Int {
    case Dark
    case Light
    case Auto
}

public class PTEmptyDataViewConfig : PTBaseModel {
    var mainTitleAtt:ASAttributedString? = """
            \(wrap: .embedding("""
            \("主标题",.foreground(.random),.font(.appfont(size: 20)),.paragraph(.alignment(.center)))
            """))
            """
    var secondaryEmptyAtt:ASAttributedString? = """
            \(wrap: .embedding("""
            \("副标题",.foreground(.random),.font(.appfont(size: 18)),.paragraph(.alignment(.center)))
            """))
            """
    var buttonTitle:String? = ""
    var buttonFont:UIFont = .appfont(size: 18)
    var buttonTextColor:UIColor = .systemBlue
    var image:UIImage? = UIImage(systemName: "exclamationmark.triangle")!
    var backgroundColor:UIColor = .clear
    var imageToTextPadding:CGFloat = 10
    var textToSecondaryTextPadding:CGFloat = 5
    var buttonToSecondaryButtonPadding:CGFloat = 15
}

#if POOTOOLS_NAVBARCONTROLLER
@objcMembers
open class PTBaseViewController: ZXNavigationBarController {
    
    public var emptyDataViewConfig:PTEmptyDataViewConfig?
    
    public var screenShotHandle:((UIImage?)->Void)?

    fileprivate var screenFunc:PTBaseScreenShotAlert?
    public var screenShotActionHandle:PTScreenShotImageHandle?

    @available(iOS 17, *)
    fileprivate func emptyButtonConfig() -> UIButton.Configuration {
        var plainConfig = UIButton.Configuration.plain()
        plainConfig.title = self.emptyDataViewConfig!.buttonTitle!
        plainConfig.titleTextAttributesTransformer = .init({ container in
            container.merging(AttributeContainer.font(self.emptyDataViewConfig!.buttonFont).foregroundColor(self.emptyDataViewConfig!.buttonTextColor))
        })
        return plainConfig
    }
    
    @available(iOS 17, *)
    fileprivate func emptyConfig(task:PTActionTask? = nil) -> UIContentUnavailableConfiguration {
        var configs = UIContentUnavailableConfiguration.empty()
        configs.imageToTextPadding = self.emptyDataViewConfig!.imageToTextPadding
        configs.textToButtonPadding = self.emptyDataViewConfig!.textToSecondaryTextPadding
        configs.buttonToSecondaryButtonPadding = self.emptyDataViewConfig!.buttonToSecondaryButtonPadding
        if self.emptyDataViewConfig?.mainTitleAtt != nil {
            configs.attributedText = self.emptyDataViewConfig!.mainTitleAtt!.value
        }
        
        if self.emptyDataViewConfig?.secondaryEmptyAtt != nil {
            configs.secondaryAttributedText = self.emptyDataViewConfig!.secondaryEmptyAtt!.value
        }
        
        if self.emptyDataViewConfig?.image != nil {
            configs.image = self.emptyDataViewConfig!.image!
        }
        if !(self.emptyDataViewConfig?.buttonTitle ?? "").stringIsEmpty() {
            configs.button = self.emptyButtonConfig()
        }
        configs.buttonProperties.primaryAction = UIAction { sender in
            if task != nil {
                task!()
            }
        }
        var configBackground = UIBackgroundConfiguration.clear()
        configBackground.backgroundColor = self.emptyDataViewConfig!.backgroundColor
        
        configs.background = configBackground

        return configs
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
    
    deinit {
        PTNSLogConsole("[\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())]===已被释放")
        self.removeFromSuperStatusBar()
    }
    
    @objc open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        PTNSLogConsole("加载==============================\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())）")
        if self.presentationController != nil {
            self.zx_leftClickedBlock { itenBtn in
                self.viewDismiss()
            }
        }
    }
    
    @objc override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        PTNSLogConsole("离开==============================\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())）")
    }
    
    @objc override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    //MARK: 是否隱藏NavBar
    ///是否隱藏NavBar
    public convenience init(hideBaseNavBar: Bool) {
        self.init()
        self.zx_hideBaseNavBar = hideBaseNavBar
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        PHPhotoLibrary.shared().register(self)

        UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
        // Do any additional setup after loading the view.
        self.edgesForExtendedLayout = []
        self.definesPresentationContext = true
        
        self.view.backgroundColor = PTAppBaseConfig.share.viewControllerBaseBackgroundColor
    }
    
    //MARK: 拦截返回上一页
    ///拦截返回上一页
    /// - Parameter popBlock: 是否允许放回上一页
    open func openPopIntercept(popBlock: @escaping (_ viewController:ZXNavigationBarController, _ popBlockFrom:ZXNavPopBlockFrom)-> Bool) {
        //因FDFullscreenPopGesture默认会在控制器即将展示时显示系统导航栏，与ZXNavigationBar共同使用时会造成系统导航栏出现一下又马上消失，因此需要以下设置
        self.fd_prefersNavigationBarHidden = true
        //当您通过zx_handlePopBlock拦截侧滑返回手势时，请设置fd_interactivePopDisabled为YES以关闭FDFullscreenPopGesture在当前控制器的全屏返回手势，否则无法拦截。
        self.fd_interactivePopDisabled = true
        
        self.zx_handlePopBlock = popBlock
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
        AppDelegateEXFunction.share.isFullScreen = isFullScreen
        
        if #available(iOS 16.0, *) {
            setNeedsUpdateOfPrefersPointerLocked()
            guard let scence = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            let orientation:UIInterfaceOrientationMask = isFullScreen ? .landscape : .portrait
            let geometryPreferencesIOS = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: orientation)
            scence.requestGeometryUpdate(geometryPreferencesIOS) { error in
                PTNSLogConsole("强制\(isFullScreen ? "横屏" : "竖屏")错误:\(error)")
            }
        } else {
            let oriention:UIDeviceOrientation = isFullScreen ? .landscapeRight : .portrait
            UIDevice.current.setValue(oriention.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            StatusBarManager.shared.style = UITraitCollection.current.userInterfaceStyle == .dark ? .lightContent : .darkContent
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    @objc public func returnFrontVC(completion:PTActionTask? = nil) {
        if self.presentingViewController != nil {
            self.dismiss(animated: true, completion: completion)
        } else {
            self.navigationController?.popViewController(animated: true, completion)
        }
    }
}
#else
@objcMembers
open class PTBaseViewController: UIViewController {
    
    public var emptyDataViewConfig:PTEmptyDataViewConfig?
    
    public var screenShotHandle:((UIImage?)->Void)?
    
    fileprivate var screenFunc:PTBaseScreenShotAlert?
    public var screenShotActionHandle:PTScreenShotImageHandle?

    @available(iOS 17, *)
    fileprivate func emptyButtonConfig() -> UIButton.Configuration {
        var plainConfig = UIButton.Configuration.plain()
        plainConfig.title = emptyDataViewConfig!.buttonTitle!
        plainConfig.titleTextAttributesTransformer = .init({ container in
            container.merging(AttributeContainer.font(self.emptyDataViewConfig!.buttonFont).foregroundColor(self.emptyDataViewConfig!.buttonTextColor))
        })
        return plainConfig
    }
    
    @available(iOS 17, *)
    fileprivate func emptyConfig(task:PTActionTask? = nil) -> UIContentUnavailableConfiguration {
        var configs = UIContentUnavailableConfiguration.empty()
        configs.imageToTextPadding = emptyDataViewConfig!.imageToTextPadding
        configs.textToButtonPadding = emptyDataViewConfig!.textToSecondaryTextPadding
        configs.buttonToSecondaryButtonPadding = emptyDataViewConfig!.buttonToSecondaryButtonPadding
        if emptyDataViewConfig?.mainTitleAtt != nil {
            configs.attributedText = emptyDataViewConfig!.mainTitleAtt!.value
        }
        
        if emptyDataViewConfig?.secondaryEmptyAtt != nil {
            configs.secondaryAttributedText = emptyDataViewConfig!.secondaryEmptyAtt!.value
        }
        
        if emptyDataViewConfig?.image != nil {
            configs.image = emptyDataViewConfig!.image!
        }
        if !(emptyDataViewConfig?.buttonTitle ?? "").stringIsEmpty() {
            configs.button = emptyButtonConfig()
        }
        configs.buttonProperties.primaryAction = UIAction { sender in
            if task != nil {
                task!()
            }
        }
        var configBackground = UIBackgroundConfiguration.clear()
        configBackground.backgroundColor = emptyDataViewConfig!.backgroundColor
        
        configs.background = configBackground

        return configs
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
    
    deinit {
        PTNSLogConsole("[\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())]===已被释放")
        removeFromSuperStatusBar()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        PTNSLogConsole("加载==============================\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())）")
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        PTNSLogConsole("离开==============================\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())）")
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    //MARK: 是否隱藏NavBar
    ///是否隱藏NavBar
    public convenience init(hideBaseNavBar: Bool) {
        self.init()
        navigationController?.navigationBar.isHidden = hideBaseNavBar
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        PHPhotoLibrary.shared().register(self)

        UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
        // Do any additional setup after loading the view.
        edgesForExtendedLayout = []
        definesPresentationContext = true
        
        view.backgroundColor = PTAppBaseConfig.share.viewControllerBaseBackgroundColor
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
        AppDelegateEXFunction.share.isFullScreen = isFullScreen
        
        if #available(iOS 16.0, *) {
            setNeedsUpdateOfPrefersPointerLocked()
            guard let scence = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            let orientation:UIInterfaceOrientationMask = isFullScreen ? .landscape : .portrait
            let geometryPreferencesIOS = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: orientation)
            scence.requestGeometryUpdate(geometryPreferencesIOS) { error in
                PTNSLogConsole("强制\(isFullScreen ? "横屏" : "竖屏")错误:\(error)")
            }
        } else {
            let oriention:UIDeviceOrientation = isFullScreen ? .landscapeRight : .portrait
            UIDevice.current.setValue(oriention.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            StatusBarManager.shared.style = UITraitCollection.current.userInterfaceStyle == .dark ? .lightContent : .darkContent
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    public func returnFrontVC(completion:PTActionTask? = nil) {
        if presentingViewController != nil {
            dismiss(animated: true, completion: completion)
        } else {
            navigationController?.popViewController(animated: true, completion)
        }
    }
}
#endif

@available(iOS 17, *)
extension PTBaseViewController {
    public func showEmptyView(task: PTActionTask? = nil) {
        if emptyDataViewConfig != nil {
            let config = emptyConfig(task:task)
            contentUnavailableConfiguration = config
        } else {
            assertionFailure("如果使用该功能,则须要设置emptyDataViewConfig")
        }
    }
    
    public func hideEmptyView(task:PTActionTask? = nil) {
        contentUnavailableConfiguration = nil
        if task != nil {
            task!()
        }
    }
    
    public func emptyViewLoading() {
        let loadingConfig = UIContentUnavailableConfiguration.loading()
        contentUnavailableConfiguration = loadingConfig
    }
}

extension PTBaseViewController: PHPhotoLibraryChangeObserver {
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        PTGCDManager.gcdAfter(time: 1) {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            
            if let lastAsset = assets.firstObject {
                if lastAsset.mediaSubtypes == .photoScreenshot {
                    if let image = self.getImage(for: lastAsset) {
                        PTNSLogConsole("产生了截图")
                        // 在这里使用截图
                        if self.screenShotHandle != nil {
                            self.screenShotHandle!(image)
                        } else {
                            if self.screenFunc == nil {
                                self.screenFunc = PTBaseScreenShotAlert(screenShotImage: image,dismiss: {
                                    self.screenFunc = nil
                                })
                                self.screenFunc?.actionHandle = self.screenShotActionHandle
                            }
                        }
                    } else {
                        if self.screenShotHandle != nil {
                            self.screenShotHandle!(nil)
                        }
                    }
                } else {
                    if self.screenShotHandle != nil {
                        self.screenShotHandle!(nil)
                    }
                }
            } else {
                if self.screenShotHandle != nil {
                    self.screenShotHandle!(nil)
                }
            }
        }
    }
    
    func getImage(for asset: PHAsset) -> UIImage? {
        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = true

        var image: UIImage?
        imageManager.requestImage(for: asset, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), contentMode: .aspectFit, options: options) { (result, info) in
            image = result
        }

        return image
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

/**
    ScreenShot的小控件
 */
class PTBaseScreenShotAlert:UIView {
                
    let ItemWidth:CGFloat = 88
    let ItemHeight:CGFloat = 164
    
    var dismissTask:PTActionTask?
    
    var actionHandle:PTScreenShotImageHandle!
    
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
        let view = self.viewLayoutBtnSet(title: "意见反馈", image: "square.and.pencil")
        view.addActionHandlers { sender in
            self.actionHandle(.Feedback,self.shareImageView.image!)
            self.dismissAlert()
        }
        return view
    }()
    
    private lazy var share:PTLayoutButton = {
        let view = self.viewLayoutBtnSet(title: "分享好友", image: "square.and.arrow.up")
        view.addActionHandlers { sender in
            self.actionHandle(.Share,self.shareImageView.image!)
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
            if self.dismissTask != nil {
                self.dismissTask!()
            }
        }
    }
    
    func viewLayoutBtnSet(title:String,image:String) -> PTLayoutButton {
        let view = PTLayoutButton()
        view.layoutStyle = .leftImageRightTitle
        view.midSpacing = 5
        view.imageSize = CGSize(width: 15, height: 15)
        view.titleLabel?.font = .appfont(size: 13)
        view.setTitle(title, for: .normal)
        view.setTitleColor(.white, for: .normal)
        PTLoadImageFunction.loadImage(contentData: image) { images, image in
            if (images?.count ?? 0) > 1 {
                view.imageView?.animationImages = images
                view.imageView?.animationDuration = 2
                view.imageView?.startAnimating()
            } else if images?.count == 1 {
                view.setImage(image, for: .normal)
            }
        }
        
        return view
    }
}
