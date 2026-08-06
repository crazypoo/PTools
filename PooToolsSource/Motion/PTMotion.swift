//
//  PTMotion.swift
//  PooTools_Example
//
//  Created by jax on 2022/8/31.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
@preconcurrency import CoreMotion

public enum PTMotionDataSource: String, Sendable {
    case iphone = "📱"
    case airpods = "🎧"
}

// MARK: - 数据模型
public struct PTMotionData: Sendable {
    public var currentDataSource: PTMotionDataSource = .iphone
    
    // --- 基础计步与运动状态 (仅 iPhone 支持) ---
    public var stepCount: Int = 0
    public var distance: Double = 0.0
    public var currentPace: Double = 0.0
    public var currentCadence: Double = 0.0
    public var isWalkingPaused: Bool = false
    public var confidence: String = "Unknown"
    public var status: String = "Unknown"
    
    // --- 爬楼与海拔预警 (仅 iPhone 支持) ---
    public var floorsAscended: Int = 0
    public var floorsDescended: Int = 0
    public var relativeAltitude: Double = 0.0
    public var pressure: Double = 0.0
    public var altitudeAlertMessage: String? = nil
    
    // --- 🌟 核心姿态与机车动态 (智能切换：AirPods / iPhone) ---
    // G 值
    public var gForceX: Double = 0.0
    public var gForceY: Double = 0.0
    public var gForceZ: Double = 0.0
    
    // 欧拉角 (压弯与俯仰)
    public var pitch: Double = 0.0
    public var roll: Double = 0.0
    public var yaw: Double = 0.0
    
    // 机车硬核统计
    public var maxLeftLean: Double = 0.0
    public var maxRightLean: Double = 0.0
    public var isTipOverDetected: Bool = false
    
    // 极客进阶数据 (AirPods 优势领域)
    public var rotX: Double = 0.0 // 角速度
    public var rotY: Double = 0.0
    public var rotZ: Double = 0.0
    public var gravX: Double = 0.0 // 重力矢量
    public var gravY: Double = 0.0
    public var gravZ: Double = 0.0
    public var quatX: Double = 0.0 // 四元数
    public var quatY: Double = 0.0
    public var quatZ: Double = 0.0
    public var quatW: Double = 0.0
    
    public var sensorLocation: CMDeviceMotion.SensorLocation? = nil
}

public protocol PTMotionDelegate: AnyObject {
    /// 任何数据发生变化时，都会抛出这个完整的超级数据包
    func motionManager(_ manager: PTMotion, didUpdateData data: PTMotionData)
    
    /// 仅在数据源 (iPhone <-> AirPods) 发生切换时回调，用于更新 UI 图标
    func motionManager(_ manager: PTMotion, didChangeDataSource source: PTMotionDataSource)
}

public extension PTMotionDelegate {
    func motionManager(_ manager: PTMotion, didChangeDataSource source: PTMotionDataSource) {}
}

@objcMembers
public class PTMotion: NSObject, @unchecked Sendable,CMHeadphoneMotionManagerDelegate {
    
    public static let shared = PTMotion()
    
    private class WeakDelegateWrapper {
        weak var delegate: PTMotionDelegate?
        init(_ delegate: PTMotionDelegate) { self.delegate = delegate }
    }
    private var delegates: [WeakDelegateWrapper] = []
    
    // --- 传感器矩阵 ---
    private let operationQueue = OperationQueue()
    private let pedometer = CMPedometer()
    private let activityManager = CMMotionActivityManager()
    private let altimeter = CMAltimeter() // 新增：气压高度计
    private let phoneManager = CMMotionManager()             // 手机主控
    private let headphoneManager = CMHeadphoneMotionManager() // 耳机主控
    
    // --- 数据源头与状态缓存 ---
    public private(set) var currentData = PTMotionData()
    public var currentSpeedKmh: Double = 0.0
    public var motionStarted:Bool = false
    
    // --- 压弯与摔车算法缓存 ---
    private var altitudeHistory: [(time: Date, altitude: Double)] = []
    private var lastImpactTime: Date?
    private let crashGForceThreshold: Double = 3.0
    private var referenceRoll: Double = 0.0
    private var smoothedRoll: Double = 0.0
    private let lowPassFactor: Double = 0.15
    
    private override init() {
        super.init()
        headphoneManager.delegate = self // 监听耳机断开/连接
    }
    
    // MARK: - 代理管理
    public func addDelegate(_ delegate: PTMotionDelegate) {
        delegates.removeAll { $0.delegate == nil }
        if !delegates.contains(where: { $0.delegate === delegate }) {
            delegates.append(WeakDelegateWrapper(delegate))
            // 立即推送一次当前状态
            delegate.motionManager(self, didChangeDataSource: currentData.currentDataSource)
        }
    }
    
