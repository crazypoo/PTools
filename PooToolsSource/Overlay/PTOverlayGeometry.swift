// English: Main-actor anchor and pure value geometry contracts for OverlayCore 2.0.
// Español: Contratos de anclaje en MainActor y geometría de valores para OverlayCore 2.0.
// 中文：OverlayCore 2.0 使用的 MainActor 锚点和纯值类型几何契约。

import UIKit

// English: A stable business-facing identifier prevents reused cells from moving an old overlay.
// Español: Un identificador estable evita que una celda reutilizada mueva un overlay antiguo.
// 中文：稳定的业务标识可以避免复用 Cell 把旧浮层移动到新内容上。
public struct PTAnchorID: Hashable, Sendable {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

// English: The anchor is MainActor-isolated because UIKit objects and custom providers are UI state.
// Español: El anclaje está aislado en MainActor porque UIKit y los proveedores personalizados son estado de UI.
// 中文：锚点隔离在 MainActor，因为 UIKit 对象和自定义提供器都属于 UI 状态。
@MainActor
public enum PTAnchor {
    case view(UIView)
    case rect(CGRect, in: UIView)
    case point(CGPoint, in: UIView)
    case windowRect(CGRect, in: UIWindow)
    case barButtonItem(UIBarButtonItem)
    case registered(PTAnchorID)
    case custom(@MainActor () -> CGRect?)
}

// English: The registry keeps only weak views so anchors cannot retain cells or controllers.
// Español: El registro solo conserva vistas débiles para no retener celdas ni controladores.
// 中文：注册表只保存弱引用，避免锚点长期持有 Cell 或控制器。
@MainActor
public final class PTAnchorRegistry {
    public static let shared = PTAnchorRegistry()

    private final class Entry {
        weak var view: UIView?
        let businessID: AnyHashable?

        init(view: UIView, businessID: AnyHashable?) {
            self.view = view
            self.businessID = businessID
        }
    }

    private var entries: [PTAnchorID: Entry] = [:]

    private init() {}

    public func register(_ id: PTAnchorID, view: UIView, businessID: AnyHashable? = nil) {
        entries[id] = Entry(view: view, businessID: businessID)
    }

    public func unregister(_ id: PTAnchorID) {
        entries.removeValue(forKey: id)
    }

    public func view(for id: PTAnchorID) -> UIView? {
        guard let entry = entries[id], entry.view != nil else {
            entries.removeValue(forKey: id)
            return nil
        }
        return entry.view
    }

    public func businessID(for id: PTAnchorID) -> AnyHashable? {
        entries[id]?.businessID
    }
}

public enum PTAnchorTrackingPolicy: Sendable {
    case staticAtPresentation
    case layoutChanges
    case continuousWhileVisible
}

public enum PTAnchorVisibilityPolicy: Sendable {
    case keepPresented
    case dismissWhenOffscreen
    case pinToVisibleBounds
}

@MainActor
public enum PTAnchorResolver {
    public struct Resolved {
        public let rect: CGRect
        public let window: UIWindow
        public let view: UIView?
        public let businessID: AnyHashable?

        public init(rect: CGRect,
                    window: UIWindow,
                    view: UIView? = nil,
                    businessID: AnyHashable? = nil) {
            self.rect = rect
            self.window = window
            self.view = view
            self.businessID = businessID
        }
    }

    public enum Failure: Error, Sendable {
        case anchorUnavailable
        case anchorNotInWindow
        case sceneUnavailable
    }

