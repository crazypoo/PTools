//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

enum DefaultElementSizeLibrary: InspectorElementLibraryProtocol, Swift.CaseIterable {
    case button
    case segmentedControl
    case label
    case tableView
    case scrollView
    case viewFrame
    case contentLayoutPriority
    case layoutConstraints

    var targetClass: AnyClass {
        switch self {
        case .tableView:
            return UITableView.self

        case .button:
            return UIButton.self

        case .segmentedControl:
            return UISegmentedControl.self

        case .scrollView:
            return UIScrollView.self

        case .label:
            return UILabel.self

        case .contentLayoutPriority,
             .viewFrame,
             .layoutConstraints:
            return UIView.self
        }
    }

    func sections(for object: NSObject) -> InspectorElementSections {
        switch self {
        case .tableView:
            return .init(with: TableViewSizeSectionDataSource(with: object))

        case .button:
            return .init(with: ButtonSizeSectionDataSource(with: object))

        case .label:
            return .init(with: LabelSizeSectionDataSource(with: object))

        case .segmentedControl:
            return .init(with: SegmentedControlSizeSectionDataSource(with: object))

        case .scrollView:
            return .init(with: ScrollViewSizeSectionDataSource(with: object))

        case .viewFrame:
            return .init(with: ViewFrameSizeSectionDataSource(with: object))

        case .contentLayoutPriority:
            return .init(with: ContentLayoutPrioritySizeSectionDataSource(with: object))

        case .layoutConstraints:
            guard let referenceView = object as? UIView else { return .empty }

            let element = ViewHierarchyElement(with: referenceView, iconProvider: .default)

            let dataSources = element.constraintElements.map {
                LayoutConstraintSizeSectionDataSource(constraint: $0)
            }

            let horizontal = dataSources.filter { $0.axis == .horizontal }
            let vertical = dataSources.filter { $0.axis == .vertical }

            var sections: InspectorElementSections = []

            if horizontal.isEmpty == false {
                sections.append(
                    InspectorElementSection(
                        title: "Horizontal Constraints",
                        rows: horizontal
                    )
                )
            }
            if vertical.isEmpty == false {
                sections.append(
                    InspectorElementSection(
                        title: "Vertical Constraints",
                        rows: vertical
                    )
                )
            }

            return sections
        }
    }
}
