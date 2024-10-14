//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

typealias ElementChildrenPanelViewControllerDelegate = OperationQueueManagerProtocol & ViewHierarchyActionableProtocol

final class ElementChildrenPanelViewController: ElementInspectorPanelViewController, DataReloadingProtocol {
    // MARK: - Properties

    weak var delegate: ElementChildrenPanelViewControllerDelegate?

    private var hasDisappeared = false

    override var panelScrollView: UIScrollView? { viewCode.tableView }

    private(set) lazy var viewCode = ElementChildrenPanelViewCode(
        frame: CGRect(
            origin: .zero,
            size: Inspector.sharedInstance.configuration.elementInspectorConfiguration.panelPreferredCompressedSize
        )
    ).then {
        $0.tableView.register(ElementChildrenPanelTableViewCodeCell.self)
        $0.tableView.activateAccessoryButtonKeyCommandOptions = [.discoverabilityTitle(title: "Inspect", key: .key("i"))]
        $0.tableView.dataSource = self
        $0.tableView.delegate = self
    }

    let viewModel: ElementChildrenPanelViewModelProtocol

    // MARK: - Init

    init(viewModel: ElementChildrenPanelViewModelProtocol) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func loadView() {
        view = viewCode
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard hasDisappeared else { return }

        hasDisappeared = false

        if let indexPathsForSelectedRows = viewCode.tableView.indexPathsForSelectedRows {
            transitionCoordinator?.animate { _ in
                indexPathsForSelectedRows.forEach {
                    self.viewCode.tableView.deselectRow(at: $0, animated: animated)
                }
            } completion: { context in
                guard context.isCancelled else { return }

                indexPathsForSelectedRows.forEach {
                    self.viewCode.tableView.selectRow(at: $0, animated: false, scrollPosition: .none)
                }
            }
        }

        viewCode.tableView.indexPathsForVisibleRows?.forEach { IndexPath in
            guard
                let cell = viewCode.tableView.cellForRow(at: IndexPath) as? ElementChildrenPanelTableViewCodeCell,
                let cellViewModel = viewModel.cellViewModel(at: IndexPath)
            else { return }
            cell.viewModel = cellViewModel
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewCode.tableView.becomeFirstResponder()

        viewCode.tableView.showsVerticalScrollIndicator = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        hasDisappeared = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        viewCode.tableView.showsVerticalScrollIndicator = false
    }

    func reloadData() {
        viewCode.tableView.reloadData()
    }

    override func calculatePreferredContentSize() -> CGSize {
        let contentHeight = viewCode.tableView.estimatedRowHeight * CGFloat(viewModel.numberOfRows)
        let contentInset = viewCode.tableView.contentInset

        return CGSize(
            width: Inspector.sharedInstance.configuration.elementInspectorConfiguration.panelPreferredCompressedSize.width,
            height: contentHeight + contentInset.top + contentInset.bottom
        )
    }
}
