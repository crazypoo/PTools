//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class HierarchyInspectorTableViewHeaderView: UITableViewHeaderFooterView, ElementInspectorAppearanceProviding {
    private(set) lazy var separatorView = SeparatorView(style: .hard)

    private lazy var titleStackView = UIStackView(arrangedSubviews: [titleLabel]).then {
        $0.axis = .vertical
        $0.spacing = elementInspectorAppearance.verticalMargins
        $0.isLayoutMarginsRelativeArrangement = true
    }

    private(set) lazy var titleLabel = UILabel(
        .textStyle(.caption1, traits: .traitBold),
        .textColor(colorStyle.secondaryTextColor)
    )

    var title: String? {
        didSet {
            titleLabel.text = title
            titleLabel.isHidden = title.isNilOrEmpty
            titleStackView.directionalLayoutMargins = title.isNilOrEmpty ? .zero : .init(insets: 16)
        }
    }

    var showSeparatorView: Bool {
        get { separatorView.isHidden }
        set { separatorView.isHidden = !newValue }
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        backgroundView = UIView()

        contentView.installView(titleStackView)

        contentView.installView(
            separatorView,
            .spacing(
                top: -separatorView.thicknesInPixels,
                leading: .zero,
                trailing: .zero
            )
        )
    }
}
