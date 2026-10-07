//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

protocol OptionListControlDelegate: AnyObject {
    func optionListControlDidChangeSelectedIndex(_ optionListControl: OptionListControl)
}

@MainActor
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

        // English: Reuse the shared selection menu so the current index is read at presentation time.
        // Español: Reutiliza el menú de selección compartido para leer el índice actual al presentarlo.
        // 中文：复用统一选择菜单，在菜单展示时读取最新选中索引。
        pt_setSelectionMenuProvider(
            trigger: .primaryAction,
            items: { [options] in
                options.enumerated().map { index, option in
                    PTControlMenuSelectionItem(id: index,
                                               title: option.title.description,
                                               selectedImage: option.icon)
                }
            },
            selectedID: { [weak self] in self?.selectedIndex },
            selectionChanged: { [weak self] index in
                guard let self else { return }
                self.updateSelectedIndex(index)
                self.delegate?.optionListControlDidChangeSelectedIndex(self)
            }
        )
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

}
