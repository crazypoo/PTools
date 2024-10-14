//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementSizeLibrary {
    final class ButtonSizeSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title: String = "Button"

        private weak var button: UIButton?

        init?(with object: NSObject) {
            guard let button = object as? UIButton else { return nil }
            self.button = button
        }

        private enum Properties: String, Swift.CaseIterable {
            case contentEdgeInsets = "Content Insets"
            case titleEdgeInsets = "Title Insets"
            case imageEdgeInsets = "Image Insets"
        }

        var properties: [InspectorElementProperty] {
            guard let button = button else { return [] }

            return Properties.allCases.map { property in
                switch property {
                case .contentEdgeInsets:
                    return .edgeInsets(
                        title: property.rawValue,
                        insets: { button.contentEdgeInsets },
                        handler: { button.contentEdgeInsets = $0 }
                    )
                case .imageEdgeInsets:
                    return .edgeInsets(
                        title: property.rawValue,
                        insets: { button.imageEdgeInsets },
                        handler: { button.imageEdgeInsets = $0 }
                    )
                case .titleEdgeInsets:
                    return .edgeInsets(
                        title: property.rawValue,
                        insets: { button.titleEdgeInsets },
                        handler: { button.titleEdgeInsets = $0 }
                    )
                }
            }
        }
    }
}
