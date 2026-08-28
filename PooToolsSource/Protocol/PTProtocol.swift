//
//  PTProtocol.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/15.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import Foundation
import os.lock

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
        set {}
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

// Thread-safe storage for the compatibility adapter configuration.
// Almacenamiento seguro para la configuración del adaptador compatible.
// 兼容适配器配置使用线程安全存储。
private struct PTAdapterConfigState: Sendable {
    var scale: Double = 1.0
    var isCalculated = false
}

// Thread-safe storage for the shared scale value.
// Almacenamiento seguro para el valor de escala compartido.
// 共享比例值使用线程安全存储。
private struct PTNumberAdapterState: Sendable {
    var customScale: Double?
    var calculatedScale: Double = 1.0
    var isCalculated = false
}

// Calculate the legacy device scale only on MainActor because it reads UIKit state.
// Calcula la escala heredada del dispositivo solo en MainActor porque lee estado de UIKit.
// 旧版设备比例只在 MainActor 上计算，因为它读取 UIKit 状态。
@MainActor
private func ptDefaultAdapterScale() -> Double {
    if UIDevice.current.userInterfaceIdiom == .pad {
        return 1.5
    }

    switch CGFloat.kSCREEN_WIDTH {
    case 0...320:   return 0.85
    case 321...375: return 1.0
    case 376...414: return 1.15
    case 415...:    return 1.3
    default:        return 1.0
    }
}

public final class PTAdapterConfig: Sendable {
    public static let shared = PTAdapterConfig()
    private let state = OSAllocatedUnfairLock(initialState: PTAdapterConfigState())

    // Reads are protected so legacy callers may access this value from any thread.
    // Las lecturas están protegidas para que los llamadores heredados puedan acceder desde cualquier hilo.
    // 读取受到保护，旧调用方可以从任意线程访问该值。
    public var scale: Double {
        state.withLock { $0.scale }
    }

    // Keep the public calculation entry point while making the shared state atomic.
    // Mantiene la entrada pública de cálculo y hace atómico el estado compartido.
    // 保留公开计算入口，同时让共享状态具备原子性。
    @MainActor
    public func calculateScaleIfNeeded() {
        PTNumberValueAdapter.share.calculateScaleIfNeeded()
        let calculatedScale = PTNumberValueAdapter.share.currentScale
        state.withLock { state in
            guard !state.isCalculated else { return }
            state.scale = calculatedScale
            state.isCalculated = true
        }
    }
}

public final class PTNumberValueAdapter: Sendable {
    public static let share = PTNumberValueAdapter()
    private let state = OSAllocatedUnfairLock(initialState: PTNumberAdapterState(customScale: nil))

    // Kept fileprivate for the compatibility configuration adapter.
    // Se mantiene fileprivate para el adaptador de configuración compatible.
    // 为兼容配置适配器保留 fileprivate 访问级别。
    fileprivate var adapterScale: Double? {
        state.withLock { $0.customScale }
    }

    private init() {}

    public var currentScale: Double {
        state.withLock { $0.calculatedScale }
    }

    // A manual value wins over the automatically calculated value.
    // Un valor manual tiene prioridad sobre el valor calculado automáticamente.
    // 手动设置的比例优先于自动计算的比例。
    public func setAdapterScale(_ scale: Double) {
        state.withLock { state in
            state.customScale = scale
            state.calculatedScale = scale
            state.isCalculated = true
        }
    }

    // UIKit-dependent calculation stays on MainActor; the final write remains locked.
    // El cálculo dependiente de UIKit permanece en MainActor; la escritura final sigue protegida.
    // 依赖 UIKit 的计算保留在 MainActor，最终写入仍由锁保护。
    @MainActor
    public func calculateScaleIfNeeded() {
        let calculatedScale = adapterScale ?? ptDefaultAdapterScale()
        state.withLock { state in
            guard !state.isCalculated else { return }
            state.calculatedScale = calculatedScale
            state.isCalculated = true
        }
    }
}

public protocol PTNumberValueAdapterable {
    associatedtype PTNumberValueAdapterType
    var adapter: PTNumberValueAdapterType { get }
}
