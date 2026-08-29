//
//  PTSideMenuControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/3.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public typealias PTSideMenuControlHandler = (_ sideMenuControl: PTSideMenuControl) -> Void
public typealias PTSideMenuControlShowAndAnimationHandler = (_ sideMenuControl: PTSideMenuControl, _ show: UIViewController, _ animated: Bool) -> Void

@objcMembers
@MainActor
open class PTSideMenuControl: PTBaseViewController {

    public enum PTSideMenuError: Error, Equatable, Sendable {
        case contentNotFound(identifier: String)
        case invalidHierarchy
        case transitionCancelled
    }

    public var sideMenuControlGetMenuWidth: ((_ sideMenuControl: PTSideMenuControl, _ forSize: CGSize) -> CGFloat)?
    public var sideMenuControlWillShow: PTSideMenuControlShowAndAnimationHandler?
    public var sideMenuControlDidShow: PTSideMenuControlShowAndAnimationHandler?
    public var sideMenuControlWillReveal: PTSideMenuControlHandler?
    public var sideMenuControlWillHideReveal: PTSideMenuControlHandler?
    public var sideMenuControlDidReveal: PTSideMenuControlHandler?
    public var sideMenuControlDidHideMenu: PTSideMenuControlHandler?
    public var sideMenuControlAnimationIn: ((_ sideMenuControl: PTSideMenuControl, _ animationControllerFrom: UIViewController, _ toVC: UIViewController) -> UIViewControllerAnimatedTransitioning)?
    public var sideMenuControlShouldRevealMenu: ((_ sideMenuControl: PTSideMenuControl) -> Bool)?

    /// 兼容旧项目的全局默认配置。实例创建后使用自己的配置快照。
    @MainActor public static var preferences = PTSideMenuPreferences()
    public private(set) var configuration: PTSideMenuPreferences

    @IBInspectable public var contentSegueID: String = PTSideMenuSegue.ContentType.content.rawValue
    @IBInspectable public var menuSegueID: String = PTSideMenuSegue.ContentType.menu.rawValue

    private var storedContentViewController: UIViewController?
    private var storedMenuViewController: UIViewController?
    private var isUpdatingChildController = false

    private let menuContainerView = UIView()
    private let contentContainerView = UIView()
    private var contentContainerOverlay: UIView?

    private var settledMenuRevealed = false
    private var activeVisibilityTarget: Bool?
    private var activeTransitionInitialVisibility = false
    private var activeShouldCallDelegate = true
    private var activeCompletions: [PTBoolTask] = []
    private var queuedVisibilityRequest: VisibilityRequest?
    private var menuAnimator: UIViewPropertyAnimator?

    private weak var panGestureRecognizer: UIPanGestureRecognizer?
    private weak var edgePanGestureRecognizer: UIScreenEdgePanGestureRecognizer?
    private var isValidatingPanGesture = false

    private struct VisibilityRequest {
        let target: Bool
        let animated: Bool
        let shouldCallDelegate: Bool
        var completions: [PTBoolTask]
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        configuration = Self.preferences
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    public required init?(coder: NSCoder) {
        configuration = Self.preferences
        super.init(coder: coder)
    }

    public convenience init(contentViewController: UIViewController, menuViewController: UIViewController) {
        self.init(contentViewController: contentViewController,
                  menuViewController: menuViewController,
                  preferences: Self.preferences)
    }

    public convenience init(contentViewController: UIViewController,
                            menuViewController: UIViewController,
                            preferences: PTSideMenuPreferences) {
        self.init(nibName: nil, bundle: nil)
        configuration = preferences
        storedContentViewController = contentViewController
        storedMenuViewController = menuViewController
    }

    deinit {
        NotificationCenter.default.removeObserver(self,
                                                   name: UIScene.didEnterBackgroundNotification,
                                                   object: nil)
    }

    open override var childForStatusBarStyle: UIViewController? {
        (activeVisibilityTarget ?? settledMenuRevealed) ? storedMenuViewController : storedContentViewController
    }

    open override var childForStatusBarHidden: UIViewController? {
        (activeVisibilityTarget ?? settledMenuRevealed) ? storedMenuViewController : storedContentViewController
    }

    /// 保留旧的可写属性，内部统一由安全的存储和容器方法处理。
    open var contentViewController: UIViewController! {
        get { storedContentViewController }
        set { setContentController(newValue) }
    }

    /// 保留旧的可写属性，内部统一由安全的存储和容器方法处理。
    open var menuViewController: UIViewController! {
        get { storedMenuViewController }
        set { setMenuController(newValue) }
    }

    /// 菜单当前是否已经稳定显示。
    /// 直接赋值仍然兼容旧代码，但会转换为无动画状态请求。
    open var isMenuRevealed: Bool {
        get { settledMenuRevealed }
        set {
            guard newValue != settledMenuRevealed else { return }
            guard isViewLoaded else {
                settledMenuRevealed = newValue
                return
            }
            changeMenuVisibility(reveal: newValue, animated: false)
        }
    }

