//
//  PTPerformanceLeakDetector.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import Foundation

// MARK: - Models

// 1. 在 Swift 6 中，包含 UI 元素的结构体最好明确其执行上下文。
// 由于它持有 UIViewController 和 UIView，我们将其隔离到主线程。
@MainActor
public struct PTPerformanceLeak {
    public let controller: UIViewController?
    public let view: UIView?
    public let message: String

    init(controller: UIViewController? = nil, view: UIView? = nil, message: String) {
        self.controller = controller
        self.view = view
        self.message = message
    }

    public var isDeallocation: Bool { controller == nil && view == nil }
}

// 2. 将数据模型标记为 Sendable，使其在 Swift 6 中可以跨 actor 边界安全传递
public struct LeakModel: Sendable {
    public let details: String
    public let screenshot: UIImage?
    public let id: Int

    public var hasDeallocated = false
    public var timeAllocated: String?

    public var isActive: Bool { !hasDeallocated }
    public var symbol: String { hasDeallocated ? "✳️" : "⚠️" }
}

// MARK: - Main Detector Class

// 3. 将整个管理类标记为 @MainActor。
// 在 Swift 6 中，包含静态可变属性 (static var) 的类必须被隔离以防止数据竞争。
@MainActor
public final class PTPerformanceLeakDetector {

    // 闭包现在明确要求在主线程执行
    public static var callback: (@MainActor (PTPerformanceLeak) -> Void)?
    public static var delay = 1.0
    public static var warningWindow: UIWindow?
    public static var lastBackgroundedDate = Date(timeIntervalSince1970: 0)
    public static var leaks = [LeakModel]()

    public static func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(toBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    @objc private static func toBackground() {
        lastBackgroundedDate = Date()
    }

    private static var _ignoredWindowClassNames = [
        "UIRemoteKeyboardWindow",
        "UITextEffectsWindow"
    ]

    public static var ignoredWindowClassNames: [String] {
        get { _ignoredWindowClassNames }
        set { _ignoredWindowClassNames += newValue }
    }

    private static var _ignoredViewControllerClassNames = [
        "UICompatibilityInputViewController",
        "_SFAppPasswordSavingViewController",
        "UIKeyboardHiddenViewController_Save",
        "_UIAlertControllerTextFieldViewController",
        "UISystemInputAssistantViewController",
        "UIPredictionViewController"
    ]
    
    public static var ignoredViewControllerClassNames: [String] {
        get { _ignoredViewControllerClassNames }
        set { _ignoredViewControllerClassNames += newValue }
    }

    private static var _ignoredViewClassNames = [
        "PLTileContainerView",
        "CAMPreviewView",
        "_UIPointerInteractionAssistantEffectContainerView"
    ]
    
    public static var ignoredViewClassNames: [String] {
        get { _ignoredViewClassNames }
        set { _ignoredViewClassNames += newValue }
    }
}

// MARK: - UIView Extensions

@MainActor
extension UIView {

    @objc public func removeFromSuperviewDetectLeaks() {
        let superViewWasNil = superview == nil && window == nil
        removeFromSuperview()

        if PTPerformanceLeakDetector.callback != nil, !superViewWasNil, UIApplication.shared.applicationState == .active {
            checkForLeakedSubViews()
        }
    }

