//
//  UITextAutocapitalizationType+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UITextAutocapitalizationType: @retroactive CaseIterable {
    public typealias AllCases = [UITextAutocapitalizationType]

    public static let allCases: [UITextAutocapitalizationType] = [
        .none,
        .words,
        .sentences,
        .allCharacters
    ]
}

extension UITextAutocapitalizationType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none:
            return "None"

        case .words:
            return "Words"

        case .sentences:
            return "Sentences"

        case .allCharacters:
            return "All Characters"

        @unknown default:
            return "\(self) (unsupported)"
        }
    }
}
