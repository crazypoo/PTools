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

/// 弹窗调试信息视图，保留给 LocalConsole 等调试模块使用。
@MainActor
final class PTAlertDebugView: UIView {

    private let textView = UITextView()
    private let refreshButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupGesture()
        refresh()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupGesture()
        refresh()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let buttonHeight: CGFloat = 30
        let buttonY = max(8, bounds.height - buttonHeight - 8)
        textView.frame = CGRect(
            x: 8,
            y: 8,
            width: max(0, bounds.width - 16),
            height: max(0, buttonY - 12)
        )
        refreshButton.frame = CGRect(x: 8, y: buttonY, width: 60, height: buttonHeight)
        closeButton.frame = CGRect(
            x: max(8, bounds.width - 68),
            y: buttonY,
            width: 60,
            height: buttonHeight
        )
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
        removeFromSuperview()
    }
}

private extension PTAlertDebugView {

    func setupView() {
        backgroundColor = UIColor.black.withAlphaComponent(0.7)
        layer.cornerRadius = 12
        clipsToBounds = true

        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.textColor = .green
        textView.font = .systemFont(ofSize: 12)

        refreshButton.setTitle("刷新", for: .normal)
        closeButton.setTitle("关闭", for: .normal)
        refreshButton.addTarget(self, action: #selector(refresh), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        addSubview(textView)
        addSubview(refreshButton)
        addSubview(closeButton)
    }

    func setupGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(pan)
    }

    @objc func handlePan(_ pan: UIPanGestureRecognizer) {
        guard let superview else { return }
        let translation = pan.translation(in: superview)
        center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
        pan.setTranslation(.zero, in: superview)
    }
}

@MainActor
private final class PTAlertDismissGroup {
    private var remaining: Int
    private var completion: PTActionTask?

    init(remaining: Int, completion: PTActionTask?) {
        self.remaining = remaining
        self.completion = completion
    }

    func finish() {
        guard remaining > 0 else { return }
        remaining -= 1
        guard remaining == 0 else { return }
        let completion = self.completion
        self.completion = nil
        completion?()
    }
}

@MainActor
@objcMembers
public final class PTAlertManager: NSObject {

    public static let shared = PTAlertManager()

    private override init() {
        super.init()
        observeSceneDestroy()
    }

    fileprivate struct PendingAlert {
        let controller: PTAlertProtocol
        let completion: PTActionTask?
    }

    fileprivate struct SceneContainer {
        var showingWindows: [String: PTAlertWindow] = [:]
        var showingControllers: [String: PTAlertProtocol] = [:]
        var waitQueue: [PendingAlert] = []
        var dismissingKeys: Set<String> = []
    }

    private var sceneContainers: [UIWindowScene: SceneContainer] = [:]

    // MARK: - Public API

    public static func show(_ controller: PTAlertProtocol,
                            completion: PTActionTask? = nil) {
        shared.showOnMainActor(controller, completion: completion)
    }

    /// async/await 入口。无论展示成功、被拦截还是场景不存在，都会结束 continuation。
    public static func show(_ controller: PTAlertProtocol) async {
        await withCheckedContinuation { continuation in
            show(controller) {
                continuation.resume()
            }
        }
    }

    public static func dismiss(_ key: String?,
                               completion: PTActionTask? = nil) {
        guard let key else {
            completion?()
            return
        }
        shared.dismissOnMainActor(key, completion: completion)
    }

    public static func dismissAll(completion: PTActionTask? = nil) {
        shared.dismissAllOnMainActor(completion: completion)
    }

    public func debugSnapshot() -> PTAlertDebugSnapshot {
        let scenes = sceneContainers.map { scene, container in
            PTAlertDebugSnapshot.SceneInfo(
                id: scene.session.persistentIdentifier,
                showingKeys: container.showingControllers.keys.sorted(),
                queueKeys: container.waitQueue.map { $0.controller.key }
            )
        }
        .sorted { $0.id < $1.id }

        return PTAlertDebugSnapshot(sceneCount: scenes.count, scenes: scenes)
    }
}

// MARK: - 展示与关闭
private extension PTAlertManager {

