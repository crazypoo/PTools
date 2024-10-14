//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class TextFieldControl: BaseFormControl {
    private let defaultFont: UIFont = .preferredFont(forTextStyle: .footnote)

    // MARK: - Properties

    private lazy var textField = UITextField().then {
        $0.textColor = colorStyle.textColor
        $0.font = defaultFont
        $0.borderStyle = .none
        $0.delegate = self
        $0.addTarget(self, action: #selector(editText), for: .editingChanged)
    }

    private(set) lazy var accessoryControl = AccessoryControl().then {
        $0.contentView.addArrangedSubview(textField)
        $0.addInteraction(UIContextMenuInteraction(delegate: self))
    }

    override var isEnabled: Bool {
        didSet {
            textField.isEnabled = isEnabled
            accessoryControl.isEnabled = isEnabled
        }
    }

    // MARK: - Init

    var value: String? {
        get {
            textField.text
        }
        set {
            textField.text = newValue
        }
    }

    var placeholder: String? {
        get {
            textField.placeholder
        }
        set {
            guard let placeholder = newValue else {
                textField.placeholder = nil
                return
            }
            textField.attributedPlaceholder = NSAttributedString(
                placeholder,
                .font(textField.font ?? defaultFont),
                .foregroundColor(colorStyle.tertiaryTextColor)
            )
        }
    }

    init(title: String?, value: String?, placeholder: String?) {
        super.init(title: title)

        self.value = value
        self.placeholder = placeholder
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setup() {
        super.setup()

        axis = .vertical
        contentView.addArrangedSubview(accessoryControl)
    }

    override var canBecomeFirstResponder: Bool {
        textField.canBecomeFirstResponder
    }

    override var canBecomeFocused: Bool {
        textField.canBecomeFocused
    }

    override func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
    }

    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                         configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration?
    {
        let localPoint = convert(location, to: accessoryControl)

        guard accessoryControl.point(inside: localPoint, with: .none) else { return nil }

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
                            UIPasteboard.general.string = self.textField.text
                        }
                    )
                ]
            )
        }
    }
}

private extension TextFieldControl {
    @objc
    func editText() {
        sendActions(for: .valueChanged)
    }
}

extension TextFieldControl: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        return true
    }
}
