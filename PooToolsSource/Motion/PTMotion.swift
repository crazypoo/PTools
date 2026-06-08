//
//  PTMotion.swift
//  PooTools_Example
//
//  Created by jax on 2022/8/31.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
@preconcurrency import CoreMotion

// MARK: - 数据模型
public struct PTMotionData: Sendable {
    // 基础计步
    public var stepCount: Int = 0
    public var distance: Double = 0.0          // 距离 (米)
    
    // 进阶运动数据
    public var currentPace: Double = 0.0       // 配速 (秒/米)
    public var currentCadence: Double = 0.0    // 步频 (步/秒)
    
    // 爬楼与海拔 (利用气压计和协处理器)
    public var floorsAscended: Int = 0         // 上楼层数
    public var floorsDescended: Int = 0        // 下楼层数
    public var relativeAltitude: Double = 0.0  // 相对高度变化 (米)
    public var pressure: Double = 0.0          // 环境气压 (千帕 kPa)
    
    // 状态与置信度
    public var confidence: String = "Unknown"
    public var status: String = "Unknown"
    
    // 自动启停侦测
    public var isWalkingPaused: Bool = false   // 侦测用户是否临时停下脚步
    
    // 🌟 新增：G 值与姿态数据
    public var gForceX: Double = 0.0 // 左右 G 值 (转弯)
    public var gForceY: Double = 0.0 // 前后 G 值 (加减速)
    public var pitch: Double = 0.0   // 俯仰角 (坡度度数)
    public var roll: Double = 0.0    // 侧倾角 (左右倾斜度数)
}

public typealias PTMotionBlock = (_ data: PTMotionData) -> Void

@objcMembers
public class PTMotion: NSObject, @unchecked Sendable {

    public static let shared = PTMotion()
    
    public var motionBlock: PTMotionBlock?
    
    private let operationQueue = OperationQueue()
    private let pedometer = CMPedometer()
    private let activityManager = CMMotionActivityManager()
    private let altimeter = CMAltimeter() // 新增：气压高度计
    
    private let motionManager = CMMotionManager() // 新增核心传感器
    
    // 实例化一个内部数据模型，作为唯一的数据源头
    private var currentData = PTMotionData()
    
    private override init() {
        super.init()
    }

    // MARK: - Start Motion Tracking
    @MainActor public func startMotion(from startDate: Date = Date()) {
        guard CMPedometer.isStepCountingAvailable(), CMMotionActivityManager.isActivityAvailable() else {
            let msg = "哎喲，不能運行哦，僅支持 M7 以上處理器，暫時只能在 iPhone5s 以上使用。"
            // 假设这是你的弹窗工具：
            // UIAlertController.base_alertVC(msg: msg, showIn: PTUtils.getCurrentVC(), moreBtn: nil)
            PTNSLogConsole(msg)
            return
        }

        // 启动所有传感器
        startPedometer(from: startDate)
        startActivityUpdates()
        startAltimeterUpdates()
        startPedometerEventUpdates()
        startDeviceMotionUpdates() // 启动车身感应
    }

    // MARK: - Stop Motion Tracking
    public func stopMotion() {
        pedometer.stopUpdates()
        pedometer.stopEventUpdates() // 停止事件侦测
        activityManager.stopActivityUpdates()
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.stopRelativeAltitudeUpdates() // 停止气压计
        }
        motionManager.stopDeviceMotionUpdates()
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

    // MARK: - Private Methods: Sensors
    
    private func startPedometer(from date: Date) {
        pedometer.startUpdates(from: date) { [weak self] pedometerData, error in
            guard let self = self, let data = pedometerData, error == nil else { return }
            
            self.currentData.stepCount = data.numberOfSteps.intValue
            self.currentData.distance = data.distance?.doubleValue ?? 0.0
            self.currentData.currentPace = data.currentPace?.doubleValue ?? 0.0
            self.currentData.currentCadence = data.currentCadence?.doubleValue ?? 0.0 // 新增步频
            self.currentData.floorsAscended = data.floorsAscended?.intValue ?? 0
            self.currentData.floorsDescended = data.floorsDescended?.intValue ?? 0
            
            self.triggerCallback()
        }
    }

    private func startActivityUpdates() {
        activityManager.startActivityUpdates(to: operationQueue) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            
            self.currentData.confidence = self.confidenceString(from: activity.confidence)
            self.currentData.status = self.statusDescription(from: activity)
            
            self.triggerCallback()
        }
    }
    
    // 新增：启动气压和海拔侦测
    private func startAltimeterUpdates() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else { return }
        
        altimeter.startRelativeAltitudeUpdates(to: operationQueue) { [weak self] altitudeData, error in
            guard let self = self, let data = altitudeData, error == nil else { return }
            
            self.currentData.relativeAltitude = data.relativeAltitude.doubleValue
            self.currentData.pressure = data.pressure.doubleValue
            
            self.triggerCallback()
        }
    }
    
    // 新增：侦测运动是否暂停或恢复
    private func startPedometerEventUpdates() {
        guard CMPedometer.isPedometerEventTrackingAvailable() else { return }
        
        pedometer.startEventUpdates { [weak self] event, error in
            guard let self = self, let event = event, error == nil else { return }
            
            // 当用户停下脚步休息时，会收到 .pause；重新走动时会收到 .resume
            DispatchQueue.main.async {
                self.currentData.isWalkingPaused = (event.type == .pause)
                self.triggerCallback()
            }
        }
    }
    
    // MARK: - Data Dispatch
    
    private func triggerCallback() {
        // 确保回调一定在主线程触发，方便外部直接更新 UI
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.motionBlock?(self.currentData)
        }
    }

    // MARK: - Helpers
    
    private func statusDescription(from activity: CMMotionActivity) -> String {
        var states: [String] = []

        if activity.stationary { states.append("Not Moving") }
        if activity.walking { states.append("Walking") }
        if activity.running { states.append("Running") }
        if activity.automotive { states.append("In a Vehicle") }
        if activity.cycling { states.append("Cycling") }

        if activity.unknown || states.isEmpty { states.append("Unknown") }

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
    
    // 🌟 核心：获取 G 值与车身姿态
    private func startDeviceMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        // 极客建议：UI 动画 30Hz 足矣，60Hz 会导致设备发热严重
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        
        motionManager.startDeviceMotionUpdates(to: operationQueue) { [weak self] motion, error in
            guard let self = self, let motion = motion, error == nil else { return }
            
            // 1. 获取纯净的 G 值 (userAcceleration 已经剔除了地球重力的 1G 干扰)
            self.currentData.gForceX = motion.userAcceleration.x
            self.currentData.gForceY = motion.userAcceleration.y
            
            // 2. 获取车身倾角 (系统给的是弧度 Radian，我们需要转成度数 Degree 方便显示)
            self.currentData.pitch = motion.attitude.pitch * 180 / .pi
            self.currentData.roll = motion.attitude.roll * 180 / .pi
            
            // 回调更新 UI (因为是 30Hz 高频，确保外部 UI 使用轻量级动画)
            self.triggerCallback()
        }
    }
}
