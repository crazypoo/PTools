//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension InspectorViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRows(in: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = {
            switch viewModel.cellViewModelForRow(at: indexPath) {
            case let .action(cellViewModel):
                let cell = tableView.dequeueReusableCell(HierarchyInspectorActionTableViewCell.self, for: indexPath)
                cell.viewModel = cellViewModel
                return cell

            case let .element(cellViewModel):
                let cell = tableView.dequeueReusableCell(HierarchyInspectorReferenceSummaryTableViewCell.self, for: indexPath)
                cell.viewModel = cellViewModel
                return cell
            }

        }()

        cell.isSelected = tableView.indexPathForSelectedRow == indexPath
        return cell
    }
}
