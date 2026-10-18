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

final class WireframeView: LayerView {
    private var leadingConstraint: PTLayoutConstraint?
    private var topConstraint: PTLayoutConstraint?
    private var bottomConstraint: PTLayoutConstraint?
    private var trailingConstraint: PTLayoutConstraint?

    @MainActor
    override init(
        frame: CGRect,
        element: ViewHierarchyElementReference,
        color borderColor: UIColor? = nil,
        border borderWidth: CGFloat? = nil
    ) {
        super.init(frame: frame, element: element, color: borderColor ?? Inspector.sharedInstance.configuration.colorStyle.wireframeLayerColor, border: borderWidth ?? Inspector.sharedInstance.appearance.wireframeLayerBorderWidth)

        isUserInteractionEnabled = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var layoutGuideView = UIView().then {
        $0.layer.borderColor = borderColor?.cgColor
        $0.layer.borderWidth = borderWidth
        $0.alpha = 1 / 4
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        guard superview != nil else {
            layoutGuideView.ptLayout.removeConstraints()
            layoutGuideView.removeFromSuperview()
            return
        }

        guard layoutGuideView.superview == nil else { return }

        contentView.addSubview(layoutGuideView)
        layoutGuideView.ptLayout.makeConstraints { make in
            leadingConstraint = make.leading.equalToSuperview().constraint
            topConstraint = make.top.equalToSuperview().constraint
            bottomConstraint = make.bottom.equalToSuperview().constraint
            trailingConstraint = make.trailing.equalToSuperview().constraint
        }
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

        leadingConstraint?.update(offset: superview.layoutMarginsGuide.layoutFrame.minX)
        topConstraint?.update(offset: superview.layoutMarginsGuide.layoutFrame.minY)
        bottomConstraint?.update(offset: superview.layoutMarginsGuide.layoutFrame.maxY - superview.bounds.maxY)
        trailingConstraint?.update(offset: superview.layoutMarginsGuide.layoutFrame.maxX - superview.bounds.maxX)
    }
}
