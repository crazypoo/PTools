//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class Icon: BaseView {
    let glpyh: Glyph

    // English: Store the requested icon size before BaseView performs setup.
    // Español: Guarda el tamaño solicitado antes de que BaseView ejecute setup.
    // 中文：在 BaseView 执行 setup 前保存请求的图标尺寸。
    private let iconSize: CGSize

    private lazy var widthConstraint_inspector = widthAnchor.constraint(equalToConstant: iconSize.width)

    private lazy var heightConstraint_inspector = heightAnchor.constraint(equalToConstant: iconSize.height)

    @MainActor init(_ glpyh: Glyph, color: UIColor? = nil, size: CGSize = CGSize(width: 16, height: 16)) {
        self.glpyh = glpyh
        self.iconSize = size

        super.init(frame: CGRect(origin: .zero, size: size))

        tintColor = color ?? Inspector.sharedInstance.configuration.colorStyle.textColor
        setupTraitObservation()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupTraitObservation() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: UIView, previousTraitCollection: UITraitCollection) in
            // 只有当深浅色真正发生切换时，才会触发这个闭包
            view.setNeedsDisplay()
        }
    }

    override var description: String {
        "\(className) '\(glpyh)'"
    }

    override func setup() {
        super.setup()

        isOpaque = false

        isUserInteractionEnabled = false

        translatesAutoresizingMaskIntoConstraints = false

        widthConstraint_inspector.isActive = true

        heightConstraint_inspector.isActive = true
    }

    override func draw(_ rect: CGRect) {
        glpyh.draw(color: tintColor, frame: bounds, resizing: .aspectFit)
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()

        setNeedsDisplay()
    }
}

extension Icon {
    static func chevronDownIcon() -> Icon {
        Icon(
            .chevronDown,
            color: Inspector.sharedInstance.configuration.colorStyle.textColor.withAlphaComponent(0.7),
            size: CGSize(16)
        )
    }
}
