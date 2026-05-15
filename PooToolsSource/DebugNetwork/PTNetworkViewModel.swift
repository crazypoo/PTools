//
//  PTNetworkViewModel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

// MARK: - 主列表视图模型
@MainActor
final class PTNetworkViewModel {

    var reachEnd = true
    var firstIn = true
    var reloadDataFinish = true

    // 动态同步底层安全的模型列表副本
    var models = PTHttpDatasource.shared.httpModels
    var cacheModels = [PTHttpModel]()
    var searchModels = [PTHttpModel]()

    var networkSearchWord = ""

    func applyFilter() {
        // 安全抓取最新快照
        cacheModels = PTHttpDatasource.shared.httpModels
        searchModels = cacheModels

        if networkSearchWord.isEmpty {
            models = cacheModels
        } else {
            let searchLower = networkSearchWord.lowercased()
            searchModels = searchModels.filter {
                $0.url?.absoluteString.lowercased().contains(searchLower) == true ||
                $0.statusCode?.lowercased().contains(searchLower) == true ||
                $0.endTime?.lowercased().contains(searchLower) == true
            }
            models = searchModels
        }
    }

    func handleClearAction() {
        // 调用重构后线程安全的数据源清空接口
        PTHttpDatasource.shared.removeAll()
        models.removeAll()
    }
}
