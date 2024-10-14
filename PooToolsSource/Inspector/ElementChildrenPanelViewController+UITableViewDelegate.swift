//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension ElementChildrenPanelViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cellViewModel = viewModel.cellViewModel(at: indexPath) else { return }

        let backgroundColor = cell.backgroundColor

        cell.backgroundColor = .none
        cell.contentView.alpha = cellViewModel.appearance.alpha
        cell.transform = cellViewModel.appearance.transform
        cell.alpha = cellViewModel.appearance.alpha

        tableView.animate(withDuration: .veryLong, delay: .short) {
            cellViewModel.animatedDisplay = false

            cell.backgroundColor = backgroundColor
            cell.contentView.alpha = cellViewModel.appearance.alpha
            cell.transform = cellViewModel.appearance.transform
            cell.alpha = cellViewModel.appearance.alpha
        }
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        viewModel.shouldHighlightItem(at: indexPath)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedCellViewModel = viewModel.cellViewModel(at: indexPath) else { return }

        guard let cell = tableView.cellForRow(at: indexPath) else { return }

        delegate?.perform(action: .inspect(preferredPanel: .children), with: selectedCellViewModel.element, from: cell)
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard
            indexPath != .first,
            let cellViewModel = viewModel.cellViewModel(at: indexPath)
        else {
            return nil
        }

        return .contextMenuConfiguration(
            initialMenus: {
                guard cellViewModel.element.isContainer else { return [] }

                return [
                    UIMenu(
                        title: "",
                        image: .none,
                        identifier: .none,
                        options: .displayInline,
                        children: [
                            UIAction.collapseAction(
                                cellViewModel.isCollapsed,
                                expandTitle: "Reveal Children",
                                collapseTitle: "Collapse Children"
                            ) { [weak self] _ in
                                self?.toggleCollapse(at: indexPath)
                            }
                        ]
                    )
                ]
            }(),
            with: cellViewModel.element
        ) { [weak self] element, action in
            guard let cell = tableView.cellForRow(at: indexPath) else { return }
            self?.delegate?.perform(action: action, with: element, from: cell)
        }
    }
}

// MARK: - Helpers

extension ElementChildrenPanelViewController {
    func updateTableView(_ indexPath: IndexPath, with actions: [ElementChildrenPanelAction]) {
        guard actions.isEmpty == false else { return }

        let tableView = viewCode.tableView

        if let cell = tableView.cellForRow(at: indexPath) as? ElementChildrenPanelTableViewCodeCell {
            cell.toggleCollapse(animated: true)
        }

        tableView.performBatchUpdates {
            actions.forEach { action in
                switch action {
                case let .inserted(insertedIndexPaths):
                    insertedIndexPaths.forEach { insertedIndexPath in
                        self.viewModel.cellViewModel(at: insertedIndexPath)?.animatedDisplay = true
                    }
                    tableView.insertRows(at: insertedIndexPaths, with: .top)

                case let .deleted(deletedIndexPaths):
                    tableView.animate {
                        deletedIndexPaths.forEach { deletedIndexPath in
                            guard let cell = tableView.cellForRow(at: deletedIndexPath) else { return }

                            cell.contentView.alpha = 0
                            cell.transform = self.elementInspectorAppearance.panelInitialTransform
                            cell.backgroundColor = .none
                        }
                    }
                    tableView.deleteRows(at: deletedIndexPaths, with: .top)
                }
            }
        } completion: { [weak self] _ in
            self?.updateVisibleRowsBackgroundColor()
        }
    }

    func updateVisibleRowsBackgroundColor() {
        UIView.animate(
            withDuration: .average,
            animations: { [weak self] in

                self?.viewCode.tableView.indexPathsForVisibleRows?.forEach { indexPath in
                    guard let cell = self?.viewCode.tableView.cellForRow(at: indexPath) as? ElementChildrenPanelTableViewCodeCell else {
                        return
                    }

                    cell.isEvenRow = indexPath.isEvenRow
                }
            }
        )
    }
}