    @objc fileprivate func checkForLeakedSubViews() {
        let delay = PTPerformanceLeakDetector.delay

        iterateTopSubviews { topSubview in
            let startTime = Date()
            
            // 4. 在闭包中保持 @MainActor 上下文
            PTGCDManager.gcdAfter(time: delay) { [weak topSubview, weak self] in
                Task { @MainActor [weak topSubview, weak self] in
                    guard let self = self, let topSubview = topSubview else { return }
                    
                    if self.superview == nil,
                       self.firstViewController == nil,
                       let leakedView = topSubview.rootView as UIView?,
                       leakedView == topSubview || !(leakedView is UIWindow),
                       leakedView.firstViewController == nil,
                       objc_getAssociatedObject(leakedView, &LVCDDeallocator.key) == nil,
                       UIApplication.shared.applicationState == .active,
                       PTPerformanceLeakDetector.lastBackgroundedDate < startTime,
                       !PTPerformanceLeakDetector.ignoredViewClassNames.contains(type(of: leakedView).description()) {

                        let errorTitle = "VIEW STILL IN MEMORY"
                        var errorMessage = leakedView.debugDescription.lvcdRemoveBundleAndModuleName()
                        if let bundleName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
                            errorMessage = errorMessage.replacingOccurrences(of: "\(bundleName).", with: "")
                        }

                        PTPerformanceLeakDetector.callback?(
                            .init(view: leakedView, message: "\(errorTitle) \(errorMessage)")
                        )
                        
                        PTNSLogConsole("\(errorTitle) \(errorMessage)")

                        let screenshot = leakedView.makeScreenshot()

                        PTPerformanceLeakDetector.leaks.append(
                            .init(details: errorMessage, screenshot: screenshot, id: Int(bitPattern: ObjectIdentifier(leakedView)))
                        )

                        let deallocator = LVCDDeallocator()
                        deallocator.memoryLeakDetectionDate = Date().timeIntervalSince1970 - delay
                        deallocator.errorMessage = errorMessage
                        deallocator.objectIdentifier = Int(bitPattern: ObjectIdentifier(leakedView))
                        deallocator.objectType = "VIEW"
                        deallocator.subviews = leakedView.subviews
                        deallocator.weakView = leakedView
                        // 5. 传入 &LVCDDeallocator.key 替代旧的 malloc 指针
                        objc_setAssociatedObject(leakedView, &LVCDDeallocator.key, deallocator, .OBJC_ASSOCIATION_RETAIN)
                    }
                }
            }
        }
    }

    fileprivate func makeScreenshot() -> UIImage? {
        let fvc = firstViewController
        if let fvc, fvc.view == self {
            #if os(iOS)
            if fvc is UIImagePickerController {
                return nil
            }
            #endif
        }

        let squareSize: CGFloat = 20
        let offset = CGPoint(x: frame.width.truncatingRemainder(dividingBy: squareSize) * 0.5, y: frame.height.truncatingRemainder( dividingBy: squareSize) * 0.5)
        let checkerBoard = UIView(frame: .init(x: 0, y: 0, width: squareSize * 2, height: squareSize * 2))
        checkerBoard.backgroundColor = .init(white: 1 - 0.4 * 0.5,alpha: 1)
        for point in [
            CGPoint(x: 0 as CGFloat, y: 0 as CGFloat),
            CGPoint(x: -squareSize,y: squareSize),
            CGPoint(x: squareSize, y: squareSize),
            CGPoint(x: 0 as CGFloat, y: squareSize * 2)
        ] {
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = UIBezierPath(rect: .init(x: point.x + offset.x, y: point.y - offset.y, width: squareSize, height: squareSize)).cgPath
            shapeLayer.fillColor = UIColor(white: 1 - 0.6 * 0.5, alpha: 1).cgColor
            checkerBoard.layer.addSublayer(shapeLayer)
        }
        UIGraphicsBeginImageContextWithOptions(checkerBoard.bounds.size, false, 0)
        checkerBoard.drawHierarchy(in: checkerBoard.bounds, afterScreenUpdates: true)
        let checkerBoardImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()

        let wasAlpha = alpha
        let wasHidden = isHidden
        alpha = alpha < 0.1 ? 1.0 : alpha
        isHidden = false
        var wasTARMICS = [ObjectIdentifier: Bool]()
        var cornerRadius: CGFloat = 0

        iterateSubviews(maxLevel: 3) { subview, level in
            if !(subview is UINavigationBar || subview is UICollectionViewCell || subview is UITabBar || subview is UIToolbar || level > 2) {
                wasTARMICS[ObjectIdentifier(subview)] = subview.translatesAutoresizingMaskIntoConstraints
                subview.translatesAutoresizingMaskIntoConstraints = true
            }
            if cornerRadius == 0, subview.bounds == bounds, subview.layer.cornerRadius != 0 {
                cornerRadius = subview.layer.cornerRadius
            }
            return true
        }

        let container = UIView(frame: .init(origin: .zero, size: frame.size))
        container.addSubview(self)
        objc_setAssociatedObject(container, &LVCDDeallocator.key, LVCDDeallocator(), .OBJC_ASSOCIATION_RETAIN)

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = UIBezierPath(rect: frame).cgPath
        shapeLayer.fillColor = UIColor(patternImage: checkerBoardImage).withAlphaComponent(0.5).cgColor
        container.layer.insertSublayer(shapeLayer, at: 0)

        var unclippedFrame = frame

        iterateSubviews { subview, _ in
            if subview.isHidden || subview.alpha < 0.1 {
                return false
            }

            var subAlpha: CGFloat = 0
            subview.backgroundColor?.getRed(nil, green: nil, blue: nil, alpha: &subAlpha)

            if subview.frame.size.height * subview.frame.size.width != 0, subAlpha >= 0.1 {
                unclippedFrame = unclippedFrame.union(subview.convert(subview.bounds, to: container))
            }
            return !subview.clipsToBounds && !subview.layer.masksToBounds && !(subview is UIScrollView)
        }

        guard unclippedFrame.size.width > 0, unclippedFrame.size.height > 0 else {
            return nil
        }

        let container2 = UIView(frame: .init(origin: .zero, size: unclippedFrame.size))
        container2.backgroundColor = UIColor.white.withAlphaComponent(0.03)
        container2.addSubview(container)
        container.frame = .init(x: 0 - unclippedFrame.minX, y: 0 - unclippedFrame.minY, width: unclippedFrame.width, height: unclippedFrame.height)
        container2.layer.cornerRadius = cornerRadius
        container2.layer.masksToBounds = container2.layer.cornerRadius > 0
        objc_setAssociatedObject(container2, &LVCDDeallocator.key, LVCDDeallocator(), .OBJC_ASSOCIATION_RETAIN)

        var iosOnMac = false
        if #available(iOS 13, tvOS 13, * ) {
            iosOnMac = ProcessInfo.processInfo.isMacCatalystApp
        }
        let maxWidth: CGFloat = 240 - (iosOnMac ? 12 : 0)
        let imageSize = container2.frame.width <= maxWidth ? container2.frame.size : CGSize(width: maxWidth, height: maxWidth * (container2.frame.height / container2.frame.width))

        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
        container2.drawHierarchy(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height), afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        alpha = wasAlpha
        isHidden = wasHidden

