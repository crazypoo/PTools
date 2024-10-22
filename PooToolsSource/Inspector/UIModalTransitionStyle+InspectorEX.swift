//
//  UIModalTransitionStyle+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UIModalTransitionStyle: @retroactive CaseIterable {
    public typealias AllCases = [UIModalTransitionStyle]

    public static let allCases: [UIModalTransitionStyle] = [
        .coverVertical,
        .flipHorizontal,
        .crossDissolve,
        .partialCurl
    ]
}

extension UIModalTransitionStyle: CustomStringConvertible {
    public var description: String {
        switch self {
        case .coverVertical:
            return "Cover Vertical"
        case .flipHorizontal:
            return "Flip Horizontal"
        case .crossDissolve:
            return "Cross Dissolve"
        case .partialCurl:
            return "Partial Curl"
        @unknown default:
            return "Unknown"
        }
    }
}
