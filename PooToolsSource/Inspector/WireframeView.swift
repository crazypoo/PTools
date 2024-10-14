//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class WireframeView: LayerView {
    private lazy var leadingAnchorConstraint = layoutGuideView.leadingAnchor.constraint(equalTo: leadingAnchor).then { $0.isActive = true }

    private lazy var topAnchorConstraint = layoutGuideView.topAnchor.constraint(equalTo: topAnchor).then { $0.isActive = true }

    private lazy var bottomAnchorConstraint = layoutGuideView.bottomAnchor.constraint(equalTo: bottomAnchor).then { $0.isActive = true }

    private lazy var trailingAnchorConstraint = layoutGuideView.trailingAnchor.constraint(equalTo: trailingAnchor).then { $0.isActive = true }

    override init(
        frame: CGRect,
        element: ViewHierarchyElementReference,
        color borderColor: UIColor = Inspector.sharedInstance.configuration.colorStyle.wireframeLayerColor,
        border borderWidth: CGFloat = Inspector.sharedInstance.appearance.wireframeLayerBorderWidth
    ) {
        super.init(frame: frame, element: element, color: borderColor, border: borderWidth)

        isUserInteractionEnabled = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var layoutGuideView = UIView().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.layer.borderColor = borderColor?.cgColor
        $0.layer.borderWidth = borderWidth
        $0.alpha = 1 / 4
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        guard superview != nil else {
            layoutGuideView.removeFromSuperview()
            return
        }

        contentView.installView(layoutGuideView)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        guard case .touches = event?.type else { return }

        delegate?.layerView(
            self,
            didSelect: element,
            withAction: .layer(
                action: element.containsVisibleHighlightViews ? .hideHighlight : .showHighlight
            )
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let superview = superview else {
            layoutGuideView.removeFromSuperview()
            return
        }

        leadingAnchorConstraint.constant = superview.layoutMarginsGuide.layoutFrame.minX
        topAnchorConstraint.constant = superview.layoutMarginsGuide.layoutFrame.minY
        bottomAnchorConstraint.constant = superview.layoutMarginsGuide.layoutFrame.maxY - superview.bounds.maxY
        trailingAnchorConstraint.constant = superview.layoutMarginsGuide.layoutFrame.maxX - superview.bounds.maxX
    }
}
