//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

class BaseView: UIView, InternalViewProtocol, InspectorAppearanceProviding, ElementInspectorAppearanceProviding {
    private(set) lazy var contentView = UIStackView.vertical().then {
        installView($0, priority: .required)
    }

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    func setup() {
        preservesSuperviewLayoutMargins = true
        layer.cornerCurve = .continuous
    }
}
