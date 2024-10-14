//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

protocol HierarchyInspectorActionTableViewCellViewModelProtocol {
    var title: String { get }
    var icon: UIImage? { get }
    var isEnabled: Bool { get }
    var isSelected: Bool { get }
}

final class HierarchyInspectorActionTableViewCell: HierarchyInspectorTableViewCell {
    var viewModel: HierarchyInspectorActionTableViewCellViewModelProtocol? {
        didSet {
            textLabel?.text = viewModel?.title

            imageView?.image = viewModel?.icon

            contentView.alpha = viewModel?.isEnabled == true ? 1 : colorStyle.disabledAlpha

            selectionStyle = viewModel?.isEnabled == true ? .default : .none

            if viewModel?.isSelected == true {
                accessoryView = checkmarkImageView
            }
            else {
                accessoryView = nil
            }
        }
    }

    private lazy var checkmarkImageView = UIImageView(image: checkmarkImage)

    private lazy var checkmarkImage = UIImage(systemName: "checkmark")!
        .applyingSymbolConfiguration(
            .init(pointSize: 16)
        )

    override func setup() {
        super.setup()

        tintColor = colorStyle.textColor

        textLabel?.textColor = colorStyle.textColor
        textLabel?.minimumScaleFactor = 0.8
        textLabel?.font = .systemFont(ofSize: 14)
    }
}
