//
//  UIKeyboardType+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UIKeyboardType: CaseIterable {
    public typealias AllCases = [UIKeyboardType]

    public static let allCases: [UIKeyboardType] = [
        .default,
        .asciiCapable,
        .numbersAndPunctuation,
        .URL,
        .numberPad,
        .phonePad,
        .namePhonePad,
        .emailAddress,
        .decimalPad,
        .twitter,
        .webSearch,
        .asciiCapableNumberPad
    ]
}

extension UIKeyboardType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .default:
            return Texts.default

        case .asciiCapable:
            return "Ascii Capable"

        case .numbersAndPunctuation:
            return "Numbers And Punctuation"

        case .URL:
            return "URL"

        case .numberPad:
            return "Number Pad"

        case .phonePad:
            return "Phone Pad"

        case .namePhonePad:
            return "Name Phone Pad"

        case .emailAddress:
            return "Email Address"

        case .decimalPad:
            return "Decimal Pad"

        case .twitter:
            return "Twitter"

        case .webSearch:
            return "Web Search"

        case .asciiCapableNumberPad:
            return "Ascii Capable Number Pad"

        @unknown default:
            return "\(self) (unsupported)"
        }
    }
}
