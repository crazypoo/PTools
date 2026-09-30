//
//  PTModelCodec.swift
//
// English: Codable-compatible model conversion without SmartCodable or KakaJSON dependencies.
// Español: Conversión compatible con Codable sin dependencias de SmartCodable ni KakaJSON.
// 中文：不依赖 SmartCodable 和 KakaJSON 的 Codable 兼容模型转换。
//

import Foundation

public struct PTModelDecoder: Sendable {
    public let policy: PTDecodePolicy
    public let duplicateKeyPolicy: PTDuplicateKeyPolicy
    public let limits: PTModelLimits
    public let dateStrategy: PTDateDecodingStrategy
    public let dataStrategy: PTDataDecodingStrategy
    public let floatingPointStrategy: PTFloatingPointStrategy
    public let urlStrategy: PTURLCodingStrategy
    public let context: PTModelContext
    public let dictionaryKeyStrategy: PTDictionaryKeyStrategy
    public let coercionPolicy: PTValueCoercionPolicy
    public let numericOverflowPolicy: PTNumericOverflowPolicy
    public let session: PTModelCodingSession

    public init(policy: PTDecodePolicy = .compatible,
                duplicateKeyPolicy: PTDuplicateKeyPolicy = .keepLast,
                limits: PTModelLimits = .init(),
                dateStrategy: PTDateDecodingStrategy = .deferredToDate,
                dataStrategy: PTDataDecodingStrategy = .base64,
                floatingPointStrategy: PTFloatingPointStrategy = .rejectNonConforming,
                urlStrategy: PTURLCodingStrategy = .deferredToURL,
                context: PTModelContext = .init(),
                dictionaryKeyStrategy: PTDictionaryKeyStrategy = .stringOnly,
                coercionPolicy: PTValueCoercionPolicy = .init(),
                numericOverflowPolicy: PTNumericOverflowPolicy = .error,
                session: PTModelCodingSession = .init()) {
        self.policy = policy
        self.duplicateKeyPolicy = duplicateKeyPolicy
        self.limits = limits
        self.dateStrategy = dateStrategy
        self.dataStrategy = dataStrategy
        self.floatingPointStrategy = floatingPointStrategy
        self.urlStrategy = urlStrategy
        self.context = context
        self.dictionaryKeyStrategy = dictionaryKeyStrategy
        self.coercionPolicy = coercionPolicy
        self.numericOverflowPolicy = numericOverflowPolicy
        self.session = session
    }

    // English: Each public decode starts with an isolated value session; nested calls receive scoped copies.
    // Español: Cada decode público empieza con una sesión de valor aislada; las llamadas anidadas reciben copias delimitadas.
    // 中文：每次公开 decode 都从独立值会话开始，嵌套调用使用带作用域的副本。
    public func scoped(to path: PTJSONPath) -> PTModelDecoder {
        var scopedSession = session
        scopedSession.push(path)
        return PTModelDecoder(policy: policy,
                               duplicateKeyPolicy: duplicateKeyPolicy,
                               limits: limits,
                               dateStrategy: dateStrategy,
                               dataStrategy: dataStrategy,
                               floatingPointStrategy: floatingPointStrategy,
                               urlStrategy: urlStrategy,
                               context: context,
                               dictionaryKeyStrategy: dictionaryKeyStrategy,
                               coercionPolicy: coercionPolicy,
                               numericOverflowPolicy: numericOverflowPolicy,
                               session: scopedSession)
    }

    public func jsonValue<Source: PTModelSource>(from source: Source) throws -> PTJSONValue {
        let data = try PTModelSourceBridge.data(from: source,
                                                duplicateKeyPolicy: duplicateKeyPolicy,
                                                limits: limits)
        return try PTJSONValue(data: data,
                               duplicateKeyPolicy: duplicateKeyPolicy,
                               limits: limits)
    }

