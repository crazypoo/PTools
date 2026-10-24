//
//  PTCollectionAutoScrollCoordinator.swift
//  PooTools
//
// English: Own one cancellable MainActor auto-scroll task per collection.
// Español: Posee una única tarea cancelable de MainActor por colección.
// 中文：每个列表只拥有一个可取消的 MainActor 自动滚动任务。
//

import Foundation
import UIKit

@MainActor
final class PTCollectionAutoScrollCoordinator {
    private var task: Task<Void, Never>?
    private var isPaused = false
    private var isVisible = true
    private var isInteracting = false
    private var configuration = PTCollectionAutoScrollConfiguration()
    private var tickHandler: (@MainActor () -> Void)?

    func configure(_ configuration: PTCollectionAutoScrollConfiguration,
                   onTick: (@MainActor () -> Void)?) {
        self.configuration = configuration
        self.tickHandler = onTick
        restartIfNeeded()
    }

    func setVisible(_ visible: Bool) {
        isVisible = visible
        restartIfNeeded()
    }

    func setInteracting(_ interacting: Bool) {
        isInteracting = interacting
        restartIfNeeded()
    }

    func pause() {
        isPaused = true
        task?.cancel()
        task = nil
    }

    func resume() {
        isPaused = false
        restartIfNeeded()
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    deinit {
        task?.cancel()
    }

    private func restartIfNeeded() {
        task?.cancel()
        task = nil
        guard configuration.isEnabled,
              !isPaused,
              (!configuration.pausesWhenNotVisible || isVisible),
              (!configuration.pausesWhileInteracting || !isInteracting),
              (!configuration.respectsReduceMotion || !UIAccessibility.isReduceMotionEnabled) else {
            return
        }

        let interval = configuration.interval
        task = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(interval))
                } catch {
                    return
                }
                guard let self, !Task.isCancelled else { return }
                guard self.configuration.isEnabled,
                      !self.isPaused,
                      (!self.configuration.pausesWhenNotVisible || self.isVisible),
                      (!self.configuration.pausesWhileInteracting || !self.isInteracting),
                      (!self.configuration.respectsReduceMotion || !UIAccessibility.isReduceMotionEnabled) else {
                    return
                }
                self.tickHandler?()
            }
        }
    }
}

