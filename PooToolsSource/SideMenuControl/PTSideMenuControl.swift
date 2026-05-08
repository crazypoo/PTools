//
//  PTSideMenuControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/3.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public typealias PTSideMenuControlHandler = (_ sideMenuControl:PTSideMenuControl) -> Void
public typealias PTSideMenuControlShowAndAnimationHandler = (_ sideMenuControl:PTSideMenuControl,_ show:UIViewController,_ animated:Bool) -> Void

@objcMembers
open class PTSideMenuControl: PTBaseViewController {
    
    public var sideMenuControlGetMenuWidth:((_ sideMenuControl:PTSideMenuControl,_ forSize:CGSize)->CGFloat)?
    public var sideMenuControlWillShow:PTSideMenuControlShowAndAnimationHandler?
    public var sideMenuControlDidShow:PTSideMenuControlShowAndAnimationHandler?
    public var sideMenuControlWillReveal:PTSideMenuControlHandler?
    public var sideMenuControlWillHideReveal:PTSideMenuControlHandler?
    public var sideMenuControlDidReveal:PTSideMenuControlHandler?
    public var sideMenuControlDidHideMenu:PTSideMenuControlHandler?
    public var sideMenuControlAnimationIn:((_ sideMenuControl:PTSideMenuControl,_ animationControllerFrom:UIViewController,_ toVC:UIViewController)->UIViewControllerAnimatedTransitioning)?
    public var sideMenuControlShouldRevealMenu:((_ sideMenuControl:PTSideMenuControl)->Bool)?

    public static var preferences = PTSideMenuPreferences()
    private var preferences:PTSideMenuPreferences {
        return Self.preferences
    }
    
    private lazy var adjustedDirection = PTSideMenuPreferences.MenuDirection.left
    
    private var isInitiatedFromStoryboard: Bool {
        storyboard != nil
    }
    
    private var menuWidth:CGFloat {
        sideMenuControlGetMenuWidth?(self,view.frame.size) ?? preferences.basic.menuWidth
    }
    
    @IBInspectable public var contentSegueID:String = PTSideMenuSegue.ContentType.content.rawValue
    @IBInspectable public var menuSegueID:String = PTSideMenuSegue.ContentType.menu.rawValue
    
    private lazy var lazyCachedViewControllerGenerators: [String: () -> UIViewController?] = [:]
    private lazy var lazyCachedViewControllers: [String: UIViewController] = [:]

    private var shouldCallSwitchingDelegate = true

    private var menuAnimator: UIViewPropertyAnimator?
    
    open override var childForStatusBarStyle: UIViewController? {
        return isMenuRevealed ? menuViewController : contentViewController
    }

    open override var childForStatusBarHidden: UIViewController? {
        return isMenuRevealed ? menuViewController : contentViewController
    }
    