    private var shouldShowShadowOnContent: Bool {
        configuration.animation.shouldAddShadowWhenRevealing && configuration.basic.position != .under
    }

    private var shouldReverseDirection: Bool {
        if configuration.basic.forceRightToLeft {
            return true
        }
        guard configuration.basic.shouldRespectLanguageDirection, isViewLoaded else {
            return false
        }
        return view.effectiveUserInterfaceLayoutDirection == .rightToLeft
    }

    private var effectiveDirection: PTSideMenuPreferences.MenuDirection {
        guard shouldReverseDirection else { return configuration.basic.direction }
        return configuration.basic.direction == .left ? .right : .left
    }

    private var directionSign: CGFloat {
        effectiveDirection == .left ? 1 : -1
    }

    private var menuWidth: CGFloat {
        safeMenuWidth(for: isViewLoaded ? view.bounds.size : .zero)
    }

    private func safeMenuWidth(for size: CGSize) -> CGFloat {
        let configuredWidth = configuration.basic.menuWidth
        let fallbackWidth = configuredWidth.isFinite && configuredWidth > 0 ? configuredWidth : 300
        let requestedWidth = sideMenuControlGetMenuWidth?(self, size) ?? fallbackWidth
        let validWidth = requestedWidth.isFinite && requestedWidth > 0 ? requestedWidth : fallbackWidth
        let availableWidth = max(size.width, 0)

        guard availableWidth > 0 else {
            return max(1, validWidth)
        }
        return min(max(1, validWidth), availableWidth)
    }

    private func safeDuration(_ duration: TimeInterval) -> TimeInterval {
        guard duration.isFinite else { return 0 }
        return max(0, duration)
    }

    private func safeDampingRatio(_ value: CGFloat) -> CGFloat {
        guard value.isFinite else { return 1 }
        return min(max(value, 0.01), 1)
    }

    private func safeShadowAlpha(_ value: CGFloat) -> CGFloat {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        guard menuAnimator == nil, activeVisibilityTarget == nil else { return }
        applyLayout(visibility: settledMenuRevealed, size: view.bounds.size)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        if storyboard != nil {
            if storedContentViewController == nil, !contentSegueID.isEmpty {
                performSegue(withIdentifier: contentSegueID, sender: self)
            }
            if storedMenuViewController == nil, !menuSegueID.isEmpty {
                performSegue(withIdentifier: menuSegueID, sender: self)
            }
        }

        if storedContentViewController == nil || storedMenuViewController == nil {
            PTNSLogConsole("[PTSideMenu] 内容或菜单控制器未配置，已禁用对应功能。", levelType: .error, loggerType: .sideMenu)
        }

        // English: Give both containers a dynamic fallback so transparent child views follow the current appearance.
        // Español: Da a ambos contenedores un fondo dinámico para que las vistas hijas transparentes sigan la apariencia actual.
        // 中文：为两个容器提供动态兜底背景，保证透明子视图跟随当前浅色或深色外观。
        view.backgroundColor = .ptPresentationSurface
        contentContainerView.backgroundColor = .ptPresentationSurface
        menuContainerView.backgroundColor = .ptPresentationSurface
        contentContainerView.frame = contentFrame(visibility: settledMenuRevealed)
        menuContainerView.frame = sideMenuFrame(visibility: settledMenuRevealed)
        view.addSubview(contentContainerView)
        view.addSubview(menuContainerView)

        if let contentViewController = storedContentViewController {
            attach(contentViewController, to: contentContainerView)
        }
        if let menuViewController = storedMenuViewController {
            attach(menuViewController, to: menuContainerView)
        }

        if configuration.basic.position == .under {
            view.bringSubviewToFront(contentContainerView)
        }

        setNeedsStatusBarAppearanceUpdate()

        if let key = configuration.basic.defaultCacheKey, let contentViewController = storedContentViewController {
            lazyCachedViewControllers[key] = contentViewController
        }

        configureGesturesRecognizer()
        setUpNotifications()
        updateAccessibilityState(isMenuVisible: settledMenuRevealed)
    }

    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segue = segue as? PTSideMenuSegue, let identifier = segue.identifier else {
            return
        }
        switch identifier {
        case contentSegueID:
            segue.contentType = .content
        case menuSegueID:
            segue.contentType = .menu
        default:
            break
        }
    }

    // MARK: - 子控制器容器

