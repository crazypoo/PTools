//
//  PTBaseViewController.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift
import AttributedString
import Photos
import SnapKit
import SafeSFSymbols
#if canImport(PToolsCore)
import PToolsCore
#endif

public typealias PTScreenShotImageHandle = (PTScreenShotActionType,UIImage) -> Void
public typealias PTScreenShotOnlyGetImageHandle = (UIImage?) -> Void


@objcMembers
@MainActor
open class PTBaseViewController: UIViewController, PTNavigationConfigurable {

    private var hidesBaseNavigationBarOnLoad = false
                   
    // MARK: - Custom Back Button

    /// setCustomBackButtonView 创建的外层容器
    private weak var customBackButtonContainer: UIView?

    /// 实际传入的自定义 Back View
    private weak var customBackButtonContentView: UIView?

    open func prefersLargeTitle() -> Bool {
        return false
    }
    
    open func allowControlNavBar() -> Bool {
        return true
    }
    
    open var pt_Title:String? {
        didSet {
            let item = PTNavigationBarManager.shared.item(for: self)
            item.navTitle = pt_Title ?? ""
            PTNavigationBarManager.shared.update(item: item, for: self)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .PTRotationOrientationDidChange, object: nil)
        PTNSLogConsole("[\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())]===已被释放",levelType: PTLogMode,loggerType: .viewCycle)
    }
    
    // MARK: - 子类 override 以决定样式
    open func preferredNavigationBarStyle() -> PTNavigationBarStyle {
        return .solid(.white)
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        PTNSLogConsole("加载==============================\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())）",levelType: PTLogMode,loggerType: .viewCycle)
        refreshNavigationBarIfNeeded()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PTNSLogConsole("加载完==============================\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())）",levelType: PTLogMode,loggerType: .viewCycle)
        refreshNavigationBarIfNeeded()
    }
    
