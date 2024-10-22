//
//  UIDatePicker+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UIDatePicker.Mode: @retroactive CaseIterable {
    public typealias AllCases = [UIDatePicker.Mode]

    public static let allCases: [UIDatePicker.Mode] = [
        .time,
        .date,
        .dateAndTime,
        .countDownTimer
    ]
}

extension UIDatePicker.Mode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .time:
            return "Time"

        case .date:
            return "Date"

        case .dateAndTime:
            return "Date And Time"

        case .countDownTimer:
            return "Count Down Timer"

        case .yearAndMonth:
            return "Year And Month"
        @unknown default:
            return "Unknown"
        }
    }
}
