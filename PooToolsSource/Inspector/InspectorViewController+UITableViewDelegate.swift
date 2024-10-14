//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension InspectorViewController: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard
            let firstVisibleSection = viewCode.tableView.indexPathsForVisibleRows?.first?.section,
            let headerView = viewCode.tableView.headerView(forSection: firstVisibleSection)
        else {
            return
        }

        for cell in viewCode.tableView.visibleCells {
            guard let cell = cell as? HierarchyInspectorTableViewCell else { continue }

            let headerHeight: CGFloat = headerView.frame.height

            let hiddenFrameHeight = scrollView.contentOffset.y + headerHeight - cell.frame.origin.y

            if hiddenFrameHeight >= 0 || hiddenFrameHeight <= cell.frame.size.height {
                cell.maskFromTop(margin: max(0, hiddenFrameHeight))
            }
            else {
                break
            }
        }
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        viewModel.isRowEnabled(at: indexPath) ? indexPath : nil
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(HierarchyInspectorTableViewHeaderView.self)
        header.title = viewModel.titleForHeader(in: section)
        header.showSeparatorView = section > .zero
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if viewModel.titleForHeader(in: section).isNilOrEmpty {
            return viewCode.elementInspectorAppearance.verticalMargins
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        viewCode.elementInspectorAppearance.verticalMargins
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let command = viewModel.selectRow(at: indexPath)
        delegate?.inspectorViewController(self, didSelect: command)
    }
}
