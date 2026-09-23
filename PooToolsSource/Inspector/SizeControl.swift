//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class SizeControl: StepperPairControl<CGFloat> {
    // English: Expose the size components through the existing stepper values.
    // Español: Expone los componentes del tamaño mediante los valores existentes del stepper.
    // 中文：通过现有 stepper 数值暴露尺寸分量。
    var width: CGFloat {
        get { firstValue }
        set { firstValue = newValue }
    }

    var height: CGFloat {
        get { secondValue }
        set { secondValue = newValue }
    }

    var size: CGSize {
        get { CGSize(width: width, height: height) }
        set {
            width = newValue.width
            height = newValue.height
        }
    }

    override var title: String? {
        didSet {
            firstSubtitle = "Width".string(prepending: title)
            secondSubtitle = "Height".string(prepending: title)
        }
    }

    convenience init(title: String?, size: CGSize) {
        self.init(
            firstValue: size.width,
            firstRange: 0...Double.infinity,
            secondValue: size.height,
            secondRange: 0...Double.infinity
        )

        self.title = title
    }
}
