// English: Core-owned semantic feedback hook; concrete haptic and audio adapters stay optional.
// Español: El núcleo posee el hook semántico; los adaptadores concretos de háptica y audio siguen siendo opcionales.
// 中文：Core 只提供语义反馈钩子，具体触觉和音频适配器保持可选。

import Foundation

public enum PTFeedbackSignal: String, Codable, Hashable, Sendable {
    case selectionChanged
    case actionConfirmed
    case actionRejected
    case navigation
    case toggle
    case submit
    case validationFailure
    case warning
    case success
    case error
    case destructive
}

// English: UI and feature modules can emit one signal without depending on PToolsFeedback.
// Español: Los módulos de UI y funciones pueden emitir una señal sin depender de PToolsFeedback.
// 中文：UI 和功能模块可以发出语义信号，而不依赖 PToolsFeedback。
@MainActor
public final class PTFeedbackCenter {
    public static let shared = PTFeedbackCenter()

    public var handler: (@MainActor @Sendable (PTFeedbackSignal) -> Void)?

    public init() {}

    public func emit(_ signal: PTFeedbackSignal) {
        handler?(signal)
    }
}
