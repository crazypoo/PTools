//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
extension UISegmentedControl {
    static func segmentedControlStyle(items: [Any]? = nil) -> UISegmentedControl {
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.selectedSegmentTintColor = segmentedControl.colorStyle.tintColor
        segmentedControl.setTitleTextAttributes([.foregroundColor: segmentedControl.colorStyle.secondaryTextColor], for: .normal)
        segmentedControl.setTitleTextAttributes([.foregroundColor: segmentedControl.colorStyle.selectedSegmentedControlForegroundColor], for: .selected)

        return segmentedControl
    }
}

final class SegmentedControl: BaseFormControl {
    // MARK: - Properties

    let options: [Any]

    override var isEnabled: Bool {
        didSet {
            segmentedControl.isEnabled = isEnabled
        }
    }

    var selectedIndex: Int? {
        get { segmentedControl.selectedSegmentIndex == UISegmentedControl.noSegment ? nil : segmentedControl.selectedSegmentIndex }
        set { segmentedControl.selectedSegmentIndex = newValue ?? UISegmentedControl.noSegment }
    }

    private lazy var segmentedControl = UISegmentedControl.segmentedControlStyle(items: options).then {
        $0.addTarget(self, action: #selector(changeSegment), for: .valueChanged)
    }

    // MARK: - Init

    init(title: String?, images: [UIImage], selectedIndex: Int?) {
        options = images

        super.init(title: title)

        self.selectedIndex = selectedIndex
    }

    init(title: String?, texts: [String], selectedIndex: Int?) {
        options = texts

        super.init(title: title)

        self.selectedIndex = selectedIndex
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setup() {
        super.setup()

        axis = .vertical

        contentView.installView(segmentedControl)
    }

    @objc
    func changeSegment() {
        sendActions(for: .valueChanged)
    }
}
