//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementAttributesLibrary {
    final class TabBarItemAttributesSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title = "Tab Bar Item"

        private weak var tabBarItem: UITabBarItem?

        init?(with object: NSObject) {
            guard
                let viewController = object as? UIViewController,
                let tabBarItem = viewController.tabBarItem
            else {
                return nil
            }

            self.tabBarItem = tabBarItem
        }

        private enum Property: String, Swift.CaseIterable {
            case badgeValue = "Badge"
            case badgeColor = "Badge Color"
            case selectedImage = "Selected Image"
            case titlePositionAdjustment = "Title Position"
            case groupDragAndDrop = "Drag and Drop"
            case isSpringLoaded = "Spring Loaded"
        }

        var properties: [InspectorElementProperty] {
            guard let tabBarItem = tabBarItem else { return [] }

            return Property.allCases.compactMap { property in
                switch property {
                case .badgeValue:
                    return .textField(
                        title: property.rawValue,
                        placeholder: "Value",
                        axis: .vertical,
                        value: { tabBarItem.badgeValue },
                        handler: { tabBarItem.badgeValue = $0 }
                    )
                case .badgeColor:
                    return .colorPicker(
                        title: property.rawValue,
                        emptyTitle: "Default",
                        color: { tabBarItem.badgeColor },
                        handler: { tabBarItem.badgeColor = $0 }
                    )
                case .selectedImage:
                    return .imagePicker(
                        title: property.rawValue,
                        image: { tabBarItem.selectedImage },
                        handler: { tabBarItem.selectedImage = $0 }
                    )
                case .titlePositionAdjustment:
                    return .uiOffset(
                        title: property.rawValue,
                        offset: { tabBarItem.titlePositionAdjustment },
                        handler: { tabBarItem.titlePositionAdjustment = $0 }
                    )
                case .groupDragAndDrop:
                    return .group(title: property.rawValue)

                case .isSpringLoaded:
                    return .switch(
                        title: property.rawValue,
                        isOn: { tabBarItem.isSpringLoaded },
                        handler: { tabBarItem.isSpringLoaded = $0 }
                    )
                }
            }
        }
    }
}
