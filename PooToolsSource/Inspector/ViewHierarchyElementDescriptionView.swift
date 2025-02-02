//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

struct ViewHierarchyElementSummary: ElementInspectorAppearanceProviding {
    var automaticallyAdjustIndentation: Bool = false
    var hideCollapseButton: Bool = true
    var iconImage: UIImage?
    var isCollapseButtonEnabled: Bool = false
    var isCollapsed: Bool = false
    var isContainer: Bool
    var isHidden: Bool = false
    var relativeDepth: Int = .zero
    var subtitle: String?
    var subtitleFont: UIFont = Inspector.sharedInstance.appearance.elementInspector.font(forRelativeDepth: .zero)
    var title: String?
    var titleFont: UIFont = Inspector.sharedInstance.appearance.elementInspector.titleFont(forRelativeDepth: .zero)
}

final class ViewHierarchyElementDescriptionView: BaseView, DataReloadingProtocol {
    var summaryInfo: ViewHierarchyElementSummary? {
        didSet {
            reloadData()
        }
    }

    var isCollapsed = false {
        didSet {
            collapseButton.transform = .init(rotationAngle: isCollapsed ? -(.pi / 2) : .zero)
        }
    }

    private var isAutomaticallyAdjustIndentation: Bool = true {
        didSet {
            if isAutomaticallyAdjustIndentation {
                indendationAdjustmentStackView.directionalLayoutMargins.update(leading: elementInspectorAppearance.horizontalMargins)
            }
            else {
                indendationAdjustmentStackView.directionalLayoutMargins.update(leading: .zero)
            }
        }
    }

    func reloadData() {
        // name
        elementNameLabel.text = summaryInfo?.title
        elementNameLabel.font = summaryInfo?.titleFont

        // icon
        iconImageView.image = summaryInfo?.iconImage

        // collapse button
        collapseButton.isHidden = summaryInfo?.hideCollapseButton != false
        collapseButton.isUserInteractionEnabled = summaryInfo?.isCollapseButtonEnabled == true
        isCollapsed = summaryInfo?.isCollapsed == true

        isAutomaticallyAdjustIndentation = summaryInfo?.automaticallyAdjustIndentation == true

        // description
        summaryInfoLabel.text = summaryInfo?.subtitle
        summaryInfoLabel.font = summaryInfo?.subtitleFont

        // Containers Insets
        let relativeDepth = summaryInfo?.relativeDepth ?? 0
        let indentation = CGFloat(relativeDepth) * elementInspectorAppearance.horizontalMargins
        contentView.directionalLayoutMargins = NSDirectionalEdgeInsets(leading: indentation)
    }

    private lazy var indendationAdjustmentStackView = UIStackView().then {
        $0.isLayoutMarginsRelativeArrangement = true
        $0.addArrangedSubview(contentViewContainer)
    }

    private lazy var contentViewContainer = UIStackView().then {
        $0.isLayoutMarginsRelativeArrangement = true
        $0.directionalLayoutMargins = elementInspectorAppearance.directionalInsets
        $0.addArrangedSubview(contentView)
    }

    override var directionalLayoutMargins: NSDirectionalEdgeInsets {
        get { contentViewContainer.directionalLayoutMargins }
        set { contentViewContainer.directionalLayoutMargins = newValue }
    }

    func toggleCollapse(animated: Bool) {
        guard animated else {
            isCollapsed.toggle()
            return
        }

        animate { [weak self] in
            self?.isCollapsed.toggle()
        }
    }

    private(set) lazy var elementNameLabel = UILabel().then {
        $0.textColor = colorStyle.textColor
        $0.setContentCompressionResistancePriority(.required, for: .vertical)
        $0.setContentHuggingPriority(.required, for: .vertical)
        $0.numberOfLines = 1
        $0.preferredMaxLayoutWidth = 150
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.8
        $0.allowsDefaultTighteningForTruncation = true
    }

    private(set) lazy var summaryInfoLabel = UILabel().then {
        $0.clipsToBounds = true
        $0.numberOfLines = .zero
        $0.textColor = colorStyle.secondaryTextColor
        $0.setContentCompressionResistancePriority(.required, for: .vertical)
        $0.setContentHuggingPriority(.defaultLow, for: .vertical)
    }

    private(set) lazy var collapseButton = IconButton(.chevronDown).then {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    private(set) lazy var iconContainerView = BaseView().then {
        $0.backgroundColor = colorStyle.highlightBackgroundColor
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
        $0.installView(iconImageView, .spacing(all: 3), priority: .required)
    }

    private(set) lazy var iconImageView = UIImageView().then {
        $0.clipsToBounds = false
        $0.contentMode = .scaleAspectFit
        $0.widthAnchor.constraint(equalToConstant: CGSize.elementIconSize.width).isActive = true
        $0.widthAnchor.constraint(equalTo: $0.heightAnchor).isActive = true
    }

    private(set) lazy var elementIconAndDescriptionLabel = UIStackView.horizontal().then {
        $0.spacing = elementInspectorAppearance.verticalMargins
        $0.addArrangedSubviews(summaryInfoLabel, iconContainerView)
        $0.alignment = .top
    }

    override func setup() {
        super.setup()

        tintColor = colorStyle.textColor

        contentView.axis = .vertical
        contentView.spacing = elementInspectorAppearance.verticalMargins / 2
        contentView.addArrangedSubviews(elementNameLabel, elementIconAndDescriptionLabel)

        installView(indendationAdjustmentStackView, priority: .required)

        contentView.addSubview(collapseButton)

        collapseButton.centerYAnchor.constraint(
            equalTo: elementIconAndDescriptionLabel.topAnchor
        ).isActive = true

        elementIconAndDescriptionLabel.leadingAnchor.constraint(
            equalTo: collapseButton.trailingAnchor,
            constant: elementInspectorAppearance.verticalMargins * 3 / 2
        ).isActive = true
    }
}
