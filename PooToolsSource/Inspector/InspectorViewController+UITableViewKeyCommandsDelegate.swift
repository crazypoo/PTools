//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

// MARK: - UITableViewKeyCommandsDelegate

extension InspectorViewController: UITableViewKeyCommandsDelegate {
    func tableViewDidBecomeFirstResponder(_ tableView: UIKeyCommandTableView) {
        addSearchKeyCommandListeners()
    }

    func tableViewDidResignFirstResponder(_ tableView: UIKeyCommandTableView) {
        tableView.indexPathsForSelectedRows?.forEach {
            tableView.deselectRow(at: $0, animated: false)
        }
        removeSearchKeyCommandListeners()

        guard isFinishing == false else { return }

        viewCode.searchView.becomeFirstResponder()
    }

    func tableViewKeyCommandSelectionBelowBounds(_ tableView: UIKeyCommandTableView) -> UIKeyCommandTableView.OutOfBoundsBehavior {
        .resignFirstResponder
    }

    func tableViewKeyCommandSelectionAboveBounds(_ tableView: UIKeyCommandTableView) -> UIKeyCommandTableView.OutOfBoundsBehavior {
        .resignFirstResponder
    }
}
