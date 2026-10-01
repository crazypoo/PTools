//
//  PTNetworkViewModel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

// English: PTRows still accepts NSObject data models, so this box carries only the value summary.
// Español: PTRows todavía acepta modelos NSObject; esta caja transporta únicamente el resumen de valor.
// 中文：PTRows 仍接收 NSObject 数据模型，因此用这个盒子只承载值类型摘要。
@MainActor
final class PTNetworkSummaryBox: NSObject {
    let value: PTNetworkCaptureSummary

    init(value: PTNetworkCaptureSummary) {
        self.value = value
        super.init()
    }
}

// English: The watcher keeps summaries and IDs only; full records stay in the capture actor.
// Español: El watcher conserva solo resúmenes e IDs; los registros completos permanecen en el actor de captura.
// 中文：监控列表只保存摘要和 ID，完整记录继续由抓包 Actor 持有。
@MainActor
final class PTNetworkViewModel {

    var reachEnd = true
    var firstIn = true
    var reloadDataFinish = true
    var networkSearchWord = ""

    private(set) var recordIDs: [UUID] = []
    private(set) var filteredRecordIDs: [UUID] = []
    private(set) var summaryByID: [UUID: PTNetworkCaptureSummary] = [:]

    var summaries: [PTNetworkCaptureSummary] {
        filteredRecordIDs.compactMap { summaryByID[$0] }
    }

    func refresh() async {
        let values = await PTNetworkCaptureStore.shared.summaries()
        summaryByID = Dictionary(uniqueKeysWithValues: values.map { ($0.id, $0) })
        recordIDs = values.map(\.id)
        applyFilter()
    }

    func applyFilter() {
        let keyword = networkSearchWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else {
            filteredRecordIDs = recordIDs
            return
        }

        let filter = PTNetworkCaptureFilter(keyword: keyword)
        filteredRecordIDs = recordIDs.filter { id in
            guard let summary = summaryByID[id] else { return false }
            return filter.matches(summary)
        }
    }

    func handleClearAction() async {
        await PTNetworkCaptureStore.shared.clear()
        summaryByID.removeAll(keepingCapacity: true)
        recordIDs.removeAll(keepingCapacity: true)
        filteredRecordIDs.removeAll(keepingCapacity: true)
        PTHttpDatasource.shared.removeAll()
    }
}
