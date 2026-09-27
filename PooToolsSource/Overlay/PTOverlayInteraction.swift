// English: Interaction, keyboard, and accessibility policies shared by overlay products.
// Español: Políticas compartidas de interacción, teclado y accesibilidad para los overlays.
// 中文：所有浮层产品共享的交互、键盘和无障碍策略。

import UIKit

public enum PTOutsideTapBehavior: Sendable {
    case ignore
    case dismiss
    case dismissAndPassthrough
    case dismissAndConsume
}

public enum PTOutsideTapScope: Sendable {
    case outsideSelf
    case outsideGroup
    case outsideAllOverlays
}

@MainActor
public final class PTExcludedHitRegion {
    public enum Source {
        case rect(CGRect, in: UIView)
        case view(UIView)
        case registered(PTAnchorID)
    }

    private let source: Source

    public init(_ source: Source) {
        self.source = source
    }

    public func contains(_ point: CGPoint, in window: UIWindow) -> Bool {
        switch source {
        case let .rect(rect, view):
            guard view.window === window else { return false }
            return view.convert(rect, to: window).contains(point)
        case let .view(view):
            guard view.window === window else { return false }
            return view.convert(view.bounds, to: window).contains(point)
        case let .registered(id):
            guard let view = PTAnchorRegistry.shared.view(for: id), view.window === window else { return false }
            return view.convert(view.bounds, to: window).contains(point)
        }
    }
}

public enum PTOverlayDragBehavior: Sendable {
    case disabled
    case wholePopover
    case headerOnly
    case customView
}

public enum PTOverlayDragDismissDirection: Sendable {
    case none
    case up
    case down
    case leading
    case trailing
    case any
}

@MainActor
public final class PTOverlayGestureCoordinator: NSObject, UIGestureRecognizerDelegate {
    public weak var scrollView: UIScrollView?
    public var dragBehavior: PTOverlayDragBehavior = .disabled
    private var panHandler: (@MainActor (UIPanGestureRecognizer) -> Void)?

    public func attachPan(to view: UIView,
                          action: Selector) -> UIPanGestureRecognizer? {
        guard dragBehavior != .disabled else { return nil }
        let pan = UIPanGestureRecognizer(target: self, action: action)
        pan.delegate = self
        view.addGestureRecognizer(pan)
        return pan
    }

    // English: Keep the gesture delegate in OverlayCore while products supply their own drag behavior.
    // Español: Mantén el delegado de gestos en OverlayCore y deja que cada producto defina su arrastre.
    // 中文：手势代理继续由 OverlayCore 统一管理，具体拖拽行为由产品层注入。
    public func attachPan(to view: UIView,
                          handler: @escaping @MainActor (UIPanGestureRecognizer) -> Void) -> UIPanGestureRecognizer? {
        guard dragBehavior != .disabled else { return nil }
        panHandler = handler
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        view.addGestureRecognizer(pan)
        return pan
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        panHandler?(gesture)
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let scrollView else { return false }
        return otherGestureRecognizer.view === scrollView || gestureRecognizer.view === scrollView
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        otherGestureRecognizer.view is UIScrollView
    }
}

public enum PTOverlayAccessibilityRole: Sendable {
    case tooltip
    case menu
    case dialog
    case transient
}

@MainActor
public final class PTOverlayFocusCoordinator {
    private weak var previousFocusedView: UIView?

    public init() {}

    public func captureFocus() {
        // English: UIKit does not expose a portable focused-view getter; restoration remains best-effort.
        // Español: UIKit no expone un getter portable de la vista enfocada; la restauración es aproximada.
        // 中文：UIKit 没有公开通用的焦点 View 获取接口，因此这里只做尽力恢复。
        previousFocusedView = nil
    }

    public func focus(_ view: UIView, role: PTOverlayAccessibilityRole) {
        view.accessibilityViewIsModal = role == .dialog || role == .menu
        UIAccessibility.post(notification: .layoutChanged, argument: view)
    }

    public func restoreFocus() {
        guard let previousFocusedView else { return }
        UIAccessibility.post(notification: .layoutChanged, argument: previousFocusedView)
        self.previousFocusedView = nil
    }
}

public enum PTOverlayKeyboardPolicy: Sendable {
    case avoid
    case dismiss
    case ignore
}

@MainActor
public final class PTOverlayKeyboardCoordinator {
    public typealias Handler = @MainActor @Sendable (CGRect?) -> Void

    private var observers: [NSObjectProtocol] = []
    private let handler: Handler

    public init(handler: @escaping Handler) {
        self.handler = handler
    }

    public func start() {
        guard observers.isEmpty else { return }
        let center = NotificationCenter.default
        let names: [Notification.Name] = [
            UIResponder.keyboardWillChangeFrameNotification,
            UIResponder.keyboardWillHideNotification
        ]
        observers = names.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in
                guard self != nil else { return }
                let frame = name == UIResponder.keyboardWillHideNotification
                    ? nil
                    : (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
                Task { @MainActor [weak self] in
                    self?.handler(frame)
                }
            }
        }
    }

    public func stop() {
        let center = NotificationCenter.default
        observers.forEach(center.removeObserver)
        observers.removeAll(keepingCapacity: false)
    }

}

@MainActor
public final class PTOverlayHitRegionCoordinator {
    public var excludedRegions: [PTExcludedHitRegion] = []

    public init() {}

    public func containsExcludedRegion(point: CGPoint, in window: UIWindow) -> Bool {
        excludedRegions.contains { $0.contains(point, in: window) }
    }
}
