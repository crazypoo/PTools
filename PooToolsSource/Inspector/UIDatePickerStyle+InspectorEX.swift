//
//  UIDatePickerStyle+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UIDatePickerStyle: @retroactive CaseIterable {
    public typealias AllCases = [UIDatePickerStyle]

    public static var allCases: [UIDatePickerStyle] {
        return [
            .automatic,
            .wheels,
            .compact,
            .inline
        ]
    }
}

extension UIDatePickerStyle: CustomStringConvertible {
    public var description: String {
        switch self {
        case .automatic:
            return "Automatic"
        case .wheels:
            return "Wheels"
        case .compact:
            return "Compact"
        case .inline:
            return "Inline"
        @unknown default:
            return "Unknown"
        }
    }
}
