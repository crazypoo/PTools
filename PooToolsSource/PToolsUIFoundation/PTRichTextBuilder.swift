// English: Result-builder and interpolation contracts for PTRichText construction.
// Español: Contratos de result-builder e interpolación para construir PTRichText.
// 中文：PTRichText 构建所需的 Result Builder 和插值契约。

import Foundation

// English: A small value fragment keeps complex interpolation and result-builder composition readable.
// Español: Un fragmento de valor pequeño mantiene legibles la interpolación compleja y el builder.
// 中文：轻量值片段让复杂插值和 Result Builder 组合保持可读。
public struct PTTextFragment: Sendable {
    public let richText: PTRichText

    public init(_ richText: PTRichText) {
        self.richText = richText
    }
}

// English: Lock-protected matcher storage isolates Foundation's reference matchers from Swift 6 shared-state diagnostics.
// Español: El almacenamiento de matchers protegido por bloqueo aísla las referencias de Foundation de los diagnósticos de estado compartido de Swift 6.
// 中文：加锁的匹配器存储隔离 Foundation 引用对象，避免 Swift 6 共享状态诊断。
// English: This compatibility boundary is only for immutable matcher reuse; every cache access is serialized by the lock.
// Español: Este límite de compatibilidad solo reutiliza matchers inmutables; cada acceso a la caché se serializa con el bloqueo.
// 中文：这个兼容边界仅用于复用不可变匹配器；所有缓存访问都通过锁串行化。
@resultBuilder
public enum PTRichTextBuilder {
    public static func buildBlock(_ components: PTRichText...) -> PTRichText {
        components.reduce(into: PTRichText(""), +=)
    }

    public static func buildExpression(_ expression: String) -> PTRichText {
        PTRichText(expression)
    }

    public static func buildExpression(_ expression: PTRichText) -> PTRichText {
        expression
    }

    public static func buildExpression(_ expression: PTTextFragment) -> PTRichText {
        expression.richText
    }

    public static func buildOptional(_ component: PTRichText?) -> PTRichText {
        component ?? PTRichText("")
    }

    public static func buildEither(first component: PTRichText) -> PTRichText {
        component
    }

    public static func buildEither(second component: PTRichText) -> PTRichText {
        component
    }

    public static func buildArray(_ components: [PTRichText]) -> PTRichText {
        components.reduce(into: PTRichText(""), +=)
    }
}

public enum PTTextWrapMode {
    case embedding(PTRichText)
    case override(PTRichText)
}
