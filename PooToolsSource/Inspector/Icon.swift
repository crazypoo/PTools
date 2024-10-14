//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class Icon: BaseView {
    let glpyh: Glyph

//    var size: CGSize {
//        didSet {
//            widthConstraint.constant = size.width
//            heightConstraint.constant = size.height
//        }
//    }

    private lazy var widthConstraint_inspector = widthAnchor.constraint(equalToConstant: size.width)

    private lazy var heightConstraint_inspector = heightAnchor.constraint(equalToConstant: size.height)

    init(_ glpyh: Glyph, color: UIColor = Inspector.sharedInstance.configuration.colorStyle.textColor, size: CGSize = CGSize(width: 16, height: 16)) {
        self.glpyh = glpyh

        super.init(frame: CGRect(origin: .zero, size: size))
        self.size = size

        tintColor = color
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var description: String {
        "\(className) '\(glpyh)'\nsize: \(size) \ncolor: \(String(describing: tintColor))"
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        setNeedsDisplay()
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
