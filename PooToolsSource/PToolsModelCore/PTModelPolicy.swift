//
//  PTModelPolicy.swift
//
// English: Field recovery, diagnostics, and validation contracts for PTModel static schemas.
// Español: Contratos de recuperación de campos, diagnósticos y validación para esquemas PTModel estáticos.
// 中文：PTModel 静态 Schema 的字段恢复、诊断和校验契约。
//

import Foundation

public struct PTModelDiagnostic: Sendable, Codable, Hashable, Equatable, LocalizedError {
    public enum Severity: String, Sendable, Codable, Hashable {
        case info
        case warning
        case error
    }

    public let severity: Severity
    public let path: PTJSONPath
    public let code: String
    public let message: String

    public init(severity: Severity = .error,
                path: PTJSONPath = .root,
                code: String,
                message: String) {
        self.severity = severity
        self.path = path
        self.code = code
        self.message = message
    }

    public var errorDescription: String? {
        "[\(code)] \(path.description): \(message)"
    }
}

// English: Decode traces make recovery decisions observable without coupling the core to a logger.
// Español: Las trazas de decodificación hacen observables las decisiones de recuperación sin acoplar el núcleo a un logger.
// 中文：解码轨迹让恢复决策可观察，同时不让 Core 绑定具体日志系统。
public struct PTDecodeTraceEvent: Sendable, Codable, Hashable, Equatable {
    public enum Kind: String, Sendable, Codable, Hashable {
        case missing
        case null
        case invalid
        case defaultValue
        case ignored
        case value
    }

    public let kind: Kind
    public let path: PTJSONPath
    public let message: String?
    public let reason: PTFieldRecoveryReason?

    public init(kind: Kind,
                path: PTJSONPath,
                message: String? = nil,
                reason: PTFieldRecoveryReason? = nil) {
        self.kind = kind
        self.path = path
        self.message = message
        self.reason = reason
    }
}

// English: Warnings are a small value type for callers that need non-fatal decode feedback.
// Español: Las advertencias son un tipo valor pequeño para feedback no fatal durante la decodificación.
// 中文：Warning 是轻量值类型，供调用方接收非致命解码反馈。
public struct PTDecodeWarning: Sendable, Codable, Hashable, Equatable, LocalizedError {
    public let path: PTJSONPath
    public let code: String
    public let message: String

    public init(path: PTJSONPath = .root, code: String, message: String) {
        self.path = path
        self.code = code
        self.message = message
    }

    public var errorDescription: String? {
        "[\(code)] \(path.description): \(message)"
    }
}

// English: A trace is mutable only at the caller boundary, so nested decoding remains value-typed and race-free.
// Español: La traza solo es mutable en el límite del llamador y la decodificación anidada sigue siendo de tipo valor y segura.
// 中文：轨迹只在调用方边界可变，嵌套解码仍保持值类型和无数据竞争。
public struct PTDecodeTrace: Sendable, Codable, Hashable, Equatable {
    public private(set) var events: [PTDecodeTraceEvent]

    public init(events: [PTDecodeTraceEvent] = []) {
        self.events = events
    }

    public mutating func append(_ event: PTDecodeTraceEvent) {
        events.append(event)
    }

    public var warnings: [PTDecodeWarning] {
        events.compactMap { event in
            guard event.kind == .invalid || event.kind == .defaultValue || event.kind == .ignored else { return nil }
            return PTDecodeWarning(path: event.path,
                                   code: "PTModel.\(event.kind.rawValue)",
                                   message: event.message ?? event.kind.rawValue)
        }
    }
}

// English: Sinks receive diagnostics without forcing model decoding to log globally or share mutable state.
// Español: Los sinks reciben diagnósticos sin obligar al decoder a registrar globalmente ni compartir estado mutable.
// 中文：诊断 Sink 接收错误信息，不要求 decoder 使用全局日志或共享可变状态。
public protocol PTModelDiagnosticSink: Sendable {
    func record(_ diagnostic: PTModelDiagnostic)
}

public struct PTNoopDiagnosticSink: PTModelDiagnosticSink, Sendable {
    public init() {}
    public func record(_ diagnostic: PTModelDiagnostic) {}
}

