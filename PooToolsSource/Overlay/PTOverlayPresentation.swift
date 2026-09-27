// English: Scene resolution, attached hosts, and pass-through overlay windows.
// Español: Resolución de escenas, hosts adjuntos y ventanas overlay transparentes.
// 中文：Scene 解析、附着式 Host 和穿透式浮层窗口。

import UIKit

@MainActor
public enum PTOverlaySceneResolver {
    public static func scene(for context: PTOverlayPresentationContext) -> UIWindowScene? {
        switch context {
        case let .scene(scene):
            return scene
        case let .window(window):
            return window.windowScene
        case let .viewController(viewController):
            return viewController.viewIfLoaded?.window?.windowScene
                ?? viewController.navigationController?.viewIfLoaded?.window?.windowScene
        case let .view(view):
            return view.window?.windowScene
        case .automatic:
            return activeScenes.first
        }
    }

    public static func window(for context: PTOverlayPresentationContext) -> UIWindow? {
        switch context {
        case let .window(window):
            return window
        case let .viewController(viewController):
            return viewController.viewIfLoaded?.window
                ?? viewController.navigationController?.viewIfLoaded?.window
        case let .view(view):
            return view.window
        case let .scene(scene):
            return window(in: scene)
        case .automatic:
            return activeScenes.lazy.compactMap { window(in: $0) }.first
        }
    }

    public static func window(in scene: UIWindowScene) -> UIWindow? {
        let windows = scene.windows.filter { !($0 is PTOverlayWindow) && !$0.isHidden && $0.alpha > 0 }
        return windows.first(where: \.isKeyWindow)
            ?? windows.first(where: { $0.windowLevel == .normal })
            ?? windows.first
    }

    public static var activeScenes: [UIWindowScene] {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }
            .sorted { lhs, rhs in
                let lhsActive = lhs.activationState == .foregroundActive
                let rhsActive = rhs.activationState == .foregroundActive
                return lhsActive && !rhsActive
            }
    }
}

@MainActor
public final class PTOverlayContainerView: UIView {
    public var hitTestPolicy: PTOverlayHitTestPolicy = .passthroughOutsideContent
    public weak var interactiveContentView: UIView?
    public var interactiveContentViews: [UIView] = []
    // English: Product layers can provide outside-tap semantics without replacing the shared window hit-test path.
    // Español: Las capas de producto pueden definir el tap exterior sin reemplazar el hit-test compartido de la ventana.
    // 中文：产品层可以提供点击外部语义，而不需要替换共享的 Window 命中测试路径。
    public var customHitTest: (@MainActor (CGPoint, UIEvent?) -> UIView?)?

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        switch hitTestPolicy {
        case .passthroughAll:
            return nil
        case .passthroughOutsideContent:
            let contentViews = interactiveContentViews.isEmpty
                ? interactiveContentView.map { [$0] } ?? []
                : interactiveContentViews
            guard contentViews.contains(where: { view in
                view.bounds.contains(view.convert(point, from: self))
            }) else { return nil }
            return super.hitTest(point, with: event)
        case .consumeAll:
            return super.hitTest(point, with: event)
        case .custom:
            if let customHitTest {
                return customHitTest(point, event)
            }
            let contentViews = interactiveContentViews.isEmpty
                ? interactiveContentView.map { [$0] } ?? []
                : interactiveContentViews
            guard contentViews.contains(where: { view in
                view.bounds.contains(view.convert(point, from: self))
            }) else { return nil }
            return super.hitTest(point, with: event)
        }
    }
}

@MainActor
public class PTOverlayPassthroughWindow: UIWindow {
    public let overlayContainer = PTOverlayContainerView()

    public init(windowScene: UIWindowScene, layer: PTOverlayLayer) {
        super.init(windowScene: windowScene)
        windowLevel = PTOverlayZOrder.windowLevel(for: layer)
        backgroundColor = .clear
        isHidden = true
        let rootViewController = UIViewController()
        rootViewController.view.backgroundColor = .clear
        rootViewController.view.addSubview(overlayContainer)
        overlayContainer.frame = rootViewController.view.bounds
        overlayContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        rootViewController.view.isUserInteractionEnabled = true
        self.rootViewController = rootViewController
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}

@MainActor
public final class PTOverlayWindow: PTOverlayPassthroughWindow {}

@MainActor
public final class PTOverlayHost {
    public let containerView: PTOverlayContainerView
    public private(set) weak var window: UIWindow?

    private let ownedWindow: PTOverlayWindow?

    public init?(context: PTOverlayPresentationContext,
                mode: PTOverlayPresentationMode,
                layer: PTOverlayLayer) {
        guard let scene = PTOverlaySceneResolver.scene(for: context) else {
            PTOverlayDiagnostics.shared.record(.sceneResolveFailed)
            return nil
        }

        switch mode {
        case .attached:
            guard let window = PTOverlaySceneResolver.window(for: context) else {
                PTOverlayDiagnostics.shared.record(.hostUnavailable)
                return nil
            }
            ownedWindow = nil
            self.window = window
            containerView = PTOverlayContainerView()
        case .overlay:
            let overlayWindow = PTOverlayWindow(windowScene: scene, layer: layer)
            ownedWindow = overlayWindow
            self.window = overlayWindow
            containerView = overlayWindow.overlayContainer
        }

        attach()
    }

    public func attach() {
        guard let window else {
            PTOverlayDiagnostics.shared.record(.hostUnavailable)
            return
        }

        if containerView.superview !== window {
            containerView.removeFromSuperview()
            window.addSubview(containerView)
        }
        containerView.frame = window.bounds
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        ownedWindow?.isHidden = false
    }

    public func detach() {
        containerView.removeFromSuperview()
        ownedWindow?.isHidden = true
    }

    public func addOverlayView(_ view: UIView) {
        attach()
        if view.superview !== containerView {
            containerView.addSubview(view)
        }
    }

    public func removeOverlayView(_ view: UIView) {
        view.removeFromSuperview()
    }

    public var safeAreaContext: PTOverlaySafeAreaContext {
        PTOverlaySafeAreaContext(environment: containerView)
    }
}
