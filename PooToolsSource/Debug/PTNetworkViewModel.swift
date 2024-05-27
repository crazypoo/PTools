//
//  PTNetworkViewModel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

final class PTNetworkViewModel {

    var reachEnd = true
    var firstIn = true
    var reloadDataFinish = true

    var models = PTHttpDatasource.shared.httpModels
    var cacheModels = [PTHttpModel]()
    var searchModels = [PTHttpModel]()

    var networkSearchWord = ""

    func applyFilter() {
        cacheModels = PTHttpDatasource.shared.httpModels
        searchModels = cacheModels

        if networkSearchWord.isEmpty {
            models = cacheModels
        } else {
            searchModels = searchModels.filter {
                $0.url?.absoluteString.lowercased().contains(networkSearchWord.lowercased()) == true ||
                    $0.statusCode?.lowercased().contains(networkSearchWord.lowercased()) == true ||
                    $0.endTime?.lowercased().contains(networkSearchWord.lowercased()) == true
            }

            models = searchModels
        }
    }

    func handleClearAction() {
        PTHttpDatasource.shared.removeAll()
        models.removeAll()
    }
}
