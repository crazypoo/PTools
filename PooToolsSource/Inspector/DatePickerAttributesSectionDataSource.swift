//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementAttributesLibrary {
    final class DatePickerAttributesSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title = "Date Picker"

        private weak var datePicker: UIDatePicker?

        init?(with object: NSObject) {
            guard let datePicker = object as? UIDatePicker else { return nil }

            self.datePicker = datePicker
        }

        private let minuteIntervalRange = 1...30

        private lazy var validMinuteIntervals = minuteIntervalRange.filter { 60 % $0 == 0 }

        private enum Property: String, Swift.CaseIterable {
            case datePickerStyle = "Style"
            case datePickerMode = "Mode"
            case locale = "Locale"
            case minuteInterval = "Interval"
        }

        var properties: [InspectorElementProperty] {
            guard let datePicker = datePicker else { return [] }

            return Property.allCases.compactMap { property in
                switch property {
                case .datePickerStyle:
                    return .optionsList(
                        title: property.rawValue,
                        options: UIDatePickerStyle.allCases.map(\.description),
                        selectedIndex: { UIDatePickerStyle.allCases.firstIndex(of: datePicker.datePickerStyle) }
                    ) {
                        guard let newIndex = $0 else {
                            return
                        }

                        let datePickerStyle = UIDatePickerStyle.allCases[newIndex]

                        if datePicker.datePickerMode == .countDownTimer, datePickerStyle == .inline || datePickerStyle == .compact {
                            datePicker.datePickerMode = .dateAndTime
                        }

                        datePicker.preferredDatePickerStyle = datePickerStyle
                    }

                case .datePickerMode:
                    return .optionsList(
                        title: property.rawValue,
                        options: UIDatePicker.Mode.allCases.map(\.description),
                        selectedIndex: { UIDatePicker.Mode.allCases.firstIndex(of: datePicker.datePickerMode) }
                    ) {
                        guard let newIndex = $0 else { return }

                        let datePickerMode = UIDatePicker.Mode.allCases[newIndex]

                        if datePickerMode == .countDownTimer, datePicker.datePickerStyle == .inline || datePicker.datePickerStyle == .compact {
                            return
                        }

                        datePicker.datePickerMode = datePickerMode
                    }

                case .locale:
                    return nil

                case .minuteInterval:
                    return .optionsList(
                        title: property.rawValue,
                        options: validMinuteIntervals.map { "\($0) \($0 == 1 ? "minute" : "minutes")" },
                        selectedIndex: { self.validMinuteIntervals.firstIndex(of: datePicker.minuteInterval) }
                    ) {
                        guard let newIndex = $0 else { return }

                        let minuteInterval = self.validMinuteIntervals[newIndex]

                        datePicker.minuteInterval = minuteInterval
                    }
                }
            }
        }
    }
}
