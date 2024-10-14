//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension ElementChildrenPanelViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(ElementChildrenPanelTableViewCodeCell.self, for: indexPath)
        cell.viewModel = viewModel.cellViewModel(at: indexPath)
        cell.isEvenRow = indexPath.isEvenRow
        cell.isFirst = indexPath.isFirst
        cell.delegate = self
        return cell
    }

    func toggleCollapse(at indexPath: IndexPath) {
        let actions = viewModel.toggleContainer(at: indexPath)
        updateTableView(indexPath, with: actions)
    }
}

extension ElementChildrenPanelViewController: ElementChildrenPanelTableViewCodeCellDelegate {
    func elementChildrenPanelTableViewCodeCellDidToggleCollapse(_ cell: ElementChildrenPanelTableViewCodeCell) {
        guard let indexPath = viewModel.indexPath(for: cell.viewModel) else { return }
        toggleCollapse(at: indexPath)
    }
}
