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
    AppWindows?.safeAreaInsets ?? .zero
}

// English: Resolve an active application window without relying on a global key-window shortcut.
// Español: Resuelve una ventana activa sin depender de un atajo global de ventana clave.
// 中文：解析活动应用窗口，不依赖全局 key window 取值捷径。
@MainActor
public enum PTSceneContext {
    public static func activeWindow(in scene: UIWindowScene? = nil) -> UIWindow? {
        let scenes: [UIWindowScene]
        if let scene {
            scenes = [scene]
        } else {
            var foregroundActiveScenes = [UIWindowScene]()
            var foregroundInactiveScenes = [UIWindowScene]()
            for connectedScene in UIApplication.shared.connectedScenes {
                guard let windowScene = connectedScene as? UIWindowScene else { continue }
                switch windowScene.activationState {
                case .foregroundActive:
                    foregroundActiveScenes.append(windowScene)
                case .foregroundInactive:
                    foregroundInactiveScenes.append(windowScene)
                case .background, .unattached:
                    continue
                @unknown default:
                    foregroundInactiveScenes.append(windowScene)
                }
            }
            scenes = foregroundActiveScenes + foregroundInactiveScenes
        }

        var windows = [UIWindow]()
        for windowScene in scenes {
            windows.append(contentsOf: windowScene.windows)
        }

        for window in windows where window.isKeyWindow && window.windowLevel == .normal && window.rootViewController != nil {
            return window
        }
        for window in windows where window.windowLevel == .normal && window.rootViewController != nil {
            return window
        }
        for window in windows where window.isKeyWindow && window.rootViewController != nil {
            return window
        }
        for windowScene in scenes {
            if let sceneWindow = (windowScene.delegate as? PTWindowSceneDelegate)?.window {
                return sceneWindow
            }
        }
        // English: Do not call the public AppWindows adapter here; it would recurse.
        // Español: No llames aquí al adaptador público AppWindows; provocaría una recursión.
        // 中文：这里不能调用公共 AppWindows 适配器，否则会形成递归。
        return nil
    }

    public static func currentViewController(in scene: UIWindowScene? = nil) -> UIViewController? {
        guard let rootViewController = activeWindow(in: scene)?.rootViewController else {
            return nil
        }
        return PTUtils.getCurrentVC(from: rootViewController)
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
            let boundedDelay = min(delay, TimeInterval(UInt64.max) / 1_000_000_000)
            do {
                try await Task.sleep(nanoseconds: UInt64(boundedDelay * 1_000_000_000))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            operation()
        }
    }

    @discardableResult
    public static func cancellableAfter(_ delay: TimeInterval,
                                        operation: @escaping @MainActor @Sendable () -> Void) -> Task<Void, Never> {
        after(delay, operation: operation)
    }
}
