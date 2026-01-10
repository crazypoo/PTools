//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

enum ViewHierarchyIssue: CustomStringConvertible, Hashable {
    case emptyFrame
    case parentHasEmptyFrame
    case controlDisabled
    case interactionDisabled
    case lostConnection
    case iOS15_emptyNavigationBarScrollEdgeAppearance

    var description: String {
        switch self {
        case .lostConnection:
            return Texts.lostConnectionToView
        case .emptyFrame:
            return "Frame is empty"
        case .parentHasEmptyFrame:
            return "Parent has empty frame"
        case .controlDisabled:
            return "Control disabled"
        case .interactionDisabled:
            return " User interaction disabled"
        case .iOS15_emptyNavigationBarScrollEdgeAppearance:
            return "Starting in iOS 15 the default behavior produces a transparent background when not scrolled.\n\nSet UINavigationBar.scrollEdgeAppearance to get the legacy behavior."
        }
    }

    static func issues(for view: UIView) -> [ViewHierarchyIssue] {
        var array = [ViewHierarchyIssue]()

        if view.frame.isEmpty == true {
            array.append(.emptyFrame)
        }
        if view.isUserInteractionEnabled == false {
            array.append(.interactionDisabled)
        }
        if (view as? UIControl)?.isEnabled == false {
            array.append(.controlDisabled)
        }

        let defaultAppearance = UINavigationBarAppearance()
        defaultAppearance.configureWithDefaultBackground()

        if let navigationBar = view as? UINavigationBar,
            navigationBar.scrollEdgeAppearance == nil,
            navigationBar.standardAppearance.backgroundColor != defaultAppearance.backgroundColor,
            navigationBar.standardAppearance.backgroundEffect?.style != defaultAppearance.backgroundEffect?.style
        {
            array.append(.iOS15_emptyNavigationBarScrollEdgeAppearance)
        }

        return array
    }
}
