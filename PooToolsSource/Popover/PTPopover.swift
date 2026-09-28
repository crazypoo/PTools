// English: UIKit-native anchored popovers built on the shared OverlayCore 2.0.
// Español: Popovers nativos de UIKit basados en el OverlayCore 2.0 compartido.
// 中文：基于共享 OverlayCore 2.0 的 UIKit 原生锚点浮层。

import UIKit
#if canImport(PToolsCore)
import PToolsCore
#endif
#if canImport(PToolsOverlay)
import PToolsOverlay
#endif
#if canImport(PToolsSymbols)
import PToolsSymbols
#endif

@MainActor
public enum PTOverlayBackground {
    case clear
    case solid(UIColor)
    case material(UIBlurEffect.Style)
}

@MainActor
public struct PTPopoverAppearance {
    public var background: PTOverlayBackground
    public var cornerRadius: CGFloat
    public var borderColor: UIColor?
    public var borderWidth: CGFloat
    public var shadowColor: UIColor
    public var shadowOpacity: Float
    public var shadowRadius: CGFloat
    public var shadowOffset: CGSize
    public var contentInsets: UIEdgeInsets
    public var arrow: PTArrowAppearance

    public init(background: PTOverlayBackground = .material(.systemMaterial),
                cornerRadius: CGFloat = 14,
                borderColor: UIColor? = nil,
                borderWidth: CGFloat = 0,
                shadowColor: UIColor = .black,
                shadowOpacity: Float = 0.16,
                shadowRadius: CGFloat = 18,
                shadowOffset: CGSize = CGSize(width: 0, height: 8),
                contentInsets: UIEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12),
                arrow: PTArrowAppearance = PTArrowAppearance()) {
        self.background = background
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.shadowColor = shadowColor
        self.shadowOpacity = shadowOpacity
        self.shadowRadius = shadowRadius
        self.shadowOffset = shadowOffset
        self.contentInsets = contentInsets
        self.arrow = arrow
    }
}

@MainActor
public enum PTPopoverSizePolicy {
    case intrinsic
    case fixed(CGSize)
    case width(CGFloat)
    case constrained(maxWidth: CGFloat?, maxHeight: CGFloat?)
    case custom(@MainActor (CGSize) -> CGSize)
}

@MainActor
public enum PTPopoverContent {
    case view(@MainActor @Sendable () -> UIView)
    case viewController(@MainActor @Sendable () -> UIViewController)
    case menu(PTContextMenu)
}

@MainActor
public struct PTPopoverConfiguration {
    public var placement: PTPopoverPlacement
    public var alignment: PTPopoverAlignment
    public var attachment: PTPopoverAttachment
    public var anchorInsets: UIEdgeInsets
    public var screenEdgeInsets: UIEdgeInsets
    public var sizePolicy: PTPopoverSizePolicy
    public var appearance: PTPopoverAppearance
    public var transition: PTOverlayTransition
    public var outsideTapBehavior: PTOutsideTapBehavior
    public var outsideTapScope: PTOutsideTapScope
    public var trackingPolicy: PTAnchorTrackingPolicy
    public var anchorVisibility: PTAnchorVisibilityPolicy
    public var keyboardPolicy: PTOverlayKeyboardPolicy
    public var dragBehavior: PTOverlayDragBehavior
    public var dragDismissDirection: PTOverlayDragDismissDirection
    public var accessibilityRole: PTOverlayAccessibilityRole
    public var overlayLayer: PTOverlayLayer
    public var exclusivityPolicy: PTOverlayExclusivityPolicy
    public var maxMenuHeight: CGFloat
    public var excludedHitRegions: [PTExcludedHitRegion]

