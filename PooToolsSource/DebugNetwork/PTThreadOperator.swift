//
//  PTThreadOperator.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

final class PTThreadOperator: NSObject {
    private let thread: Thread
    private let modes: [RunLoop.Mode]

    private var operation: PTActionTask?

    override init() {
        self.thread = Thread.current

        // 捕获当前线程的 RunLoop 模式，确保跨线程同步回拨时不会被阻断
        if let mode = RunLoop.current.currentMode {
            self.modes = [mode, .default]
        } else {
            self.modes = [.default]
        }

        super.init()
    }

    /// 将闭包任务安全地同步派发回当前对象初始化的目标线程执行
    func execute(_ operation: @escaping PTActionTask) {
        self.operation = operation
        // 严格依赖 performSelector 机制跨线程同步 (waitUntilDone: true)
        perform(#selector(operate), on: thread, with: nil, waitUntilDone: true, modes: modes.map(\.rawValue))
        self.operation = nil
    }

    // 移除 @MainActor 标记，彻底杜绝多线程环境下的调度冲突与主线程死锁
    @MainActor @objc private func operate() {
        operation?()
    }
}