    open override func viewWillDisappear(_ animated:Bool) {
        super.viewWillDisappear(animated)
        PTNSLogConsole("离开==============================\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())）",levelType: PTLogMode,loggerType: .viewCycle)
        if let presenting = presentingViewController {
            PTNavigationBarManager.shared.restoreIfNeeded(for: presenting)
        }
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
        
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupBaseConfigs()
        if let sheet = self.sheetViewController,let nav = sheet.childViewController as? UINavigationController {
            PTNavigationBarManager.shared.bind(to: nav)
        } else {
            if let nav = navigationController {
                PTNavigationBarManager.shared.bind(to: nav)
            }
        }

        if hidesBaseNavigationBarOnLoad {
            navigationController?.navigationBar.isHidden = true
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRotationOrientationChange(_:)),
            name: .PTRotationOrientationDidChange,
            object: nil
        )
    }
    
    open override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        PTNavigationBarManager.shared.restoreIfNeeded(for: self)
    }

    /// 只在页面没有转场时恢复一次导航栏状态，避免生命周期重复刷新。
    private func refreshNavigationBarIfNeeded() {
        guard transitionCoordinator == nil else { return }
        PTNavigationBarManager.shared.restoreIfNeeded(for: self)

        if let sheet = sheetViewController,
           let nav = sheet.childViewController as? UINavigationController {
            PTNavigationBarManager.shared.apply(style: preferredNavigationBarStyle(), in: nav)
        } else if let nav = navigationController {
            PTNavigationBarManager.shared.apply(style: preferredNavigationBarStyle(), in: nav)
        }
    }

    @objc private func handleRotationOrientationChange(_ notification: Notification) {
        guard let orientationMask = notification.object as? UIInterfaceOrientationMask else { return }
        viewControllerOrientation(orientationMask)
    }
    
    @MainActor open func prepareDefaultNavigationBarItem() {
        let item = PTNavigationBarManager.shared.item(for: self)
        item.barColorStyle = preferredNavigationBarStyle()
        
        // 此时 Navigation Stack 已经稳定，可以安全判断是否为第一层
        let isNotRoot = self.navigationController?.viewControllers.first != self
        let isModal = self.isBeingPresented ||
                          self.navigationController?.isBeingPresented == true ||
                          self.presentingViewController != nil ||
                          self.navigationController?.presentingViewController != nil ||
                          self.sheetViewController != nil
        
        if isNotRoot || isModal {
            pt_prefersTabBarHidden = true
            // 关键防护：仅当目前没有任何左侧按钮时，才加上默认的返回按钮，避免重复添加
            if item.leftView.isEmpty {
                let backBtn = baseBackButton()
                            
                backBtn.addActionHandlers { [weak self] _ in
                    self?.returnFrontVC()
                }
                
                self.setCustomBackButtonView(backBtn,size: backBtn.bounds.size)
            }
        }
    }
        
    private func setBaseBackButton() {
        let backBtn = baseBackButton()
        backBtn.addActionHandlers { seder in
            if self.navigationController?.viewControllers.first != self,let findFirst = self.navigationController?.viewControllers.first,let _ = findFirst.sheetViewController {
                self.navigationController?.popViewController(animated: true)
            } else {
                self.viewDismiss()
            }
        }
        setCustomBackButtonView(backBtn)
    }

    private func baseBackButton() -> PTBaseButton {
        let backBtn = PTBaseButton(type: .custom)
        backBtn.setImage(PTAppBaseConfig.share.viewControllerBackItemImage, for: .normal)
        backBtn.bounds = CGRectMake(0, 0, PTAppBaseConfig.share.navBarButtonSize, PTAppBaseConfig.share.navBarButtonSize)
        return backBtn
    }
    
    fileprivate func updateStatusBar(_ style: PTNavigationBarStyle) {
        switch style {
        case .gradient:
            changeStatusBar(type: .Dark)
        case .solid(let color):
            setStatusBarStyle(color: color)
        case .transparent:
            setStatusBarStyle(color: (self.view.backgroundColor ?? PTAppBaseConfig.share.viewControllerBaseBackgroundColor))
        }
    }
    
    private func setStatusBarStyle(color:UIColor) {
        switch color.pt_colorTone() {
        case .dark:
            changeStatusBar(type: .Dark)
        case .light:
            changeStatusBar(type: .Light)
        case .normal:
            changeStatusBar(type: .Dark)
        case .clear:
            changeStatusBar(type: .Light)
        }
    }

    open func viewControllerOrientation(_ orientationMask: UIInterfaceOrientationMask) {}
    
    // English: Keep this deprecated wrapper for source compatibility; URL parsing belongs to the Foundation core.
    // Español: Conserva este wrapper obsoleto por compatibilidad; el análisis URL pertenece al núcleo Foundation.
    // 中文：保留此弃用包装器以兼容旧代码；URL 解析统一归属 Foundation 核心。
    @available(*, deprecated, message: "Use URL.pt_queryParameters or PTURLParser.queryParameters(from:)")
    public func parseURLParameters(url: URL) -> [String: String]? {
        PTURLParser.queryParameters(from: url)
    }
        
    // MARK: - 公共 API（子类/外部可调用）
    open func setCustomBackButton(image: UIImage?,
                                  backgroundColor: UIColor = .clear,
                                  size: CGSize = CGSize(width: 30, height: 30),
                                  leftPadding: CGFloat = 0,
                                  action: PTActionTask? = nil) {
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
        let item = PTNavigationBarManager.shared.item(for: self)
        item.leftView = [backButton]
        item.leftItemSpacing = leftPadding
        PTNavigationBarManager.shared.update(item: item, for: self)
    }
    
    // 新增：直接传入任意自定义 view
    open func setCustomBackButtonView(_ customView: UIView,
                                      size: CGSize? = nil,
                                      action: PTActionTask? = nil) {
        let targetSize = size ?? CGSize(
            width: PTAppBaseConfig.share.navBarButtonSize,
            height: PTAppBaseConfig.share.navBarButtonSize
        )

        // 容器 UIView
        let container = UIView()
        container.isUserInteractionEnabled = true
        container.clipsToBounds = true
        container.bounds = CGRect(origin: .zero, size: targetSize)
        
        // 保存引用，后面语言切换时可以重新计算 Bounds
        customBackButtonContainer = container
        customBackButtonContentView = customView

        // 加 customView
        container.addSubview(customView)
        customView.snp.makeConstraints { make in
            make.edges.equalToSuperview() // 填满 container
        }
        
        // 点击事件
        if let action = action {
            let button = UIButton(type: .custom)
            container.addSubview(button)
            button.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            button.addActionHandlers { _ in
                action()
            }
        }
        
        let item = PTNavigationBarManager.shared.item(for: self)
        item.leftView = [container]
        
        PTNavigationBarManager.shared.update(item: item, for: self)
    }
    
    open func updateCustomBackButtonBounds(_ size: CGSize) {
        guard let container = customBackButtonContainer,
              size.width > 0,
              size.height > 0 else {
            return
        }

        // ① 更新真正决定 NavigationBar 布局的 container.bounds
        container.bounds = CGRect(origin: .zero, size: size)
        container.setNeedsLayout()
        container.layoutIfNeeded()
        
        // ② 重新通知 PTNavigationBarManager
        // setLeftView() 会重新读取：
        // value.bounds.size
        // 然后重新生成 SnapKit size 约束。
        let item = PTNavigationBarManager.shared.item(for: self)

        guard item.leftView.contains(where: { $0 === container }) else {
            return
        }

        PTNavigationBarManager.shared.update(item: item, for: self)
    }
    
    open func refreshCustomBackButtonBounds(minimumWidth: CGFloat? = nil,height: CGFloat? = nil) {
        guard let contentView = customBackButtonContentView,
              let container = customBackButtonContainer else {
            return
        }

        contentView.invalidateIntrinsicContentSize()
        contentView.setNeedsLayout()
        contentView.layoutIfNeeded()

        let targetHeight: CGFloat

        if let height {
            targetHeight = height
        } else if container.bounds.height > 0 {
            targetHeight = container.bounds.height
        } else {
            targetHeight = PTAppBaseConfig.share.navBarButtonSize
        }

        let fittingSize = contentView.systemLayoutSizeFitting(CGSize(width: UIView.layoutFittingCompressedSize.width, height: targetHeight), withHorizontalFittingPriority: .fittingSizeLevel, verticalFittingPriority: .required)

        let targetWidth = max(minimumWidth ?? PTAppBaseConfig.share.navBarButtonSize,ceil(fittingSize.width))

        updateCustomBackButtonBounds(CGSize(width: targetWidth, height: targetHeight))
    }
    
    open func setLeftButtons(views:[UIView], buttonSpacing: CGFloat = 10) {
        guard !views.isEmpty else {
            let item = PTNavigationBarManager.shared.item(for: self)
            item.leftView = []
            PTNavigationBarManager.shared.update(item: item, for: self)
            return
        }
        let item = PTNavigationBarManager.shared.item(for: self)
        item.leftView = views
        item.leftItemSpacing = buttonSpacing
        PTNavigationBarManager.shared.update(item: item, for: self)
    }

    //MARK: 需要设置按钮Bounds
    open func setCustomRightButtons(buttons: [UIView], buttonSpacing: CGFloat = 10) {
        guard !buttons.isEmpty else {
            let item = PTNavigationBarManager.shared.item(for: self)
            item.rightViews = []
            PTNavigationBarManager.shared.update(item: item, for: self)
            return
        }
        let item = PTNavigationBarManager.shared.item(for: self)
        item.rightViews = buttons
        item.rightItemSpacing = buttonSpacing
        
        PTNavigationBarManager.shared.update(item: item, for: self)
    }

    open func setCustomTitleView(_ view: UIView? = nil, fillSpace: Bool = true) {
        let item = PTNavigationBarManager.shared.item(for: self)
        item.titleView = view
        item.titleViewFillSpace = fillSpace // 记录填满状态
        PTNavigationBarManager.shared.update(item: item, for: self)
    }

    // MARK: - 设置自定义导航栏背景
    open func updateNavigationBarBackground(scrollView: UIScrollView, changeOffset: CGFloat = 100, color: UIColor = .white) {
        let offset = scrollView.contentOffset.y
        let alpha = min(1, max(0, offset / changeOffset))
        
        PTNavigationBarManager.shared.setAlpha(alpha)
    }
    
    open func setNavigationBarBackgroundAlpha(clear:Bool = false) {
        PTNavigationBarManager.shared.setAlpha(clear ? 0 : 1)
    }

    // MARK: - 私有实现
    private func setupBaseConfigs() {
        // English: Configure scroll views locally; a base controller must not mutate UIKit's global appearance proxy.
        // Español: Configura los scroll views localmente; el controlador base no debe mutar el proxy global de apariencia de UIKit.
        // 中文：仅在具体列表上配置滚动视图，基类不再修改 UIKit 全局 appearance 代理。
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = [.top, .left, .bottom, .right]
        definesPresentationContext = true
        view.backgroundColor = PTAppBaseConfig.share.viewControllerBaseBackgroundColor
        navigationController?.hidesBarsOnSwipe = PTAppBaseConfig.share.hidesBarsOnSwipe
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _: UITraitCollection) in
            self.baseTraitCollectionDidChange(style:self.traitCollection.userInterfaceStyle)
            self.setNeedsStatusBarAppearanceUpdate()
        }

    }
    
    @objc func backButtonTapped() {
        self.returnFrontVC()
    }
    
    public func safePushViewController(_ vc: UIViewController, animated: Bool = true) {
        guard let nav = self.navigationController else { return }
        if nav.transitionCoordinator != nil {
            PTNSLogConsole("拦截到重复跳转，已抛弃", levelType: PTLogMode, loggerType: .viewCycle)
            return
        }
        nav.pushViewController(vc, animated: animated)
    }
}

