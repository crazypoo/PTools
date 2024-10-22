//
//  UIReturnKeyType+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UIReturnKeyType: @retroactive CaseIterable {
    public typealias AllCases = [UIReturnKeyType]

    public static let allCases: [UIReturnKeyType] = [
        .default,
        .go,
        .google,
        .join,
        .next,
        .route,
        .search,
        .send,
        .yahoo,
        .done,
        .emergencyCall,
        .continue
    ]
}

extension UIReturnKeyType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .default:
            return Texts.default

        case .go:
            return "Go"

        case .google:
            return "Google"

        case .join:
            return "Join"

        case .next:
            return "Next"

        case .route:
            return "Route"

        case .search:
            return "Search"

        case .send:
            return "Send"

        case .yahoo:
            return "Yahoo"

        case .done:
            return "Done"

        case .emergencyCall:
            return "Emergency Call"

        case .continue:
            return "Continue"

        @unknown default:
            return "\(self) (unsupported)"
        }
    }
}
