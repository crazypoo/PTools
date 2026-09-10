//
//  PTAssociatedObjectStore.swift
//  PToolsCore
//
//  Objective-C associated-object compatibility for Foundation extensions.
//  Compatibilidad con objetos asociados de Objective-C para extensiones de Foundation.
//  为 Foundation 扩展提供 Objective-C 关联对象兼容能力。
//

import Foundation
import ObjectiveC

// English: Keep associated-object access in the Foundation layer; callers own synchronization.
// Español: Mantiene el acceso a objetos asociados en la capa Foundation; el llamador es responsable de la sincronización.
// 中文：将关联对象访问放在 Foundation 层；同步责任由调用方负责。
public protocol PTAssociatedObjectStore {}

public extension PTAssociatedObjectStore {
    func associatedObject<T>(forKey key: UnsafeRawPointer) -> T? {
        objc_getAssociatedObject(self, key) as AnyObject as? T
    }

    func associatedObject<T>(forKey key: UnsafeRawPointer,
                             default: @autoclosure () -> T,
                             policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) -> T {
        if let object: T = associatedObject(forKey: key) {
            return object
        }
        let object = `default`()
        setAssociatedObject(object, forKey: key, policy: policy)
        return object
    }

    func setAssociatedObject<T>(_ object: T?,
                                forKey key: UnsafeRawPointer,
                                policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        objc_setAssociatedObject(self, key, object, policy)
    }
}

final class PTWeakWrapper: NSObject {
    weak var obj: NSObject?
}
