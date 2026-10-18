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

protocol HierarchyInspectorViewCodeDelegate: AnyObject {
    func hierarchyInspectorViewCodeDidTapOutside(_ view: HierarchyInspectorViewCode)
}

final class HierarchyInspectorViewCode: BaseView {
    var verticalMargin: CGFloat { 30 }

    var horizontalMargin: CGFloat { verticalMargin / 2 }

    var keyboardFrame: CGRect? {
        didSet {
            let visibleHeight: CGFloat = {
                guard let keyboardFrame = keyboardFrame else {
                    return .zero
                }

                let globalFrame = convert(frame, to: nil)

                return globalFrame.height + globalFrame.origin.y - safeAreaInsets.bottom - keyboardFrame.origin.y
            }()

            bottomAnchorConstraint?.update(offset: (visibleHeight + verticalMargin) * -1)
        }
    }

    weak var delegate: HierarchyInspectorViewCodeDelegate?

    var tableViewContentSize: CGSize = .zero {
        didSet {
            debounce(#selector(updateTableViewHeight), after: .veryShort)
        }
    }

    // MARK: - Constraints

    private var tableViewHeightConstraint: PTLayoutConstraint?

    private var bottomAnchorConstraint: PTLayoutConstraint?

    private var customConstraints: [PTLayoutConstraint] = []

    private var tableViewHeight: CGFloat = .zero

    // MARK: - Components

    private(set) lazy var searchView = HierarchyInspectorSearchView()

    private(set) lazy var tableView = UIKeyCommandTableView().then {
        $0.backgroundColor = .none
        $0.keyboardDismissMode = .onDrag
        $0.rowHeight = UITableView.automaticDimension
        $0.separatorStyle = .none
        $0.sectionHeaderTopPadding = 0
    }

    private lazy var blurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: colorStyle.blurStyle)

        let blurView = UIVisualEffectView(effect: blur)
        blurView.clipsToBounds = true
        blurView.layer.cornerRadius = elementInspectorAppearance.verticalMargins
        blurView.layer.borderWidth = 1
        blurView.layer.cornerCurve = .continuous
        blurView.layer.borderColor = {
            switch colorStyle {
            case .dark: return colorStyle.tertiaryTextColor.cgColor
            case .light: return colorStyle.quaternaryTextColor.cgColor
            }
        }()

        return blurView
    }()

    private lazy var stackView = UIStackView.vertical(
        .arrangedSubviews(
            searchView,
            tableView
        )
    )

    override func didMoveToWindow() {
        super.didMoveToWindow()

        if window == .none {
            customConstraints.forEach { $0.deactivate() }
        }
        else {
            customConstraints.forEach { _ = $0.activate() }
        }
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        updateTableViewHeight()
    }

    @objc func updateTableViewHeight() {
        guard superview?.window != nil else { return }

        let height: CGFloat = floor(tableViewContentSize.height + 1) + tableView.contentInset.verticalInsets

        guard tableViewHeight != height else {
            return
        }

        UIView.performWithoutAnimation {
            self.tableViewHeight = height
            self.tableViewHeightConstraint?.update(offset: height)
            self.layoutIfNeeded()
        }
    }

    override func setup() {
        super.setup()

        tintColor = colorStyle.textColor
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        preservesSuperviewLayoutMargins = false

        layer.shadowColor = colorStyle.shadowColor.cgColor
        layer.shadowOffset = .init(width: 0, height: verticalMargin / 2)
        layer.shadowOpacity = 1
        layer.shadowRadius = verticalMargin

        blurView.contentView.installView(stackView)

        contentView.addSubview(blurView)
        tableView.ptLayout.makeConstraints { make in
            tableViewHeightConstraint = make.height.equalTo(0).priority(UILayoutPriority.defaultLow.rawValue).constraint
        }
        blurView.ptLayout.makeConstraints { make in
            customConstraints = [
                make.top.equalTo(safeAreaLayoutGuide.ptLayout.top).offset(verticalMargin).priority(UILayoutPriority.defaultHigh.rawValue).constraint,
                make.centerX.equalTo(safeAreaLayoutGuide.ptLayout.centerX).priority(UILayoutPriority.defaultHigh.rawValue).constraint,
                make.width.lessThanOrEqualTo(readableContentGuide.ptLayout.width).offset(-horizontalMargin * 4).priority(UILayoutPriority.defaultHigh.rawValue).constraint,
                make.width.greaterThanOrEqualTo(Inspector.sharedInstance.configuration.elementInspectorConfiguration.panelPreferredCompressedSize.width).priority(UILayoutPriority.defaultHigh.rawValue).constraint
            ]
            let bottomConstraint = make.bottom.lessThanOrEqualTo(safeAreaLayoutGuide.ptLayout.bottom).offset(-verticalMargin).priority(UILayoutPriority.defaultHigh.rawValue).constraint
            bottomAnchorConstraint = bottomConstraint
            customConstraints.append(bottomConstraint)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        guard
            let location = touches.first?.location(in: blurView),
            blurView.point(inside: location, with: .none) == false
        else {
            return
        }

        Task { @MainActor in
            self.delegate?.hierarchyInspectorViewCodeDidTapOutside(self)
        }
    }
}

extension HierarchyInspectorViewCode: DataReloadingProtocol {
    func reloadData() {
        tableView.reloadData()
        updateTableViewHeight()
    }
}