    public init(placement: PTPopoverPlacement = .automatic,
                alignment: PTPopoverAlignment = .center,
                attachment: PTPopoverAttachment = .automatic,
                anchorInsets: UIEdgeInsets = .zero,
                screenEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12),
                sizePolicy: PTPopoverSizePolicy = .intrinsic,
                appearance: PTPopoverAppearance = PTPopoverAppearance(),
                transition: PTOverlayTransition = .scale,
                outsideTapBehavior: PTOutsideTapBehavior = .dismiss,
                outsideTapScope: PTOutsideTapScope = .outsideSelf,
                trackingPolicy: PTAnchorTrackingPolicy = .layoutChanges,
                anchorVisibility: PTAnchorVisibilityPolicy = .dismissWhenOffscreen,
                keyboardPolicy: PTOverlayKeyboardPolicy = .avoid,
                dragBehavior: PTOverlayDragBehavior = .disabled,
                dragDismissDirection: PTOverlayDragDismissDirection = .none,
                accessibilityRole: PTOverlayAccessibilityRole = .menu,
                overlayLayer: PTOverlayLayer = .popover,
                exclusivityPolicy: PTOverlayExclusivityPolicy = .none,
                maxMenuHeight: CGFloat = 420,
                excludedHitRegions: [PTExcludedHitRegion] = []) {
        self.placement = placement
        self.alignment = alignment
        self.attachment = attachment
        self.anchorInsets = anchorInsets
        self.screenEdgeInsets = screenEdgeInsets
        self.sizePolicy = sizePolicy
        self.appearance = appearance
        self.transition = transition
        self.outsideTapBehavior = outsideTapBehavior
        self.outsideTapScope = outsideTapScope
        self.trackingPolicy = trackingPolicy
        self.anchorVisibility = anchorVisibility
        self.keyboardPolicy = keyboardPolicy
        self.dragBehavior = dragBehavior
        self.dragDismissDirection = dragDismissDirection
        self.accessibilityRole = accessibilityRole
        self.overlayLayer = overlayLayer
        self.exclusivityPolicy = exclusivityPolicy
        self.maxMenuHeight = maxMenuHeight
        self.excludedHitRegions = excludedHitRegions
    }

    public static var menu: PTPopoverConfiguration {
        PTPopoverConfiguration(appearance: PTPopoverAppearance(background: .material(.systemMaterial)))
    }
}

@MainActor
public final class PTPopover {
    public let id: PTOverlayID
    public var groupID: PTOverlayGroupID?
    public var content: PTPopoverContent
    public var configuration: PTPopoverConfiguration
    public var onContextChange: (@MainActor @Sendable (PTPopoverContext) -> Void)?

    public init(id: PTOverlayID = PTOverlayID(),
                groupID: PTOverlayGroupID? = nil,
                content: PTPopoverContent,
                configuration: PTPopoverConfiguration = PTPopoverConfiguration()) {
        self.id = id
        self.groupID = groupID
        self.content = content
        self.configuration = configuration
    }
}

public enum PTPopoverPresentationError: Error, Sendable {
    case anchorUnavailable
    case anchorNotInWindow
    case sceneUnavailable
    case hostUnavailable
    case invalidContentSize
}

@MainActor
public final class PTPopoverHandle {
    public let id: PTOverlayID
    public var state: PTOverlayState { overlayHandle.state }

    fileprivate let overlayHandle: PTOverlayHandle
    fileprivate weak var center: PTPopoverCenter?

    fileprivate init(overlayHandle: PTOverlayHandle, center: PTPopoverCenter) {
        self.id = overlayHandle.id
        self.overlayHandle = overlayHandle
        self.center = center
    }

    public func dismiss() {
        overlayHandle.dismiss()
    }

    public func update(content: PTPopoverContent) {
        center?.update(content: content, id: id)
    }

    public func reposition() {
        center?.reposition(id: id, animated: true)
    }

    public func replace(with popover: PTPopover, from anchor: PTAnchor) -> PTPopoverHandle? {
        center?.replace(id: id, with: popover, anchor: anchor)
    }
}

@MainActor
public final class PTPopoverCenter {
    public static let shared = PTPopoverCenter()

    private final class Record {
        let popover: PTPopover
        let anchor: PTAnchor
        let host: PTOverlayHost
        let surface: PTPopoverSurfaceView
        let overlayHandle: PTOverlayHandle
        let focusCoordinator: PTOverlayFocusCoordinator
        let keyboardCoordinator: PTOverlayKeyboardCoordinator
        let lifecycle: PTOverlayLifecycle
        var gestureCoordinator: PTOverlayGestureCoordinator?
        let anchorView: UIView?
        let anchorBusinessID: AnyHashable?
        var contentController: UIViewController?
        var parentController: UIViewController?
        var keyboardFrame: CGRect?
        var geometry: PTOverlayGeometry?
        var displayLink: CADisplayLink?
        var dragStartFrame: CGRect = .zero

