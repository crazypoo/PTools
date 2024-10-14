//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

enum ThumbnailBackgroundStyle: Hashable, CaseIterable, RawRepresentable {
    typealias RawValue = Int

    typealias AllCases = [ThumbnailBackgroundStyle]

    static let allCases: [ThumbnailBackgroundStyle] = [
        strong,
        medium,
        systemBackground
    ]

    case strong
    case medium
    case systemBackground
    case custom(UIColor)

    init?(rawValue: Int) {
        switch rawValue {
        case 0:
            self = .strong
        case 1:
            self = .medium
        case 2:
            self = .systemBackground
        default:
            return nil
        }
    }

    var rawValue: Int {
        switch self {
        case .strong:
            return 0
        case .medium:
            return 1
        case .systemBackground:
            return 2
        case .custom:
            return -1
        }
    }

    var color: UIColor {
        switch (self, Inspector.sharedInstance.configuration.colorStyle) {
        case (.strong, .dark):
            return UIColor(white: 0.40, alpha: 1)
        case (.medium, .dark):
            return UIColor(white: 0.80, alpha: 1)
        case (.systemBackground, .dark):
            return UIColor(white: 0, alpha: 1)

        case (.strong, .light):
            return UIColor(white: 0.40, alpha: 1)
        case (.medium, .light):
            return UIColor(white: 0.80, alpha: 1)
        case (.systemBackground, .light):
            return UIColor(white: 1, alpha: 1)
        case let (.custom(color), _):
            return color
        }
    }

    var contrastingColor: UIColor {
        switch (self, Inspector.sharedInstance.configuration.colorStyle) {
        case (.strong, .dark):
            return .darkText
        case (.medium, .dark):
            return .white
        case (.systemBackground, .dark):
            return .lightGray

        case (.strong, .light):
            return .white
        case (.medium, .light):
            return .darkText
        case (.systemBackground, .light):
            return .darkText

        case let (.custom(color), _):
            return color.contrasting
        }
    }

    var image: UIImage {
        switch self {
        case .strong:
            return IconKit.imageOfAppearanceLight().withRenderingMode(.alwaysTemplate)

        case .custom, .medium:
            return IconKit.imageOfAppearanceMedium().withRenderingMode(.alwaysTemplate)

        case .systemBackground:
            return IconKit.imageOfAppearanceDark().withRenderingMode(.alwaysTemplate)
        }
    }
}