        iterateSubviews { subview, level in
            if !(subview is UINavigationBar || subview is UICollectionViewCell || subview is UITabBar || subview is UIToolbar || level > 2) {
                subview.translatesAutoresizingMaskIntoConstraints = wasTARMICS[ObjectIdentifier(subview)] ?? subview.translatesAutoresizingMaskIntoConstraints
            }
            return true
        }

        return image
    }

    private func iterateTopSubviews(onViewFound: (UIView) -> Void) {
        var hasSubview = false

        if !(self is UINavigationBar && firstViewController is UINavigationController) {
            for subview in subviews {
                subview.iterateTopSubviews(onViewFound: onViewFound)
                hasSubview = true
            }
        }
        if !hasSubview {
            onViewFound(self)
        }
    }

    private func iterateSubviews(maxLevel: UInt = UInt.max, level: UInt = 0, onSubview: (UIView, UInt) -> (Bool)) {
        if onSubview(self, level) {
            let nextLevel = level + 1
            if nextLevel <= maxLevel {
                for subview in subviews {
                    subview.iterateSubviews(maxLevel: maxLevel, level: nextLevel, onSubview: onSubview)
                }
            }
        }
    }

    fileprivate var rootView: UIView {
        superview?.rootView ?? self
    }

    private var firstViewController: UIViewController? {
        sequence(first: self, next: { $0.next }).first(where: { $0 is UIViewController }) as? UIViewController
    }
}

// MARK: - UIViewController Extensions

@MainActor
extension UIViewController {

    nonisolated fileprivate static let lvcdCheckForMemoryLeakNotification = Notification.Name("lvcdCheckForMemoryLeak")
    nonisolated fileprivate static let lvcdCheckForSplitViewVCMemoryLeakNotification = Notification.Name("lvcdCheckForSplitViewVCMemoryLeak")

    public static func lvcdSwizzleLifecycleMethods() {
        _ = lvcdActuallySwizzleLifecycleMethods
    }

