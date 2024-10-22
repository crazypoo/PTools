//
//  NSLayoutConstraint+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension NSLayoutConstraint.Attribute {
    var axis: NSLayoutConstraint.Axis? {
        switch self {
        case .left,
             .leftMargin,
             .right,
             .rightMargin,
             .leading,
             .leadingMargin,
             .trailing,
             .trailingMargin,
             .centerX,
             .centerXWithinMargins,
             .width:
            return .horizontal
        case .top,
             .topMargin,
             .bottom,
             .bottomMargin,
             .centerY,
             .centerYWithinMargins,
             .lastBaseline,
             .firstBaseline,
             .height:
            return .vertical
        case .notAnAttribute:
            return nil
        @unknown default:
            return nil
        }
    }

    var displayName: String? {
        switch self {
        case .left,
             .leftMargin:
            return "Left Space"
        case .right,
             .rightMargin:
            return "Right Space"
        case .top,
             .topMargin:
            return "Top Space"
        case .bottom,
             .bottomMargin:
            return "Bottom Space"
        case .leading,
             .leadingMargin:
            return "Leading Space"
        case .trailing,
             .trailingMargin:
            return "Trailing Space"
        case .width:
            return "Width"
        case .height:
            return "Height"
        case .centerX,
             .centerXWithinMargins:
            return "Align Center X"
        case .centerY,
             .centerYWithinMargins:
            return "Align Center Y"
        case .lastBaseline:
            return "Last Baseline"
        case .firstBaseline:
            return "First Baseline"
        case .notAnAttribute:
            return nil
        @unknown default:
            return nil
        }
    }

    var isRelativeToMargin: Bool {
        switch self {
        case .leftMargin,
             .rightMargin,
             .topMargin,
             .bottomMargin,
             .leadingMargin,
             .trailingMargin,
             .centerXWithinMargins,
             .centerYWithinMargins:
            return true
        default:
            return false
        }
    }
}

extension NSLayoutConstraint.Axis: @retroactive CaseIterable {
    public typealias AllCases = [NSLayoutConstraint.Axis]

    public static let allCases: [NSLayoutConstraint.Axis] = [
        .horizontal,
        vertical
    ]
}

extension NSLayoutConstraint.Axis: CustomStringConvertible {
    public var description: String {
        switch self {
        case .horizontal:
            return "Horizontal"

        case .vertical:
            return "Vertical"

        @unknown default:
            return "\(self) (unsupported)"
        }
    }
}

extension NSLayoutConstraint.Relation: @retroactive CaseIterable {
    public typealias AllCases = [NSLayoutConstraint.Relation]
    public static let allCases: [NSLayoutConstraint.Relation] = [.lessThanOrEqual, .equal, .greaterThanOrEqual]
}

extension NSLayoutConstraint.Relation: CustomStringConvertible {
    var description: String {
        switch self {
        case .lessThanOrEqual:
            return "Less Than Or Equal"
        case .equal:
            return "Equals"
        case .greaterThanOrEqual:
            return "Greater Than Or Equal"
        @unknown default:
            return "Unknown"
        }
    }
}

extension NSLayoutConstraint {
    var safeIdentifier: String? {
        if identifier != nil {
            return identifier!
        }
        else {
            return nil
        }
    }
}