    public func calibrateZeroPoint() {
        let activeMotion = currentData.currentDataSource == .airpods ? headphoneManager.deviceMotion : phoneManager.deviceMotion
        if let currentAttitude = activeMotion?.attitude {
            referenceRoll = currentAttitude.roll
            PTNSLogConsole("✅ [机车姿态] 压弯零点基准已重新校准 (基于 \(currentData.currentDataSource.rawValue))")
        }
    }
    
    public func resetLeanAngles() {
        currentData.maxLeftLean = 0.0
        currentData.maxRightLean = 0.0
        currentData.isTipOverDetected = false
        triggerCallback()
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
        
        startPedometer(from: startDate)
        startActivityUpdates()
        startAltimeterUpdates()
        startPedometerEventUpdates()
        
        // 🌟 启动双擎姿态感应
        startDualMotionUpdates()
        motionStarted = true
    }
    
    // MARK: - Stop Motion Tracking
    public func stopMotion() {
        pedometer.stopUpdates()
        pedometer.stopEventUpdates()
        activityManager.stopActivityUpdates()
        if CMAltimeter.isRelativeAltitudeAvailable() { altimeter.stopRelativeAltitudeUpdates() }
        
        phoneManager.stopDeviceMotionUpdates()
        if headphoneManager.isDeviceMotionActive { headphoneManager.stopDeviceMotionUpdates() }
        motionStarted = false
    }
    
    // MARK: - 双擎运动数据调度核心
    private func startDualMotionUpdates() {
        // 1. 启动 iPhone 传感器 (作为底层保底)
        if phoneManager.isDeviceMotionAvailable {
            phoneManager.deviceMotionUpdateInterval = 1.0 / 30.0 // 30Hz
            phoneManager.startDeviceMotionUpdates(to: operationQueue) { [weak self] motion, error in
                guard let self = self, let motion = motion, error == nil else { return }
                
                // 🌟 智能拦截：如果耳机在线，直接丢弃手机的姿态数据
                guard self.currentData.currentDataSource == .iphone else { return }
                self.processDeviceMotion(motion, source: .iphone)
            }
        }
        
        // 2. 启动 AirPods 传感器 (作为高级覆写)
        if headphoneManager.isDeviceMotionAvailable {
            headphoneManager.startDeviceMotionUpdates(to: operationQueue) { [weak self] motion, error in
                guard let self = self, let motion = motion, error == nil else { return }
                
                // 只要耳机有数据，立刻切换数据源状态
                self.updateDataSourceState(to: .airpods)
                self.processDeviceMotion(motion, source: .airpods)
            }
        } else {
            PTNSLogConsole("⚠️ 未检测到支持的 AirPods，仅使用 iPhone 传感器。")
        }
    }
    
