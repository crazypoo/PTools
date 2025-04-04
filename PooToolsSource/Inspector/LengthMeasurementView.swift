//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class LengthMeasurementView: BaseView {
    let axis: NSLayoutConstraint.Axis

    var color: UIColor

    var measurementName: String? {
        didSet {
            nameLabel.text = measurementName
            nameLabel.isHidden = measurementName.isNilOrEmpty
        }
    }

    private lazy var valueLabel = UILabel(
        .textStyle(.caption2),
        .textAlignment(.center),
        .textColor(color)
    )

    private lazy var nameLabel = UILabel(
        .text(measurementName),
        .textStyle(.caption2),
        .textAlignment(.center),
        .textColor(color),
        .viewOptions(.isHidden(measurementName.isNilOrEmpty))
    )

    private lazy var arrowView = ArrowView(
        axis: axis,
        color: color,
        frame: bounds
    )

    private lazy var topAnchorConstraint = contentView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor)

    private lazy var leadingAnchorConstraint = contentView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor)

    init(axis: NSLayoutConstraint.Axis, color: UIColor, name: String? = nil, frame: CGRect = .zero) {
        self.axis = axis
        self.color = color
        measurementName = name

        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setup() {
        super.setup()

        contentView.alignment = .center

        contentView.directionalLayoutMargins = NSDirectionalEdgeInsets(insets: 2)

        contentView.spacing = elementInspectorAppearance.verticalMargins

        contentView.addArrangedSubview(valueLabel)

        contentView.addArrangedSubview(nameLabel)

        contentView.removeFromSuperview()

        installView(arrowView)

        contentView.removeFromSuperview()

        installView(contentView, .centerXY)

        topAnchorConstraint.isActive = true

        leadingAnchorConstraint.isActive = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        switch axis {
        case .vertical:
            valueLabel.text = frame.height.formattedString

        case .horizontal:
            valueLabel.text = frame.width.formattedString

        @unknown default:
            break
        }

        arrowView.gapSize = {
            guard nameLabel.isHidden else {
                return .zero
            }

            return contentView.frame.size

        }()
    }
}

private extension CGFloat {
    private static let numberFormatter = NumberFormatter(
        .numberStyle(.decimal)
    )

    var formattedString: String? {
        Self.numberFormatter.string(from: NSNumber(value: Float(self)))
    }
}
