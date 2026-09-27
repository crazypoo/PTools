// English: Shared overlay contracts for scene-aware UIKit presentation.
// Español: Contratos compartidos para presentar overlays UIKit conscientes de la escena.
// 中文：面向多 Scene UIKit 浮层展示的共享契约。

import UIKit

public struct PTOverlayID: Hashable, Sendable {
    public let rawValue: UUID

    public init(rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}

public enum PTOverlayState: Sendable {
    case idle
    case preparing
    case presenting
    case visible
    case dismissing
    case dismissed
}

public enum PTOverlayLayer: Int, Sendable {
    case content = 0
    case tips = 100
    case popover = 200
    case banner = 300
    case modal = 400
    case debug = 500
}

@MainActor
public enum PTOverlayZOrder {
    public static func windowLevel(for layer: PTOverlayLayer) -> UIWindow.Level {
        switch layer {
        case .content:
            return .normal
        case .tips:
            return .alert + 20
        case .popover:
            return .alert + 40
        case .banner:
            return .alert + 100
        case .modal:
            return .alert + 150
        case .debug:
            return .alert + 200
        }
    }
}

public enum PTOverlayPresentationContext {
    case scene(UIWindowScene)
    case window(UIWindow)
    case viewController(UIViewController)
    case view(UIView)
    case automatic
}

public enum PTOverlayPresentationMode: Sendable {
    case attached
    case overlay
}

public enum PTOverlayHitTestPolicy: Sendable {
    case consumeAll
    case passthroughOutsideContent
    case passthroughAll
    case custom
}

public enum PTOverlayDismissReason: Sendable {
    case manual
    case sceneDisconnected
    case hostUnavailable
    // English: The anchor no longer identifies the content that owns the overlay.
    // Español: El anclaje ya no identifica el contenido que posee el overlay.
    // 中文：锚点已无法继续标识当前浮层所属的内容。
    case anchorLost
    case replaced
}

// English: These policies extend the 1.0 contracts without changing Banner defaults.
// Español: Estas políticas amplían los contratos 1.0 sin cambiar los valores predeterminados de Banner.
// 中文：这些策略扩展 1.0 契约，但不改变 Banner 的默认行为。
public enum PTOverlayExclusivityPolicy: Sendable {
    case none
    case dismissLowerTransient
    case dismissSameGroup
}

public struct PTOverlayGroupID: Hashable, Sendable {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct PTPopoverContext {
    public let overlayID: PTOverlayID
    public let frame: CGRect
    public let anchorFrame: CGRect
    public let availableBounds: CGRect
    public let safeAreaInsets: UIEdgeInsets
    public let resolvedPlacement: PTPopoverPlacement
    public let arrowPoint: CGPoint?
    public let keyboardFrame: CGRect?

    @MainActor
    public init(overlayID: PTOverlayID,
                geometry: PTOverlayGeometry,
                anchorFrame: CGRect,
                availableBounds: CGRect,
                safeAreaInsets: UIEdgeInsets,
                keyboardFrame: CGRect?) {
        self.overlayID = overlayID
        self.frame = geometry.frame
        self.anchorFrame = anchorFrame
        self.availableBounds = availableBounds
        self.safeAreaInsets = safeAreaInsets
        self.resolvedPlacement = geometry.placement
        self.arrowPoint = geometry.arrowPoint
        self.keyboardFrame = keyboardFrame
    }
}

@MainActor
public struct PTOverlaySafeAreaContext {
    public let bounds: CGRect
    public let safeAreaInsets: UIEdgeInsets
    public let layoutDirection: UIUserInterfaceLayoutDirection

    public init(environment: UIView) {
        bounds = environment.bounds
        safeAreaInsets = environment.safeAreaInsets
        layoutDirection = environment.effectiveUserInterfaceLayoutDirection
    }
}

@MainActor
public final class PTOverlayHandle {
    public let id: PTOverlayID
    public private(set) var state: PTOverlayState = .idle

    private var dismissAction: (@MainActor () -> Void)?
    private var updateAction: (@MainActor () -> Void)?
    private var replaceAction: (@MainActor () -> Void)?

    public init(id: PTOverlayID,
         dismissAction: (@MainActor () -> Void)? = nil,
         updateAction: (@MainActor () -> Void)? = nil,
         replaceAction: (@MainActor () -> Void)? = nil) {
        self.id = id
        self.dismissAction = dismissAction
        self.updateAction = updateAction
        self.replaceAction = replaceAction
    }

    public func dismiss() {
        dismissAction?()
    }

    public func update() {
        updateAction?()
    }

    public func replace() {
        replaceAction?()
    }

    // English: Product adapters can attach lifecycle actions after the shared handle is created.
    // Español: Los adaptadores de producto pueden asociar acciones de ciclo de vida después de crear el handle compartido.
    // 中文：产品适配层可以在共享句柄创建后补充生命周期操作。
    public func setActions(dismiss: (@MainActor () -> Void)? = nil,
                           update: (@MainActor () -> Void)? = nil,
                           replace: (@MainActor () -> Void)? = nil) {
        dismissAction = dismiss
        updateAction = update
        replaceAction = replace
    }

    public func setState(_ state: PTOverlayState) {
        self.state = state
    }

    public func invalidate() {
        dismissAction = nil
        updateAction = nil
        replaceAction = nil
    }
}

public enum PTOverlayDiagnosticEvent: Sendable {
    case sceneResolveFailed
    case hostUnavailable
    case registered(PTOverlayID)
    case removed(PTOverlayID)
    case invalidState
}

@MainActor
public final class PTOverlayDiagnostics {
    public static let shared = PTOverlayDiagnostics()

    public var sink: (@MainActor @Sendable (PTOverlayDiagnosticEvent) -> Void)?

    private init() {}

    public func record(_ event: PTOverlayDiagnosticEvent) {
        sink?(event)
    }
}

@MainActor
public protocol PTOverlayMetricsSink: AnyObject {
    func record(event: String)
}

@MainActor
public final class PTOverlayRegistry {
    private var hosts: [PTOverlayID: PTOverlayHost] = [:]

    public init() {}

    public func register(_ host: PTOverlayHost, id: PTOverlayID) {
        hosts[id] = host
        PTOverlayDiagnostics.shared.record(.registered(id))
    }

    public func remove(id: PTOverlayID) {
        hosts.removeValue(forKey: id)
        PTOverlayDiagnostics.shared.record(.removed(id))
    }

    public func removeAll() {
        let ids = hosts.keys
        hosts.removeAll(keepingCapacity: false)
        ids.forEach { PTOverlayDiagnostics.shared.record(.removed($0)) }
    }
}

@MainActor
public final class PTOverlayRegistryStore {
    public static let shared = PTOverlayRegistryStore()

    private var registries: [String: PTOverlayRegistry] = [:]

    private init() {}

    public func registry(for scene: UIWindowScene) -> PTOverlayRegistry {
        let key = scene.session.persistentIdentifier
        if let registry = registries[key] {
            return registry
        }
        let registry = PTOverlayRegistry()
        registries[key] = registry
        return registry
    }

    public func removeRegistry(for scene: UIWindowScene) {
        registries.removeValue(forKey: scene.session.persistentIdentifier)?.removeAll()
    }
}
