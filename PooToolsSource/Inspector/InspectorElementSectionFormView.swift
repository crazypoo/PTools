//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

class InspectorElementSectionFormView: BaseView {
    var title: String? {
        get { header.title }
        set { header.title = newValue }
    }

    var subtitle: String? {
        get { header.subtitle }
        set { header.subtitle = newValue }
    }

    static func makeItemView(with inititalState: InspectorElementSectionState) -> InspectorElementSectionView {
        InspectorElementSectionFormView(header: SectionHeader.formSectionTitle(), state: inititalState, frame: .zero)
    }

    // MARK: - Properties

    weak var delegate: InspectorElementFormItemViewDelegate?

    var separatorStyle: InspectorElementItemSeparatorStyle = .none {
        didSet {
            switch separatorStyle {
            case .none:
                topSeparatorView.isHidden = true
                bottomSeparatorView.isHidden = true
            case .top:
                topSeparatorView.isHidden = false
                bottomSeparatorView.isHidden = true
            case .bottom:
                topSeparatorView.isHidden = true
                bottomSeparatorView.isHidden = false
            }
        }
    }

    var state: InspectorElementSectionState {
        didSet {
            guard oldValue != state else { return }

            updateViewsForState()
        }
    }

    // MARK: - Views

    private(set) lazy var formStackView = UIStackView.vertical().then {
        $0.clipsToBounds = true
    }

    private lazy var topSeparatorView = SeparatorView(style: .hard).then {
        $0.isSafelyHidden = true
    }

    private lazy var bottomSeparatorView = SeparatorView(style: .hard).then {
        $0.isSafelyHidden = true
    }

    var header: SectionHeader

    private lazy var headerStackView = UIStackView.horizontal().then {
        $0.isLayoutMarginsRelativeArrangement = true
        $0.alignment = .center
        $0.addArrangedSubview(headerControl)
        $0.clipsToBounds = true
    }

    var headerLayoutMargins: NSDirectionalEdgeInsets {
        get { headerControl.contentView.directionalLayoutMargins }
        set { headerControl.contentView.directionalLayoutMargins = newValue }
    }

    private(set) lazy var headerControl = BaseControl(.translatesAutoresizingMaskIntoConstraints(false)).then {
        $0.addTarget(self, action: #selector(changeState), for: .touchUpInside)
        $0.addTarget(self, action: #selector(headerControlDidChangeState), for: .stateChanged)

        $0.contentView.isUserInteractionEnabled = false
        $0.contentView.spacing = elementInspectorAppearance.verticalMargins
        $0.contentView.addArrangedSubviews(collapseIcon, header)
        $0.contentView.alignment = .center
        $0.contentView.directionalLayoutMargins = elementInspectorAppearance.directionalInsets
    }

    private(set) lazy var collapseIcon = CollapseIcon()

    init(header: SectionHeader,
         state: InspectorElementSectionState,
         frame: CGRect = .zero)
    {
        self.state = state
        self.header = header

        super.init(frame: frame)
    }

    override func setup() {
        super.setup()

        let interaction = UIContextMenuInteraction(delegate: self)
        headerControl.addInteraction(interaction)

        clipsToBounds = true
        updateViewsForState()
        installSeparators()

        headerControl.contentView.directionalLayoutMargins = elementInspectorAppearance.directionalInsets
        formStackView.directionalLayoutMargins = elementInspectorAppearance.directionalInsets.with(top: .zero)

        contentView.addArrangedSubviews(headerStackView, formStackView)
    }

    private func updateViewsForState() {
        switch state {
        case .collapsed:
            hideContent(true)

        case .expanded:
            hideContent(false)
        }
    }

    private func installSeparators() {
        topSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topSeparatorView)
        topSeparatorView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        topSeparatorView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        topSeparatorView.topAnchor.constraint(equalTo: topAnchor).isActive = true

        bottomSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomSeparatorView)
        bottomSeparatorView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        bottomSeparatorView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        bottomSeparatorView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    private func hideContent(_ hide: Bool) {
        formStackView.alpha = hide ? 0 : 1
        formStackView.isSafelyHidden = hide
        collapseIcon.transform = hide ? CGAffineTransform(rotationAngle: -(.pi / 2)) : .identity
    }
}

extension InspectorElementSectionFormView: InspectorElementSectionView {
    func addTitleAccessoryView(_ titleAccessoryView: UIView?) {
        var headerSubviews: [UIView] = [headerControl]

        if let titleAccessoryView = titleAccessoryView {
            headerSubviews.append(titleAccessoryView)
            headerStackView.directionalLayoutMargins.update(trailing: elementInspectorAppearance.horizontalMargins)
        }
        else {
            headerStackView.directionalLayoutMargins.update(trailing: .zero)
        }

        headerStackView.replaceArrangedSubviews(with: headerSubviews)
    }

    func addFormViews(_ formViews: [UIView]) {
        contentView.spacing = formViews.first is NoteControl ? .zero : elementInspectorAppearance.verticalMargins
        formStackView.addArrangedSubviews(formViews)
    }
}

@objc private extension InspectorElementSectionFormView {
    func changeState() {
        var newState = state
        newState.toggle()

        delegate?.inspectorElementFormItemView(self, willChangeFrom: state, to: newState)
    }

    func headerControlDidChangeState() {
        animate {
            switch self.headerControl.state {
            case .highlighted:
                self.headerControl.alpha = 0.66
                self.headerControl.transform = .init(scaleX: 0.98, y: 0.93)
            default:
                self.headerControl.alpha = 1
                self.headerControl.transform = .identity
            }
        }
    }
}

extension InspectorElementSectionFormView {
    final class CollapseIcon: BaseView {
        private lazy var icon = IconButton(.chevronDown).then {
            $0.isUserInteractionEnabled = false
        }

        private lazy var activityIndicatorView = UIActivityIndicatorView().then {
            $0.hidesWhenStopped = true
            $0.color = colorStyle.tertiaryTextColor
            contentView.installView($0, .centerXY)
        }

        override func setup() {
            super.setup()

            contentView.installView(icon)
        }

        func showLoading() {
            activityIndicatorView.startAnimating()
            icon.isSafelyHidden = true
        }

        func hideLoading() {
            activityIndicatorView.stopAnimating()
            icon.isSafelyHidden = false
        }
    }
}

// MARK: - UIContextMenuInteractionDelegate

extension InspectorElementSectionFormView: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: nil,
            actionProvider: { [weak self] _ in
                guard let self = self else { return nil }

                return UIMenu(
                    title: String(),
                    image: nil,
                    identifier: nil,
                    options: .displayInline,
                    children: [
                        UIAction.collapseAction(self.state == .collapsed) { [weak self] _ in
                            self?.changeState()
                        }
                    ]
                )
            }
        )
    }
}
