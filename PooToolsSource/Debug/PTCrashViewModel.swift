//
//  PTCrashViewModel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import UIKit
import SwiftDate

final class PTCrashViewModel: NSObject {

    var data: [PTCrashModel] {
        (
            PTCrashManager.recover(ofType: .nsexception) +
                PTCrashManager.recover(ofType: .signal)
        ).sorted(by: { $0.details.date > $1.details.date })
    }

    // MARK: - ViewModel

    func viewTitle() -> String {
        "Crash"
    }

    func numberOfItems() -> Int {
        data.count
    }

    func dataSourceForItem(atIndex index: Int) -> (title: String, value: String) {
        let trace = data[index]
        return (
            title: trace.details.name,
            value: "\n     \(trace.details.date.dateFormat(formatString:"yyyy-MM-dd HH:mm:ss"))"
        )
    }

    func handleClearAction() {
        PTCrashManager.deleteAll(ofType: .nsexception)
        PTCrashManager.deleteAll(ofType: .signal)
    }

    func handleDeleteItemAction(atIndex index: Int) {
        let crash = data[index]
        PTCrashManager.delete(crash: crash)
    }

    func emptyListDescriptionString() -> String {
       "Empty data" + viewTitle()
    }
}
