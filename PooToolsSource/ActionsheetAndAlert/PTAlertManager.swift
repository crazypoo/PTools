//
//  PTAlertManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/6/15.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
public final class PTAlertManager: NSObject {

    // MARK: - Singleton
    public static let shared = PTAlertManager()
    private override init() {
        super.init()
        observeSceneDestroy()
    }

    // MARK: - Thread Safety
    private let queue = DispatchQueue(label: "com.pt.alert.manager")

    // MARK: - Scene Container
    fileprivate struct SceneContainer {
        var showingWindows: [String: PTAlertWindow] = [:]
        var showingControllers: [String: PTAlertProtocol] = [:]
        var waitQueue: [PTAlertProtocol] = []
    }

    private var sceneContainers: [UIWindowScene: SceneContainer] = [:]

    // MARK: - Window Pool
    private var reusableWindows: [PTAlertWindow] = []

    // MARK: - Public API

    public static func show(_ controller: PTAlertProtocol,
                            completion: PTActionTask? = nil) {
        shared.queue.async {
            DispatchQueue.main.async {
                shared._show(controller, completion: completion)
            }
        }
    }

    /// async/await 支持
    public static func show(_ controller: PTAlertProtocol) async {
        await withCheckedContinuation { continuation in
            show(controller) {
                continuation.resume()
            }
        }
    }

    public static func dismiss(_ key: String?,
                               completion: PTActionTask? = nil) {
        guard let key else { return }
        shared.queue.async {
            DispatchQueue.main.async {
                shared._dismiss(key, completion: completion)
            }
        }
    }

    public static func dismissAll(completion: PTActionTask? = nil) {
        shared.queue.async {
            DispatchQueue.main.async {
                shared._dismissAll(completion: completion)
            }
        }
    }
}

// MARK: - Core
private extension PTAlertManager {

    // MARK: Show
    @MainActor
    func _show(_ controller: PTAlertProtocol, completion: PTActionTask?) {

        guard let scene = resolveScene(for: controller) else {
            PTNSLogConsole("❌ No Scene Found")
            return
        }

        var container = self.container(for: scene)

        cleanInvalidWindows(&container)

        if isDuplicate(controller, container: container) {
            PTNSLogConsole("❌ duplicate blocked")
            return
        }

        handleMode(controller, container: &container)

        if controller.config.popoverMode == .queue,
           hasValidShowingWindow(container) {

            insertQueue(controller, container: &container)
            updateContainer(container, for: scene)
            return
        }

        let window = dequeueWindow(for: controller, scene: scene)

        configWindow(window, controller: controller)

        container.showingWindows[controller.key] = window
        container.showingControllers[controller.key] = controller

        updateContainer(container, for: scene)

        controller.showAnimation(completion: completion)
    }

    // MARK: Dismiss
    func _dismiss(_ key: String, completion: PTActionTask?) {

        for (scene, var container) in sceneContainers {

            guard let window = container.showingWindows[key],
                  let controller = container.showingControllers[key] else { continue }

            controller.dismissAnimation { [weak self] in
                guard let self else { return }

                self.recycle(window)

                container.showingWindows.removeValue(forKey: key)
                container.showingControllers.removeValue(forKey: key)

                self.updateContainer(container, for: scene)

                self.makeMainWindowKey(in: scene)

                self.showNextIfNeeded(scene: scene)

                completion?()
            }
        }
    }

    // MARK: Dismiss All
    @MainActor
    func _dismissAll(completion: PTActionTask?) {

        for (scene, var container) in sceneContainers {

            container.showingWindows.values.forEach { recycle($0) }

            container.showingWindows.removeAll()
            container.showingControllers.removeAll()
            container.waitQueue.removeAll()

            updateContainer(container, for: scene)

            makeMainWindowKey(in: scene)
        }

        completion?()
    }
}

// MARK: - Scene
private extension PTAlertManager {