        init(popover: PTPopover,
             anchor: PTAnchor,
             host: PTOverlayHost,
             surface: PTPopoverSurfaceView,
             overlayHandle: PTOverlayHandle,
             focusCoordinator: PTOverlayFocusCoordinator,
             keyboardCoordinator: PTOverlayKeyboardCoordinator,
             lifecycle: PTOverlayLifecycle,
             anchorView: UIView?,
             anchorBusinessID: AnyHashable?) {
            self.popover = popover
            self.anchor = anchor
            self.host = host
            self.surface = surface
            self.overlayHandle = overlayHandle
            self.focusCoordinator = focusCoordinator
            self.keyboardCoordinator = keyboardCoordinator
            self.lifecycle = lifecycle
            self.anchorView = anchorView
            self.anchorBusinessID = anchorBusinessID
        }
    }

    private var records: [PTOverlayID: Record] = [:]

    private init() {}

    @discardableResult
    public func present(_ popover: PTPopover,
                        from anchor: PTAnchor,
                        context: PTOverlayPresentationContext = .automatic) -> PTPopoverHandle? {
        guard let resolved = resolve(anchor, context: context) else { return nil }
        if let groupID = popover.groupID {
            records.values.filter { $0.popover.groupID == groupID }.forEach { dismiss(id: $0.popover.id, reason: .replaced) }
        }
        applyExclusivityPolicy(for: popover, in: resolved.window.windowScene)

        guard let host = PTOverlayHost(context: .window(resolved.window), mode: .attached, layer: popover.configuration.overlayLayer) else {
            return nil
        }
        let surface = PTPopoverSurfaceView(appearance: popover.configuration.appearance)
        surface.accessibilityViewIsModal = popover.configuration.accessibilityRole == .dialog || popover.configuration.accessibilityRole == .menu
        host.addOverlayView(surface)

        let overlayHandle = PTOverlayHandle(id: popover.id,
                                             dismissAction: { [weak self] in
                                                 self?.dismiss(id: popover.id)
                                             },
                                             updateAction: { [weak self] in
                                                 self?.reposition(id: popover.id, animated: true)
                                             })
        let focusCoordinator = PTOverlayFocusCoordinator()
        let keyboardCoordinator = PTOverlayKeyboardCoordinator { [weak self, weak overlayHandle] frame in
            guard let self, overlayHandle != nil else { return }
            guard let record = self.records[popover.id] else { return }
            record.keyboardFrame = frame
            self.reposition(id: popover.id, animated: true)
        }
        guard let scene = resolved.window.windowScene else {
            host.detach()
            return nil
        }
        let lifecycle = PTOverlayLifecycle(scene: scene) { [weak self] event in
            if event == .didDisconnect {
                self?.dismiss(id: popover.id, reason: .sceneDisconnected)
            }
        }
        let record = Record(popover: popover,
                            anchor: anchor,
                            host: host,
                            surface: surface,
                            overlayHandle: overlayHandle,
                            focusCoordinator: focusCoordinator,
                            keyboardCoordinator: keyboardCoordinator,
                            lifecycle: lifecycle,
                            anchorView: resolved.view,
                            anchorBusinessID: resolved.businessID)
        records[popover.id] = record
        overlayHandle.setState(.preparing)
        overlayHandle.setState(.presenting)

        if !installContent(for: record) {
            records.removeValue(forKey: popover.id)
            host.removeOverlayView(surface)
            host.detach()
            return nil
        }

        configureActions(for: record, context: context)
        configureDrag(for: record)
        reposition(id: popover.id, animated: false)
        keyboardCoordinator.start()
        focusCoordinator.captureFocus()
        focusCoordinator.focus(surface, role: popover.configuration.accessibilityRole)
        startTracking(record)

        let animator = PTOverlayAnimator()
        surface.alpha = 0
        animator.present(view: surface, transition: popover.configuration.transition) { [weak self, weak overlayHandle] in
            guard let self, let overlayHandle, self.records[popover.id] != nil else { return }
            overlayHandle.setState(.visible)
        }
        register(record, scene: resolved.window.windowScene)
        return PTPopoverHandle(overlayHandle: overlayHandle, center: self)
    }

