//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class ViewHierarchyPreviewController: UIViewController {
    let element: ViewHierarchyElementReference

    init(with element: ViewHierarchyElementReference) {
        self.element = element
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private(set) lazy var viewCode = BaseView().then {
        $0.installView($0.contentView, priority: .required)
        $0.backgroundColor = $0.colorStyle.highlightBackgroundColor
    }

    private(set) lazy var elementDescriptionView = ViewHierarchyElementDescriptionView().then {
        $0.summaryInfo = element.summaryInfo
    }

    private(set) lazy var separatorView = SeparatorView(style: .hard)

    private(set) lazy var thumbnailView = LiveViewHierarchyElementThumbnailView(with: element)

    override func loadView() {
        view = viewCode
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewCode.contentView.addArrangedSubviews(elementDescriptionView, separatorView, thumbnailView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let size = view.systemLayoutSizeFitting(
            view.frame.size,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        preferredContentSize = size
    }
}
