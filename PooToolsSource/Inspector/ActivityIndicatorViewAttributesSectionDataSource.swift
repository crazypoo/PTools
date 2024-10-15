//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementAttributesLibrary {
    final class ActivityIndicatorViewAttributesSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title = "Activity Indicator"

        private weak var activityIndicatorView: UIActivityIndicatorView?

        init?(with object: NSObject) {
            guard let activityIndicatorView = object as? UIActivityIndicatorView else { return nil }

            self.activityIndicatorView = activityIndicatorView
        }

        private enum Property: String, Swift.CaseIterable {
            case style = "Style"
            case color = "Color"
            case groupBehavior = "Behavior"
            case isAnimating = "Animating"
            case hidesWhenStopped = "Hides When Stopped"
        }

        var properties: [InspectorElementProperty] {
            guard let activityIndicatorView = activityIndicatorView else { return [] }

            return Property.allCases.compactMap { property in
                switch property {
                case .style:
                    return .optionsList(title: property.rawValue, options: UIActivityIndicatorView.Style.allCases.map(\.description), selectedIndex: { UIActivityIndicatorView.Style.allCases.firstIndex(of: activityIndicatorView.style) }) {
                        guard let newIndex = $0 else { return }
                        let style = UIActivityIndicatorView.Style.allCases[newIndex]
                        activityIndicatorView.style = style
                    }
                case .color:
                    return .colorPicker(title: property.rawValue, color: { activityIndicatorView.color }) {
                        guard let color = $0 else {
                            return
                        }
                        activityIndicatorView.color = color
                    }
                case .groupBehavior:
                    return .group(title: property.rawValue)
                case .isAnimating:
                    return .switch(title: property.rawValue, isOn: { activityIndicatorView.isAnimating }) { isAnimating in
                        switch isAnimating {
                        case true:
                            activityIndicatorView.startAnimating()

                        case false:
                            activityIndicatorView.stopAnimating()
                        }
                    }
                case .hidesWhenStopped:
                    return .switch(title: property.rawValue, isOn: { activityIndicatorView.hidesWhenStopped }) { hidesWhenStopped in
                        activityIndicatorView.hidesWhenStopped = hidesWhenStopped
                    }
                }
            }
        }
    }
}
