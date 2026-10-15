//
//  PTCollectionSkeletonTypes.swift
//  PooTools
//
// English: Public, UIKit-safe value descriptions for PTCollectionView skeletons.
// Español: Descripciones públicas y seguras para UIKit de los skeletons de PTCollectionView.
// 中文：为 PTCollectionView 骨架提供公开且符合 UIKit 边界的值描述类型。
//

import UIKit

// English: Keep count policies independent from the legacy 1...50 compatibility clamp.
// Español: Mantiene las políticas de cantidad independientes del límite heredado 1...50.
// 中文：让数量策略独立于旧 API 的 1...50 兼容限制。
public enum PTCollectionSkeletonItemCountMode: Sendable, Equatable {
    case configured
    case fixed(Int)
    case fillViewport(extraRows: Int = 0)
}

public enum PTCollectionSkeletonDirection: String, Sendable, CaseIterable {
    case leftToRight
    case rightToLeft
    case topToBottom
    case bottomToTop
    case topLeadingToBottomTrailing
    case bottomTrailingToTopLeading
}

public enum PTCollectionSkeletonAnimationStyle: String, Sendable, CaseIterable {
    case solid
    case gradient
    case pulse
    case shimmer
    case none
}

@MainActor
public struct PTCollectionSkeletonLayout {
    public var itemHeight: CGFloat?
    public var itemWidth: CGFloat?
    public var horizontalSpacing: CGFloat?
    public var verticalSpacing: CGFloat?
    public var columnCount: Int?
    public var contentInsets: NSDirectionalEdgeInsets?
    public var cornerRadius: CGFloat?
    public var itemHeightMultipliers: [CGFloat]?
    public var geometryProvider: PTSkeletonGeometryProvider?

    public init(itemHeight: CGFloat? = nil,
                itemWidth: CGFloat? = nil,
                horizontalSpacing: CGFloat? = nil,
                verticalSpacing: CGFloat? = nil,
                columnCount: Int? = nil,
                contentInsets: NSDirectionalEdgeInsets? = nil,
                cornerRadius: CGFloat? = nil,
                itemHeightMultipliers: [CGFloat]? = nil,
                geometryProvider: PTSkeletonGeometryProvider? = nil) {
        self.itemHeight = itemHeight
        self.itemWidth = itemWidth
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.columnCount = columnCount
        self.contentInsets = contentInsets
        self.cornerRadius = cornerRadius
        self.itemHeightMultipliers = itemHeightMultipliers
        self.geometryProvider = geometryProvider
    }
}

@MainActor
public struct PTCollectionSkeletonAppearance {
    public var baseColor: UIColor
    public var highlightColor: UIColor
    public var gradientColors: [UIColor]?
    public var pulseMinimumAlpha: Float
    public var pulseMaximumAlpha: Float

    public init(baseColor: UIColor = .secondarySystemBackground,
                highlightColor: UIColor = .tertiarySystemBackground,
                gradientColors: [UIColor]? = nil,
                pulseMinimumAlpha: Float = 0.55,
                pulseMaximumAlpha: Float = 1) {
        self.baseColor = baseColor
        self.highlightColor = highlightColor
        self.gradientColors = gradientColors
        self.pulseMinimumAlpha = min(max(pulseMinimumAlpha, 0), 1)
        self.pulseMaximumAlpha = min(max(pulseMaximumAlpha, 0), 1)
    }
}

@MainActor
public struct PTCollectionSkeletonAnimation {
    public var style: PTCollectionSkeletonAnimationStyle
    public var direction: PTCollectionSkeletonDirection
    public var duration: TimeInterval
    public var autoreverses: Bool
    public var repeatCount: Float

    public init(style: PTCollectionSkeletonAnimationStyle = .shimmer,
                direction: PTCollectionSkeletonDirection = .leftToRight,
                duration: TimeInterval = 1.2,
                autoreverses: Bool = false,
                repeatCount: Float = .infinity) {
        self.style = style
        self.direction = direction
        self.duration = duration.isFinite && duration > 0 ? duration : 1.2
        self.autoreverses = autoreverses
        self.repeatCount = repeatCount.isFinite && repeatCount >= 0 ? repeatCount : .infinity
    }

