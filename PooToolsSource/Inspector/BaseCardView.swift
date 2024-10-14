//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

class BaseCardView: BaseView {
    private(set) lazy var containerView = BaseView().then {
        $0.installView(roundedView, priority: .required)
    }

    private(set) lazy var roundedView = BaseView().then {
        $0.layer.borderColor = borderColor?.cgColor
        $0.layer.borderWidth = 0
        $0.installView(contentView, priority: .required)
        $0.layer.cornerRadius = cornerRadius
    }

    private lazy var stackView = UIStackView.vertical(
        .arrangedSubviews(containerView),
        .isLayoutMarginsRelativeArrangement(true),
        .directionalLayoutMargins(margins)
    )

    var margins: NSDirectionalEdgeInsets = .zero {
        didSet {
            stackView.directionalLayoutMargins = margins
        }
    }

    var cornerRadius: CGFloat = .zero {
        didSet {
            roundedView.layer.cornerRadius = cornerRadius
        }
    }

    var contentMargins: NSDirectionalEdgeInsets = .zero {
        didSet {
            contentView.directionalLayoutMargins = contentMargins
        }
    }

    override var backgroundColor: UIColor? {
        get { roundedView.backgroundColor }
        set { roundedView.backgroundColor = newValue }
    }

    var borderColor: UIColor? {
        didSet {
            updateViews()
        }
    }

    var borderWidth: CGFloat {
        get { roundedView.layer.borderWidth }
        set { roundedView.layer.borderWidth = newValue }
    }

    override func setup() {
        super.setup()

        cornerRadius = elementInspectorAppearance.horizontalMargins

        installView(stackView, priority: .required)

        contentView.directionalLayoutMargins = contentMargins

        updateViews()
    }

    private func updateViews() {
        roundedView.layer.borderColor = borderColor?.cgColor
        roundedView.layer.borderWidth = borderWidth
    }
}
