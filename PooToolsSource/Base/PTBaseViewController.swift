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
public enum PTNavigationBarStyle:Equatable {
    case gradient(type: Imagegradien = .LeftToRight, colors: [DynamicColor])
    case solid(UIColor)
    case transparent
    
    // 提供一个默认样式入口（避免把默认写在关联值上）
    public static var `default`: PTNavigationBarStyle {
        return .gradient(type: .LeftToRight, colors: [UIColor.white,UIColor.white])
    }
}

open class PTNavTitleContainer: UIView {

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required public init?(coder: NSCoder) { fatalError() }

    open override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: PTAppBaseConfig.share.bavTitleContainerHeight) // 保持标准高度
    }
}

public final class PTNavigationBarContainer: UIView {
    
    let backgroundView = UIView()
    let contentView = UIView()
        
    // ✅ 新增三块区域
    lazy var leftContainer:UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .fillProportionally
        return view
    }()
    let rightContainer:UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .fillProportionally
        return view
    }()
    
    let titleContainer = UIView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubviews([backgroundView,contentView])
        
        contentView.addSubviews([leftContainer,rightContainer,titleContainer])
        leftContainer.isHidden = true
        rightContainer.isHidden = true
        titleContainer.isHidden = true
        
        backgroundView.frame = bounds
        contentView.frame = bounds
        
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    public required init?(coder: NSCoder) { fatalError() }
    
    public func apply(style: PTNavigationBarStyle) {
        switch style {
        case .gradient(let type, let colors):
            backgroundView.backgroundGradient(type: type, colors: colors)
        case .solid(let color):
            backgroundView.backgroundColor = color
        case .transparent:
            backgroundView.backgroundColor = .clear
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
}

public final class PTNavBarItem {
    public var isConfigured = false   // ✅ 新增
    public var leftView: [UIView] = []
    public var leftItemSpacing:CGFloat = 0
    public var rightViews: [UIView] = []
    public var rightItemSpacing:CGFloat = 0
    public var titleView: UIView?
    public var navTitle:String = ""
    public var barColorStyle:PTNavigationBarStyle = .transparent
}

public final class PTNavigationBarManager:NSObject {
    
    public static let shared = PTNavigationBarManager()
    
    private override init() {}
    
    private var lastStyle: PTNavigationBarStyle?
    
    private var titleLabel:Bool = false
    
    // ❗ 核心：按 VC 存储
    private var itemCache = NSMapTable<UIViewController, PTNavBarItem>(keyOptions: .weakMemory, valueOptions: .strongMemory)
    private var containerMap = NSMapTable<UINavigationController, PTNavigationBarContainer>(keyOptions: .weakMemory, valueOptions: .strongMemory)
    
    private weak var currentVC: UIViewController?
    private weak var currentNav: UINavigationController?
    public func installIfNeeded(in nav: UINavigationController) {
        if containerMap.object(forKey: nav) != nil { return }

        let navBar = nav.navigationBar
        
        // ✅ 获取 statusBar 高度（正确方式）
        let statusBarHeight = nav.view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        
        let totalHeight = navBar.bounds.height + statusBarHeight
        
        // ✅ 关键：往上扩展
        let container = PTNavigationBarContainer(
            frame: CGRect(x: 0,
                          y: -statusBarHeight,
                          width: navBar.bounds.width,
                          height: totalHeight)
        )
        
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        navBar.setBackgroundImage(UIImage(), for: .default)
        navBar.shadowImage = UIImage()
        navBar.isTranslucent = true
        
        navBar.addSubview(container)
        navBar.sendSubviewToBack(container)
        containerMap.setObject(container, forKey: nav)
    }
    
    public func apply(style: PTNavigationBarStyle, in nav: UINavigationController) {
        installIfNeeded(in: nav)
        currentNav = nav
        guard lastStyle != style else { return }
        lastStyle = style
        let container = containerMap.object(forKey: nav)
        container?.apply(style: style)
        
        // 同步 appearance（避免 push 闪）
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        // 设置标题属性
        appearance.titleTextAttributes = [
            .font: PTAppBaseConfig.share.navTitleFont,
            .foregroundColor: PTAppBaseConfig.share.navTitleTextColor
        ]
        nav.navigationBar.standardAppearance = appearance
        nav.navigationBar.scrollEdgeAppearance = appearance
        nav.navigationBar.compactAppearance = appearance
    }
        
    public func setAlpha(_ alpha: CGFloat) {
        guard let nav = currentNav,
              let container = containerMap.object(forKey: nav) else { return }
        container.backgroundView.alpha = alpha
    }
    
    public func bind(to nav: UINavigationController) {
        nav.delegate = self
    }
    
    public func item(for vc: UIViewController) -> PTNavBarItem {
        if let item = itemCache.object(forKey: vc) {
            return item
        }
        let newItem = PTNavBarItem()
        itemCache.setObject(newItem, forKey: vc)
        return newItem
    }

    public func update(item: PTNavBarItem, for vc: UIViewController) {
        item.isConfigured = true
        itemCache.setObject(item, forKey: vc)
        
        // 如果当前正在显示，立即刷新
        if vc === currentVC {
            apply(item: item)
        }
    }
}

extension PTNavigationBarManager: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController,
                              animated: Bool) {
        // ❗如果这个 VC 不是 nav 栈里的（理论上不会，但防御）
        guard viewController.navigationController === navigationController else {
            return
        }
        
        viewController.navigationItem.hidesBackButton = true
        viewController.title = nil
        viewController.navigationItem.titleView = nil
        currentVC = viewController
        
        // ✅ 应用对应 VC 的 NavBar
        if let item = itemCache.object(forKey: viewController) {
            apply(style: item.barColorStyle, in: navigationController) // ✅ 顺便补上
            apply(item: item)
        } else {
            clear()
        }
    }
    
    private func apply(item: PTNavBarItem) {
        setLeftView(item.leftView,spacing: item.leftItemSpacing)
        setRightViews(item.rightViews,spacing: item.rightItemSpacing)
        if let findTitleView = item.titleView {
            titleLabel = false
            setTitleView(findTitleView)
        } else if !item.navTitle.stringIsEmpty() {
            titleLabel = true
            let titleLabel = UILabel()
            titleLabel.font = PTAppBaseConfig.share.navTitleFont
            titleLabel.textColor = PTAppBaseConfig.share.navTitleTextColor
            titleLabel.numberOfLines = 0
            titleLabel.text = item.navTitle
            titleLabel.textAlignment = .center
            setTitleView(titleLabel)
        } else {
            titleLabel = false
            setTitleView(nil)
        }
    }

    private func clear() {
        setLeftView([])
        setRightViews([])
        setTitleView(nil)
    }
    
    public func restoreIfNeeded(for vc: UIViewController) {
        // ❗关键：只处理有 navigationController 的 VC
        let realVC = PTUtils.getCurrentVC(from: vc)
        guard let nav = realVC.navigationController else { return }
        currentVC = realVC
        guard let item = itemCache.object(forKey: realVC),
                  item.isConfigured else {
            return
        }
        apply(style: item.barColorStyle, in: nav)
        apply(item: item)
    }
}