    open var contentViewController: UIViewController! {
        didSet {
            guard contentViewController !== oldValue &&
                isViewLoaded &&
                !children.contains(contentViewController) else {
                    return
            }

            if shouldCallSwitchingDelegate {
                if sideMenuControlWillShow != nil {
                    sideMenuControlWillShow!(self,contentViewController,false)
                }
            }

            load(contentViewController, on: contentContainerView)
            contentContainerView.sendSubviewToBack(contentViewController.view)
            unload(oldValue)

            if shouldCallSwitchingDelegate {
                if sideMenuControlDidShow != nil {
                    sideMenuControlDidShow!(self,contentViewController,false)
                }
            }

            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    open var menuViewController: UIViewController! {
        didSet {
            guard menuViewController !== oldValue && isViewLoaded else {
                return
            }

            load(menuViewController, on: menuContainerView)
            unload(oldValue)
        }
    }

    private let menuContainerView = UIView()
    private let contentContainerView = UIView()
    private var statusBarScreenShotView: UIView?
    
    open var isMenuRevealed = false

    private var shouldShowShadowOnContent: Bool {
        return preferences.animation.shouldAddShadowWhenRevealing && preferences.basic.position != .under
    }
    
    private var isValidatePanningBegan = false
    private var panningBeganPointX: CGFloat = 0

    private var isContentOrMenuNotInitialized: Bool {
        return menuViewController == nil || contentViewController == nil
    }
    
    private weak var contentContainerOverlay: UIView?

    private weak var panGestureRecognizer: UIPanGestureRecognizer?

    var shouldReverseDirection: Bool {
        if preferences.basic.forceRightToLeft { return true }
        guard preferences.basic.shouldRespectLanguageDirection else {
            return false
        }
        let attribute = view.semanticContentAttribute
        let layoutDirection = UIView.userInterfaceLayoutDirection(for: attribute)
        return layoutDirection == .rightToLeft
    }
    
    public convenience init(contentViewController: UIViewController, menuViewController: UIViewController) {
        self.init(nibName: nil, bundle: nil)

        self.contentViewController = contentViewController
        self.menuViewController = menuViewController
    }

    deinit {}

    open override func viewDidLoad() {
        super.viewDidLoad()
        
        if isInitiatedFromStoryboard && isContentOrMenuNotInitialized {
            performSegue(withIdentifier: contentSegueID, sender: self)
            performSegue(withIdentifier: menuSegueID, sender: self)
        }

        if isContentOrMenuNotInitialized {
            fatalError("[PTSideMenuSwift] `menuViewController` or `contentViewController` should not be nil.")
        }

        contentContainerView.frame = view.bounds
        view.addSubview(contentContainerView)

        resolveDirection(with: contentContainerView)

        menuContainerView.frame = sideMenuFrame(visibility: false)
        view.addSubview(menuContainerView)

        load(contentViewController, on: contentContainerView)
        load(menuViewController, on: menuContainerView)

        if preferences.basic.position == .under {
            view.bringSubviewToFront(contentContainerView)
        }

        setNeedsStatusBarAppearanceUpdate()

        if let key = preferences.basic.defaultCacheKey {
            lazyCachedViewControllers[key] = contentViewController
        }

        configureGesturesRecognizer()
        setUpNotifications()
    }
    
    private func resolveDirection(with view: UIView) {
        if shouldReverseDirection {
            adjustedDirection = (preferences.basic.direction == .left ? .right : .left)
        } else {
            adjustedDirection = preferences.basic.direction
        }
    }

    // MARK: Storyboard
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

    // MARK: 展示/隐藏
    /// 展示Menu
    /// - Parameters:
    ///   - animated: 动画
    ///   - completion: 完成回调
    open func revealMenu(animated: Bool = true, completion: PTBoolTask? = nil) {
        changeMenuVisibility(reveal: true, animated: animated, completion: completion)
    }

    /// 隐藏Menu
    /// - Parameters:
    ///   - animated: 动画
    ///   - completion: 完成回调
    open func hideMenu(animated: Bool = true, completion: PTBoolTask? = nil) {
        changeMenuVisibility(reveal: false, animated: animated, completion: completion)
    }

    private func changeMenuVisibility(reveal: Bool,
                                      animated: Bool = true,
                                      shouldCallDelegate: Bool = true,
                                      shouldChangeStatusBar: Bool = true,
                                      completion: PTBoolTask? = nil) {
        
        // 如果已有正在运行的动画，先停止它
        if let runningAnimator = menuAnimator, runningAnimator.isRunning {
            runningAnimator.stopAnimation(true)
        }

        menuViewController.beginAppearanceTransition(reveal, animated: animated)

        if shouldCallDelegate {
            reveal ? sideMenuControlWillReveal?(self) : sideMenuControlWillHideReveal?(self)
        }

        if reveal {
            addContentOverlayViewIfNeeded()
        }

        self.view.isUserInteractionEnabled = false
        
        // 1. 创建动画器
        let animator = UIViewPropertyAnimator(duration: reveal ? preferences.animation.revealDuration : preferences.animation.hideDuration,
                                              dampingRatio: preferences.animation.dampingRatio)
        
        // 2. 配置动画状态
        animator.addAnimations {
            self.menuContainerView.frame = self.sideMenuFrame(visibility: reveal)
            self.contentContainerView.frame = self.contentFrame(visibility: reveal)
            if self.shouldShowShadowOnContent {
                self.contentContainerOverlay?.alpha = reveal ? self.preferences.animation.shadowAlpha : 0
            }
            
            if shouldChangeStatusBar {
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
        
        // 3. 配置完成回调
        animator.addCompletion { [weak self] position in
            guard let self = self else { return }
            
            // 判断动画是否因为被反转而回到起点
            let didReveal = position == .end ? reveal : !reveal
            
            self.menuViewController.endAppearanceTransition()

            if shouldCallDelegate {
                if didReveal {
                    self.sideMenuControlDidReveal?(self)
                } else {
                    self.sideMenuControlDidHideMenu?(self)
                }
            }

            if !didReveal {
                self.contentContainerOverlay?.removeFromSuperview()
                self.contentContainerOverlay = nil
            }

            completion?(true)
            self.view.isUserInteractionEnabled = true
            self.isMenuRevealed = didReveal
            self.menuAnimator = nil
        }

        self.menuAnimator = animator

        // 4. 执行动画
        if animated {
            animator.startAnimation()
        } else {
            // 无动画直接触发结束状态
            animator.fractionComplete = 1.0
            animator.stopAnimation(false)
            animator.finishAnimation(at: .end)
        }
    }
    
    // MARK: Gesture Recognizer
    private func configureGesturesRecognizer() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(PTSideMenuControl.handlePanGesture(_:)))
        panGesture.delegate = self
        panGestureRecognizer = panGesture
        view.addGestureRecognizer(panGesture)
    }

    private func addContentOverlayViewIfNeeded() {
        guard contentContainerOverlay == nil else {
            return
        }

        var overlay:UIView
        if PTSideMenuControl.preferences.animation.shouldAddBlurWhenRevealing {
            let blurEffect = UIBlurEffect(style: .light)
            overlay = UIVisualEffectView(effect: blurEffect)
        } else {
            overlay = UIView(frame: contentContainerView.bounds)
        }
        overlay.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        if !shouldShowShadowOnContent {
            overlay.backgroundColor = .clear
        } else {
            overlay.backgroundColor = PTSideMenuControl.preferences.animation.shadowColor
            overlay.alpha = 0
        }

        let tapToHideGesture = UITapGestureRecognizer()
        tapToHideGesture.addTarget(self, action: #selector(PTSideMenuControl.handleTapGesture(_:)))
        overlay.addGestureRecognizer(tapToHideGesture)

        contentContainerView.insertSubview(overlay, aboveSubview: contentViewController.view)
        contentContainerOverlay = overlay
        contentContainerOverlay?.accessibilityIdentifier = "ContentShadowOverlay"
    }

    @objc private func handleTapGesture(_ tap: UITapGestureRecognizer) {
        hideMenu()
    }

    @objc private func handlePanGesture(_ pan: UIPanGestureRecognizer) {
        let isLeft = adjustedDirection == .left
        let translation = pan.translation(in: view).x
        let velocity = pan.velocity(in: view).x
        
        // 计算移动因数：处理左右方向以及 RTL 适配
        var factor: CGFloat = isLeft ? 1 : -1
        if shouldReverseDirection { factor *= -1 }

        switch pan.state {
        case .began:
            // 如果没有 Animator，说明是手势主动触发，我们需要创建它并暂停
            if menuAnimator == nil {
                let targetReveal = !isMenuRevealed
                changeMenuVisibility(reveal: targetReveal, shouldCallDelegate: true, shouldChangeStatusBar: true)
                // 立即暂停动画，交由手势控制进度
                menuAnimator?.pauseAnimation()
            } else {
                // 如果动画正在运行（比如点击了按钮正在打开，此时用户用手指按住），直接暂停接管
                menuAnimator?.pauseAnimation()
            }
            isValidatePanningBegan = true
            
        case .changed:
            guard isValidatePanningBegan, let animator = menuAnimator else { return }
            
            // 计算手势拖拽进度 (0.0 到 1.0)
            var progress = (translation * factor) / menuWidth
            
            // 如果当前是打开状态，手势是反向的（用于关闭）
            if isMenuRevealed {
                progress = -progress
            }
            
            // 实现简单的阻尼（橡皮筋）效果
            if progress < 0 {
                // 反向拖动（越界），给进度打个折扣
                if preferences.basic.enableRubberEffectWhenPanning {
                    progress = progress * 0.2
                } else {
                    progress = 0
                }
            }
            
            // 更新动画进度
            animator.fractionComplete = min(max(0, progress), 1)
            
        case .ended, .cancelled, .failed:
            guard let animator = menuAnimator else { return }
            
            var progress = (translation * factor) / menuWidth
            if isMenuRevealed { progress = -progress }
            
            // 速度阈值：用来判断用户是否进行了“甩”的操作
            let velocityThreshold: CGFloat = 300
            
            let isMovingInFavorableDirection = isMenuRevealed ? (velocity * factor < -velocityThreshold) : (velocity * factor > velocityThreshold)
            let isMovingInOppositeDirection = isMenuRevealed ? (velocity * factor > velocityThreshold) : (velocity * factor < -velocityThreshold)
            
            let shouldComplete: Bool
            if isMovingInFavorableDirection {
                // 速度够快且方向正确，判定完成
                shouldComplete = true
            } else if isMovingInOppositeDirection {
                // 速度够快但方向相反（比如打开时反悔往回甩），判定取消
                shouldComplete = false
            } else {
                // 速度慢，按拖动距离过半来判定
                shouldComplete = progress > 0.5
            }
            
            // 关键：如果不完成，就将动画反转，它会自动回到起点
            animator.isReversed = !shouldComplete
            
            // 继承手指离开屏幕时的速度，让松手后的回弹更加符合物理规律
            let normalizedVelocity = CGVector(dx: abs(velocity) / menuWidth, dy: 0)
            let springParameters = UISpringTimingParameters(dampingRatio: preferences.animation.dampingRatio, initialVelocity: normalizedVelocity)
            
            animator.continueAnimation(withTimingParameters: springParameters, durationFactor: 0)
            isValidatePanningBegan = false
            
        default:
            break
        }
    }
    
    // MARK: Notification
    private func setUpNotifications() {
        NotificationCenter.default.addObserver(self,
                                                   selector: #selector(appDidEnteredBackground),
                                                   name: UIScene.didEnterBackgroundNotification,
                                                   object: nil)
        NotificationCenter.default.addObserver(self,
                                                   selector: #selector(appDidEnteredBackground),
                                                   name: UIApplication.didEnterBackgroundNotification,
                                                   object: nil)
    }

    @objc private func appDidEnteredBackground() {
        if preferences.basic.hideMenuWhenEnteringBackground {
            hideMenu(animated: false)
        }
    }

    // MARK: Caching
    /// 缓存生成带有标识符的视图控制器的闭包。
    /// 当您想要配置缓存关系而不立即实例化视图控制器时，它很有用。
    /// - Parameters:
    ///   - viewControllerGenerator: 用到的时候才执行
    ///   - identifier: ID
    open func cache(viewControllerGenerator: @escaping () -> UIViewController?, with identifier: String) {
        lazyCachedViewControllerGenerators[identifier] = viewControllerGenerator
    }

    /// 根据ID缓存ViewController
    /// - Parameters:
    ///   - viewController: 被缓存的ViewController
    ///   - identifier: ID
    open func cache(viewController: UIViewController, with identifier: String) {
        lazyCachedViewControllers[identifier] = viewController
    }

    /// 将内容视图控制器更改为具有给定`identifier `的缓存控制器。
    /// - Parameters:
    ///   - identifier: 与缓存视图控制器或生成器关联的ID。
    ///   - animated: 动画, 默认 `false`.
    ///   - completion: 完成闭包将在转换完成时调用。注意，如果调用者是当前内容视图控制器，一旦转换完成，调用者将从父视图控制器中移除，并且它将无法通过`sideMenuController `访问侧菜单控制器
    open func setContentViewController(with identifier: String,
                                       animated: Bool = false,
                                       completion: PTActionTask? = nil) {
        if let viewController = lazyCachedViewControllers[identifier] {
            setContentViewController(to: viewController, animated: animated, completion: completion)
        } else if let viewController = lazyCachedViewControllerGenerators[identifier]?() {
            lazyCachedViewControllerGenerators[identifier] = nil
            lazyCachedViewControllers[identifier] = viewController
            setContentViewController(to: viewController, animated: animated, completion: completion)
        } else {
            fatalError("[SideMenu] View controller associated with \(identifier) not found!")
        }
    }

    /// 将Content view controler转到`viewController`
    /// - Parameters:
    ///   - viewController: 将要转到的ViewController
    ///   - animated: 动画, 默认 `false`.
    ///   - completion: 完成闭包将在转换完成时调用。注意，如果调用者是当前内容视图控制器，一旦转换完成，调用者将从父视图中移除
    open func setContentViewController(to viewController: UIViewController,
                                       animated: Bool = false,
                                       completion: PTActionTask? = nil) {
        guard contentViewController !== viewController && isViewLoaded else {
            completion?()
            return
        }

        if animated {
            sideMenuControlWillShow?(self,viewController,animated)

            addChild(viewController)

            viewController.view.frame = view.bounds
            viewController.view.translatesAutoresizingMaskIntoConstraints = true
            viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            let animatorFromDelegate = sideMenuControlAnimationIn?(self,contentViewController,viewController)

            #if DEBUG
            if animatorFromDelegate == nil {
                PTNSLogConsole("[PTSideMenu] `setContentViewController` is called with animated while the delegate method return nil, fall back to the fade animation.",levelType: .error,loggerType: .sideMenu)
            }
            #endif

            let animator = animatorFromDelegate ?? PTSideMenuBasicTransitionAnimator()

            let transitionContext = PTSideMenuControl.TransitionContext(with: contentViewController,
                                                                         toViewController: viewController)
            transitionContext.isAnimated = true
            transitionContext.isInteractive = false
            transitionContext.completion = { finish in
                self.unload(self.contentViewController)

                self.shouldCallSwitchingDelegate = false
                self.contentViewController = viewController
                self.shouldCallSwitchingDelegate = true

                self.sideMenuControlDidShow?(self,viewController,animated)

                viewController.didMove(toParent: self)

                completion?()
            }
            animator.animateTransition(using: transitionContext)

        } else {
            contentViewController = viewController
            completion?()
        }
    }

    /// 查找当前Content view controller的ID
    /// - Returns: 如果找不到就nil
    open func currentCacheIdentifier() -> String? {
        guard let index = lazyCachedViewControllers.values.firstIndex(of: contentViewController) else {
            return nil
        }
        return lazyCachedViewControllers.keys[index]
    }

    /// 根据ID清理缓存
    /// - Parameter identifier: 被清理的ID
    open func clearCache(with identifier: String) {
        lazyCachedViewControllerGenerators[identifier] = nil
        lazyCachedViewControllers[identifier] = nil
    }

    // MARK: - Helper Methods
    private func sideMenuFrame(visibility: Bool, targetSize: CGSize? = nil) -> CGRect {
        let position = preferences.basic.position
        switch position {
        case .above, .sideBySide:
            var baseFrame = CGRect(origin: view.frame.origin, size: targetSize ?? view.frame.size)
            if visibility {
                baseFrame.origin.x = menuWidth - baseFrame.width
            } else {
                baseFrame.origin.x = -baseFrame.width
            }
            let factor: CGFloat = adjustedDirection == .left ? 1 : -1
            baseFrame.origin.x *= factor
            return CGRect(origin: baseFrame.origin, size: targetSize ?? baseFrame.size)
        case .under:
            return CGRect(origin: view.frame.origin, size: targetSize ?? view.frame.size)
        }
    }

    private func contentFrame(visibility: Bool, targetSize: CGSize? = nil) -> CGRect {
        let position = preferences.basic.position
        switch position {
        case .above:
            return CGRect(origin: view.frame.origin, size: targetSize ?? view.frame.size)
        case .under, .sideBySide:
            var baseFrame = CGRect(origin: view.frame.origin, size: targetSize ?? view.frame.size)
            if visibility {
                let factor: CGFloat = adjustedDirection == .left ? 1 : -1
                baseFrame.origin.x = menuWidth * factor
            } else {
                baseFrame.origin.x = 0
            }
            return CGRect(origin: baseFrame.origin, size: targetSize ?? baseFrame.size)
        }
    }

    private func keepSideMenuOpenOnRotation() {
        guard menuViewController != nil else {
            return
        }
        
        if isMenuRevealed {
            hideMenu(animated: false, completion: nil)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                self.revealMenu(animated: false, completion: nil)
            })
        } else {
            revealMenu(animated: false) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                    self.hideMenu(animated: false, completion: nil)
                })
            }
        }
    }

    // MARK: Orientation
    open override var shouldAutorotate: Bool {
        if preferences.basic.shouldUseContentSupportedOrientations {
            return contentViewController.shouldAutorotate
        }
        return preferences.basic.shouldAutorotate
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if preferences.basic.shouldUseContentSupportedOrientations {
            return contentViewController.supportedInterfaceOrientations
        }
        return preferences.basic.supportedOrientations
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if preferences.basic.keepsMenuOpenAfterRotation {
            keepSideMenuOpenOnRotation()
        } else {
            hideMenu(animated: false, completion: { _ in
                // Temporally hide the menu container view for smooth animation
                self.menuContainerView.isHidden = true
                coordinator.animate(alongsideTransition: { _ in
                    self.contentContainerView.frame = self.contentFrame(visibility: self.isMenuRevealed, targetSize: size)
                }, completion: { (_) in
                    self.menuContainerView.isHidden = false
                    self.menuContainerView.frame = self.sideMenuFrame(visibility: self.isMenuRevealed, targetSize: size)
                })
            })
        }
        super.viewWillTransition(to: size, with: coordinator)
    }
}

