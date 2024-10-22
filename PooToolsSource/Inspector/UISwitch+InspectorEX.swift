//
//  UISwitch+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UISwitch.Style: @retroactive CaseIterable {
    public typealias AllCases = [UISwitch.Style]

    public static let allCases: [UISwitch.Style] = [
        .automatic,
        .checkbox,
        .sliding
    ]
}

extension UISwitch.Style: CustomStringConvertible {
    public var description: String {
        switch self {
        case .automatic:
            return "Automatic"

        case .checkbox:
            return "Checkbox"

        case .sliding:
            return "Sliding"

        @unknown default:
            return "\(self) (unsupported)"
        }
    }
}