    public func decode<T: Decodable, Source: PTModelSource>(_ type: T.Type, from source: Source) throws -> T {
        let data = try PTModelSourceBridge.data(from: source,
                                                duplicateKeyPolicy: duplicateKeyPolicy,
                                                limits: limits)
        // English: Parse once to enforce duplicate-key and resource limits before JSONDecoder sees the payload.
        // Español: Analiza una vez para aplicar duplicados y límites antes de entregar el payload a JSONDecoder.
        // 中文：先解析一次，在交给 JSONDecoder 前统一执行重复键和资源限制。
        let parsedValue = try PTJSONValue(data: data,
                                          duplicateKeyPolicy: duplicateKeyPolicy,
                                          limits: limits)
        let lifecycle = T.self as? any PTModelLifecycle.Type
        let lifecycleValue = try lifecycle?.ptWillDecode(parsedValue, using: self) ?? parsedValue
        // English: Decode the bounded tree first; JSONDecoder remains the compatibility fallback for custom Codable containers.
        // Español: Primero decodifica el árbol limitado; JSONDecoder queda como compatibilidad para contenedores Codable personalizados.
        // 中文：优先直接解码受限 JSON 树；自定义 Codable 容器仍由 JSONDecoder 作为兼容回退。
        do {
            let model = try treeDecode(type, from: lifecycleValue)
            try lifecycle?.ptDidDecode(lifecycleValue, using: self)
            return model
        } catch {
            // English: Keep the established Codable escape hatch for unsupported custom decoding implementations.
            // Español: Conserva la salida Codable existente para implementaciones de decodificación personalizadas no compatibles.
            // 中文：保留既有 Codable 逃生口，兼容暂不支持的自定义解码实现。
        }
        // English: Re-encode the normalized tree so JSONDecoder cannot silently reapply its own duplicate-key policy.
        // Español: Re-encode el árbol normalizado para que JSONDecoder no aplique silenciosamente otra política de claves duplicadas.
        // 中文：重新编码归一化后的树，避免 JSONDecoder 悄悄使用另一套重复键策略。
        let normalizedData = try lifecycleValue.jsonData(sortedKeys: false)
        let decoder = JSONDecoder()
        switch dateStrategy {
        case .deferredToDate: decoder.dateDecodingStrategy = .deferredToDate
        case .secondsSince1970: decoder.dateDecodingStrategy = .secondsSince1970
        case .millisecondsSince1970: decoder.dateDecodingStrategy = .millisecondsSince1970
        case .iso8601: decoder.dateDecodingStrategy = .iso8601
        case .custom, .fallback:
            // English: The custom strategy already ran in the tree decoder; keep the fallback deterministic if custom Codable is used.
            // Español: La estrategia personalizada ya se ejecutó en el tree decoder; el fallback Codable conserva un comportamiento determinista.
            // 中文：自定义策略已由 Tree Decoder 执行；进入 Codable 回退时使用确定的默认策略。
            decoder.dateDecodingStrategy = .deferredToDate
        }
        switch dataStrategy {
        case .deferredToData: decoder.dataDecodingStrategy = .deferredToData
        case .base64: decoder.dataDecodingStrategy = .base64
        case .utf8: decoder.dataDecodingStrategy = .base64
        }
        if floatingPointStrategy == .convertToString {
            decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "inf",
                                                                              negativeInfinity: "-inf",
                                                                              nan: "nan")
        }
        do {
            return try decoder.decode(T.self, from: normalizedData)
        } catch {
            guard policy != .strict else { throw PTModelError.underlying(error.localizedDescription) }
            if let fallback = try PTPrimitiveFallback.decode(type,
                                                             data: normalizedData,
                                                             coercion: coercionPolicy) {
                return fallback
            }
            throw PTModelError.underlying(error.localizedDescription)
        }
    }

    public func decodeValue<T: Decodable>(_ type: T.Type,
                                          from value: PTJSONValue,
                                          path: PTJSONPath = .root) throws -> T {
        do {
            return try decode(type, from: value)
        } catch {
            guard policy != .strict,
                  let fallback = try PTPrimitiveFallback.decode(type, value: value, coercion: coercionPolicy) else {
                throw PTModelError.underlying("\(path.description): \(error.localizedDescription)")
            }
            return fallback
        }
    }

    // English: Resolve one field into missing, null, invalid, or value without collapsing diagnostics into nil.
    // Español: Resuelve un campo como ausente, nulo, inválido o valor sin convertir los diagnósticos en nil.
    // 中文：将字段明确解析为 missing、null、invalid 或 value，不把诊断信息压成 nil。
    public func decodeField<T: Decodable>(_ type: T.Type,
                                          from object: PTJSONValue,
                                          key: String,
                                          path: PTJSONPath = .root) -> PTModelFieldState<T> {
        guard case .object(let values) = object else {
            return .invalid(path.appending(.key(key)).description)
        }
        guard let value = values[key] else { return .missing }
        let fieldPath = path.appending(.key(key))
        if case .null = value { return .null }
        do {
            return .value(try decodeValue(type, from: value, path: fieldPath))
        } catch let error as PTModelError {
            if case .numericOverflow(let raw) = error {
                return .overflow(raw)
            }
            return .invalid(fieldPath.description)
        } catch {
            return .invalid(fieldPath.description)
        }
    }

    // English: Empty-object behavior is explicit and does not require a macro-generated model initializer.
    // Español: El comportamiento de un objeto vacío es explícito y no requiere un inicializador generado por macro.
    // 中文：空对象行为显式配置，不依赖宏生成的模型初始化器。
    public func decodeOptional<T: Decodable>(_ type: T.Type,
                                             from value: PTJSONValue,
                                             emptyObjectStrategy: PTEmptyObjectStrategy = .preserve,
                                             defaultValue: T? = nil) throws -> T? {
        if case .null = value { return nil }
        if case .object(let object) = value, object.isEmpty {
            switch emptyObjectStrategy {
            case .preserve:
                break
            case .decodeAsNil:
                return nil
            case .decodeAsDefault:
                guard let defaultValue else {
                    throw PTModelError.conversionFailed("A default value is required for an empty object")
                }
                return defaultValue
            }
        }
        return try decodeValue(type, from: value)
    }

    // English: Decode an aliased field through the same coercion and path diagnostics as every other value.
    // Español: Decodifica un campo con alias usando la misma coerción y diagnósticos de ruta que los demás valores.
    // 中文：别名字段复用统一的类型转换和路径诊断逻辑。
    public func decodeAliased<T: Decodable>(_ type: T.Type,
                                            from object: PTJSONValue,
                                            mapping: PTModelKeyMapping,
                                            conflictPolicy: PTModelAliasConflictPolicy = .preferCanonical,
                                            path: PTJSONPath = .root) throws -> T? {
        guard let value = try object.aliasedValue(using: mapping, conflictPolicy: conflictPolicy) else {
            return nil
        }
        return try decodeValue(type, from: value, path: path.appending(.key(mapping.encodeKey)))
    }

    public func decodeArray<Element: Decodable>(_ type: Element.Type,
                                                from value: PTJSONValue,
                                                strategy: PTLossyCollectionStrategy = .fail,
                                                defaultValue: Element? = nil) throws -> [Element] {
        guard case .array(let values) = value else { throw PTModelError.rootIsNotArray }
        var result: [Element] = []
        for (index, value) in values.enumerated() {
            do {
                result.append(try decodeValue(type, from: value, path: PTJSONPath([.index(index)])))
            } catch {
                switch strategy {
                case .fail:
                    throw error
                case .skipInvalid:
                    continue
                case .preserveIndexAsNil:
                    throw PTModelError.invalidCollectionElement("[\(index)] requires an optional element result")
                case .replaceWithDefault:
                    guard let defaultValue else {
                        throw PTModelError.invalidCollectionElement("[\(index)]")
                    }
                    result.append(defaultValue)
                }
            }
        }
        return result
    }

    public func decodeOptionalArray<Element: Decodable>(_ type: Element.Type,
                                                        from value: PTJSONValue,
                                                        strategy: PTLossyCollectionStrategy = .preserveIndexAsNil) throws -> [Element?] {
        guard case .array(let values) = value else { throw PTModelError.rootIsNotArray }
        var result: [Element?] = []
        for (index, value) in values.enumerated() {
            do {
                result.append(try decodeValue(type, from: value, path: PTJSONPath([.index(index)])))
            } catch {
                switch strategy {
                case .preserveIndexAsNil:
                    result.append(nil)
                case .skipInvalid:
                    continue
                case .fail:
                    throw error
                case .replaceWithDefault:
                    throw PTModelError.invalidCollectionElement("[\(index)]")
                }
            }
        }
        return result
    }

    public func decodeDictionary<Key: Hashable & Decodable, Value: Decodable>(_ keyType: Key.Type,
                                                                                _ valueType: Value.Type,
                                                                                from value: PTJSONValue,
                                                                                strategy: PTLossyCollectionStrategy = .fail,
                                                                                defaultValue: Value? = nil) throws -> [Key: Value] {
        switch dictionaryKeyStrategy {
        case .keyValuePairs:
            guard case .array(let pairs) = value else { throw PTModelError.rootIsNotArray }
            var result: [Key: Value] = [:]
            for (index, pair) in pairs.enumerated() {
                do {
                    guard case .object(let object) = pair,
                          let keyValue = object["key"],
                          let itemValue = object["value"] else {
                        throw PTModelError.conversionFailed("Invalid key-value pair")
                    }
                    let key = try decodeValue(keyType, from: keyValue)
                    result[key] = try decodeValue(valueType, from: itemValue)
                } catch {
                    switch strategy {
                    case .fail: throw error
                    case .skipInvalid: continue
                    case .replaceWithDefault:
                        guard let defaultValue else {
                            throw PTModelError.invalidCollectionElement("[\(index)]")
                        }
                        guard case .object(let object) = pair,
                              let keyValue = object["key"] else {
                            throw PTModelError.invalidCollectionElement("[\(index)]")
                        }
                        result[try decodeValue(keyType, from: keyValue)] = defaultValue
                    case .preserveIndexAsNil:
                        throw PTModelError.invalidCollectionElement("[\(index)] requires an optional dictionary value")
                    }
                }
            }
            return result
        case .stringOnly, .losslessStringConvertible, .rawRepresentable:
            guard case .object(let object) = value else { throw PTModelError.rootIsNotObject }
            var result: [Key: Value] = [:]
            for (rawKey, itemValue) in object {
                do {
                    let key: Key
                    if dictionaryKeyStrategy == .stringOnly {
                        guard let string = rawKey as? Key else {
                            throw PTModelError.conversionFailed("Dictionary key is not String")
                        }
                        key = string
                    } else if let type = Key.self as? any LosslessStringConvertible.Type,
                              let parsed = type.init(rawKey) as? Key {
                        key = parsed
                    } else {
                        throw PTModelError.conversionFailed("Dictionary key cannot be decoded: \(rawKey)")
                    }
                    result[key] = try decodeValue(valueType, from: itemValue)
                } catch {
                    switch strategy {
                    case .fail: throw error
                    case .skipInvalid: continue
                    case .replaceWithDefault:
                        guard let defaultValue,
                              let type = Key.self as? any LosslessStringConvertible.Type,
                              let key = type.init(rawKey) as? Key else {
                            throw PTModelError.invalidCollectionElement(rawKey)
                        }
                        result[key] = defaultValue
                    case .preserveIndexAsNil:
                        throw PTModelError.invalidCollectionElement("\(rawKey) requires an optional dictionary value")
                    }
                }
            }
            return result
        }
    }

    public func decodeSet<Element: Hashable & Decodable>(_ type: Element.Type,
                                                          from value: PTJSONValue,
                                                          duplicatePolicy: PTSetDuplicatePolicy = .keepFirst) throws -> Set<Element> {
        guard case .array(let values) = value else { throw PTModelError.rootIsNotArray }
        var result: Set<Element> = []
        for (index, value) in values.enumerated() {
            let element = try decodeValue(type, from: value, path: PTJSONPath([.index(index)]))
            if duplicatePolicy == .reject, result.contains(element) {
                throw PTModelError.duplicateKey("array[\(index)]")
            }
            result.insert(element)
        }
        return result
    }

    public func decodeRawDictionary<Key: RawRepresentable & Hashable & Decodable, Value: Decodable>(_ keyType: Key.Type,
                                                                                                    _ valueType: Value.Type,
                                                                                                    from value: PTJSONValue) throws -> [Key: Value]
    where Key.RawValue: LosslessStringConvertible {
        guard case .object(let object) = value else { throw PTModelError.rootIsNotObject }
        var result: [Key: Value] = [:]
        for (rawKey, itemValue) in object {
            guard let rawValue = Key.RawValue(rawKey), let key = Key(rawValue: rawValue) else {
                throw PTModelError.conversionFailed("Dictionary key cannot be decoded: \(rawKey)")
            }
            result[key] = try decodeValue(valueType, from: itemValue)
        }
        return result
    }

    // English: RawRepresentable dictionary keys are decoded through the configured strategy instead of a side API.
    // Español: Las claves RawRepresentable se decodifican mediante la estrategia configurada y no por una API paralela.
    // 中文：RawRepresentable 字典 key 通过统一策略解码，不再依赖旁路 API。
    public func decodeDictionary<Key: RawRepresentable & Hashable & Decodable, Value: Decodable>(
        _ keyType: Key.Type,
        _ valueType: Value.Type,
        from value: PTJSONValue,
        strategy: PTLossyCollectionStrategy = .fail,
        defaultValue: Value? = nil
    ) throws -> [Key: Value]
    where Key.RawValue: LosslessStringConvertible {
        guard dictionaryKeyStrategy == .rawRepresentable else {
            return try decodeRawDictionary(keyType, valueType, from: value)
        }
        guard case .object(let object) = value else { throw PTModelError.rootIsNotObject }
        var result: [Key: Value] = [:]
        for (rawKey, itemValue) in object {
            do {
                guard let rawValue = Key.RawValue(rawKey), let key = Key(rawValue: rawValue) else {
                    throw PTModelError.conversionFailed("Dictionary key cannot be decoded: \(rawKey)")
                }
                result[key] = try decodeValue(valueType, from: itemValue)
            } catch {
                switch strategy {
                case .fail: throw error
                case .skipInvalid: continue
                case .replaceWithDefault:
                    guard let defaultValue,
                          let rawValue = Key.RawValue(rawKey),
                          let key = Key(rawValue: rawValue) else {
                        throw PTModelError.invalidCollectionElement(rawKey)
                    }
                    result[key] = defaultValue
                case .preserveIndexAsNil:
                    throw PTModelError.invalidCollectionElement(rawKey)
                }
            }
        }
        return result
    }

    public static func decode<T: Decodable, Source: PTModelSource>(_ type: T.Type,
                                                                    from source: Source,
                                                                    policy: PTDecodePolicy = .compatible) throws -> T {
        try PTModelDecoder(policy: policy).decode(type, from: source)
    }
}

