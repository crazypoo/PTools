//
//  PTAlertManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/6/15.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift

// MARK: - Debug Snapshot
public struct PTAlertDebugSnapshot {
    public let sceneCount: Int
    public let scenes: [SceneInfo]

    public struct SceneInfo {
        public let id: String
        public let showingKeys: [String]
        public let queueKeys: [String]
    }
}

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

extension PTAlertManager {
    public func debugSnapshot() -> PTAlertDebugSnapshot {

        let scenes = sceneContainers.map { (scene, container) in
            PTAlertDebugSnapshot.SceneInfo(
                id: "\(ObjectIdentifier(scene).hashValue)",
                showingKeys: Array(container.showingControllers.keys),
                queueKeys: container.waitQueue.map { $0.key }
            )
        }

        return PTAlertDebugSnapshot(
            sceneCount: sceneContainers.count,
            scenes: scenes
        )
    }
}

final class PTAlertDebugView: UIView {

    private let textView = UITextView()
    private let refreshBtn = UIButton(type: .system)
    private let closeBtn = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.black.withAlphaComponent(0.7)
        layer.cornerRadius = 12

        setupUI()
        setupGesture()
        refresh()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {

        textView.isEditable = false
        textView.backgroundColor = .clear
        textView.textColor = .green
        textView.font = .systemFont(ofSize: 12)

        refreshBtn.setTitle("刷新", for: .normal)
        closeBtn.setTitle("关闭", for: .normal)

        refreshBtn.addTarget(self, action: #selector(refresh), for: .touchUpInside)
        closeBtn.addTarget(self, action: #selector(close), for: .touchUpInside)

        addSubviews([textView,refreshBtn,closeBtn])

        textView.frame = CGRect(x: 8, y: 8, width: 260, height: 200)
        refreshBtn.frame = CGRect(x: 8, y: 210, width: 60, height: 30)
        closeBtn.frame = CGRect(x: 200, y: 210, width: 60, height: 30)
    }

    @objc private func refresh() {

        let snapshot = PTAlertManager.shared.debugSnapshot()

        var text = "📊 Alert Debug\n"
        text += "Scene Count: \(snapshot.sceneCount)\n\n"

        for scene in snapshot.scenes {
            text += "🟦 Scene: \(scene.id)\n"
            text += "Showing:\n"
            scene.showingKeys.forEach { text += " - \($0)\n" }

            text += "Queue:\n"
            scene.queueKeys.forEach { text += " - \($0)\n" }

            text += "\n"
        }

        textView.text = text
    }

    @objc private func close() {
        (window as? PTAlertDebugWindow)?.dismiss()
    }
}

private extension PTAlertDebugView {

    func setupGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(pan)
    }

    @objc func handlePan(_ pan: UIPanGestureRecognizer) {
        let translation = pan.translation(in: self.superview)
        center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
        pan.setTranslation(.zero, in: self.superview)
    }
}

final class PTAlertDebugWindow: UIWindow {

    static let shared = PTAlertDebugWindow()

    private weak var debugView: UIView?

    init() {
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first {

            super.init(windowScene: scene)
        } else {
            super.init(frame: UIScreen.main.bounds)
        }

        windowLevel = .alert + 1000
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    func show() {
        if debugView != nil {
            isHidden = false
            return
        }

        let view = PTAlertDebugView(frame: CGRect(x: 40, y: 100, width: 280, height: 250))
        addSubview(view)
        debugView = view

        isHidden = false
    }

    // ⭐️ 关键：事件穿透
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {

        guard let debugView else { return nil }

        let pointInDebug = debugView.convert(point, from: self)

        // ✅ 点在 debugView 内 → 正常响应
        if debugView.bounds.contains(pointInDebug) {
            return super.hitTest(point, with: event)
        }

        // ❌ 其它区域 → 直接穿透
        return nil
    }
    
    func dismiss() {
        debugView?.removeFromSuperview()
        debugView = nil
        isHidden = true
    }
}
