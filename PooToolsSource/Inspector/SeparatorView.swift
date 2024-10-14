//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class SeparatorView: BaseView {
    enum Style: ColorStylable {
        case soft
        case medium
        case hard
        case color(UIColor)

        fileprivate var color: UIColor {
            switch self {
            case .soft:
                return colorStyle.textColor.withAlphaComponent(0.09)
            case .medium:
                return colorStyle.textColor.withAlphaComponent(0.18)
            case .hard:
                return colorStyle.textColor.withAlphaComponent(0.27)
            case let .color(color):
                return color
            }
        }
    }

    var thickness: CGFloat {
        didSet {
            thicknessConstraint.constant = thicknesInPixels
        }
    }

    var thicknesInPixels: CGFloat { thickness / UIScreen.main.scale }

    var style: Style {
        didSet {
            backgroundColor = style.color
        }
    }

    private lazy var thicknessConstraint = heightAnchor.constraint(equalToConstant: thicknesInPixels)

    convenience init(color: UIColor, thickness: CGFloat = 1, frame: CGRect = .zero) {
        self.init(style: .color(color), thickness: thickness, frame: frame)
    }

    init(style: Style, thickness: CGFloat = 1, frame: CGRect = .zero) {
        self.thickness = thickness
        self.style = style

        super.init(frame: frame)

        backgroundColor = style.color
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setup() {
        super.setup()
        thicknessConstraint.isActive = true
    }
}