    func showOnMainActor(_ controller: PTAlertProtocol,
                         completion: PTActionTask?) {
        guard let scene = resolveScene(for: controller) else {
            PTNSLogConsole("❌ 没有找到可用的窗口场景")
            completion?()
            return
        }

        var container = container(for: scene)
        cleanInvalidWindows(&container)

        guard !isDuplicate(controller, container: container) else {
            PTNSLogConsole("❌ 重复弹窗已拦截")
            updateContainer(container, for: scene)
            completion?()
            return
        }

        if controller.config.popoverMode == .queue,
           hasValidShowingWindow(container) {
            container.waitQueue.append(PendingAlert(controller: controller,
                                                     completion: completion))
            container.waitQueue.sort {
                $0.controller.config.popoverPriority > $1.controller.config.popoverPriority
            }
            updateContainer(container, for: scene)
            return
        }

        if controller.config.popoverMode == .replace ||
            controller.config.popoverMode == .unique {
            let keys = Array(container.showingControllers.keys)
            if !keys.isEmpty {
                updateContainer(container, for: scene)
                dismissControllers(keys,
                                   in: scene,
                                   advanceQueue: false) { [weak self] in
                    Task { @MainActor [weak self] in
                        self?.showNow(controller, completion: completion, in: scene)
                    }
                }
                return
            }
        }

        updateContainer(container, for: scene)
        showNow(controller, completion: completion, in: scene)
    }

    func showNow(_ controller: PTAlertProtocol,
                 completion: PTActionTask?,
                 in scene: UIWindowScene) {
        var container = self.container(for: scene)
        let window = makeWindow(for: scene, controller: controller)

        container.showingWindows[controller.key] = window
        container.showingControllers[controller.key] = controller
        updateContainer(container, for: scene)

        controller.showAnimation(completion: completion)
    }

    func dismissOnMainActor(_ key: String,
                            completion: PTActionTask?) {
        for scene in Array(sceneContainers.keys) {
            if sceneContainers[scene]?.showingControllers[key] != nil {
                dismiss(key, in: scene, advanceQueue: true, completion: completion)
                return
            }
        }
        completion?()
    }

    func dismiss(_ key: String,
                 in scene: UIWindowScene,
                 advanceQueue: Bool,
                 completion: PTActionTask?) {
        guard var container = sceneContainers[scene],
              let controller = container.showingControllers[key] else {
            completion?()
            return
        }

        if container.dismissingKeys.contains(key) {
            completion?()
            return
        }

        container.dismissingKeys.insert(key)
        updateContainer(container, for: scene)

        controller.dismissAnimation { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else {
                    completion?()
                    return
                }
                self.finishDismiss(key,
                                   in: scene,
                                   advanceQueue: advanceQueue,
                                   completion: completion)
            }
        }
    }

    func dismissControllers(_ keys: [String],
                            in scene: UIWindowScene,
                            advanceQueue: Bool,
                            completion: @escaping PTActionTask) {
        let validKeys = keys.filter {
            sceneContainers[scene]?.showingControllers[$0] != nil
        }
        guard !validKeys.isEmpty else {
            completion()
            return
        }

        let group = PTAlertDismissGroup(remaining: validKeys.count,
                                        completion: completion)
        for key in validKeys {
            dismiss(key, in: scene, advanceQueue: advanceQueue) {
                Task { @MainActor in
                    group.finish()
                }
            }
        }
    }

    func finishDismiss(_ key: String,
                       in scene: UIWindowScene,
                       advanceQueue: Bool,
                       completion: PTActionTask?) {
        guard var container = sceneContainers[scene] else {
            completion?()
            return
        }

        if let window = container.showingWindows.removeValue(forKey: key) {
            window.isHidden = true
            window.resignKey()
            window.rootViewController = nil
        }
        container.showingControllers.removeValue(forKey: key)
        container.dismissingKeys.remove(key)
        updateContainer(container, for: scene)

        restoreKeyWindow(in: scene)
        completion?()

        if advanceQueue {
            showNextIfNeeded(in: scene)
        }
    }

    func dismissAllOnMainActor(completion: PTActionTask?) {
        let scenes = Array(sceneContainers.keys)
        var total = 0

        for scene in scenes {
            guard var container = sceneContainers[scene] else { continue }

            let pending = container.waitQueue
            container.waitQueue.removeAll()
            updateContainer(container, for: scene)
            pending.forEach { $0.completion?() }

            total += container.showingControllers.count
        }

        guard total > 0 else {
            completion?()
            return
        }

        let group = PTAlertDismissGroup(remaining: total, completion: completion)
        for scene in scenes {
            let keys = sceneContainers[scene].map {
                Array($0.showingControllers.keys)
            } ?? []
            for key in keys {
                dismiss(key, in: scene, advanceQueue: false) {
                    Task { @MainActor in
                        group.finish()
                    }
                }
            }
        }
    }
}

