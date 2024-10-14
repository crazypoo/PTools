//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class TextViewControl: BaseFormControl {
    // MARK: - Properties

    private lazy var textView = UITextView(
        .backgroundColor(nil),
        .isScrollEnabled(false),
        .textColor(colorStyle.textColor),
        .textStyle(.footnote),
        .tintColor(colorStyle.tintColor),
        .delegate(self)
    ).then {
        $0.isSelectable = true

        let padding = $0.textContainer.lineFragmentPadding

        $0.textContainerInset = UIEdgeInsets(
            top: padding,
            left: padding * -1,
            bottom: padding,
            right: padding * -1
        )
    }

    private lazy var placeholderLabel = UILabel(
        .font(textView.font!),
        .numberOfLines(.zero),
        .textColor(colorStyle.tertiaryTextColor)
    )

    private(set) lazy var accessoryControl = AccessoryControl().then {
        $0.animateOnTouch = false
        $0.contentView.addArrangedSubview(textView)
        $0.addInteraction(UIContextMenuInteraction(delegate: self))
    }

    override var isEnabled: Bool {
        get { true }
        set {
            textView.isEditable = newValue
        }
    }

    // MARK: - Init

    var value: String? {
        didSet {
            guard value != textView.text else {
                return
            }

            updateViews()
        }
    }

    var placeholder: String? {
        didSet {
            updateViews()
        }
    }

    init(title: String?, value: String?, placeholder: String?) {
        self.value = value
        self.placeholder = placeholder

        super.init(title: title)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setup() {
        super.setup()

        axis = .vertical

        contentView.addArrangedSubview(accessoryControl)

        textView.installView(
            placeholderLabel,
            .spacing(
                top: textView.textContainerInset.top,
                leading: .zero,
                bottom: textView.textContainerInset.bottom,
                trailing: .zero
            )
        )

        updateViews()
    }

    override var tintColor: UIColor! {
        didSet {
            textView.tintColor = tintColor
        }
    }

    private let aspectRatio: CGFloat = 3 / 5

    private lazy var textViewHeightConstraint = textView.heightAnchor.constraint(equalTo: textView.widthAnchor, multiplier: aspectRatio)

    private var isScrollEnabled: Bool = false {
        didSet {
            textViewHeightConstraint.isActive = isScrollEnabled
            textView.isScrollEnabled = isScrollEnabled
        }
    }

    func updateViews() {
        placeholderLabel.text = placeholder
        placeholderLabel.isHidden = placeholder.isNilOrEmpty || !value.isNilOrEmpty

        textView.text = value
        textView.textContainer.maximumNumberOfLines = 10

        isScrollEnabled = false // hasLongText
        accessoryControl.directionalLayoutMargins = /*! hasLongText ? .zero : */ .init(horizontal: .zero, vertical: elementInspectorAppearance.verticalMargins)
    }

    override var canBecomeFirstResponder: Bool {
        textView.canBecomeFirstResponder
    }

    override var canBecomeFocused: Bool {
        textView.canBecomeFocused
    }

    override func becomeFirstResponder() -> Bool {
        textView.becomeFirstResponder()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        placeholderLabel.preferredMaxLayoutWidth = placeholderLabel.frame.width
    }

    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                         configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration?
    {
        let localPoint = convert(location, to: accessoryControl)

        guard accessoryControl.point(inside: localPoint, with: nil) else { return nil }

        var actions = [UIMenuElement]()

        if let range = textView.selectedTextRange {
            let copySelectionAction = UIAction(
                title: "Copy Selection",
                image: .copySymbol,
                identifier: nil,
                discoverabilityTitle: "Copy Selection",
                handler: { [weak self] _ in
                    guard let self = self else { return }
                    UIPasteboard.general.string = self.textView.text(in: range)
                }
            )
            actions.append(copySelectionAction)
        }

        let copyAllAction = UIAction(
            title: "Copy All Content",
            image: .copySymbol,
            identifier: nil,
            discoverabilityTitle: "Copy All Content",
            handler: { [weak self] _ in
                guard let self = self else { return }
                UIPasteboard.general.string = self.textView.text
            }
        )

        actions.append(copyAllAction)

        return .init(
            identifier: nil,
            previewProvider: nil
        ) { _ in
            UIMenu(
                title: "",
                image: nil,
                identifier: nil,
                children: actions
            )
        }
    }
}

// MARK: - Private Actions

private extension TextViewControl {
    @objc
    func editText() {
        guard value != textView.text else {
            return
        }

        value = textView.text
        placeholderLabel.isHidden = !value.isNilOrEmpty

        sendActions(for: .valueChanged)
    }
}

// MARK: - UITextViewDelegate

extension TextViewControl: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        editText()
    }
}