    private func setContentController(_ newValue: UIViewController?) {
        let oldValue = storedContentViewController
        guard oldValue !== newValue else { return }

        if newValue == nil, isViewLoaded {
            PTNSLogConsole("[PTSideMenu] 不允许在已加载页面后将 contentViewController 设为 nil。", levelType: .error, loggerType: .sideMenu)
            return
        }
        if newValue?.parent != nil {
            PTNSLogConsole("[PTSideMenu] contentViewController 已属于其他容器。", levelType: .error, loggerType: .sideMenu)
            return
        }

        storedContentViewController = newValue
        guard isViewLoaded, let newValue else { return }
        guard !isUpdatingChildController else { return }

        isUpdatingChildController = true
        defer { isUpdatingChildController = false }

        sideMenuControlWillShow?(self, newValue, false)
        attach(newValue, to: contentContainerView)
        contentContainerView.sendSubviewToBack(newValue.view)
        detach(oldValue)
        sideMenuControlDidShow?(self, newValue, false)
        setNeedsStatusBarAppearanceUpdate()
    }

    private func setMenuController(_ newValue: UIViewController?) {
        let oldValue = storedMenuViewController
        guard oldValue !== newValue else { return }

        if newValue == nil, isViewLoaded {
            PTNSLogConsole("[PTSideMenu] 不允许在已加载页面后将 menuViewController 设为 nil。", levelType: .error, loggerType: .sideMenu)
            return
        }
        if newValue?.parent != nil {
            PTNSLogConsole("[PTSideMenu] menuViewController 已属于其他容器。", levelType: .error, loggerType: .sideMenu)
            return
        }

        storedMenuViewController = newValue
        guard isViewLoaded, let newValue else { return }
        attach(newValue, to: menuContainerView)
        applyLayout(visibility: settledMenuRevealed, size: view.bounds.size)
    }

    private func attach(_ viewController: UIViewController, to container: UIView) {
        let needsParent = viewController.parent !== self
        if needsParent {
            addChild(viewController)
        }

        if viewController.view.superview !== container {
            viewController.view.removeFromSuperview()
            container.addSubview(viewController.view)
        }
        viewController.view.frame = container.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.view.translatesAutoresizingMaskIntoConstraints = true

        if needsParent {
            viewController.didMove(toParent: self)
        }
    }

    private func detach(_ viewController: UIViewController?) {
        guard let viewController else { return }
        if viewController.parent === self {
            viewController.willMove(toParent: nil)
            viewController.view.removeFromSuperview()
            viewController.removeFromParent()
        } else {
            viewController.view.removeFromSuperview()
        }
    }

    // MARK: - 菜单显示与隐藏

    open func revealMenu(animated: Bool = true, completion: PTBoolTask? = nil) {
        changeMenuVisibility(reveal: true, animated: animated, completion: completion)
    }

    open func hideMenu(animated: Bool = true, completion: PTBoolTask? = nil) {
        changeMenuVisibility(reveal: false, animated: animated, completion: completion)
    }

    private func changeMenuVisibility(reveal: Bool,
                                      animated: Bool = true,
                                      shouldCallDelegate: Bool = true,
                                      completion: PTBoolTask? = nil) {
        let request = VisibilityRequest(target: reveal,
                                        animated: animated,
                                        shouldCallDelegate: shouldCallDelegate,
                                        completions: completion.map { [$0] } ?? [])
        enqueueVisibilityRequest(request)
    }

    private func enqueueVisibilityRequest(_ request: VisibilityRequest) {
        guard isViewLoaded, storedContentViewController != nil, storedMenuViewController != nil else {
            request.completions.forEach { $0(false) }
            return
        }

        if let activeTarget = activeVisibilityTarget {
            if activeTarget == request.target {
                if let queuedVisibilityRequest {
                    queuedVisibilityRequest.completions.forEach { $0(false) }
                    self.queuedVisibilityRequest = nil
                }
                activeCompletions.append(contentsOf: request.completions)
            } else if var queued = queuedVisibilityRequest {
                if queued.target == request.target {
                    queued.completions.append(contentsOf: request.completions)
                    queuedVisibilityRequest = queued
                } else {
                    queued.completions.forEach { $0(false) }
                    queuedVisibilityRequest = request
                }
            } else {
                queuedVisibilityRequest = request
            }
            return
        }

        guard settledMenuRevealed != request.target else {
            request.completions.forEach { $0(true) }
            return
        }

        startMenuTransition(request)
    }

