//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementSizeLibrary {
    final class ContentLayoutPrioritySizeSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title: String = "Content Layout Priority"

        private weak var view: UIView?

        init?(with object: NSObject) {
            guard let view = object as? UIView else { return nil }

            self.view = view
        }

        private enum Properties: String, Swift.CaseIterable {
            case groupHuggingPriority = "Content Hugging Priority"
            case horizontalHugging = "Horizontal Hugging"
            case verticalHugging = "Vertical Hugging"
            case separator0
            case groupCompressionResistancePriority = "Content Compression Resistance Priority"
            case horizontalCompressionResistance = "Horizontal Resistance"
            case verticalCompressionResistance = "Vertical Resistance"
            case separator1
            case instrinsicContentSize = "Intrinsic Size"
        }

        var properties: [InspectorElementProperty] {
            guard let view = view else { return [] }

            return Properties.allCases.map { property in
                switch property {
                case .groupHuggingPriority,
                     .groupCompressionResistancePriority:
                    return .group(title: property.rawValue)

                case .horizontalHugging:
                    return .optionsList(
                        title: property.rawValue,
                        options: UILayoutPriority.allCases.map(\.description),
                        selectedIndex: { UILayoutPriority.allCases.firstIndex(of: view.contentHuggingPriority(for: .horizontal)) },
                        handler: {
                            guard let newIndex = $0 else { return }
                            let priority = UILayoutPriority.allCases[newIndex]
                            view.setContentHuggingPriority(priority, for: .horizontal)
                        }
                    )

                case .verticalHugging:
                    return .optionsList(
                        title: property.rawValue,
                        options: UILayoutPriority.allCases.map(\.description),
                        selectedIndex: { UILayoutPriority.allCases.firstIndex(of: view.contentHuggingPriority(for: .vertical)) },
                        handler: {
                            guard let newIndex = $0 else { return }
                            let priority = UILayoutPriority.allCases[newIndex]
                            view.setContentHuggingPriority(priority, for: .vertical)
                        }
                    )
                case .horizontalCompressionResistance:
                    return .optionsList(
                        title: property.rawValue,
                        options: UILayoutPriority.allCases.map(\.description),
                        selectedIndex: { UILayoutPriority.allCases.firstIndex(of: view.contentCompressionResistancePriority(for: .horizontal)) },
                        handler: {
                            guard let newIndex = $0 else { return }
                            let priority = UILayoutPriority.allCases[newIndex]
                            view.setContentCompressionResistancePriority(priority, for: .horizontal)
                        }
                    )
                case .verticalCompressionResistance:
                    return .optionsList(
                        title: property.rawValue,
                        options: UILayoutPriority.allCases.map(\.description),
                        selectedIndex: { UILayoutPriority.allCases.firstIndex(of: view.contentCompressionResistancePriority(for: .vertical)) },
                        handler: {
                            guard let newIndex = $0 else { return }
                            let priority = UILayoutPriority.allCases[newIndex]
                            view.setContentCompressionResistancePriority(priority, for: .vertical)
                        }
                    )
                case .separator0,
                     .separator1:
                    return .separator

                case .instrinsicContentSize:
                    return .cgSize(
                        title: property.rawValue,
                        size: { view.intrinsicContentSize },
                        handler: nil
                    )
                }
            }
        }
    }
}