// MARK: UIGestureRecognizerDelegate
extension PTSideMenuControl {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard preferences.basic.enablePanGesture else {
            return false
        }

        if let shouldReveal = self.sideMenuControlShouldRevealMenu?(self) {
            guard shouldReveal else {
                return false
            }
        }

        if isViewControllerInsideNavigationStack(for: touch.view) {
            return false
        }

        if touch.view is UISlider {
            return false
        }

        // If the view is scrollable in horizon direction, don't receive the touch
        if let scrollView = touch.view as? UIScrollView, scrollView.frame.width > scrollView.contentSize.width {
            return false
        }

        return true
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let velocity = panGestureRecognizer?.velocity(in: view) {
            return isValidateHorizontalMovement(for: velocity)
        }
        return true
    }

    private func isViewControllerInsideNavigationStack(for view: UIView?) -> Bool {
        guard let view = view,
            let viewController = view.parentViewController else {
                return false
        }
        
        if let navigationController = viewController as? UINavigationController {
            return navigationController.viewControllers.count > 1
        } else if let navigationController = viewController.navigationController {
            if let index = navigationController.viewControllers.firstIndex(of: viewController) {
                return index > 0
            }
        } else {
            var parent = viewController.parent
            while parent != nil {
                guard let navigationController = parent as? UINavigationController else {
                    parent = parent?.parent
                    continue
                }
                return navigationController.viewControllers.count > 0
            }
        }
        return false
    }

    private func isValidateHorizontalMovement(for velocity: CGPoint) -> Bool {
        if isMenuRevealed {
            return true
        }

        let direction = preferences.basic.direction
        var factor: CGFloat = direction == .left ? 1 : -1
        factor *= shouldReverseDirection ? -1 : 1
        guard velocity.x * factor > 0 else {
            return false
        }
        return abs(velocity.y / velocity.x) < preferences.basic.panGestureSensitivity
    }
}

