//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementAttributesLibrary {
    final class SegmentedControlAttributesSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title = "Segmented Control"

        private weak var segmentedControl: UISegmentedControl?

        init?(with object: NSObject) {
            guard let segmentedControl = object as? UISegmentedControl else { return nil }

            self.segmentedControl = segmentedControl

            selectedSegment = segmentedControl.numberOfSegments == 0 ? nil : 0
        }

        private var selectedSegment: Int?

        private enum Property: String, Swift.CaseIterable {
            case selectedSegmentTintColor = "Selected Tint"
            case isMomentary = "Momentary"
            case isSpringLoaded = "Spring Loaded"
            case groupSegment = "Segment Group"
            case segmentPicker = "Segment"
            case segmentTitle = "Title"
            case segmentImage = "Image"
            case segmentIsEnabled = "Enabled"
            case segmentIsSelected = "Selected"
        }

        var properties: [InspectorElementProperty] {
            guard let segmentedControl = segmentedControl else { return [] }

            return Property.allCases.compactMap { property in
                switch property {
                case .selectedSegmentTintColor:
                    guard #available(iOS 13.0, *) else { return nil }

                    return .colorPicker(
                        title: property.rawValue,
                        color: { segmentedControl.selectedSegmentTintColor }
                    ) { selectedSegmentTintColor in
                        segmentedControl.selectedSegmentTintColor = selectedSegmentTintColor
                    }
                case .isMomentary:
                    return .switch(
                        title: property.rawValue,
                        isOn: { segmentedControl.isMomentary }
                    ) { isMomentary in
                        segmentedControl.isMomentary = isMomentary
                    }
                case .isSpringLoaded:
                    return .switch(
                        title: property.rawValue,
                        isOn: { segmentedControl.isSpringLoaded }
                    ) { isSpringLoaded in
                        segmentedControl.isSpringLoaded = isSpringLoaded
                    }

                case .groupSegment:
                    return .separator

                case .segmentPicker:
                    return .segmentPicker(for: segmentedControl) { [weak self] selectedSegment in
                        self?.selectedSegment = selectedSegment
                    }
                case .segmentTitle:
                    return .textField(
                        title: property.rawValue,
                        placeholder: property.rawValue,
                        value: { [weak self] in

                            guard let selectedSegment = self?.selectedSegment else {
                                return nil
                            }

                            return segmentedControl.titleForSegment(at: selectedSegment)
                        }
                    ) { [weak self] segmentTitle in

                        guard let selectedSegment = self?.selectedSegment else {
                            return
                        }

                        segmentedControl.setTitle(segmentTitle, forSegmentAt: selectedSegment)
                    }
                case .segmentImage:
                    return .imagePicker(
                        title: property.rawValue,
                        image: { [weak self] in

                            guard let selectedSegment = self?.selectedSegment else {
                                return nil
                            }

                            return segmentedControl.imageForSegment(at: selectedSegment)
                        }
                    ) { [weak self] segmentImage in

                        guard let selectedSegment = self?.selectedSegment else {
                            return
                        }

                        segmentedControl.setImage(segmentImage, forSegmentAt: selectedSegment)
                    }
                case .segmentIsEnabled:
                    return .switch(
                        title: property.rawValue,
                        isOn: { [weak self] in

                            guard let selectedSegment = self?.selectedSegment else {
                                return false
                            }

                            return segmentedControl.isEnabledForSegment(at: selectedSegment)
                        }
                    ) { [weak self] isEnabled in

                        guard let selectedSegment = self?.selectedSegment else {
                            return
                        }

                        segmentedControl.setEnabled(isEnabled, forSegmentAt: selectedSegment)
                    }
                case .segmentIsSelected:
                    return .switch(
                        title: property.rawValue,
                        isOn: { [weak self] in self?.selectedSegment == segmentedControl.selectedSegmentIndex }
                    ) { [weak self] isSelected in

                        guard let selectedSegment = self?.selectedSegment else {
                            return
                        }

                        switch isSelected {
                        case true:
                            segmentedControl.selectedSegmentIndex = selectedSegment

                        case false:
                            segmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
                        }
                    }
                }
            }
        }
    }
}
