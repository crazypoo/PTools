//
//  PTLegacyKakaJSONAdapter.swift
//
// English: Keep KakaJSON at an explicit optional compatibility boundary.
// Español: Mantiene KakaJSON en un límite de compatibilidad opcional y explícito.
// 中文：将 KakaJSON 保持在显式可选的兼容边界内。
//

import Foundation
import KakaJSON

@MainActor
public enum PTLegacyKakaJSONAdapter {
    public static func decode<Model: Convertible>(_ type: Model.Type,
                                                   data: Data) throws -> Model {
        guard let string = String(data: data, encoding: .utf8),
              let model = string.kj.model(type) else {
            throw PTLegacyKakaJSONError.decodeFailed
        }
        return model
    }
}

public enum PTLegacyKakaJSONError: Error, LocalizedError, Sendable {
    case decodeFailed

    public var errorDescription: String? {
        "KakaJSON compatibility decoding failed."
    }
}