    private static let lvcdActuallySwizzleLifecycleMethods: Void = {
        Swizzle(UIViewController.self) {
            #selector(viewDidLoad) <-> #selector(lvcdViewDidLoad)
            #selector(viewDidDisappear(_:)) <-> #selector(lvcdViewDidDisappear(_:))
            #selector(removeFromParent) <-> #selector(lvcdRemoveFromParent)
            #selector(showDetailViewController(_:sender:)) <-> #selector(lvcdShowDetailViewController(_:sender:))
            #selector(setter: view) <-> #selector(lvcdSetView(_:))
        }
    }()

    private func lvcdShouldIgnore() -> Bool {
        let ignoredVC = PTPerformanceLeakDetector.ignoredViewControllerClassNames.contains(
            type(of: self).description()
        )
        let ignoredWindow = isViewLoaded && view?.window != nil && PTPerformanceLeakDetector.ignoredWindowClassNames.contains(type(of: view.window!).description())

        let ignoreLVCD = objc_getAssociatedObject(self, &LVCDSplitViewAssociatedObject.key) != nil

        return ignoredVC || ignoredWindow || ignoreLVCD
    }

    @objc private func lvcdSetView(_ newView: UIView?) {
        if isViewLoaded, let deallocator = objc_getAssociatedObject(self, &LVCDDeallocator.key) as? LVCDDeallocator {
            deallocator.strongView?.checkForLeakedSubViews()
            deallocator.strongView = newView
        }
        lvcdSetView(newView)
    }

