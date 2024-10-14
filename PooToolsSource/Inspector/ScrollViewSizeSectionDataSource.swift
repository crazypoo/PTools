//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementSizeLibrary {
    final class ScrollViewSizeSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title: String = "Scroll View"

        private weak var scrollView: UIScrollView?

        init?(with object: NSObject) {
            guard let scrollView = object as? UIScrollView else { return nil }
            self.scrollView = scrollView
        }

        private enum Properties: String, Swift.CaseIterable {
            case verticalScrollIndicatorInsets = "Vertical Indicator Insets"
            case horizontalScrollIndicatorInsets = "Horizontal Indicator Insets"
            case contentInsetsAdjustmentBehavior = "Content Insets Adjustment"
            case contentInset = "Content Inset"
            case separator
            case adjustedContentInset = "Adjusted Content Inset"
        }

        var properties: [InspectorElementProperty] {
            guard let scrollView = scrollView else { return [] }

            return Properties.allCases.map { property in
                switch property {
                case .verticalScrollIndicatorInsets:
                    return .edgeInsets(
                        title: property.rawValue,
                        insets: { scrollView.verticalScrollIndicatorInsets },
                        handler: { scrollView.verticalScrollIndicatorInsets = $0 }
                    )
                case .horizontalScrollIndicatorInsets:
                    return .edgeInsets(
                        title: property.rawValue,
                        insets: { scrollView.horizontalScrollIndicatorInsets },
                        handler: { scrollView.horizontalScrollIndicatorInsets = $0 }
                    )
                case .contentInsetsAdjustmentBehavior:
                    return .optionsList(
                        title: property.rawValue,
                        axis: .vertical,
                        options: UIScrollView.ContentInsetAdjustmentBehavior.allCases.map(\.description),
                        selectedIndex: { UIScrollView.ContentInsetAdjustmentBehavior.allCases.firstIndex(of: scrollView.contentInsetAdjustmentBehavior) },
                        handler: {
                            guard let newIndex = $0 else { return }
                            let contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.allCases[newIndex]
                            scrollView.contentInsetAdjustmentBehavior = contentInsetAdjustmentBehavior
                        }
                    )
                case .contentInset:
                    return .edgeInsets(
                        title: property.rawValue,
                        insets: { scrollView.contentInset },
                        handler: { scrollView.contentInset = $0 }
                    )
                case .separator:
                    return .separator

                case .adjustedContentInset:
                    return .edgeInsets(
                        title: property.rawValue,
                        insets: { scrollView.adjustedContentInset },
                        handler: nil
                    )
                }
            }
        }
    }
}
