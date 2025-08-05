//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class IconButton: BaseControl {
    typealias Action = PTActionTask

    enum Style: ElementInspectorAppearanceProviding {
        case rounded
        case plain

        fileprivate func cornerRadius(for view: UIView) -> CGFloat {
            switch self {
            case .rounded:
                return view.frame.height / 2
            case .plain:
                return .zero
            }
        }

        fileprivate var layoutMargins: NSDirectionalEdgeInsets {
            .init(insets: elementInspectorAppearance.verticalMargins / 3)
        }
    }

    let style: Style

    let icon: Icon

    var actionHandler: Action?

    init(_ glyph: Icon.Glyph,
         style: Style = .rounded,
         size: CGSize = .init(16),
         tintColor: UIColor = Inspector.sharedInstance.configuration.colorStyle.textColor,
         actionHandler: Action? = nil) {
        icon = Icon(glyph, color: tintColor, size: size)
        self.style = style
        self.actionHandler = actionHandler
        super.init(frame: .zero)
        self.tintColor = tintColor
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()

        applyStyle()
    }

    private func applyStyle() {
        switch style {
        case .plain:
            icon.tintColor = tintColor
            backgroundColor = .clear
        case .rounded:
            icon.tintColor = tintColor
            backgroundColor = colorStyle.accessoryControlBackgroundColor
        }

        clipsToBounds = true
    }

    override func setup() {
        super.setup()

        enableRasterization()

        contentView.axis = .vertical
        contentView.addArrangedSubview(icon)
        contentView.directionalLayoutMargins = style.layoutMargins

        addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)

        applyStyle()
    }

    @objc private func touchUpInside() {
        actionHandler?()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = style.cornerRadius(for: self)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        animate(.in)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        animate(.out)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        animate(.out)
    }
}
