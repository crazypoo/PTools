//
//  UIDatePickerStyle+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UIDatePickerStyle: CaseIterable {
    public typealias AllCases = [UIDatePickerStyle]

    public static var allCases: [UIDatePickerStyle] {
        if #available(iOS 14.0, *) {
            return [
                .automatic,
                .wheels,
                .compact,
                .inline
            ]
        }

        return [
            .automatic,
            .wheels,
            .compact
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
