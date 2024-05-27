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

    private var operation: (() -> Void)?

    override init() {
        self.thread = Thread.current

        if let mode = RunLoop.current.currentMode {
            self.modes = [mode, .default].map { $0 }
        } else {
            self.modes = [.default]
        }

        super.init()
    }

    func execute(_ operation: @escaping () -> Void) {
        self.operation = operation
        perform(
            #selector(operate),
            on: thread,
            with: nil,
            waitUntilDone: true,
            modes: modes.map(\.rawValue)
        )
        self.operation = nil
    }

    @objc private func operate() {
        operation?()
    }
}