    public static func resolve(_ anchor: PTAnchor,
                               context: PTOverlayPresentationContext = .automatic) -> Result<Resolved, Failure> {
        switch anchor {
        case let .view(view):
            guard let window = view.window else { return .failure(.anchorNotInWindow) }
            return .success(Resolved(rect: view.convert(view.bounds, to: window),
                                     window: window,
                                     view: view))
        case let .rect(rect, sourceView):
            guard let window = sourceView.window else { return .failure(.anchorNotInWindow) }
            return .success(Resolved(rect: sourceView.convert(rect, to: window), window: window, view: sourceView))
        case let .point(point, sourceView):
            guard let window = sourceView.window else { return .failure(.anchorNotInWindow) }
            let converted = sourceView.convert(point, to: window)
            return .success(Resolved(rect: CGRect(origin: converted, size: .zero), window: window, view: sourceView))
        case let .windowRect(rect, window):
            guard window.windowScene != nil else { return .failure(.sceneUnavailable) }
            return .success(Resolved(rect: rect, window: window))
        case let .barButtonItem(item):
            guard let view = item.customView else { return .failure(.anchorUnavailable) }
            return resolve(.view(view), context: context)
        case let .registered(id):
            guard let view = PTAnchorRegistry.shared.view(for: id) else { return .failure(.anchorUnavailable) }
            let result = resolve(.view(view), context: context)
            guard case let .success(value) = result else { return result }
            return .success(Resolved(rect: value.rect,
                                     window: value.window,
                                     view: value.view,
                                     businessID: PTAnchorRegistry.shared.businessID(for: id)))
        case let .custom(provider):
            guard let rect = provider(), let window = PTOverlaySceneResolver.window(for: context) else {
                return .failure(.anchorUnavailable)
            }
            return .success(Resolved(rect: rect, window: window))
        }
    }
}

@MainActor
public enum PTAnchorIdentityValidator {
    public static func matches(_ resolved: PTAnchorResolver.Resolved,
                               view: UIView?,
                               businessID: AnyHashable?) -> Bool {
        guard resolved.view === view else { return false }
        return resolved.businessID == businessID
    }
}

public enum PTPopoverPlacement: Sendable {
    case automatic
    case top
    case topLeading
    case topTrailing
    case bottom
    case bottomLeading
    case bottomTrailing
    case leading
    case trailing
}

public enum PTPopoverAlignment: Sendable {
    case leading
    case center
    case trailing
}

public enum PTPopoverAttachment: Sendable {
    case automatic
    case topToBottom
    case bottomToTop
    case leadingToTrailing
    case trailingToLeading
}

public struct PTOverlayCollisionEdges: OptionSet, Sendable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let top = PTOverlayCollisionEdges(rawValue: 1 << 0)
    public static let bottom = PTOverlayCollisionEdges(rawValue: 1 << 1)
    public static let leading = PTOverlayCollisionEdges(rawValue: 1 << 2)
    public static let trailing = PTOverlayCollisionEdges(rawValue: 1 << 3)
}

public struct PTOverlayCollisionResult: Sendable {
    public let flipped: Bool
    public let shifted: Bool
    public let resized: Bool
    public let edges: PTOverlayCollisionEdges

    public init(flipped: Bool = false,
                shifted: Bool = false,
                resized: Bool = false,
                edges: PTOverlayCollisionEdges = []) {
        self.flipped = flipped
        self.shifted = shifted
        self.resized = resized
        self.edges = edges
    }
}

public struct PTOverlayGeometry: Sendable {
    public let frame: CGRect
    public let placement: PTPopoverPlacement
    public let arrowPoint: CGPoint?
    public let collision: PTOverlayCollisionResult

    public init(frame: CGRect,
                placement: PTPopoverPlacement,
                arrowPoint: CGPoint?,
                collision: PTOverlayCollisionResult) {
        self.frame = frame
        self.placement = placement
        self.arrowPoint = arrowPoint
        self.collision = collision
    }
}

@MainActor
public struct PTArrowAppearance {
    public var size: CGSize
    public var cornerRadius: CGFloat
    public var fillColor: UIColor
    public var borderColor: UIColor?
    public var borderWidth: CGFloat
    public var isVisible: Bool

    public init(size: CGSize = CGSize(width: 18, height: 9),
                cornerRadius: CGFloat = 2,
                fillColor: UIColor = .secondarySystemBackground,
                borderColor: UIColor? = nil,
                borderWidth: CGFloat = 0,
                isVisible: Bool = true) {
        self.size = size
        self.cornerRadius = cornerRadius
        self.fillColor = fillColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.isVisible = isVisible
    }
}

public struct PTArrowPlacementResult: Sendable {
    public let point: CGPoint
    public let isClamped: Bool

    public init(point: CGPoint, isClamped: Bool) {
        self.point = point
        self.isClamped = isClamped
    }
}

