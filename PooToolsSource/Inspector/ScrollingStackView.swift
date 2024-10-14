//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class ScrollingStackView: UIScrollView {
    private(set) lazy var contentView = UIStackView().then {
        $0.isLayoutMarginsRelativeArrangement = true
        $0.directionalLayoutMargins = .zero
        $0.axis = .vertical

        installView($0, priority: .required)
        widthAnchor.constraint(equalTo: $0.widthAnchor).isActive = true
    }
}
