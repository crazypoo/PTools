//
//  PTDebugUserInfo.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import DeviceKit

enum PTDebugUserInfo {

    struct Info {
        let title: String
        let detail: String
    }

    static var infos: [Info] {
        [
            getAppVersionInfo(),
            getAppBuildInfo(),
            getBundleName(),
            getBundleId(),
            getScreenResolution(),
            getDeviceModelInfo(),
            getIOSVersionInfo(),
            getMeasureAppStartUpTime(),
            getReachability()
        ].compactMap { $0 }
    }

    static func getAppVersionInfo() -> Info? {
        guard let version = kAppVersion else {
            return nil
        }

        return Info(title: "App version", detail: "\(version)")
    }

    static func getAppBuildInfo() -> Info? {
        guard let build = kAppBuildVersion
        else {
            return nil
        }

        return Info(title: "Build version", detail: "Build: \(build)")
    }

    static func getBundleName() -> Info? {
        guard let bundleName = kAppName else {
            return nil
        }

        return Info(title: "Bundle name", detail: "\(bundleName)")
    }

    static func getBundleId() -> Info? {
        guard let bundleID = kAppBundleId else {
            return nil
        }

        return Info(title: "Bundle id", detail: "\(bundleID)")
    }

    static func getScreenResolution() -> Info {
        let screen = UIScreen.main
        let bounds = screen.bounds
        let scale = screen.scale

        let screenWidth = bounds.size.width * scale
        let screenHeight = bounds.size.height * scale

        return .init(title: "Screen resolution", detail: "\(screenWidth) x \(screenHeight) points")
    }

    static func getDeviceModelInfo() -> Info {
        let deviceModel = Device.current.model ?? "Unknow"
        return Info(title: "Device model", detail: deviceModel)
    }

    static func getIOSVersionInfo() -> Info {
        let iOSVersion = UIDevice.current.systemVersion
        return Info(title: "ios version", detail: iOSVersion)
    }

    static func getMeasureAppStartUpTime() -> Info? {
        guard let launchStartTime = PTLaunchTimeTracker.launchStartTime else { return nil }

        return Info(title: "Inicialization time",detail: String(format: "%.4lf%", launchStartTime) + " (s)")
    }

    static func getReachability() -> Info {        
        return Info(title: "reachability status",detail: LocalConsole.shared.networkStatus)
    }
}
