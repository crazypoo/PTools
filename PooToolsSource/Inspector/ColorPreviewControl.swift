//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

protocol ColorPreviewControlDelegate: AnyObject {
    func colorPreviewControlDidTap(_ colorPreviewControl: ColorPreviewControl)
}

final class ColorPreviewControl: BaseFormControl {
    // MARK: - Properties

    weak var delegate: ColorPreviewControlDelegate?

    var selectedColor: UIColor? {
        didSet {
            updateViews()
        }
    }

    func updateSelectedColor(_ color: UIColor?) {
        selectedColor = color

        sendActions(for: .valueChanged)
    }

    override var isEnabled: Bool {
        didSet {
            tapGestureRecognizer.isEnabled = isEnabled
            accessoryControl.isEnabled = isEnabled
        }
    }

    private lazy var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapColor))

    private lazy var colorDisplayControl = ColorDisplayControl().then {
        $0.color = selectedColor

        $0.heightAnchor.constraint(equalToConstant: 20).isActive = true
        $0.widthAnchor.constraint(equalTo: $0.heightAnchor, multiplier: 2).isActive = true
    }

    private lazy var colorDisplayLabel = UILabel(
        .textStyle(.footnote),
        .textColor(colorStyle.textColor),
        .huggingPriority(.defaultHigh, for: .horizontal)
    )

    private(set) lazy var accessoryControl = AccessoryControl().then {
        $0.addGestureRecognizer(tapGestureRecognizer)
        $0.contentView.addArrangedSubview(colorDisplayLabel)
        $0.contentView.addArrangedSubview(colorDisplayControl)
        $0.addInteraction(UIContextMenuInteraction(delegate: self))
    }

    let emptyTitle: String?

    // MARK: - Init

    init(title: String?, emptyTitle: String?, color: UIColor?) {
        self.emptyTitle = emptyTitle
        selectedColor = color

        super.init(title: title)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setup() {
        super.setup()

        contentView.addArrangedSubview(accessoryControl)

        if #available(iOS 14.0, *) {
            colorDisplayControl.isEnabled = true
        }
        else {
            accessoryControl.isUserInteractionEnabled = false
            colorDisplayLabel.textColor = colorStyle.tintColor
            accessoryControl.backgroundColor = nil
            var margins = accessoryControl.contentView.directionalLayoutMargins
            margins.leading = 0
            margins.trailing = 0

            accessoryControl.contentView.directionalLayoutMargins = margins
        }

        updateViews()
    }

    private func updateViews() {
        colorDisplayControl.color = selectedColor

        colorDisplayLabel.text = selectedColor?.hex ?? emptyTitle
    }

    @objc private func tapColor() {
        delegate?.colorPreviewControlDidTap(self)
    }

    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                         configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration?
    {
        let localPoint = convert(location, to: colorDisplayControl)

        guard colorDisplayControl.point(inside: localPoint, with: .none) else { return nil }

        return .init(
            identifier: nil,
            previewProvider: nil
        ) { _ in
            UIMenu(
                title: "",
                image: nil,
                identifier: nil,
                children: [
                    UIAction(
                        title: "Copy",
                        image: .copySymbol,
                        identifier: nil,
                        discoverabilityTitle: "Copy",
                        handler: { [weak self] _ in
                            guard let self = self else { return }
                            UIPasteboard.general.string = self.colorDisplayLabel.text
                        }
                    )
                ]
            )
        }
    }
}

extension ColorPreviewControl {
    final class ColorDisplayControl: BaseControl {
        var color: UIColor? {
            didSet {
                colorBackgroundView.backgroundColor = color
            }
        }

        private lazy var colorBackgroundView = UIView(
            .backgroundColor(nil),
            .isUserInteractionEnabled(false)
        )

        override func setup() {
            super.setup()

            backgroundColor = colorStyle.tertiaryTextColor

            layer.cornerRadius = 5

            layer.masksToBounds = true

            installView(colorBackgroundView)
        }

        override func draw(_ rect: CGRect) {
            IconKit.drawColorGrid(frame: bounds, resizing: .aspectFill)
        }
    }
}