    public static var legacyShimmer: PTCollectionSkeletonAnimation {
        PTCollectionSkeletonAnimation()
    }
}

public enum PTCollectionSkeletonTransition: Sendable, Equatable {
    case none
    case crossDissolve(duration: TimeInterval)

    var duration: TimeInterval {
        switch self {
        case .none: return 0
        case .crossDissolve(let duration): return duration.isFinite && duration > 0 ? duration : 0.2
        }
    }
}

public enum PTCollectionSkeletonInteractionPolicy: String, Sendable {
    case blocksTouches
    case allowsScrolling
    case passthrough
}

public enum PTSkeletonAuxiliaryViewPolicy: String, Sendable {
    case unchanged
    case hideWhileVisible
    case disableInteraction
}

public enum PTSkeletonFillRole: String, Sendable {
    case base
    case highlight
}

public enum PTSkeletonShapeKind: String, Sendable {
    case rect
    case roundedRect
    case circle
    case line
}

@MainActor
public struct PTSkeletonShape {
    public var kind: PTSkeletonShapeKind
    public var localFrame: CGRect
    public var isNormalized: Bool
    public var cornerRadius: CGFloat
    public var fillRole: PTSkeletonFillRole

    public init(kind: PTSkeletonShapeKind = .roundedRect,
                localFrame: CGRect = .zero,
                isNormalized: Bool = true,
                cornerRadius: CGFloat = 8,
                fillRole: PTSkeletonFillRole = .base) {
        self.kind = kind
        self.localFrame = localFrame
        self.isNormalized = isNormalized
        self.cornerRadius = max(0, cornerRadius.isFinite ? cornerRadius : 0)
        self.fillRole = fillRole
    }

    public static func rect(_ frame: CGRect, normalized: Bool = true, fillRole: PTSkeletonFillRole = .base) -> PTSkeletonShape {
        PTSkeletonShape(kind: .rect, localFrame: frame, isNormalized: normalized, cornerRadius: 0, fillRole: fillRole)
    }

    public static func roundedRect(_ frame: CGRect,
                                   normalized: Bool = true,
                                   cornerRadius: CGFloat = 8,
                                   fillRole: PTSkeletonFillRole = .base) -> PTSkeletonShape {
        PTSkeletonShape(kind: .roundedRect, localFrame: frame, isNormalized: normalized, cornerRadius: cornerRadius, fillRole: fillRole)
    }

    public static func circle(_ frame: CGRect, normalized: Bool = true, fillRole: PTSkeletonFillRole = .base) -> PTSkeletonShape {
        PTSkeletonShape(kind: .circle, localFrame: frame, isNormalized: normalized, cornerRadius: 0, fillRole: fillRole)
    }

    public static func line(_ frame: CGRect,
                            normalized: Bool = true,
                            cornerRadius: CGFloat = 4,
                            fillRole: PTSkeletonFillRole = .base) -> PTSkeletonShape {
        PTSkeletonShape(kind: .line, localFrame: frame, isNormalized: normalized, cornerRadius: cornerRadius, fillRole: fillRole)
    }
}

@MainActor
public enum PTSkeletonTextLineCount {
    case fixed(Int)
    case automaticFill
    case inherited(Int?)
}

@MainActor
public enum PTSkeletonTextLineHeight {
    case fixed(CGFloat)
    case relativeToFont(UIFont)
    case relativeToAvailableHeight
}

@MainActor
public struct PTSkeletonTextDescriptor {
    public var lineCount: PTSkeletonTextLineCount
    public var lineHeight: PTSkeletonTextLineHeight
    public var lineSpacing: CGFloat
    public var lastLineFillRatio: CGFloat
    public var lineCornerRadius: CGFloat
    public var padding: NSDirectionalEdgeInsets
    public var alignment: NSTextAlignment
    public var preferredFont: UIFont?