    private func startMenuTransition(_ request: VisibilityRequest, startPaused: Bool = false) {
        guard let menuViewController = storedMenuViewController,
              storedContentViewController != nil else {
            request.completions.forEach { $0(false) }
            return
        }

        activeVisibilityTarget = request.target
        activeTransitionInitialVisibility = settledMenuRevealed
        activeShouldCallDelegate = request.shouldCallDelegate
        activeCompletions = request.completions

        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        let duration = request.target
            ? safeDuration(configuration.animation.revealDuration)
            : safeDuration(configuration.animation.hideDuration)
        let shouldAnimate = startPaused || (request.animated && !reduceMotion && duration > 0)

        if request.shouldCallDelegate {
            if request.target {
                sideMenuControlWillReveal?(self)
            } else {
                sideMenuControlWillHideReveal?(self)
            }
        }
        menuViewController.beginAppearanceTransition(request.target, animated: shouldAnimate)
        if request.target {
            addContentOverlayViewIfNeeded()
        }
        updateAccessibilityState(isMenuVisible: request.target)
        setNeedsStatusBarAppearanceUpdate()

        guard shouldAnimate else {
            applyLayout(visibility: request.target, size: view.bounds.size)
            finishMenuTransition(reachedTarget: true)
            return
        }

        let animator = UIViewPropertyAnimator(duration: max(duration, 0.01), timingParameters: timingParameters())
        animator.addAnimations { [weak self] in
            guard let self else { return }
            self.applyLayout(visibility: request.target, size: self.view.bounds.size)
        }
        animator.addCompletion { [weak self] position in
            self?.finishMenuTransition(reachedTarget: position == .end)
        }
        menuAnimator = animator

        if startPaused {
            animator.startAnimation()
            animator.pauseAnimation()
        } else {
            animator.startAnimation()
        }
    }

    private func timingParameters() -> UITimingCurveProvider {
        let damping = safeDampingRatio(configuration.animation.dampingRatio)
        let velocity = configuration.animation.initialSpringVelocity.isFinite
            ? max(0, configuration.animation.initialSpringVelocity)
            : 0
        if damping < 1 {
            return UISpringTimingParameters(dampingRatio: damping,
                                            initialVelocity: CGVector(dx: velocity, dy: 0))
        }

        let options = configuration.animation.options
        if options.contains(.curveLinear) {
            return UICubicTimingParameters(animationCurve: .linear)
        }
        if options.contains(.curveEaseIn) {
            return UICubicTimingParameters(animationCurve: .easeIn)
        }
        if options.contains(.curveEaseOut) {
            return UICubicTimingParameters(animationCurve: .easeOut)
        }
        return UICubicTimingParameters(animationCurve: .easeInOut)
    }

    private func finishMenuTransition(reachedTarget: Bool) {
        guard let target = activeVisibilityTarget else { return }

        let initialVisibility = activeTransitionInitialVisibility
        let shouldCallDelegate = activeShouldCallDelegate
        let completions = activeCompletions
        let queuedRequest = queuedVisibilityRequest

        menuAnimator = nil
        activeVisibilityTarget = nil
        activeCompletions = []
        self.queuedVisibilityRequest = nil

        let finalVisibility = reachedTarget ? target : !target
        settledMenuRevealed = finalVisibility
        applyLayout(visibility: finalVisibility, size: view.bounds.size)

        if let menuViewController = storedMenuViewController {
            menuViewController.endAppearanceTransition()
            if !reachedTarget {
                // 取消动画时补发相反方向的生命周期，保持 UIKit 生命周期成对。
                menuViewController.beginAppearanceTransition(finalVisibility, animated: false)
                menuViewController.endAppearanceTransition()
            }
        }

        updateAccessibilityState(isMenuVisible: finalVisibility)
        setNeedsStatusBarAppearanceUpdate()

        if shouldCallDelegate, finalVisibility != initialVisibility {
            if finalVisibility {
                sideMenuControlDidReveal?(self)
            } else {
                sideMenuControlDidHideMenu?(self)
            }
        }

        syncGestureAvailability()
        completions.forEach { $0(reachedTarget) }

        if let queuedRequest {
            enqueueVisibilityRequest(queuedRequest)
        }
    }

    // MARK: - 布局与遮罩

    private func sideMenuFrame(visibility: Bool, targetSize: CGSize? = nil) -> CGRect {
        let size = targetSize ?? view.bounds.size
        let width = safeMenuWidth(for: size)

        if configuration.basic.position == .under {
            return CGRect(x: directionSign > 0 ? 0 : size.width - width,
                          y: 0,
                          width: width,
                          height: size.height)
        }

        let shownX = directionSign > 0 ? 0 : size.width - width
        let hiddenX = directionSign > 0 ? -width : size.width
        return CGRect(x: visibility ? shownX : hiddenX,
                      y: 0,
                      width: width,
                      height: size.height)
    }

    private func contentFrame(visibility: Bool, targetSize: CGSize? = nil) -> CGRect {
        let size = targetSize ?? view.bounds.size
        let width = safeMenuWidth(for: size)

        switch configuration.basic.position {
        case .above:
            return CGRect(origin: .zero, size: size)
        case .under, .sideBySide:
            let x = visibility ? directionSign * width : 0
            return CGRect(x: x, y: 0, width: size.width, height: size.height)
        }
    }

    private func applyLayout(visibility: Bool, size: CGSize) {
        contentContainerView.frame = contentFrame(visibility: visibility, targetSize: size)
        menuContainerView.frame = sideMenuFrame(visibility: visibility, targetSize: size)
        contentContainerOverlay?.frame = contentContainerView.bounds

        if let overlay = contentContainerOverlay {
            overlay.alpha = shouldShowShadowOnContent && visibility
                ? safeShadowAlpha(configuration.animation.shadowAlpha)
                : (visibility ? 1 : 0)
            overlay.isHidden = !visibility
        }
    }

