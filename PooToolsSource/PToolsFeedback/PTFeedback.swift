// English: Semantic haptic feedback with UIKit and CoreHaptics native backends.
// Español: Feedback háptico semántico con backends nativos de UIKit y CoreHaptics.
// 中文：使用 UIKit 和 CoreHaptics 原生后端提供语义化触觉反馈。

import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(CoreHaptics)
import CoreHaptics
#endif

#if SWIFT_PACKAGE
import PToolsCore
#endif

public struct PTFeedbackPatternID: RawRepresentable, Codable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.init(rawValue: value) }
}

public enum PTFeedbackEvent: Sendable, Hashable {
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
    case custom(PTFeedbackPatternID)
}

public enum PTFeedbackPolicy: String, Codable, Sendable {
    case enabled
    case disabled
}

public struct PTFeedbackCapabilities: Codable, Hashable, Sendable {
    public let supportsHaptics: Bool
    public let supportsAudio: Bool

    public init(supportsHaptics: Bool, supportsAudio: Bool) {
        self.supportsHaptics = supportsHaptics
        self.supportsAudio = supportsAudio
    }
}

public struct PTHapticPattern: Codable, Hashable, Sendable {
    public let intensity: Float
    public let sharpness: Float
    public let duration: TimeInterval

    public init(intensity: Float = 0.7,
                sharpness: Float = 0.5,
                duration: TimeInterval = 0.08) {
        self.intensity = min(max(intensity, 0), 1)
        self.sharpness = min(max(sharpness, 0), 1)
        self.duration = max(duration, 0.01)
    }
}

@MainActor
public final class PTHapticEngine {
    public static let shared = PTHapticEngine()

    public var policy: PTFeedbackPolicy = .enabled
    public private(set) var capabilities: PTFeedbackCapabilities

#if canImport(UIKit)
    private var selectionGenerator: UISelectionFeedbackGenerator?
    private var notificationGenerator: UINotificationFeedbackGenerator?
    private var impactGenerator: UIImpactFeedbackGenerator?
#endif

    private var isDefaultFeedbackHandlerInstalled = false

#if canImport(CoreHaptics)
    private var engine: CHHapticEngine?
#endif

    public init() {
#if canImport(CoreHaptics)
        let hardware = CHHapticEngine.capabilitiesForHardware()
        capabilities = PTFeedbackCapabilities(supportsHaptics: hardware.supportsHaptics,
                                              supportsAudio: hardware.supportsAudio)
#else
        capabilities = PTFeedbackCapabilities(supportsHaptics: false, supportsAudio: false)
#endif
    }

    public func prepare() {
#if canImport(UIKit)
        selectionGenerator = UISelectionFeedbackGenerator()
        notificationGenerator = UINotificationFeedbackGenerator()
        impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        selectionGenerator?.prepare()
        notificationGenerator?.prepare()
        impactGenerator?.prepare()
#endif
        prepareCoreHaptics()
    }

    public func play(_ event: PTFeedbackEvent) {
        guard policy == .enabled else { return }
        if playUIKit(event) { return }
        if case .custom(let identifier) = event {
            play(identifier: identifier, pattern: .init())
        }
    }

    // English: Install the optional haptic adapter behind the Core semantic hook.
    // Español: Instala el adaptador háptico opcional detrás del hook semántico del núcleo.
    // 中文：将可选触觉适配器安装到 Core 的语义反馈钩子之后。
    public func installAsDefault() {
        guard !isDefaultFeedbackHandlerInstalled else { return }
        PTFeedbackCenter.shared.handler = { signal in
            PTHapticEngine.shared.play(PTFeedbackEvent(signal: signal))
        }
        isDefaultFeedbackHandlerInstalled = true
    }

    // English: Remove only the handler installed by this engine instance.
    // Español: Elimina solo el handler instalado por esta instancia del motor.
    // 中文：只移除当前引擎实例安装的处理器。
    public func uninstallAsDefault() {
        guard isDefaultFeedbackHandlerInstalled else { return }
        PTFeedbackCenter.shared.handler = nil
        isDefaultFeedbackHandlerInstalled = false
    }

    public func play(identifier: PTFeedbackPatternID,
                     pattern: PTHapticPattern = .init()) {
        guard policy == .enabled else { return }
#if canImport(CoreHaptics)
        guard capabilities.supportsHaptics else { return }
        do {
            if engine == nil { prepareCoreHaptics() }
            let parameters = [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: pattern.intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: pattern.sharpness)
            ]
            let event: CHHapticEvent
            if pattern.duration > 0.1 {
                event = CHHapticEvent(eventType: .hapticContinuous,
                                      parameters: parameters,
                                      relativeTime: 0,
                                      duration: pattern.duration)
            } else {
                event = CHHapticEvent(eventType: .hapticTransient,
                                      parameters: parameters,
                                      relativeTime: 0)
            }
            let hapticPattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: hapticPattern)
            try player?.start(atTime: 0)
        } catch {
            engine = nil
        }
#else
        _ = identifier
        _ = pattern
#endif
    }

    public func resetEngine() {
#if canImport(CoreHaptics)
        engine?.stop(completionHandler: nil)
        engine = nil
#endif
        prepare()
    }

    private func playUIKit(_ event: PTFeedbackEvent) -> Bool {
#if canImport(UIKit)
        switch event {
        case .selectionChanged, .toggle:
            selectionGenerator?.selectionChanged()
            return true
        case .actionConfirmed, .submit, .success:
            notificationGenerator?.notificationOccurred(.success)
            return true
        case .actionRejected, .warning, .validationFailure:
            notificationGenerator?.notificationOccurred(.warning)
            return true
        case .error, .destructive:
            notificationGenerator?.notificationOccurred(.error)
            return true
        case .navigation:
            impactGenerator?.impactOccurred()
            return true
        case .custom:
            return false
        }
#else
        _ = event
        return false
#endif
    }

    private func prepareCoreHaptics() {
#if canImport(CoreHaptics)
        guard capabilities.supportsHaptics, engine == nil else { return }
        engine = try? CHHapticEngine()
        try? engine?.start()
#endif
    }
}

private extension PTFeedbackEvent {
    init(signal: PTFeedbackSignal) {
        switch signal {
        case .selectionChanged: self = .selectionChanged
        case .actionConfirmed: self = .actionConfirmed
        case .actionRejected: self = .actionRejected
        case .navigation: self = .navigation
        case .toggle: self = .toggle
        case .submit: self = .submit
        case .validationFailure: self = .validationFailure
        case .warning: self = .warning
        case .success: self = .success
        case .error: self = .error
        case .destructive: self = .destructive
        }
    }
}
