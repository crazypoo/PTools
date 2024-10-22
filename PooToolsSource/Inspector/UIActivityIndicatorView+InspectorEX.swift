//
//  UIActivityIndicatorView+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UIActivityIndicatorView.Style: @retroactive CaseIterable {
    public typealias AllCases = [UIActivityIndicatorView.Style]

    public static let allCases: [UIActivityIndicatorView.Style] = [
        .large,
        .medium
    ]
}

extension UIActivityIndicatorView.Style: CustomStringConvertible {
    public var description: String {
        switch self {
        case .medium:
            return "Medium"

        case .large:
            return "Large"

        case .whiteLarge:
            return "White Large (deprecated)"

        case .white:
            return "White (deprecated)"

        case .gray:
            return "Gray (deprecated)"

        @unknown default:
            return "\(self) (unsupported)"
        }
    }
}
