//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class ToogleCollapseButton: BaseControl {
    private lazy var imageView = UIImageView(image: .expandSymbol, highlightedImage: .collapseSymbol).then {
        $0.widthAnchor.constraint(equalToConstant: CGSize.regularIconSize.width).isActive = true
        $0.heightAnchor.constraint(equalToConstant: CGSize.regularIconSize.height).isActive = true
    }

    private lazy var activityIndicatorView = UIActivityIndicatorView().then {
        installView($0, .centerXY)
        $0.color = colorStyle.tertiaryTextColor
        $0.hidesWhenStopped = true
    }

    private func startLoading() {
        isEnabled = false
        imageView.alpha = 0
        activityIndicatorView.startAnimating()
    }

    private func stopLoading() {
        isEnabled = true
        imageView.alpha = 1
        activityIndicatorView.stopAnimating()
    }

    var collapseState: ElementInspectorPanelListState? {
        didSet {
            switch collapseState {
            case .none:
                startLoading()

            case .allExpanded:
                stopLoading()
                isSelected = true

            case .allCollapsed:
                stopLoading()
                isSelected = false

            case .mixed:
                stopLoading()
                isSelected = false

            case .firstExpanded:
                stopLoading()
                isSelected = false
            }
        }
    }

    override func setup() {
        super.setup()

        tintColor = colorStyle.secondaryTextColor

        installView(imageView)

        updateViews()

        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.defaultLow, for: .vertical)
    }

    private func updateViews() {
        if state == .selected {
            imageView.isHighlighted = true
            imageView.transform = .init(rotationAngle: .pi / 2)
        }
        else {
            imageView.isHighlighted = false
            imageView.transform = .identity
        }
    }

    override func stateDidChange(from oldState: UIControl.State, to newState: UIControl.State) {
        animate(withDuration: .long) {
            self.updateViews()
        }
    }
}
