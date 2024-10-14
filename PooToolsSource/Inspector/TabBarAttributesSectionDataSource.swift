//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementAttributesLibrary {
    final class TabBarAttributesSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title = "Tab Bar"

        private weak var tabBar: UITabBar?

        init?(with object: NSObject) {
            guard let tabBar = object as? UITabBar else { return nil }
            self.tabBar = tabBar
        }

        private enum Property: String, Swift.CaseIterable {
            case backgroundImage = "Background"
            case shadowImage = "Shadow"
            case selectionIndicatorImage = "Selection"
            case separator
            case style = "Style"
            case translucent = "Translucent"
            case barTintColor = "Bar Tint"
        }

        var properties: [InspectorElementProperty] {
            guard let tabBar = tabBar else { return [] }

            return Property.allCases.compactMap { property in
                switch property {
                case .style:
                    return .optionsList(
                        title: property.rawValue,
                        options: UIBarStyle.allCases.map(\.description),
                        selectedIndex: { UIBarStyle.allCases.firstIndex(of: tabBar.barStyle) },
                        handler: { newIndex in
                            guard let index = newIndex else { return }

                            let newStyle = UIBarStyle.allCases[index]
                            tabBar.barStyle = newStyle
                        }
                    )
                case .translucent:
                    return .switch(
                        title: property.rawValue,
                        isOn: { tabBar.isTranslucent },
                        handler: { tabBar.isTranslucent = $0 }
                    )
                case .barTintColor:
                    return .colorPicker(
                        title: property.rawValue,
                        color: { tabBar.barTintColor },
                        handler: { tabBar.barTintColor = $0 }
                    )
                case .shadowImage:
                    return .imagePicker(
                        title: property.rawValue,
                        image: { tabBar.shadowImage },
                        handler: { tabBar.shadowImage = $0 }
                    )
                case .backgroundImage:
                    return .imagePicker(
                        title: property.rawValue,
                        image: { tabBar.backgroundImage },
                        handler: { tabBar.backgroundImage = $0 }
                    )
                case .separator:
                    return .separator

                case .selectionIndicatorImage:
                    return .imagePicker(
                        title: property.rawValue,
                        image: { tabBar.selectionIndicatorImage },
                        handler: { tabBar.selectionIndicatorImage = $0 }
                    )
                }
            }
        }
    }
}