public struct PTModelEncoder: Sendable {
    public let prettyPrinted: Bool
    public let sortedKeys: Bool
    public let nilStrategy: PTNilEncodingStrategy
    public let dateStrategy: PTDateEncodingStrategy
    public let dataStrategy: PTDataEncodingStrategy
    public let floatingPointStrategy: PTFloatingPointStrategy
    public let urlStrategy: PTURLCodingStrategy
    public let dictionaryKeyStrategy: PTDictionaryKeyStrategy
    public let canonical: Bool
    public let canonicalPolicy: PTCanonicalJSONPolicy
    public let session: PTModelCodingSession

    public init(prettyPrinted: Bool = false,
                sortedKeys: Bool = true,
                nilStrategy: PTNilEncodingStrategy = .omit,
                dateStrategy: PTDateEncodingStrategy = .deferredToDate,
                dataStrategy: PTDataEncodingStrategy = .base64,
                floatingPointStrategy: PTFloatingPointStrategy = .rejectNonConforming,
                urlStrategy: PTURLCodingStrategy = .deferredToURL,
                dictionaryKeyStrategy: PTDictionaryKeyStrategy = .stringOnly,
                canonical: Bool = false,
                canonicalPolicy: PTCanonicalJSONPolicy = .ptModel,
                session: PTModelCodingSession = .init()) {
        self.prettyPrinted = prettyPrinted
        self.sortedKeys = sortedKeys
        self.nilStrategy = nilStrategy
        self.dateStrategy = dateStrategy
        self.dataStrategy = dataStrategy
        self.floatingPointStrategy = floatingPointStrategy
        self.urlStrategy = urlStrategy
        self.dictionaryKeyStrategy = dictionaryKeyStrategy
        self.canonical = canonical
        self.canonicalPolicy = canonicalPolicy
        self.session = session
    }

