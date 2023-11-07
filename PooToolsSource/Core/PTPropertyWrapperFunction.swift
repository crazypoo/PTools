//
//  PTPropertyWrapperFunction.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 7/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

//MARK: 此方法用于设定范围,且不会小于和多于相关数值
@propertyWrapper public struct PTClampedProperyWrapper<T: Comparable> {
    public let wrappedValue: T

    public init(wrappedValue: T, range: ClosedRange<T>) {
        self.wrappedValue = min(max(wrappedValue, range.lowerBound), range.upperBound)
    }
}

//MARK: 此方法用于强制英文字符串首字母大写
@propertyWrapper public struct PTCapitalized {
    public var wrappedValue: String {
        didSet { wrappedValue = wrappedValue.capitalized }
    }

    public init(wrappedValue: String) {
        self.wrappedValue = wrappedValue.capitalized
    }
}

//MARK: 此方法用于属性锁
@propertyWrapper public class PTLockAtomic<T> {
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

//MARK: 此方法用于属性包装统一管理
@propertyWrapper public struct PTUserDefault<T> {
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
            return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
            UserDefaults.standard.synchronize()
        }
    }
}
