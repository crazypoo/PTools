//
//  UIBarStyle+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UIBarStyle: CaseIterable {
    public typealias AllCases = [UIBarStyle]

    public static let allCases: [UIBarStyle] = [
        .default,
        .black
    ]
}

extension UIBarStyle: CustomStringConvertible {
    public var description: String {
        switch self {
        case .default:
            return Texts.default
        case .black:
            return "Black"
        case .blackTranslucent:
            return "Black Translucent (Deprecated)"
        @unknown default:
            return "Unkown"
        }
    }
}
