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

public enum PTSheetSize: Equatable {
    case intrinsic
    case fixed(CGFloat)
    case fullscreen
    case percent(Float)
    case marginFromTop(CGFloat)
}

public class PTSheetViewController: PTBaseViewController {

    public private(set) var options: PTSheetOptions
    
    /// Default value for autoAdjustToKeyboard. Defaults to true.
    public static var autoAdjustToKeyboard = true
    /// Automatically grow/move the sheet to accommodate the keyboard. Defaults to false.
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
        didSet { self.updateOrderedSizes() }
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
    private var panOffset: CGFloat = 0
    private var panGestureRecognizer: PTInitialTouchPanGestureRecognizer!
    private var prePanHeight: CGFloat = 0
    private var isPanning: Bool = false
    
    public var contentBackgroundColor: UIColor? {
        get { self.contentViewController.contentBackgroundColor }
        set { self.contentViewController.contentBackgroundColor = newValue }
    }
    
    private var dismissPanGes: Bool = true
    
    // MARK: - Initialization
    
    public init(controller: UIViewController, sizes: [PTSheetSize] = [.intrinsic], options: PTSheetOptions? = nil, dismissPanGes: Bool = true) {
        let options = options ?? PTSheetOptions.default
        self.contentViewController = PTSheetContentViewController(childViewController: controller, options: options)
        self.contentViewController.contentBackgroundColor = UIColor.systemBackground
        self.sizes = sizes.count > 0 ? sizes : [.intrinsic]
        self.options = options
        self.transition = PTSheetTransition(options: options)
        self.minimumSpaceAbovePullBar = PTSheetViewController.minimumSpaceAbovePullBar
        super.init(nibName: nil, bundle: nil)
        
        self.gripColor = PTSheetViewController.gripColor
        self.gripSize = PTSheetViewController.gripSize
        self.pullBarBackgroundColor = PTSheetViewController.pullBarBackgroundColor
        self.cornerRadius = PTSheetViewController.cornerRadius
        self.dismissPanGes = dismissPanGes
        self.updateOrderedSizes()
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func loadView() {
        if self.options.useInlineMode {
            let sheetView = PTSheetView()
            // [优化] 引入 weak self 避免内存泄漏
            sheetView.sheetPointHandler = { [weak self] point, event in
                guard let self = self else { return true }
                let isInOverlay = self.overlayTapView.bounds.contains(point)
                if self.allowGestureThroughOverlay, isInOverlay {
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
        
        self.compatibleAdditionalSafeAreaInsets = UIEdgeInsets(top: -self.options.pullBarHeight, left: 0, bottom: 0, right: 0)
        self.view.backgroundColor = UIColor.clear
        
        if self.dismissPanGes {
            self.addPanGestureRecognizer()
        }
        
        self.addOverlay()
        self.addBlurBackground()
        self.addContentView()
        self.addOverlayTapView()
        self.registerKeyboardObservers()
        self.resize(to: self.sizes.first ?? .intrinsic, animated: false)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        self.updateOrderedSizes()
        self.contentViewController.updatePreferredHeight()
        self.resize(to: self.currentSize, animated: false)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let presenter = self.transition.presenter, self.options.shrinkPresentingViewController {
            self.transition.restorePresenter(presenter, completion: { [weak self] _ in
                guard let self = self else { return }
                self.didDismiss?(self)
            })
        } else if !self.options.useInlineMode {
            self.didDismiss?(self)
        }
    }
    
    // MARK: - Setup & Configuration
    
    public func handleScrollView(_ scrollView: UIScrollView) {
        scrollView.panGestureRecognizer.require(toFail: panGestureRecognizer)
        self.childScrollView = scrollView
    }
    
    public func setSizes(_ sizes: [PTSheetSize], animated: Bool = true) {
        guard sizes.count > 0 else { return }
        self.sizes = sizes
        self.resize(to: sizes[0], animated: animated)
    }
    
    func updateOrderedSizes() {
        var concreteSizes: [(PTSheetSize, CGFloat)] = self.sizes.map { ($0, self.height(for: $0)) }
        concreteSizes.sort { $0.1 < $1.1 }
        self.orderedSizes = concreteSizes.map { $0.0 }
        self.updateAccessibility()
    }
    
    private func updateAccessibility() {
        let isOverlayAccessable = !self.allowGestureThroughOverlay && (self.dismissOnOverlayTap || self.dismissOnPull)
        self.overlayTapView.isAccessibilityElement = isOverlayAccessable
        
        var pullBarLabel = ""
        if !isOverlayAccessable && (self.dismissOnOverlayTap || self.dismissOnPull) {
            pullBarLabel = "Tap to Dismiss Presentation."
        } else if self.orderedSizes.count > 1 {
            pullBarLabel = "Tap to switch between presentation sizes."
        }
        
        self.contentViewController.pullBarView.isAccessibilityElement = !pullBarLabel.isEmpty
        self.contentViewController.pullBarView.accessibilityLabel = pullBarLabel
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
        self.overlayTapView.accessibilityLabel = "Tap to Dismiss Presentation."
        
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
        self.contentViewController.willMove(toParent: self)
        self.addChild(self.contentViewController)
        self.view.addSubview(self.contentViewController.view)
        self.contentViewController.didMove(toParent: self)
        
        // [修复核心漏洞 1] 必须使用 [weak self] 防止内存泄漏！
        self.contentViewController.sheetContentViewPreferredHeightChanged = { [weak self] oldHeight, newSize in
            guard let self = self else { return }
            if self.sizes.contains(.intrinsic) {
                self.updateOrderedSizes()
            }
            if self.currentSize == .intrinsic, !self.isPanning {
                self.resize(to: .intrinsic)
            }
        }
        
        // [修复核心漏洞 2] 必须使用 [weak self] 防止内存泄漏！
        self.contentViewController.pullBarTappedAction = { [weak self] in
            guard let self = self else { return }
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
        
        self.contentViewController.view.snp.makeConstraints { make in
            make.left.equalToSuperview().priority(999)
            make.left.greaterThanOrEqualToSuperview().inset(self.options.horizontalPadding)
            if let maxWidth = self.options.maxWidth {
                make.width.lessThanOrEqualTo(maxWidth)
            }
            make.centerX.equalToSuperview()
            make.height.equalTo(self.height(for: self.currentSize))
            
            let top = self.options.useFullScreenMode ? 0 : max(12, AppWindows?.compatibleSafeAreaInsets.top ?? 12)
            make.bottom.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview().inset(top).priority(999)
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
    }
    
    @objc func panned(_ gesture: UIPanGestureRecognizer) {
        let point = gesture.translation(in: gesture.view?.superview)
        if gesture.state == .began {
            self.firstPanPoint = point
            self.prePanHeight = self.contentViewController.view.bounds.height
            self.isPanning = true
        }
        
        let minHeight: CGFloat = self.height(for: self.orderedSizes.first)
        let maxHeight: CGFloat = self.allowPullingPastMaxHeight ? self.height(for: .fullscreen) : max(self.height(for: self.orderedSizes.last), self.prePanHeight)
        
        var newHeight = max(0, self.prePanHeight + (self.firstPanPoint.y - point.y))
        var offset: CGFloat = 0
        
        if newHeight < minHeight {
            if self.allowPullingPastMinHeight {
                offset = minHeight - newHeight
            }
            newHeight = minHeight
        }
        
        if newHeight > maxHeight {
            if options.isRubberBandEnabled {
                newHeight = logConstraintValueForYPosition(verticalLimit: maxHeight, yPosition: newHeight)
            } else {
                newHeight = maxHeight
            }
        }
        
        switch gesture.state {
        case .cancelled, .failed:
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
                self.contentViewController.view.transform = .identity
                self.contentViewController.view.snp.updateConstraints { make in
                    make.height.equalTo(self.height(for: self.currentSize))
                }
                self.transition.setPresenter(percentComplete: 0)
                self.overlayView.alpha = 1
                self.overlayControlView.alpha = 1
                self.overlayControlView.subviews.forEach { $0.alpha = 1 }
            }, completion: { _ in
                self.isPanning = false
            })
            
        case .began, .changed:
            self.contentViewController.view.snp.updateConstraints { make in
                make.height.equalTo(newHeight)
            }
            if offset > 0 {
                let percent = max(0, min(1, offset / max(1, newHeight)))
                self.transition.setPresenter(percentComplete: percent)
                self.overlayView.alpha = 1 - percent
                self.overlayControlView.alpha = 1 - percent
                self.overlayControlView.subviews.forEach { $0.alpha = (1 - percent) }
                self.contentViewController.view.transform = CGAffineTransform(translationX: 0, y: offset)
            } else {
                self.contentViewController.view.transform = .identity
            }
            
        case .ended:
            let velocity = (0.2 * gesture.velocity(in: self.view).y)
            var finalHeight = newHeight - offset - velocity
            
            // 注意: 此处的 pullDismissThreshod 对应了之前 Options 里的拼写
            if velocity > options.pullDismissThreshod {
                finalHeight = -1 // Swipe down hard -> dismiss
            }
            
            let animationDuration = TimeInterval(abs(velocity * 0.0002) + 0.2)
            
            guard finalHeight > 0 || !(self.dismissOnPull && self.shouldDismiss?(self) ?? true) else {
                // Dismiss logic
                UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: self.options.transitionDampening, initialSpringVelocity: self.options.transitionVelocity, options: self.options.transitionAnimationOptions, animations: {
                    self.contentViewController.view.transform = CGAffineTransform(translationX: 0, y: self.contentViewController.view.bounds.height)
                    self.view.backgroundColor = UIColor.clear
                    self.transition.setPresenter(percentComplete: 1)
                    self.overlayView.alpha = 0
                    self.overlayControlView.alpha = 0
                    self.overlayControlView.subviews.forEach { $0.alpha = 0 }
                }, completion: { _ in
                    self.attemptDismiss(animated: false)
                })
                return
            }
            
            var newSize = self.currentSize
            if point.y < 0 {
                newSize = self.orderedSizes.last ?? self.currentSize
                for size in self.orderedSizes.reversed() {
                    if finalHeight < self.height(for: size) { newSize = size } else { break }
                }
            } else {
                newSize = self.orderedSizes.first ?? self.currentSize
                for size in self.orderedSizes {
                    if finalHeight > self.height(for: size) { newSize = size } else { break }
                }
            }
            
            let previousSize = self.currentSize
            self.currentSize = newSize
            let newContentHeight = self.height(for: newSize)
            
            UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: self.options.transitionDampening, initialSpringVelocity: self.options.transitionVelocity, options: self.options.transitionAnimationOptions, animations: {
                self.contentViewController.view.transform = .identity
                self.contentViewController.view.snp.updateConstraints { make in
                    make.height.equalTo(newContentHeight)
                }
                self.transition.setPresenter(percentComplete: 0)
                self.overlayView.alpha = 1
                self.overlayControlView.alpha = 1
                self.overlayControlView.subviews.forEach { $0.alpha = 1 }
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.isPanning = false
                if previousSize != newSize {
                    self.sizeChanged?(self, newSize, newContentHeight)
                }
            })
            
        case .possible: fallthrough
        @unknown default: break
        }
    }

    // MARK: - Keyboard Handling
    
    private func registerKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardShown(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDismissed(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardShown(_ notification: Notification) {
        guard let info = notification.userInfo, let keyboardRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        let windowRect = self.view.convert(self.view.bounds, to: nil)
        let actualHeight = windowRect.maxY - keyboardRect.origin.y
        self.adjustForKeyboard(height: actualHeight, from: notification)
    }
    
    @objc func keyboardDismissed(_ notification: Notification) {
        self.adjustForKeyboard(height: 0, from: notification)
    }
    
    private func adjustForKeyboard(height: CGFloat, from notification: Notification) {
        guard self.autoAdjustToKeyboard, let info = notification.userInfo else { return }
        self.keyboardHeight = height
        
        let duration = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let animationCurveRaw = (info[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let animationCurve = UIView.AnimationOptions(rawValue: animationCurveRaw)
        
        self.contentViewController.adjustForKeyboard(height: self.keyboardHeight)
        self.resize(to: self.currentSize, duration: duration, options: animationCurve, animated: true, complete: { [weak self] in
            guard let self = self else { return }
            self.resize(to: self.currentSize)
        })
    }
    
    // MARK: - Helpers & Utilities
    
    private func height(for size: PTSheetSize?) -> CGFloat {
        guard let size = size else { return 0 }
        let contentHeight: CGFloat
        let fullscreenHeight = self.options.useFullScreenMode ?
            self.view.bounds.height - self.minimumSpaceAbovePullBar :
            self.view.bounds.height - self.view.compatibleSafeAreaInsets.top - self.minimumSpaceAbovePullBar
        
        switch size {
        case .fixed(let height):
            contentHeight = height + self.keyboardHeight
        case .fullscreen:
            contentHeight = fullscreenHeight
        case .intrinsic:
            contentHeight = self.contentViewController.preferredHeight + self.keyboardHeight
        case .percent(let percent):
            if percent > 1 {
                print("Size percent should be less than or equal to 1.0, but was set to \(percent)")
            }
            contentHeight = (self.view.bounds.height) * CGFloat(percent) + self.keyboardHeight
        case .marginFromTop(let margin):
            contentHeight = (self.view.bounds.height) - margin + self.keyboardHeight
        }
        return min(fullscreenHeight, contentHeight)
    }

    private func logConstraintValueForYPosition(verticalLimit: CGFloat, yPosition: CGFloat) -> CGFloat {
      return verticalLimit * (1 + log10(yPosition / verticalLimit))
    }
    
    public func resize(to size: PTSheetSize, duration: TimeInterval = 0.2, options: UIView.AnimationOptions = [.curveEaseOut], animated: Bool = true, complete: PTActionTask? = nil) {
        
        let previousSize = self.currentSize
        self.currentSize = size
        
        let oldConstraintHeight = self.contentViewController.view.frame.height
        let newHeight = self.height(for: size)
        
        guard oldConstraintHeight != newHeight else {
            complete?()
            return
        }
        
        if animated {
            UIView.animate(withDuration: duration, delay: 0, options: options, animations: { [weak self] in
                guard let self = self else { return }
                self.contentViewController.view.snp.updateConstraints { make in
                    make.height.equalTo(newHeight)
                }
                // [优化] 移除原本奇怪的 #available(iOS 26.0) 判定，执行标准的布局刷新
                if #available(iOS 26.0, *) { } else {
                    self.view.layoutIfNeeded()
                }
            }, completion: { [weak self] _ in
                guard let self = self else { return }
                if previousSize != size {
                    self.sizeChanged?(self, size, newHeight)
                }
                self.contentViewController.updateAfterLayout()
                complete?()
            })
        } else {
            UIView.performWithoutAnimation {
                self.contentViewController.view.snp.updateConstraints { make in
                    make.height.equalTo(self.height(for: size))
                }
                if #available(iOS 26.0, *) { } else {
                    self.contentViewController.view.layoutIfNeeded()
                }
            }
            complete?()
        }
    }
    
    public func attemptDismiss(animated: Bool) {
        if self.shouldDismiss?(self) != false {
            if self.options.useInlineMode {
                if animated {
                    self.animateOut { [weak self] in
                        guard let self = self else { return }
                        self.didDismiss?(self)
                    }
                } else {
                    self.view.removeFromSuperview()
                    self.removeFromParent()
                    self.didDismiss?(self)
                }
            } else {
                self.dismiss(animated: animated, completion: nil)
            }
        }
    }
    
    public func updateIntrinsicHeight() {
        contentViewController.updatePreferredHeight()
    }
    
    public func animateIn(to view: UIView, in parent: UIViewController, size: PTSheetSize? = nil, duration: TimeInterval = 0.3, completion: PTActionTask? = nil) {
        self.willMove(toParent: parent)
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
        
        self.view.superview?.layoutIfNeeded()
        self.contentViewController.updatePreferredHeight()
        self.resize(to: size ?? self.sizes.first ?? self.currentSize, animated: false)
        let contentView = self.contentViewController.view!
        contentView.transform = CGAffineTransform(translationX: 0, y: contentView.bounds.height)
        self.overlayView.alpha = 0
        self.updateOrderedSizes()
        
        UIView.animate(withDuration: duration, animations: {
            contentView.transform = .identity
            self.overlayView.alpha = 1
            self.overlayControlView.alpha = 1
            self.overlayControlView.subviews.forEach { $0.alpha = 1 }
        }, completion: { _ in
            completion?()
        })
    }
    
    public func animateOut(duration: TimeInterval = 0.3, completion: PTActionTask? = nil) {
        guard self.options.useInlineMode else { return }
        let contentView = self.contentViewController.view!
        
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: self.options.transitionDampening, initialSpringVelocity: self.options.transitionVelocity, options: self.options.transitionAnimationOptions, animations: {
            contentView.transform = CGAffineTransform(translationX: 0, y: contentView.bounds.height)
            self.overlayView.alpha = 0
            self.overlayControlView.alpha = 0
            self.overlayControlView.subviews.forEach { $0.alpha = 0 }
        }, completion: { _ in
            self.view.removeFromSuperview()
            self.removeFromParent()
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
        guard let panGestureRecognizer = gestureRecognizer as? PTInitialTouchPanGestureRecognizer, let childScrollView = self.childScrollView, let point = panGestureRecognizer.initialTouchLocation else { return true }
        
        if let pan = gestureRecognizer as? UIPanGestureRecognizer, let closure = panGestureShouldBegin, let should = closure(pan) {
            return should
        }
        
        let pointInChildScrollView = self.view.convert(point, to: childScrollView).y - childScrollView.contentOffset.y
        let velocity = panGestureRecognizer.velocity(in: panGestureRecognizer.view?.superview)
        
        guard pointInChildScrollView > 0, pointInChildScrollView < childScrollView.bounds.height else {
            if keyboardHeight > 0 {
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
