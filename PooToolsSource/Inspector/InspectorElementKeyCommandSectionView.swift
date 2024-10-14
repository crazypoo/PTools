//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class InspectorElementKeyCommandSectionView: BaseView {
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
        $0.headerLayoutMargins.update(top: 4, bottom: 4)
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
        titleFont: .init(.callout, .traitBold),
        subtitleFont: .init(.footnote, .traitBold),
        margins: .init(vertical: elementInspectorAppearance.verticalMargins)
    )

    private lazy var cardView = BaseCardView().then {
        var insets = elementInspectorAppearance.directionalInsets
        insets.bottom = insets.leading
        insets.top = .zero

        $0.margins = .init(
            horizontal: elementInspectorAppearance.horizontalMargins,
            vertical: elementInspectorAppearance.verticalMargins / 2
        )
        $0.contentMargins = .zero
        $0.backgroundColor = colorStyle.cellHighlightBackgroundColor
        $0.contentView.addArrangedSubview(formView)

        formView.headerControl.layer.cornerRadius = $0.cornerRadius
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

extension InspectorElementKeyCommandSectionView: InspectorElementSectionView {
    static func makeItemView(with inititalState: InspectorElementSectionState) -> InspectorElementSectionView {
        InspectorElementKeyCommandSectionView(state: inititalState)
    }

    func addTitleAccessoryView(_ titleAccessoryView: UIView?) {
        formView.addTitleAccessoryView(titleAccessoryView)
    }

    func addFormViews(_ formViews: [UIView]) {
        formView.addFormViews(formViews)
    }
}
