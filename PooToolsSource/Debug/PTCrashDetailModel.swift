//
//  PTCrashDetailModel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import UIKit
import SwiftDate

final class PTCrashDetailModel: NSObject {

    private(set) var data: PTCrashModel

    init(data: PTCrashModel) {
        self.data = data
    }

    // MARK: - ViewModel

    func viewTitle() -> String {
        "actions-crash".localized()
    }

    func numberOfItems(section: Int) -> Int {
        switch PTCrashDetailViewController.Features(rawValue: section) {
        case .details:
            return details.count
        case .context:
            return contexts.count
        case .stackTrace:
            return data.traces.count
        default:
            return .zero
        }
    }

    var details: [PTDebugUserInfo.Info] {
        [
            .init(title: "Error", detail: data.type.rawValue),
            .init(title: "Date", detail: data.details.date.dateFormat(formatString: "yyyy-MM-dd HH:mm:ss")),
            .init(title: "App version", detail: data.details.appVersion ?? ""),
            .init(title: "Build version", detail: data.details.appBuild ?? ""),
            .init(title: "iOS version",detail: data.details.iosVersion),
            .init(title: "Device model", detail: data.details.deviceModel),
            .init(title: "Reachability status", detail: data.details.reachability),
            .init(title: "Error".localized(), detail: data.details.name)
        ]
    }

    var contexts: [PTDebugUserInfo.Info] {
        var infos = [PTDebugUserInfo.Info]()
        if data.context.uiImage != nil {
            infos.append(.init(title: "Snapshot", detail: ""))
        }

        if !data.context.consoleOutput.isEmpty {
            infos.append(.init(title: "Logs", detail: ""))
        }

        if !data.context.errorOutput.isEmpty {
            infos.append(.init(title: "Error log", detail: ""))
        }

        return infos
    }

    func dataSourceForItem(_ indexPath: IndexPath) -> PTDebugUserInfo.Info? {
        switch PTCrashDetailViewController.Features(rawValue: indexPath.section) {
        case .details:
            return details[indexPath.row]
        case .context:
            return contexts[indexPath.row]
        case .stackTrace:
            return data.traces[indexPath.row].info
        default:
            return nil
        }
    }

    func getAllValues() -> String {
        var result = "network-details-title".localized() + ":\n"
        for detail in details {
            result += "\(detail.title): \(detail.detail)\n"
        }

        result += "\nStack Trace:\n"
        for trace in data.traces {
            result += "\(trace.info)\n"
        }

        return result
    }
}
