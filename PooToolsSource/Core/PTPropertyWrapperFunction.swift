//
//  PTPropertyWrapperFunction.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 7/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

// MARK: 此方法用于设定范围,且不会小于和多于相关数值
// 🛠️ Swift 6 升级：约束 T 必须是 Sendable，并让结构体遵循 Sendable
@propertyWrapper public struct PTClampedPropertyWrapper<T: Comparable & Sendable>: Sendable {
    private var value: T
    private let range: ClosedRange<T>
    
    public var wrappedValue: T {
        get { value }
        set { value = min(max(newValue, range.lowerBound), range.upperBound) }
    }

    public init(wrappedValue: T, range: ClosedRange<T>) {
        self.range = range
        self.value = min(max(wrappedValue, range.lowerBound), range.upperBound)
    }
}

// MARK: 此方法用于强制英文字符串首字母大写
// 🛠️ Swift 6 升级：结构体直接遵循 Sendable（因为内部只有 String，天然安全）
@propertyWrapper public struct PTCapitalized: Sendable {
    public var wrappedValue: String {
        didSet { wrappedValue = wrappedValue.capitalized }
    }

    public init(wrappedValue: String) {
        self.wrappedValue = wrappedValue.capitalized
    }
}

// MARK: 此方法用于属性锁
// 🛠️ Swift 6 升级：
// 1. Class 必须声明为 final，防止子类化破坏安全性
// 2. 约束 T 为 Sendable
// 3. 使用 @unchecked Sendable 告诉编译器：“我已经用 NSLock 手动加锁了，请相信它是安全的，不要再报警告”
@propertyWrapper public final class PTLockAtomic<T: Sendable>: @unchecked Sendable {
    private var value: T
    private let lock = NSLock()
 
    public init(wrappedValue value: T) {
        self.value = value
    }
 
    public var wrappedValue: T {
        get { getValue() }
        set { setValue(newValue: newValue) }
    }
 
    // 加锁处理获取数据
    public func getValue() -> T {
        lock.lock()
        defer { lock.unlock() }
 
        return value
    }
 
    // 设置数据加锁
    public func setValue(newValue: T) {
        lock.lock()
        defer { lock.unlock() }
 
        value = newValue
    }
}

// MARK: 此方法用于属性包装统一管理
// 🛠️ Swift 6 升级：约束 T: Sendable，并让结构体遵循 Sendable
@propertyWrapper public struct PTUserDefault<T: Sendable>: Sendable {
    ///这里的属性key 和 defaultValue 还有init方法都是实际业务中的业务代码
    let key: String
    let defaultValue: T
     
    public init(withKey key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    ///  wrappedValue是@propertyWrapper必须要实现的属性
    /// 当操作我们要包裹的属性时  其具体set get方法实际上走的都是wrappedValue 的set get 方法。
    public var wrappedValue: T {
        get {
            UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
            // 💡 编码助手小贴士：UserDefaults.standard.synchronize() 在 iOS 12 之后已经废弃且不再需要，
            // 系统会自动高效地进行异步写入，你可以考虑安全地删除下面这行代码来提升性能。
            UserDefaults.standard.synchronize()
        }
    }
}