    private func addContentOverlayViewIfNeeded() {
        guard let contentViewController = storedContentViewController else { return }

        if let overlay = contentContainerOverlay {
            overlay.isHidden = false
            contentContainerView.bringSubviewToFront(overlay)
            return
        }

        let overlay: UIView
        if configuration.animation.shouldAddBlurWhenRevealing {
            overlay = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        } else {
            overlay = UIView(frame: contentContainerView.bounds)
        }

        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.backgroundColor = shouldShowShadowOnContent
            ? configuration.animation.shadowColor
            : .clear
        overlay.alpha = 0
        overlay.isAccessibilityElement = true
        overlay.accessibilityTraits = .button
        overlay.accessibilityLabel = "PT SideMenu close".localized()
        overlay.accessibilityIdentifier = "ContentShadowOverlay"

        let tapToHideGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        overlay.addGestureRecognizer(tapToHideGesture)
        contentContainerView.insertSubview(overlay, aboveSubview: contentViewController.view)
        contentContainerOverlay = overlay
    }

    @objc private func handleTapGesture(_ tap: UITapGestureRecognizer) {
        hideMenu()
    }

    private func updateAccessibilityState(isMenuVisible: Bool) {
        storedContentViewController?.view.accessibilityElementsHidden = isMenuVisible
        storedMenuViewController?.view.accessibilityViewIsModal = isMenuVisible

        if let overlay = contentContainerOverlay {
            overlay.isHidden = !isMenuVisible
            overlay.accessibilityElementsHidden = !isMenuVisible
        }

        if isMenuVisible {
            UIAccessibility.post(notification: .screenChanged, argument: storedMenuViewController?.view)
        } else {
            UIAccessibility.post(notification: .screenChanged, argument: storedContentViewController?.view)
        }
    }

    // MARK: - 手势

    private func configureGesturesRecognizer() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.delegate = self
        panGesture.cancelsTouchesInView = false
        panGestureRecognizer = panGesture
        view.addGestureRecognizer(panGesture)