// MARK: - 场景与队列
private extension PTAlertManager {

    func resolveScene(for controller: PTAlertProtocol) -> UIWindowScene? {
        if let scene = controller.preferredWindowScene {
            return scene
        }
        if let scene = controller.viewIfLoaded?.window?.windowScene {
            return scene
        }

        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        if let keyScene = scenes
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .windowScene {
            return keyScene
        }

        return scenes.first(where: { $0.activationState == .foregroundActive })
    }

    func container(for scene: UIWindowScene) -> SceneContainer {
        sceneContainers[scene] ?? SceneContainer()
    }

    func updateContainer(_ container: SceneContainer, for scene: UIWindowScene) {
        sceneContainers[scene] = container
    }

    func isDuplicate(_ controller: PTAlertProtocol,
                     container: SceneContainer) -> Bool {
        if container.showingWindows.values.contains(where: {
            $0.rootPopoverController?.config.popoverMode == .unique
        }) {
            return true
        }

        guard let identifier = controller.config.identifier else { return false }

        if container.showingControllers.values.contains(where: {
            $0.config.identifier == identifier
        }) {
            return true
        }

        return container.waitQueue.contains {
            $0.controller.config.identifier == identifier
        }
    }

    func hasValidShowingWindow(_ container: SceneContainer) -> Bool {
        container.showingWindows.values.contains {
            $0.rootViewController != nil && !$0.isHidden
        }
    }

    func showNextIfNeeded(in scene: UIWindowScene) {
        guard var container = sceneContainers[scene],
              container.showingWindows.isEmpty,
              let next = container.waitQueue.first else { return }

        container.waitQueue.removeFirst()
        updateContainer(container, for: scene)
        showOnMainActor(next.controller, completion: next.completion)
    }

    func cleanInvalidWindows(_ container: inout SceneContainer) {
        let invalidKeys = container.showingWindows.compactMap { key, window in
            window.rootViewController == nil || window.isHidden ? key : nil
        }
        invalidKeys.forEach {
            container.showingWindows[$0]?.isHidden = true
            container.showingWindows.removeValue(forKey: $0)
            container.showingControllers.removeValue(forKey: $0)
            container.dismissingKeys.remove($0)
        }
    }
}

// MARK: - 窗口
private extension PTAlertManager {

    func makeWindow(for scene: UIWindowScene,
                    controller: PTAlertProtocol) -> PTAlertWindow {
        let window = PTAlertWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        window.backgroundColor = .clear
        window.windowLevel = .alert + 50
        window.overrideUserInterfaceStyle = UIUserInterfaceStyle(
            rawValue: controller.config.userInterfaceStyleOverride.rawValue
        ) ?? .unspecified
        window.autoHideWhenPenetrated = controller.config.autoHideWhenPenetrated
        window.allowsEventPenetration = controller.config.allowsEventPenetration
        window.rootViewController = controller
        window.makeKeyAndVisible()
        return window
    }

    func restoreKeyWindow(in scene: UIWindowScene) {
        if let values = sceneContainers[scene]?.showingWindows.values {
            let mapValue = values.map({ $0 })
            if let alertWindow = mapValue.last(where: { !$0.isHidden }) {
                alertWindow.makeKey()
                return
            }
        }

        scene.windows
            .first(where: { $0.windowLevel == .normal && !$0.isHidden })?
            .makeKey()
    }
}

// MARK: - 场景生命周期
private extension PTAlertManager {

    func observeSceneDestroy() {
        NotificationCenter.default.addObserver(
            forName: UIScene.didDisconnectNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let scene = notification.object as? UIWindowScene else { return }
            let sceneID = ObjectIdentifier(scene)
            Task { @MainActor [weak self] in
                guard let self,
                      let disconnectedScene = self.sceneContainers.keys.first(where: {
                          ObjectIdentifier($0) == sceneID
                      }) else { return }
                self.sceneContainers.removeValue(forKey: disconnectedScene)
            }
        }
    }
}
