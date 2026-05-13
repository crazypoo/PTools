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

// 🌟 专门定义一个轻量级的空模型，用来给不需要解析 JSON 的接口占位
public struct PTDummyModel: PTModelProtocol {
    public init() {}
}

// 🌟 要求遵守它的人必须同时遵守 SmartCodable 和 PTDiffableModel
public protocol PTModelProtocol: SmartCodableX, PTDiffableModel {}

public extension PTModelProtocol {
    var diffId: String {
        return "\(type(of: self))-\(UUID().uuidString)"
    }
    
    var diffHash: Int {
        return 0
    }
    
    func didFinishMapping() {}
}

// 🌟 Swift 6 终极数据包裹：支持强泛型推断与向后兼容的并发载体
public struct PTBaseStructModel<T>: @unchecked Sendable {
    public var originalString: String = ""
    public var customerModel: T? = nil
    public var resultData: Data? = Data()
    
    public init() {}
}

// 向下兼容旧版单体擦除模型
public typealias PTLegacyStructModel = PTBaseStructModel<Any>

// 🌟 Swift 6 安全补丁：跨线程安全传递元类型的容器
public struct PTSendableTypeBox<T>: @unchecked Sendable {
    let type: T?
    init(_ type: T?) { self.type = type }
}
