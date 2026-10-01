//
//  PTBaseModel.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/1.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
#if canImport(PToolsCore)
import PToolsCore
#endif

// English: Keep the base model Foundation/Codable-only; legacy codecs add their conformance from opt-in adapters.
// Español: Mantiene el modelo base solo con Foundation/Codable; los codecs heredados agregan su conformidad desde adaptadores opt-in.
// 中文：基础模型只依赖 Foundation/Codable；旧 codec 的兼容能力由可选适配器扩展提供。
open class PTBaseModel {
    required public init() {}
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
// English: The canonical model protocol is Codable-only; third-party codecs live in explicit legacy products.
// Español: El protocolo canónico solo usa Codable; los codecs de terceros viven en productos legacy explícitos.
// 中文：规范模型协议只依赖 Codable；第三方 codec 放在显式 legacy 产品中。
public protocol PTCodableModelProtocol: Codable, Sendable {}

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
