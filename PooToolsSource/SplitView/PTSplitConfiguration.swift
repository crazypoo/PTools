//
//  PTSplitConfiguration.swift
//  PooTools
//

import UIKit

// English: These value types describe split behavior without carrying UIKit controllers across concurrency boundaries.
// Español: Estos tipos de valor describen el comportamiento split sin transportar controladores UIKit entre límites de concurrencia.
// 中文：这些值类型只描述分栏行为，不让 UIKit 控制器跨并发边界传递。

public struct PTSplitConfiguration: Sendable {
    public enum Style: Sendable {
        case doubleColumn
        case tripleColumn
    }

    public var style: Style
    public var displayMode: UISplitViewController.DisplayMode
    public var splitBehavior: UISplitViewController.SplitBehavior
    public var primaryWidthFraction: CGFloat?
    public var supplementaryWidthFraction: CGFloat?
    public var automaticallyCollapseInCompactWidth: Bool
    public var navigationPolicy: PTSplitNavigationPolicy

    public init(style: Style = .doubleColumn,
                displayMode: UISplitViewController.DisplayMode = .automatic,
                splitBehavior: UISplitViewController.SplitBehavior = .automatic,
                primaryWidthFraction: CGFloat? = nil,
                supplementaryWidthFraction: CGFloat? = nil,
                automaticallyCollapseInCompactWidth: Bool = true,
                navigationPolicy: PTSplitNavigationPolicy = .wrapAll) {
        self.style = style
        self.displayMode = displayMode
        self.splitBehavior = splitBehavior
        self.primaryWidthFraction = primaryWidthFraction
        self.supplementaryWidthFraction = supplementaryWidthFraction
        self.automaticallyCollapseInCompactWidth = automaticallyCollapseInCompactWidth
        self.navigationPolicy = navigationPolicy
    }
}

public enum PTSplitColumn: Hashable, Sendable {
    case primary
    case supplementary
    case secondary
    case inspector
}

public enum PTSplitNavigationPolicy: Sendable {
    case none
    case wrapPrimary
    case wrapSecondary
    case wrapAll
    case custom
}

public enum PTSplitPresentationTarget: Sendable {
    case automatic
    case primary
    case supplementary
    case secondary
    case inspector
    case navigationPush
}

public struct PTSplitState: Codable, Sendable, Equatable {
    public var selectedPrimaryIdentifier: String?
    public var selectedSupplementaryIdentifier: String?
    public var selectedSecondaryIdentifier: String?
    public var inspectorVisible: Bool

    public init(selectedPrimaryIdentifier: String? = nil,
                selectedSupplementaryIdentifier: String? = nil,
                selectedSecondaryIdentifier: String? = nil,
                inspectorVisible: Bool = false) {
        self.selectedPrimaryIdentifier = selectedPrimaryIdentifier
        self.selectedSupplementaryIdentifier = selectedSupplementaryIdentifier
        self.selectedSecondaryIdentifier = selectedSecondaryIdentifier
        self.inspectorVisible = inspectorVisible
    }
}