        if configuration.basic.revealFromScreenEdgeOnly {
            let edgeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
            edgeGesture.delegate = self
            edgeGesture.edges = effectiveDirection == .left ? .left : .right
            edgePanGestureRecognizer = edgeGesture
            view.addGestureRecognizer(edgeGesture)
        }
        syncGestureAvailability()
    }

    private func syncGestureAvailability() {
        let enabled = configuration.basic.enablePanGesture && activeVisibilityTarget == nil
        panGestureRecognizer?.isEnabled = enabled && (!configuration.basic.revealFromScreenEdgeOnly || settledMenuRevealed)
        edgePanGestureRecognizer?.isEnabled = enabled && configuration.basic.revealFromScreenEdgeOnly && !settledMenuRevealed
    }

    @objc private func handlePanGesture(_ pan: UIPanGestureRecognizer) {
        guard configuration.basic.enablePanGesture else { return }

        switch pan.state {
        case .began:
            guard activeVisibilityTarget == nil,
                  !UIAccessibility.isReduceMotionEnabled,
                  storedMenuViewController != nil,
                  storedContentViewController != nil else {
                return
            }

            let request = VisibilityRequest(target: !settledMenuRevealed,
                                            animated: true,
                                            shouldCallDelegate: true,
                                            completions: [])
            startMenuTransition(request, startPaused: true)
            guard let animator = menuAnimator else { return }
            animator.pauseAnimation()
            isValidatingPanGesture = true

        case .changed:
            guard isValidatingPanGesture, let animator = menuAnimator else { return }
            animator.fractionComplete = panProgress(for: pan)

        case .ended, .cancelled, .failed:
            guard isValidatingPanGesture, let animator = menuAnimator else {
                isValidatingPanGesture = false
                return
            }

            let progress = panProgress(for: pan)
            let velocity = pan.velocity(in: view).x
            let expectedSign = settledMenuRevealed ? -directionSign : directionSign
            let projectedVelocity = velocity * expectedSign
            let shouldComplete: Bool

            if pan.state != .ended {
                shouldComplete = false
            } else if projectedVelocity > 300 {
                shouldComplete = true
            } else if projectedVelocity < -300 {
                shouldComplete = false
            } else {
                shouldComplete = progress > 0.5
            }

            animator.isReversed = !shouldComplete
            let normalizedVelocity = min(abs(projectedVelocity) / max(menuWidth, 1), 10)
            let spring = UISpringTimingParameters(dampingRatio: safeDampingRatio(configuration.animation.dampingRatio),
                                                  initialVelocity: CGVector(dx: normalizedVelocity, dy: 0))
            animator.continueAnimation(withTimingParameters: spring, durationFactor: 0)
            isValidatingPanGesture = false

        default:
            break
        }
    }

    private func panProgress(for pan: UIPanGestureRecognizer) -> CGFloat {
        let translation = pan.translation(in: view).x * directionSign
        var progress = (settledMenuRevealed ? -translation : translation) / max(menuWidth, 1)
        if progress < 0 {
            progress = configuration.basic.enableRubberEffectWhenPanning ? progress * 0.2 : 0
        }
        return min(max(progress, 0), 1)
    }

    // MARK: - 生命周期

    private func setUpNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidEnterBackground(_:)),
                                               name: UIScene.didEnterBackgroundNotification,
                                               object: nil)
    }

    @objc private func appDidEnterBackground(_ notification: Notification) {
        guard let scene = notification.object as? UIScene,
              scene === view.window?.windowScene else {
            return
        }
        if configuration.basic.hideMenuWhenEnteringBackground {
            hideMenu(animated: false)
        }
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        settleActiveTransitionForLayout()
        let shouldCloseMenu = !configuration.basic.keepsMenuOpenAfterRotation && settledMenuRevealed
        if shouldCloseMenu {
            changeMenuVisibility(reveal: false, animated: false)
        }

        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self else { return }
            self.applyLayout(visibility: self.settledMenuRevealed, size: size)
        }, completion: { [weak self] _ in
            guard let self else { return }
            self.applyLayout(visibility: self.settledMenuRevealed, size: self.view.bounds.size)
        })
    }

    private func settleActiveTransitionForLayout() {
        guard let target = activeVisibilityTarget else { return }
        let shouldReachTarget = (menuAnimator?.fractionComplete ?? 0) >= 0.5
        let finalVisibility = shouldReachTarget ? target : !target
        menuAnimator?.stopAnimation(true)
        finishMenuTransition(reachedTarget: finalVisibility == target)
    }

    // MARK: - 缓存

    private lazy var lazyCachedViewControllerGenerators: [String: () -> UIViewController?] = [:]
    private lazy var lazyCachedViewControllers: [String: UIViewController] = [:]

    open func cache(viewControllerGenerator: @escaping () -> UIViewController?, with identifier: String) {
        lazyCachedViewControllerGenerators[identifier] = viewControllerGenerator
    }

    open func cache(viewController: UIViewController, with identifier: String) {
        lazyCachedViewControllers[identifier] = viewController
    }

    open func selectContent(with identifier: String,
                            animated: Bool = false,
                            completion: @escaping @MainActor @Sendable (Result<Void, PTSideMenuError>) -> Void) {
        if let viewController = lazyCachedViewControllers[identifier] {
            switchContent(to: viewController, animated: animated, completion: completion)
            return
        }

        guard let viewController = lazyCachedViewControllerGenerators[identifier]?() else {
            completion(.failure(.contentNotFound(identifier: identifier)))
            return
        }

        lazyCachedViewControllerGenerators[identifier] = nil
        lazyCachedViewControllers[identifier] = viewController
        switchContent(to: viewController, animated: animated, completion: completion)
    }

    open func selectContent(with identifier: String, animated: Bool = false) async throws {
        try await withCheckedThrowingContinuation { continuation in
            selectContent(with: identifier, animated: animated) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    open func setContentViewController(with identifier: String,
                                       animated: Bool = false,
                                       completion: PTActionTask? = nil) {
        selectContent(with: identifier, animated: animated) { result in
            if case .failure(let error) = result {
                PTNSLogConsole("[PTSideMenu] 内容切换失败：\(error)", levelType: .error, loggerType: .sideMenu)
            }
            completion?()
        }
    }

    open func setContentViewController(to viewController: UIViewController,
                                       animated: Bool = false,
                                       completion: PTActionTask? = nil) {
        guard contentViewController !== viewController else {
            completion?()
            return
        }

        guard let currentContent = storedContentViewController else {
            setContentController(viewController)
            completion?()
            return
        }

        guard isViewLoaded else {
            storedContentViewController = viewController
            completion?()
            return
        }

        if animated {
            switchContent(from: currentContent, to: viewController, animated: true) { result in
                if case .failure(let error) = result {
                    PTNSLogConsole("[PTSideMenu] 内容转场失败：\(error)", levelType: .error, loggerType: .sideMenu)
                }
                completion?()
            }
        } else {
            setContentController(viewController)
            completion?()
        }
    }

    private func switchContent(to viewController: UIViewController,
                               animated: Bool,
                               completion: @escaping @MainActor @Sendable (Result<Void, PTSideMenuError>) -> Void) {
        guard let currentContent = storedContentViewController else {
            setContentController(viewController)
            completion(.success(()))
            return
        }
        guard currentContent !== viewController else {
            completion(.success(()))
            return
        }
        guard isViewLoaded else {
            storedContentViewController = viewController
            completion(.success(()))
            return
        }
        guard viewController.parent == nil else {
            completion(.failure(.invalidHierarchy))
            return
        }

        if animated {
            switchContent(from: currentContent, to: viewController, animated: true, completion: completion)
        } else {
            setContentController(viewController)
            completion(.success(()))
        }
    }

    private func switchContent(from currentContent: UIViewController,
                               to newContent: UIViewController,
                               animated: Bool,
                               completion: @escaping @MainActor @Sendable (Result<Void, PTSideMenuError>) -> Void) {
        guard currentContent.view.superview != nil else {
            completion(.failure(.invalidHierarchy))
            return
        }

        sideMenuControlWillShow?(self, newContent, animated)
        addChild(newContent)
        newContent.view.frame = contentContainerView.bounds
        newContent.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        newContent.view.translatesAutoresizingMaskIntoConstraints = true
        contentContainerView.addSubview(newContent.view)

        guard let transitionContext = TransitionContext(fromViewController: currentContent,
                                                         toViewController: newContent,
                                                         containerView: contentContainerView) else {
            newContent.willMove(toParent: nil)
            newContent.view.removeFromSuperview()
            newContent.removeFromParent()
            completion(.failure(.invalidHierarchy))
            return
        }

        let animator = sideMenuControlAnimationIn?(self, currentContent, newContent)
            ?? PTSideMenuBasicTransitionAnimator(options: configuration.animation.options,
                                                  duration: safeDuration(configuration.animation.revealDuration))
        transitionContext.completion = { [weak self, weak currentContent, weak newContent] finished in
            guard let self, let currentContent, let newContent else {
                return
            }
            if finished {
                self.detach(currentContent)
                self.storedContentViewController = newContent
                newContent.didMove(toParent: self)
                self.sideMenuControlDidShow?(self, newContent, animated)
                completion(.success(()))
            } else {
                newContent.willMove(toParent: nil)
                newContent.view.removeFromSuperview()
                newContent.removeFromParent()
                completion(.failure(.transitionCancelled))
            }
        }
        animator.animateTransition(using: transitionContext)
    }

    open func currentCacheIdentifier() -> String? {
        lazyCachedViewControllers.first { $0.value === storedContentViewController }?.key
    }

    open func clearCache(with identifier: String) {
        lazyCachedViewControllerGenerators[identifier] = nil
        lazyCachedViewControllers[identifier] = nil
    }

    // MARK: - 旋转配置

    open override var shouldAutorotate: Bool {
        if configuration.basic.shouldUseContentSupportedOrientations {
            return true
        }
        return configuration.basic.shouldAutorotate
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if configuration.basic.shouldUseContentSupportedOrientations {
            return storedContentViewController?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
        }
        return configuration.basic.supportedOrientations
    }

    // MARK: - UIGestureRecognizerDelegate

    @objc(gestureRecognizer:shouldReceiveTouch:)
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard configuration.basic.enablePanGesture, activeVisibilityTarget == nil else {
            return false
        }
        if gestureRecognizer === edgePanGestureRecognizer, settledMenuRevealed {
            return false
        }
        if gestureRecognizer === panGestureRecognizer,
           configuration.basic.revealFromScreenEdgeOnly,
           !settledMenuRevealed {
            return false
        }

        if !settledMenuRevealed, sideMenuControlShouldRevealMenu?(self) == false {
            return false
        }
        if !settledMenuRevealed && isViewControllerInsideNavigationStack(for: touch.view) {
            return false
        }
        if touch.view is UISlider {
            return false
        }
        if !settledMenuRevealed,
           let scrollView = nearestScrollView(from: touch.view),
           scrollViewCanConsumeHorizontalPan(scrollView) {
            return false
        }
        return true
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard activeVisibilityTarget == nil, !UIAccessibility.isReduceMotionEnabled else {
            return false
        }
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
            return false
        }
        return isValidateHorizontalMovement(for: panGesture.velocity(in: view))
    }

    private func isViewControllerInsideNavigationStack(for view: UIView?) -> Bool {
        var current = view?.parentViewController
        while let viewController = current {
            if let navigationController = viewController as? UINavigationController {
                return navigationController.viewControllers.count > 1
            }
            if let navigationController = viewController.navigationController,
               let index = navigationController.viewControllers.firstIndex(of: viewController) {
                return index > 0
            }
            current = viewController.parent
        }
        return false
    }

    private func nearestScrollView(from view: UIView?) -> UIScrollView? {
        var current = view
        while let candidate = current {
            if let scrollView = candidate as? UIScrollView {
                return scrollView
            }
            current = candidate.superview
        }
        return nil
    }

    private func scrollViewCanConsumeHorizontalPan(_ scrollView: UIScrollView) -> Bool {
        let minimumOffset = -scrollView.adjustedContentInset.left
        let maximumOffset = max(minimumOffset,
                                scrollView.contentSize.width
                                - scrollView.bounds.width
                                + scrollView.adjustedContentInset.right)
        guard maximumOffset > minimumOffset else { return false }

        let atLeadingEdge = scrollView.contentOffset.x <= minimumOffset + 0.5
        let atTrailingEdge = scrollView.contentOffset.x >= maximumOffset - 0.5
        if directionSign > 0 {
            return !atLeadingEdge
        }
        return !atTrailingEdge
    }

    private func isValidateHorizontalMovement(for velocity: CGPoint) -> Bool {
        guard abs(velocity.x) > 0.01 else { return false }
        let expectedSign = settledMenuRevealed ? -directionSign : directionSign
        guard velocity.x * expectedSign > 0 else { return false }

        let sensitivity = configuration.basic.panGestureSensitivity.isFinite
            ? max(configuration.basic.panGestureSensitivity, 0.01)
            : 0.25
        return abs(velocity.y / velocity.x) < sensitivity
    }
}

