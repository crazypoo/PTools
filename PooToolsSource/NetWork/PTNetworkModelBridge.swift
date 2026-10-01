//
//  PTNetworkModelBridge.swift
//
// English: Typed response payloads keep raw bytes and metadata together without crossing actors with dynamic values.
// Español: Los payloads tipados mantienen bytes y metadatos juntos sin cruzar actores con valores dinámicos.
// 中文：类型化响应载荷把原始字节和元数据绑定在一起，不让动态值跨 actor 传递。
//

import Foundation
#if SWIFT_PACKAGE
import PToolsCore
import PToolsModelCore
import PToolsModelLegacySmartCodable
import PToolsModelLegacyKakaJSON
#endif

public struct PTNetworkResponsePayload: Sendable {
    public let url: URL?
    public let data: Data
    public let metadata: PTResponseMetadata

    public init(url: URL? = nil, data: Data, metadata: PTResponseMetadata = .init()) {
        self.url = url
        self.data = data
        self.metadata = metadata
    }

    public init(url: String, data: Data, metadata: PTResponseMetadata = .init()) {
        self.init(url: URL(string: url), data: data, metadata: metadata)
    }

    public var string: String? {
        String(data: data, encoding: .utf8)
    }

    // English: Keep UTF-8 access explicit for callers that want to avoid treating the payload as an always-present string.
    // Español: Mantiene explícito el acceso UTF-8 para no tratar el payload como una cadena siempre disponible.
    // 中文：提供明确的 UTF-8 访问入口，避免调用方把 payload 当成必然存在的字符串。
    public var utf8String: String? { string }
}

// English: Typed model responses keep raw bytes separate from model decoding and legacy wrappers.
// Español: Las respuestas tipadas separan los bytes sin procesar de la decodificación y los wrappers heredados.
// 中文：类型化模型响应把原始字节与模型解码、旧版包装器彻底分开。
public struct PTModelNetworkResponse<Model: Sendable>: Sendable {
    public let payload: PTNetworkResponsePayload
    public let model: Model

    public init(payload: PTNetworkResponsePayload, model: Model) {
        self.payload = payload
        self.model = model
    }
}

public enum PTNetworkDecoderKind: String, Sendable, Codable {
    case ptModel
    case smartCodable
    case kakaJSON
    case codable
}

public enum PTNetworkDecodeError: Error, LocalizedError, Sendable, Equatable {
    case emptyPayload
    case invalidUTF8
    case unsupportedDecoder(PTNetworkDecoderKind)
    case underlying(String)

    public var errorDescription: String? {
        switch self {
        case .emptyPayload: return "The network response has no payload."
        case .invalidUTF8: return "The network response is not valid UTF-8."
        case .unsupportedDecoder(let kind): return "Unsupported network decoder: \(kind.rawValue)."
        case .underlying(let message): return message
        }
    }
}

public struct PTNetworkResponseDecoder<Output: Sendable>: Sendable {
    public let kind: PTNetworkDecoderKind
    private let closure: @Sendable (PTNetworkResponsePayload) throws -> Output

    public init(kind: PTNetworkDecoderKind,
                decode: @escaping @Sendable (PTNetworkResponsePayload) throws -> Output) {
        self.kind = kind
        self.closure = decode
    }

    public func decode(_ payload: PTNetworkResponsePayload) throws -> Output {
        guard !payload.data.isEmpty else { throw PTNetworkDecodeError.emptyPayload }
        do {
            return try closure(payload)
        } catch let error as PTNetworkDecodeError {
            throw error
        } catch {
            throw PTNetworkDecodeError.underlying(error.localizedDescription)
        }
    }

    public static func ptModel<T: Decodable & Sendable>(_ type: T.Type) -> PTNetworkResponseDecoder<T> {
        PTNetworkResponseDecoder<T>(kind: .ptModel) { payload in
            try PTModelDecoder(policy: .compatible).decode(type, from: payload.data)
        }
    }

