//
//  PTSheetViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/5.
//  Copyright © 2024 crazypoo. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
import CoreGraphics
import SnapKit

public enum PTSheetSize: Equatable, Sendable {
    case intrinsic
    case fixed(CGFloat)
    case fullscreen
    case percent(Float)
    case marginFromTop(CGFloat)
}

@MainActor
public class PTSheetViewController: PTBaseViewController {

    public private(set) var options: PTSheetOptions
    
    /// 键盘出现时自动调整面板高度，默认开启。
    public static var autoAdjustToKeyboard = true
    /// 是否自动调整面板以避开键盘，默认开启。
    public var autoAdjustToKeyboard = PTSheetViewController.autoAdjustToKeyboard
    
    /// Default value for allowPullingPastMaxHeight. Defaults to true.
    public static var allowPullingPastMaxHeight = true
    /// Allow pulling past the maximum height and bounce back. Defaults to true.
    public var allowPullingPastMaxHeight = PTSheetViewController.allowPullingPastMaxHeight
    
    /// Default value for allowPullingPastMinHeight. Defaults to true.
    public static var allowPullingPastMinHeight = true
    /// Allow pulling below the minimum height and bounce back. Defaults to true.
    public var allowPullingPastMinHeight = PTSheetViewController.allowPullingPastMinHeight
    
    /// The sizes that the sheet will attempt to pin to. Defaults to intrinsic only.
    public var sizes: [PTSheetSize] = [.intrinsic] {
        didSet {
            if self.sizes.isEmpty || self.sizes.contains(where: self.isInvalidSize) {
                self.sizes = self.normalizedSizes(self.sizes)
                return
            }
            self.updateOrderedSizes()
        }
    }
    public var orderedSizes: [PTSheetSize] = []
    public private(set) var currentSize: PTSheetSize = .intrinsic
    
    /// Allows dismissing of the sheet by pulling down
    public var dismissOnPull: Bool = true {
        didSet { self.updateAccessibility() }
    }
    /// Dismisses the sheet by tapping on the background overlay
    public var dismissOnOverlayTap: Bool = true {
       didSet { self.updateAccessibility() }
   }
    /// If true you can pull using UIControls (so you can grab and drag a button to control the sheet)
    public var shouldRecognizePanGestureWithUIControls: Bool = true
    
    /// The view controller being presented by the sheet currently
    public var childViewController: UIViewController {
        return self.contentViewController.childViewController
    }

    public override var childForStatusBarStyle: UIViewController? {
        childViewController
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return childViewController.supportedInterfaceOrientations
    }
    
    public static var hasBlurBackground = false
    public var hasBlurBackground = PTSheetViewController.hasBlurBackground {
        didSet {
            blurView.isHidden = !hasBlurBackground
            overlayView.backgroundColor = hasBlurBackground ? .clear : self.overlayColor
        }
    }
    
    public static var minimumSpaceAbovePullBar: CGFloat = 0
    public var minimumSpaceAbovePullBar: CGFloat {
        didSet {
            if self.isViewLoaded {
                self.resize(to: self.currentSize)
            }
        }
    }
    
    /// The default color of the overlay background
    public static var overlayColor = UIColor(white: 0, alpha: 0.25)
    /// The color of the overlay background
    public var overlayColor = PTSheetViewController.overlayColor {
        didSet {
            self.overlayView.backgroundColor = self.hasBlurBackground ? .clear : self.overlayColor
        }
    }
    
    public static var blurEffect: UIBlurEffect = UIBlurEffect(style: .prominent)
    
    public var blurEffect = PTSheetViewController.blurEffect {
        didSet { self.blurView.effect = blurEffect }
    }
    
    public static var allowGestureThroughOverlay: Bool = false
    public var allowGestureThroughOverlay: Bool = PTSheetViewController.allowGestureThroughOverlay {
        didSet {
            self.overlayTapView.isUserInteractionEnabled = !self.allowGestureThroughOverlay
        }
    }
    
    public static var cornerRadius: CGFloat = 12
    public var cornerRadius: CGFloat {
        get { self.contentViewController.cornerRadius }
        set { self.contentViewController.cornerRadius = newValue }
    }

    public static var cornerCurve: CALayerCornerCurve = .circular
    public var cornerCurve: CALayerCornerCurve {
        get { self.contentViewController.cornerCurve }
        set { self.contentViewController.cornerCurve = newValue }
    }
    
