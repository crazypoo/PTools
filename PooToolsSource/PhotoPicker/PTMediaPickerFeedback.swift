//
//  PTMediaPickerFeedback.swift
//  PooTools
//
//  English: Provide instance-scoped PhotoPicker feedback without changing the legacy alert default.
//  Español: Proporciona comentarios por instancia para PhotoPicker sin cambiar la alerta heredada.
//  中文：提供实例级 PhotoPicker 反馈，同时保持旧版默认提示行为不变。
//

import Foundation

public enum PTMediaPickerFeedbackKind: String, Sendable, Equatable {
    case cameraUnavailable
    case cameraPermissionDenied
    case selectionLimitReached
    case videoDurationInvalid
    case videoSizeInvalid
    case mediaMixRejected
    case iCloudRequestTimedOut
    case saveStarted
    case saveSucceeded
    case saveFailed
    case saveCancelled
    case editFailed
    case submissionRejected
    case captureVisibilityTimedOut
}

public struct PTMediaPickerFeedback: Sendable {
    public let kind: PTMediaPickerFeedbackKind
    public let title: String
    public let message: String
    public let operationID: UUID?

    public init(kind: PTMediaPickerFeedbackKind,
                title: String,
                message: String,
                operationID: UUID? = nil) {
        self.kind = kind
        self.title = title
        self.message = message
        self.operationID = operationID
    }
}

public typealias PTMediaPickerFeedbackHandler = @MainActor @Sendable (PTMediaPickerFeedback) -> Void

@MainActor
enum PTMediaPickerFeedbackRouter {
    static func route(_ feedback: PTMediaPickerFeedback,
                      handler: PTMediaPickerFeedbackHandler?,
                      fallback: @MainActor () -> Void = {}) {
        if let handler {
            PTMediaPickerTrace.event("feedbackRouted", details: "kind=\(feedback.kind.rawValue),mode=custom,operationIDPresent=\(feedback.operationID != nil)")
            handler(feedback)
        } else {
            PTMediaPickerTrace.event("feedbackRouted", details: "kind=\(feedback.kind.rawValue),mode=default,operationIDPresent=\(feedback.operationID != nil)")
            fallback()
        }
    }
}

// English: Guard one save operation so a late PhotoKit callback cannot emit two terminal events.
// Español: Protege una operación de guardado para que un callback tardío de PhotoKit no emita dos estados finales.
// 中文：保护一次保存操作，避免 PhotoKit 的迟到回调重复发送终态事件。
@MainActor
final class PTMediaPickerFeedbackOperation {
    let id = UUID()
    private(set) var didEmitTerminal = false

    func canEmitTerminal() -> Bool {
        guard !didEmitTerminal else { return false }
        didEmitTerminal = true
        return true
    }
}
