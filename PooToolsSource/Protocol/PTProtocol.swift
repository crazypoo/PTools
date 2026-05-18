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

@MainActor
public struct PTNumberValueAdapter {
    public static var share = PTNumberValueAdapter()
        
    /// 记录适配比例
    fileprivate var adapterScale: Double?
}

public protocol PTNumberValueAdapterable {
    associatedtype PTNumberValueAdapterType
    var adapter: PTNumberValueAdapterType { get }
}

extension PTNumberValueAdapterable {
    @MainActor func adapterScale() -> Double {
        if let scale = PTNumberValueAdapter.share.adapterScale {
            return scale
        } else {
            let isPad = UIDevice.current.userInterfaceIdiom == .pad
            var adjustedScale:Double = 1
            // 如果是 iPad 设备，进一步调整字体大小
            if isPad {
                adjustedScale = 1.5 // iPad 上的字体适当放大
            } else {
                // 根据屏幕宽度调整字体大小
                switch CGFloat.kSCREEN_WIDTH {
                case 0...320:
                    adjustedScale = 0.85 // 适用于较小屏幕
                case 321...375:
                    adjustedScale = 1 // 适用于中等屏幕
                case 376...414:
                    adjustedScale = 1.15 // 适用于较大屏幕
                case 415...:
                    adjustedScale = 1.3 // 适用于最大屏幕
                default:
                    adjustedScale = 1
                }
            }
            return adjustedScale
        }
    }
}