    public func dismiss(id: PTOverlayID, reason: PTOverlayDismissReason = .manual) {
        guard let record = records[id] else { return }
        record.overlayHandle.setState(.dismissing)
        record.displayLink?.invalidate()
        record.displayLink = nil
        record.keyboardCoordinator.stop()
        record.focusCoordinator.restoreFocus()
        removeContentController(from: record)
        let animator = PTOverlayAnimator()
        animator.dismiss(view: record.surface, transition: record.popover.configuration.transition) { [weak self, weak record] in
            guard let self, let record else { return }
            record.host.removeOverlayView(record.surface)
            record.host.containerView.customHitTest = nil
            record.host.detach()
            record.overlayHandle.setState(.dismissed)
            record.overlayHandle.invalidate()
            self.records.removeValue(forKey: id)
            if let scene = record.host.window?.windowScene {
                PTOverlayRegistryStore.shared.registry(for: scene).remove(id: id)
            }
        }
        if reason == .sceneDisconnected {
            animator.stop()
            record.surface.removeFromSuperview()
        }
    }

    public func dismissAll() {
        Array(records.keys).forEach { dismiss(id: $0) }
    }

    fileprivate func update(content: PTPopoverContent, id: PTOverlayID) {
        guard let record = records[id] else { return }
        removeContentController(from: record)
        record.popover.content = content
        guard installContent(for: record) else {
            dismiss(id: id)
            return
        }
        reposition(id: id, animated: true)
    }

    fileprivate func reposition(id: PTOverlayID, animated: Bool) {
        guard let record = records[id], let resolved = resolve(record.anchor, context: .window(record.host.window ?? UIWindow())) else {
            if records[id]?.popover.configuration.anchorVisibility == .dismissWhenOffscreen { dismiss(id: id) }
            return
        }
        guard PTAnchorIdentityValidator.matches(resolved,
                                                view: record.anchorView,
                                                businessID: record.anchorBusinessID) else {
            dismiss(id: id, reason: .anchorLost)
            return
        }
        guard let geometry = geometry(for: record, resolved: resolved) else { return }
        record.geometry = geometry
        let apply = {
            record.surface.frame = geometry.frame
            record.surface.apply(geometry: geometry, placement: geometry.placement)
            let context = PTPopoverContext(overlayID: id,
                                            geometry: geometry,
                                            anchorFrame: resolved.rect,
                                            availableBounds: self.availableBounds(for: record, window: resolved.window),
                                            safeAreaInsets: record.host.safeAreaContext.safeAreaInsets,
                                            keyboardFrame: record.keyboardFrame)
            record.popover.onContextChange?(context)
        }
        if animated && !UIAccessibility.isReduceMotionEnabled {
            UIView.animate(withDuration: 0.2, animations: apply)
        } else {
            apply()
        }
    }

    fileprivate func replace(id: PTOverlayID, with popover: PTPopover, anchor: PTAnchor) -> PTPopoverHandle? {
        dismiss(id: id, reason: .replaced)
        return present(popover, from: anchor)
    }

    private func resolve(_ anchor: PTAnchor,
                         context: PTOverlayPresentationContext) -> PTAnchorResolver.Resolved? {
        guard case let .success(resolved) = PTAnchorResolver.resolve(anchor, context: context) else { return nil }
        return resolved
    }

    private func installContent(for record: Record) -> Bool {
        switch record.popover.content {
        case let .view(builder):
            let view = builder()
            record.surface.setContentView(view)
        case let .viewController(builder):
            let controller = builder()
            guard let parent = parentController(for: record) else {
                record.surface.setContentView(controller.view)
                record.contentController = controller
                return true
            }
            parent.addChild(controller)
            record.surface.setContentView(controller.view)
            controller.didMove(toParent: parent)
            record.contentController = controller
            record.parentController = parent
        case let .menu(menu):
            let view = PTContextMenuView(menu: menu,
                                         maxHeight: record.popover.configuration.maxMenuHeight)
            view.onSelect = { item in
                PTFeedbackCenter.shared.emit(item.state == .destructive ? .destructive : .selectionChanged)
                item.action()
            }
            record.surface.setContentView(view)
        }
        return record.surface.contentView != nil
    }

