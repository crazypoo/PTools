//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class AccessoryControl: BaseControl {
    override var isEnabled: Bool {
        didSet {
            backgroundColor = isEnabled ? colorStyle.accessoryControlBackgroundColor : colorStyle.accessoryControlDisabledBackgroundColor
        }
    }

    override func setup() {
        super.setup()

        animateOnTouch = true

        contentView.axis = .horizontal

        contentView.spacing = elementInspectorAppearance.verticalMargins / 2

        contentView.directionalLayoutMargins = NSDirectionalEdgeInsets(horizontal: 12, vertical: 9) // matches UIStepper

        layer.cornerRadius = 8

        backgroundColor = colorStyle.accessoryControlBackgroundColor
    }
}
