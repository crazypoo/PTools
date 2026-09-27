// English: Native UIKit banner models and queue policies for iOS 17+.
// Español: Modelos de banner UIKit nativos y políticas de cola para iOS 17+.
// 中文：面向 iOS 17+ 的原生 UIKit Banner 模型和队列策略。

import UIKit
#if canImport(PToolsOverlay)
import PToolsOverlay
#endif
#if canImport(PToolsSymbols)
import PToolsSymbols
#endif

@MainActor
public enum PTBannerText {
    case string(String)
    case attributed(NSAttributedString)
}

public struct PTBannerStyleID: Hashable, Sendable {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

public enum PTBannerStyle: Sendable, Equatable {
    case info
    case success
    case warning
    case danger
    case neutral
    case custom(PTBannerStyleID)
}

public enum PTBannerPosition: Sendable, Equatable {
    case top
    case bottom
}

public enum PTBannerLayoutMode: Sendable, Equatable {
    case standard
    case growing
    case floating
    case compact
}

public enum PTBannerPriority: Int, Sendable {
    case low = 0
    case normal = 100
    case high = 200
    case critical = 300
}

public enum PTBannerDuration: Sendable, Equatable {
    case automatic
    case seconds(TimeInterval)
    case persistent
}

public enum PTBannerHaptic: Sendable, Equatable {
    case none
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case automatic
}

public enum PTBannerKeyboardAvoidance: Sendable, Equatable {
    case none
    case automatic
}

public enum PTBannerAccessibilityAnnouncement: Sendable, Equatable {
    case automatic
    case enabled
    case disabled
}

public enum PTBannerTextOverflowMode: Sendable, Equatable {
    case grow
    case truncate
    case marquee
}

@MainActor
public enum PTBannerAccessory {
    case image(UIImage)
    case symbol(PTSymbol)
    case view(@MainActor @Sendable () -> UIView)
    case activity
    case progress(Double)
}

@MainActor
public struct PTBannerContent {
    public var title: PTBannerText?
    public var subtitle: PTBannerText?
    public var leading: PTBannerAccessory?
    public var trailing: PTBannerAccessory?

    public init(title: PTBannerText? = nil,
                subtitle: PTBannerText? = nil,
                leading: PTBannerAccessory? = nil,
                trailing: PTBannerAccessory? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading
        self.trailing = trailing
    }
}

@MainActor
public struct PTBannerAction {
    public let id: String
    public let title: String
    public let handler: (@MainActor @Sendable () -> Void)?

    public init(id: String = UUID().uuidString,
                title: String,
                handler: (@MainActor @Sendable () -> Void)? = nil) {
        self.id = id
        self.title = title
        self.handler = handler
    }
}

@MainActor
public struct PooToolsBannerConfiguration {
    public var position: PTBannerPosition = .top
    public var layoutMode: PTBannerLayoutMode = .standard
    public var duration: PTBannerDuration = .automatic
    public var presentationMode: PTOverlayPresentationMode = .attached
    public var haptic: PTBannerHaptic = .automatic
    public var accessibilityAnnouncement: PTBannerAccessibilityAnnouncement = .automatic
    public var keyboardAvoidance: PTBannerKeyboardAvoidance = .automatic
    public var textOverflow: PTBannerTextOverflowMode = .grow
    public var maximumVisibleHeight: CGFloat = 0
    public var maximumWidth: CGFloat = 0
    public var cornerRadius: CGFloat = 14
    public var contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
    public var backgroundColor: UIColor?
    public var tintColor: UIColor?
    public var borderColor: UIColor?
    public var shadowColor: UIColor = .black
    public var showsShadow = true
    public var allowsTapToDismiss = true

    public init() {}
}

@MainActor
public struct PTBanner: Identifiable {
    public let id: UUID
    public var content: PTBannerContent
    public var style: PTBannerStyle
    public var configuration: PooToolsBannerConfiguration
    public var actions: [PTBannerAction]
    public var priority: PTBannerPriority
    public var onTap: (@MainActor @Sendable () -> Void)?

    public init(id: UUID = UUID(),
                content: PTBannerContent,
                style: PTBannerStyle = .info,
                configuration: PooToolsBannerConfiguration = PooToolsBannerConfiguration(),
                actions: [PTBannerAction] = [],
                priority: PTBannerPriority = .normal,
                onTap: (@MainActor @Sendable () -> Void)? = nil) {
        self.id = id
        self.content = content
        self.style = style
        self.configuration = configuration
        self.actions = actions
        self.priority = priority
        self.onTap = onTap
    }

    public static func info(title: String,
                            subtitle: String? = nil,
                            position: PTBannerPosition = .top) -> PTBanner {
        var configuration = PooToolsBannerConfiguration()
        configuration.position = position
        return PTBanner(content: PTBannerContent(title: .string(title), subtitle: subtitle.map(PTBannerText.string)),
                        style: .info,
                        configuration: configuration)
    }

    public static func success(title: String,
                               subtitle: String? = nil,
                               position: PTBannerPosition = .top) -> PTBanner {
        var banner = info(title: title, subtitle: subtitle, position: position)
        banner.style = .success
        return banner
    }

    public static func warning(title: String,
                               subtitle: String? = nil,
                               position: PTBannerPosition = .top) -> PTBanner {
        var banner = info(title: title, subtitle: subtitle, position: position)
        banner.style = .warning
        return banner
    }

    public static func error(title: String,
                             subtitle: String? = nil,
                             position: PTBannerPosition = .top) -> PTBanner {
        var banner = info(title: title, subtitle: subtitle, position: position)
        banner.style = .danger
        return banner
    }

    public static func loading(_ title: String,
                               subtitle: String? = nil,
                               position: PTBannerPosition = .top) -> PTBanner {
        var configuration = PooToolsBannerConfiguration()
        configuration.position = position
        configuration.duration = .persistent
        let content = PTBannerContent(title: .string(title),
                                      subtitle: subtitle.map(PTBannerText.string),
                                      leading: .activity)
        return PTBanner(content: content, style: .info, configuration: configuration)
    }
}

public enum PTBannerResult: Sendable {
    case autoDismissed
    case tapped
    case swiped
    case manuallyDismissed
    case replaced
    case dropped
}

public enum PTBannerEnqueuePosition: Sendable, Equatable {
    case front
    case back
}

public enum PTBannerInterruptionPolicy: Sendable, Equatable {
    case enqueue
    case replace
    case suspendCurrent
}

public enum PTBannerDeduplicationPolicy: Sendable, Equatable {
    case none
    case byID
    case byContent(window: TimeInterval)
}

public enum PTBannerOverflowPolicy: Sendable, Equatable {
    case keepAll
    case dropOldest
    case dropNewest
}

public struct PTBannerQueueConfiguration: Sendable {
    public var maxVisibleCount: Int
    public var maxQueueCount: Int
    public var deduplication: PTBannerDeduplicationPolicy
    public var overflow: PTBannerOverflowPolicy

    public init(maxVisibleCount: Int = 1,
                maxQueueCount: Int = 20,
                deduplication: PTBannerDeduplicationPolicy = .none,
                overflow: PTBannerOverflowPolicy = .dropOldest) {
        self.maxVisibleCount = max(1, maxVisibleCount)
        self.maxQueueCount = max(1, maxQueueCount)
        self.deduplication = deduplication
        self.overflow = overflow
    }
}