extension PTSideMenuControl {
    @MainActor
    final class TransitionContext: NSObject, UIViewControllerContextTransitioning {
        let containerView: UIView
        let presentationStyle: UIModalPresentationStyle = .custom
        private let viewControllers: [UITransitionContextViewControllerKey: UIViewController]
        var isAnimated = true
        var targetTransform: CGAffineTransform = .identity
        var isInteractive = false
        var transitionWasCancelled = false
        var completion: ((Bool) -> Void)?
        private var didComplete = false

        init?(fromViewController: UIViewController,
              toViewController: UIViewController,
              containerView: UIView) {
            guard fromViewController.view.superview != nil else { return nil }
            self.containerView = containerView
            self.viewControllers = [
                .from: fromViewController,
                .to: toViewController
            ]
            super.init()
        }

        func completeTransition(_ didComplete: Bool) {
            guard !self.didComplete else { return }
            self.didComplete = true
            transitionWasCancelled = !didComplete
            completion?(didComplete)
        }

        func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
            viewControllers[key]
        }

        func view(forKey key: UITransitionContextViewKey) -> UIView? {
            switch key {
            case .from:
                return viewControllers[.from]?.view
            case .to:
                return viewControllers[.to]?.view
            default:
                return nil
            }
        }

        func initialFrame(for vc: UIViewController) -> CGRect {
            containerView.bounds
        }