    private func removeContentController(from record: Record) {
        guard let controller = record.contentController else { return }
        controller.willMove(toParent: nil)
        controller.view.removeFromSuperview()
        controller.removeFromParent()
        record.contentController = nil
        record.parentController = nil
    }

    private func parentController(for record: Record) -> UIViewController? {
        guard let window = record.host.window else { return nil }
        return window.rootViewController
    }

    private func geometry(for record: Record,
                          resolved: PTAnchorResolver.Resolved) -> PTOverlayGeometry? {
        let configuration = record.popover.configuration
        let available = availableBounds(for: record, window: resolved.window)
        var anchorRect = resolved.rect
        switch configuration.anchorVisibility {
        case .dismissWhenOffscreen:
            guard available.insetBy(dx: -1, dy: -1).intersects(anchorRect) else {
                dismiss(id: record.popover.id)
                return nil
            }
        case .pinToVisibleBounds:
            anchorRect = visibleAnchorRect(anchorRect, in: available)
        case .keepPresented:
            break
        }
        let size = measuredSize(for: record.surface,
                                configuration: configuration,
                                availableBounds: available)
        guard size.width > 0, size.height > 0 else { return nil }
        let anchor = anchorRect.inset(by: configuration.anchorInsets)
        return PTPopoverPositioningEngine.resolve(anchorRect: anchor,
                                                  contentSize: size,
                                                  availableBounds: available,
                                                  preferredPlacement: configuration.placement,
                                                  alignment: configuration.alignment,
                                                  attachment: configuration.attachment,
                                                  arrow: configuration.appearance.arrow,
                                                  minimumSize: CGSize(width: 44, height: 32))
    }

    private func measuredSize(for surface: PTPopoverSurfaceView,
                              configuration: PTPopoverConfiguration,
                              availableBounds: CGRect) -> CGSize {
        let intrinsic = surface.measuredContentSize(maximum: availableBounds.size)
        switch configuration.sizePolicy {
        case .intrinsic:
            return intrinsic
        case let .fixed(size):
            return size
        case let .width(width):
            return CGSize(width: min(width, availableBounds.width), height: intrinsic.height)
        case let .constrained(maxWidth, maxHeight):
            return CGSize(width: min(maxWidth ?? intrinsic.width, availableBounds.width),
                          height: min(maxHeight ?? intrinsic.height, availableBounds.height))
        case let .custom(provider):
            return provider(intrinsic)
        }
    }

    private func availableBounds(for record: Record, window: UIWindow) -> CGRect {
        PTScreenCollisionResolver.availableBounds(for: window,
                                                  edgeInsets: record.popover.configuration.screenEdgeInsets,
                                                  keyboardFrame: record.keyboardFrame,
                                                  keyboardPolicy: record.popover.configuration.keyboardPolicy)
    }

    private func configureActions(for record: Record, context: PTOverlayPresentationContext) {
        let container = record.host.containerView
        container.hitTestPolicy = .custom
        container.customHitTest = { [weak self, weak record, weak container] point, event in
            guard let self, let record, let container else { return nil }
            let excluded = record.popover.configuration.excludedHitRegions.contains { $0.contains(point, in: record.host.window ?? UIWindow()) }
            let surfacePoint = record.surface.convert(point, from: container)
            if record.surface.bounds.contains(surfacePoint) {
                return record.surface.hitTest(surfacePoint, with: event)
            }
            if excluded { return nil }
            switch record.popover.configuration.outsideTapBehavior {
            case .ignore:
                return container
            case .dismiss, .dismissAndConsume:
                self.dismissForOutsideTap(record)
                return container
            case .dismissAndPassthrough:
                self.dismissForOutsideTap(record)
                return nil
            }
        }
    }