public actor PTModelDiagnosticStore {
    private var values: [PTModelDiagnostic] = []

    public init() {}

    public func record(_ diagnostic: PTModelDiagnostic) {
        values.append(diagnostic)
    }

    public func diagnostics() -> [PTModelDiagnostic] {
        values
    }

    public func removeAll() {
        values.removeAll(keepingCapacity: true)
    }

    // English: The adapter keeps the synchronous diagnostic protocol non-blocking while the actor owns storage.
    // Español: El adaptador mantiene no bloqueante el protocolo síncrono mientras el actor es dueño del almacenamiento.
    // 中文：适配器保持同步诊断协议非阻塞，同时由 actor 独占存储。
    public nonisolated var sink: PTModelDiagnosticStoreSink {
        PTModelDiagnosticStoreSink(store: self)
    }
}

// English: Record diagnostics asynchronously so an actor-backed store remains safe under concurrent validation.
// Español: Registra diagnósticos de forma asíncrona para que el almacén basado en actor siga siendo seguro.
// 中文：异步记录诊断信息，让 actor 存储在并发校验下保持安全。
public struct PTModelDiagnosticStoreSink: PTModelDiagnosticSink, Sendable {
    private let store: PTModelDiagnosticStore

    public init(store: PTModelDiagnosticStore) {
        self.store = store
    }

    public func record(_ diagnostic: PTModelDiagnostic) {
        Task { await store.record(diagnostic) }
    }
}

public struct PTModelValidationContext: Sendable {
    public let path: PTJSONPath
    public let session: PTModelCodingSession
    public let diagnosticSink: any PTModelDiagnosticSink

    public init(path: PTJSONPath = .root,
                session: PTModelCodingSession = .init(),
                diagnosticSink: any PTModelDiagnosticSink = PTNoopDiagnosticSink()) {
        self.path = path
        self.session = session
        self.diagnosticSink = diagnosticSink
    }

    public func report(code: String,
                       message: String,
                       severity: PTModelDiagnostic.Severity = .error,
                       at path: PTJSONPath? = nil) {
        diagnosticSink.record(PTModelDiagnostic(severity: severity,
                                                 path: path ?? self.path,
                                                 code: code,
                                                 message: message))
    }
}

public struct PTModelValidator<Model: Sendable>: Sendable {
    private let closure: @Sendable (Model, PTModelValidationContext) throws -> Void

    public init(_ closure: @escaping @Sendable (Model, PTModelValidationContext) throws -> Void) {
        self.closure = closure
    }

    public func validate(_ model: Model,
                         context: PTModelValidationContext = .init()) throws {
        try closure(model, context)
    }
}

// English: Recovery stays value-typed and explicit so a missing field never resets an existing value by accident.
// Español: La recuperación permanece tipada y explícita para que un campo ausente nunca restablezca un valor existente por accidente.
// 中文：恢复逻辑保持值类型和显式配置，避免缺失字段意外重置已有值。
public struct PTFieldRecovery<Value: Sendable>: Sendable {
    public let defaultValue: Value?
    public let defaultProvider: PTDefaultValueProvider<Value>?
    public let missingPolicy: PTMissingPolicy
    public let nullPolicy: PTNullPolicy
    public let invalidPolicy: PTInvalidValuePolicy
    private let validator: (@Sendable (Value) throws -> Void)?

    public init(provider: PTDefaultValueProvider<Value>,
                missingPolicy: PTMissingPolicy = .useDefault,
                nullPolicy: PTNullPolicy = .useDefault,
                invalidPolicy: PTInvalidValuePolicy = .useDefault,
                validator: (@Sendable (Value) throws -> Void)? = nil) {
        self.init(defaultValue: nil,
                  defaultProvider: provider,
                  missingPolicy: missingPolicy,
                  nullPolicy: nullPolicy,
                  invalidPolicy: invalidPolicy,
                  validator: validator)
    }

    public init(defaultValue: Value? = nil,
                defaultProvider: PTDefaultValueProvider<Value>? = nil,
                missingPolicy: PTMissingPolicy = .useDefault,
                nullPolicy: PTNullPolicy = .useNil,
                invalidPolicy: PTInvalidValuePolicy = .error,
                validator: (@Sendable (Value) throws -> Void)? = nil) {
        self.defaultValue = defaultValue
        self.defaultProvider = defaultProvider
        self.missingPolicy = missingPolicy
        self.nullPolicy = nullPolicy
        self.invalidPolicy = invalidPolicy
        self.validator = validator
    }

