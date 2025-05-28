//
//  PTMotion.swift
//  PooTools_Example
//
//  Created by jax on 2022/8/31.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import CoreMotion

public typealias PTMotionBlock = (_ step: Int, _ confidence: String, _ status: String) -> Void

@objcMembers
public class PTMotion: NSObject {

    public static let shared = PTMotion()
    
    public var motionBlock: PTMotionBlock?
    
    private let operationQueue = OperationQueue()
    private let pedometer = CMPedometer()
    private let activityManager = CMMotionActivityManager()
    private var stepCount: Int = 0
    
    private override init() {
        super.init()
    }

    // MARK: - Start Motion Tracking
    public func startMotion(from startDate: Date = Date()) {
        guard CMPedometer.isStepCountingAvailable(), CMMotionActivityManager.isActivityAvailable() else {
            let msg = "哎喲，不能運行哦，僅支持 M7 以上處理器，暫時只能在 iPhone5s 以上使用。"
            UIAlertController.base_alertVC(msg: msg, showIn: PTUtils.getCurrentVC(), moreBtn: nil)
            return
        }

        startPedometer(from: startDate)
        startActivityUpdates()
    }

    // MARK: - Stop Motion Tracking
    public func stopMotion() {
        pedometer.stopUpdates()
        activityManager.stopActivityUpdates()
    }

    // MARK: - Authorization Check (iOS 11+)
    public func checkAuthorizationStatus() -> Bool {
        if #available(iOS 11.0, *) {
            let status = CMPedometer.authorizationStatus()
            switch status {
            case .authorized: return true
            case .notDetermined, .restricted, .denied: return false
            @unknown default: return false
            }
        } else {
            return true
        }
    }

    // MARK: - Private Methods
    private func startPedometer(from date: Date) {
        pedometer.startUpdates(from: date) { [weak self] pedometerData, error in
            guard let self = self, let data = pedometerData, error == nil else { return }
            self.stepCount = data.numberOfSteps.intValue
        }
    }

    private func startActivityUpdates() {
        activityManager.startActivityUpdates(to: operationQueue) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            PTGCDManager.gcdMain {
                let confidence = self.confidenceString(from: activity.confidence)
                let status = self.statusDescription(from: activity)
                self.motionBlock?(self.stepCount, confidence, status)
            }
        }
    }

    private func statusDescription(from activity: CMMotionActivity) -> String {
        var states: [String] = []

        if activity.stationary {
            states.append("Not Moving")
        }
        if activity.walking {
            states.append("Walking")
        }
        if activity.running {
            states.append("Running")
        }
        if activity.automotive {
            states.append("In a Vehicle")
        }

        if activity.unknown || states.isEmpty {
            states.append("Unknown")
        }

        return states.joined(separator: ", ")
    }

    private func confidenceString(from confidence: CMMotionActivityConfidence) -> String {
        switch confidence {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        @unknown default: return "Unknown"
        }
    }
}