    // English: Static-schema encoders use this decision before inserting a field into an object.
    // Español: Los encoders de esquema estático usan esta decisión antes de insertar un campo en un objeto.
    // 中文：静态 Schema 编码器在把字段写入对象前统一使用这个决策。
    public func encodedField(_ value: PTJSONValue?,
                             for field: PTModelFieldDescriptor) throws -> (String, PTJSONValue)? {
        guard let value else {
            let strategy: PTNilEncodingStrategy
            switch field.encoding {
            case .omit: strategy = .omit
            case .null: strategy = .null
            case .required: throw PTModelError.requiredValue(field.name)
            case .inherit: strategy = field.nilStrategy ?? nilStrategy
            }
            return strategy == .null ? (field.mapping.encodeKey, .null) : nil
        }
        return (field.mapping.encodeKey, value)
    }

    // English: Nested static schemas inherit the current encoder path instead of starting a shared mutable frame.
    // Español: Los esquemas estáticos anidados heredan la ruta actual del encoder sin compartir un frame mutable.
    // 中文：嵌套静态 Schema 继承当前 encoder 路径，不共享可变 frame。
    public func scoped(to path: PTJSONPath) -> PTModelEncoder {
        var scopedSession = session
        scopedSession.push(path)
        return PTModelEncoder(prettyPrinted: prettyPrinted,
                              sortedKeys: sortedKeys,
                              nilStrategy: nilStrategy,
                              dateStrategy: dateStrategy,
                              dataStrategy: dataStrategy,
                              floatingPointStrategy: floatingPointStrategy,
                              urlStrategy: urlStrategy,
                              dictionaryKeyStrategy: dictionaryKeyStrategy,
                              canonical: canonical,
                              canonicalPolicy: canonicalPolicy,
                              session: scopedSession)
    }