    // English: Resolve a fixed or context-driven default exactly once for one field decision.
    // Español: Resuelve una vez el valor fijo o dependiente del contexto para la decisión de un campo.
    // 中文：每次字段决策只解析一次固定默认值或上下文默认值。
    private func resolvedDefault(using context: PTModelContext) throws -> Value? {
        if let defaultProvider { return try defaultProvider.resolve(using: context) }
        return defaultValue
    }

    public func resolve(_ state: PTModelFieldState<Value>,
                        descriptor: PTModelFieldDescriptor,
                        path: PTJSONPath = .root,
                        context: PTModelContext = .init()) throws -> Value? {
        var trace = PTDecodeTrace()
        return try resolve(state, descriptor: descriptor, path: path, trace: &trace, context: context)
    }

    public func resolve(_ state: PTModelFieldState<Value>,
                        descriptor: PTModelFieldDescriptor,
                        path: PTJSONPath = .root,
                        trace: inout PTDecodeTrace,
                        context: PTModelContext = .init()) throws -> Value? {
        switch state {
        case .value(let value):
            try validator?(value)
            trace.append(PTDecodeTraceEvent(kind: .value, path: path))
            return value
        case .missing:
            trace.append(PTDecodeTraceEvent(kind: .missing, path: path, reason: .missing))
            switch missingPolicy {
            case .useDefault:
                guard let defaultValue = try resolvedDefault(using: context) else {
                    if descriptor.required { throw PTModelError.requiredValue(path.description) }
                    return nil
                }
                try validator?(defaultValue)
                trace.append(PTDecodeTraceEvent(kind: .defaultValue,
                                                path: path,
                                                message: "Missing value recovered with the field default.",
                                                reason: .missing))
                return defaultValue
            case .useNil, .ignore:
                if descriptor.required { throw PTModelError.requiredValue(path.description) }
                if missingPolicy == .ignore {
                    trace.append(PTDecodeTraceEvent(kind: .ignored, path: path, message: "Missing value ignored."))
                }
                return nil
            case .error:
                throw PTModelError.missingValue(path.description)
            }
        case .null:
            trace.append(PTDecodeTraceEvent(kind: .null, path: path, reason: .null))
            switch nullPolicy {
            case .useDefault:
                guard let defaultValue = try resolvedDefault(using: context) else {
                    if descriptor.required { throw PTModelError.requiredValue(path.description) }
                    return nil
                }
                try validator?(defaultValue)
                trace.append(PTDecodeTraceEvent(kind: .defaultValue,
                                                path: path,
                                                message: "Null value recovered with the field default.",
                                                reason: .null))
                return defaultValue
            case .useNil, .ignore:
                if descriptor.required { throw PTModelError.requiredValue(path.description) }
                if nullPolicy == .ignore {
                    trace.append(PTDecodeTraceEvent(kind: .ignored, path: path, message: "Null value ignored."))
                }
                return nil
            case .error:
                throw PTModelError.nullValue(path.description)
            }
        case .invalid(let message):
            trace.append(PTDecodeTraceEvent(kind: .invalid,
                                            path: path,
                                            message: message,
                                            reason: .invalid(message)))
            return try resolveInvalid(message,
                                      reason: .invalid(message),
                                      descriptor: descriptor,
                                      path: path,
                                      trace: &trace,
                                      context: context)
        case .overflow(let message):
            trace.append(PTDecodeTraceEvent(kind: .invalid,
                                            path: path,
                                            message: message,
                                            reason: .overflow))
            return try resolveInvalid(message,
                                      reason: .overflow,
                                      descriptor: descriptor,
                                      path: path,
                                      trace: &trace,
                                      context: context)
        }
    }

