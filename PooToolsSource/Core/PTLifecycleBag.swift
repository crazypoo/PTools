// English: PTLifecycleBag owns UI-bound disposable resources and invalidates them together.
// Español: PTLifecycleBag posee los recursos ligados a la UI y los invalida juntos.
// 中文：PTLifecycleBag 统一持有 UI 生命周期资源，并集中失效处理。

import Foundation
import UIKit
import Dispatch

@MainActor
public final class PTLifecycleBag {
    private var tasks: [Task<Void, Never>] = []
    private var observers: [NSObjectProtocol] = []
    private var observations: [NSKeyValueObservation] = []
    private var timers: [Timer] = []
    private var displayLinks: [CADisplayLink] = []
    private var sources: [DispatchSource] = []
    private var cancellations: [@MainActor () -> Void] = []

    public init() {}

    public func store(_ task: Task<Void, Never>) {
        tasks.append(task)
    }

    public func store(observer: NSObjectProtocol) {
        observers.append(observer)
    }

    // English: Retain KVO observations until the owning UI object is invalidated.
    // Español: Conserva las observaciones KVO hasta invalidar el objeto de UI propietario.
    // 中文：在所属 UI 对象失效前持有 KVO 观察令牌。
    public func store(_ observation: NSKeyValueObservation) {
        observations.append(observation)
    }

    public func store(_ timer: Timer) {
        timers.append(timer)
    }

    public func store(_ displayLink: CADisplayLink) {
        displayLinks.append(displayLink)
    }

    // English: Own dispatch sources so event delivery cannot outlive the UI owner.
    // Español: Posee las fuentes de Dispatch para que los eventos no sobrevivan al dueño de UI.
    // 中文：统一持有 DispatchSource，避免事件回调超过 UI 所有者生命周期。
    public func store(_ source: DispatchSource) {
        sources.append(source)
    }

    // English: Store custom MainActor cancellation without exposing the bag's storage.
    // Español: Guarda una cancelación personalizada en MainActor sin exponer el almacenamiento.
    // 中文：保存自定义 MainActor 取消操作，但不暴露容器内部存储。
    public func storeCancellation(_ cancellation: @escaping @MainActor () -> Void) {
        cancellations.append(cancellation)
    }

    public func invalidate() {
        tasks.forEach { $0.cancel() }
        tasks.removeAll(keepingCapacity: true)
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll(keepingCapacity: true)
        observations.forEach { $0.invalidate() }
        observations.removeAll(keepingCapacity: true)
        timers.forEach { $0.invalidate() }
        timers.removeAll(keepingCapacity: true)
        displayLinks.forEach { $0.invalidate() }
        displayLinks.removeAll(keepingCapacity: true)
        sources.forEach { $0.cancel() }
        sources.removeAll(keepingCapacity: true)
        let pendingCancellations = cancellations
        cancellations.removeAll(keepingCapacity: true)
        pendingCancellations.forEach { $0() }
    }

}