    public func object(fields: [(PTModelFieldDescriptor, PTJSONValue?)]) throws -> PTJSONValue {
        var values: [String: PTJSONValue] = [:]
        values.reserveCapacity(fields.count)
        for (field, value) in fields {
            guard let (key, encoded) = try encodedField(value, for: field) else { continue }
            if field.flattened {
                guard case .object(let flattenedValues) = encoded else {
                    let actual: String
                    switch encoded {
                    case .null: actual = "null"
                    case .bool: actual = "bool"
                    case .number: actual = "number"
                    case .string: actual = "string"
                    case .array: actual = "array"
                    case .object: actual = "object"
                    }
                    throw PTModelError.typeMismatch(expected: "object for flattened field", actual: actual)
                }
                for (flattenedKey, flattenedValue) in flattenedValues {
                    if values[flattenedKey] != nil { throw PTModelError.duplicateKey(flattenedKey) }
                    values[flattenedKey] = flattenedValue
                }
                continue
            }
            if values[key] != nil { throw PTModelError.duplicateKey(key) }
            values[key] = encoded
        }
        return .object(values)
    }

    public func encode<T: Encodable>(_ value: T) throws -> Data {
        if let lifecycle = T.self as? any PTModelLifecycle.Type {
            // English: Lifecycle-enabled models use the same normalized PTJSONValue for both hooks and output.
            // Español: Los modelos con ciclo de vida usan el mismo PTJSONValue normalizado para hooks y salida.
            // 中文：启用生命周期的模型统一使用同一个规范化 PTJSONValue 供钩子和输出使用。
            let prepared = try lifecycle.ptWillEncode(treeJSONValue(value), using: self)
            let data = try prepared.jsonData(prettyPrinted: prettyPrinted,
                                             sortedKeys: sortedKeys || canonical,
                                             canonicalPolicy: canonicalPolicy)
            try lifecycle.ptDidEncode(prepared, using: self)
            return data
        }
        if canonical || dataStrategy == .utf8 {
            return try treeJSONValue(value).jsonData(prettyPrinted: prettyPrinted,
                                                     sortedKeys: sortedKeys || canonical,
                                                     canonicalPolicy: canonical ? canonicalPolicy : nil)
        }
        let encoder = JSONEncoder()
        if prettyPrinted { encoder.outputFormatting.insert(.prettyPrinted) }
        if sortedKeys || canonical { encoder.outputFormatting.insert(.sortedKeys) }
        switch dateStrategy {
        case .deferredToDate: encoder.dateEncodingStrategy = .deferredToDate
        case .secondsSince1970: encoder.dateEncodingStrategy = .secondsSince1970
        case .millisecondsSince1970: encoder.dateEncodingStrategy = .millisecondsSince1970
        case .iso8601: encoder.dateEncodingStrategy = .iso8601
        case .custom:
            // English: Custom date formats are handled by the PTJSONValue path, not by JSONEncoder's fixed strategies.
            // Español: Los formatos de fecha personalizados usan la ruta PTJSONValue, no las estrategias fijas de JSONEncoder.
            // 中文：自定义日期格式走 PTJSONValue 路径，不交给 JSONEncoder 的固定策略。
            return try treeJSONValue(value).jsonData(prettyPrinted: prettyPrinted,
                                                     sortedKeys: sortedKeys || canonical,
                                                     canonicalPolicy: canonicalPolicy)
        }
        switch dataStrategy {
        case .deferredToData: encoder.dataEncodingStrategy = .deferredToData
        case .base64: encoder.dataEncodingStrategy = .base64
        case .utf8: break
        }
        if floatingPointStrategy == .convertToString {
            encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "inf",
                                                                           negativeInfinity: "-inf",
                                                                           nan: "nan")
        }
        return try encoder.encode(value)
    }

    public func encode(_ value: PTJSONValue) throws -> Data {
        try value.jsonData(prettyPrinted: prettyPrinted,
                           sortedKeys: sortedKeys || canonical,
                           canonicalPolicy: canonical ? canonicalPolicy : nil)
    }

    public func jsonValue<T: Encodable>(_ value: T) throws -> PTJSONValue {
        if let value = value as? PTJSONValue { return value }
        return try PTJSONValue(data: encode(value), duplicateKeyPolicy: .reject)
    }

    // English: Preserve an absent optional so static schemas can apply omit/null at the field boundary.
    // Español: Conserva el opcional ausente para que los esquemas estáticos apliquen omit/null en el campo.
    // 中文：保留缺失的 Optional，让静态 Schema 在字段边界统一应用 omit/null 策略。
    public func optionalJSONValue<T: Encodable>(_ value: T?) throws -> PTJSONValue? {
        guard let value else { return nil }
        return try jsonValue(value)
    }

    public func jsonString<T: Encodable>(_ value: T) throws -> String {
        try jsonValue(value).jsonString(prettyPrinted: prettyPrinted,
                                        sortedKeys: sortedKeys || canonical,
                                        canonicalPolicy: canonical ? canonicalPolicy : nil)
    }

    public func dictionary<T: Encodable>(_ value: T) throws -> [String: Any] {
        guard case .object(let object) = try jsonValue(value) else {
            throw PTModelError.rootIsNotObject
        }
        return object.mapValues(\.foundationObject)
    }

    public func array<T: Encodable>(_ value: T) throws -> [Any] {
        guard case .array(let array) = try jsonValue(value) else {
            throw PTModelError.rootIsNotArray
        }
        return array.map(\.foundationObject)
    }

    public func jsonValue<Key: Hashable & Encodable, Value: Encodable>(dictionary: [Key: Value]) throws -> PTJSONValue {
        switch dictionaryKeyStrategy {
        case .stringOnly:
            var object: [String: PTJSONValue] = [:]
            for (key, value) in dictionary {
                guard let string = key as? String else {
                    throw PTModelError.conversionFailed("Dictionary key is not String")
                }
                object[string] = try jsonValue(value)
            }
            return .object(object)
        case .losslessStringConvertible:
            var object: [String: PTJSONValue] = [:]
            for (key, value) in dictionary {
                guard let string = key as? any LosslessStringConvertible else {
                    throw PTModelError.conversionFailed("Dictionary key is not LosslessStringConvertible")
                }
                object[String(string)] = try jsonValue(value)
            }
            return .object(object)
        case .rawRepresentable:
            throw PTModelError.conversionFailed("Use encodeRawDictionary for RawRepresentable keys")
        case .keyValuePairs:
            var pairs: [(String, PTJSONValue)] = []
            pairs.reserveCapacity(dictionary.count)
            for (key, value) in dictionary {
                let pair: PTJSONValue = .object(["key": try jsonValue(key), "value": try jsonValue(value)])
                pairs.append((try pair.jsonString(sortedKeys: true), pair))
            }
            return .array(pairs.sorted { $0.0 < $1.0 }.map(\.1))
        }
    }

    // English: RawRepresentable keys use the same strategy entry point as String and LosslessStringConvertible keys.
    // Español: Las claves RawRepresentable usan el mismo punto de entrada que String y LosslessStringConvertible.
    // 中文：RawRepresentable key 与 String、LosslessStringConvertible 共用同一个策略入口。
    public func jsonValue<Key: RawRepresentable & Hashable & Encodable, Value: Encodable>(dictionary: [Key: Value]) throws -> PTJSONValue
    where Key.RawValue: LosslessStringConvertible {
        guard dictionaryKeyStrategy == .rawRepresentable else {
            return try jsonValue(rawDictionary: dictionary)
        }
        return try jsonValue(rawDictionary: dictionary)
    }

    public func jsonValue<Key: RawRepresentable & Hashable & Encodable, Value: Encodable>(rawDictionary: [Key: Value]) throws -> PTJSONValue
    where Key.RawValue: LosslessStringConvertible {
        var object: [String: PTJSONValue] = [:]
        for (key, value) in rawDictionary {
            object[String(key.rawValue)] = try jsonValue(value)
        }
        return .object(object)
    }

    public func encode<Key: RawRepresentable & Hashable & Encodable, Value: Encodable>(rawDictionary: [Key: Value]) throws -> Data
    where Key.RawValue: LosslessStringConvertible {
        try jsonValue(rawDictionary: rawDictionary).jsonData(prettyPrinted: prettyPrinted, sortedKeys: sortedKeys)
    }

    public func encode<Key: Hashable & Encodable, Value: Encodable>(dictionary: [Key: Value]) throws -> Data {
        try jsonValue(dictionary: dictionary).jsonData(prettyPrinted: prettyPrinted, sortedKeys: sortedKeys)
    }

    public func jsonValue<Element: Hashable & Encodable>(set: Set<Element>) throws -> PTJSONValue {
        let values = try set.map { try jsonValue($0) }
        let sorted = try values.sorted {
            try $0.jsonString(sortedKeys: true) < $1.jsonString(sortedKeys: true)
        }
        return .array(sorted)
    }

    public func encode<Element: Hashable & Encodable>(set: Set<Element>) throws -> Data {
        try jsonValue(set: set).jsonData(prettyPrinted: prettyPrinted, sortedKeys: sortedKeys)
    }

    public func write<T: Encodable, Sink: PTJSONByteSink>(_ value: T, to sink: inout Sink) throws {
        try sink.write(encode(value))
    }

    public static func encode<T: Encodable>(_ value: T,
                                            prettyPrinted: Bool = false,
                                            sortedKeys: Bool = true) throws -> Data {
        try PTModelEncoder(prettyPrinted: prettyPrinted, sortedKeys: sortedKeys).encode(value)
    }
}

