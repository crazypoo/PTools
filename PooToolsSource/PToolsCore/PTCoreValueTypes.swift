//
//  PTCoreValueTypes.swift
//  PToolsCore
//
//  Immutable values shared across concurrency boundaries.
//  Valores inmutables compartidos entre límites de concurrencia.
//  在并发边界之间传递的不可变值类型。
//

import Foundation

// English: Keep these response and progress values free of UIKit and dynamic payloads.
// Español: Mantiene estos valores de respuesta y progreso libres de UIKit y payloads dinámicos.
// 中文：让响应和进度值类型不依赖 UIKit，也不携带动态对象。
public struct PTProgressSnapshot: Sendable, Equatable {
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

// English: Response metadata contains only immutable value types.
// Español: Los metadatos de respuesta contienen únicamente tipos de valor inmutables.
// 中文：响应元数据只包含不可变值类型。
public struct PTResponseMetadata: Sendable, Equatable {
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

// English: Preserve the legacy erased model while keeping new value types typed.
// Español: Conserva el modelo borrado heredado y mantiene tipados los nuevos valores.
// 中文：保留旧版擦除模型，同时让新的值类型保持明确类型。
public struct PTBaseStructModel<T> {
    public var originalString: String = ""
    public var customerModel: T?
    public var resultData: Data? = Data()

    public init() {}
}

extension PTBaseStructModel: Sendable where T: Sendable {}

public typealias PTLegacyStructModel = PTBaseStructModel<Any>

// English: Keep this compatibility box out of the UI and network layers.
// Español: Mantiene esta caja de compatibilidad fuera de las capas UI y de red.
// 中文：让这个兼容包装器不进入 UI 和网络层。
@available(*, deprecated, message: "Use a concrete Sendable value instead of boxing a metatype")
public struct PTSendableTypeBox<T: Sendable>: Sendable {
    public let type: T?

    public init(_ type: T?) {
        self.type = type
    }
}
