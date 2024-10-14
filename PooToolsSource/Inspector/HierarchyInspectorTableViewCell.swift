//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

class HierarchyInspectorTableViewCell: UITableViewCell, ElementInspectorAppearanceProviding {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        backgroundView = UIView()
        backgroundColor = nil

        textLabel?.textColor = colorStyle.textColor
        detailTextLabel?.textColor = colorStyle.secondaryTextColor

        selectedBackgroundView = UIView().then {
            let colorView = BaseView(
                .clipsToBounds(true),
                .backgroundColor(colorStyle.softTintColor),
                .layerOptions(
                    .cornerRadius(elementInspectorAppearance.verticalMargins / 2)
                )
            )

            $0.installView(
                colorView,
                .spacing(
                    horizontal: elementInspectorAppearance.verticalMargins,
                    vertical: .zero
                )
            )
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        layer.mask = nil
    }
}
