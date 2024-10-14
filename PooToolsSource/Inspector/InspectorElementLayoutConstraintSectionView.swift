//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class InspectorElementLayoutConstraintSectionView: BaseView {
    var title: String? {
        get { header.title }
        set { header.title = newValue }
    }

    var subtitle: String? {
        get { header.subtitle }
        set { header.subtitle = newValue }
    }

    var separatorStyle: InspectorElementItemSeparatorStyle {
        get { .none }
        set {}
    }

    private lazy var formView = InspectorElementSectionFormView(header: header, state: state).then {
        $0.separatorStyle = .none
    }

    var delegate: InspectorElementFormItemViewDelegate? {
        get { formView.delegate }
        set { formView.delegate = newValue }
    }

    var state: InspectorElementSectionState {
        didSet {
            formView.state = state
        }
    }

    private(set) lazy var header = SectionHeader(
        titleFont: .init(.footnote, .traitBold),
        subtitleFont: .caption1,
        margins: .init(vertical: elementInspectorAppearance.verticalMargins)
    )

    private lazy var cardView = BaseCardView().then {
        var insets = elementInspectorAppearance.directionalInsets
        insets.bottom = insets.leading
        insets.top = .zero

        $0.margins = insets
        $0.borderWidth = 1
        $0.cornerRadius = elementInspectorAppearance.elementInspectorCornerRadius
        $0.contentMargins = .zero
        $0.backgroundColor = colorStyle.layoutConstraintsCardBackgroundColor

        formView.headerControl.layer.cornerRadius = $0.cornerRadius

        $0.contentView.addArrangedSubview(formView)
    }

    private var isConstraintActive = true {
        didSet {
            if isConstraintActive {
                header.alpha = 1
                tintAdjustmentMode = .automatic

                cardView.borderColor = colorStyle.tintColor
                cardView.backgroundColor = colorStyle.layoutConstraintsCardBackgroundColor
            }
            else {
                header.alpha = 0.5
                tintAdjustmentMode = .dimmed

                cardView.borderColor = colorStyle.quaternaryTextColor
                cardView.backgroundColor = colorStyle.layoutConstraintsCardInactiveBackgroundColor
            }
        }
    }

    init(state: InspectorElementSectionState, frame: CGRect = .zero) {
        self.state = state
        super.init(frame: frame)
    }

    override func setup() {
        super.setup()

        contentView.addArrangedSubview(cardView)
    }
}

// MARK: - InspectorElementSectionView

extension InspectorElementLayoutConstraintSectionView: InspectorElementSectionView {
    static func makeItemView(with inititalState: InspectorElementSectionState) -> InspectorElementSectionView {
        InspectorElementLayoutConstraintSectionView(state: inititalState)
    }

    func addTitleAccessoryView(_ titleAccessoryView: UIView?) {
        formView.addTitleAccessoryView(titleAccessoryView)

        guard let toggleControl = titleAccessoryView as? ToggleControl else {
            return
        }

        toggleControl.delegate = self
        toggleControl.isShowingSeparator = false
        isConstraintActive = toggleControl.isOn
    }

    func addFormViews(_ formViews: [UIView]) {
        formView.addFormViews(formViews)
    }
}

// MARK: - ToggleControlDelegate

extension InspectorElementLayoutConstraintSectionView: ToggleControlDelegate {
    func toggleControl(_ toggleControl: ToggleControl, didChangeValueTo isOn: Bool) {
        animate {
            self.isConstraintActive = toggleControl.isOn
        }
    }
}
