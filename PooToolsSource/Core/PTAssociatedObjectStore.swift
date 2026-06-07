//
//  AssociatedObjectStore.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/7/19.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import ObjectiveC

/// 一个用于为 Swift 扩展和协议提供“关联对象（Associated Objects）”能力的协议。
/// 遵循此协议的类型可以轻松地动态添加存储属性。
public protocol PTAssociatedObjectStore { }

public extension PTAssociatedObjectStore {
    
    /// 获取关联对象
    /// - Parameter key: 用于关联对象的唯一键（通常使用静态全局变量的地址，即 UnsafeRawPointer）
    /// - Returns: 返回指定类型 `T` 的对象。如果未设置，则返回 `nil`
    func associatedObject<T>(forKey key: UnsafeRawPointer) -> T? {
        // 先获取对象，转换为 AnyObject，再尝试向下转型为我们需要的类型 T
        return objc_getAssociatedObject(self, key) as AnyObject as? T
    }
    
    /// 获取关联对象（带默认值）
    /// 如果找不到对应的关联对象，会自动使用 `default` 闭包生成一个默认值，保存并返回。
    ///
    /// - Parameters:
    ///   - key: 用于关联对象的唯一键
    ///   - default: 默认值闭包（使用 @autoclosure 延迟执行，提升性能）
    ///   - policy: 内存管理策略，默认为 .OBJC_ASSOCIATION_RETAIN_NONATOMIC
    /// - Returns: 返回已存在的关联对象，或者新创建的默认对象
    func associatedObject<T>(forKey key: UnsafeRawPointer,
                             default: @autoclosure () -> T,
                             policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) -> T {
        // 1. 尝试获取现有的对象
        if let object: T = self.associatedObject(forKey: key) {
            return object
        }
        // 2. 如果不存在，通过闭包生成默认值
        let object = `default`()
        // 3. 将默认值保存起来
        self.setAssociatedObject(object, forKey: key, policy: policy)
        return object
    }
    
    /// 设置关联对象
    /// - Parameters:
    ///   - object: 要保存的对象（如果传入 nil，则相当于移除该关联对象）
    ///   - key: 用于关联对象的唯一键
    ///   - policy: 内存管理策略，默认为 .OBJC_ASSOCIATION_RETAIN_NONATOMIC
    func setAssociatedObject<T>(_ object: T?,
                                forKey key: UnsafeRawPointer,
                                policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        objc_setAssociatedObject(self, key, object, policy)
    }
}

class PTWeakWrapper: NSObject {
    weak var obj: NSObject?
}
