// English: Native, typed coach-mark models built on top of the shared Overlay layer.
// Español: Modelos nativos y tipados de tutorial construidos sobre la capa Overlay compartida.
// 中文：基于共享 Overlay 层构建的原生类型化引导模型。

import UIKit
#if SWIFT_PACKAGE
import PToolsOverlay
#endif

public struct PTInstructionID: Hashable, Codable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }
}

public enum PTInstructionState: Sendable {
    case idle
    case resolvingTarget
    case presenting
    case visible
    case paused
    case dismissing
    case finished
}

public enum PTInstructionResult: Sendable {
    case completed
    case skipped
    case cancelled
}

public enum PTInstructionFailure: Error, Sendable, LocalizedError {
    case emptyTour
    case duplicateStepID(PTInstructionID)
    case targetUnavailable(PTInstructionID)
    case targetTimeout(PTInstructionID)
    case hostUnavailable
    case alreadyRunning

    public var errorDescription: String? {
        switch self {
        case .emptyTour: return "The instruction tour has no steps."
        case let .duplicateStepID(id): return "The instruction step ID is duplicated: \(id.rawValue)."
        case let .targetUnavailable(id): return "The instruction target is unavailable: \(id.rawValue)."
        case let .targetTimeout(id): return "The instruction target timed out: \(id.rawValue)."
        case .hostUnavailable: return "The instruction overlay host is unavailable."
        case .alreadyRunning: return "Another instruction tour is already running."
        }
    }
}

public enum PTInstructionPresentationPolicy: Sendable {
    case always
    case once
    case oncePerVersion
}

public enum PTInstructionTouchForwardingPolicy: Sendable {
    case none
    case target
    case cutout
    case all
}

public enum PTInstructionTargetWaitPolicy: Sendable {
    case fail
    case skip
    case wait(seconds: Double)

    var timeout: Duration? {
        switch self {
        case .fail, .skip: return nil
        case let .wait(seconds): return .milliseconds(Int64(max(0, seconds) * 1_000))
        }
    }
}

public enum PTInstructionTargetRevealPolicy: Sendable {
    case none
    case scrollIfNeeded
}

public enum PTInstructionIdleAnimation: Sendable {
    case none
    case pulse
}

public struct PTInstructionMessage: Sendable {
    public let title: String?
    public let message: String
    public let nextTitle: String
    public let previousTitle: String?
    public let skipTitle: String?

    public init(title: String? = nil,
                message: String,
                nextTitle: String = "Next",
                previousTitle: String? = nil,
                skipTitle: String? = "Skip") {
        self.title = title
        self.message = message
        self.nextTitle = nextTitle
        self.previousTitle = previousTitle
        self.skipTitle = skipTitle
    }
}

@MainActor
public enum PTInstructionTarget {
    case none
    case view(UIView)
    case anchor(PTAnchor)
    case registered(PTInstructionID)
    case multiple([PTAnchor])

    var anchors: [PTAnchor] {
        switch self {
        case .none:
            return []
        case let .view(view):
            return [.view(view)]
        case let .anchor(anchor):
            return [anchor]
        case let .registered(id):
            return [.registered(PTAnchorID(id.rawValue))]
        case let .multiple(anchors):
            return anchors
        }
    }
}

@MainActor
public enum PTInstructionCutoutShape {
    case rectangle
    case roundedRectangle(cornerRadius: CGFloat)
    case capsule
    case circle
    case oval
    case custom(@MainActor @Sendable (CGRect) -> UIBezierPath?)
}

@MainActor
public struct PTInstructionSpotlight {
    public var shape: PTInstructionCutoutShape
    public var insets: UIEdgeInsets
    public var color: UIColor
    public var borderColor: UIColor?
    public var borderWidth: CGFloat

    public init(shape: PTInstructionCutoutShape = .roundedRectangle(cornerRadius: 12),
                insets: UIEdgeInsets = .zero,
                color: UIColor = UIColor.black.withAlphaComponent(0.58),
                borderColor: UIColor? = nil,
                borderWidth: CGFloat = 0) {
        self.shape = shape
        self.insets = insets
        self.color = color
        self.borderColor = borderColor
        self.borderWidth = borderWidth
    }
}

@MainActor
public enum PTInstructionContent {
    case message(PTInstructionMessage)
    case view(@MainActor @Sendable () -> UIView)
    case viewController(@MainActor @Sendable () -> UIViewController)
}

@MainActor
public enum PTInstructionAdvancePolicy {
    case nextButton
    case overlayTap
    case targetTap
    case controlEvent(UInt)
    case manual
    case any

    var isControlEvent: Bool {
        if case .controlEvent = self { return true }
        return false
    }
}

@MainActor
public final class PTInstructionStepContext {
    public let tourID: PTInstructionID
    public let stepID: PTInstructionID
    public private(set) var targetFrame: CGRect?

    private weak var coordinator: PTInstructionCoordinator?

    init(tourID: PTInstructionID,
         stepID: PTInstructionID,
         targetFrame: CGRect?,
         coordinator: PTInstructionCoordinator) {
        self.tourID = tourID
        self.stepID = stepID
        self.targetFrame = targetFrame
        self.coordinator = coordinator
    }

