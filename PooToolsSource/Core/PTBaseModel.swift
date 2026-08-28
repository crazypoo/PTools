//
//  PTBaseModel.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/1.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SmartCodable
import KakaJSON

open class PTBaseModel: Convertible {
    required public init() {}
            
    // 实现kj_modelKey方法
    // 会传入模型的属性`property`作为参数，返回值就是属性对应的key
    open func kj_modelKey(from property: KakaJSON.Property) -> ModelPropertyKey {
        property.name
    }
    
    open func kj_modelValue(from jsonValue:Any?,_ property:KakaJSON.Property) -> Any? {
        return jsonValue
    }
}

extension PTBaseModel: PTDiffableModel {
    
    public var diffId: String {
        return "\(type(of: self))_\(ObjectIdentifier(self))"
    }
    
    public var diffHash: Int {
        return 0 // 默认不参与 diff（避免性能问题）
    }
}

// Codable-only models do not carry list-diff identity.
// Los modelos que solo codifican no transportan identidad para diffs de listas.
// 仅用于 Codable 的模型不再携带列表 Diffable 身份。
public protocol PTCodableModelProtocol: SmartCodableX {}

// 🌟 专门定义一个轻量级的空模型，用来给不需要解析 JSON 的接口占位
public struct PTDummyModel: PTCodableModelProtocol, Sendable {
    public init() {}
}

// 🌟 兼容旧版同时承担解析和列表 Diffable 身份的协议。
// Compatibilidad con el protocolo antiguo que mezclaba解析 y la identidad Diffable de listas.
// 兼容旧版同时承担解析能力和列表 Diffable 身份的协议。
@available(*, deprecated, message: "Use PTCodableModelProtocol for network models and PTDiffableModel with a stored diffId for list models")
public protocol PTModelProtocol: PTCodableModelProtocol, PTDiffableModel {}

@available(*, deprecated, message: "Use PTCodableModelProtocol for network models and PTDiffableModel with a stored diffId for list models")
public extension PTModelProtocol {
    var diffId: String {
        // Class instances have a stable identity; legacy value types use their reflected value.
        // Las instancias de clase tienen una identidad estable; los valores heredados usan su reflejo.
        // 类实例使用稳定对象身份；旧值类型使用反射值作为兼容回退。
        if Mirror(reflecting: self).displayStyle == .class {
            return "\(type(of: self))-\(ObjectIdentifier(self as AnyObject))"
        }
        return "\(type(of: self))-\(String(reflecting: self))"
    }
    
    var diffHash: Int {
        return 0
    }
    
    func didFinishMapping() {}
}

// Modern network responses are Sendable only when their payload is Sendable.
// The legacy KakaJSON/Any APIs keep the unconstrained specialization below;
// they do not gain a false Sendable guarantee from this value type.
public struct PTBaseStructModel<T> {
    public var originalString: String = ""
    public var customerModel: T? = nil
    public var resultData: Data? = Data()
    
    public init() {}
}

extension PTBaseStructModel: Sendable where T: Sendable {}

// 向下兼容旧版单体擦除模型
public typealias PTLegacyStructModel = PTBaseStructModel<Any>

// Progress values are converted to immutable data before crossing an actor boundary.
// Los valores de progreso se convierten en datos inmutables antes de cruzar un límite de actor.
// 进度值在跨越 actor 边界前会先转换为不可变数据。
public struct PTProgressSnapshot: Sendable {
    public let completedUnitCount: Int64
    public let totalUnitCount: Int64
    public let fractionCompleted: Double

    public init(completedUnitCount: Int64,
                totalUnitCount: Int64,
                fractionCompleted: Double) {
        self.completedUnitCount = completedUnitCount
        self.totalUnitCount = totalUnitCount
        self.fractionCompleted = fractionCompleted
    }
}

// Response metadata contains only value types and is safe to retain after a request callback returns.
// Los metadatos de respuesta contienen únicamente tipos de valor y son seguros después del callback.
// 响应元数据只包含值类型，可在请求回调结束后安全保留。
public struct PTResponseMetadata: Sendable {
    public let statusCode: Int?
    public let headers: [String: String]
    public let isDegraded: Bool
    public let isCancelled: Bool

    public init(statusCode: Int? = nil,
                headers: [String: String] = [:],
                isDegraded: Bool = false,
                isCancelled: Bool = false) {
        self.statusCode = statusCode
        self.headers = headers
        self.isDegraded = isDegraded
        self.isCancelled = isCancelled
    }
}

// Kept for source compatibility; new concurrency code does not use this box for metatypes.
// Se conserva por compatibilidad de código; el código nuevo no lo usa para metatipos.
// 为保持源码兼容而保留；新的并发代码不会用它包装元类型。
@available(*, deprecated, message: "Use a concrete Sendable value instead of boxing a metatype")
public struct PTSendableTypeBox<T: Sendable>: Sendable {
    public let type: T?

    public init(_ type: T?) {
        self.type = type
    }
}
