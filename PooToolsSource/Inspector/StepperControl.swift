//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class StepperControl: BaseFormControl {
    // MARK: - Properties

    override var isEnabled: Bool {
        didSet {
            stepperControl.isEnabled = isEnabled
            stepperControl.isHidden = !isEnabled
            updateState()
        }
    }

    var value: Double {
        get {
            stepperControl.value
        }
        set {
            stepperControl.value = newValue
            updateCounterLabel()
        }
    }

    var range: ClosedRange<Double> {
        get {
            stepperControl.minimumValue...stepperControl.maximumValue
        }
        set {
            stepperControl.minimumValue = newValue.lowerBound
            stepperControl.maximumValue = newValue.upperBound
        }
    }

    var stepValue: Double {
        get {
            stepperControl.stepValue
        }
        set {
            stepperControl.stepValue = newValue
        }
    }

    let isDecimalValue: Bool

    // MARK: - Components

    private lazy var stepperControl = UIStepper().then {
        $0.addTarget(self, action: #selector(step), for: .valueChanged)
    }

    private lazy var counterLabel = UILabel(
        .font(titleLabel.font!.withTraits(.traitMonoSpace)),
        .huggingPriority(.required, for: .horizontal)
    )

    // MARK: - Init

    init(title: String?, value: Double, range: ClosedRange<Double>, stepValue: Double, isDecimalValue: Bool) {
        self.isDecimalValue = isDecimalValue

        super.init(title: title)

        stepperControl.maximumValue = range.upperBound
        stepperControl.minimumValue = range.lowerBound
        stepperControl.stepValue = stepValue
        self.value = value
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setup() {
        super.setup()

        updateState()
        contentView.addArrangedSubviews(counterLabel, stepperControl)
    }

    @objc
    func step() {
        updateCounterLabel()

        sendActions(for: .valueChanged)
    }

    private func updateCounterLabel() {
        counterLabel.text = stepperControl.value.toString()
    }

    private func updateState() {
        stepperControl.alpha = isEnabled ? 1 : 0.5
        counterLabel.textColor = isEnabled ? colorStyle.textColor : colorStyle.secondaryTextColor
    }
}
