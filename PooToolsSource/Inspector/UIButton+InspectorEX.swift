//
//  UIButton+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UIButton.ButtonType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .custom: return "Custom"
        case .system: return "System"
        case .detailDisclosure: return "Detail Disclosure"
        case .infoLight: return "Info Light"
        case .infoDark: return "Info Dark"
        case .contactAdd: return "Contact Add"
        case .close: return "Close"
        @unknown default: return "Unknown"
        }
    }
}

extension UIButton.ButtonType: @retroactive CaseIterable {
    public typealias AllCases = [UIButton.ButtonType]

    public static let allCases: [UIButton.ButtonType] = [
        .custom,
        .system,
        .detailDisclosure,
        .infoLight,
        .infoDark,
        .contactAdd,
        .close
    ]
}