    // English: Map outside taps to the configured overlay scope without changing the shared window hit-test path.
    // Español: Aplica el alcance configurado del toque exterior sin cambiar el hit-test compartido de la ventana.
    // 中文：在不改变共享 Window 命中测试的前提下，按配置范围处理点击浮层外部的行为。
    private func dismissForOutsideTap(_ record: Record) {
        let scene = record.host.window?.windowScene
        let sameScene = records.values.filter { $0.host.window?.windowScene === scene }
        let targets: [Record]
        switch record.popover.configuration.outsideTapScope {
        case .outsideSelf:
            targets = [record]
        case .outsideGroup:
            guard let groupID = record.popover.groupID else {
                targets = [record]
                break
            }
            targets = sameScene.filter { $0.popover.groupID == groupID }
        case .outsideAllOverlays:
            targets = sameScene
        }
        targets.forEach { dismiss(id: $0.popover.id) }
    }

    // English: Clamp an offscreen anchor to the nearest usable point for pin-to-visible-bounds behavior.
    // Español: Ajusta un anclaje fuera de pantalla al punto utilizable más cercano para fijarlo a los límites visibles.
    // 中文：为 pinToVisibleBounds 将屏幕外锚点限制到最近的可用位置。
    private func visibleAnchorRect(_ rect: CGRect, in bounds: CGRect) -> CGRect {
        guard !bounds.isEmpty else { return rect }
        if rect.intersects(bounds) {
            return rect.intersection(bounds)
        }
        let x = min(max(rect.midX, bounds.minX), bounds.maxX)
        let y = min(max(rect.midY, bounds.minY), bounds.maxY)
        return CGRect(origin: CGPoint(x: x, y: y), size: .zero)
    }

    // English: Apply product-level exclusivity while keeping ownership in the shared overlay center.
    // Español: Aplica la exclusividad del producto manteniendo la propiedad en el centro de overlays compartido.
    // 中文：由共享浮层中心统一执行产品级互斥策略。
    private func applyExclusivityPolicy(for popover: PTPopover, in scene: UIWindowScene?) {
        let candidates = records.values.filter { $0.host.window?.windowScene === scene }
        switch popover.configuration.exclusivityPolicy {
        case .none:
            break
        case .dismissLowerTransient:
            candidates
                .filter { $0.popover.configuration.overlayLayer.rawValue < popover.configuration.overlayLayer.rawValue }
                .forEach { dismiss(id: $0.popover.id, reason: .replaced) }
        case .dismissSameGroup:
            guard let groupID = popover.groupID else { return }
            candidates
                .filter { $0.popover.groupID == groupID }
                .forEach { dismiss(id: $0.popover.id, reason: .replaced) }
        }
    }

    private func configureDrag(for record: Record) {
        guard record.popover.configuration.dragBehavior != .disabled else { return }
        let coordinator = PTOverlayGestureCoordinator()
        coordinator.dragBehavior = record.popover.configuration.dragBehavior
        coordinator.scrollView = record.surface.subviews.compactMap { $0 as? UIScrollView }.first
        _ = coordinator.attachPan(to: record.surface) { [weak self, weak record] gesture in
            guard let self, let record else { return }
            self.handleDrag(gesture, for: record)
        }
        record.gestureCoordinator = coordinator
    }

    private func handleDrag(_ gesture: UIPanGestureRecognizer, for record: Record) {
        let container = record.host.containerView
        switch gesture.state {
        case .began:
            record.dragStartFrame = record.surface.frame
        case .changed:
            let translation = gesture.translation(in: container)
            var frame = record.dragStartFrame.offsetBy(dx: translation.x, dy: translation.y)
            let bounds = availableBounds(for: record, window: record.host.window ?? UIWindow())
            frame.origin.x = min(max(frame.origin.x, bounds.minX), max(bounds.minX, bounds.maxX - frame.width))
            frame.origin.y = min(max(frame.origin.y, bounds.minY), max(bounds.minY, bounds.maxY - frame.height))
            record.surface.frame = frame
        case .ended, .cancelled, .failed:
            let translation = gesture.translation(in: container)
            if shouldDismiss(translation: translation,
                             direction: record.popover.configuration.dragDismissDirection,
                             layoutDirection: container.effectiveUserInterfaceLayoutDirection) {
                dismiss(id: record.popover.id)
            } else {
                reposition(id: record.popover.id, animated: true)
            }
        default:
            break
        }
    }

