//
//  PTBaseModel.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/1.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SmartCodable

// 🌟 1. 专门定义一个轻量级的空模型，用来给不需要解析 JSON 的接口占位
public struct PTDummyModel: PTModelProtocol {
    public init() {}
}

open class PTBaseModel: SmartCodableX {
    required public init() {}
    
    open func didFinishMapping() {}
}

extension PTBaseModel: PTDiffableModel {
    
    public var diffId: String {
        return "\(type(of: self))_\(ObjectIdentifier(self))"
    }
    
    public var diffHash: Int {
        return 0 // 默认不参与 diff（避免性能问题）
    }
}

// 🌟 1. 定义一个协议，要求遵守它的人必须同时遵守 SmartCodable 和 PTDiffableModel
public protocol PTModelProtocol: SmartCodableX, PTDiffableModel {
    // 如果你有所有模型共有的属性，比如 id，可以写在这里
    // var id: String? { get set }
}

// 🌟 2. 利用协议扩展，提供 Diffable 的默认实现！
// 这样所有遵守 PTModelProtocol 的结构体都不用再手写这两行代码了。
public extension PTModelProtocol {
    var diffId: String {
        // 对于 struct，这里最好用属性来做 hash，或者直接转 JSON 字符串作为标识
        // 因为 struct 没有 ObjectIdentifier
        return "\(type(of: self))-\(UUID().uuidString)"
    }
    
    var diffHash: Int {
        return 0 // 默认不参与 diff
    }
    
    // 如果需要保留 didFinishMapping 的默认空实现，可以加在这里
    func didFinishMapping() {}
}
