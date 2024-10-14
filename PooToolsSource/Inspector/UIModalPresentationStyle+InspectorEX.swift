//
//  UIModalPresentationStyle+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UIModalPresentationStyle: CaseIterable {
    public typealias AllCases = [UIModalPresentationStyle]

    public static let allCases: [UIModalPresentationStyle] = [
        .automatic,
        .fullScreen,
        .pageSheet,
        .formSheet,
        .currentContext,
        .custom,
        .overFullScreen,
        .overCurrentContext,
        .popover,
        .none
    ]
}

extension UIModalPresentationStyle: CustomStringConvertible {
    public var description: String {
        switch self {
        case .fullScreen:
            return "Full Screen"
        case .pageSheet:
            return "Page Sheet"
        case .formSheet:
            return "Form Sheet"
        case .currentContext:
            return "Current Context"
        case .custom:
            return "Custom"
        case .overFullScreen:
            return "Over Full Screen"
        case .overCurrentContext:
            return "Over Current Context"
        case .popover:
            return "Popover"
        case .none:
            return "None"
        case .automatic:
            return "Automatic"
        @unknown default:
            return "Unknown"
        }
    }
}
