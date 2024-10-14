//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementSizeLibrary {
    final class SegmentedControlSizeSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title: String = "Segmented Control"

        private var selectedSegment: Int?

        private weak var segmentedControl: UISegmentedControl?

        init?(with object: NSObject) {
            guard let segmentedControl = object as? UISegmentedControl else {
                return nil
            }

            self.segmentedControl = segmentedControl

            selectedSegment = segmentedControl.numberOfSegments == 0 ? nil : 0
        }

        private enum Properties: String, Swift.CaseIterable {
            case segmentPicker = "Segment"
            case segmentWidth = "Width"
            case separator
            case apportionsSegmentWidthsByContent = "Size Mode"
        }

        var properties: [InspectorElementProperty] {
            guard let segmentedControl = segmentedControl else { return [] }

            return Properties.allCases.map { property in
                switch property {
                case .segmentPicker:
                    return .segmentPicker(for: segmentedControl) { [weak self] selectedSegment in
                        self?.selectedSegment = selectedSegment
                    }
                case .segmentWidth:
                    return .cgFloatStepper(
                        title: property.rawValue,
                        value: { [weak self] in
                            guard let index = self?.selectedSegment else {
                                return .zero
                            }
                            return segmentedControl.widthForSegment(at: index)
                        },
                        range: { 0...segmentedControl.frame.width },
                        stepValue: { 1 },
                        handler: { [weak self] segmentWidth in
                            guard let index = self?.selectedSegment else {
                                return
                            }
                            segmentedControl.setWidth(segmentWidth, forSegmentAt: index)
                        }
                    )
                case .apportionsSegmentWidthsByContent:
                    return .optionsList(
                        title: property.rawValue,
                        options: ["Equal Widths", "Proportional to Content"],
                        selectedIndex: { segmentedControl.apportionsSegmentWidthsByContent ? 1 : 0 },
                        handler: { newIndex in
                            segmentedControl.apportionsSegmentWidthsByContent = newIndex == 1
                        }
                    )
                case .separator:
                    return .separator
                }
            }
        }
    }
}
