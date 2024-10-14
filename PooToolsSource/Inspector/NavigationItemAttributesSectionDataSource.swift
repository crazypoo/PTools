//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementAttributesLibrary {
    final class NavigationItemAttributesSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title = "Navigation Item"

        private weak var navigationItem: UINavigationItem?

        init?(with object: NSObject) {
            guard let navigationItem = (object as? UIViewController)?.navigationItem else {
                return nil
            }

            self.navigationItem = navigationItem
        }

        private enum Property: String, Swift.CaseIterable {
            case title = "Title"
            case prompt = "Prompt"
            case backButtonTitle = "Back Button"
            case leftItemsSupplementBackButton = "Left Items Supplement"
            case LargeTitle = "Large Title"
        }

        var properties: [InspectorElementProperty] {
            guard let navigationItem = navigationItem else { return [] }

            return Property.allCases.compactMap { property in
                switch property {
                case .title:
                    return .textField(
                        title: property.rawValue,
                        placeholder: navigationItem.title,
                        axis: .vertical,
                        value: { navigationItem.title },
                        handler: { navigationItem.title = $0.isNilOrEmpty ? nil : $0 }
                    )
                case .prompt:
                    return .textField(
                        title: property.rawValue,
                        placeholder: navigationItem.prompt,
                        axis: .vertical,
                        value: { navigationItem.prompt },
                        handler: { navigationItem.prompt = $0.isNilOrEmpty ? nil : $0 }
                    )
                case .backButtonTitle:
                    return .textField(
                        title: property.rawValue,
                        placeholder: navigationItem.backButtonTitle,
                        axis: .vertical,
                        value: { navigationItem.backButtonTitle },
                        handler: { navigationItem.backButtonTitle = $0.isNilOrEmpty ? nil : $0 }
                    )
                case .leftItemsSupplementBackButton:
                    return .switch(
                        title: property.rawValue,
                        isOn: { navigationItem.leftItemsSupplementBackButton },
                        handler: { navigationItem.leftItemsSupplementBackButton = $0 }
                    )
                case .LargeTitle:
                    return .optionsList(
                        title: property.rawValue,
                        axis: .vertical,
                        options: UINavigationItem.LargeTitleDisplayMode.allCases.map(\.description),
                        selectedIndex: { UINavigationItem.LargeTitleDisplayMode.allCases.firstIndex(of: navigationItem.largeTitleDisplayMode) },
                        handler: {
                            guard let newIndex = $0 else { return }

                            let largeTitleDisplayMode = UINavigationItem.LargeTitleDisplayMode.allCases[newIndex]
                            navigationItem.largeTitleDisplayMode = largeTitleDisplayMode
                        }
                    )
                }
            }
        }
    }
}

extension UINavigationItem.LargeTitleDisplayMode: CaseIterable {
    public typealias AllCases = [UINavigationItem.LargeTitleDisplayMode]

    public static let allCases: [UINavigationItem.LargeTitleDisplayMode] = [
        automatic,
        always,
        never
    ]
}

extension UINavigationItem.LargeTitleDisplayMode: CustomStringConvertible {
    var description: String {
        switch self {
        case .automatic:
            return "Automatic"
        case .always:
            return "Always"
        case .never:
            return "Never"
        @unknown default:
            return "Unknown"
        }
    }
}