extension PTSideMenuControl {
    class TransitionContext: NSObject, UIViewControllerContextTransitioning {
        var isAnimated = true
        var targetTransform: CGAffineTransform = .identity

        let containerView: UIView
        let presentationStyle: UIModalPresentationStyle

        private var viewControllers = [UITransitionContextViewControllerKey: UIViewController]()

        var isInteractive = false

        var transitionWasCancelled: Bool {
            return false
        }

        var completion: PTBoolTask?

        init(with fromViewController: UIViewController, toViewController: UIViewController) {
            guard let superView = fromViewController.view.superview else {
                fatalError("fromViewController's view should have a parent view")
            }
            presentationStyle = .custom
            containerView = superView
            viewControllers = [
                .from: fromViewController,
                .to: toViewController
            ]

            super.init()
        }

        func completeTransition(_ didComplete: Bool) {
            completion?(didComplete)
        }

        func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
            return viewControllers[key]
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

        // swiftlint:disable identifier_name
        func initialFrame(for vc: UIViewController) -> CGRect {
            return containerView.frame
        }

        func finalFrame(for vc: UIViewController) -> CGRect {
            return containerView.frame
        }

        // MARK: Interactive, not supported yet
        func updateInteractiveTransition(_ percentComplete: CGFloat) {}
        func finishInteractiveTransition() {}
        func cancelInteractiveTransition() {}
        func pauseInteractiveTransition() {}
    }
}

