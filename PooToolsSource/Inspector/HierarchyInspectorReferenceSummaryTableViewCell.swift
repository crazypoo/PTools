//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

protocol HierarchyInspectorReferenceSummaryCellViewModelProtocol {
    var title: String? { get }
    var isEnabled: Bool { get }
    var subtitle: String? { get }
    var image: UIImage? { get }
    var depth: Int { get }
    var element: ViewHierarchyElementReference { get }
}

final class HierarchyInspectorReferenceSummaryTableViewCell: HierarchyInspectorTableViewCell {
    var viewModel: HierarchyInspectorReferenceSummaryCellViewModelProtocol? {
        didSet {
            textLabel?.text = viewModel?.title
            detailTextLabel?.text = viewModel?.subtitle
            imageView?.image = viewModel?.image

            let defaultLayoutMargins = directionalLayoutMargins
            let depth = CGFloat(viewModel?.depth ?? 0)
            var margins = defaultLayoutMargins
            margins.leading += depth * 5

            directionalLayoutMargins = margins
            separatorInset = UIEdgeInsets(left: margins.leading, right: defaultLayoutMargins.trailing)

            contentView.alpha = viewModel?.isEnabled == true ? 1 : colorStyle.disabledAlpha
            selectionStyle = viewModel?.isEnabled == true ? .default : .none
        }
    }

    override func setup() {
        super.setup()

        tintColor = colorStyle.textColor

        textLabel?.font = .preferredFont(forTextStyle: .footnote).bold()
        textLabel?.numberOfLines = 2

        detailTextLabel?.numberOfLines = 4

        installView(contentView)

        imageView?.contentMode = .center
    }
}
