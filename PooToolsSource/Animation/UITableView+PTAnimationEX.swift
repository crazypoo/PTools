//
//  UITableView+PTAnimationEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/26.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public extension UITableView {

    func visibleCells(in section: Int) -> [UITableViewCell] {
        visibleCells.filter({
            indexPath(for: $0)?.section == section
        })
    }
}