    public static func codable<T: Decodable & Sendable>(_ type: T.Type) -> PTNetworkResponseDecoder<T> {
        PTNetworkResponseDecoder<T>(kind: .codable) { payload in
            let decoder = JSONDecoder()
            do {
                return try decoder.decode(type, from: payload.data)
            } catch {
                throw PTNetworkDecodeError.underlying(error.localizedDescription)
            }
        }
    }

    // English: Legacy decoders stay type-erased and are available only through opt-in adapter products.
    // Español: Los decodificadores heredados permanecen borrados por tipo y solo están disponibles mediante adaptadores opt-in.
    // 中文：旧 decoder 使用类型擦除，仅通过显式 opt-in 适配器产品提供。
    public static func legacy<T: Sendable>(_ type: T.Type,
                                           kind: PTNetworkDecoderKind) -> PTNetworkResponseDecoder<T> {
        PTNetworkResponseDecoder<T>(kind: kind) { payload in
            let decoded: Any
            switch kind {
            case .smartCodable:
                decoded = try PTLegacySmartCodableAdapter.decode(type, data: payload.data)
            case .kakaJSON:
                decoded = try PTLegacyKakaJSONAdapter.decode(type, data: payload.data)
            default:
                throw PTNetworkDecodeError.unsupportedDecoder(kind)
            }
            guard let model = decoded as? T else {
                throw PTNetworkDecodeError.underlying("Legacy decoder returned an unexpected model type.")
            }
            return model
        }
    }

    public static func smartCodable<T: Sendable>(_ type: T.Type) -> PTNetworkResponseDecoder<T> {
        legacy(type, kind: .smartCodable)
    }

    public static func kakaJSON<T: Sendable>(_ type: T.Type) -> PTNetworkResponseDecoder<T> {
        legacy(type, kind: .kakaJSON)
    }
}

// English: Legacy reference models are decoded on the caller's MainActor and never cross the transport actor.
// Español: Los modelos de referencia heredados se decodifican en el MainActor del llamador y nunca cruzan el actor de transporte.
// 中文：旧版引用模型只在调用方 MainActor 解码，不跨越 Network transport actor。
@MainActor
public struct PTNetworkLegacyResponseDecoder<Output> {
    private let closure: (PTNetworkResponsePayload) throws -> Output

    public init(decode: @escaping (PTNetworkResponsePayload) throws -> Output) {
        self.closure = decode
    }

    public func decode(_ payload: PTNetworkResponsePayload) throws -> Output {
        guard !payload.data.isEmpty else { throw PTNetworkDecodeError.emptyPayload }
        return try closure(payload)
    }

    public static func legacy(_ type: Any.Type,
                              kind: PTNetworkDecoderKind) -> PTNetworkLegacyResponseDecoder<Any> {
        PTNetworkLegacyResponseDecoder<Any> { payload in
            switch kind {
            case .smartCodable:
                return try PTLegacySmartCodableAdapter.decode(type, data: payload.data)
            case .kakaJSON:
                return try PTLegacyKakaJSONAdapter.decode(type, data: payload.data)
            default:
                throw PTNetworkDecodeError.unsupportedDecoder(kind)
            }
        }
    }

    public static func smartCodable<T>(_ type: T.Type) -> PTNetworkLegacyResponseDecoder<T> {
        PTNetworkLegacyResponseDecoder<T> { payload in
            guard let model = try legacy(type, kind: .smartCodable).decode(payload) as? T else {
                throw PTNetworkDecodeError.underlying("SmartCodable returned an unexpected model type.")
            }
            return model
        }
    }

    public static func kakaJSON<T>(_ type: T.Type) -> PTNetworkLegacyResponseDecoder<T> {
        PTNetworkLegacyResponseDecoder<T> { payload in
            guard let model = try legacy(type, kind: .kakaJSON).decode(payload) as? T else {
                throw PTNetworkDecodeError.underlying("KakaJSON returned an unexpected model type.")
            }
            return model
        }
    }
}

extension PTNetworkResponsePayload {
    init(snapshot: PTNetworkResponseSnapshot) {
        self.init(url: URL(string: snapshot.url),
                  data: snapshot.data ?? Data(),
                  metadata: snapshot.metadata)
    }
}
