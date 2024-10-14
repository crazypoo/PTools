//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

struct ElementInspectorAppearance: Hashable {
    let horizontalMargins: CGFloat = 24

    let verticalMargins: CGFloat = 12

    let elementInspectorCornerRadius: CGFloat = 30

    var panelInitialTransform: CGAffineTransform {
        CGAffineTransform(
            scaleX: 0.99,
            y: 0.98
        ).translatedBy(
            x: .zero,
            y: -verticalMargins
        )
    }

    var directionalInsets: NSDirectionalEdgeInsets {
        NSDirectionalEdgeInsets(
            horizontal: horizontalMargins,
            vertical: verticalMargins
        )
    }

    func font(forRelativeDepth relativeDepth: Int) -> UIFont {
        UIFont.preferredFont(
            forTextStyle: {
                switch relativeDepth {
                case let depth where depth <= -5:
                    return .title3
                case -4:
                    return .headline
                case -3:
                    return .subheadline
                case -2:
                    return .body
                case -1:
                    return .callout
                default:
                    return .footnote
                }
            }()
        )
    }

    func titleFont(forRelativeDepth relativeDepth: Int) -> UIFont {
        font(forRelativeDepth: relativeDepth - 5).bold()
    }
}
