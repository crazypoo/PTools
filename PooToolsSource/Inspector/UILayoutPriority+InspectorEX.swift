//
//  UILayoutPriority+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UILayoutPriority: @retroactive CaseIterable {
    public typealias AllCases = [UILayoutPriority]

    public static let allCases: [UILayoutPriority] = [
        .fittingSizeLevel,
        .defaultLow,
        .defaultHigh,
        .required
    ]
}

extension UILayoutPriority: CustomStringConvertible {
    public var name: String {
        switch self {
        case .defaultHigh:
            return "High"
        case .defaultLow:
            return "Low"
        case .fittingSizeLevel:
            return "Fitting Size"
        case .required:
            return "Required"
        case .dragThatCanResizeScene:
            return "Drag That Can Resize Scene"
        case .sceneSizeStayPut:
            return "Scene Size Stay Put"
        case .dragThatCannotResizeScene:
            return "Drag That Can't Resize Scene"
        default:
            return rawValue.toString()
        }
    }

    var description: String { "\(name) (\(rawValue.toString()))" }
}