public extension PTModelNamespace {
    func model<Source: PTModelSource>(from source: Source,
                                      using decoder: PTModelDecoder = .init()) throws -> Model where Model: Decodable {
        try decoder.decode(Model.self, from: source)
    }

    func models<Source: PTModelSource>(from source: Source,
                                       using decoder: PTModelDecoder = .init()) throws -> [Model] where Model: Decodable {
        try decoder.decode([Model].self, from: source)
    }

    func jsonData(using encoder: PTModelEncoder = .init()) throws -> Data where Model: Encodable {
        guard let value = value else { throw PTModelError.invalidInput }
        return try encoder.encode(value)
    }

    func jsonString(using encoder: PTModelEncoder = .init()) throws -> String where Model: Encodable {
        guard let value = value else { throw PTModelError.invalidInput }
        return try encoder.jsonString(value)
    }

    func dictionary(using encoder: PTModelEncoder = .init()) throws -> [String: Any] where Model: Encodable {
        guard let value = value else { throw PTModelError.invalidInput }
        return try encoder.dictionary(value)
    }

    func jsonArray(using encoder: PTModelEncoder = .init()) throws -> [Any] where Model: Encodable {
        guard let value = value else { throw PTModelError.invalidInput }
        return try encoder.array(value)
    }
}