extension PTBaseViewController: UIScrollViewDelegate {
    open func bindScrollView(_ scrollView: UIScrollView) {
        pt_prepareScrollViewForLargeTitle(scrollView, assignsDelegate: true)
    }
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        pt_updateLargeTitleTransition(for: scrollView)
    }
    
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        pt_finishLargeTitleDrag(for: scrollView)
    }

    // English: Prepare large-title insets without changing the delegate when a wrapper owns it.
    // Español: Prepara los insets del título grande sin cambiar el delegate cuando un wrapper lo posee.
    // 中文：当包装器拥有 delegate 时，只准备大标题 inset，不改变 delegate 归属。
    func pt_prepareScrollViewForLargeTitle(_ scrollView: UIScrollView, assignsDelegate: Bool) {
        view.layoutIfNeeded()
        if assignsDelegate {
            scrollView.delegate = self
        }
        guard prefersLargeTitle() else { return }

        let topHeight = scrollView.frame.origin.y + PTAppBaseConfig.share.navLargeTitleBarHeight
        scrollView.contentInset.top = topHeight
        scrollView.verticalScrollIndicatorInsets.top = topHeight
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    }

    // English: Reuse the same progress calculation for direct and wrapped scroll views.
    // Español: Reutiliza el mismo cálculo de progreso para scroll views directos y envueltos.
    // 中文：直接绑定和包装后的滚动视图统一使用同一套进度计算。
    func pt_updateLargeTitleTransition(for scrollView: UIScrollView) {
        guard prefersLargeTitle() else { return }

        let offset = scrollView.contentOffset.y
        let insetTop = scrollView.contentInset.top
        let progress = (offset + insetTop) / PTAppBaseConfig.share.navLargeTitleProgress
        PTNavigationBarManager.shared.updateScrollProgress(progress)
    }

    // English: Preserve the existing overscroll snap behavior for wrapped lists.
    // Español: Conserva el ajuste existente del sobre desplazamiento para listas envueltas.
    // 中文：为包装后的列表保留原有的过度下拉回弹行为。
    func pt_finishLargeTitleDrag(for scrollView: UIScrollView) {
        guard prefersLargeTitle(), scrollView.contentOffset.y < -scrollView.contentInset.top else { return }

        UIView.animate(withDuration: PTUIAccessibility.animationDuration(0.25),
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.5,
                       options: [.curveEaseOut]) {
            scrollView.setContentOffset(
                CGPoint(x: 0, y: -scrollView.contentInset.top),
                animated: false
            )
        }
    }
}

