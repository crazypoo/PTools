//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public enum InspectorElemenPropertyNoteIcon: ColorStylable {
    case info, warning

    var image: UIImage? {
        switch self {
        case .info:
            return .infoOutlineSymbol

        case .warning:
            return .warningSymbol
        }
    }

    var color: UIColor {
        switch self {
        case .info:
            return colorStyle.tertiaryTextColor
        case .warning:
            return UIColor(hex: 0xDA7A3A)
        }
    }
}

final class NoteControl: BaseControl {
    let title: String?

    let text: String?

    let icon: InspectorElemenPropertyNoteIcon?

    init(icon: InspectorElemenPropertyNoteIcon?, title: String?, text: String?, frame: CGRect = .zero) {
        self.title = title
        self.text = text
        self.icon = icon
        super.init(frame: frame)
    }

    private lazy var imageView = UIImageView(
        image: icon?.image?.resized(.regularIconSize)
    ).then {
        guard let icon = icon else {
            $0.isHidden = true
            return
        }

        $0.tintColor = icon.color
        $0.widthAnchor.constraint(equalToConstant: CGSize.regularIconSize.width).isActive = true
    }

    private lazy var header = SectionHeader(
        title: title,
        titleFont: .footnote,
        subtitle: text,
        subtitleFont: .caption2,
        margins: .init(
            leading: elementInspectorAppearance.verticalMargins,
            trailing: elementInspectorAppearance.horizontalMargins
        )
    ).then {
        $0.titleLabel.numberOfLines = 0
        $0.subtitleLabel.numberOfLines = 0
    }

    override func setup() {
        super.setup()

        contentView.axis = .horizontal

        contentView.alignment = .top

        contentView.spacing = 5

        contentView.directionalLayoutMargins.update(
            bottom: elementInspectorAppearance.horizontalMargins
        )

        contentView.addArrangedSubviews(imageView, header)

        header.heightAnchor.constraint(greaterThanOrEqualTo: imageView.heightAnchor).isActive = true
    }
}