public extension Encodable {
    var ptModel: PTModelNamespace<Self> { PTModelNamespace(value: self) }
}

private enum PTModelSourceBridge {
    static func data(from source: any PTModelSource,
                    duplicateKeyPolicy: PTDuplicateKeyPolicy,
                    limits: PTModelLimits) throws -> Data {
        if let data = source as? Data {
            guard data.count <= limits.maxInputBytes else { throw PTModelError.inputTooLarge }
            return data
        }
        if let string = source as? String {
            let data = Data(string.utf8)
            guard data.count <= limits.maxInputBytes else { throw PTModelError.inputTooLarge }
            return data
        }
        if let value = source as? PTJSONValue {
            return try value.jsonData(sortedKeys: duplicateKeyPolicy != .keepFirst)
        }
        if let dictionary = source as? [String: Any] {
            let value = try PTFoundationJSONBridge.value(from: dictionary, limits: limits)
            return try value.jsonData(sortedKeys: true)
        }
        if let array = source as? [Any] {
            let value = try PTFoundationJSONBridge.value(from: array, limits: limits)
            return try value.jsonData(sortedKeys: true)
        }
        if let dictionary = source as? NSDictionary {
            let value = try PTFoundationJSONBridge.value(from: dictionary, limits: limits)
            return try value.jsonData(sortedKeys: true)
        }
        if let array = source as? NSArray {
            let value = try PTFoundationJSONBridge.value(from: array, limits: limits)
            return try value.jsonData(sortedKeys: true)
        }
        throw PTModelError.unsupportedSource(String(reflecting: type(of: source)))
    }
}

