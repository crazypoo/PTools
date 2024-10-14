//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementAttributesLibrary {
    final class ControlAttributesSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title = "Control"

        private weak var control: UIControl?

        init?(with object: NSObject) {
            guard let control = object as? UIControl else { return nil }

            self.control = control
        }

        private enum Property: String, Swift.CaseIterable {
            case contentHorizontalAlignment = "Horizontal Alignment"
            case contentVerticalAlignment = "Vertical Alignment"
            case groupState = "State"
            case isSelected = "Selected"
            case isEnabled = "Enabled"
            case isHighlighted = "Highlighted"
        }

        var properties: [InspectorElementProperty] {
            guard let control = control else { return [] }

            return Property.allCases.compactMap { property in
                switch property {
                case .contentHorizontalAlignment:
                    let allCases = UIControl.ContentHorizontalAlignment.allCases.withImages

                    return .imageButtonGroup(
                        title: property.rawValue,
                        images: allCases.compactMap(\.image),
                        selectedIndex: { allCases.firstIndex(of: control.contentHorizontalAlignment) }
                    ) {
                        guard let newIndex = $0 else { return }

                        let contentHorizontalAlignment = allCases[newIndex]

                        control.contentHorizontalAlignment = contentHorizontalAlignment
                    }
                case .contentVerticalAlignment:
                    let knownCases = UIControl.ContentVerticalAlignment.allCases.filter { $0.image?.withRenderingMode(.alwaysTemplate) != nil }

                    return .imageButtonGroup(
                        title: property.rawValue,
                        images: knownCases.compactMap(\.image),
                        selectedIndex: { knownCases.firstIndex(of: control.contentVerticalAlignment) }
                    ) {
                        guard let newIndex = $0 else { return }

                        let contentVerticalAlignment = UIControl.ContentVerticalAlignment.allCases[newIndex]

                        control.contentVerticalAlignment = contentVerticalAlignment
                    }
                case .groupState:
                    return .group(title: property.rawValue)

                case .isSelected:
                    return .switch(
                        title: property.rawValue,
                        isOn: { control.isSelected }
                    ) { isSelected in
                        control.isSelected = isSelected
                    }
                case .isEnabled:
                    return .switch(
                        title: property.rawValue,
                        isOn: { control.isEnabled }
                    ) { isEnabled in
                        control.isEnabled = isEnabled
                    }
                case .isHighlighted:
                    return .switch(
                        title: property.rawValue,
                        isOn: { control.isHighlighted }
                    ) { isHighlighted in
                        control.isHighlighted = isHighlighted
                    }
                }
            }
        }
    }
}
