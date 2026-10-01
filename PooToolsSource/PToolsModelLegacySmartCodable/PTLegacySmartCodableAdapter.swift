//
//  PTLegacySmartCodableAdapter.swift
//
// English: Keep SmartCodable at an explicit optional compatibility boundary.
// Español: Mantiene SmartCodable en un límite de compatibilidad opcional y explícito.
// 中文：将 SmartCodable 保持在显式可选的兼容边界内。
//

import Foundation
import SmartCodable

public enum PTLegacySmartCodableAdapter {
    public static func decode<Model: SmartDecodable>(_ type: Model.Type,
                                                    data: Data) throws -> Model {
        guard let string = String(data: data, encoding: .utf8),
              let model = Model.deserialize(from: string) else {
            throw PTLegacySmartCodableError.decodeFailed
        }
        return model
    }

    public static func decode(_ type: Any.Type, data: Data) throws -> Any {
        guard let modelType = type as? any SmartDecodable.Type,
              let model = modelType.deserialize(from: data) else {
            throw PTLegacySmartCodableError.decodeFailed
        }
        return model
    }
}

public enum PTLegacySmartCodableError: Error, LocalizedError, Sendable {
    case decodeFailed

    public var errorDescription: String? {
        "SmartCodable compatibility decoding failed."
    }
}
