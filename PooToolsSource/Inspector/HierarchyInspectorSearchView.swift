//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class HierarchyInspectorSearchView: BaseView {
    private lazy var searchIcon = Icon(
        .search,
        color: colorStyle.textColor.withAlphaComponent(0.73),
        size: CGSize(19)
    )

    private(set) lazy var textField = KeyPressTextField(
        .clearButtonMode(.always),
        .textStyle(.title2),
        .textColor(colorStyle.textColor),
        .attributedPlaceholder(
            NSAttributedString(
                Texts.searchViews,
                .foregroundColor(colorStyle.secondaryTextColor),
                .textStyle(.title2)
            )
        )
    )

    private(set) lazy var separatorView = SeparatorView(style: .medium, thickness: UIScreen.main.scale)

    override var canBecomeFirstResponder: Bool {
        textField.canBecomeFirstResponder
    }

    override var isFirstResponder: Bool {
        textField.isFirstResponder
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
    }

    override func setup() {
        super.setup()

        contentView.axis = .horizontal
        contentView.alignment = .center
        contentView.directionalLayoutMargins = elementInspectorAppearance.directionalInsets.with(trailing: elementInspectorAppearance.verticalMargins)
        contentView.spacing = elementInspectorAppearance.verticalMargins

        contentView.addArrangedSubview(searchIcon)
        contentView.addArrangedSubview(textField)

        installView(separatorView, .spacing(leading: .zero, bottom: .zero, trailing: .zero))
    }
}

// MARK: - APIs

extension HierarchyInspectorSearchView {
    var query: String? {
        textField.text
    }

    var hasText: Bool {
        textField.hasText
    }

    func insertText(_ text: String) {
        textField.insertText(text)
    }

    func deleteBackward() {
        textField.deleteBackward()
    }
}

extension HierarchyInspectorSearchView {
    final class KeyPressTextField: UITextField {
        var keyPressHandler: ((UIKey?) -> Bool)?

        override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            guard let keyPressHandler = keyPressHandler else {
                return super.pressesBegan(presses, with: event)
            }

            for press in presses where keyPressHandler(press.key) == false {
                resignFirstResponder()
                return
            }
            super.pressesBegan(presses, with: event)
        }
    }
}
