//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementIdentityLibrary {
    final class PreviewIdentitySectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title: String = Texts.preview

        private let element: ViewHierarchyElement

        private var isHighlightingViews: Bool { element.containsVisibleHighlightViews }

        init(with view: UIView) {
            element = .init(with: view, iconProvider: .default)
        }

        private enum Property: String, Swift.CaseIterable {
            case preview = "Preview"
            case backgroundColor = "Preview Background"
        }

        var properties: [InspectorElementProperty] {
            Property.allCases.compactMap { property in
                switch property {
                case .preview:
                    guard let view = element.underlyingView else { return nil }
                    return .preview(target: .init(view: view))

                case .backgroundColor:
                    return .colorPicker(
                        title: property.rawValue,
                        color: { Inspector.sharedInstance.configuration.elementInspectorConfiguration.thumbnailBackgroundStyle.color },
                        handler: {
                            guard let color = $0 else { return }
                            Inspector.sharedInstance.configuration.elementInspectorConfiguration.thumbnailBackgroundStyle = .custom(color)
                        }
                    )
                }
            }
        }
    }
}
