//
//  PTLeakViewModel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

class PTLeakViewModel: NSObject {
    
    private var data: [PTPerformanceLeakDetector.LeakModel] {
        PTPerformanceLeakDetector.leaks
    }

    var filteredInfo = [PTPerformanceLeakDetector.LeakModel]()

    var leakSearchWord = ""

    func applyFilter() {
        if leakSearchWord.isEmpty {
            filteredInfo = data
        } else {
            filteredInfo = data.filter {
                $0.details.localizedCaseInsensitiveContains(leakSearchWord)
            }
        }
    }
    
    func handleClearAction() {
        PTPerformanceLeakDetector.leaks.removeAll()
        filteredInfo.removeAll()
    }
}
