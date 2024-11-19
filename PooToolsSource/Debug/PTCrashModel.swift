//
//  PTCrashModel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

struct PTCrashModel: Codable, Equatable {
    let type: PTCrashType
    let details: Details
    let context: Context
    let traces: [Trace]

    init(
        type: PTCrashType,
        details: Details,
        context: Context = .builder(),
        traces: [Trace]
    ) {
        self.type = type
        self.details = details
        self.context = context
        self.traces = traces
    }

    static func == (lhs: PTCrashModel, rhs: PTCrashModel) -> Bool {
        lhs.details.name == rhs.details.name
    }
}

extension PTCrashModel {
    struct Details: Codable {
        let name: String
        let date: Date
        let appVersion: String?
        let appBuild: String?
        let iosVersion: String
        let deviceModel: String
        let reachability: String

        @MainActor static func builder(name: String) -> Self {
            .init(
                name: name,
                date: .init(),
                appVersion: PTDebugUserInfo.getAppVersionInfo()?.detail,
                appBuild: PTDebugUserInfo.getAppBuildInfo()?.detail,
                iosVersion: PTDebugUserInfo.getIOSVersionInfo().detail,
                deviceModel: PTDebugUserInfo.getDeviceModelInfo().detail,
                reachability: PTDebugUserInfo.getReachability().detail
            )
        }
    }
}

extension PTCrashModel {
    struct Context: Codable {
        let image: Data?
        let consoleOutput: String
        let errorOutput: String

        var uiImage: UIImage? {
            guard let image else { return nil }
            return UIImage(data: image)
        }

        static func builder() -> Self {
            .init(image: UIWindow.keyWindow?._snapshotWithTouch?.pngData(), consoleOutput: "", errorOutput: "")
        }
    }
}

extension PTCrashModel {
    struct Trace: Codable {
        let title: String
        let detail: String

        var info: PTDebugUserInfo.Info {
            .init(title: title, detail: detail)
        }
    }
}

extension [PTCrashModel.Trace] {
    static func builder(_ stack: [String]) -> [PTCrashModel.Trace] {
        var traces = [PTCrashModel.Trace]()

        for symbol in stack {
            let trace = PTCrashModel.Trace(title: symbol, detail: "")
            traces.append(trace)
        }

        return traces
    }
}