    public static var gripSize: CGSize = CGSize(width: 50, height: 6)
    public var gripSize: CGSize {
        get { self.contentViewController.gripSize }
        set { self.contentViewController.gripSize = newValue }
    }
    
    public static var gripColor: UIColor = .lightGray
    public var gripColor: UIColor? {
        get { self.contentViewController.gripColor }
        set { self.contentViewController.gripColor = newValue }
    }
    
    public static var pullBarBackgroundColor: UIColor = UIColor.clear
    public var pullBarBackgroundColor: UIColor? {
        get { self.contentViewController.pullBarBackgroundColor }
        set { self.contentViewController.pullBarBackgroundColor = newValue }
    }
    
    public static var treatPullBarAsClear: Bool = false
    public var treatPullBarAsClear: Bool {
        get { self.contentViewController.treatPullBarAsClear }
        set { self.contentViewController.treatPullBarAsClear = newValue }
    }
    
    let transition: PTSheetTransition
    
    public var shouldDismiss: ((PTSheetViewController) -> Bool)?
    public var didDismiss: ((PTSheetViewController) -> Void)?
    public var sizeChanged: ((PTSheetViewController, PTSheetSize, CGFloat) -> Void)?
    public var panGestureShouldBegin: ((UIPanGestureRecognizer) -> Bool?)?
    
