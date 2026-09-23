//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class PointControl: StepperPairControl<CGFloat> {
    // English: Expose point components through the existing stepper values.
    // Español: Expone los componentes del punto mediante los valores existentes del stepper.
    // 中文：通过现有 stepper 数值暴露点坐标分量。
    var x: CGFloat {
        get { firstValue }
        set { firstValue = newValue }
    }

    var y: CGFloat {
        get { secondValue }
        set { secondValue = newValue }
    }

    var point: CGPoint {
        get { CGPoint(x: x, y: y) }
        set {
            x = newValue.x
            y = newValue.y
        }
    }

    override var title: String? {
        didSet {
            firstSubtitle = "X".string(prepending: title)
            secondSubtitle = "Y".string(prepending: title)
        }
    }

    convenience init(title: String?, point: CGPoint) {
        self.init(
            firstValue: point.x,
            firstRange: -Double.infinity...Double.infinity,
            secondValue: point.y,
            secondRange: -Double.infinity...Double.infinity
        )
        self.title = title
    }
}