        func finalFrame(for vc: UIViewController) -> CGRect {
            containerView.bounds
        }

        func updateInteractiveTransition(_ percentComplete: CGFloat) {}
        func finishInteractiveTransition() {}
        func cancelInteractiveTransition() {}
        func pauseInteractiveTransition() {}
    }
}

extension PTSideMenuControl {
    public struct PTSideMenuPreferences {
        public enum MenuDirection {
            case left
            case right
        }

        public enum MenuPosition {
            case above
            case under
            case sideBySide
        }

        public struct PTSideMenuAnimation {
            public var revealDuration: TimeInterval = 0.4
            public var hideDuration: TimeInterval = 0.4
            public var options: UIView.AnimationOptions = .curveEaseInOut
            public var dampingRatio: CGFloat = 1
            public var initialSpringVelocity: CGFloat = 1
            public var shouldAddShadowWhenRevealing = true
            public var shadowAlpha: CGFloat = 0.2
            public var shadowColor: UIColor = .black
            public var shouldAddBlurWhenRevealing = false

            public init() {}
        }

        public struct PTSideMentConfiguration {
            public var menuWidth: CGFloat = 300
            public var position: MenuPosition = .above
            public var shouldRespectLanguageDirection = true
            public var forceRightToLeft = false
            public var direction: MenuDirection = .left
            public var enablePanGesture = true
            public var revealFromScreenEdgeOnly = false
            public var enableRubberEffectWhenPanning = true
            public var hideMenuWhenEnteringBackground = false
            public var defaultCacheKey: String?
            public var shouldUseContentSupportedOrientations = false
            public var supportedOrientations: UIInterfaceOrientationMask = .allButUpsideDown
            public var shouldAutorotate = true
            public var panGestureSensitivity: CGFloat = 0.25
            public var keepsMenuOpenAfterRotation = false

            public init() {}
        }

        /// 正确拼写的配置名称，旧名称继续保留以兼容已有调用方。
        public typealias PTSideMenuConfiguration = PTSideMentConfiguration

        public var basic = PTSideMentConfiguration()
        public var animation = PTSideMenuAnimation()

        public init() {}
    }
}

extension PTSideMenuControl {
    @MainActor
    open func revealMenuAsync(animated: Bool = true) async -> Bool {
        await withCheckedContinuation { continuation in
            revealMenu(animated: animated) { result in
                continuation.resume(returning: result)
            }
        }
    }

    @MainActor
    open func hideMenuAsync(animated: Bool = true) async -> Bool {
        await withCheckedContinuation { continuation in
            hideMenu(animated: animated) { result in
                continuation.resume(returning: result)
            }
        }
    }
}