extension PTSideMenuControl {
    /// 选项
    public struct PTSideMenuPreferences {

        /// Menu出现方向
        public enum MenuDirection {
            /// 从左到右
            case left
            /// 从右到左
            case right
        }

        /// Menu出现的位置
        public enum MenuPosition {
            /// 在当前ViewController上面
            case above
            /// 在当前ViewController下面
            case under
            /// 与当前的ViewController相连
            case sideBySide
        }

        public struct PTSideMenuAnimation {
            /// 出现的动画时间,默认`0.4`
            public var revealDuration: TimeInterval = 0.4

            /// 小时的动画时间,默认`0.4`
            public var hideDuration: TimeInterval = 0.4

            /// 动画. 默认 ``.curveEaseInOut``.
            public var options: UIView.AnimationOptions = .curveEaseInOut

            /// 放大比例选项用于菜单的显示和隐藏动画. 默认 `1`.
            public var dampingRatio: CGFloat = 1

            ///`initialSpringVelocit`(弹簧力度)选项用于显示和隐藏菜单的动画 . 默认 `1`.
            public var initialSpringVelocity: CGFloat = 1

            /// 显示菜单时是否应该在内容视图上添加阴影效果。默认为true
            /// 如果Config的`position`是`.under`,即使该值设置为`true`，阴影效果也不会被添加
            public var shouldAddShadowWhenRevealing = true

