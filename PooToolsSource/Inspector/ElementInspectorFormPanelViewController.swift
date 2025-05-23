//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

protocol ElementInspectorFormPanelDelegate: OperationQueueManagerProtocol {
    func elementInspectorFormPanel(_ formPanelViewController: ElementInspectorFormPanelViewController,
                                   didTap colorPreviewControl: ColorPreviewControl)

    func elementInspectorFormPanel(_ formPanelViewController: ElementInspectorFormPanelViewController,
                                   didTap imagePreviewControl: ImagePreviewControl)

    func elementInspectorFormPanel(_ formPanelViewController: ElementInspectorFormPanelViewController,
                                   didUpdateProperty property: InspectorElementProperty,
                                   in section: InspectorElementSection)
}

protocol ElementInspectorFormPanelItemStateDelegate: AnyObject {
    func elementInspectorFormPanelItemDidChangeState(_ formPanelViewController: ElementInspectorFormPanelViewController)
}

class ElementInspectorFormPanelViewController: ElementInspectorPanelViewController {
    func addOperationToQueue(_ operation: MainThreadOperation) {
        formDelegate?.addOperationToQueue(operation)
    }

    func suspendQueue(_ isSuspended: Bool) {
        formDelegate?.suspendQueue(isSuspended)
    }

    func cancelAllOperations() {
        formDelegate?.cancelAllOperations()
    }

    weak var itemStateDelegate: ElementInspectorFormPanelItemStateDelegate?

    weak var formDelegate: ElementInspectorFormPanelDelegate?

    var dataSource: ElementInspectorFormPanelDataSource? {
        didSet {
            if isViewLoaded {
                reloadData()
            }
        }
    }

    var initialListState: ElementInspectorPanelListState?

    var initialCompactListState: ElementInspectorPanelListState?

    private var initialListStateForCurrentHeight: ElementInspectorPanelListState? {
        isFullHeightPresentation ? initialListState : initialCompactListState
    }

    var selectedColorPreviewControl: ColorPreviewControl?

    var selectedImagePreviewControl: ImagePreviewControl?

    private(set) var sections: [InspectorElementSectionViewController: InspectorElementSection] = [:]

    var formPanels: [InspectorElementSectionViewController] {
        children.compactMap { $0 as? InspectorElementSectionViewController }
    }

    var containsExpandedFormItem: Bool { listState != .allCollapsed }

    var listState: ElementInspectorPanelListState {
        let expandedPanels = formPanels.filter { $0.state == .expanded }
        if expandedPanels.isEmpty { return .allCollapsed }
        if formPanels.count == expandedPanels.count { return .allExpanded }
        if expandedPanels.count == 1, formPanels.first?.state == .expanded { return .firstExpanded }
        return .mixed
    }

    var panelSelectionMode: ElementInspectorPanelSelectionMode { .multipleSelection }

    override var isFullHeightPresentation: Bool {
        didSet {
            switch (oldValue, isFullHeightPresentation) {
            // is expanding
            case (false, true),
                 (true, false):
                apply(
                    state: {
                        switch listState {
                        case .allCollapsed, .firstExpanded:
                            return initialListStateForCurrentHeight
                        case .mixed:
                            return .mixed
                        case .allExpanded:
                            return .allExpanded
                        }
                    }(),
                    animated: true
                )
            default:
                return
            }
        }
    }

    private lazy var viewCode = BaseView()

    override func loadView() {
        view = viewCode
    }

    private var viewHasAppeared = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if viewHasAppeared { return }
        viewHasAppeared = true

        reloadData()

        togglePanels(to: initialListStateForCurrentHeight, animated: false)
    }
}

// MARK: - DataReloadingProtocol

extension ElementInspectorFormPanelViewController: DataReloadingProtocol {
    func reloadData() {
        viewCode.contentView.removeAllArrangedSubviews()

        children.forEach { child in
            child.view.removeFromSuperview()
            child.willMove(toParent: nil)
            child.removeFromParent()
        }

        guard let dataSource = dataSource else { return }

        for sectionIndex in 0 ..< dataSource.numberOfSections {
            let section = dataSource.section(at: sectionIndex)

            if let title = section.title {
                viewCode.contentView.addArrangedSubview(
                    sectionHeader(title: title)
                )
            }

            for dataSource in section.dataSources {
                let view = dataSource.makeView().then {
                    $0.separatorStyle = .bottom
                }

                let sectionViewController = InspectorElementSectionViewController(view: view).then {
                    $0.dataSource = dataSource
                    $0.delegate = self
                }

                addChild(sectionViewController)

                sectionViewController.viewWillAppear(false)

                viewCode.contentView.addArrangedSubview(view)

                sectionViewController.didMove(toParent: self)

                sections[sectionViewController] = section
            }
        }
    }

    private func sectionHeader(title: String) -> SectionHeader {
        SectionHeader(
            title: title,
            titleFont: .title3,
            margins: elementInspectorAppearance.directionalInsets.with(
                top: elementInspectorAppearance.horizontalMargins * 2,
                bottom: elementInspectorAppearance.horizontalMargins * 2
            )
        ).then {
            $0.alpha = 0.5
        }
    }
}

extension ElementInspectorFormPanelViewController {
    func togglePanels(to newState: ElementInspectorPanelListState?, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        let newState = newState ?? .allCollapsed

        guard animated else {
            apply(state: newState, animated: false)
            itemStateDelegate?.elementInspectorFormPanelItemDidChangeState(self)
            return
        }

        animate(
            withDuration: .veryLong,
            options: [.beginFromCurrentState, .layoutSubviews]
        ) {
            self.apply(state: newState, animated: false)

        } completion: { [weak self] finished in
            completion?(finished)

            if let self = self {
                self.itemStateDelegate?.elementInspectorFormPanelItemDidChangeState(self)
            }
        }
    }

    @discardableResult
    private func apply(state: ElementInspectorPanelListState?, animated: Bool) -> Bool {
        switch state {
        case .none, .mixed:
            return false
        case .allCollapsed:
            collapseAllSections(animated: animated)
        case .firstExpanded:
            expandFirstSection(animated: animated)
        case .allExpanded:
            expandAllSections(animated: animated)
        }
        return true
    }

    private func collapseAllSections(animated: Bool) {
        formPanels.forEach { $0.setState(.collapsed, animated: animated) }
    }

    private func expandFirstSection(animated: Bool) {
        formPanels.enumerated().forEach { index, form in
            form.setState(index == .zero ? .expanded : .collapsed, animated: animated)
        }
    }

    private func expandAllSections(animated: Bool) {
        formPanels.forEach { $0.setState(.expanded, animated: animated) }
    }
}

// MARK: - Selection

extension ElementInspectorFormPanelViewController {
    func selectImage(_ image: UIImage?) {
        selectedImagePreviewControl?.updateSelectedImage(image)
    }

    func selectColor(_ color: UIColor) {
        selectedColorPreviewControl?.updateSelectedColor(color)
    }

    func finishColorSelection() {
        selectedColorPreviewControl = nil
    }
}
