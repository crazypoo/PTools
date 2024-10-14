//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class EdgeInsetsControl: BaseFormControl {
    var insets: UIEdgeInsets {
        get {
            .init(
                top: CGFloat(topStepper.value),
                left: CGFloat(leftStepper.value),
                bottom: CGFloat(bottomStepper.value),
                right: CGFloat(rightStepper.value)
            )
        }
        set {
            topStepper.value = Double(newValue.top)
            leftStepper.value = Double(newValue.left)
            bottomStepper.value = Double(newValue.bottom)
            rightStepper.value = Double(newValue.right)
        }
    }

    override var isEnabled: Bool {
        didSet {
            topStepper.isEnabled = isEnabled
            leftStepper.isEnabled = isEnabled
            bottomStepper.isEnabled = isEnabled
            rightStepper.isEnabled = isEnabled
        }
    }

    override var title: String? {
        didSet {
            topStepper.title = "Top".string(prepending: title)
            leftStepper.title = "Leading".string(prepending: title)
            bottomStepper.title = "Bottom".string(prepending: title)
            rightStepper.title = "Trailing".string(prepending: title)
        }
    }

    private lazy var topStepper = Self.makeStepper().then {
        $0.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    }

    private lazy var leftStepper = Self.makeStepper().then {
        $0.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    }

    private lazy var bottomStepper = Self.makeStepper().then {
        $0.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    }

    private lazy var rightStepper = Self.makeStepper().then {
        $0.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    }

    convenience init(title: String?, insets: UIEdgeInsets) {
        self.init(title: title, frame: .zero)
        self.insets = insets
    }

    override func setup() {
        super.setup()

        axis = .vertical

        applyTitleSectionStyle()

        contentView.axis = .vertical
        contentView.spacing = elementInspectorAppearance.verticalMargins
        contentView.addArrangedSubviews(
            topStepper,
            leftStepper,
            SeparatorView(style: .soft),
            bottomStepper,
            rightStepper
        )
    }

    @objc
    private func valueChanged() {
        sendActions(for: .valueChanged)
    }

    private static func makeStepper() -> StepperControl {
        StepperControl(
            title: .none,
            value: .zero,
            range: -Double.infinity...Double.infinity,
            stepValue: 1,
            isDecimalValue: true
        ).then {
            $0.containerView.directionalLayoutMargins.update(top: .zero, bottom: .zero)
            $0.isShowingSeparator = false
        }
    }
}
