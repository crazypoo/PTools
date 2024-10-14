//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class OffsetControl: StepperPairControl<CGFloat> {
    private var horizontal: CGFloat {
        get { firstValue }
        set { firstValue = newValue }
    }

    private var vertical: CGFloat {
        get { secondValue }
        set { secondValue = newValue }
    }

    var offset: UIOffset {
        get {
            UIOffset(
                horizontal: horizontal,
                vertical: vertical
            )
        }
        set {
            horizontal = newValue.horizontal
            vertical = newValue.vertical
        }
    }

    override var title: String? {
        didSet {
            firstSubtitle = "Horizontal".string(prepending: title)
            secondSubtitle = "Vertical".string(prepending: title)
        }
    }

    convenience init(title: String?, offset: UIOffset) {
        self.init(
            firstValue: offset.horizontal,
            firstRange: -Double.infinity...Double.infinity,
            secondValue: offset.vertical,
            secondRange: -Double.infinity...Double.infinity
        )

        self.title = title
    }
}