public enum PTArrowGeometry {
    public static func placement(anchorRect: CGRect,
                                 popoverFrame: CGRect,
                                 placement: PTPopoverPlacement,
                                 arrowSize: CGSize,
                                 cornerRadius: CGFloat,
                                 minimumInset: CGFloat = 8) -> PTArrowPlacementResult? {
        guard arrowSize.width > 0, arrowSize.height > 0 else { return nil }
        let half = arrowSize.width / 2
        switch placement {
        case .top, .topLeading, .topTrailing:
            let desired = anchorRect.midX - popoverFrame.minX
            let value = clamped(desired,
                                lower: cornerRadius + half + minimumInset,
                                upper: popoverFrame.width - cornerRadius - half - minimumInset)
            return PTArrowPlacementResult(point: CGPoint(x: value, y: popoverFrame.height), isClamped: value != desired)
        case .bottom, .bottomLeading, .bottomTrailing:
            let desired = anchorRect.midX - popoverFrame.minX
            let value = clamped(desired,
                                lower: cornerRadius + half + minimumInset,
                                upper: popoverFrame.width - cornerRadius - half - minimumInset)
            return PTArrowPlacementResult(point: CGPoint(x: value, y: 0), isClamped: value != desired)
        case .leading, .trailing:
            let desired = anchorRect.midY - popoverFrame.minY
            let value = clamped(desired,
                                lower: cornerRadius + half + minimumInset,
                                upper: popoverFrame.height - cornerRadius - half - minimumInset)
            let x = placement == .leading ? popoverFrame.width : 0
            return PTArrowPlacementResult(point: CGPoint(x: x, y: value), isClamped: value != desired)
        case .automatic:
            return nil
        }
    }

    // English: Keep the lower bound valid when a compact popover is smaller than its arrow insets.
    // Español: Mantén válido el límite inferior cuando un popover compacto sea menor que sus márgenes de flecha.
    // 中文：当紧凑弹层小于箭头内缩范围时，仍保持有效的下界，避免构造非法 ClosedRange。
    private static func clamped(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        let safeUpper = max(lower, upper)
        return min(max(value, lower), safeUpper)
    }
}

@MainActor
public enum PTScreenCollisionResolver {
    public static func availableBounds(for window: UIWindow,
                                       edgeInsets: UIEdgeInsets,
                                       keyboardFrame: CGRect? = nil,
                                       keyboardPolicy: PTOverlayKeyboardPolicy = .avoid) -> CGRect {
        var bounds = window.bounds.inset(by: edgeInsets)
        guard let keyboardFrame, keyboardPolicy == .avoid else {
            return bounds
        }
        let keyboardInWindow = window.convert(keyboardFrame, from: nil)
        guard keyboardInWindow.intersects(bounds) else { return bounds }
        bounds.size.height = max(0, keyboardInWindow.minY - bounds.minY)
        return bounds
    }
}

@MainActor
public enum PTPopoverPositioningEngine {
    public static func resolve(anchorRect: CGRect,
                               contentSize: CGSize,
                               availableBounds: CGRect,
                               preferredPlacement: PTPopoverPlacement,
                               alignment: PTPopoverAlignment = .center,
                               attachment: PTPopoverAttachment = .automatic,
                               arrow: PTArrowAppearance? = PTArrowAppearance(),
                               minimumSize: CGSize = CGSize(width: 1, height: 1)) -> PTOverlayGeometry {
        let candidates = candidatePlacements(preferredPlacement)
        let arrowHeight = arrow?.isVisible == true ? arrow?.size.height ?? 0 : 0
        let first = candidates.first ?? .bottom
        var best = proposedFrame(anchorRect: anchorRect,
                                 contentSize: contentSize,
                                 placement: first,
                                 alignment: alignment,
                                 attachment: attachment,
                                 arrowHeight: arrowHeight)
        var bestOverflow = overflow(of: best, in: availableBounds)
        var resolvedPlacement = first
        for candidate in candidates.dropFirst() {
            let frame = proposedFrame(anchorRect: anchorRect,
                                       contentSize: contentSize,
                                       placement: candidate,
                                       alignment: alignment,
                                       attachment: attachment,
                                       arrowHeight: arrowHeight)
            let candidateOverflow = overflow(of: frame, in: availableBounds)
            if candidateOverflow < bestOverflow {
                best = frame
                bestOverflow = candidateOverflow
                resolvedPlacement = candidate
            }
            if candidateOverflow == 0 { break }
        }

        let clampedWidth = min(max(best.width, minimumSize.width), max(minimumSize.width, availableBounds.width))
        let clampedHeight = min(max(best.height, minimumSize.height), max(minimumSize.height, availableBounds.height))
        var frame = CGRect(x: best.minX, y: best.minY, width: clampedWidth, height: clampedHeight)
        let originalFrame = frame
        frame.origin.x = min(max(frame.origin.x, availableBounds.minX), availableBounds.maxX - frame.width)
        frame.origin.y = min(max(frame.origin.y, availableBounds.minY), availableBounds.maxY - frame.height)

        let edges = collisionEdges(for: originalFrame, in: availableBounds)
        let collision = PTOverlayCollisionResult(
            flipped: resolvedPlacement != first,
            shifted: frame.origin != originalFrame.origin,
            resized: frame.size != originalFrame.size,
            edges: edges
        )
        let arrowPoint = PTArrowGeometry.placement(anchorRect: anchorRect,
                                                    popoverFrame: frame,
                                                    placement: resolvedPlacement,
                                                    arrowSize: arrow?.size ?? .zero,
                                                    cornerRadius: 12)?.point
        return PTOverlayGeometry(frame: frame,
                                 placement: resolvedPlacement,
                                 arrowPoint: arrowPoint,
                                 collision: collision)
    }

