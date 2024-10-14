//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class LoaderView: LayerViewComponent {
    // MARK: - Components

    private lazy var activityIndicator = UIActivityIndicatorView(style: .large).then {
        $0.color = .white
        $0.hidesWhenStopped = true
        $0.startAnimating()
    }

    private lazy var checkmarkLabel = UILabel(
        .text("✓"),
        .adjustsFontSizeToFitWidth(true),
        .font(.systemFont(ofSize: 32, weight: .semibold)),
        .textColor(.white),
        .textAlignment(.center),
        .viewOptions(.isHidden(true))
    )

    private(set) lazy var highlightView = InspectorHighlightView(
        frame: bounds,
        name: elementName,
        colorScheme: colorScheme,
        element: ViewHierarchyElement(with: self, iconProvider: .default)
    ).then {
        $0.initialTransformation = .identity
        $0.displayMode = .text
        $0.verticalAlignmentOffset = activityIndicator.frame.height * 2 / 3
    }

    let colorScheme: ViewHierarchyColorScheme

    override var accessibilityIdentifier: String? {
        didSet {
            if let name = accessibilityIdentifier {
                highlightView.name = name
            }
        }
    }

    init(colorScheme: ViewHierarchyColorScheme, frame: CGRect = .zero) {
        self.colorScheme = colorScheme
        super.init(frame: frame)
    }

    // MARK: - Setup

    override func setup() {
        super.setup()

        installView(checkmarkLabel, .centerXY)

        installView(activityIndicator, .spacing(all: 8))

        installView(highlightView, .autoResizingMask)

        addInspectorViews()

        checkmarkLabel.widthAnchor.constraint(equalTo: activityIndicator.widthAnchor).isActive = true

        checkmarkLabel.heightAnchor.constraint(equalTo: activityIndicator.heightAnchor).isActive = true
    }

    func addInspectorViews() {
        installView(highlightView, .autoResizingMask)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        backgroundColor = colorScheme.value(for: self)

        highlightView.borderWidth = .zero
        highlightView.borderColor = backgroundColor?.lighter(amount: 0.07)

        layer.cornerRadius = frame.height / .pi
    }

    func done() {
        activityIndicator.stopAnimating()

        checkmarkLabel.isSafelyHidden = false
    }

    func prepareForReuse() {
        activityIndicator.startAnimating()

        checkmarkLabel.isSafelyHidden = true

        alpha = 1
    }
}