    public func next() async {
        await coordinator?.next()
    }

    public func previous() async {
        await coordinator?.previous()
    }

    public func skip() async {
        await coordinator?.skip()
    }

    public func skipStep() async {
        await coordinator?.skipStep()
    }

    public func jump(to id: PTInstructionID) async {
        await coordinator?.jump(to: id)
    }

    public func pause() async {
        await coordinator?.pause()
    }

    public func resume() async {
        await coordinator?.resume()
    }
}

@MainActor
public struct PTInstructionStep {
    public let id: PTInstructionID
    public let target: PTInstructionTarget
    public let content: PTInstructionContent
    public let spotlight: PTInstructionSpotlight
    public let placement: PTPopoverPlacement
    public let advancePolicy: PTInstructionAdvancePolicy
    public let touchForwarding: PTInstructionTouchForwardingPolicy
    public let targetWaitPolicy: PTInstructionTargetWaitPolicy
    public let targetRevealPolicy: PTInstructionTargetRevealPolicy
    public let isSkippable: Bool
    public let condition: (@MainActor @Sendable () async -> Bool)?
    public let beforePresent: (@MainActor @Sendable (PTInstructionStepContext) async throws -> Void)?
    public let afterDismiss: (@MainActor @Sendable (PTInstructionStepContext) async throws -> Void)?

    public init(id: PTInstructionID,
                target: PTInstructionTarget = .none,
                content: PTInstructionContent,
                spotlight: PTInstructionSpotlight = PTInstructionSpotlight(),
                placement: PTPopoverPlacement = .automatic,
                advancePolicy: PTInstructionAdvancePolicy = .nextButton,
                touchForwarding: PTInstructionTouchForwardingPolicy = .none,
                targetWaitPolicy: PTInstructionTargetWaitPolicy = .fail,
                targetRevealPolicy: PTInstructionTargetRevealPolicy = .none,
                isSkippable: Bool = true,
                condition: (@MainActor @Sendable () async -> Bool)? = nil,
                beforePresent: (@MainActor @Sendable (PTInstructionStepContext) async throws -> Void)? = nil,
                afterDismiss: (@MainActor @Sendable (PTInstructionStepContext) async throws -> Void)? = nil) {
        self.id = id
        self.target = target
        self.content = content
        self.spotlight = spotlight
        self.placement = placement
        self.advancePolicy = advancePolicy
        self.touchForwarding = touchForwarding
        self.targetWaitPolicy = targetWaitPolicy
        self.targetRevealPolicy = targetRevealPolicy
        self.isSkippable = isSkippable
        self.condition = condition
        self.beforePresent = beforePresent
        self.afterDismiss = afterDismiss
    }
}

@MainActor
public struct PTInstructionTour {
    public let id: PTInstructionID
    public let version: String
    public let steps: [PTInstructionStep]
    public let presentationPolicy: PTInstructionPresentationPolicy

    public init(id: PTInstructionID,
                version: String = "1",
                steps: [PTInstructionStep],
                presentationPolicy: PTInstructionPresentationPolicy = .always) {
        self.id = id
        self.version = version
        self.steps = steps
        self.presentationPolicy = presentationPolicy
    }
}

@MainActor
public struct PTInstructionConfiguration {
    public var maximumContentWidth: CGFloat
    public var contentPadding: CGFloat
    public var cardCornerRadius: CGFloat
    public var cardColor: UIColor
    public var titleColor: UIColor
    public var messageColor: UIColor
    public var accentColor: UIColor
    public var idleAnimation: PTInstructionIdleAnimation
    public var transition: PTOverlayTransition
    public var dismissOnSceneDisconnect: Bool

    public init(maximumContentWidth: CGFloat = 320,
                contentPadding: CGFloat = 20,
                cardCornerRadius: CGFloat = 18,
                cardColor: UIColor = .secondarySystemBackground,
                titleColor: UIColor = .label,
                messageColor: UIColor = .secondaryLabel,
                accentColor: UIColor = .tintColor,
                idleAnimation: PTInstructionIdleAnimation = .pulse,
                transition: PTOverlayTransition = .scale,
                dismissOnSceneDisconnect: Bool = true) {
        self.maximumContentWidth = maximumContentWidth
        self.contentPadding = contentPadding
        self.cardCornerRadius = cardCornerRadius
        self.cardColor = cardColor
        self.titleColor = titleColor
        self.messageColor = messageColor
        self.accentColor = accentColor
        self.idleAnimation = idleAnimation
        self.transition = transition
        self.dismissOnSceneDisconnect = dismissOnSceneDisconnect
    }
}

public enum PTInstructionProgressStatus: String, Codable, Sendable {
    case started
    case completed
    case skipped
}

public struct PTInstructionProgressSnapshot: Codable, Sendable {
    public let tourID: PTInstructionID
    public let version: String
    public let lastStepID: PTInstructionID?
    public let status: PTInstructionProgressStatus

    public init(tourID: PTInstructionID,
                version: String,
                lastStepID: PTInstructionID?,
                status: PTInstructionProgressStatus) {
        self.tourID = tourID
        self.version = version
        self.lastStepID = lastStepID
        self.status = status
    }
}