private enum PTPrimitiveFallback {
    static func decode<T: Decodable>(_ type: T.Type,
                                     data: Data,
                                     coercion: PTValueCoercionPolicy = .init()) throws -> T? {
        let value = try? PTJSONValue(data: data)
        guard let value else { return nil }
        return try decode(type, value: value, coercion: coercion)
    }

    static func decode<T: Decodable>(_ type: T.Type,
                                     value: PTJSONValue,
                                     coercion: PTValueCoercionPolicy) throws -> T? {
        switch value {
        case .string(let string):
            if type == String.self { return string as? T }
            guard coercion.stringToNumber || type == Bool.self else { return nil }
            if type == Int.self { return Int(string) as? T }
            if type == Int64.self { return Int64(string) as? T }
            if type == UInt.self { return UInt(string) as? T }
            if type == UInt64.self { return UInt64(string) as? T }
            if type == Double.self { return Double(string) as? T }
            if type == Float.self { return Float(string) as? T }
            if type == Bool.self, coercion.yesNoToBool { return parseBool(string) as? T }
        case .number(let number):
            if type == String.self, coercion.numberToString { return number.rawRepresentation as? T }
            if type == Int.self { return number.int64Value.flatMap(Int.init) as? T }
            if type == Int64.self { return number.int64Value as? T }
            if type == UInt.self { return number.uint64Value.flatMap(UInt.init) as? T }
            if type == UInt64.self { return number.uint64Value as? T }
            if type == Double.self { return number.doubleValue as? T }
            if type == Float.self { return number.doubleValue.flatMap(Float.init) as? T }
        case .bool(let value):
            if type == Bool.self { return value as? T }
            if type == String.self { return (value ? "true" : "false") as? T }
            if type == Int.self, coercion.boolToInteger { return (value ? 1 : 0) as? T }
        default:
            break
        }
        return nil
    }

    private static func parseBool(_ value: String) -> Bool? {
        switch value.lowercased() {
        case "true", "yes", "y", "1": return true
        case "false", "no", "n", "0": return false
        default: return nil
        }
    }
}
