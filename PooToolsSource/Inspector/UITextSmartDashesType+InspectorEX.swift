//
//  UITextSmartDashesType+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UITextSmartDashesType: @retroactive CaseIterable {
    public typealias AllCases = [UITextSmartDashesType]

    public static let allCases: [UITextSmartDashesType] = [
        .default,
        .no,
        .yes
    ]
}

extension UITextSmartDashesType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .default:
            return Texts.default

        case .no:
            return "No"

        case .yes:
            return "Yes"

        @unknown default:
            return "\(self) (unsupported)"
        }
    }
}