extension PTNavigationBarManager {
    
    public func setLeftView(_ views: [UIView],spacing:CGFloat = 8) {
        guard let nav = currentNav,
              let container = containerMap.object(forKey: nav) else { return }
        container.leftContainer.spacing = spacing
        container.leftContainer.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        container.leftContainer.isHidden = true
        container.leftContainer.snp.remakeConstraints { make in
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.equalToSuperview().inset(CGFloat.statusBarHeight())
            make.bottom.equalToSuperview()
            make.width.equalTo(0)
        }
        guard !views.isEmpty else { return }
        container.leftContainer.isHidden = false
        var containerWidth:CGFloat = 0
        views.forEach { value in
            container.leftContainer.addArrangedSubview(value)
            value.snp.makeConstraints { make in
                make.size.equalTo(value.bounds.size)
            }
            containerWidth += value.bounds.size.width
        }
        containerWidth += CGFloat(views.count - 1) * spacing
        container.leftContainer.snp.remakeConstraints { make in
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.equalToSuperview().inset(CGFloat.statusBarHeight())
            make.bottom.equalToSuperview()
            make.width.equalTo(containerWidth)
        }
    }
    
    public func setRightViews(_ views: [UIView], spacing: CGFloat = 8) {
        guard let nav = currentNav,
              let container = containerMap.object(forKey: nav) else { return }
        container.rightContainer.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        container.rightContainer.isHidden = true
        container.rightContainer.snp.remakeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.equalToSuperview().inset(CGFloat.statusBarHeight())
            make.bottom.equalToSuperview()
            make.width.equalTo(0)
        }
        guard !views.isEmpty else { return }
        container.rightContainer.isHidden = false
        var containerWidth:CGFloat = 0
        views.forEach { value in
            container.rightContainer.addArrangedSubview(value)
            value.snp.makeConstraints { make in
                make.size.equalTo(value.bounds.size)
            }
            containerWidth += value.bounds.size.width
        }
        containerWidth += CGFloat(views.count - 1) * spacing
        container.rightContainer.snp.remakeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.equalToSuperview().inset(CGFloat.statusBarHeight())
            make.bottom.equalToSuperview()
            make.width.equalTo(containerWidth)
        }
    }
    
    public func setTitleView(_ view: UIView?) {
        guard let nav = currentNav,
              let container = containerMap.object(forKey: nav) else { return }
        container.titleContainer.subviews.forEach { $0.removeFromSuperview() }
        container.titleContainer.isHidden = true
        guard let view else { return }
        container.titleContainer.isHidden = false
        container.titleContainer.addSubview(view)
        container.titleContainer.snp.remakeConstraints { make in
            if self.titleLabel {
                make.left.lessThanOrEqualTo(container.leftContainer.snp.right)
                make.right.lessThanOrEqualTo(container.rightContainer.snp.left)
                make.top.equalToSuperview().inset(CGFloat.statusBarHeight())
                make.bottom.equalToSuperview()
                make.centerX.equalToSuperview()
            } else {
                make.left.equalTo(container.leftContainer.snp.right)
                make.right.equalTo(container.rightContainer.snp.left)
                make.bottom.equalToSuperview()
                make.top.equalToSuperview().inset(CGFloat.statusBarHeight())
            }
        }
        
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

@objcMembers
open class PTBaseViewController: UIViewController {
                   
    open var pt_Title:String? {
        didSet {
            let item = PTNavigationBarManager.shared.item(for: self)
            item.navTitle = pt_Title ?? ""
            PTNavigationBarManager.shared.update(item: item, for: self)
        }
    }

    override public var pt_prefersTabBarHidden: Bool { false }

    deinit {
        PTNSLogConsole("[\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())]===已被释放",levelType: PTLogMode,loggerType: .ViewCycle)
        removeFromSuperStatusBar()
    }
    
    // MARK: - 子类 override 以决定样式
    open func preferredNavigationBarStyle() -> PTNavigationBarStyle {
        return .solid(.white)
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        PTNSLogConsole("加载==============================\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())）",levelType: PTLogMode,loggerType: .ViewCycle)
        applyNavigationBar()
        PTNavigationBarManager.shared.restoreIfNeeded(for: self)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
        PTNSLogConsole("加载完==============================\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())）",levelType: PTLogMode,loggerType: .ViewCycle)
        let style = self.preferredNavigationBarStyle()
        self.updateStatusBar(style)
    }
    
    open override func viewWillDisappear(_ animated:Bool) {
        super.viewWillDisappear(animated)
        PTNSLogConsole("离开==============================\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())）",levelType: PTLogMode,loggerType: .ViewCycle)
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let presenting = presentingViewController {
            PTNavigationBarManager.shared.restoreIfNeeded(for: presenting)
        }
    }
        
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupBaseConfigs()
        if let nav = navigationController {
            PTNavigationBarManager.shared.bind(to: nav)
        }

        PTRotationManager.shared.orientationMaskDidChange = { orientationMask in
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
    
    private func applyNavigationBar() {
        guard let nav = navigationController else { return }
        
        let style = preferredNavigationBarStyle()
        PTNavigationBarManager.shared.apply(style: style, in: nav)
        let item = PTNavigationBarManager.shared.item(for: self)
        item.barColorStyle = style
        PTNavigationBarManager.shared.update(item: item, for: self)
        if self.navigationController?.viewControllers.first != self {
            let backBtn = baseBackButton()
            backBtn.addActionHandlers { seder in
                self.viewDismiss()
            }
            setCustomBackButtonView(backBtn)
        }
        if let _ = self.presentingViewController {
            let backBtn = baseBackButton()
            backBtn.addActionHandlers { seder in
                self.viewDismiss()
            }
            setCustomBackButtonView(backBtn)
        }
        
        updateStatusBar(style)
    }

    private func baseBackButton() -> UIButton {
        let backBtn = UIButton(type: .custom)
        backBtn.setImage(PTAppBaseConfig.share.viewControllerBackItemImage, for: .normal)
        backBtn.bounds = CGRect.init(x: 0, y: 0, width: 34, height: 34)
        return backBtn
    }
    
    private func updateStatusBar(_ style: PTNavigationBarStyle) {
        switch style {
        case .gradient:
            changeStatusBar(type: .Dark)
        case .solid(let color):
            setStatusBarStyle(color: color)
        case .transparent:
            setStatusBarStyle(color: (self.view.backgroundColor ?? PTAppBaseConfig.share.viewControllerBaseBackgroundColor))
        }
        setNeedsStatusBarAppearanceUpdate()
    }
    
    private func setStatusBarStyle(color:UIColor) {
        switch color.pt_colorTone() {
        case .dark:
            changeStatusBar(type: .Light)
        case .light:
            changeStatusBar(type: .Dark)
        case .normal:
            changeStatusBar(type: .Dark)
        case .clear:
            changeStatusBar(type: .Light)
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
        PTNavigationBarManager.shared.setLeftView([backButton])
    }
    
    // 新增：直接传入任意自定义 view
    open func setCustomBackButtonView(_ customView: UIView,
                                      size: CGSize = CGSize(width: 34, height: 34),
                                      action: PTActionTask? = nil) {
        // 容器 UIView
        let container = UIView()
        container.isUserInteractionEnabled = true
        container.clipsToBounds = true
        container.bounds = CGRect(origin: .zero, size: size)
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

    //MARK: 需要设置按钮Bounds
    open func setCustomRightButtons(buttons: [UIView], buttonSpacing: CGFloat = 10) {
        guard !buttons.isEmpty else {
            navigationItem.rightBarButtonItem = nil
            return
        }
        let item = PTNavigationBarManager.shared.item(for: self)
        item.rightViews = buttons
        item.rightItemSpacing = buttonSpacing
        
        PTNavigationBarManager.shared.update(item: item, for: self)
    }

    open func setCustomTitleView(_ view: UIView? = nil) {
        let item = PTNavigationBarManager.shared.item(for: self)
        item.titleView = view
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
        if let presentingVC = self.presentingViewController {
            dismiss(animated: true, completion: {
                PTNavigationBarManager.shared.restoreIfNeeded(for: presentingVC)
                completion?()
            })
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
        
        PTUtils.getCurrentVC()?.view.addSubview(self)
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
