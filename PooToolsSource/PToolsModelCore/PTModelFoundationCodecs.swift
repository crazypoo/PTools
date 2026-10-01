//
//  PTModelFoundationCodecs.swift
//
// English: Explicit Foundation value codecs keep date, data, URL, and stringified JSON behavior deterministic.
// Español: Los codecs explícitos de Foundation mantienen deterministas las fechas, datos, URLs y JSON como cadena.
// 中文：显式 Foundation 值 codec 让日期、Data、URL 和字符串化 JSON 的行为保持确定。
//

import Foundation

public enum PTModelFoundationCodec {
    public static func date(_ value: Date,
                            strategy: PTDateEncodingStrategy) throws -> PTJSONValue {
        switch strategy {
        case .deferredToDate:
            return .number(try PTJSONNumber(String(value.timeIntervalSinceReferenceDate)))
        case .secondsSince1970:
            return .number(try PTJSONNumber(String(value.timeIntervalSince1970)))
        case .millisecondsSince1970:
            return .number(try PTJSONNumber(String(value.timeIntervalSince1970 * 1_000)))
        case .iso8601:
            return .string(ISO8601DateFormatter().string(from: value))
        case .custom(let format):
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.dateFormat = format
            guard let string = formatter.string(for: value) else {
                throw PTModelError.conversionFailed("Unable to encode date with format: \(format)")
            }
            return .string(string)
        }
    }

    public static func date(from value: PTJSONValue,
                            strategy: PTDateDecodingStrategy) throws -> Date {
        switch strategy {
        case .secondsSince1970:
            guard case .number(let number) = value, let seconds = number.doubleValue else {
                throw PTModelError.typeMismatch(expected: "seconds", actual: "non-number")
            }
            return Date(timeIntervalSince1970: seconds)
        case .millisecondsSince1970:
            guard case .number(let number) = value, let milliseconds = number.doubleValue else {
                throw PTModelError.typeMismatch(expected: "milliseconds", actual: "non-number")
            }
            return Date(timeIntervalSince1970: milliseconds / 1_000)
        case .iso8601:
            guard case .string(let string) = value,
                  let date = ISO8601DateFormatter().date(from: string) else {
                throw PTModelError.typeMismatch(expected: "ISO8601 date", actual: "invalid string")
            }
            return date
        case .custom(let format):
            guard case .string(let string) = value else {
                throw PTModelError.typeMismatch(expected: "custom date string", actual: value.ptTypeName)
            }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.dateFormat = format
            guard let date = formatter.date(from: string) else {
                throw PTModelError.typeMismatch(expected: "custom date string", actual: string)
            }
            return date
        case .fallback(let strategies):
            var lastError: Error?
            for strategy in strategies {
                do {
                    return try date(from: value, strategy: strategy)
                } catch {
                    lastError = error
                }
            }
            throw lastError ?? PTModelError.typeMismatch(expected: "date", actual: value.ptTypeName)
        case .deferredToDate:
            guard case .number(let number) = value,
                  let seconds = number.doubleValue else {
                throw PTModelError.typeMismatch(expected: "date value", actual: "invalid value")
            }
            return Date(timeIntervalSinceReferenceDate: seconds)
        }
    }

    public static func data(_ value: Data,
                            strategy: PTDataEncodingStrategy) throws -> PTJSONValue {
        switch strategy {
        case .deferredToData:
            // English: Match Data.encode(to:) by preserving the byte-array representation.
            // Español: Coincide con Data.encode(to:) y conserva la representación como arreglo de bytes.
            // 中文：对齐 Data.encode(to:)，保留字节数组表示。
            var values: [PTJSONValue] = []
            values.reserveCapacity(value.count)
            for byte in value {
                guard let number = try? PTJSONNumber(String(byte)) else {
                    throw PTModelError.invalidJSON("Invalid Data byte")
                }
                values.append(.number(number))
            }
            return .array(values)
        case .base64:
            return .string(value.base64EncodedString())
        case .utf8:
            guard let string = String(data: value, encoding: .utf8) else {
                throw PTModelError.conversionFailed("Data is not valid UTF-8")
            }
            return .string(string)
        }
    }

    public static func data(from value: PTJSONValue,
                            strategy: PTDataDecodingStrategy) throws -> Data {
        guard case .string(let string) = value else {
            if case .array(let values) = value,
               strategy == .deferredToData {
                var bytes = Data()
                bytes.reserveCapacity(values.count)
                for value in values {
                    guard case .number(let number) = value,
                          let byte = number.uint64Value,
                          byte <= UInt64(UInt8.max) else {
                        throw PTModelError.typeMismatch(expected: "byte array", actual: "invalid byte")
                    }
                    bytes.append(UInt8(byte))
                }
                return bytes
            }
            throw PTModelError.typeMismatch(expected: "encoded data", actual: "non-string")
        }
        switch strategy {
        case .deferredToData:
            throw PTModelError.typeMismatch(expected: "byte array", actual: "string")
        case .base64:
            guard let data = Data(base64Encoded: string) else {
                throw PTModelError.conversionFailed("Invalid Base64 data")
            }
            return data
        case .utf8:
            return Data(string.utf8)
        }
    }

    public static func url(_ value: URL,
                           strategy: PTURLCodingStrategy = .absoluteString) -> PTJSONValue {
        .string(value.absoluteString)
    }

    public static func url(from value: PTJSONValue,
                           strategy: PTURLCodingStrategy = .deferredToURL) throws -> URL {
        guard case .string(let string) = value,
              let url = URL(string: string) else {
            throw PTModelError.typeMismatch(expected: "URL string", actual: "invalid value")
        }
        return url
    }

    public static func decodeStringified<T: Decodable>(
        _ type: T.Type,
        from value: PTJSONValue,
        decoder: PTModelDecoder = .init(),
        policy: PTStringifiedJSONPolicy = .collectionsAndModels
    ) throws -> T {
        guard policy != .disabled,
              case .string(let string) = value else {
            throw PTModelError.typeMismatch(expected: "stringified JSON", actual: "non-string")
        }
        // English: Prefer the static schema for nested PTModel values so aliases and annotations survive stringification.
        // Español: Prioriza el esquema estático para valores PTModel anidados y conserva alias y anotaciones.
        // 中文：字符串化的嵌套 PTModel 优先使用静态 Schema，确保别名和注解不会丢失。
        if let staticType = type as? any PTStaticDecodableType.Type,
           let decoded = try staticType.ptDecodeErased(from: Data(string.utf8), using: decoder) as? T {
            return decoded
        }
        return try decoder.decode(type, from: string)
    }

    public static func encodeStringified<T: Encodable>(
        _ value: T,
        encoder: PTModelEncoder = .init(),
        policy: PTStringifiedJSONPolicy = .collectionsAndModels
    ) throws -> PTJSONValue {
        guard policy != .disabled else {
            throw PTModelError.unsupportedFeature("Stringified JSON is disabled")
        }
        return .string(try encoder.jsonString(value))
    }
}

private extension PTJSONValue {
    // English: Keep error rendering local so Foundation codecs do not depend on decoder implementation details.
    // Español: Mantiene el texto de errores local para que los codecs de Foundation no dependan del decoder.
    // 中文：错误类型描述在本文件内完成，避免 Foundation codec 依赖 decoder 的实现细节。
    var ptTypeName: String {
        switch self {
        case .null: return "null"
        case .bool: return "bool"
        case .number: return "number"
        case .string: return "string"
        case .array: return "array"
        case .object: return "object"
        }
    }
}
