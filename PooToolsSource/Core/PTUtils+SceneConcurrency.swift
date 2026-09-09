//
//  PTUtils+SceneConcurrency.swift
//  PooTools
//
//  English: Scene resolution and MainActor scheduling primitives shared by UI modules.
//  Español: Primitivas compartidas de resolución de escenas y planificación en MainActor para los módulos de UI.
//  中文：供 UI 模块共用的场景解析与 MainActor 调度基础能力。
//

import UIKit

@MainActor public func deviceSafeAreaInsets() -> UIEdgeInsets {
    PTSceneContext.activeWindow()?.safeAreaInsets ?? .zero
}

// English: Resolve an active application window without relying on a global key-window shortcut.
// Español: Resuelve una ventana activa sin depender de un atajo global de ventana clave.
// 中文：解析活动应用窗口，不依赖全局 key window 取值捷径。
@MainActor
public enum PTSceneContext {
    // English: Keep scene discovery in one place so UI modules do not choose an arbitrary connected scene.
    // Español: Mantén el descubrimiento de escenas en un solo lugar para que los módulos UI no elijan una escena arbitraria.
    // 中文：将场景发现集中到一个入口，避免 UI 模块随意选择某个已连接场景。
    public static func connectedWindowScenes() -> [UIWindowScene] {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .sorted { lhs, rhs in
                let lhsPriority = sceneActivationPriority(lhs.activationState)
                let rhsPriority = sceneActivationPriority(rhs.activationState)
                if lhsPriority != rhsPriority {
                    return lhsPriority < rhsPriority
                }
                return lhs.session.persistentIdentifier < rhs.session.persistentIdentifier
            }
    }

    // English: Return windows owned by an explicit scene; callers should use this for scene-scoped UI state.
    // Español: Devuelve las ventanas de una escena explícita; los llamadores deben usarlo para el estado UI por escena.
    // 中文：返回明确场景拥有的窗口；按场景保存 UI 状态时应优先使用此方法。
    public static func windows(in scene: UIWindowScene) -> [UIWindow] {
        scene.windows
    }

    public static func activeWindow(in scene: UIWindowScene? = nil) -> UIWindow? {
        let scenes = scene.map { [$0] } ?? connectedWindowScenes().filter {
            $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive
        }
        return scenes
            .lazy
            .flatMap { windows(in: $0) }
            .sorted { lhs, rhs in
                if lhs.isKeyWindow != rhs.isKeyWindow {
                    return lhs.isKeyWindow
                }
                if lhs.windowLevel != rhs.windowLevel {
                    return lhs.windowLevel.rawValue < rhs.windowLevel.rawValue
                }
                return lhs.rootViewController != nil && rhs.rootViewController == nil
            }
            .first { window in
                !window.isHidden && window.alpha > 0.01 && window.rootViewController != nil
            }
    }

    // English: Resolve the scene already hosting a view instead of falling back to another scene.
    // Español: Resuelve la escena que ya aloja una vista en lugar de cambiar a otra escena.
    // 中文：优先解析已经承载视图的场景，不回退到其他场景。
    public static func windowScene(for view: UIView?) -> UIWindowScene? {
        view?.window?.windowScene
    }

    // English: Resolve a controller's existing scene through its loaded hierarchy.
    // Español: Resuelve la escena existente de un controlador a través de su jerarquía cargada.
    // 中文：通过控制器已加载的层级解析其当前所属场景。
    public static func windowScene(for viewController: UIViewController?) -> UIWindowScene? {
        var current = viewController
        var visited = Set<ObjectIdentifier>()
        while let viewController = current,
              visited.insert(ObjectIdentifier(viewController)).inserted {
            if let scene = viewController.viewIfLoaded?.window?.windowScene {
                return scene
            }
            current = viewController.parent ?? viewController.presentingViewController
        }
        return nil
    }

    // English: Resolve a window from an existing view first and use the canonical fallback only when needed.
    // Español: Resuelve primero la ventana existente de la vista y usa el respaldo canónico solo cuando es necesario.
    // 中文：先返回视图现有的窗口，仅在必要时使用统一的兜底窗口。
    public static func window(for view: UIView?) -> UIWindow? {
        if let window = view?.window {
            return window
        }
        return activeWindow()
    }

