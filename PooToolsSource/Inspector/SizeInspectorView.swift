//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
#if canImport(PToolsConstraintLayout)
import PToolsConstraintLayout
#endif
import SnapKit
#if SWIFT_PACKAGE
import ptools
#endif

final class SizeInspectorView: BaseView {
    // MARK: - Height

    private lazy var verticalMeasurementView = LengthMeasurementView(axis: .vertical, color: .systemPurple)

    private var verticalMeasurementViewCenterXConstraint: PTLayoutConstraint?

    // MARK: - Width

    private lazy var horizontalMeasurementView = LengthMeasurementView(axis: .horizontal, color: .systemPurple)

    private var horizontalMeasurementViewCenterYConstraint: PTLayoutConstraint?

    // MARK: - Safe Area Layout Guide

    private lazy var safeAreaVerticalMeasurementView = LengthMeasurementView(axis: .vertical, color: .systemGreen)

    private var safeAreaVerticalMeasurementViewCenterXConstraint: PTLayoutConstraint?

    private lazy var safeAreaHorizontalMeasurementView = LengthMeasurementView(axis: .horizontal, color: .systemGreen, name: "Safe Area")

    private var safeAreaHorizontalMeasurementViewCenterYConstraint: PTLayoutConstraint?

    // MARK: - Readable Guide

    private lazy var readableGuideLeadingHorizontalMeasurementView = LengthMeasurementView(axis: .horizontal, color: .systemYellow, name: " ")

    private lazy var readableGuideTrailingHorizontalMeasurementView = LengthMeasurementView(axis: .horizontal, color: .systemYellow, name: " ")

    private lazy var readableGuideHorizontalMeasurementView = LengthMeasurementView(axis: .horizontal, color: .systemYellow, name: "Readable Content")

    private var readableGuideHorizontalMeasurementViewCenterYConstraint: PTLayoutConstraint?

    // MARK: - Layout Guide

    private lazy var layoutGuideHorizontalMeasurementView = LengthMeasurementView(axis: .horizontal, color: .cyan, name: "Layout Margins")

    private var layoutGuideHorizontalMeasurementViewCenterYConstraint: PTLayoutConstraint?

    private lazy var layoutGuideLeadingHorizontalMeasurementView = LengthMeasurementView(axis: .horizontal, color: .cyan, name: " ")

    private lazy var layoutGuideTrailingHorizontalMeasurementView = LengthMeasurementView(axis: .horizontal, color: .cyan, name: " ")

    // MARK: - Setup

