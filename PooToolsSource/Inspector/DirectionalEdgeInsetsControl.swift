//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class DirectionalEdgeInsetsControl: BaseFormControl {
    var insets: NSDirectionalEdgeInsets {
        get {
            .init(
                top: CGFloat(topStepper.value),
                leading: CGFloat(leadingStepper.value),
                bottom: CGFloat(bottomStepper.value),
                trailing: CGFloat(trailingStepper.value)
            )
        }
        set {
            topStepper.value = Double(newValue.top)
            leadingStepper.value = Double(newValue.leading)
            bottomStepper.value = Double(newValue.bottom)
            trailingStepper.value = Double(newValue.trailing)
        }
    }

    override var isEnabled: Bool {
        didSet {
            topStepper.isEnabled = isEnabled
            leadingStepper.isEnabled = isEnabled
            bottomStepper.isEnabled = isEnabled
            trailingStepper.isEnabled = isEnabled
        }
    }

    override var title: String? {
        didSet {
            topStepper.title = "Top".string(prepending: title)
            leadingStepper.title = "Leading".string(prepending: title)
            bottomStepper.title = "Bottom".string(prepending: title)
            trailingStepper.title = "Trailing".string(prepending: title)
        }
    }

    private lazy var topStepper = Self.makeStepper().then {
        $0.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    }

    private lazy var leadingStepper = Self.makeStepper().then {
        $0.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    }

    private lazy var bottomStepper = Self.makeStepper().then {
        $0.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    }

    private lazy var trailingStepper = Self.makeStepper().then {
        $0.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    }

    convenience init(title: String?, insets: NSDirectionalEdgeInsets) {
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
            leadingStepper,
            SeparatorView(style: .soft),
            bottomStepper,
            trailingStepper
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
