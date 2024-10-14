//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementAttributesLibrary {
    final class SliderAttributesSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title = "Slider"

        private weak var slider: UISlider?

        init?(with object: NSObject) {
            guard let slider = object as? UISlider else { return nil }

            self.slider = slider
        }

        private enum Property: String, Swift.CaseIterable {
            case value = "Value"
            case minimumValue = "Minimum"
            case maximumValue = "Maximum"
            case groupImages = "Images"
            case minimumValueImage = "Min Image"
            case maximumValueImage = "Max Image"
            case groupColors = "Colors"
            case minimumTrackTintColor = "Min Track"
            case maxTrack = "Max Track"
            case thumbTintColor = "Thumb Tint"
            case groupEvent = "Event"
            case isContinuous = "Continuous updates"
        }

        var properties: [InspectorElementProperty] {
            guard let slider = slider else { return [] }
            let stepValueProvider = { max(0.01, (slider.maximumValue - slider.minimumValue) / 100) }

            return Property.allCases.compactMap { property in
                switch property {
                case .value:
                    return .floatStepper(
                        title: property.rawValue,
                        value: { slider.value },
                        range: { min(slider.minimumValue, slider.maximumValue)...max(slider.minimumValue, slider.maximumValue) },
                        stepValue: stepValueProvider
                    ) { value in
                        slider.value = value
                        slider.sendActions(for: .valueChanged)
                    }

                case .minimumValue:
                    return .floatStepper(
                        title: property.rawValue,
                        value: { slider.minimumValue },
                        range: { 0...max(0, slider.maximumValue) },
                        stepValue: stepValueProvider
                    ) { minimumValue in
                        slider.minimumValue = minimumValue
                    }

                case .maximumValue:
                    return .floatStepper(
                        title: property.rawValue,
                        value: { slider.maximumValue },
                        range: { slider.minimumValue...Float.infinity },
                        stepValue: stepValueProvider
                    ) { maximumValue in
                        slider.maximumValue = maximumValue
                    }

                case .groupImages:
                    return .separator

                case .minimumValueImage:
                    return .imagePicker(
                        title: property.rawValue,
                        image: { slider.minimumValueImage }
                    ) { minimumValueImage in
                        slider.minimumValueImage = minimumValueImage
                    }

                case .maximumValueImage:
                    return .imagePicker(
                        title: property.rawValue,
                        image: { slider.maximumValueImage }
                    ) { maximumValueImage in
                        slider.maximumValueImage = maximumValueImage
                    }

                case .groupColors:
                    return .separator

                case .minimumTrackTintColor:
                    return .colorPicker(
                        title: property.rawValue,
                        color: { slider.minimumTrackTintColor }
                    ) { minimumTrackTintColor in
                        slider.minimumTrackTintColor = minimumTrackTintColor
                    }

                case .maxTrack:
                    return .colorPicker(
                        title: property.rawValue,
                        color: { slider.maximumTrackTintColor }
                    ) { maximumTrackTintColor in
                        slider.maximumTrackTintColor = maximumTrackTintColor
                    }

                case .thumbTintColor:
                    return .colorPicker(
                        title: property.rawValue,
                        color: { slider.thumbTintColor }
                    ) { thumbTintColor in
                        slider.thumbTintColor = thumbTintColor
                    }

                case .groupEvent:
                    return .group(title: property.rawValue)

                case .isContinuous:
                    return .switch(
                        title: property.rawValue,
                        isOn: { slider.isContinuous }
                    ) { isContinuous in
                        slider.isContinuous = isContinuous
                    }
                }
            }
        }
    }
}
