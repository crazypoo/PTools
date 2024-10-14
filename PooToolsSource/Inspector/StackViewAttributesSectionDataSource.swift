//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementAttributesLibrary {
    final class StackViewAttributesSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title = "Stack View"

        private weak var stackView: UIStackView?

        init?(with object: NSObject) {
            guard let stackView = object as? UIStackView else { return nil }

            self.stackView = stackView
        }

        private enum Property: String, Swift.CaseIterable {
            case axis = "Axis"
            case alignment = "Alignment"
            case distribution = "Distribution"
            case spacing = "Spacing"
            case isLayoutMarginsRelativeArrangement = "Layout Margins Relative"
            case isBaselineRelativeArrangement = "Baseline Relative"
        }

        var properties: [InspectorElementProperty] {
            guard let stackView = stackView else { return [] }

            return Property.allCases.compactMap { property in
                switch property {
                case .axis:
                    return .textButtonGroup(
                        title: property.rawValue,
                        texts: NSLayoutConstraint.Axis.allCases.map(\.description),
                        selectedIndex: { NSLayoutConstraint.Axis.allCases.firstIndex(of: stackView.axis) }
                    ) {
                        guard let newIndex = $0 else { return }

                        let axis = NSLayoutConstraint.Axis.allCases[newIndex]

                        stackView.axis = axis
                    }
                case .alignment:
                    return .optionsList(
                        title: property.rawValue,
                        options: UIStackView.Alignment.allCases.map(\.description),
                        selectedIndex: { UIStackView.Alignment.allCases.firstIndex(of: stackView.alignment) }
                    ) {
                        guard let newIndex = $0 else { return }

                        let alignment = UIStackView.Alignment.allCases[newIndex]

                        stackView.alignment = alignment
                    }
                case .distribution:
                    return .optionsList(
                        title: property.rawValue,
                        options: UIStackView.Distribution.allCases.map(\.description),
                        selectedIndex: { UIStackView.Distribution.allCases.firstIndex(of: stackView.distribution) }
                    ) {
                        guard let newIndex = $0 else { return }

                        let distribution = UIStackView.Distribution.allCases[newIndex]

                        stackView.distribution = distribution
                    }
                case .spacing:
                    return .cgFloatStepper(
                        title: property.rawValue,
                        value: { stackView.spacing },
                        range: { 0 ... .infinity },
                        stepValue: { 1 }
                    ) { spacing in
                        stackView.spacing = spacing
                    }
                case .isBaselineRelativeArrangement:
                    return .switch(
                        title: property.rawValue,
                        isOn: { stackView.isBaselineRelativeArrangement }
                    ) { isBaselineRelativeArrangement in
                        stackView.isBaselineRelativeArrangement = isBaselineRelativeArrangement
                    }
                case .isLayoutMarginsRelativeArrangement:
                    return .switch(
                        title: property.rawValue,
                        isOn: { stackView.isLayoutMarginsRelativeArrangement }
                    ) { isLayoutMarginsRelativeArrangement in
                        stackView.isLayoutMarginsRelativeArrangement = isLayoutMarginsRelativeArrangement
                    }
                }
            }
        }
    }
}
