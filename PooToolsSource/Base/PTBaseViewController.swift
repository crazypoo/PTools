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

extension UIColor {
    func interpolate(to: UIColor, progress: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        to.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return UIColor(
            red: r1 + (r2 - r1) * progress,
            green: g1 + (g2 - g1) * progress,
            blue: b1 + (b2 - b1) * progress,
            alpha: a1 + (a2 - a1) * progress
        )
    }
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
    
    private var fromStyle: PTNavigationBarStyle?
    private var toStyle: PTNavigationBarStyle?

    let backgroundView = UIView()
    let contentView = UIView()
        
    // ✅ 新增三块区域
    fileprivate lazy var leftContainer:UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .fillProportionally
        return view
    }()
    fileprivate let rightContainer:UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .fillProportionally
        return view
    }()
    
    fileprivate let titleContainer = UIView()
    
    let topBarContainer = UIView()   // ← 放 left/right/title
    let largeTitleContainer = UIView() // ← 单独一层
    fileprivate let largeTitleLabel = UILabel()
    fileprivate var largeTitleHeight: CGFloat = PTAppBaseConfig.share.navLargeTitleBarHeight

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubviews([backgroundView,contentView])
        contentView.addSubviews([topBarContainer, largeTitleContainer])
        topBarContainer.addSubviews([leftContainer, rightContainer, titleContainer])
        leftContainer.translatesAutoresizingMaskIntoConstraints = false
        rightContainer.translatesAutoresizingMaskIntoConstraints = false
        largeTitleContainer.addSubview(largeTitleLabel)
        topBarContainer.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            var offsetHeight:CGFloat = 0
            if let findCurrent = PTUtils.getCurrentVC(),let sheet = findCurrent.sheetViewController {
                let offset = sheet.options.useFullScreenMode ? CGFloat.statusBarHeight() : sheet.options.pullBarHeight
                make.top.equalToSuperview().offset(-offset)
                offsetHeight = offset
            } else {
                make.top.equalToSuperview()
                offsetHeight = CGFloat.statusBarHeight()
            }
            make.height.equalTo(offsetHeight + CGFloat.kNavBarHeight)
        }
        
        largeTitleContainer.snp.makeConstraints { make in
            make.top.equalTo(topBarContainer.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(0) // LargeTitle 高度
        }
        largeTitleContainer.isHidden = true
        leftContainer.isHidden = true
        rightContainer.isHidden = true
        titleContainer.isHidden = true
        
        backgroundView.frame = bounds
        contentView.frame = bounds
        
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        largeTitleLabel.font = PTAppBaseConfig.share.navLargeTitleFont
        largeTitleLabel.textColor = PTAppBaseConfig.share.navTitleTextColor
        largeTitleLabel.numberOfLines = 0
        largeTitleLabel.lineBreakMode = .byTruncatingTail
        largeTitleLabel.alpha = 0
        largeTitleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.bottom.top.equalToSuperview()
        }
    }
    
    public required init?(coder: NSCoder) { fatalError() }
    
    public func apply(style: PTNavigationBarStyle) {
        switch style {
        case .gradient(let type, let colors):
            backgroundView.backgroundGradient(type: type, colors: colors)
            largeTitleContainer.backgroundGradient(type: type, colors: colors)
        case .solid(let color):
            backgroundView.backgroundColor = color
            largeTitleContainer.backgroundColor = color
        case .transparent:
            backgroundView.backgroundColor = .clear
            largeTitleContainer.backgroundColor = .clear
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
}

extension PTNavigationBarContainer {
    func updateLargeTitle(progress: CGFloat) {
        let p = min(1, max(0, progress))
        // 大标题高度收缩
        let maxHeight: CGFloat = largeTitleHeight
        // ===== 1. Stretch（下拉放大）=====
        if p < 0 {
            let stretch = abs(p)
            let height = maxHeight + stretch * 40   // 拉伸幅度
            
            largeTitleContainer.snp.updateConstraints { make in
                make.height.equalTo(height)
            }
            
            // 字体轻微放大（系统类似效果）
            let scale = 1 + stretch * 0.08
            largeTitleLabel.transform = CGAffineTransform(scaleX: scale, y: scale)
            
            // 始终显示大标题
            largeTitleLabel.alpha = 1
            titleContainer.alpha = 0
            
            return
        }
        
        // ===== 2. 正常收缩 =====
        let height = maxHeight * (1 - p)
        
        largeTitleContainer.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
        
        // ===== 3. alpha 渐变 =====
        largeTitleLabel.alpha = 1 - p
        titleContainer.alpha = p
        
        // ===== 4. scale（系统 subtle 动画）=====
        let scale = 1 - 0.05 * p
        largeTitleLabel.transform = CGAffineTransform(scaleX: scale, y: scale)
        
        // ===== 5. 字重动态变化（🔥重点）=====
        let baseFont = PTAppBaseConfig.share.navLargeTitleFont
        let fontSize = baseFont.pointSize
        
        let weight: UIFont.Weight = p > 0.5 ? .semibold : .bold
        
        largeTitleLabel.font = UIFont.systemFont(ofSize: fontSize, weight: weight)

    }
}

extension PTNavigationBarContainer {
    func prepareTransition(from: PTNavigationBarStyle, to: PTNavigationBarStyle) {
        self.fromStyle = from
        self.toStyle = to
        
        // 先应用 from
        apply(style: from)
    }

    /// 核心：根据 progress 渐变
    func updateTransition(progress: CGFloat) {
        guard let from = fromStyle, let to = toStyle else { return }
        
        switch (from, to) {
            
        case (.solid(let c1), .solid(let c2)):
            backgroundView.backgroundColor = c1.interpolate(to: c2, progress: progress)
            
        case (.transparent, .solid(let c)):
            backgroundView.backgroundColor = c.withAlphaComponent(progress)
            
        case (.solid(let c), .transparent):
            backgroundView.backgroundColor = c.withAlphaComponent(1 - progress)
            
        default:
            // gradient 你可以后面扩展（先支持 solid 最稳）
            break
        }
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
    
    private var displayLink: CADisplayLink?
    private weak var transitionCoordinatorRef: UIViewControllerTransitionCoordinator?
    private weak var transitionContainer: PTNavigationBarContainer?

    private var fromStyle: PTNavigationBarStyle = .transparent
    private var toStyle: PTNavigationBarStyle = .transparent
    
    public var tabBarHandler: ((UINavigationController, UIViewController, Bool, UIViewControllerTransitionCoordinator?) -> Void)?
    
    public func installIfNeeded(in nav: UINavigationController) {
        if containerMap.object(forKey: nav) != nil { return }

        let navBar = nav.navigationBar
        resetSystemNavBarAppearance(nav)
        
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
        
        resetSystemNavBarAppearance(nav)
    }
    
    private func resetSystemNavBarAppearance(_ nav: UINavigationController) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = nil   // ❗关键（去 blur）
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        appearance.backgroundImage = UIImage()
        appearance.shadowImage = UIImage()
        
        appearance.titleTextAttributes = [
            .font: PTAppBaseConfig.share.navTitleFont,
            .foregroundColor: PTAppBaseConfig.share.navTitleTextColor
        ]
        
        if #available(iOS 15.0, *) {
            nav.navigationBar.compactScrollEdgeAppearance = appearance
        }

        nav.navigationBar.standardAppearance = appearance
        nav.navigationBar.scrollEdgeAppearance = appearance
        nav.navigationBar.compactAppearance = appearance
        
        // 🔥 关键：关闭系统 blur
        nav.navigationBar.isTranslucent = true
        
        nav.navigationBar.subviews.forEach {
            if NSStringFromClass(type(of: $0)).contains("UIBarBackground") {
                $0.isHidden = true
                $0.isUserInteractionEnabled = false
                $0.alpha = 0
            }
        }
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

extension PTNavigationBarManager {
    func updateScrollProgress(_ progress: CGFloat) {
        guard let nav = currentNav,
              let container = containerMap.object(forKey: nav) else { return }
        container.updateLargeTitle(progress: progress)
    }
    
    public func currentNavLargeTitleBarHeight() -> CGFloat {
        guard let nav = currentNav,
              let container = containerMap.object(forKey: nav) else { return 0 }
        container.layoutIfNeeded()
        return container.largeTitleContainer.frame.height
    }
    
    public func currentNavBarHeight() -> CGFloat {
        guard let _ = currentNav else { return 0 }
        
        let status = CGFloat.statusBarHeight()
        let navBar: CGFloat = CGFloat.kNavBarHeight
        
        return status + navBar + currentNavLargeTitleBarHeight()
    }
}

extension PTNavigationBarManager: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController,
                              animated: Bool) {
        if let baseVC = viewController as? PTBaseViewController,
           !baseVC.allowControlNavBar() {
            return
        }
        
        currentNav = navigationController
        currentVC = viewController
        resetSystemNavBarAppearance(navigationController)
        
        // ❗如果这个 VC 不是 nav 栈里的（理论上不会，但防御）
        guard let container = containerMap.object(forKey: navigationController) else { return }
        // 2. 关键修改：直接从 VC 获取样式，不要只依赖 itemCache
        let toStyle: PTNavigationBarStyle
        if let baseVC = viewController as? PTBaseViewController {
            toStyle = baseVC.preferredNavigationBarStyle()
            // 同步更新一下 item 里的样式，防止后续逻辑冲突
            let item = self.item(for: viewController)
            item.barColorStyle = toStyle
        } else {
            toStyle = .default
        }

        StatusBarManager.shared.update(with: toStyle)
        
        let fromVC = navigationController.transitionCoordinator?.viewController(forKey: .from)
        let fromStyle = (fromVC as? PTBaseViewController)?.preferredNavigationBarStyle() ?? .transparent

        self.fromStyle = fromStyle
        self.toStyle = toStyle
        self.transitionContainer = container

        // 3. 立即准备过渡：这会消除颜色闪烁
        container.prepareTransition(from: fromStyle, to: toStyle)
        
        if let coordinator = navigationController.transitionCoordinator {
            startDisplayLink()
            coordinator.animate(alongsideTransition: { _ in
                // 动画过程中，系统会自动处理 alpha 或 这里的 progress
                container.updateTransition(progress: 1)
            }, completion: { context in
                self.stopDisplayLink()
                if context.isCancelled {
                    StatusBarManager.shared.update(with: fromStyle)
                    fromVC?.setNeedsStatusBarAppearanceUpdate()
                    container.apply(style: fromStyle)
                } else {
                    container.apply(style: toStyle)
                    StatusBarManager.shared.update(with: toStyle)
                    if let vc = viewController as? PTBaseViewController {
                        vc.setNeedsStatusBarAppearanceUpdate()
                        navigationController.setNeedsStatusBarAppearanceUpdate() // 触发 Nav 重新询问 child
                    }
                }
            })
            
            coordinator.notifyWhenInteractionChanges { context in
                if context.isCancelled {
                    StatusBarManager.shared.update(with: fromStyle)
                    fromVC?.setNeedsStatusBarAppearanceUpdate()
                    container.apply(style: fromStyle)
                }
            }
        } else {
            // 非动画转场，直接应用目标样式
            container.apply(style: toStyle)
            if let vc = viewController as? PTBaseViewController {
                vc.setNeedsStatusBarAppearanceUpdate()
            }
        }

        // 🔥🔥🔥 关键：驱动 TabBar（这里替代 delegate）
        tabBarHandler?(navigationController, viewController, animated, navigationController.transitionCoordinator)

        viewController.navigationItem.hidesBackButton = true
        viewController.title = nil
        viewController.navigationItem.titleView = nil

        // 处理 Item 内容（左/右/标题按钮）
        if let item = itemCache.object(forKey: viewController) {
            apply(item: item)
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
        
        // ===== LargeTitle 逻辑（🔥重点）=====
        guard let nav = currentNav,
              let container = containerMap.object(forKey: nav),
              let vc = currentVC as? PTBaseViewController else { return }

        let isLarge = vc.prefersLargeTitle()
        let hasTitle = !item.navTitle.stringIsEmpty()

        if isLarge && hasTitle {
            container.largeTitleContainer.isHidden = false
            
            container.largeTitleContainer.snp.updateConstraints { make in
                make.height.equalTo(container.largeTitleHeight)
            }
            
            container.largeTitleLabel.text = item.navTitle
            container.largeTitleLabel.isHidden = false
            
            container.largeTitleLabel.alpha = 1
            container.largeTitleLabel.transform = .identity
            
            container.titleContainer.alpha = 0

        } else {
            // ❗关键：彻底关闭 largeTitle            
            container.largeTitleContainer.isHidden = true
            
            container.largeTitleContainer.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
            
            container.largeTitleLabel.text = nil
            container.largeTitleLabel.isHidden = true
            container.largeTitleLabel.alpha = 0
            container.largeTitleLabel.transform = .identity
            
            container.titleContainer.alpha = 1
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
        
        // 3. 🔥 关键：同步更新状态栏单例并通知系统刷新
        StatusBarManager.shared.update(with: item.barColorStyle)
        realVC.setNeedsStatusBarAppearanceUpdate()
        nav.setNeedsStatusBarAppearanceUpdate()
    }
    
    public func refreshCurrentNavBar() {
        guard let vc = currentVC,
              let nav = currentNav else { return }
        
        guard let item = itemCache.object(forKey: vc),
              item.isConfigured else { return }
        
        apply(style: item.barColorStyle, in: nav)
        apply(item: item)
    }
}

extension PTNavigationBarManager {
    private func startDisplayLink() {
        stopDisplayLink()
        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func handleDisplayLink() {
        guard let coordinator = transitionCoordinatorRef,
              let container = transitionContainer else { return }
        
        let progress = coordinator.percentComplete
        
        container.updateTransition(progress: progress)
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
        let highPriority = UILayoutPriority(999)
        container.leftContainer.setContentCompressionResistancePriority(highPriority, for: .horizontal)
        container.leftContainer.setContentHuggingPriority(.required, for: .horizontal)
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
        let highPriority = UILayoutPriority(999)
        container.rightContainer.setContentCompressionResistancePriority(highPriority, for: .horizontal)
        container.rightContainer.setContentHuggingPriority(.required, for: .horizontal)
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
            make.bottom.equalToSuperview()
            make.top.equalToSuperview().inset(CGFloat.statusBarHeight())

            if self.titleLabel {
                make.left.lessThanOrEqualTo(container.leftContainer.snp.right).offset(PTAppBaseConfig.share.navContainerSpacing).priority(750)
                make.right.lessThanOrEqualTo(container.rightContainer.snp.left).offset(-PTAppBaseConfig.share.navContainerSpacing).priority(750)
                make.centerX.equalToSuperview()
            } else {
                make.left.equalTo(container.leftContainer.snp.right).offset(PTAppBaseConfig.share.navContainerSpacing)
                make.right.equalTo(container.rightContainer.snp.left).offset(-PTAppBaseConfig.share.navContainerSpacing)
            }
        }
        
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

@objcMembers
open class PTBaseViewController: UIViewController {
                   
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
        // 🔥 防止 tab 切换 / 返回导致系统 navbar 恢复
        if let nav = navigationController {
            PTNavigationBarManager.shared.apply(style: preferredNavigationBarStyle(), in: nav)
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PTNSLogConsole("加载完==============================\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())）",levelType: PTLogMode,loggerType: .ViewCycle)        
    }
    
    open override func viewWillDisappear(_ animated:Bool) {
        super.viewWillDisappear(animated)
        PTNSLogConsole("离开==============================\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())）",levelType: PTLogMode,loggerType: .ViewCycle)
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
        }
    }
    
    private func applyNavigationBar() {
        guard let _ = navigationController else { return }
        
        let style = preferredNavigationBarStyle()
        let item = PTNavigationBarManager.shared.item(for: self)
        item.barColorStyle = style
        PTNavigationBarManager.shared.update(item: item, for: self)
        if self.navigationController?.viewControllers.first != self {
            self.setBaseBackButton()
            pt_prefersTabBarHidden = true
        }
        if let _ = self.presentingViewController {
            pt_prefersTabBarHidden = true
            self.setBaseBackButton()
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

    private func baseBackButton() -> UIButton {
        let backBtn = UIButton(type: .custom)
        backBtn.setImage(PTAppBaseConfig.share.viewControllerBackItemImage, for: .normal)
        backBtn.bounds = CGRect.init(x: 0, y: 0, width: 34, height: 34)
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
    
    open func setLeftButtons(views:[UIView], buttonSpacing: CGFloat = 10) {
        guard !views.isEmpty else {
            navigationItem.rightBarButtonItem = nil
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
                self.baseTraitCollectionDidChange(style:previousTraitCollection.userInterfaceStyle)
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    
    @objc func backButtonTapped() {
        self.returnFrontVC()
    }
}

extension PTBaseViewController: UIScrollViewDelegate {
    open func bindScrollView(_ scrollView: UIScrollView) {
        
        self.view.layoutIfNeeded()
        scrollView.delegate = self
        if prefersLargeTitle() {
            let topHeight = scrollView.frame.origin.y + PTAppBaseConfig.share.navLargeTitleBarHeight
            
            scrollView.contentInset.top = topHeight
            scrollView.verticalScrollIndicatorInsets.top = topHeight
            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if prefersLargeTitle() {
            let offset = scrollView.contentOffset.y
            let insetTop = scrollView.contentInset.top
            
            let progress = (offset + insetTop) / PTAppBaseConfig.share.navLargeTitleProgress
            PTNavigationBarManager.shared.updateScrollProgress(progress)
        }
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if prefersLargeTitle() {
            guard scrollView.contentOffset.y < -scrollView.contentInset.top else { return }
            
            UIView.animate(withDuration: 0.25,
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
