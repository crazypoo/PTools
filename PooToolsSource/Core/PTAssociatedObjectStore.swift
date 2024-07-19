//
//  AssociatedObjectStore.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/7/19.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import ObjectiveC

public protocol PTAssociatedObjectStore { }

extension PTAssociatedObjectStore {
    func associatedObject<T>(forKey key: UnsafeRawPointer) -> T? {
        return objc_getAssociatedObject(self, key) as AnyObject as? T
    }
    
    func associatedObject<T>(forKey key: UnsafeRawPointer, default: @autoclosure () -> T, ploicy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) -> T {
        if let object: T = self.associatedObject(forKey: key) {
            return object
        }
        let object = `default`()
        self.setAssociatedObject(object, forKey: key, ploicy: ploicy)
        return object
    }
    
    func setAssociatedObject<T>(_ object: T?, forKey key: UnsafeRawPointer, ploicy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        objc_setAssociatedObject(self, key, object, ploicy)
    }
}


class PTWeakWrapper: NSObject {
    weak var obj: NSObject?
}
