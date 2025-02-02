//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class SizeInspectorView: BaseView {
    // MARK: - Height

    private lazy var verticalMeasurementView = LengthMeasurementView(axis: .vertical, color: .systemPurple)

    private lazy var verticalMeasurementViewCenterXAnchor = verticalMeasurementView.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor)

    // MARK: - Width

    private lazy var horizontalMeasurementView = LengthMeasurementView(axis: .horizontal, color: .systemPurple)

    private lazy var horizontalMeasurementViewCenterYAnchor = horizontalMeasurementView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor)

    // MARK: - Safe Area Layout Guide

    private lazy var safeAreaVerticalMeasurementView = LengthMeasurementView(axis: .vertical, color: .systemGreen)

    private lazy var safeAreaVerticalMeasurementViewCenterXAnchor = safeAreaVerticalMeasurementView.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -100)

    private lazy var safeAreaHorizontalMeasurementView = LengthMeasurementView(axis: .horizontal, color: .systemGreen, name: "Safe Area")

    private lazy var safeAreaHorizontalMeasurementViewCenterYAnchor = safeAreaHorizontalMeasurementView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: -100)

    // MARK: - Readable Guide

    private lazy var readableGuideLeadingHorizontalMeasurementView = LengthMeasurementView(axis: .horizontal, color: .systemYellow, name: " ")

    private lazy var readableGuideTrailingHorizontalMeasurementView = LengthMeasurementView(axis: .horizontal, color: .systemYellow, name: " ")

    private lazy var readableGuideHorizontalMeasurementView = LengthMeasurementView(axis: .horizontal, color: .systemYellow, name: "Readable Content")

    private lazy var readableGuideHorizontalMeasurementViewCenterYAnchor = readableGuideHorizontalMeasurementView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: -200)

    // MARK: - Layout Guide

    private lazy var layoutGuideHorizontalMeasurementView = LengthMeasurementView(axis: .horizontal, color: .cyan, name: "Layout Margins")

    private lazy var layoutGuideHorizontalMeasurementViewCenterYAnchor = layoutGuideHorizontalMeasurementView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: -300)

    private lazy var layoutGuideLeadingHorizontalMeasurementView = LengthMeasurementView(axis: .horizontal, color: .cyan, name: " ")

    private lazy var layoutGuideTrailingHorizontalMeasurementView = LengthMeasurementView(axis: .horizontal, color: .cyan, name: " ")

    // MARK: - Setup

    override func setup() {
        super.setup()

        preservesSuperviewLayoutMargins = true

        addSubview(verticalMeasurementView)
        activateConstraints(
            verticalMeasurementView.topAnchor.constraint(equalTo: topAnchor),
            verticalMeasurementView.bottomAnchor.constraint(equalTo: bottomAnchor),
            verticalMeasurementViewCenterXAnchor
        )

        addSubview(safeAreaVerticalMeasurementView)
        activateConstraints(
            safeAreaVerticalMeasurementView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            safeAreaVerticalMeasurementView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            safeAreaVerticalMeasurementViewCenterXAnchor
        )

        addSubview(safeAreaHorizontalMeasurementView)
        activateConstraints(
            safeAreaHorizontalMeasurementView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            safeAreaHorizontalMeasurementView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            safeAreaHorizontalMeasurementViewCenterYAnchor
        )

        addSubview(horizontalMeasurementView)
        activateConstraints(
            horizontalMeasurementView.leadingAnchor.constraint(equalTo: leadingAnchor),
            horizontalMeasurementView.trailingAnchor.constraint(equalTo: trailingAnchor),
            horizontalMeasurementViewCenterYAnchor
        )

        addSubview(readableGuideHorizontalMeasurementView)
        activateConstraints(
            readableGuideHorizontalMeasurementView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            readableGuideHorizontalMeasurementView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            readableGuideHorizontalMeasurementViewCenterYAnchor
        )

        addSubview(readableGuideLeadingHorizontalMeasurementView)
        activateConstraints(
            readableGuideLeadingHorizontalMeasurementView.leadingAnchor.constraint(equalTo: leadingAnchor),
            readableGuideLeadingHorizontalMeasurementView.trailingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            readableGuideLeadingHorizontalMeasurementView.centerYAnchor.constraint(equalTo: readableGuideHorizontalMeasurementView.centerYAnchor)
        )

        addSubview(readableGuideTrailingHorizontalMeasurementView)
        activateConstraints(
            readableGuideTrailingHorizontalMeasurementView.trailingAnchor.constraint(equalTo: trailingAnchor),
            readableGuideTrailingHorizontalMeasurementView.leadingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            readableGuideTrailingHorizontalMeasurementView.centerYAnchor.constraint(equalTo: readableGuideHorizontalMeasurementView.centerYAnchor)
        )

        addSubview(layoutGuideHorizontalMeasurementView)
        activateConstraints(
            layoutGuideHorizontalMeasurementView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            layoutGuideHorizontalMeasurementView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            layoutGuideHorizontalMeasurementViewCenterYAnchor
        )

        addSubview(layoutGuideLeadingHorizontalMeasurementView)
        activateConstraints(
            layoutGuideLeadingHorizontalMeasurementView.leadingAnchor.constraint(equalTo: leadingAnchor),
            layoutGuideLeadingHorizontalMeasurementView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            layoutGuideLeadingHorizontalMeasurementView.centerYAnchor.constraint(equalTo: layoutGuideHorizontalMeasurementView.centerYAnchor)
        )

        addSubview(layoutGuideTrailingHorizontalMeasurementView)
        activateConstraints(
            layoutGuideTrailingHorizontalMeasurementView.trailingAnchor.constraint(equalTo: trailingAnchor),
            layoutGuideTrailingHorizontalMeasurementView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            layoutGuideTrailingHorizontalMeasurementView.centerYAnchor.constraint(equalTo: layoutGuideHorizontalMeasurementView.centerYAnchor)
        )
    }

    private func activateConstraints(_ constraints: NSLayoutConstraint...) {
        constraints.forEach {
            if let view = $0.firstItem as? UIView {
                view.translatesAutoresizingMaskIntoConstraints = false
            }
            $0.priority = .defaultHigh
            $0.isActive = true
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        verticalMeasurementViewCenterXAnchor.constant = -frame.width * 0.10
        safeAreaVerticalMeasurementViewCenterXAnchor.constant = -frame.width * 0.25

        layoutGuideHorizontalMeasurementViewCenterYAnchor.constant = frame.height * 0.20
        readableGuideHorizontalMeasurementViewCenterYAnchor.constant = frame.height * 0.55
        safeAreaHorizontalMeasurementViewCenterYAnchor.constant = frame.height * 0.75
        horizontalMeasurementViewCenterYAnchor.constant = frame.height * 0.85
    }
}
