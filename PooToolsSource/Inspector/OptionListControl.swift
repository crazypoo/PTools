//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

protocol OptionListControlDelegate: AnyObject {
    func optionListControlDidChangeSelectedIndex(_ optionListControl: OptionListControl)
}

final class OptionListControl: BaseFormControl {
    // MARK: - Properties

    weak var delegate: OptionListControlDelegate?

    override var isEnabled: Bool {
        didSet {
            icon.isHidden = !isEnabled
            valueLabel.textColor = textColor
            accessoryControl.isEnabled = isEnabled
        }
    }

    private lazy var icon = Icon(.chevronUpDown, color: textColor, size: CGSize(width: 14, height: 14))

    private var textColor: UIColor {
        isEnabled ? colorStyle.textColor : colorStyle.secondaryTextColor
    }

    private lazy var valueLabel = UILabel(
        .textStyle(.footnote),
        .textColor(textColor)
    ).then {
        $0.allowsDefaultTighteningForTruncation = true
        $0.lineBreakMode = .byTruncatingMiddle
        $0.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        $0.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }

    private(set) lazy var accessoryControl = AccessoryControl().then {
        $0.contentView.addArrangedSubviews(valueLabel, icon)
        $0.contentView.alignment = .center
        $0.contentView.spacing = elementInspectorAppearance.verticalMargins
        $0.contentView.directionalLayoutMargins.update(top: elementInspectorAppearance.verticalMargins, bottom: elementInspectorAppearance.verticalMargins)
    }

    // MARK: - Init

    let options: [Option]

    let emptyTitle: String

    var selectedIndex: Int? {
        didSet {
            updateViews()
        }
    }

    typealias Option = (title: Swift.CustomStringConvertible, icon: UIImage?)

    init(
        title: String?,
        options: [Option],
        emptyTitle: String,
        selectedIndex: Int? = nil
    ) {
        self.options = options

        self.selectedIndex = selectedIndex

        self.emptyTitle = emptyTitle

        super.init(title: title)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setup() {
        super.setup()

        contentView.addArrangedSubview(accessoryControl)

        accessoryControl.widthAnchor.constraint(greaterThanOrEqualTo: contentContainerView.widthAnchor, multiplier: 1 / 2).isActive = true

        updateViews()

        showsMenuAsPrimaryAction = true
        isContextMenuInteractionEnabled = true
    }

    func updateSelectedIndex(_ selectedIndex: Int?) {
        self.selectedIndex = selectedIndex
        sendActions(for: .valueChanged)
    }

    private func updateViews() {
        guard let selectedIndex = selectedIndex else {
            valueLabel.text = emptyTitle
            return
        }

        valueLabel.text = options[selectedIndex].title.description
    }

    // MARK: - Actions

    override func menuAttachmentPoint(for configuration: UIContextMenuConfiguration) -> CGPoint {
        switch axis {
        case .horizontal:
            let point = CGPoint(x: accessoryControl.bounds.maxX, y: accessoryControl.bounds.minY)
            let localPoint = accessoryControl.convert(point, to: self)
            return localPoint

        default:
            return super.menuAttachmentPoint(for: configuration)
        }
    }

    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let localPoint = convert(location, to: accessoryControl)

        guard accessoryControl.point(inside: localPoint, with: nil) else { return nil }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            self.makeOptionSelectionMenu()
        }
    }

    private func makeOptionSelectionMenu() -> UIMenu {
        UIMenu(
            title: title ?? "",
            children: options
                .enumerated()
                .map { index, option in
                    UIAction(
                        title: option.title.description,
                        image: option.icon,
                        state: index == self.selectedIndex ? .on : .off
                    ) { [weak self] _ in
                        guard let self = self else { return }
                        self.selectedIndex = index
                        self.delegate?.optionListControlDidChangeSelectedIndex(self)
                    }
                }
        )
    }
}