    private func shouldDismiss(translation: CGPoint,
                               direction: PTOverlayDragDismissDirection,
                               layoutDirection: UIUserInterfaceLayoutDirection) -> Bool {
        let threshold: CGFloat = 80
        switch direction {
        case .none:
            return false
        case .up:
            return translation.y <= -threshold
        case .down:
            return translation.y >= threshold
        case .leading:
            return layoutDirection == .rightToLeft ? translation.x >= threshold : translation.x <= -threshold
        case .trailing:
            return layoutDirection == .rightToLeft ? translation.x <= -threshold : translation.x >= threshold
        case .any:
            return max(abs(translation.x), abs(translation.y)) >= threshold
        }
    }

    private func register(_ record: Record, scene: UIWindowScene?) {
        guard let scene else { return }
        PTOverlayRegistryStore.shared.registry(for: scene).register(record.host, id: record.popover.id)
    }

    private func startTracking(_ record: Record) {
        guard record.popover.configuration.trackingPolicy == .continuousWhileVisible else { return }
        let displayLink = CADisplayLink(target: DisplayLinkProxy { [weak self, weak record] in
            guard let self, let record else { return }
            self.reposition(id: record.popover.id, animated: false)
        }, selector: #selector(DisplayLinkProxy.fire))
        displayLink.add(to: .main, forMode: .common)
        record.displayLink = displayLink
    }
}

@MainActor
private final class DisplayLinkProxy: NSObject {
    private let action: @MainActor () -> Void

    init(_ action: @escaping @MainActor () -> Void) {
        self.action = action
    }

    @objc func fire() {
        action()
    }
}

@MainActor
public final class PTPopoverSurfaceView: UIView {
    public private(set) var contentView: UIView?

    private let contentContainer = UIView()
    private let backgroundLayer = CAShapeLayer()
    private var blurView: UIVisualEffectView?
    private var appearance: PTPopoverAppearance
    private var currentGeometry: PTOverlayGeometry?
    private var currentPlacement: PTPopoverPlacement = .bottom