    public init(lineCount: PTSkeletonTextLineCount = .fixed(2),
                lineHeight: PTSkeletonTextLineHeight = .relativeToFont(.preferredFont(forTextStyle: .body)),
                lineSpacing: CGFloat = 6,
                lastLineFillRatio: CGFloat = 0.7,
                lineCornerRadius: CGFloat = 4,
                padding: NSDirectionalEdgeInsets = .zero,
                alignment: NSTextAlignment = .natural,
                preferredFont: UIFont? = nil) {
        self.lineCount = lineCount
        self.lineHeight = lineHeight
        self.lineSpacing = max(0, lineSpacing.isFinite ? lineSpacing : 0)
        self.lastLineFillRatio = min(max(lastLineFillRatio.isFinite ? lastLineFillRatio : 0.7, 0.05), 1)
        self.lineCornerRadius = max(0, lineCornerRadius.isFinite ? lineCornerRadius : 0)
        self.padding = padding
        self.alignment = alignment
        self.preferredFont = preferredFont
    }
}

@MainActor
public enum PTCollectionSkeletonContent {
    case block
    case text(PTSkeletonTextDescriptor)
    case avatarText
    case imageText
    case card
    case custom(shapes: [PTSkeletonShape])
}

@MainActor
public struct PTSkeletonItemDescriptor {
    public var content: PTCollectionSkeletonContent
    public var shapes: [PTSkeletonShape]

    public init(content: PTCollectionSkeletonContent = .block, shapes: [PTSkeletonShape] = []) {
        self.content = content
        self.shapes = shapes
    }

    public static var block: PTSkeletonItemDescriptor {
        PTSkeletonItemDescriptor()
    }
}

@MainActor
public struct PTSkeletonTemplateContext {
    public let reuseIdentifier: String
    public let sectionIndex: Int
    public let itemIndex: Int
    public let itemFrame: CGRect

    public init(reuseIdentifier: String = "", sectionIndex: Int, itemIndex: Int, itemFrame: CGRect) {
        self.reuseIdentifier = reuseIdentifier
        self.sectionIndex = sectionIndex
        self.itemIndex = itemIndex
        self.itemFrame = itemFrame
    }
}

@MainActor
public struct PTSkeletonItemContext {
    public let skeletonSectionIndex: Int
    public let itemIndex: Int
    public let itemFrame: CGRect
    public let layoutDirection: UIUserInterfaceLayoutDirection

    public init(skeletonSectionIndex: Int,
                itemIndex: Int,
                itemFrame: CGRect,
                layoutDirection: UIUserInterfaceLayoutDirection) {
        self.skeletonSectionIndex = skeletonSectionIndex
        self.itemIndex = itemIndex
        self.itemFrame = itemFrame
        self.layoutDirection = layoutDirection
    }
}

@MainActor
public struct PTSkeletonSupplementaryDescriptor {
    public var height: CGFloat
    public var content: PTSkeletonItemDescriptor

    public init(height: CGFloat = 28, content: PTSkeletonItemDescriptor = .block) {
        self.height = max(1, height.isFinite ? height : 28)
        self.content = content
    }
}

public typealias PTSkeletonItemProvider = @MainActor (PTSkeletonItemContext) -> PTSkeletonItemDescriptor
public typealias PTSkeletonSupplementaryProvider = @MainActor (_ sectionIndex: Int, _ kind: String, _ frame: CGRect) -> PTSkeletonItemDescriptor?
public typealias PTSkeletonGeometryProvider = @MainActor (_ sectionIndex: Int, _ itemIndex: Int, _ viewport: CGRect, _ context: PTSkeletonItemContext) -> CGRect?

@MainActor
public struct PTSkeletonSectionDescriptor {
    public var id: String
    public var itemCountMode: PTCollectionSkeletonItemCountMode
    public var layoutOverride: PTCollectionSkeletonLayout?
    public var header: PTSkeletonSupplementaryDescriptor?
    public var footer: PTSkeletonSupplementaryDescriptor?
    public var defaultItem: PTSkeletonItemDescriptor
    public var itemProvider: PTSkeletonItemProvider?
    public var supplementaryProvider: PTSkeletonSupplementaryProvider?

