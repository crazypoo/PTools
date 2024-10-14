//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public struct InspectorConfiguration {
    var elementInspectorConfiguration = ElementInspectorConfiguration()

    public var keyCommands: KeyCommandSettings = .init()

    public var snapshotExpirationTimeInterval: TimeInterval

    public var snapshotMaxCount: Int = 1

    public var showAllViewSearchQuery: String

    public var nonInspectableClassNames: [String]

    public let enableLayoutSubviewsSwizzling: Bool

    public var showFullApplicationHierarchy: Bool

    public var verbose: Bool

    public static func config(
        enableLayoutSubviewsSwizzling: Bool = false,
        nonInspectableClassNames: [String] = [],
        showAllViewSearchQuery: String = ".",
        snapshotExpiration: TimeInterval = 1,
        showFullApplicationHierarchy: Bool = false,
        verbose: Bool = false
    ) -> InspectorConfiguration {
        .init(
            snapshotExpirationTimeInterval: snapshotExpiration,
            showAllViewSearchQuery: showAllViewSearchQuery,
            nonInspectableClassNames: nonInspectableClassNames,
            enableLayoutSubviewsSwizzling: enableLayoutSubviewsSwizzling,
            showFullApplicationHierarchy: showFullApplicationHierarchy,
            verbose: verbose
        )
    }

    public static let `default` = InspectorConfiguration.config()

    var colorStyle: InspectorColorStyle {
        guard let keyWindow = ViewHierarchy(application: .shared).keyWindow else { return .light }

        switch (keyWindow.overrideUserInterfaceStyle, keyWindow.traitCollection.userInterfaceStyle) {
        case (.dark, _),
             (.unspecified, .dark):
            return .dark
        default:
            return .light
        }
    }

    let defaultLayers: [ViewHierarchyLayer] = [
        .accessibilityElements,
        .accessibilityIdentifiers,
        .accessibilityLabels,
        .activityIndicators,
        .collectionViewCells,
        .controls,
        .images,
        .maps,
        .navigationBars,
        .progressIndicators,
        .scrollViews,
        .segmentedControls,
        .stackViews,
        .staticTexts,
        .switches,
        .tabBars,
        .tableViewCells,
        .textInputs,
        .webViews
    ]

    let knownSystemContainers: [String] = [
        "UIEditingOverlayViewController",
        "UIWindow",
        "UITransitionView",
        "UIDropShadowView",
        "UILayoutContainerView",
        // Navigation
        "UIViewControllerWrapperView",
        "UINavigationTransitionView",
        // Swift UI
        "_UIHostingView",
        "PlatformViewHost",
        "PlatformGroupContainer",
        "HostingScrollView"
    ]
}
