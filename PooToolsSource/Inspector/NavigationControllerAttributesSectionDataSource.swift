//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementAttributesLibrary {
    final class NavigationControllerAttributesSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title = "Navigation Controller"

        private weak var navigationController: UINavigationController?

        init?(with object: NSObject) {
            guard let navigationController = object as? UINavigationController else {
                return nil
            }

            self.navigationController = navigationController
        }

        private enum Property: String, Swift.CaseIterable {
            case groupBarVisiblity = "Bar Visibility"
            case isNavigationBarHidden = "Shows Navigation Bar"
            case isToolbarHidden = "Shows Toolbar"
            case groupHideBars = "Hide Bars"
            case hidesBarsOnSwipe = "On Swipe"
            case hidesBarsOnTap = "On Tap"
            case hidesBarsWhenKeyboardAppears = "When Keyboard Appears"
            case hidesBarsWhenVerticallyCompact = "When Vertically Compact"
        }

        var properties: [InspectorElementProperty] {
            guard let navigationController = navigationController else { return [] }

            return Property.allCases.compactMap { property in
                switch property {
                case .groupHideBars, .groupBarVisiblity:
                    return .group(title: property.rawValue)

                case .isNavigationBarHidden:
                    return .switch(
                        title: property.rawValue,
                        isOn: { !navigationController.isNavigationBarHidden },
                        handler: { navigationController.setNavigationBarHidden(!$0, animated: true) }
                    )
                case .isToolbarHidden:
                    return .switch(
                        title: property.rawValue,
                        isOn: { !navigationController.isToolbarHidden },
                        handler: { navigationController.setToolbarHidden(!$0, animated: true) }
                    )
                case .hidesBarsOnSwipe:
                    return .switch(
                        title: property.rawValue,
                        isOn: { navigationController.hidesBarsOnSwipe },
                        handler: { navigationController.hidesBarsOnSwipe = $0 }
                    )
                case .hidesBarsOnTap:
                    return .switch(
                        title: property.rawValue,
                        isOn: { navigationController.hidesBarsOnTap },
                        handler: { navigationController.hidesBarsOnTap = $0 }
                    )
                case .hidesBarsWhenKeyboardAppears:
                    return .switch(
                        title: property.rawValue,
                        isOn: { navigationController.hidesBarsWhenKeyboardAppears },
                        handler: { navigationController.hidesBarsWhenKeyboardAppears = $0 }
                    )
                case .hidesBarsWhenVerticallyCompact:
                    return .switch(
                        title: property.rawValue,
                        isOn: { navigationController.hidesBarsWhenVerticallyCompact },
                        handler: { navigationController.hidesBarsWhenVerticallyCompact = $0 }
                    )
                }
            }
        }
    }
}
