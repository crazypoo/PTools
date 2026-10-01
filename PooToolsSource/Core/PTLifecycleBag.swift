// English: PTLifecycleBag owns UI-bound disposable resources and invalidates them together.
// Español: PTLifecycleBag posee los recursos ligados a la UI y los invalida juntos.
// 中文：PTLifecycleBag 统一持有 UI 生命周期资源，并集中失效处理。

import Foundation
import UIKit

@MainActor
public final class PTLifecycleBag {
    private var tasks: [Task<Void, Never>] = []
    private var observers: [NSObjectProtocol] = []
    private var timers: [Timer] = []
    private var displayLinks: [CADisplayLink] = []

    public init() {}

    public func store(_ task: Task<Void, Never>) {
        tasks.append(task)
    }

    public func store(observer: NSObjectProtocol) {
        observers.append(observer)
    }

    public func store(_ timer: Timer) {
        timers.append(timer)
    }

    public func store(_ displayLink: CADisplayLink) {
        displayLinks.append(displayLink)
    }

    public func invalidate() {
        tasks.forEach { $0.cancel() }
        tasks.removeAll(keepingCapacity: true)
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll(keepingCapacity: true)
        timers.forEach { $0.invalidate() }
        timers.removeAll(keepingCapacity: true)
        displayLinks.forEach { $0.invalidate() }
        displayLinks.removeAll(keepingCapacity: true)
    }

}
