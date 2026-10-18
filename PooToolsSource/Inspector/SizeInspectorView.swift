//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
#if SWIFT_PACKAGE
import ptools
#endif

final class SizeInspectorView: BaseView {
    // MARK: - Height

    private lazy var verticalMeasurementView = LengthMeasurementView(axis: .vertical, color: .systemPurple)

    private var verticalMeasurementViewCenterXConstraint: Constraint?

    // MARK: - Width

    private lazy var horizontalMeasurementView = LengthMeasurementView(axis: .horizontal, color: .systemPurple)

    private var horizontalMeasurementViewCenterYConstraint: Constraint?

    // MARK: - Safe Area Layout Guide

    private lazy var safeAreaVerticalMeasurementView = LengthMeasurementView(axis: .vertical, color: .systemGreen)

    private var safeAreaVerticalMeasurementViewCenterXConstraint: Constraint?

    private lazy var safeAreaHorizontalMeasurementView = LengthMeasurementView(axis: .horizontal, color: .systemGreen, name: "Safe Area")

    private var safeAreaHorizontalMeasurementViewCenterYConstraint: Constraint?

    // MARK: - Readable Guide

    private lazy var readableGuideLeadingHorizontalMeasurementView = LengthMeasurementView(axis: .horizontal, color: .systemYellow, name: " ")

    private lazy var readableGuideTrailingHorizontalMeasurementView = LengthMeasurementView(axis: .horizontal, color: .systemYellow, name: " ")

    private lazy var readableGuideHorizontalMeasurementView = LengthMeasurementView(axis: .horizontal, color: .systemYellow, name: "Readable Content")

    private var readableGuideHorizontalMeasurementViewCenterYConstraint: Constraint?

    // MARK: - Layout Guide

    private lazy var layoutGuideHorizontalMeasurementView = LengthMeasurementView(axis: .horizontal, color: .cyan, name: "Layout Margins")

    private var layoutGuideHorizontalMeasurementViewCenterYConstraint: Constraint?

    private lazy var layoutGuideLeadingHorizontalMeasurementView = LengthMeasurementView(axis: .horizontal, color: .cyan, name: " ")

    private lazy var layoutGuideTrailingHorizontalMeasurementView = LengthMeasurementView(axis: .horizontal, color: .cyan, name: " ")

    // MARK: - Setup

    override func setup() {
        super.setup()

        preservesSuperviewLayoutMargins = true

        addSubview(verticalMeasurementView)
        verticalMeasurementView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().priority(UILayoutPriority.defaultHigh.rawValue)
            verticalMeasurementViewCenterXConstraint = make.centerX.equalTo(safeAreaLayoutGuide.snp.trailing).priority(UILayoutPriority.defaultHigh.rawValue).constraint
        }

        addSubview(safeAreaVerticalMeasurementView)
        safeAreaVerticalMeasurementView.snp.makeConstraints { make in
            make.top.bottom.equalTo(safeAreaLayoutGuide).priority(UILayoutPriority.defaultHigh.rawValue)
            safeAreaVerticalMeasurementViewCenterXConstraint = make.centerX.equalTo(safeAreaLayoutGuide.snp.trailing).offset(-100).priority(UILayoutPriority.defaultHigh.rawValue).constraint
        }

        addSubview(safeAreaHorizontalMeasurementView)
        safeAreaHorizontalMeasurementView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(safeAreaLayoutGuide).priority(UILayoutPriority.defaultHigh.rawValue)
            safeAreaHorizontalMeasurementViewCenterYConstraint = make.centerY.equalTo(safeAreaLayoutGuide.snp.top).offset(-100).priority(UILayoutPriority.defaultHigh.rawValue).constraint
        }

        addSubview(horizontalMeasurementView)
        horizontalMeasurementView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().priority(UILayoutPriority.defaultHigh.rawValue)
            horizontalMeasurementViewCenterYConstraint = make.centerY.equalTo(safeAreaLayoutGuide.snp.top).priority(UILayoutPriority.defaultHigh.rawValue).constraint
        }

        addSubview(readableGuideHorizontalMeasurementView)
        readableGuideHorizontalMeasurementView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(readableContentGuide).priority(UILayoutPriority.defaultHigh.rawValue)
            readableGuideHorizontalMeasurementViewCenterYConstraint = make.centerY.equalTo(safeAreaLayoutGuide.snp.top).offset(-200).priority(UILayoutPriority.defaultHigh.rawValue).constraint
        }

        addSubview(readableGuideLeadingHorizontalMeasurementView)
        readableGuideLeadingHorizontalMeasurementView.snp.makeConstraints { make in
            make.leading.equalToSuperview().priority(UILayoutPriority.defaultHigh.rawValue)
            make.trailing.equalTo(readableContentGuide.snp.leading).priority(UILayoutPriority.defaultHigh.rawValue)
            make.centerY.equalTo(readableGuideHorizontalMeasurementView.snp.centerY).priority(UILayoutPriority.defaultHigh.rawValue)
        }

        addSubview(readableGuideTrailingHorizontalMeasurementView)
        readableGuideTrailingHorizontalMeasurementView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().priority(UILayoutPriority.defaultHigh.rawValue)
            make.leading.equalTo(readableContentGuide.snp.trailing).priority(UILayoutPriority.defaultHigh.rawValue)
            make.centerY.equalTo(readableGuideHorizontalMeasurementView.snp.centerY).priority(UILayoutPriority.defaultHigh.rawValue)
        }

        addSubview(layoutGuideHorizontalMeasurementView)
        layoutGuideHorizontalMeasurementView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(layoutMarginsGuide).priority(UILayoutPriority.defaultHigh.rawValue)
            layoutGuideHorizontalMeasurementViewCenterYConstraint = make.centerY.equalTo(safeAreaLayoutGuide.snp.top).offset(-300).priority(UILayoutPriority.defaultHigh.rawValue).constraint
        }

        addSubview(layoutGuideLeadingHorizontalMeasurementView)
        layoutGuideLeadingHorizontalMeasurementView.snp.makeConstraints { make in
            make.leading.equalToSuperview().priority(UILayoutPriority.defaultHigh.rawValue)
            make.trailing.equalTo(layoutMarginsGuide.snp.leading).priority(UILayoutPriority.defaultHigh.rawValue)
            make.centerY.equalTo(layoutGuideHorizontalMeasurementView.snp.centerY).priority(UILayoutPriority.defaultHigh.rawValue)
        }

        addSubview(layoutGuideTrailingHorizontalMeasurementView)
        layoutGuideTrailingHorizontalMeasurementView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().priority(UILayoutPriority.defaultHigh.rawValue)
            make.leading.equalTo(layoutMarginsGuide.snp.trailing).priority(UILayoutPriority.defaultHigh.rawValue)
            make.centerY.equalTo(layoutGuideHorizontalMeasurementView.snp.centerY).priority(UILayoutPriority.defaultHigh.rawValue)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        verticalMeasurementViewCenterXConstraint?.update(offset: -frame.width * 0.10)
        safeAreaVerticalMeasurementViewCenterXConstraint?.update(offset: -frame.width * 0.25)

        layoutGuideHorizontalMeasurementViewCenterYConstraint?.update(offset: frame.height * 0.20)
        readableGuideHorizontalMeasurementViewCenterYConstraint?.update(offset: frame.height * 0.55)
        safeAreaHorizontalMeasurementViewCenterYConstraint?.update(offset: frame.height * 0.75)
        horizontalMeasurementViewCenterYConstraint?.update(offset: frame.height * 0.85)
    }
}
