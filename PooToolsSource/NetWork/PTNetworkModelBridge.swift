//
//  PTNetworkModelBridge.swift
//
// English: Typed response payloads keep raw bytes and metadata together without crossing actors with dynamic values.
// Español: Los payloads tipados mantienen bytes y metadatos juntos sin cruzar actores con valores dinámicos.
// 中文：类型化响应载荷把原始字节和元数据绑定在一起，不让动态值跨 actor 传递。
//

import Foundation
import SmartCodable
import KakaJSON
#if SWIFT_PACKAGE
import PToolsModelCore
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

#if SWIFT_PACKAGE
    public static func smartCodable<T: SmartCodable & Sendable>(_ type: T.Type) -> PTNetworkResponseDecoder<T> {
        PTNetworkResponseDecoder<T>(kind: .smartCodable) { payload in
            guard let string = payload.string else { throw PTNetworkDecodeError.invalidUTF8 }
            guard let model = T.deserialize(from: string) else {
                throw PTNetworkDecodeError.underlying("SmartCodable could not decode the response.")
            }
            return model
        }
    }
#else
    public static func smartCodable<T: SmartCodableX & Sendable>(_ type: T.Type) -> PTNetworkResponseDecoder<T> {
        PTNetworkResponseDecoder<T>(kind: .smartCodable) { payload in
            guard let string = payload.string else { throw PTNetworkDecodeError.invalidUTF8 }
            guard let model = T.deserialize(from: string) else {
                throw PTNetworkDecodeError.underlying("SmartCodable could not decode the response.")
            }
            return model
        }
    }
#endif

    public static func kakaJSON<T: Convertible & Sendable>(_ type: T.Type) -> PTNetworkResponseDecoder<T> {
        PTNetworkResponseDecoder<T>(kind: .kakaJSON) { payload in
            guard let string = payload.string else { throw PTNetworkDecodeError.invalidUTF8 }
            guard let model = string.kj.model(type) else {
                throw PTNetworkDecodeError.underlying("KakaJSON could not decode the response.")
            }
            return model
        }
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

#if SWIFT_PACKAGE
    public static func smartCodable<T: SmartCodable>(_ type: T.Type) -> PTNetworkLegacyResponseDecoder<T> {
        PTNetworkLegacyResponseDecoder<T> { payload in
            guard let string = payload.string,
                  let model = T.deserialize(from: string) else {
                throw PTNetworkDecodeError.underlying("SmartCodable could not decode the response.")
            }
            return model
        }
    }
#else
    public static func smartCodable<T: SmartCodableX>(_ type: T.Type) -> PTNetworkLegacyResponseDecoder<T> {
        PTNetworkLegacyResponseDecoder<T> { payload in
            guard let string = payload.string,
                  let model = T.deserialize(from: string) else {
                throw PTNetworkDecodeError.underlying("SmartCodable could not decode the response.")
            }
            return model
        }
    }
#endif

    public static func kakaJSON<T: Convertible>(_ type: T.Type) -> PTNetworkLegacyResponseDecoder<T> {
        PTNetworkLegacyResponseDecoder<T> { payload in
            guard let string = payload.string,
                  let model = string.kj.model(type) else {
                throw PTNetworkDecodeError.underlying("KakaJSON could not decode the response.")
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
