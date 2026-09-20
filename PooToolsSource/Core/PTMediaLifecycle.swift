//
//  PTMediaLifecycle.swift
//  PooTools
//

// English: UI-bound media owners expose one idempotent cleanup operation.
// Español: Los propietarios multimedia ligados a UI exponen una única limpieza idempotente.
// 中文：绑定 UI 的媒体持有者统一提供幂等的清理入口。
@MainActor
public protocol PTMediaInvalidating: AnyObject {
    func invalidate()
}