    // English: Overflow follows the invalid-value recovery policy while retaining a distinct diagnostic reason.
    // Español: El desbordamiento sigue la política de recuperación de valores inválidos y conserva una razón distinta.
    // 中文：溢出复用无效值恢复策略，同时保留独立的诊断原因。
    private func resolveInvalid(_ message: String,
                                reason: PTFieldRecoveryReason,
                                descriptor: PTModelFieldDescriptor,
                                path: PTJSONPath,
                                trace: inout PTDecodeTrace,
                                context: PTModelContext) throws -> Value? {
            switch invalidPolicy {
            case .useDefault:
                guard let defaultValue = try resolvedDefault(using: context) else {
                    if reason == .overflow { throw PTModelError.numericOverflow(message) }
                    throw PTModelError.conversionFailed(message)
                }
                try validator?(defaultValue)
                trace.append(PTDecodeTraceEvent(kind: .defaultValue,
                                                path: path,
                                                message: "Invalid value recovered with the field default.",
                                                reason: reason))
                return defaultValue
            case .useNil, .ignore:
                if descriptor.required { throw PTModelError.requiredValue(path.description) }
                if invalidPolicy == .ignore {
                    trace.append(PTDecodeTraceEvent(kind: .ignored, path: path, message: "Invalid value ignored."))
                }
                return nil
            case .error:
                if reason == .overflow { throw PTModelError.numericOverflow(message) }
                throw PTModelError.conversionFailed(message)
            }
    }
}

public extension PTModelDecoder {
    // English: Apply the complete missing/null/invalid/value pipeline to one static-schema field.
    // Español: Aplica el pipeline completo de ausente/nulo/inválido/valor a un campo del esquema estático.
    // 中文：对静态 Schema 字段执行完整的 missing/null/invalid/value 恢复流程。
    func resolveField<Value: Decodable & Sendable>(
        _ type: Value.Type,
        from object: PTJSONValue,
        field: PTModelFieldDescriptor,
        recovery: PTFieldRecovery<Value> = .init(),
        path: PTJSONPath = .root
    ) throws -> Value? {
        let fieldPath = path.appending(.key(field.mapping.encodeKey))
        let state = decodeField(type, from: object, field: field, path: path)
        return try recovery.resolve(state, descriptor: field, path: fieldPath)
    }

    // English: This overload exposes trace and diagnostics without changing the legacy field-resolution signature.
    // Español: Esta sobrecarga expone trazas y diagnósticos sin cambiar la firma heredada de resolución de campos.
    // 中文：该重载在不改变旧字段解析签名的前提下暴露 trace 和 diagnostics。
    func resolveField<Value: Decodable & Sendable>(
        _ type: Value.Type,
        from object: PTJSONValue,
        field: PTModelFieldDescriptor,
        recovery: PTFieldRecovery<Value> = .init(),
        path: PTJSONPath = .root,
        context: PTModelContext = .init(),
        trace: inout PTDecodeTrace,
        diagnosticSink: any PTModelDiagnosticSink = PTNoopDiagnosticSink()
    ) throws -> Value? {
        let fieldPath = path.appending(.key(field.mapping.encodeKey))
        let state = decodeField(type, from: object, field: field, path: path)
        let value = try recovery.resolve(state,
                                        descriptor: field,
                                        path: fieldPath,
                                        trace: &trace,
                                        context: context)
        for event in trace.events where event.path == fieldPath {
            guard event.kind == .invalid || event.kind == .defaultValue || event.kind == .ignored else { continue }
            diagnosticSink.record(PTModelDiagnostic(severity: event.kind == .invalid ? .warning : .info,
                                                     path: event.path,
                                                     code: "PTModel.\(event.kind.rawValue)",
                                                     message: event.message ?? event.kind.rawValue))
        }
        return value
    }

    // English: Resolve aliases and nested paths before classifying the field state.
    // Español: Resuelve alias y rutas anidadas antes de clasificar el estado del campo.
    // 中文：先解析别名和嵌套路径，再判断字段状态。
    private func decodeField<T: Decodable>(
        _ type: T.Type,
        from object: PTJSONValue,
        field: PTModelFieldDescriptor,
        path: PTJSONPath
    ) -> PTModelFieldState<T> {
        let fieldPath = path.appending(.key(field.mapping.encodeKey))
        let value: PTJSONValue?
        do {
            value = try PTModelSchemaSupport.value(for: field, in: object)
        } catch {
            return .invalid(fieldPath.description)
        }
        guard let value else { return .missing }
        if case .null = value { return .null }
        do {
            return .value(try decodeValue(type, from: value, path: fieldPath))
        } catch let error as PTModelError {
            if case .numericOverflow(let raw) = error { return .overflow(raw) }
            return .invalid(fieldPath.description)
        } catch {
            return .invalid(fieldPath.description)
        }
    }
}
