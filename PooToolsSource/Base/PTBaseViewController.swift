//
//  PTBaseViewController.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
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

// MARK: - 导航栏样式枚举
public enum PTNavigationBarStyle {
    case gradient(type: Imagegradien = .LeftToRight, colors: [DynamicColor])
    case solid(UIColor)
    case transparent
    case custom((UINavigationBar) -> Void)   // 给子类最大自由度
    
    // 提供一个默认样式入口（避免把默认写在关联值上）
    public static var `default`: PTNavigationBarStyle {
        return .gradient(type: .LeftToRight, colors: [UIColor.white,UIColor.white])
    }
}

open class PTNavTitleContainer: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required public init?(coder: NSCoder) { fatalError() }

    open override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: PTAppBaseConfig.share.bavTitleContainerHeight) // 保持标准高度
    }
}

@objcMembers
open class PTBaseViewController: UIViewController {
            
    deinit {
        PTNSLogConsole("[\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())]===已被释放",levelType: PTLogMode,loggerType: .ViewCycle)
        removeFromSuperStatusBar()
    }
    
    // 用于自定义背景View（渐变、纯色、透明）
    public private(set) lazy var navBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        view.clipsToBounds = true
        return view
    }()
    private weak var currentCustomNavView: UIView?
    public private(set) lazy var navBackgroundControlView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        view.clipsToBounds = true
        return view
    }()

    // MARK: - 子类 override 以决定样式
    open func preferredNavigationBarStyle() -> PTNavigationBarStyle {
        return .solid(.white)
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        PTNSLogConsole("加载==============================\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())）",levelType: PTLogMode,loggerType: .ViewCycle)
        applyNavigationBarStyle()
        setOtherToControlBar()
        navViewSet()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    open override func viewWillDisappear(_ animated:Bool) {
        super.viewWillDisappear(animated)
        PTNSLogConsole("离开==============================\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())）",levelType: PTLogMode,loggerType: .ViewCycle)
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
        
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupBaseConfigs()
        
        PTRotationManager.shared.orientationMaskDidChange = { orientationMask in
            if let barBackground = self.navigationController?.navigationBar.subviews.first {
                self.navBackgroundView.frame = barBackground.bounds
            }
            self.viewControllerOrientation(orientationMask)
        }
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
    
    open func viewControllerOrientation(_ orientationMask: UIInterfaceOrientationMask) {}
    
    // 定義一個函數來解析URL中的鍵值對
    public func parseURLParameters(url: URL) -> [String: String]? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }
        
        var parameters = [String: String]()
        
        for queryItem in queryItems {
            parameters[queryItem.name] = queryItem.value
        }
        
        return parameters
    }
        
    // MARK: - 公共 API（子类/外部可调用）
    open func setCustomBackButton(image: UIImage?,
                                  backgroundColor: UIColor = .clear,
                                  size: CGSize = CGSize(width: 30, height: 30),
                                  leftPadding: CGFloat = 0,
                                  action: PTActionTask? = nil) {
        let navBarHeight = CGFloat.kNavBarHeight
        
        let backButton = PTBaseButton(type: .custom)
        if let img = image { backButton.setImage(img.withRenderingMode(.alwaysOriginal), for: .normal) }
        backButton.backgroundColor = backgroundColor
        backButton.frame = CGRect(origin: .zero, size: size)
        backButton.isUserInteractionEnabled = true
        backButton.addActionHandlers { sender in
            if let tapAction = action {
                tapAction()
            } else {
                self.backButtonTapped()
            }
        }
        backButton.viewCorner(radius: size.height / 2)
        let container = UIView()
        container.snp.makeConstraints { make in
            make.height.equalTo(navBarHeight)
            make.width.equalTo(size.width + leftPadding)
        }
        container.isUserInteractionEnabled = true
        container.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(leftPadding)
            make.size.equalTo(size)
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: container)
        if let nav = navigationController {
            nav.navigationBar.subviews.forEach {
                if $0 is UIButton || $0.description.contains("BarButton") || $0.description.contains("SearchBar") {
                    nav.navigationBar.bringSubviewToFront($0)
                }
            }
        }
    }
    
    // 新增：直接传入任意自定义 view
    open func setCustomBackButtonView(_ customView: UIView,
                                      size: CGSize? = CGSize(width: 34, height: 34),
                                      action: PTActionTask? = nil) {
        let finalSize = size ?? customView.frame.size
        // 容器 UIView
        let container = UIView()
        
        // 加 customView
        container.addSubview(customView)
        customView.snp.makeConstraints { make in
            make.edges.equalToSuperview() // 填满 container
        }
        
        // 点击事件
        if let action = action {
            let button = UIButton(type: .custom)
            button.addSubview(container)
            container.snp.makeConstraints { make in
                make.size.equalTo(finalSize)
            }
            button.addActionHandlers { _ in
                action()
            }
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
            button.snp.makeConstraints { make in
                make.size.equalTo(finalSize)
            }
        } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: container)
            container.snp.makeConstraints { make in
                make.size.equalTo(finalSize)
            }
        }
    }

    //MARK: 需要设置按钮Bounds
    open func setCustomRightButtons(buttons: [UIView], buttonSpacing: CGFloat = 10, rightPadding: CGFloat = 0) {
        guard !buttons.isEmpty else {
            navigationItem.rightBarButtonItem = nil
            return
        }

        let stackView = UIStackView(arrangedSubviews: buttons)
        stackView.axis = .horizontal
        stackView.spacing = buttonSpacing
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.isUserInteractionEnabled = true
        stackView.arrangedSubviews.forEach { view in
            view.snp.makeConstraints { make in
                make.size.equalTo(view.bounds.size)
            }
        }

        let container = UIView()
        container.addSubview(stackView)
        container.isUserInteractionEnabled = true

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 自动测量合适大小
        let fittingSize = stackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        
        if rightPadding <= 0 {
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: container)
        } else {
            let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            fixedSpace.width = rightPadding // 距离屏幕右侧的间距
            navigationItem.rightBarButtonItems = [fixedSpace,UIBarButtonItem(customView: container)]
        }

        container.snp.makeConstraints { make in
            make.size.equalTo(fittingSize)
        }
    }

    open func setCustomTitleView(_ view: UIView? = nil) {
        navigationItem.titleView = view
    }

    // MARK: - 设置自定义导航栏背景
    open func setFullNavigationBarView(_ customView: UIView? = nil) {
        guard let _ = navigationController else { return }
        // 先保证背景存在
        applyNavigationBarStyle()
        navBackgroundControlView.isUserInteractionEnabled = false
        // 移除旧的
        if let oldView = currentCustomNavView, oldView != customView {
            oldView.removeFromSuperview()
            currentCustomNavView = nil
        }
        
        guard let navView = customView else { return }
        navBackgroundControlView.addSubview(navView)
        navBackgroundControlView.isUserInteractionEnabled = true
        navView.snp.remakeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(CGFloat.kNavBarHeight)
        }
    }
    
    // MARK: - 设置自定义导航栏背景
    open func setOtherToControlBar(_ customView: UIView? = nil) {
        guard let _ = navigationController else { return }
        // 先保证背景存在
        applyNavigationBarStyle()
        navBackgroundControlView.isHidden = true
        guard let navView = customView else { return }
        navBackgroundControlView.addSubview(navView)
        navBackgroundControlView.isHidden = false
    }

    open func updateNavigationBarBackground(scrollView: UIScrollView, changeOffset: CGFloat = 100, color: UIColor = .white) {
        let offset = scrollView.contentOffset.y
        let alpha = min(1, max(0, offset / changeOffset))
        // 根据 preferredNavigationBarStyle 应用
        switch preferredNavigationBarStyle() {
        case .gradient( _, _):
            navBackgroundView.alpha = alpha
        case .solid(_):
            navBackgroundView.backgroundColor = color.withAlphaComponent(alpha)
        case .transparent:break
        case .custom(_):break
        }
    }
    
    open func setNavigationBarBackgroundAlpha(clear:Bool = false) {
        navBackgroundView.alpha = clear ? 0 : 1
    }

    open func setNavTitleFont(_ navigationController: UINavigationController, color: DynamicColor = PTAppBaseConfig.share.navTitleTextColor, font: UIFont = PTAppBaseConfig.share.navTitleFont) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        // 设置标题属性
        appearance.titleTextAttributes = [
            .font: font,
            .foregroundColor: color
        ]
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
    }

    // MARK: - 私有实现
    private func setupBaseConfigs() {
        UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = [.top, .left, .bottom, .right]
        definesPresentationContext = true
        view.backgroundColor = PTAppBaseConfig.share.viewControllerBaseBackgroundColor
        navigationController?.hidesBarsOnSwipe = PTAppBaseConfig.share.hidesBarsOnSwipe
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
                StatusBarManager.shared.style = previousTraitCollection.userInterfaceStyle == .dark ? .lightContent : .darkContent
                self.baseTraitCollectionDidChange(style:previousTraitCollection.userInterfaceStyle)
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }

    public func applyNavigationBarStyle() {
        guard let nav = navigationController else { return }
        // 先清理旧背景
        clearNavBackgroundView()

        // 根据 preferredNavigationBarStyle 应用
        switch preferredNavigationBarStyle() {
        case .gradient(let type, let colors):
            setupCustomNavigationBar(nav, isGradient: true, type: type, gradientColors: colors,fontColor: .white)
            changeStatusBar(type: .Dark)
        case .solid(let color):
            setupCustomNavigationBar(nav, isGradient: false, barColor: color,fontColor: .black)
            changeStatusBar(type: .Auto)
        case .transparent:
            setupCustomNavigationBar(nav, isGradient: false, barColor: .clear,fontColor: .black)
            changeStatusBar(type: .Auto)
        case .custom(let config):
            config(nav.navigationBar)
        }
    }

    // MARK: - 清理背景
    public func clearNavBackgroundView() {
        navBackgroundView.subviews.forEach { $0.removeFromSuperview() }
        navBackgroundView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        navBackgroundView.removeFromSuperview()
        navBackgroundControlView.subviews.forEach { $0.removeFromSuperview() }
        navBackgroundControlView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        navBackgroundControlView.removeFromSuperview()

        // 保险检查，避免 pop 过程中 navigationController 已释放导致崩溃
        if let nav = navigationController {
            nav.navigationBar.subviews.first?.subviews.filter({ $0.tag == 9999 }).forEach { $0.removeFromSuperview() }
            nav.navigationBar.subviews.filter({ $0.tag == 100001 }).forEach { $0.removeFromSuperview() }
        }
    }

    /// 创建并插入一个背景容器到 navigationBar 的最底层
    public func setupCustomNavigationBar(_ navigationController: UINavigationController,
                                  isGradient: Bool = false,
                                  type: Imagegradien = .LeftToRight,
                                  gradientColors: [UIColor] = [],
                                  barColor: UIColor = .white,
                                  fontColor: UIColor = PTAppBaseConfig.share.navTitleTextColor,
                                  font: UIFont = PTAppBaseConfig.share.navTitleFont) {
        // 保证 navigationBar 是透明配置（appearance 已处理）
        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController.navigationBar.shadowImage = UIImage()
        navigationController.navigationBar.isTranslucent = true

        // 先移除旧 tag 的 view（额外保险）
        navigationController.navigationBar.subviews.first?.subviews.filter({ $0.tag == 9999 }).forEach { $0.removeFromSuperview() }
        navigationController.navigationBar.subviews.filter({ $0.tag == 100001 }).forEach { $0.removeFromSuperview() }

        if let barBackground = navigationController.navigationBar.subviews.first {
            
            let containerFrame = barBackground.bounds
            let container = UIView(frame: containerFrame)
            container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            container.isUserInteractionEnabled = false
            container.tag = 9999
            
            if isGradient {
                let colorsToUse = gradientColors.isEmpty ? PTAppBaseConfig.share.navGradientColors : gradientColors
                container.backgroundGradient(type: type, colors: colorsToUse)
            } else {
                container.backgroundColor = barColor
            }
            
            barBackground.insertSubview(container, at: 0)
            self.navBackgroundView = container
        }
        
        var controlContainerFrame = CGRect.zero
        switch PTRotationManager.shared.orientationMask {
        case .landscape,.landscapeLeft,.landscapeRight:
            controlContainerFrame = CGRectMake(0, 0, CGFloat.kNavBarWidth, CGFloat.kNavBarHeight)
        case .portrait,.portraitUpsideDown:
            controlContainerFrame = CGRectMake(0, -CGFloat.statusBarHeight(), CGFloat.kNavBarWidth, CGFloat.kNavBarHeight_Total)
        default:
            controlContainerFrame = CGRectMake(0, -CGFloat.statusBarHeight(), CGFloat.kNavBarWidth, CGFloat.kNavBarHeight_Total)
        }
        
        let controlContainer = UIView(frame: controlContainerFrame)
        controlContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        controlContainer.isUserInteractionEnabled = false
        controlContainer.clipsToBounds = true
        controlContainer.tag = 100001
        navigationController.navigationBar.insertSubview(controlContainer, at: 0)
        self.navBackgroundControlView = controlContainer

        // 使用 UINavigationBarAppearance 保证无黑条
        setNavTitleFont(navigationController, color: fontColor, font: font)
    }

    // MARK: - 其他
    open func navViewSet() {
        guard let nav = navigationController else { return }
        if nav.viewControllers.firstIndex(of: self) ?? 0 > 0 {
            // 子类可以在 preferredNavigationBarStyle 控制颜色，这里只决定使用哪个 back image
            var imageName:UIImage
            switch preferredNavigationBarStyle() {
            case .gradient(type: .LeftToRight, colors: PTAppBaseConfig.share.navGradientColors):
                if #available(iOS 26.0, *) {
                    imageName = PTAppBaseConfig.share.navGradientBack26Image
                } else {
                    imageName = PTAppBaseConfig.share.navGradientBackImage
                }
                setNavTitleFont(nav,color: .white)
            default:
                imageName = (PTDarkModeOption.isLight ? PTAppBaseConfig.share.viewControllerBackItemImage : PTAppBaseConfig.share.viewControllerBackDarkItemImage)
                setNavTitleFont(nav,color: .black)
            }
            setCustomBackButton(image: imageName)
        }
    }

    @objc func backButtonTapped() {
        self.returnFrontVC()
    }
}

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
            
    //MARK: 是否隱藏NavBar
    ///是否隱藏NavBar
    public convenience init(hideBaseNavBar: Bool) {
        self.init()
        navigationController?.navigationBar.isHidden = hideBaseNavBar
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
        } else if let nav = navigationController {
            // pop 时用主线程保证安全
            PTGCDManager.gcdMain {
                nav.popViewController(animated: true) {
                    completion?()
                }
            }
        } else {
            completion?()
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
            guard type == .Normal else {
                self.screenShotHandle?(nil)
                return
            }

            PTGCDManager.gcdAfter(time: 1) {
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

                guard let lastAsset = PHAsset.fetchAssets(with: .image, options: fetchOptions).firstObject,
                      lastAsset.mediaSubtypes == .photoScreenshot else {
                    self.screenShotHandle?(nil)
                    return
                }

                self.getImage(for: lastAsset) { image in
                    guard let image else {
                        self.screenShotHandle?(nil)
                        return
                    }

                    if let handler = self.screenShotHandle {
                        handler(image)
                    } else {
                        if self.screenFunc == nil {
                            self.screenFunc = PTBaseScreenShotAlert(screenShotImage: image) {
                                self.screenFunc = nil
                            }
                            if let actionHandle = self.screenShotActionHandle {
                                self.screenFunc?.actionHandle = actionHandle
                            }
                        } else {
                            self.screenShotHandle?(nil)
                        }
                    }
                }
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
        
    func getImage(for asset: PHAsset,finish:@escaping (UIImage?) -> Void) {
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
        if let scree = screenFunc {
            if !scree.frame.contains(touchLocation) {
                scree.dismissAlert()
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
            if let image = self.shareImageView.image {
                self.actionHandle?(.Feedback,image)
                self.dismissAlert()
            }
        }
        return view
    }()
    
    private lazy var share:PTLayoutButton = {
        let view = self.viewLayoutBtnSet(title: "PT Screen share".localized(), image: PTAppBaseConfig.share.screenShotShare)
        view.addActionHandlers { _ in
            if let image = self.shareImageView.image {
                self.actionHandle?(.Share,image)
                self.dismissAlert()
            }
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
