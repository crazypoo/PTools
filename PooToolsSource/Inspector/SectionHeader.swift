//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension SectionHeader {
    private static var elementInspectorAppearance: ElementInspectorAppearance { Inspector.sharedInstance.appearance.elementInspector }

    static func formSectionTitle(title: String? = nil, subtitle: String? = nil) -> SectionHeader {
        SectionHeader(
            title: title,
            titleFont: .init(.body, .traitBold),
            subtitle: subtitle,
            subtitleFont: .caption1,
            margins: .init(vertical: elementInspectorAppearance.verticalMargins / 2)
        )
    }

    static func attributesInspectorGroup(title: String? = nil, subtitle: String? = nil) -> SectionHeader {
        SectionHeader(
            title: title,
            titleFont: .callout,
            subtitle: subtitle,
            subtitleFont: .caption1,
            margins: .init(
                top: elementInspectorAppearance.horizontalMargins,
                bottom: elementInspectorAppearance.verticalMargins
            )
        )
        .then {
            $0.titleLabel.textColor = $0.colorStyle.secondaryTextColor
        }
    }
}

final class SectionHeader: BaseView {
    var titleAlignment: NSTextAlignment {
        get { titleLabel.textAlignment }
        set { titleLabel.textAlignment = newValue }
    }

    private(set) lazy var titleLabel = UILabel(
        .textColor(colorStyle.textColor)
    ).then {
        $0.numberOfLines = 2
        $0.font = titleFont.font()
        $0.isHidden = $0.text.isNilOrEmpty
    }

    var subtitleAlignment: NSTextAlignment {
        get { subtitleLabel.textAlignment }
        set { subtitleLabel.textAlignment = newValue }
    }

    private(set) lazy var subtitleLabel = UILabel(
        .textColor(colorStyle.secondaryTextColor)
    ).then {
        $0.font = subtitleFont.font()
        $0.numberOfLines = 2
        $0.isHidden = $0.text.isNilOrEmpty
    }

    var title: String? {
        get {
            titleLabel.text
        }
        set {
            titleLabel.text = newValue
            titleLabel.isHidden = newValue.isNilOrEmpty
        }
    }

    var subtitle: String? {
        get {
            subtitleLabel.text
        }
        set {
            subtitleLabel.text = newValue
            subtitleLabel.isHidden = newValue.isNilOrEmpty
        }
    }

    struct FontOptions {
        var style: UIFont.TextStyle
        var traits: UIFontDescriptor.SymbolicTraits = .traitUIOptimized

        init(_ style: UIFont.TextStyle, _ traits: UIFontDescriptor.SymbolicTraits = .traitUIOptimized) {
            self.style = style
            self.traits = traits
        }

        func font() -> UIFont {
            .preferredFont(forTextStyle: style, with: traits.union(.traitUIOptimized))
        }

        // MARK: - Convenience Inits

        static let largeTitle: Self = .init(.largeTitle)
        static let title1: Self = .init(.title1)
        static let title2: Self = .init(.title2)
        static let title3: Self = .init(.title3)
        static let headline: Self = .init(.headline)
        static let subheadline: Self = .init(.subheadline)
        static let body: Self = .init(.body)
        static let callout: Self = .init(.callout)
        static let footnote: Self = .init(.footnote)
        static let caption1: Self = .init(.caption1)
        static let caption2: Self = .init(.caption2)
    }

    var margins: NSDirectionalEdgeInsets {
        get { contentView.directionalLayoutMargins }
        set { contentView.directionalLayoutMargins = newValue }
    }

    var titleFont: FontOptions {
        didSet {
            titleLabel.font = titleFont.font()
        }
    }

    var subtitleFont: FontOptions {
        didSet {
            subtitleLabel.font = subtitleFont.font()
        }
    }

    override func setup() {
        super.setup()
        contentView.axis = .vertical
        contentView.addArrangedSubviews(titleLabel, subtitleLabel)
        contentView.spacing = elementInspectorAppearance.verticalMargins / 2
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let maxWidth = contentView.bounds.inset(by: contentView.directionalLayoutMargins.edgeInsets()).width

        titleLabel.preferredMaxLayoutWidth = maxWidth
        subtitleLabel.preferredMaxLayoutWidth = maxWidth
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        backgroundColor = superview?.backgroundColor
    }

    init(
        title: String? = nil,
        titleFont: FontOptions = .title3,
        subtitle: String? = nil,
        subtitleFont: FontOptions = .body,
        margins: NSDirectionalEdgeInsets? = .none
    ) {
        self.titleFont = titleFont
        self.subtitleFont = subtitleFont

        super.init(frame: .zero)

        self.title = title
        self.subtitle = subtitle
        self.margins = margins ?? elementInspectorAppearance.directionalInsets
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init?(coder:) not implemented")
    }
}