            /// 在Content上的阴影值. 默认 `0.2`.
            public var shadowAlpha: CGFloat = 0.2

            /// 阴影颜色. 默认 `black`.
            public var shadowColor: UIColor = .black

            /// 是否开启毛玻璃效果.默认 `false`
            public var shouldAddBlurWhenRevealing = false
        }

        public struct PTSideMentConfiguration {
            /// Side的Width. 默认 `300`.
            /// 需要在SideMenu初始化之前调用
            public var menuWidth: CGFloat = 300

            /// 展示位置. 默认 `.above`.
            /// 需要在SideMenu初始化之前调用
            public var position: MenuPosition = .above

            /// 当用户交互布局方向为RTL时，侧菜单方向是否需要反转。
            /// 更具体地说，当应用程序使用从右向左(RTL)语言时，侧边菜单的方向将会颠倒
            public var shouldRespectLanguageDirection = true
          
            /// 侧菜单的方向是否要强行反转到RTL。如果我们在运行时更改应用程序语言，走runtime方法。
            /// 侧边菜单的方向会被强行反转。默认为 `false`。
            public var forceRightToLeft = false

            /// 展示方向.默认 `.left`.
            /// 需要在SideMenu初始化之前调用
            public var direction: MenuDirection = .left

            /// 开启触发手势 `.left`.
            public var enablePanGesture = true

            /// 如果启用，当到达边界时，菜单视图将像橡皮筋一样起作用.默认为`true`.
            public var enableRubberEffectWhenPanning = true

            /// 如果启用，当应用程序进入后台时菜单视图将被隐藏.默认为`false`.
            public var hideMenuWhenEnteringBackground = false

            /// 第一个内容视图控制器的缓存键。
            public var defaultCacheKey: String?

            /// 侧边菜单应该使用内容支持的方向.默认为`false`.
            public var shouldUseContentSupportedOrientations: Bool = false

            /// 侧边菜单控制器支持的方向.默认为`. allbutupsidedown`.
            public var supportedOrientations: UIInterfaceOrientationMask = .allButUpsideDown
            
            /// 是否支持旋转. 默认`true`.
            public var shouldAutorotate: Bool = true
            
            /// 平移手势识别器显示菜单视图控制器的灵敏度.默认`0.25`
            public var panGestureSensitivity: CGFloat = 0.25

            /// 如果旁边的菜单应该保持打开旋转.默认为`false`.
            public var keepsMenuOpenAfterRotation: Bool = false
        }

        /// 配置
        public var basic = PTSideMentConfiguration()

        /// 动画配置
        public var animation = PTSideMenuAnimation()
    }
}