    public init(appearance: PTPopoverAppearance) {
        self.appearance = appearance
        super.init(frame: .zero)
        isUserInteractionEnabled = true
        backgroundColor = .clear
        layer.addSublayer(backgroundLayer)
        addSubview(contentContainer)
        updateAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    public func setContentView(_ view: UIView) {
        contentView?.removeFromSuperview()
        contentView = view
        view.translatesAutoresizingMaskIntoConstraints = true
        contentContainer.addSubview(view)
        setNeedsLayout()
    }

    public func measuredContentSize(maximum: CGSize) -> CGSize {
        guard let contentView else { return CGSize(width: 1, height: 1) }
        let available = CGSize(width: max(1, maximum.width - appearance.contentInsets.left - appearance.contentInsets.right),
                               height: max(1, maximum.height - appearance.contentInsets.top - appearance.contentInsets.bottom))
        let fitting = contentView.systemLayoutSizeFitting(available,
                                                           withHorizontalFittingPriority: .fittingSizeLevel,
                                                           verticalFittingPriority: .fittingSizeLevel)
        let intrinsic = contentView.intrinsicContentSize
        let width = fitting.width > 0 ? fitting.width : intrinsic.width
        let height = fitting.height > 0 ? fitting.height : intrinsic.height
        return CGSize(width: max(1, width), height: max(1, height))
    }

    public func apply(geometry: PTOverlayGeometry, placement: PTPopoverPlacement) {
        currentGeometry = geometry
        currentPlacement = placement
        setNeedsLayout()
        layoutIfNeeded()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        backgroundLayer.frame = bounds
        // English: Keep the content hit-test hierarchy aligned with the surface bounds.
        // Español: Mantén la jerarquía de hit-test del contenido alineada con los límites de la superficie.
        // 中文：让内容命中测试层级始终与浮层表面边界一致。
        contentContainer.frame = bounds
        let arrowHeight = appearance.arrow.isVisible ? appearance.arrow.size.height : 0
        var contentFrame = bounds.inset(by: appearance.contentInsets)
        switch currentPlacement {
        case .bottom, .bottomLeading, .bottomTrailing:
            contentFrame.origin.y += arrowHeight
            contentFrame.size.height = max(0, contentFrame.height - arrowHeight)
        case .top, .topLeading, .topTrailing:
            contentFrame.size.height = max(0, contentFrame.height - arrowHeight)
        case .leading:
            contentFrame.origin.x += arrowHeight
            contentFrame.size.width = max(0, contentFrame.width - arrowHeight)
        case .trailing:
            contentFrame.size.width = max(0, contentFrame.width - arrowHeight)
        case .automatic:
            break
        }
        contentView?.frame = contentFrame
        if let currentGeometry {
            backgroundLayer.path = surfacePath(for: currentGeometry, placement: currentPlacement).cgPath
            layer.shadowPath = backgroundLayer.path
        }
    }

    private func updateAppearance() {
        backgroundLayer.fillColor = appearanceFillColor().cgColor
        backgroundLayer.strokeColor = appearance.borderColor?.cgColor
        backgroundLayer.lineWidth = appearance.borderWidth
        layer.shadowColor = appearance.shadowColor.cgColor
        layer.shadowOpacity = appearance.shadowOpacity
        layer.shadowRadius = appearance.shadowRadius
        layer.shadowOffset = appearance.shadowOffset
        if case let .material(style) = appearance.background, !UIAccessibility.isReduceTransparencyEnabled {
            let blur = UIVisualEffectView(effect: UIBlurEffect(style: style))
            blur.frame = bounds
            blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            insertSubview(blur, at: 0)
            blurView = blur
        }
    }

    private func appearanceFillColor() -> UIColor {
        switch appearance.background {
        case .clear: return .clear
        case let .solid(color): return color
        case .material: return UIColor.secondarySystemBackground.withAlphaComponent(0.92)
        }
    }

    private func surfacePath(for geometry: PTOverlayGeometry,
                             placement: PTPopoverPlacement) -> UIBezierPath {
        let radius = min(appearance.cornerRadius, min(bounds.width, bounds.height) / 2)
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: radius)
        guard appearance.arrow.isVisible, let arrowPoint = geometry.arrowPoint else { return path }
        let arrow = appearance.arrow
        let half = arrow.size.width / 2
        let triangle: UIBezierPath
        switch placement {
        case .bottom, .bottomLeading, .bottomTrailing:
            triangle = UIBezierPath(ptPoints: [CGPoint(x: arrowPoint.x - half, y: arrowPoint.y),
                                              CGPoint(x: arrowPoint.x, y: arrowPoint.y - arrow.size.height),
                                              CGPoint(x: arrowPoint.x + half, y: arrowPoint.y)])
        case .top, .topLeading, .topTrailing:
            triangle = UIBezierPath(ptPoints: [CGPoint(x: arrowPoint.x - half, y: arrowPoint.y),
                                              CGPoint(x: arrowPoint.x, y: arrowPoint.y + arrow.size.height),
                                              CGPoint(x: arrowPoint.x + half, y: arrowPoint.y)])
        case .leading:
            triangle = UIBezierPath(ptPoints: [CGPoint(x: arrowPoint.x, y: arrowPoint.y - half),
                                              CGPoint(x: arrowPoint.x - arrow.size.height, y: arrowPoint.y),
                                              CGPoint(x: arrowPoint.x, y: arrowPoint.y + half)])
        case .trailing:
            triangle = UIBezierPath(ptPoints: [CGPoint(x: arrowPoint.x, y: arrowPoint.y - half),
                                              CGPoint(x: arrowPoint.x + arrow.size.height, y: arrowPoint.y),
                                              CGPoint(x: arrowPoint.x, y: arrowPoint.y + half)])
        case .automatic:
            return path
        }
        path.append(triangle)
        return path
    }
}

private extension UIBezierPath {
    convenience init(ptPoints points: [CGPoint]) {
        self.init()
        guard let first = points.first else { return }
        move(to: first)
        points.dropFirst().forEach { addLine(to: $0) }
        close()
    }
}
