//
//  PTProtocol.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/15.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import Foundation

// 1. 定义包装器，并补全 public 访问控制
public struct PTPOP<Base> {
    public let base: Base // 升级：添加 public，确保在其他模块可以访问 base 实例
    
    public init(_ base: Base) {
        self.base = base
    }
}

// 2. Swift 6 核心升级：条件遵守 Sendable 协议
// 解释：这行代码告诉 Swift 6 编译器：“只要被包装的 Base 类型是线程安全的，那么 PTPOP 也是线程安全的。”
// 这在并发编程（如 Task, async/await）中是必不可少的。
extension PTPOP: Sendable where Base: Sendable {}

// 3. 定义协议
public protocol PTProtocolCompatible {}

// 4. 实现扩展
public extension PTProtocolCompatible {
    
    // 静态类型的命名空间
    static var pt: PTPOP<Self>.Type {
        // 升级：移除空的 set {}。在 Swift 6 中，纯计算属性配合 actor 隔离会更安全、无警告。
        get { PTPOP<Self>.self }
    }
    
    // 实例类型的命名空间
    var pt: PTPOP<Self> {
        // 同理，移除空 set，保持其为一个纯粹的只读包装器。
        get { PTPOP(self) }
    }
}

/// Define Property protocol
internal protocol PTSwiftPropertyCompatible {
  
    /// Extended type
    associatedtype T
    
    ///Alias for callback function
    typealias SwiftCallBack = (T?) -> ()
    
    ///Define the calculated properties of the closure type
    var swiftCallBack: SwiftCallBack?  { get set }
}

public final class PTAdapterConfig: @unchecked Sendable {
    public static let shared = PTAdapterConfig()
    
    // 用于缓存计算好的比例，默认值为 1.0
    private var _cachedScale: Double = 1.0
    private var isCalculated = false // 标记是否已经计算过
    
    // 任何线程都可以安全读取这个比例
    public var scale: Double {
        return _cachedScale
    }
    
    // 2. 这个方法限制在主线程，专门用来做初始化计算
    @MainActor
    public func calculateScaleIfNeeded() {
        // 如果已经计算过了，就不再重复计算
        guard !isCalculated else { return }
        
        // 优先使用手动设置的比例
        if let customScale = PTNumberValueAdapter.share.adapterScale {
            _cachedScale = customScale
        } else {
            // 这里都在主线程执行，所以调用 UIDevice 和 kSCREEN_WIDTH 绝对安全
            let isPad = UIDevice.current.userInterfaceIdiom == .pad
            if isPad {
                _cachedScale = 1.5
            } else {
                switch CGFloat.kSCREEN_WIDTH {
                case 0...320:   _cachedScale = 0.85
                case 321...375: _cachedScale = 1.0
                case 376...414: _cachedScale = 1.15
                case 415...:    _cachedScale = 1.3
                default:        _cachedScale = 1.0
                }
            }
        }
        isCalculated = true
    }
}

public final class PTNumberValueAdapter: @unchecked Sendable {
    // 使用 let 保证单例本身的引用不会被意外修改
    public static let share = PTNumberValueAdapter()
    
    // 记录用户手动设置的适配比例
    fileprivate var adapterScale: Double?
    
    // 内部缓存计算好的最终比例，默认是 1.0
    private var _calculatedScale: Double = 1.0
    private var isCalculated = false
    
    // 私有化初始化方法，确保单例的唯一性
    private init() {}
    
    // 提供一个供外部在任意线程读取的属性
    public var currentScale: Double {
        return _calculatedScale
    }
    
    // 如果你需要手动设置比例，可以通过这个方法
    public func setAdapterScale(_ scale: Double) {
        self.adapterScale = scale
        self._calculatedScale = scale
        self.isCalculated = true
    }
    
    // 2. 专门在主线程执行的计算方法（因为用到了 UIDevice 和 kSCREEN_WIDTH）
    @MainActor
    public func calculateScaleIfNeeded() {
        // 如果已经计算过，或者用户手动设置过，就不再重复计算
        guard !isCalculated else { return }
        
        if let customScale = adapterScale {
            _calculatedScale = customScale
        } else {
            let isPad = UIDevice.current.userInterfaceIdiom == .pad
            if isPad {
                _calculatedScale = 1.5
            } else {
                switch CGFloat.kSCREEN_WIDTH {
                case 0...320:   _calculatedScale = 0.85
                case 321...375: _calculatedScale = 1.0
                case 376...414: _calculatedScale = 1.15
                case 415...:    _calculatedScale = 1.3
                default:        _calculatedScale = 1.0
                }
            }
        }
        isCalculated = true
    }
}

public protocol PTNumberValueAdapterable {
    associatedtype PTNumberValueAdapterType
    var adapter: PTNumberValueAdapterType { get }
}