    // MARK: - CMHeadphoneMotionManagerDelegate (无缝回退魔法)
    public func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        PTNSLogConsole("📱 [传感器调度] AirPods 已断开/摘下。无缝回退至 iPhone 传感器！")
        updateDataSourceState(to: .iphone) // 强制切回手机
    }
    
    private func updateDataSourceState(to newSource: PTMotionDataSource) {
        if currentData.currentDataSource != newSource {
            currentData.currentDataSource = newSource
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegates.removeAll { $0.delegate == nil }
                self.delegates.forEach { $0.delegate?.motionManager(self, didChangeDataSource: newSource) }
            }
        }
    }
    
    // MARK: - 统一物理引擎计算 (无论手机还是耳机，都走这个算法)
    private func processDeviceMotion(_ motion: CMDeviceMotion, source: PTMotionDataSource) {
        let gx = motion.userAcceleration.x
        let gy = motion.userAcceleration.y
        let gz = motion.userAcceleration.z
        
        // 更新 G 值
        currentData.gForceX = gx
        currentData.gForceY = gy
        currentData.gForceZ = gz
        
        // --- 🚨 摔车侦测算法 ---
        let totalGForce = sqrt(gx * gx + gy * gy + gz * gz)
        if totalGForce > crashGForceThreshold {
            lastImpactTime = Date()
        }
        
        let now = Date()
        if let impactTime = lastImpactTime, now.timeIntervalSince(impactTime) < 10.0 {
            if currentSpeedKmh < 2.0 {
                currentData.isTipOverDetected = true
            } else if currentSpeedKmh > 10.0 {
                currentData.isTipOverDetected = false
                lastImpactTime = nil
            }
        } else {
            currentData.isTipOverDetected = false
            lastImpactTime = nil
        }
        
        // --- 🚨 倾角平滑与计算 ---
        currentData.pitch = motion.attitude.pitch * 180.0 / .pi
        currentData.yaw = motion.attitude.yaw * 180.0 / .pi
        
        let rawRollDegrees = (motion.attitude.roll - referenceRoll) * 180.0 / .pi
        smoothedRoll = (rawRollDegrees * lowPassFactor) + (smoothedRoll * (1.0 - lowPassFactor))
        let displayAngle = abs(smoothedRoll) < 1.5 ? 0.0 : smoothedRoll
        currentData.roll = displayAngle
        
        if displayAngle < 0 {
            let leftAngle = abs(displayAngle)
            if leftAngle > currentData.maxLeftLean && leftAngle < 60.0 { currentData.maxLeftLean = leftAngle }
        } else {
            let rightAngle = displayAngle
            if rightAngle > currentData.maxRightLean && rightAngle < 60.0 { currentData.maxRightLean = rightAngle }
        }
        
        // --- 补充 AirPods 独占的极客数据 ---
        currentData.rotX = motion.rotationRate.x
        currentData.rotY = motion.rotationRate.y
        currentData.rotZ = motion.rotationRate.z
        currentData.gravX = motion.gravity.x
        currentData.gravY = motion.gravity.y
        currentData.gravZ = motion.gravity.z
        currentData.quatX = motion.attitude.quaternion.x
        currentData.quatY = motion.attitude.quaternion.y
        currentData.quatZ = motion.attitude.quaternion.z
        currentData.quatW = motion.attitude.quaternion.w
        
        // 如果是耳机，提取传感器位置
        if source == .airpods {
            // 注意：sensorLocation 仅在 CMHeadphoneMotionManager 返回的子类中有效
            // 但苹果底层通常封装在 extension 中。为安全起见，这里忽略或通过特定强转获取。
            // 简单处理：仅通过状态通知 UI 即可。
        }
        
        triggerCallback()
    }
    
    // MARK: - 辅助传感器 (计步与海拔，均来自 iPhone)
    // (保留你原本完美的代码，只需将结果赋值给 currentData 并调用 triggerCallback)
    
    private func startPedometer(from date: Date) {
        pedometer.startUpdates(from: date) { [weak self] data, error in
            guard let self = self, let data = data, error == nil else { return }
            self.currentData.stepCount = data.numberOfSteps.intValue
            self.currentData.distance = data.distance?.doubleValue ?? 0.0
            self.currentData.currentPace = data.currentPace?.doubleValue ?? 0.0
            self.currentData.currentCadence = data.currentCadence?.doubleValue ?? 0.0
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
    
    private func startPedometerEventUpdates() {
        guard CMPedometer.isPedometerEventTrackingAvailable() else { return }
        pedometer.startEventUpdates { [weak self] event, error in
            guard let self = self, let event = event, error == nil else { return }
            self.currentData.isWalkingPaused = (event.type == .pause)
            self.triggerCallback()
        }
    }
    
    private func startAltimeterUpdates() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else { return }
        altimeter.startRelativeAltitudeUpdates(to: operationQueue) { [weak self] data, error in
            guard let self = self, let data = data, error == nil else { return }
            let relativeAlt = data.relativeAltitude.doubleValue
            self.currentData.relativeAltitude = relativeAlt
            self.currentData.pressure = data.pressure.doubleValue
            
            let now = Date()
            self.altitudeHistory.append((time: now, altitude: relativeAlt))
            self.altitudeHistory = self.altitudeHistory.filter { now.timeIntervalSince($0.time) <= 30.0 }
            
            if let firstRecord = self.altitudeHistory.first {
                let heightDifference = relativeAlt - firstRecord.altitude
                let timeDifference = now.timeIntervalSince(firstRecord.time)
                if timeDifference > 5.0 {
                    if heightDifference > 15.0 {
                        self.currentData.altitudeAlertMessage = "⛰️ 海拔急速爬升中，注意防风降温与胎压变化"
                    } else if heightDifference < -15.0 {
                        self.currentData.altitudeAlertMessage = "📉 正在急速下山，注意控制刹车热衰减"
                    } else {
                        self.currentData.altitudeAlertMessage = nil
                    }
                }
            }
            self.triggerCallback()
        }
    }
    
    // MARK: - 数据分发
    private func triggerCallback() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegates.removeAll { $0.delegate == nil }
            self.delegates.forEach { $0.delegate?.motionManager(self, didUpdateData: self.currentData) }
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
}