    @objc private func lvcdViewDidLoad() {
        lvcdViewDidLoad() // run original implementation
        PTGCDManager.gcdAfter(time: 0.1) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if !self.lvcdShouldIgnore() {
                    if objc_getAssociatedObject(self, &LVCDDeallocator.key) == nil {
                        objc_setAssociatedObject(self, &LVCDDeallocator.key, LVCDDeallocator(self.view), .OBJC_ASSOCIATION_RETAIN)
                    }
                    self.addCheckForMemoryLeakObserver(skipIgnoreCheck: true)
                }
            }
        }
    }

    private func addCheckForMemoryLeakObserver(skipIgnoreCheck: Bool = false) {
        NotificationCenter.lvcd.removeObserver(self, name: UIViewController.lvcdCheckForMemoryLeakNotification, object: nil)
        if skipIgnoreCheck || !lvcdShouldIgnore() {
            NotificationCenter.lvcd.addObserver(self, selector: #selector(lvcdCheckForMemoryLeak), name: UIViewController.lvcdCheckForMemoryLeakNotification, object: nil)
        }
    }

    @objc private func lvcdViewDidDisappear(_ animated: Bool) {
        lvcdViewDidDisappear(animated)
        if (self as? UINavigationController)?.viewControllers.isEmpty ?? true,
           (self as? UITabBarController)?.viewControllers?.isEmpty ?? true,
           (self as? UIPageViewController)?.viewControllers?.isEmpty ?? true,
           !lvcdShouldIgnore() {
            NotificationCenter.lvcd.post(name: Self.lvcdCheckForMemoryLeakNotification, object: nil)
        }
    }

    @objc private func lvcdRemoveFromParent() {
        lvcdRemoveFromParent()
        if !lvcdShouldIgnore(), view?.window != nil {
            NotificationCenter.lvcd.post(name: Self.lvcdCheckForMemoryLeakNotification, object: nil)
        }
    }

    @objc private func lvcdShowDetailViewController(_ vc: UIViewController, sender: Any?) {
        NotificationCenter.lvcd.post(name: Self.lvcdCheckForSplitViewVCMemoryLeakNotification, object: self)
        NotificationCenter.lvcd.post(name: Self.lvcdCheckForMemoryLeakNotification,object: nil)

        if objc_getAssociatedObject(vc, &LVCDSplitViewAssociatedObject.key) == nil {
            let mldAssociatedObject = LVCDSplitViewAssociatedObject()
            mldAssociatedObject.splitViewController = self as? UISplitViewController
            mldAssociatedObject.viewController = vc
            objc_setAssociatedObject(vc, &LVCDSplitViewAssociatedObject.key, mldAssociatedObject, .OBJC_ASSOCIATION_RETAIN)
        }
        lvcdShowDetailViewController(vc, sender: sender)
    }

    fileprivate static var lvcdMemoryCheckQueue = Set<ObjectIdentifier>()

    private var lvcdRootParentViewController: UIViewController {
        parent?.lvcdRootParentViewController ?? self
    }

    @objc private func lvcdCheckForMemoryLeak(restarted: Bool = false) {
        guard UIApplication.shared.applicationState == .active else { return }

        if (view != nil && view.window != nil) || lvcdShouldIgnore() {
            return
        }

        let objectIdentifier = ObjectIdentifier(self)

        guard !Self.lvcdMemoryCheckQueue.contains(objectIdentifier) else { return }
        Self.lvcdMemoryCheckQueue.insert(objectIdentifier)

        // Switch to MainActor task execution
        Task { @MainActor in
            Self.lvcdMemoryCheckQueue.remove(objectIdentifier)
            let rootParentVC = self.lvcdRootParentViewController
            
            guard rootParentVC.presentedViewController == nil,
                  !self.isViewLoaded || rootParentVC.view.window == nil,
                  let deallocator = objc_getAssociatedObject(self, &LVCDDeallocator.key) as? LVCDDeallocator,
                  deallocator.objectIdentifier == 0
            else { return }

            if let svc = self as? UISplitViewController {
                NotificationCenter.lvcd.post(name: Self.lvcdCheckForSplitViewVCMemoryLeakNotification, object: svc)
            }

            let startTime = Date()
            let delay = PTPerformanceLeakDetector.delay
            
            PTGCDManager.gcdAfter(time: delay) { [weak self] in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    
                    if UIApplication.shared.applicationState != .active || PTPerformanceLeakDetector.lastBackgroundedDate > startTime {
                        return
                    }

                    if !restarted && abs(startTime.timeIntervalSinceNow) > delay + 0.5 {
                        self.lvcdCheckForMemoryLeak(restarted: true)
                        return
                    }

                    if !self.isViewLoaded || self.view?.window == nil, self.parent == nil, self.presentedViewController == nil, self.view == nil || self.view.superview == nil || type(of: self.view.rootView).description() == "UILayoutContainerView" {
                        
                        NotificationCenter.lvcd.removeObserver(self, name: Self.lvcdCheckForMemoryLeakNotification, object: nil)

                        let errorTitle = "VIEWCONTROLLER STILL IN MEMORY"
                        var errorMessage = self.debugDescription.lvcdRemoveBundleAndModuleName()

                        if let nvc = self as? UINavigationController {
                            errorMessage = "\(errorMessage):\n\(nvc.viewControllers)"
                        }
                        if let tbvc = self as? UITabBarController, let vcs = tbvc.viewControllers {
                            errorMessage = "\(errorMessage):\n\(vcs)"
                        }
                        if let alertVC = self as? UIAlertController {
                            var actions = alertVC.actions.isEmpty ? "-" : ""
                            for action in alertVC.actions {
                                actions = "\(actions) \"\(action.title ?? "-")\","
                            }
                            errorMessage = """
                                \(errorMessage)
                                title: \"\((alertVC.title ?? "") == "" ? "" : alertVC.title!)\"
                                message: \"\((alertVC.message ?? "") == "" ? "" : alertVC.message!)\"
                                actions: \(actions);
                            """
                            if alertVC.textFields?.isEmpty == false {
                                var tfs = ""
                                for tf in alertVC.textFields ?? [] {
                                    tfs = "\(tfs) \"\(tf.placeholder ?? "-")\","
                                }
                                errorMessage += "\ntextfields: \(tfs);"
                            }
                            errorMessage = errorMessage.replacingOccurrences(of: ",;", with: ";")
                        }

                        PTPerformanceLeakDetector.callback?( .init(controller: self, message: "\(errorTitle) \(errorMessage)"))
                        PTNSLogConsole("\(errorTitle) \(errorMessage)")

                        let screenshot = self.view?.rootView.makeScreenshot()
                        let id = Int(bitPattern: ObjectIdentifier(self))

                        if !PTPerformanceLeakDetector.leaks.contains(where: { $0.id == id }) {
                            PTPerformanceLeakDetector.leaks.append( .init(details: errorMessage, screenshot: screenshot, id: id))
                        }

                        deallocator.memoryLeakDetectionDate = Date().timeIntervalSince1970 - delay
                        deallocator.errorMessage = errorMessage
                        deallocator.objectIdentifier = Int(bitPattern: ObjectIdentifier(self))
                        deallocator.objectType = "VIEWCONTROLLER"
                        deallocator.screenshot = screenshot
                    }
                }
            }
        }
    }

    fileprivate class func lvcdMemoryLeakResolved(memoryLeakDetectionDate: TimeInterval, errorMessage: String, objectIdentifier: Int, objectType: String, screenshot: UIImage?) {
        let interval = Date().timeIntervalSince1970 - memoryLeakDetectionDate
        let errorTitle = "LEAKED \(objectType) DEINNITED"
        let errorMessage = String(format: "\(errorMessage)\n\nDeinnited after %.3fs.",interval)

        if let index = PTPerformanceLeakDetector.leaks.firstIndex(where: { $0.id == objectIdentifier }) {
            PTPerformanceLeakDetector.leaks[index].hasDeallocated = true
            PTPerformanceLeakDetector.leaks[index].timeAllocated = String(format: "%.3fs.", interval)
        }

        PTPerformanceLeakDetector.callback?(
            .init(message: "\(errorTitle) \(errorMessage)")
        )
        PTNSLogConsole("\(errorTitle) \(errorMessage)")
    }

    fileprivate class LVCDSplitViewAssociatedObject {
        // 6. 使用 UInt8 替代容易泄漏和崩溃的 malloc(1)!
        @MainActor static var key: UInt8 = 0

        weak var splitViewController: UISplitViewController?
        weak var viewController: UIViewController? {
            didSet {
                NotificationCenter.lvcd.addObserver(self, selector: #selector(checkIfBelongsToSplitViewController(_:)), name: UIViewController.lvcdCheckForSplitViewVCMemoryLeakNotification, object: nil)
            }
        }

        @objc func checkIfBelongsToSplitViewController(_ notification: Notification) {
            // 1. 在开启 Task 之前，做条件判断并把需要的属性提取为局部变量
            // 这样 Task 内部就不需要再访问 `self` 了
            guard notification.object as? UISplitViewController == splitViewController, let vc = viewController else {
                return
            }
            
            // 提前提取出 splitViewController，彻底和 self 解绑
            let currentSplitVC = self.splitViewController
            
            // 2. 开启主线程任务
            Task { @MainActor in
                // 清理并重新设置关联对象，这里直接使用局部变量 vc
                objc_setAssociatedObject(vc, &LVCDSplitViewAssociatedObject.key, nil, .OBJC_ASSOCIATION_RETAIN)

                if objc_getAssociatedObject(vc, &LVCDDeallocator.key) == nil {
                    objc_setAssociatedObject(vc, &LVCDDeallocator.key, LVCDDeallocator(vc.view), .OBJC_ASSOCIATION_RETAIN)
                }

                vc.addCheckForMemoryLeakObserver()

                // 3. 将局部变量 currentSplitVC 和 vc 弱引用传入延时任务
                PTGCDManager.gcdAfter(time: PTPerformanceLeakDetector.delay) { [weak currentSplitVC, weak vc] in
                    
                    if currentSplitVC == nil {
                        // 4. 这里的闭包已经被我们升级为 @MainActor 了，所以不需要再嵌套 Task
                        Task { @MainActor in
                            vc?.lvcdCheckForMemoryLeak()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Sub Helpers

extension NotificationCenter {
    fileprivate static let lvcd = NotificationCenter()
}

@MainActor
private class LVCDDeallocator {
    // 使用安全的静态键传递给关联对象
    static var key: UInt8 = 0

    var memoryLeakDetectionDate: TimeInterval = 0.0
    var errorMessage = ""
    var objectIdentifier = 0
    var objectType = ""
    var screenshot: UIImage?

    var strongView: UIView?
    var subviews: [UIView]?
    var subviewObserver: NSKeyValueObservation?
    weak var weakView: UIView? {
        didSet {
            subviewObserver?.invalidate()
            subviewObserver = weakView?.layer.observe(\.sublayers, options: [.old, .new]) { [weak self] _, _ in
                // 确保在主线程更新 UI 数组
                Task { @MainActor [weak self] in
                    if let view = self?.weakView {
                        self?.subviews = view.subviews
                    }
                }
            }
        }
    }

    init(_ view: UIView? = nil) {
        self.strongView = view
    }

    deinit {
        // 注意：deinit 在 Swift 6 的隔离类型中是脱离 actor 上下文的 (nonisolated)
        // 但如果仅处理自身状态或交由 MainActor 处理即可
        let viewToRelease = strongView
        let subviewsToRelease = subviews
        let id = objectIdentifier
        let msg = errorMessage
        let date = memoryLeakDetectionDate
        let type = objectType
        let image = screenshot
        
        Task { @MainActor in
            viewToRelease?.checkForLeakedSubViews()
            for subview in subviewsToRelease ?? [] {
                subview.checkForLeakedSubViews()
            }
            if id != 0 {
                UIViewController.lvcdMemoryLeakResolved(memoryLeakDetectionDate: date, errorMessage: msg, objectIdentifier: id, objectType: type, screenshot: image)
            }
        }
        
        subviewObserver?.invalidate()
    }
}

@MainActor
extension UIResponder {
    fileprivate var viewController: UIViewController? {
        next as? UIViewController ?? next?.viewController
    }
}

@MainActor
extension UIApplication {
    private var lvcdActiveMainKeyWindow: UIWindow? {
        if #available(iOS 13, tvOS 13, *) {
            let activeScenes = connectedScenes.filter {
                $0.activationState == UIScene.ActivationState.foregroundActive
            }
            return (activeScenes.count > 0 ? activeScenes : connectedScenes).flatMap {
                ($0 as? UIWindowScene)?.windows ?? []
            }.first { $0.isKeyWindow }
        } else {
            return keyWindow
        }
    }

    private class func lvcdTopViewController(controller: UIViewController? = nil) -> UIViewController? {
        let new = controller ?? UIApplication.shared.lvcdActiveMainKeyWindow?.rootViewController
        return new?.presentedViewController != nil ? lvcdTopViewController(controller: new?.presentedViewController!) : new
    }

    private class func lvcdFindViewControllerWithTag(controller: UIViewController? = nil, tag: Int ) -> UIViewController? {
        let new = controller ?? UIApplication.shared.lvcdActiveMainKeyWindow?.rootViewController
        return new == nil ? nil : (new?.view.tag == tag ? new : lvcdFindViewControllerWithTag(controller: new?.presentedViewController,tag: tag))
    }

    @available(iOS 13.0, tvOS 13, *)
    private var lvcdFirstActiveWindowScene: UIWindowScene? {
        let activeScenes = UIApplication.shared.connectedScenes.filter { $0.activationState == UIScene.ActivationState.foregroundActive && $0 is UIWindowScene }
        return (activeScenes.count > 0 ? activeScenes : UIApplication.shared.connectedScenes).first(where: { $0 is UIWindowScene }) as? UIWindowScene
    }
}

extension String {
    private mutating func lvcdRegReplace(pattern: String, replaceWith: String = "") {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .anchorsMatchLines])
            let range = NSRange(startIndex..., in: self)
            self = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replaceWith)
        } catch {
            return
        }
    }

    // 这些全局可变状态在 Swift 6 下需要保护，既然是工具方法，隔离到 MainActor 是最简单的方式
    @MainActor private static var lvcdBundleName: String?
    @MainActor private static var lvcdModuleName: String?

    @MainActor fileprivate func lvcdRemoveBundleAndModuleName() -> String {
        Self.lvcdBundleName = Self.lvcdBundleName ?? kAppName
        if Self.lvcdBundleName != nil, Self.lvcdModuleName == nil {
            Self.lvcdModuleName = Self.lvcdBundleName
            Self.lvcdModuleName?.lvcdRegReplace(pattern: "[^A-Za-z0-9]", replaceWith: "_")
        }
        if Self.lvcdBundleName != nil, Self.lvcdModuleName != nil {
            return replacingOccurrences(of: "\(Self.lvcdBundleName!).", with: "").replacingOccurrences(of: "\(Self.lvcdModuleName!).", with: "")
        }
        return self
    }
}
