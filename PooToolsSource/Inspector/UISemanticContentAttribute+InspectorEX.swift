//
//  UISemanticContentAttribute+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UISemanticContentAttribute: CaseIterable {
    public typealias AllCases = [UISemanticContentAttribute]

    public static let allCases: [UISemanticContentAttribute] = [
        .unspecified,
        .playback,
        .spatial,
        .forceLeftToRight,
        .forceRightToLeft
    ]
}

extension UISemanticContentAttribute: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unspecified:
            return "Unspecified"

        case .playback:
            return "Playback"

        case .spatial:
            return "Spatial"

        case .forceLeftToRight:
            return "Force Left To Right"

        case .forceRightToLeft:
            return "Force right To Left"

        @unknown default:
            return "\(self) (unsupported)"
        }
    }
}