/**
    抽出两个Controller同样用到的地方
 */
extension PTBaseViewController {
    @MainActor
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
        hidesBaseNavigationBarOnLoad = hideBaseNavBar
    }
            
    //MARK: 動態更換StatusBar
    ///動態更換StatusBar
    open func changeStatusBar(type:VCStatusBarChangeStatusType) {
        switch type {
        case .Auto:
            StatusBarManager.shared.update(with: preferredNavigationBarStyle())
        case .Dark:
            StatusBarManager.shared.update(with: .gradient(colors: [UIColor.clear,UIColor.clear]))
        case .Light:
            StatusBarManager.shared.update(with: .transparent)
        }
        setNeedsStatusBarAppearanceUpdate()
    }
    
    open func switchOrientation(isFullScreen:Bool) {
        
        PTAppWindowsDelegate.appDelegate()?.isFullScreen = isFullScreen
                
        setNeedsUpdateOfPrefersPointerLocked()
        guard let scence = view.window?.windowScene
                ?? PTSceneContext.activeWindow()?.windowScene else { return }
        let orientation:UIInterfaceOrientationMask = isFullScreen ? .landscape : .portrait
        let geometryPreferencesIOS = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: orientation)
        scence.requestGeometryUpdate(geometryPreferencesIOS) { error in
            PTNSLogConsole("强制\(isFullScreen ? "横屏" : "竖屏")错误:\(error)",levelType: PTLogMode,loggerType: .viewCycle)
        }
    }
        
    open func baseTraitCollectionDidChange(style:UIUserInterfaceStyle) { }
    
    public func returnFrontVC(completion:PTActionTask? = nil) {
        let finish: @MainActor () -> Void = {
            PTUIKitRuntimeHooks.controllerTransitionDidComplete?()
            completion?()
        }
        if let presentingVC = self.presentingViewController {
            dismiss(animated: true, completion: {
                PTNavigationBarManager.shared.restoreIfNeeded(for: presentingVC)
                Task { @MainActor in finish() }
            })
        } else if let nav = navigationController {
            nav.popViewController(animated: true) {
                Task { @MainActor in finish() }
            }
        } else {
            finish()
        }
    }
    
    //MARK: 截图反馈注册
    ///截图反馈注册
    public func registerScreenShotService() {
        UIScreen.pt.detectScreenShot { type in
            guard type == .Normal else {
                PTGCDManager.shared.runOnMain {
                    self.screenShotHandle?(nil)
                }
                return
            }

            PTGCDManager.shared.delayOnMain(time: 1) {
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

                guard let lastAsset = PHAsset.fetchAssets(with: .image, options: fetchOptions).firstObject,
                      lastAsset.mediaSubtypes == .photoScreenshot else {
                    self.screenShotHandle?(nil)
                    return
                }

                self.getImage(for: lastAsset) { image in
                    guard let image else {
                        PTGCDManager.shared.runOnMain {
                            self.screenShotHandle?(nil)
                        }
                        return
                    }

                    PTGCDManager.shared.runOnMain {
                        if let handler = self.screenShotHandle {
                            handler(image)
                        } else {
                            if self.screenFunc == nil {
                                self.screenFunc = PTBaseScreenShotAlert(screenShotImage: image) {
                                    PTGCDManager.shared.runOnMain {
                                        self.screenFunc = nil
                                    }
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
extension PTBaseViewController {
    
    public func showEmptyView(task: PTActionTask? = nil) {
        // 使用 if let 解包更安全、更 Swift 风格
        if let config = emptyDataViewConfig {
            PTUnavailableManager.render(.empty, in: self, config: config, action: task)
        } else {
            assertionFailure("如果使用该功能,则须要设置emptyDataViewConfig")
        }
    }
    
    public func hideEmptyView(task: PTActionTask? = nil) {
        PTUnavailableManager.render(.content, in: self)
        task?()
    }
    
    public func emptyViewLoading() {
        PTUnavailableManager.render(.loading, in: self)
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
        
    func getImage(for asset: PHAsset,finish:@escaping @Sendable (UIImage?) -> Void) {
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
    @MainActor
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
        
        PTUtils.getCurrentVC()?.view.addSubview(self)
        showAlert()
        
        Task { @MainActor in
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
            Task { @MainActor in
                self.alpha = 0
            }
        }) { ok in
            Task { @MainActor in
                self.removeFromSuperview()
                self.dismissTask?()
            }
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