    public init(id: String,
                itemCountMode: PTCollectionSkeletonItemCountMode = .configured,
                layoutOverride: PTCollectionSkeletonLayout? = nil,
                header: PTSkeletonSupplementaryDescriptor? = nil,
                footer: PTSkeletonSupplementaryDescriptor? = nil,
                defaultItem: PTSkeletonItemDescriptor = .block,
                itemProvider: PTSkeletonItemProvider? = nil,
                supplementaryProvider: PTSkeletonSupplementaryProvider? = nil) {
        self.id = id
        self.itemCountMode = itemCountMode
        self.layoutOverride = layoutOverride
        self.header = header
        self.footer = footer
        self.defaultItem = defaultItem
        self.itemProvider = itemProvider
        self.supplementaryProvider = supplementaryProvider
    }
}

@MainActor
public struct PTCollectionSkeletonConfiguration {
    public var layout: PTCollectionSkeletonLayout
    public var appearance: PTCollectionSkeletonAppearance
    public var animation: PTCollectionSkeletonAnimation
    public var transition: PTCollectionSkeletonTransition
    public var content: PTCollectionSkeletonContent
    public var itemCountMode: PTCollectionSkeletonItemCountMode
    public var interactionPolicy: PTCollectionSkeletonInteractionPolicy
    public var auxiliaryViewPolicy: PTSkeletonAuxiliaryViewPolicy
    public var showDelay: TimeInterval
    public var minimumVisibleDuration: TimeInterval
    public var sections: [PTSkeletonSectionDescriptor]?
    public var accessibilityLabel: String?

    public init(layout: PTCollectionSkeletonLayout = .init(),
                appearance: PTCollectionSkeletonAppearance = .init(),
                animation: PTCollectionSkeletonAnimation = .legacyShimmer,
                transition: PTCollectionSkeletonTransition = .none,
                content: PTCollectionSkeletonContent = .block,
                itemCountMode: PTCollectionSkeletonItemCountMode = .configured,
                interactionPolicy: PTCollectionSkeletonInteractionPolicy = .blocksTouches,
                auxiliaryViewPolicy: PTSkeletonAuxiliaryViewPolicy = .unchanged,
                showDelay: TimeInterval = 0,
                minimumVisibleDuration: TimeInterval = 0,
                sections: [PTSkeletonSectionDescriptor]? = nil,
                accessibilityLabel: String? = "内容加载中") {
        self.layout = layout
        self.appearance = appearance
        self.animation = animation
        self.transition = transition
        self.content = content
        self.itemCountMode = itemCountMode
        self.interactionPolicy = interactionPolicy
        self.auxiliaryViewPolicy = auxiliaryViewPolicy
        self.showDelay = showDelay.isFinite && showDelay > 0 ? showDelay : 0
        self.minimumVisibleDuration = minimumVisibleDuration.isFinite && minimumVisibleDuration > 0 ? minimumVisibleDuration : 0
        self.sections = sections
        self.accessibilityLabel = accessibilityLabel
    }
}

// English: Theme changes are MainActor-scoped and affect only future skeleton sessions.
// Español: Los cambios de tema están aislados en MainActor y solo afectan sesiones futuras.
// 中文：主题修改限制在 MainActor，只影响之后创建的骨架会话。
@MainActor
public enum PTSkeletonThemeDefaults {
    private static var storedAppearance: PTCollectionSkeletonAppearance?

    public static var appearance: PTCollectionSkeletonAppearance? {
        get { storedAppearance }
        set { storedAppearance = newValue }
    }
}

@MainActor
public protocol PTSkeletonTemplateProviding: AnyObject {
    static func skeletonTemplate(for context: PTSkeletonTemplateContext) -> PTSkeletonItemDescriptor
}

@MainActor
public struct PTCollectionSkeletonConfigurationSnapshot {
    public let itemCountMode: PTCollectionSkeletonItemCountMode
    public let animationStyle: PTCollectionSkeletonAnimationStyle
    public let transition: PTCollectionSkeletonTransition
    public let interactionPolicy: PTCollectionSkeletonInteractionPolicy
    public let sectionCount: Int

    init(configuration: PTCollectionSkeletonConfiguration) {
        itemCountMode = configuration.itemCountMode
        animationStyle = configuration.animation.style
        transition = configuration.transition
        interactionPolicy = configuration.interactionPolicy
        sectionCount = configuration.sections?.count ?? 0
    }
}