    public lazy var overlayControlView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        return view
    }()
    
    public private(set) var contentViewController: PTSheetContentViewController
    var overlayView = UIView()
    var blurView = UIVisualEffectView()
    var overlayTapView = UIView()
    var overflowView = UIView()
    var overlayTapGesture: UITapGestureRecognizer?
    
    /// The child view controller's scroll view we are watching so we can override the pull down/up to work on the sheet when needed
    private weak var childScrollView: UIScrollView?
    
    private var keyboardHeight: CGFloat = 0
    private var firstPanPoint: CGPoint = CGPoint.zero
    private var panGestureRecognizer: PTInitialTouchPanGestureRecognizer?
    private var pendingChildScrollView: UIScrollView?
    private var prePanHeight: CGFloat = 0
    private var isPanning: Bool = false
    private var isDismissing: Bool = false
    private var didNotifyDismissal: Bool = false
    private var lastLayoutBounds: CGRect = .zero
    private var lastLayoutSafeAreaInsets: UIEdgeInsets = .zero
    private var sheetHeightConstraint: Constraint?
    private var sheetTopConstraint: Constraint?
    private var currentHeight: CGFloat = 0
    private var originalAdditionalSafeAreaInsets: UIEdgeInsets = .zero
    
    public var contentBackgroundColor: UIColor? {
        get { self.contentViewController.contentBackgroundColor }
        set { self.contentViewController.contentBackgroundColor = newValue }
    }
    
    private var dismissPanGes: Bool = true
    
    // MARK: - Initialization
    
    public init(controller: UIViewController, sizes: [PTSheetSize] = [.intrinsic], options: PTSheetOptions? = nil, dismissPanGes: Bool = true) {
        let options = (options ?? PTSheetOptions.default).normalized()
        self.contentViewController = PTSheetContentViewController(childViewController: controller, options: options)
        self.contentViewController.contentBackgroundColor = nil
        self.sizes = sizes.count > 0 ? sizes : [.intrinsic]
        self.options = options
        self.transition = PTSheetTransition(options: options)
        self.minimumSpaceAbovePullBar = PTSheetViewController.minimumSpaceAbovePullBar
        super.init(nibName: nil, bundle: nil)
        self.originalAdditionalSafeAreaInsets = self.additionalSafeAreaInsets
        
        self.gripColor = PTSheetViewController.gripColor
        self.gripSize = PTSheetViewController.gripSize
        self.pullBarBackgroundColor = PTSheetViewController.pullBarBackgroundColor
        self.cornerRadius = PTSheetViewController.cornerRadius
        self.dismissPanGes = dismissPanGes
        self.sizes = self.normalizedSizes(self.sizes)
        self.updateOrderedSizes()
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
    }

    deinit {
        NotificationCenter.default.removeObserver(self,
                                                   name: UIResponder.keyboardWillChangeFrameNotification,
                                                   object: nil)
    }
    
    public required init?(coder: NSCoder) {
        // FloatPanel 只支持代码创建；从 storyboard 解码时安全返回失败，避免初始化阶段崩溃。
        return nil
    }
    
    // MARK: - Lifecycle
    
    public override func loadView() {
        if self.options.useInlineMode {
            let sheetView = PTSheetView()
            sheetView.sheetPointHandler = { [weak self] point, event in
                guard let self = self else { return true }
                let overlayPoint = self.overlayTapView.convert(point, from: self.view)
                let isInOverlay = self.overlayTapView.point(inside: overlayPoint, with: event)
                let controlPoint = self.overlayControlView.convert(point, from: self.view)
                let hitsOverlayControl = self.overlayControlView.isHidden == false
                    && self.overlayControlView.alpha > 0.01
                    && self.overlayControlView.bounds.contains(controlPoint)
                    && self.overlayControlView.subviews.contains { subview in
                        !subview.isHidden && subview.alpha > 0.01 && subview.frame.contains(controlPoint)
                    }
                if self.allowGestureThroughOverlay, isInOverlay, !hitsOverlayControl {
                    return false
                }
                return true
            }
            self.view = sheetView
        } else {
            super.loadView()
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        var additionalSafeAreaInsets = self.originalAdditionalSafeAreaInsets
        additionalSafeAreaInsets.top -= self.options.pullBarHeight
        self.additionalSafeAreaInsets = additionalSafeAreaInsets
        self.view.backgroundColor = UIColor.clear
        self.view.accessibilityViewIsModal = !self.options.useInlineMode
        
        if self.dismissPanGes {
            self.addPanGestureRecognizer()
        }
        
        self.addOverlay()
        self.addBlurBackground()
        self.addContentView()
        self.addOverlayTapView()
        self.registerKeyboardObservers()
        self.resize(to: self.sizes.first ?? .intrinsic, animated: false)
        self.connectPendingScrollViewIfNeeded()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.didNotifyDismissal = false
        self.isDismissing = false
        self.updateOrderedSizes()
        self.contentViewController.updatePreferredHeight()
        self.resize(to: self.currentSize, animated: false)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.invalidateLayoutIfNeeded()
    }

    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        self.invalidateLayoutIfNeeded()
    }
    
    // MARK: - Setup & Configuration
    
    public func handleScrollView(_ scrollView: UIScrollView) {
        self.childScrollView = scrollView
        self.pendingChildScrollView = scrollView
        self.connectPendingScrollViewIfNeeded()
    }
    
    public func setSizes(_ sizes: [PTSheetSize], animated: Bool = true) {
        guard sizes.count > 0 else { return }
        self.sizes = sizes
        self.resize(to: self.sizes[0], animated: animated)
    }

    private func isInvalidSize(_ size: PTSheetSize) -> Bool {
        switch size {
        case .intrinsic, .fullscreen:
            return false
        case .fixed(let value), .marginFromTop(let value):
            return !value.isFinite || value < 0
        case .percent(let value):
            return !value.isFinite || value < 0 || value > 1
        }
    }

    private func normalized(_ size: PTSheetSize) -> PTSheetSize {
        switch size {
        case .intrinsic, .fullscreen:
            return size
        case .fixed(let value):
            return .fixed(value.isFinite ? max(0, value) : 0)
        case .percent(let value):
            return .percent(value.isFinite ? min(max(value, 0), 1) : 0)
        case .marginFromTop(let value):
            return .marginFromTop(value.isFinite ? max(0, value) : 0)
        }
    }

    private func normalizedSizes(_ sizes: [PTSheetSize]) -> [PTSheetSize] {
        let normalizedSizes = sizes.map(self.normalized)
        return normalizedSizes.isEmpty ? [.intrinsic] : normalizedSizes
    }

    func updateOrderedSizes() {
        let concreteSizes: [(PTSheetSize, CGFloat)] = self.sizes.compactMap { size in
            let height = self.height(for: size)
            return height.isFinite ? (size, height) : nil
        }
        let sortedSizes = concreteSizes.sorted { $0.1 < $1.1 }
        var uniqueSizes: [PTSheetSize] = []
        var lastHeight: CGFloat?
        let tolerance = self.layoutPixelTolerance
        for (size, height) in sortedSizes {
            if let lastHeight, abs(lastHeight - height) < tolerance {
                continue
            }
            uniqueSizes.append(size)
            lastHeight = height
        }
        self.orderedSizes = uniqueSizes.isEmpty ? [.intrinsic] : uniqueSizes
        self.updateAccessibility()
    }
    
    private func updateAccessibility() {
        let isOverlayAccessable = !self.allowGestureThroughOverlay && (self.dismissOnOverlayTap || self.dismissOnPull)
        self.overlayTapView.isAccessibilityElement = isOverlayAccessable
        
        var pullBarLabel = ""
        if !isOverlayAccessable && (self.dismissOnOverlayTap || self.dismissOnPull) {
            pullBarLabel = "PT Sheet dismiss".localized()
        } else if self.orderedSizes.count > 1 {
            pullBarLabel = "PT Sheet change size".localized()
        }
        
        self.contentViewController.pullBarView.isAccessibilityElement = !pullBarLabel.isEmpty
        self.contentViewController.pullBarView.accessibilityLabel = pullBarLabel
        self.contentViewController.pullBarView.accessibilityValue = self.orderedSizes.count > 1
            ? "\((self.orderedSizes.firstIndex(of: self.currentSize) ?? 0) + 1)/\(self.orderedSizes.count)"
            : nil
        self.overlayTapView.accessibilityLabel = "PT Sheet dismiss".localized()
    }

    private var topInset: CGFloat {
        guard self.options.useFullScreenMode == false else { return 0 }
        let safeAreaTop = self.viewIfLoaded?.safeAreaInsets.top ?? 0
        return max(12, safeAreaTop)
    }

    private var layoutPixelTolerance: CGFloat {
        let scale = max(self.viewIfLoaded?.window?.screen.scale ?? self.traitCollection.displayScale, 1)
        return 1 / scale
    }

    private func invalidateLayoutIfNeeded() {
        guard self.isViewLoaded, self.view.bounds.width > 0, self.view.bounds.height > 0 else { return }
        let bounds = self.view.bounds
        let safeAreaInsets = self.view.safeAreaInsets
        guard bounds != self.lastLayoutBounds || safeAreaInsets != self.lastLayoutSafeAreaInsets else { return }

        self.lastLayoutBounds = bounds
        self.lastLayoutSafeAreaInsets = safeAreaInsets
        self.sheetTopConstraint?.update(inset: self.topInset)
        self.contentViewController.updatePreferredHeight()
        self.updateOrderedSizes()
        self.resize(to: self.currentSize, animated: false)
    }

    private func connectPendingScrollViewIfNeeded() {
        guard let scrollView = self.pendingChildScrollView,
              let panGestureRecognizer = self.panGestureRecognizer else { return }
        scrollView.panGestureRecognizer.require(toFail: panGestureRecognizer)
        self.pendingChildScrollView = nil
    }

    private func applyPanVisualState(height: CGFloat, offset: CGFloat) {
        self.currentHeight = height
        self.sheetHeightConstraint?.update(offset: height)
        if offset > 0 {
            let percent = min(max(offset / max(1, height), 0), 1)
            self.transition.setPresenter(percentComplete: percent)
            self.overlayView.alpha = 1 - percent
            self.overlayControlView.alpha = 1 - percent
            self.contentViewController.view.transform = CGAffineTransform(translationX: 0, y: offset)
        } else {
            self.transition.setPresenter(percentComplete: 0)
            self.overlayView.alpha = 1
            self.overlayControlView.alpha = 1
            self.contentViewController.view.transform = .identity
        }
        self.view.layoutIfNeeded()
    }

    private func restoreAfterPan() {
        guard self.isViewLoaded else {
            self.isPanning = false
            return
        }
        self.isPanning = false
        let targetHeight = self.height(for: self.currentSize)
        self.currentHeight = targetHeight
        UIView.animate(withDuration: self.normalizedAnimationDuration(0.2), delay: 0, options: [.curveEaseOut]) {
            self.contentViewController.view.transform = .identity
            self.sheetHeightConstraint?.update(offset: targetHeight)
            self.transition.setPresenter(percentComplete: 0)
            self.overlayView.alpha = 1
            self.overlayControlView.alpha = 1
            self.view.layoutIfNeeded()
        }
    }

    private func nearestSize(to height: CGFloat, movingUp: Bool) -> PTSheetSize {
        let candidates = self.orderedSizes.isEmpty ? [.intrinsic] : self.orderedSizes
        let targetHeight = min(max(0, height), self.height(for: .fullscreen))
        var result = candidates[0]
        var resultHeight = self.height(for: result)
        var resultDistance = abs(resultHeight - targetHeight)

        for candidate in candidates.dropFirst() {
            let candidateHeight = self.height(for: candidate)
            let distance = abs(candidateHeight - targetHeight)
            let isCloser = distance < resultDistance - self.layoutPixelTolerance
            let isTieInDirection = abs(distance - resultDistance) < self.layoutPixelTolerance
                && ((movingUp && candidateHeight > resultHeight) || (!movingUp && candidateHeight < resultHeight))
            if isCloser || isTieInDirection {
                result = candidate
                resultHeight = candidateHeight
                resultDistance = distance
            }
        }
        return result
    }

    private func panAnimationDuration(for velocity: CGFloat) -> TimeInterval {
        let speedFactor = min(abs(velocity) / 3000, 0.25)
        return self.normalizedAnimationDuration(0.2 + TimeInterval(speedFactor))
    }

    private func normalizedAnimationDuration(_ duration: TimeInterval) -> TimeInterval {
        guard duration.isFinite else { return 0.2 }
        let safeDuration = max(0, duration)
        if UIAccessibility.isReduceMotionEnabled {
            return min(safeDuration, 0.15)
        }
        return min(max(safeDuration, 0.01), 2)
    }
    
    private func addOverlay() {
        self.view.addSubview(self.overlayView)
        self.overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.overlayView.isUserInteractionEnabled = false
        self.overlayView.backgroundColor = self.hasBlurBackground ? .clear : self.overlayColor
    }
    
    private func addBlurBackground() {
        self.overlayView.addSubview(self.blurView)
        blurView.effect = blurEffect
        self.blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.blurView.isUserInteractionEnabled = false
        self.blurView.isHidden = !self.hasBlurBackground
    }
    
    private func addOverlayTapView() {
        let overlayTapView = self.overlayTapView
        overlayTapView.backgroundColor = .clear
        overlayTapView.isUserInteractionEnabled = !self.allowGestureThroughOverlay
        self.view.addSubview(overlayTapView)
        self.overlayTapView.accessibilityLabel = "PT Sheet dismiss".localized()
        
        overlayTapView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(self.contentViewController.view.snp.top)
        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(overlayTapped))
        self.overlayTapGesture = tapGestureRecognizer
        overlayTapView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func overlayTapped(_ gesture: UITapGestureRecognizer) {
        guard self.dismissOnOverlayTap else { return }
        self.attemptDismiss(animated: true)
    }

    private func addContentView() {
        self.addChild(self.contentViewController)
        self.view.addSubview(self.contentViewController.view)
        self.contentViewController.didMove(toParent: self)

        self.contentViewController.sheetContentViewPreferredHeightChanged = { [weak self] _, _ in
            guard let self = self else { return }
            if self.sizes.contains(.intrinsic) {
                self.updateOrderedSizes()
            }
            if self.currentSize == .intrinsic, !self.isPanning {
                self.resize(to: .intrinsic)
            }
        }
        
        self.contentViewController.pullBarTappedAction = { [weak self] in
            guard let self = self else { return }
            PTGCDManager.shared.runOnMain {
                guard UIAccessibility.isVoiceOverRunning else { return }
                let shouldDismiss = self.allowGestureThroughOverlay && (self.dismissOnOverlayTap || self.dismissOnPull)
                guard !shouldDismiss else {
                    self.attemptDismiss(animated: true)
                    return
                }

                if self.sizes.count > 1 {
                    let index = (self.sizes.firstIndex(of: self.currentSize) ?? 0) + 1
                    if index >= self.sizes.count {
                        self.resize(to: self.sizes[0])
                    } else {
                        self.resize(to: self.sizes[index])
                    }
                }
            }
        }
        
        self.contentViewController.view.snp.makeConstraints { make in
            make.left.equalToSuperview().priority(999)
            make.left.greaterThanOrEqualToSuperview().inset(self.options.horizontalPadding)
            if let maxWidth = self.options.maxWidth {
                make.width.lessThanOrEqualTo(maxWidth)
            }
            make.centerX.equalToSuperview()
            self.sheetHeightConstraint = make.height.equalTo(self.height(for: self.currentSize)).constraint
            
            let top = self.topInset
            make.bottom.equalToSuperview()
            self.sheetTopConstraint = make.top.greaterThanOrEqualToSuperview().inset(top).priority(999).constraint
        }
        
        self.view.addSubview(overlayControlView)
        overlayControlView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(self.contentViewController.view.snp.top)
        }
    }
    
    // MARK: - Gestures & Panning
    
    private func addPanGestureRecognizer() {
        let panGestureRecognizer = PTInitialTouchPanGestureRecognizer(target: self, action: #selector(panned(_:)))
        self.view.addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.delegate = self
        self.panGestureRecognizer = panGestureRecognizer
        self.connectPendingScrollViewIfNeeded()
    }
    
    @objc func panned(_ gesture: UIPanGestureRecognizer) {
        guard let gestureView = gesture.view else { return }
        let point = gesture.translation(in: gestureView.superview ?? gestureView)

        switch gesture.state {
        case .began:
            guard !self.isDismissing else { return }
            self.firstPanPoint = point
            self.prePanHeight = self.contentViewController.view.bounds.height
            self.isPanning = true

        case .changed, .ended:
            guard self.isPanning else { return }

        case .cancelled, .failed:
            self.restoreAfterPan()
            return

        case .possible:
            return

        @unknown default:
            self.restoreAfterPan()
            return
        }

        let minHeight = self.height(for: self.orderedSizes.first)
        let fullscreenHeight = self.height(for: .fullscreen)
        let maxHeight = self.allowPullingPastMaxHeight
            ? fullscreenHeight
            : max(self.height(for: self.orderedSizes.last), self.prePanHeight)

        var newHeight = max(0, self.prePanHeight + (self.firstPanPoint.y - point.y))
        var offset: CGFloat = 0

        if newHeight < minHeight {
            if self.allowPullingPastMinHeight {
                offset = minHeight - newHeight
            }
            newHeight = minHeight
        }

        if newHeight > maxHeight {
            if self.options.isRubberBandEnabled, maxHeight > 0 {
                newHeight = self.logConstraintValueForYPosition(verticalLimit: maxHeight, yPosition: newHeight)
            } else {
                newHeight = maxHeight
            }
        }

        self.applyPanVisualState(height: newHeight, offset: offset)

        guard gesture.state == .ended else { return }

        let rawVelocity = gesture.velocity(in: self.view).y
        let projectedHeight = newHeight - offset - (rawVelocity * 0.2)
        self.isPanning = false

        if self.dismissOnPull,
           (rawVelocity > self.options.pullDismissThreshold || projectedHeight <= 0) {
            self.attemptDismiss(animated: true)
            return
        }

        let targetSize = self.nearestSize(to: projectedHeight, movingUp: rawVelocity < 0)
        let targetHeight = self.height(for: targetSize)
        let animationDuration = self.panAnimationDuration(for: rawVelocity)
        let previousSize = self.currentSize
        self.currentSize = targetSize
        self.currentHeight = targetHeight

        UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            usingSpringWithDamping: self.options.transitionDampening,
            initialSpringVelocity: self.options.transitionVelocity,
            options: self.options.transitionAnimationOptions,
            animations: {
                self.contentViewController.view.transform = .identity
                self.sheetHeightConstraint?.update(offset: targetHeight)
                self.transition.setPresenter(percentComplete: 0)
                self.overlayView.alpha = 1
                self.overlayControlView.alpha = 1
                self.view.layoutIfNeeded()
            },
            completion: { _ in
                if previousSize != targetSize {
                    self.sizeChanged?(self, targetSize, targetHeight)
                }
                UIAccessibility.post(notification: .layoutChanged, argument: self.contentViewController.view)
            }
        )
    }

    // MARK: - Keyboard Handling
    
    private func registerKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardShown(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @objc func keyboardShown(_ notification: Notification) {
        guard let info = notification.userInfo, let keyboardRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        guard self.autoAdjustToKeyboard, self.view.window != nil else { return }
        let keyboardFrame = self.view.convert(keyboardRect, from: nil)
        let visibleIntersection = self.view.bounds.intersection(keyboardFrame)
        let isDockedToBottom = visibleIntersection.height > 0
            && visibleIntersection.width >= self.view.bounds.width * 0.5
            && keyboardFrame.maxY >= self.view.bounds.maxY - 1
        let actualHeight = isDockedToBottom ? max(0, self.view.bounds.maxY - keyboardFrame.minY) : 0
        self.adjustForKeyboard(height: actualHeight, from: notification)
    }
    
    private func adjustForKeyboard(height: CGFloat, from notification: Notification) {
        guard self.autoAdjustToKeyboard, let info = notification.userInfo else { return }
        self.keyboardHeight = height
        
        let duration = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let animationCurveRaw = (info[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? 0
        let animationCurve = UIView.AnimationOptions(rawValue: animationCurveRaw << 16)
        
        self.contentViewController.adjustForKeyboard(height: self.keyboardHeight)
        self.resize(to: self.currentSize, duration: duration, options: animationCurve, animated: true)
    }
    
    // MARK: - Helpers & Utilities
    
    private func height(for size: PTSheetSize?) -> CGFloat {
        guard let size = size else { return 0 }
        let bounds = self.viewIfLoaded?.bounds ?? .zero
        let safeAreaInsets = self.viewIfLoaded?.safeAreaInsets ?? .zero
        let fullscreenHeight = max(
            0,
            bounds.height
                - (self.options.useFullScreenMode ? 0 : safeAreaInsets.top)
                - max(0, self.minimumSpaceAbovePullBar)
        )
        let keyboardHeight = min(max(0, self.keyboardHeight), fullscreenHeight)
        let contentHeight: CGFloat

        switch size {
        case .fixed(let height):
            let baseHeight = height.isFinite ? max(0, height) : 0
            contentHeight = baseHeight + keyboardHeight
        case .fullscreen:
            contentHeight = fullscreenHeight
        case .intrinsic:
            contentHeight = max(0, self.contentViewController.preferredHeight) + keyboardHeight
        case .percent(let percent):
            let normalizedPercent = percent.isFinite ? min(max(percent, 0), 1) : 0
            contentHeight = fullscreenHeight * CGFloat(normalizedPercent) + keyboardHeight
        case .marginFromTop(let margin):
            let normalizedMargin = margin.isFinite ? max(0, margin) : 0
            contentHeight = fullscreenHeight - normalizedMargin + keyboardHeight
        }
        return min(fullscreenHeight, max(0, contentHeight))
    }

    private func logConstraintValueForYPosition(verticalLimit: CGFloat, yPosition: CGFloat) -> CGFloat {
        guard verticalLimit > 0, yPosition.isFinite, yPosition > verticalLimit else { return verticalLimit }
        let value = verticalLimit * (1 + log10(yPosition / verticalLimit))
        return value.isFinite ? max(verticalLimit, value) : verticalLimit
    }
    
    public func resize(to size: PTSheetSize, duration: TimeInterval = 0.2, options: UIView.AnimationOptions = [.curveEaseOut], animated: Bool = true, complete: PTActionTask? = nil) {
        let targetSize = self.normalized(size)
        let previousSize = self.currentSize
        self.currentSize = targetSize
        let newHeight = self.height(for: targetSize)
        let oldHeight = self.currentHeight
        self.currentHeight = newHeight

        guard abs(oldHeight - newHeight) >= self.layoutPixelTolerance else {
            if previousSize != targetSize {
                self.sizeChanged?(self, targetSize, newHeight)
            }
            complete?()
            return
        }

        let updateHeight = {
            self.sheetHeightConstraint?.update(offset: newHeight)
            self.view.layoutIfNeeded()
        }

        if animated, duration > 0 {
            let safeDuration = self.normalizedAnimationDuration(duration)
            UIView.animate(withDuration: safeDuration, delay: 0, options: options, animations: {
                updateHeight()
            }, completion: { [weak self] _ in
                guard let self = self else { return }
                if previousSize != targetSize {
                    self.sizeChanged?(self, targetSize, newHeight)
                }
                self.contentViewController.updateAfterLayout()
                complete?()
                UIAccessibility.post(notification: .layoutChanged, argument: self.contentViewController.view)
            })
        } else {
            UIView.performWithoutAnimation {
                updateHeight()
            }
            if previousSize != targetSize {
                self.sizeChanged?(self, targetSize, newHeight)
            }
            self.contentViewController.updateAfterLayout()
            complete?()
        }
    }
    
    public func attemptDismiss(animated: Bool) {
        guard !self.isDismissing else { return }
        guard self.shouldDismiss?(self) != false else {
            self.restoreAfterPan()
            return
        }

        self.isDismissing = true
        self.isPanning = false
        if self.options.useInlineMode {
            if animated {
                self.animateOut(duration: self.normalizedAnimationDuration(0.3))
            } else {
                self.removeInlineSheet()
                self.notifyDismissed()
            }
        } else {
            self.dismiss(animated: animated) { [weak self] in
                guard let self = self else { return }
                self.finishDismissal(completed: self.presentingViewController == nil)
            }
        }
    }
    
    public func updateIntrinsicHeight() {
        contentViewController.updatePreferredHeight()
    }

    func transitionDidFinishDismissal(completed: Bool) {
        self.finishDismissal(completed: completed)
    }

    private func finishDismissal(completed: Bool) {
        guard completed else {
            self.isDismissing = false
            self.restoreAfterPan()
            return
        }
        self.isDismissing = false
        self.notifyDismissed()
    }

    private func notifyDismissed() {
        guard !self.didNotifyDismissal else { return }
        self.didNotifyDismissal = true
        self.didDismiss?(self)
    }

    private func removeInlineSheet() {
        if self.parent != nil {
            self.willMove(toParent: nil)
        }
        self.view.removeFromSuperview()
        if self.parent != nil {
            self.removeFromParent()
        }
    }
    
    public func animateIn(to view: UIView, in parent: UIViewController, size: PTSheetSize? = nil, duration: TimeInterval = 0.3, completion: PTActionTask? = nil) {
        self.didNotifyDismissal = false
        self.isDismissing = false
        parent.addChild(self)
        view.addSubview(self.view)
        self.didMove(toParent: parent)
        
        self.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.animateIn(size: size, duration: duration, completion: completion)
    }
    
    public func animateIn(size: PTSheetSize? = nil, duration: TimeInterval = 0.3, completion: PTActionTask? = nil) {
        guard self.options.useInlineMode else { return }
        guard self.view.superview != nil else {
            print("Error: It appears your sheet is not set as a subview of another view.")
            return
        }
        
        self.didNotifyDismissal = false
        self.isDismissing = false
        self.view.superview?.layoutIfNeeded()
        self.contentViewController.updatePreferredHeight()
        self.resize(to: size ?? self.sizes.first ?? self.currentSize, animated: false)
        let contentView = self.contentViewController.view
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        contentView?.transform = reduceMotion ? .identity : CGAffineTransform(translationX: 0, y: contentView?.bounds.height ?? 0)
        contentView?.alpha = reduceMotion ? 0 : 1
        self.overlayView.alpha = 0
        self.updateOrderedSizes()
        
        UIView.animate(withDuration: self.normalizedAnimationDuration(duration), animations: {
            contentView?.transform = .identity
            contentView?.alpha = 1
            self.overlayView.alpha = 1
            self.overlayControlView.alpha = 1
        }, completion: { _ in
            completion?()
        })
    }
    
    public func animateOut(duration: TimeInterval = 0.3, completion: PTActionTask? = nil) {
        guard self.options.useInlineMode else { return }
        guard self.contentViewController.isViewLoaded else {
            self.removeInlineSheet()
            self.notifyDismissed()
            completion?()
            return
        }
        let contentView = self.contentViewController.view
        
        UIView.animate(withDuration: self.normalizedAnimationDuration(duration), delay: 0, usingSpringWithDamping: self.options.transitionDampening, initialSpringVelocity: self.options.transitionVelocity, options: self.options.transitionAnimationOptions, animations: {
            if UIAccessibility.isReduceMotionEnabled {
                contentView?.alpha = 0
            } else {
                contentView?.transform = CGAffineTransform(translationX: 0, y: contentView?.bounds.height ?? 0)
            }
            self.overlayView.alpha = 0
            self.overlayControlView.alpha = 0
        }, completion: { _ in
            self.removeInlineSheet()
            self.notifyDismissed()
            completion?()
        })
    }
}

// MARK: - UIGestureRecognizerDelegate
extension PTSheetViewController {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if !shouldRecognizePanGestureWithUIControls {
            if let view = touch.view {
                return !(view is UIControl)
            }
        }
        return true
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGestureRecognizer = gestureRecognizer as? PTInitialTouchPanGestureRecognizer else { return true }

        if let closure = self.panGestureShouldBegin, let should = closure(panGestureRecognizer) {
            return should
        }

        let velocity = panGestureRecognizer.velocity(in: panGestureRecognizer.view?.superview)
        guard abs(velocity.y) >= abs(velocity.x) else { return false }
        guard let childScrollView = self.childScrollView,
              let point = panGestureRecognizer.initialTouchLocation else { return true }

        let pointInChildScrollView = self.view.convert(point, to: childScrollView).y - childScrollView.contentOffset.y

        guard pointInChildScrollView > 0, pointInChildScrollView < childScrollView.bounds.height else {
            if self.keyboardHeight > 0 {
                childScrollView.endEditing(true)
            }
            return true
        }
        
        let topInset = childScrollView.contentInset.top
        guard abs(velocity.y) > abs(velocity.x), childScrollView.contentOffset.y <= -topInset else { return false }
        
        if velocity.y < 0 {
            let containerHeight = height(for: self.currentSize)
            return height(for: self.orderedSizes.last) > containerHeight && containerHeight < height(for: PTSheetSize.fullscreen)
        } else {
            return true
        }
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension PTSheetViewController: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.presenting = true
        return transition
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.presenting = false
        return transition
    }
}
#endif // os(iOS) || os(tvOS) || os(watchOS)
