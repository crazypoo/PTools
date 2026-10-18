//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
#if canImport(PToolsConstraintLayout)
import PToolsConstraintLayout
#endif
import SnapKit
#if SWIFT_PACKAGE
import ptools
#endif

final class ScrollingStackView: UIScrollView {
    private(set) lazy var contentView = UIStackView().then {
        $0.isLayoutMarginsRelativeArrangement = true
        $0.directionalLayoutMargins = .zero
        $0.axis = .vertical

        installView($0, priority: .required)
        $0.ptLayout.makeConstraints { make in
            make.width.equalToSuperview()
        }
    }
}