    private static func candidatePlacements(_ placement: PTPopoverPlacement) -> [PTPopoverPlacement] {
        switch placement {
        case .automatic:
            return [.bottom, .top, .trailing, .leading]
        case .top, .topLeading, .topTrailing:
            return [placement, .bottom, .trailing, .leading]
        case .bottom, .bottomLeading, .bottomTrailing:
            return [placement, .top, .trailing, .leading]
        case .leading:
            return [.leading, .trailing, .bottom, .top]
        case .trailing:
            return [.trailing, .leading, .bottom, .top]
        }
    }

    private static func proposedFrame(anchorRect: CGRect,
                                      contentSize: CGSize,
                                      placement: PTPopoverPlacement,
                                      alignment: PTPopoverAlignment,
                                      attachment: PTPopoverAttachment,
                                      arrowHeight: CGFloat) -> CGRect {
        let gap: CGFloat = 8
        let verticalArrow = placement == .top || placement == .topLeading || placement == .topTrailing || placement == .bottom || placement == .bottomLeading || placement == .bottomTrailing
        let width = contentSize.width
        let height = contentSize.height
        switch placement {
        case .top, .topLeading, .topTrailing:
            return CGRect(x: horizontalOrigin(anchorRect: anchorRect, width: width, alignment: alignment),
                          y: anchorRect.minY - height - gap - (verticalArrow ? arrowHeight : 0),
                          width: width,
                          height: height + (verticalArrow ? arrowHeight : 0))
        case .bottom, .bottomLeading, .bottomTrailing:
            return CGRect(x: horizontalOrigin(anchorRect: anchorRect, width: width, alignment: alignment),
                          y: anchorRect.maxY + gap,
                          width: width,
                          height: height + (verticalArrow ? arrowHeight : 0))
        case .leading:
            return CGRect(x: anchorRect.minX - width - gap - arrowHeight,
                          y: anchorRect.midY - height / 2,
                          width: width + arrowHeight,
                          height: height)
        case .trailing:
            return CGRect(x: anchorRect.maxX + gap,
                          y: anchorRect.midY - height / 2,
                          width: width + arrowHeight,
                          height: height)
        case .automatic:
            return .zero
        }
    }

    private static func horizontalOrigin(anchorRect: CGRect,
                                         width: CGFloat,
                                         alignment: PTPopoverAlignment) -> CGFloat {
        switch alignment {
        case .leading: return anchorRect.minX
        case .center: return anchorRect.midX - width / 2
        case .trailing: return anchorRect.maxX - width
        }
    }

    private static func overflow(of frame: CGRect, in bounds: CGRect) -> CGFloat {
        max(0, bounds.minX - frame.minX) + max(0, frame.maxX - bounds.maxX)
            + max(0, bounds.minY - frame.minY) + max(0, frame.maxY - bounds.maxY)
    }

    private static func collisionEdges(for frame: CGRect, in bounds: CGRect) -> PTOverlayCollisionEdges {
        var result: PTOverlayCollisionEdges = []
        if frame.minY < bounds.minY { result.insert(.top) }
        if frame.maxY > bounds.maxY { result.insert(.bottom) }
        if frame.minX < bounds.minX { result.insert(.leading) }
        if frame.maxX > bounds.maxX { result.insert(.trailing) }
        return result
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