    override func setup() {
        super.setup()

        preservesSuperviewLayoutMargins = true

        addSubview(verticalMeasurementView)
        verticalMeasurementView.ptLayout.makeConstraints { make in
            make.top.bottom.equalToSuperview().priority(UILayoutPriority.defaultHigh.rawValue)
            verticalMeasurementViewCenterXConstraint = make.centerX.equalTo(safeAreaLayoutGuide.ptLayout.trailing).priority(UILayoutPriority.defaultHigh.rawValue).constraint
        }

        addSubview(safeAreaVerticalMeasurementView)
        safeAreaVerticalMeasurementView.ptLayout.makeConstraints { make in
            make.top.bottom.equalTo(safeAreaLayoutGuide).priority(UILayoutPriority.defaultHigh.rawValue)
            safeAreaVerticalMeasurementViewCenterXConstraint = make.centerX.equalTo(safeAreaLayoutGuide.ptLayout.trailing).offset(-100).priority(UILayoutPriority.defaultHigh.rawValue).constraint
        }

        addSubview(safeAreaHorizontalMeasurementView)
        safeAreaHorizontalMeasurementView.ptLayout.makeConstraints { make in
            make.leading.trailing.equalTo(safeAreaLayoutGuide).priority(UILayoutPriority.defaultHigh.rawValue)
            safeAreaHorizontalMeasurementViewCenterYConstraint = make.centerY.equalTo(safeAreaLayoutGuide.ptLayout.top).offset(-100).priority(UILayoutPriority.defaultHigh.rawValue).constraint
        }

        addSubview(horizontalMeasurementView)
        horizontalMeasurementView.ptLayout.makeConstraints { make in
            make.leading.trailing.equalToSuperview().priority(UILayoutPriority.defaultHigh.rawValue)
            horizontalMeasurementViewCenterYConstraint = make.centerY.equalTo(safeAreaLayoutGuide.ptLayout.top).priority(UILayoutPriority.defaultHigh.rawValue).constraint
        }

        addSubview(readableGuideHorizontalMeasurementView)
        readableGuideHorizontalMeasurementView.ptLayout.makeConstraints { make in
            make.leading.trailing.equalTo(readableContentGuide).priority(UILayoutPriority.defaultHigh.rawValue)
            readableGuideHorizontalMeasurementViewCenterYConstraint = make.centerY.equalTo(safeAreaLayoutGuide.ptLayout.top).offset(-200).priority(UILayoutPriority.defaultHigh.rawValue).constraint
        }

        addSubview(readableGuideLeadingHorizontalMeasurementView)
        readableGuideLeadingHorizontalMeasurementView.ptLayout.makeConstraints { make in
            make.leading.equalToSuperview().priority(UILayoutPriority.defaultHigh.rawValue)
            make.trailing.equalTo(readableContentGuide.ptLayout.leading).priority(UILayoutPriority.defaultHigh.rawValue)
            make.centerY.equalTo(readableGuideHorizontalMeasurementView.ptLayout.centerY).priority(UILayoutPriority.defaultHigh.rawValue)
        }

        addSubview(readableGuideTrailingHorizontalMeasurementView)
        readableGuideTrailingHorizontalMeasurementView.ptLayout.makeConstraints { make in
            make.trailing.equalToSuperview().priority(UILayoutPriority.defaultHigh.rawValue)
            make.leading.equalTo(readableContentGuide.ptLayout.trailing).priority(UILayoutPriority.defaultHigh.rawValue)
            make.centerY.equalTo(readableGuideHorizontalMeasurementView.ptLayout.centerY).priority(UILayoutPriority.defaultHigh.rawValue)
        }

        addSubview(layoutGuideHorizontalMeasurementView)
        layoutGuideHorizontalMeasurementView.ptLayout.makeConstraints { make in
            make.leading.trailing.equalTo(layoutMarginsGuide).priority(UILayoutPriority.defaultHigh.rawValue)
            layoutGuideHorizontalMeasurementViewCenterYConstraint = make.centerY.equalTo(safeAreaLayoutGuide.ptLayout.top).offset(-300).priority(UILayoutPriority.defaultHigh.rawValue).constraint
        }

        addSubview(layoutGuideLeadingHorizontalMeasurementView)
        layoutGuideLeadingHorizontalMeasurementView.ptLayout.makeConstraints { make in
            make.leading.equalToSuperview().priority(UILayoutPriority.defaultHigh.rawValue)
            make.trailing.equalTo(layoutMarginsGuide.ptLayout.leading).priority(UILayoutPriority.defaultHigh.rawValue)
            make.centerY.equalTo(layoutGuideHorizontalMeasurementView.ptLayout.centerY).priority(UILayoutPriority.defaultHigh.rawValue)
        }

        addSubview(layoutGuideTrailingHorizontalMeasurementView)
        layoutGuideTrailingHorizontalMeasurementView.ptLayout.makeConstraints { make in
            make.trailing.equalToSuperview().priority(UILayoutPriority.defaultHigh.rawValue)
            make.leading.equalTo(layoutMarginsGuide.ptLayout.trailing).priority(UILayoutPriority.defaultHigh.rawValue)
            make.centerY.equalTo(layoutGuideHorizontalMeasurementView.ptLayout.centerY).priority(UILayoutPriority.defaultHigh.rawValue)
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