    // English: Keep presentation tied to the controller's scene whenever UIKit has already attached it.
    // Español: Mantén la presentación ligada a la escena del controlador cuando UIKit ya lo haya conectado.
    // 中文：当 UIKit 已经挂载控制器时，让展示行为始终绑定到该控制器所在场景。
    public static func window(for viewController: UIViewController?) -> UIWindow? {
        if let window = viewController?.viewIfLoaded?.window {
            return window
        }
        return activeWindow(in: windowScene(for: viewController))
    }

    private static func sceneActivationPriority(_ state: UIScene.ActivationState) -> Int {
        switch state {
        case .foregroundActive: return 0
        case .foregroundInactive: return 1
        case .background: return 2
        case .unattached: return 3
        @unknown default: return 4
        }
    }

    // English: Return the root controller from the same window selection used by every scene-aware lookup.
    // Español: Devuelve el controlador raíz usando la misma selección de ventana que todas las búsquedas por escena.
    // 中文：使用所有场景查询共用的窗口选择策略返回根控制器。
    public static func rootViewController(in scene: UIWindowScene? = nil) -> UIViewController? {
        activeWindow(in: scene)?.rootViewController
    }

    public static func currentViewController(in scene: UIWindowScene? = nil) -> UIViewController? {
        guard let rootViewController = rootViewController(in: scene) else {
            return nil
        }
        return PTUtils.getCurrentVC(from: rootViewController)
    }
}

// English: Inject scene resolution without forcing new code to depend on global lookup.
// Español: Inyecta la resolución de escenas sin obligar al código nuevo a depender de una búsqueda global.
// 中文：提供场景解析注入能力，避免新代码强依赖全局查询。
@MainActor
public protocol PTSceneContextProviding {
    func activeWindow(in scene: UIWindowScene?) -> UIWindow?
    func rootViewController(in scene: UIWindowScene?) -> UIViewController?
    func currentViewController(in scene: UIWindowScene?) -> UIViewController?
}

// English: The default provider preserves the existing PTSceneContext behavior for compatibility.
// Español: El proveedor predeterminado conserva el comportamiento existente de PTSceneContext para compatibilidad.
// 中文：默认提供器保留 PTSceneContext 的现有行为，确保兼容性。
@MainActor
public struct PTDefaultSceneContextProvider: PTSceneContextProviding {
    public init() {}

    public func activeWindow(in scene: UIWindowScene? = nil) -> UIWindow? {
        PTSceneContext.activeWindow(in: scene)
    }

    public func rootViewController(in scene: UIWindowScene? = nil) -> UIViewController? {
        PTSceneContext.rootViewController(in: scene)
    }

    public func currentViewController(in scene: UIWindowScene? = nil) -> UIViewController? {
        PTSceneContext.currentViewController(in: scene)
    }
}

// English: Schedule UI work with cancellation checks at the MainActor boundary.
// Español: Programa trabajo de UI con comprobaciones de cancelación en el límite de MainActor.
// 中文：在 MainActor 边界调度 UI 工作，并在执行前检查取消状态。
public enum PTMainActorBridge {
    @discardableResult
    public static func perform(_ operation: @escaping @MainActor @Sendable () -> Void) -> Task<Void, Never> {
        Task { @MainActor in
            guard !Task.isCancelled else { return }
            operation()
        }
    }

    @discardableResult
    public static func after(_ delay: TimeInterval,
                             operation: @escaping @MainActor @Sendable () -> Void) -> Task<Void, Never> {
        Task { @MainActor in
            guard delay.isFinite, delay >= 0 else { return }
            // English: Keep the nanosecond conversion below UInt64.max even when a caller passes a huge finite delay.
            // Español: Mantén la conversión de nanosegundos por debajo de UInt64.max aunque llegue un retraso finito enorme.
            // 中文：即使调用方传入极大的有限延迟，也要保证纳秒转换不会超过 UInt64.max。
            let maxNanoseconds = UInt64(Int64.max)
            let maxDelay = TimeInterval(Int64.max) / 1_000_000_000
            let boundedDelay = min(delay, maxDelay)
            do {
                let nanoseconds = min(UInt64((boundedDelay * 1_000_000_000).rounded(.down)), maxNanoseconds)
                try await Task.sleep(nanoseconds: nanoseconds)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            operation()
        }
    }

    @discardableResult
    @available(*, deprecated, message: "请使用 PTMainActorBridge.after(_:operation:)")
    public static func cancellableAfter(_ delay: TimeInterval,
                                        operation: @escaping @MainActor @Sendable () -> Void) -> Task<Void, Never> {
        after(delay, operation: operation)
    }
}
