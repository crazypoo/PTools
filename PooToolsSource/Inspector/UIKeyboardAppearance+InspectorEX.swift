//
//  UIKeyboardAppearance+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UIKeyboardAppearance: @retroactive CaseIterable {
    public typealias AllCases = [UIKeyboardAppearance]

    public static let allCases: [UIKeyboardAppearance] = [
        .default,
        .dark,
        .light
    ]
}

extension UIKeyboardAppearance: CustomStringConvertible {
    public var description: String {
        switch self {
        case .default:
            return Texts.default

        case .dark:
            return "Dark"

        case .light:
            return "Light"

        @unknown default:
            return "\(self) (unsupported)"
        }
    }
}
