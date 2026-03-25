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
    private override init() {}

    // MARK: - Thread Safety
    private let queue = DispatchQueue(label: "com.pt.alert.manager")

    // MARK: - Data
    private var showingWindows: [String: PTAlertWindow] = [:]
    private var waitQueue: [PTAlertProtocol] = []
    private var showingControllers: [String: PTAlertProtocol] = [:]
    
    // MARK: - Window Pool
    private var reusableWindows: [PTAlertWindow] = []

    // MARK: - Public API

    /// 显示弹窗
    public static func show(_ controller: PTAlertProtocol, completion: PTActionTask? = nil) {
        shared.queue.async {
            DispatchQueue.main.async {
                shared._show(controller, completion: completion)
            }
        }
    }

    /// 关闭指定弹窗
    public static func dismiss(_ key: String?, completion: PTActionTask? = nil) {
        guard let key else { return }
        shared.queue.async {
            DispatchQueue.main.async {
                shared._dismiss(key, completion: completion)
            }
        }
    }

    /// 关闭全部
    public static func dismissAll(completion: PTActionTask? = nil) {
        shared.queue.async {
            DispatchQueue.main.async {
                shared._dismissAll(completion: completion)
            }
        }
    }
}

// MARK: - Private
private extension PTAlertManager {

    // MARK: Show
    @MainActor func _show(_ controller: PTAlertProtocol, completion: PTActionTask?) {
        cleanInvalidWindows() // ✅ 关键！！！

        // 1. 唯一 & 重复判断
        if isDuplicate(controller) {
            PTNSLogConsole("❌ duplicate blocked")
            return
        }

        // 2. 模式处理
        handleMode(controller)

        // 3. queue 模式
        if controller.config.popoverMode == .queue,
           hasValidShowingWindow() {
            insertQueue(controller)
            return
        }

        // 4. 创建 / 复用 window
        let window = dequeueWindow()
        configWindow(window, controller: controller)
        
        showingWindows[controller.key] = window
        showingControllers[controller.key] = controller

        // 5. show
        controller.showAnimation(completion: completion)
    }

    // MARK: Dismiss
    func _dismiss(_ key: String, completion: PTActionTask?) {
        guard let window = showingWindows[key],
              let controller = showingControllers[key] else { return }

        controller.dismissAnimation { [weak self] in
            guard let self else { return }

            // 回收 window
            self.recycle(window)

            self.showingWindows.removeValue(forKey: key)
            self.showingControllers.removeValue(forKey: key)

            // 恢复主 window
            self.makeMainWindowKey()

            // 显示下一个
            self.showNextIfNeeded()

            completion?()
        }
    }

    // MARK: Dismiss All
    @MainActor func _dismissAll(completion: PTActionTask?) {

        showingWindows.values.forEach { recycle($0) }

        showingWindows.removeAll()
        waitQueue.removeAll()
        showingControllers.removeAll()
        
        makeMainWindowKey()

        completion?()
    }
    
    func cleanInvalidWindows() {
        showingWindows = showingWindows.filter { key, window in
            let isValid = window.rootViewController != nil && !window.isHidden
            if !isValid {
                reusableWindows.append(window)
            }
            return isValid
        }

        // 同步清 controller
        showingControllers = showingControllers.filter { key, _ in
            showingWindows[key] != nil
        }
    }
    
    func hasValidShowingWindow() -> Bool {
        return showingWindows.values.contains {
            $0.rootViewController != nil && !$0.isHidden
        }
    }
}

// MARK: - Core Logic
private extension PTAlertManager {

    func isDuplicate(_ controller: PTAlertProtocol) -> Bool {

        // unique 模式
        if showingWindows.values.contains(where: {
            $0.rootPopoverController?.config.popoverMode == .unique
        }) {
            return true
        }

        // identifier 判重
        if let id = controller.config.identifier {
            if showingWindows.values.contains(where: {
                $0.rootPopoverController?.config.identifier == id
            }) {
                return true
            }

            if waitQueue.contains(where: {
                $0.config.identifier == id
            }) {
                return true
            }
        }

        return false
    }

    @MainActor func handleMode(_ controller: PTAlertProtocol) {
        switch controller.config.popoverMode {
        case .replace:
            _dismissAll(completion: nil)
        case .unique:
            _dismissAll(completion: nil)
        default:
            break
        }
    }

    func insertQueue(_ controller: PTAlertProtocol) {
        waitQueue.append(controller)
        waitQueue.sort {
            $0.config.popoverPriority > $1.config.popoverPriority
        }
    }

    @MainActor func showNextIfNeeded() {
        guard showingWindows.isEmpty, !waitQueue.isEmpty else { return }

        let next = waitQueue.removeFirst()
        _show(next, completion: nil)
    }
}

// MARK: - Window
private extension PTAlertManager {

    func dequeueWindow() -> PTAlertWindow {
        if let window = reusableWindows.popLast() {
            return window
        }
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            PTNSLogConsole("❌ No active scene")
            return PTAlertWindow(frame: UIScreen.main.bounds)
        }

        return PTAlertWindow(windowScene: scene)
    }

    func recycle(_ window: PTAlertWindow) {
        window.isHidden = true
        window.resignKey()
        window.rootViewController = nil
        reusableWindows.append(window)
    }

    func configWindow(_ window: PTAlertWindow, controller: PTAlertProtocol) {
        window.frame = UIScreen.main.bounds
        window.backgroundColor = .clear
        window.windowLevel = .alert + 50
        window.overrideUserInterfaceStyle =
            UIUserInterfaceStyle(rawValue: controller.config.userInterfaceStyleOverride.rawValue) ?? .light

        window.autoHideWhenPenetrated = controller.config.autoHideWhenPenetrated
        window.allowsEventPenetration = controller.config.allowsEventPenetration
        window.rootViewController = controller
        window.makeKeyAndVisible()
    }

    func makeMainWindowKey() {
        UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.windowLevel == .normal }?
            .makeKey()
    }
}
