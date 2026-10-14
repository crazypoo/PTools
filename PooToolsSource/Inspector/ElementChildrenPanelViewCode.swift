//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
#if SWIFT_PACKAGE
import ptools
#endif

final class ElementChildrenPanelViewCode: BaseView {
    private(set) lazy var tableView = UIKeyCommandTableView(
        .backgroundColor(backgroundColor),
        .viewOptions(.isOpaque(true)),
        .tableFooterView(UIView()),
        .separatorStyle(.none),
        .contentInset(bottom: elementInspectorAppearance.horizontalMargins)
    )

    override func setup() {
        super.setup()

        installView(tableView)
    }
}