    func resolveScene(for controller: PTAlertProtocol) -> UIWindowScene? {

        // 🥇 controller 所在
        if let scene = controller.view.window?.windowScene {
            return scene
        }

        // 🥈 keyWindow
        if let scene = UIApplication.shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .windowScene {
            return scene
        }

        // 🥉 fallback
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })
    }

    func container(for scene: UIWindowScene) -> SceneContainer {
        if let c = sceneContainers[scene] { return c }
        let new = SceneContainer()
        sceneContainers[scene] = new
        return new
    }

    func updateContainer(_ container: SceneContainer, for scene: UIWindowScene) {
        sceneContainers[scene] = container
    }
}

// MARK: - Queue / Logic
private extension PTAlertManager {

    func isDuplicate(_ controller: PTAlertProtocol,
                     container: SceneContainer) -> Bool {

        if container.showingWindows.values.contains(where: {
            $0.rootPopoverController?.config.popoverMode == .unique
        }) {
            return true
        }

        if let id = controller.config.identifier {

            if container.showingWindows.values.contains(where: {
                $0.rootPopoverController?.config.identifier == id
            }) { return true }

            if container.waitQueue.contains(where: {
                $0.config.identifier == id
            }) { return true }
        }

        return false
    }

    @MainActor
    func handleMode(_ controller: PTAlertProtocol,
                    container: inout SceneContainer) {

        switch controller.config.popoverMode {
        case .replace, .unique:
            container.showingWindows.values.forEach { recycle($0) }
            container.showingWindows.removeAll()
            container.showingControllers.removeAll()
        default:
            break
        }
    }

    func insertQueue(_ controller: PTAlertProtocol,
                     container: inout SceneContainer) {

        container.waitQueue.append(controller)

        container.waitQueue.sort {
            $0.config.popoverPriority > $1.config.popoverPriority
        }
    }

    func hasValidShowingWindow(_ container: SceneContainer) -> Bool {
        return container.showingWindows.values.contains {
            $0.rootViewController != nil && !$0.isHidden
        }
    }

    @MainActor
    func showNextIfNeeded(scene: UIWindowScene) {

        var container = self.container(for: scene)

        guard container.showingWindows.isEmpty,
              !container.waitQueue.isEmpty else { return }

        let next = container.waitQueue.removeFirst()

        updateContainer(container, for: scene)

        _show(next, completion: nil)
    }

    func cleanInvalidWindows(_ container: inout SceneContainer) {

        container.showingWindows = container.showingWindows.filter { _, window in
            let valid = window.rootViewController != nil && !window.isHidden
            if !valid { reusableWindows.append(window) }
            return valid
        }

        container.showingControllers = container.showingControllers.filter {
            container.showingWindows[$0.key] != nil
        }
    }
}

// MARK: - Window
private extension PTAlertManager {

    func dequeueWindow(for controller: PTAlertProtocol,
                       scene: UIWindowScene) -> PTAlertWindow {

        if let window = reusableWindows.popLast() {
            return window
        }

        return PTAlertWindow(windowScene: scene)
    }

    func recycle(_ window: PTAlertWindow) {
        window.isHidden = true
        window.resignKey()
        window.rootViewController = nil
        reusableWindows.append(window)
    }

    func configWindow(_ window: PTAlertWindow,
                      controller: PTAlertProtocol) {

        window.frame = UIScreen.main.bounds
        window.backgroundColor = .clear
        window.windowLevel = .alert + 50

        window.overrideUserInterfaceStyle =
        UIUserInterfaceStyle(rawValue:
            controller.config.userInterfaceStyleOverride.rawValue) ?? .light

        window.autoHideWhenPenetrated = controller.config.autoHideWhenPenetrated
        window.allowsEventPenetration = controller.config.allowsEventPenetration

        window.rootViewController = controller
        window.makeKeyAndVisible()
    }

    func makeMainWindowKey(in scene: UIWindowScene) {
        scene.windows
            .first(where: { $0.windowLevel == .normal && !$0.isHidden })?
            .makeKey()
    }
}

// MARK: - Scene Lifecycle
private extension PTAlertManager {

    func observeSceneDestroy() {
        NotificationCenter.default.addObserver(
            forName: UIScene.didDisconnectNotification,
            object: nil,
            queue: .main) { [weak self] notification in

            guard let scene = notification.object as? UIWindowScene else { return }

            self?.sceneContainers.removeValue(forKey: scene)
        }
    }
}
