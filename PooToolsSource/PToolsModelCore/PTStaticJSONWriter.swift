//
//  PTStaticJSONWriter.swift
//
// English: Write generated static-schema fields directly without building a complete object dictionary.
// Español: Escribe campos de esquemas estáticos generados directamente sin construir un diccionario de objeto completo.
// 中文：直接写出生成的静态 Schema 字段，不先构建完整对象字典。
//

import Foundation

public enum PTStaticJSONWriter {
    public static func data(fields: [(PTModelFieldDescriptor, PTJSONValue?)],
                            using encoder: PTModelEncoder) throws -> Data {
        var sink = PTDataByteSink()
        try write(fields: fields, using: encoder, to: &sink)
        return sink.data
    }

    public static func write<Sink: PTJSONByteSink>(fields: [(PTModelFieldDescriptor, PTJSONValue?)],
                                                   using encoder: PTModelEncoder,
                                                   to sink: inout Sink) throws {
        if fields.contains(where: { $0.0.path != nil || $0.0.flattened }) {
            let value = try structuredValue(fields: fields, using: encoder)
            try sink.write(try value.jsonData(prettyPrinted: encoder.prettyPrinted,
                                              sortedKeys: encoder.sortedKeys || encoder.canonical,
                                              canonicalPolicy: encoder.canonical ? encoder.canonicalPolicy : nil))
            return
        }
        let ordered = encoder.sortedKeys || encoder.canonical
            ? fields.sorted { $0.0.mapping.encodeKey < $1.0.mapping.encodeKey }
            : fields
        try sink.write(Data("{".utf8))
        var outputIndex = 0
        for (descriptor, value) in ordered {
            guard let entry = try encoder.encodedField(value, for: descriptor) else { continue }
            if outputIndex > 0 { try sink.write(Data(",".utf8)) }
            outputIndex += 1
            try sink.write(try PTJSONValue.string(entry.0).jsonData(canonicalPolicy: encoder.canonical ? encoder.canonicalPolicy : nil))
            try sink.write(Data(":".utf8))
            try sink.write(try entry.1.jsonData(canonicalPolicy: encoder.canonical ? encoder.canonicalPolicy : nil))
        }
        try sink.write(Data("}".utf8))
    }

    // English: Rebuild only the structured fields needed by path and flat mappings before writing canonical JSON.
    // Español: Reconstruye solo los campos estructurados necesarios para mappings path y flat antes de escribir JSON canónico.
    // 中文：仅为 Path 和 Flat 映射重建必要的结构字段，再写出规范 JSON。
    private static func structuredValue(fields: [(PTModelFieldDescriptor, PTJSONValue?)],
                                        using encoder: PTModelEncoder) throws -> PTJSONValue {
        var object: [String: PTJSONValue] = [:]
        for (descriptor, value) in fields {
            guard let value else { continue }
            if descriptor.flattened {
                guard case .object(let nested) = value else {
                    throw PTModelError.typeMismatch(expected: "object for flattened field", actual: "non-object")
                }
                for (key, nestedValue) in nested {
                    guard object[key] == nil else { throw PTModelError.duplicateKey(key) }
                    object[key] = nestedValue
                }
                continue
            }
            guard let path = descriptor.path else {
                let key = encoder.keyPolicy.encodedKey(for: descriptor)
                guard object[key] == nil else {
                    throw PTModelError.duplicateKey(key)
                }
                object[key] = value
                continue
            }
            object = try placing(value, at: path, in: object)
        }
        return .object(object)
    }

    private static func placing(_ replacement: PTJSONValue,
                                at path: PTJSONPath,
                                in object: [String: PTJSONValue]) throws -> [String: PTJSONValue] {
        guard let first = path.components.first else {
            guard case .object(let replacementObject) = replacement else {
                throw PTModelError.rootIsNotObject
            }
            return replacementObject
        }
        guard case .key(let key) = first else {
            throw PTModelError.pathTypeMismatch(path.description)
        }
        let tail = PTJSONPath(Array(path.components.dropFirst()))
        var result = object
        if tail.components.isEmpty {
            guard result[key] == nil else { throw PTModelError.duplicateKey(key) }
            result[key] = replacement
            return result
        }
        let current = result[key] ?? .object([:])
        result[key] = try placeIntoValue(replacement, at: tail, in: current)
        return result
    }

    private static func placeIntoValue(_ replacement: PTJSONValue,
                                       at path: PTJSONPath,
                                       in value: PTJSONValue) throws -> PTJSONValue {
        guard let first = path.components.first else { return replacement }
        let tail = PTJSONPath(Array(path.components.dropFirst()))
        switch (first, value) {
        case (.key(let key), .object(var object)):
            if tail.components.isEmpty {
                guard object[key] == nil else { throw PTModelError.duplicateKey(key) }
                object[key] = replacement
            } else {
                object[key] = try placeIntoValue(replacement,
                                                 at: tail,
                                                 in: object[key] ?? .object([:]))
            }
            return .object(object)
        case (.index(let index), .array(var array)):
            guard array.indices.contains(index) else {
                throw PTModelError.patchFailed("Array index out of bounds: \(index)")
            }
            array[index] = try placeIntoValue(replacement, at: tail, in: array[index])
            return .array(array)
        default:
            throw PTModelError.pathTypeMismatch(path.description)
        }
    }
}
