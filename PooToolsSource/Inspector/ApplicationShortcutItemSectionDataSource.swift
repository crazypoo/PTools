//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

import UIKit

extension DefaultElementAttributesLibrary {
    final class ApplicationShortcutItemSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        var title: String { shortcutItem.localizedTitle }

        let shortcutItem: UIApplicationShortcutItem

        init?(with object: NSObject) {
            guard let shortcutItem = object as? UIApplicationShortcutItem else { return nil }
            self.shortcutItem = shortcutItem
        }

        private enum Property: String, Swift.CaseIterable {
            case type = "Link"
            case localizedTitle = "Title"
            case localizedSubtitle = "Subtitle"
        }

        var properties: [InspectorElementProperty] {
            Property.allCases.compactMap { property in
                switch property {
                case .type:
                    return .textField(
                        title: property.rawValue,
                        placeholder: property.rawValue,
                        value: { self.shortcutItem.type }
                    )
                case .localizedTitle:
                    return .textField(
                        title: property.rawValue,
                        placeholder: .none,
                        value: { self.shortcutItem.localizedTitle }
                    )
                case .localizedSubtitle:
                    return .textField(
                        title: property.rawValue,
                        placeholder: property.rawValue,
                        value: { self.shortcutItem.localizedSubtitle }
                    )
                }
            }
        }
    }
}
