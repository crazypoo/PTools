//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

class StepperPairControl<FloatingPoint: BinaryFloatingPoint>: BaseFormControl {
    override var isEnabled: Bool {
        didSet {
            firstStepper.isEnabled = isEnabled
            secondStepper.isEnabled = isEnabled
        }
    }

    var firstSubtitle: String? {
        get { firstStepper.title }
        set { firstStepper.title = newValue }
    }

    var firstValue: FloatingPoint {
        get { FloatingPoint(firstStepper.value) }
        set { firstStepper.value = Double(newValue) }
    }

    var secondSubtitle: String? {
        get { secondStepper.title }
        set { secondStepper.title = newValue }
    }

    var secondValue: FloatingPoint {
        get { FloatingPoint(secondStepper.value) }
        set { secondStepper.value = Double(newValue) }
    }

    var firstRange: ClosedRange<FloatingPoint> {
        get { FloatingPoint(firstStepper.range.lowerBound)...FloatingPoint(firstStepper.range.upperBound) }
        set { firstStepper.range = Double(newValue.lowerBound)...Double(newValue.upperBound) }
    }

    var secondRange: ClosedRange<FloatingPoint> {
        get { FloatingPoint(secondStepper.range.lowerBound)...FloatingPoint(secondStepper.range.upperBound) }
        set { secondStepper.range = Double(newValue.lowerBound)...Double(newValue.upperBound) }
    }

    private lazy var firstStepper = StepperControl(
        title: .none,
        value: .zero,
        range: 0...Double.infinity,
        stepValue: 1,
        isDecimalValue: true
    ).then {
        $0.containerView.directionalLayoutMargins.update(bottom: .zero)
        $0.isShowingSeparator = false
        $0.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    }

    private lazy var secondStepper = StepperControl(
        title: .none,
        value: .zero,
        range: 0...Double.infinity,
        stepValue: 1,
        isDecimalValue: true
    ).then {
        $0.containerView.directionalLayoutMargins.update(top: .zero, bottom: .zero)
        $0.isShowingSeparator = false
        $0.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    }

    init(
        title: String? = nil,
        firstSubtitle: String? = nil,
        firstValue: FloatingPoint = .zero,
        firstRange: ClosedRange<FloatingPoint>,
        secondSubtitle: String? = nil,
        secondValue: FloatingPoint = .zero,
        secondRange: ClosedRange<FloatingPoint>,
        isEnabled: Bool = true,
        frame: CGRect = .zero
    ) {
        super.init(title: title, isEnabled: isEnabled, frame: frame)

        self.firstSubtitle = firstSubtitle
        self.firstRange = firstRange
        self.firstValue = firstValue
        self.secondSubtitle = secondSubtitle
        self.secondRange = secondRange
        self.secondValue = secondValue
    }

    override func setup() {
        super.setup()

        axis = .vertical

        applyTitleSectionStyle()

        contentView.axis = .vertical
        contentView.spacing = elementInspectorAppearance.verticalMargins * 1.5
        contentView.addArrangedSubviews(firstStepper, secondStepper)
    }

    @objc
    private func valueChanged() {
        sendActions(for: .valueChanged)
    }
}
