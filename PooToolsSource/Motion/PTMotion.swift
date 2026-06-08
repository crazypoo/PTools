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
    public var gForceZ: Double = 0.0 // 上下颠簸 G 值 (非铺装路面震动)
    public var gForceX: Double = 0.0 // 左右 G 值 (转弯)
    public var gForceY: Double = 0.0 // 前后 G 值 (加减速)
    public var pitch: Double = 0.0   // 俯仰角 (坡度度数)
    public var roll: Double = 0.0    // 侧倾角 (左右倾斜度数)
    
    public var maxLeftLean: Double = 0.0       // 历史最大左压弯角度 (正数)
    public var maxRightLean: Double = 0.0      // 历史最大右压弯角度 (正数)
    
    public var isTipOverDetected: Bool = false  // 是否侦测到倒车/摔车事故
    public var altitudeAlertMessage: String? = nil // 海拔突变预警提示语 (为 nil 表示正常)
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
    
    public var currentSpeedKmh: Double = 0.0
    
    // 🌟 用于计算海拔变动率的历史队列 (缓存最近 30 秒的数据)
    private var altitudeHistory: [(time: Date, altitude: Double)] = []

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
        // 🌟 启动机车姿态感应
        startBikeOrientationUpdates()
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
        
    // 🌟 新增：手动重置压弯极限数据
    public func resetLeanAngles() {
        currentData.maxLeftLean = 0.0
        currentData.maxRightLean = 0.0
        currentData.isTipOverDetected = false
        triggerCallback()
    }

    // MARK: - 核心功能 1 & 2：压弯与摔车侦测
    private func startBikeOrientationUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        // 机车动态瞬息万变，采用 30Hz 高频采样
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager.startDeviceMotionUpdates(to: operationQueue) { [weak self] motion, error in
            guard let self = self, let motion = motion, error == nil else { return }
            
            self.currentData.gForceX = motion.userAcceleration.x
            self.currentData.gForceY = motion.userAcceleration.y
            self.currentData.gForceZ = motion.userAcceleration.z
            
            self.currentData.pitch = motion.attitude.pitch * 180 / .pi
            // 1. 计算当前倾角 (将弧度转换为角度)
            // 默认手机竖直固定在车把上时，roll 代表左右倾斜
            let rollDegrees = motion.attitude.roll * 180.0 / .pi
            self.currentData.roll = rollDegrees
            
            // 2. 统计左右极限压弯角度 (剔除超过60度的异常摔车角度)
            if rollDegrees < 0 {
                // 左压弯 (roll 为负数)
                let leftAngle = abs(rollDegrees)
                if leftAngle > self.currentData.maxLeftLean && leftAngle < 60.0 {
                    self.currentData.maxLeftLean = leftAngle
                }
            } else {
                // 右压弯 (roll 为正数)
                let rightAngle = rollDegrees
                if rightAngle > self.currentData.maxRightLean && rightAngle < 60.0 {
                    self.currentData.maxRightLean = rightAngle
                }
            }
            
            // 3. 核心功能 2：摔车/倒车侦测
            // 逻辑：如果车速极低或静止(<5km/h)，且车身倾角绝度值超过 55 度，判定为非正常骑行姿态（倒地）
            if self.currentSpeedKmh < 5.0 && abs(rollDegrees) > 55.0 {
                self.currentData.isTipOverDetected = true
            } else {
                // 如果车速起来了或者重新扶起，解除报警
                if abs(rollDegrees) < 30.0 {
                    self.currentData.isTipOverDetected = false
                }
            }
            
            self.triggerCallback()
        }
    }

    // MARK: - 核心功能 3：气压与海拔突变预警
    private func startAltimeterUpdates() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else { return }
        
        altimeter.startRelativeAltitudeUpdates(to: operationQueue) { [weak self] altitudeData, error in
            guard let self = self, let data = altitudeData, error == nil else { return }
            
            let relativeAlt = data.relativeAltitude.doubleValue
            self.currentData.relativeAltitude = relativeAlt
            self.currentData.pressure = data.pressure.doubleValue
            
            // 🌟 爬升率计算算法：
            let now = Date()
            self.altitudeHistory.append((time: now, altitude: relativeAlt))
            
            // 清理掉超过 30 秒前的历史数据，保持队列轻量
            self.altitudeHistory = self.altitudeHistory.filter { now.timeIntervalSince($0.time) <= 30.0 }
            
            if let firstRecord = self.altitudeHistory.first {
                let heightDifference = relativeAlt - firstRecord.altitude
                let timeDifference = now.timeIntervalSince(firstRecord.time)
                
                if timeDifference > 5.0 { // 至少积累了 5 秒的数据才开始评估
                    // 如果 30 秒内爬升超过 15 米（换算算成车速相当于在极陡的盘山公路上狂飙爬升）
                    if heightDifference > 15.0 {
                        self.currentData.altitudeAlertMessage = "⛰️ 海拔急速爬升中，注意防风降温与胎压变化"
                    } else if heightDifference < -15.0 {
                        self.currentData.altitudeAlertMessage = "📉 正在急速下山，注意控制刹车热衰减"
                    } else {
                        self.currentData.altitudeAlertMessage = nil // 恢复正常
                    }
                }
            }
            
            self.triggerCallback()
        }
    }
}
