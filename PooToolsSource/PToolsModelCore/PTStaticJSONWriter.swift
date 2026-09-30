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
}
