//
//  PTDebugPerformanceToolKit.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/26.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

@MainActor
final class PTDebugPerformanceToolKit {
    
    static let shared = PTDebugPerformanceToolKit.init()
    
    static func generate() {
        // iOS 不提供公开 API 主动制造内存警告，也不应通过私有 API 或大块泄漏模拟。
        // 这里保留调试入口，改为记录当前内存状态，实际压力测试请使用 Instruments。
        let currentMemory = shared.memory()
        PTNSLogConsole("当前内存约为 \(String(format: "%.1f MB", currentMemory))，请使用 Instruments 进行内存压力测试")
    }
    
    private var floatingView : PFloatingButton?
    private lazy var fpsLabel : UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.backgroundColor = .black
        label.textAlignment = .center
        label.font = .appfont(size: 12)
        return label
    }()
    
    var floatingShow:Bool {
        get {
            if let floating = floatingView {
                return !floating.isHidden
            } else {
                return false
            }
        } set {
            if let floating = floatingView {
                floating.isHidden = !newValue
            }
        }
    }

    var measurementsTimer: Timer?
    let measurementsLimit = 120
    var currentMeasurementIndex = 0

    var cpuMeasurements: [CGFloat] = []
    var currentCPU: CGFloat = 0
    var maxCPU: CGFloat = 0

    @MainActor var fpsCounter = PTFPSTool.shared
    var currentFPS: CGFloat = 0
    var minFPS: CGFloat = 9999
    var maxFPS: CGFloat = 0
    var fpsMeasurements: [CGFloat] = []

    var currentMemory: CGFloat = 0
    var maxMemory: CGFloat = 0
    var memoryMeasurements: [CGFloat] = []

    var currentLeaks: CGFloat = 0
    var maxLeaks: CGFloat = 0
    var leaksMeasurements: [CGFloat] = []

    var timeBetweenMeasurements: TimeInterval = 1
    var controllerMarked: TimeInterval = 120

    var performanceDataUpdateCallBack:((PTDebugPerformanceToolKit)->Void)?
    
    init() {}
    
    deinit {
//        performanceClose()
    }
    
    func performanceClose() {
        measurementsTimer?.invalidate()
        measurementsTimer = nil
        fpsCounter.close()
    }
    
    func performanceRestart() {
        measurementsTimer?.invalidate()
        fpsCounter.open()
        let timer = Timer(timeInterval: timeBetweenMeasurements,
                          target: self,
                          selector: #selector(updateMeasurements),
                          userInfo: nil,
                          repeats: true)
        measurementsTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }
    
    @MainActor func setupPerformanceMeasurement() {
        currentMeasurementIndex = 0
        cpuMeasurements.removeAll(keepingCapacity: true)
        memoryMeasurements.removeAll(keepingCapacity: true)
        fpsMeasurements.removeAll(keepingCapacity: true)
        leaksMeasurements.removeAll(keepingCapacity: true)
        currentCPU = 0
        currentMemory = 0
        currentFPS = 0
        currentLeaks = 0
        maxCPU = 0
        maxMemory = 0
        minFPS = .greatestFiniteMagnitude
        maxFPS = 0
        maxLeaks = 0
        performanceRestart()
        floatingButtonCreate()
    }
    
    @objc private func updateMeasurements() {
        currentCPU = cpu()
        cpuMeasurements = array(cpuMeasurements, byAddingMeasurement: currentCPU)
        maxCPU = max(maxCPU, currentCPU)

        currentMemory = memory()
        memoryMeasurements = array(memoryMeasurements, byAddingMeasurement: currentMemory)
        maxMemory = max(maxMemory, currentMemory)

        currentFPS = fps()
        fpsMeasurements = array(fpsMeasurements, byAddingMeasurement: currentFPS)
        if !currentFPS.isZero {
            minFPS = min(minFPS, currentFPS)
        }
        maxFPS = max(maxFPS, currentFPS)
        
        currentLeaks = leak()
        maxLeaks = max(maxLeaks, currentLeaks)
        leaksMeasurements = array(leaksMeasurements, byAddingMeasurement: currentLeaks)

        updateFloatingView()
        
        performanceDataUpdateCallBack?(self)
        currentMeasurementIndex = min(measurementsLimit, currentMeasurementIndex + 1)
    }

    private func array<T>(_ array: [T], byAddingMeasurement measurement: T) -> [T] {
        var newMeasurements = array

        if currentMeasurementIndex == measurementsLimit {
            // Shift previous measurements
            for index in 0..<measurementsLimit - 1 {
                newMeasurements[index] = newMeasurements[index + 1]
            }

            // Add the new measurement to the end of the array
            newMeasurements[measurementsLimit - 1] = measurement
        } else {
            // Add the next measurement if we haven't reached the limit
            newMeasurements.append(measurement)
        }

        return newMeasurements
    }
    
    func cpu() -> CGFloat {
        var totalUsageOfCPU: CGFloat = 0.0
        
        // Get the list of threads
        var threadsList: thread_act_array_t?
        var threadsCount = mach_msg_type_number_t(0)
        let threadsResult = task_threads(mach_task_self_, &threadsList, &threadsCount)
        
        guard threadsResult == KERN_SUCCESS, let threads = threadsList else {
            return totalUsageOfCPU
        }
        
        defer {
            // Deallocate memory for threadsList
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: threads)), vm_size_t(threadsCount * UInt32(MemoryLayout<thread_t>.stride)))
        }
        
        // Iterate through each thread
        for index in 0..<Int(threadsCount) {
            var threadInfo = thread_basic_info()
            var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
            
            let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) { thread_info(threads[index], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount) }
            }
            
            guard infoResult == KERN_SUCCESS else {
                break
            }
            
            let threadBasicInfo = threadInfo
            if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                totalUsageOfCPU += CGFloat(threadBasicInfo.cpu_usage) / CGFloat(TH_USAGE_SCALE) * 100.0
            }
        }
        
        return totalUsageOfCPU
    }

    private func memory() -> CGFloat {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) { $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        return kerr == KERN_SUCCESS ? CGFloat(info.resident_size) / 1024.0 / 1024.0 : 0
    }

    @MainActor
    private func fps() -> CGFloat {
        CGFloat(fpsCounter.fpsValue)
    }
    
    func leak() -> CGFloat {
        CGFloat(PTPerformanceLeakDetector.leaks.filter(\.isActive).count)
    }
    
    private func updateFloatingView() {
        if floatingView != nil {
            fpsLabel.text = "CPU:\(String(format: "%.1lf%%", currentCPU)) Memory:\(String(format: "%.1lfMB", currentMemory)) FPS:\(String(format: "%.0lf", currentFPS)) Leaks:\(Int(currentLeaks))"
        }
    }
    
    @MainActor private func floatingButtonCreate() {
        if floatingView == nil {
            floatingView = PFloatingButton(inView: PTConsoleWindow.shared, frame: CGRect(x: PTAppBaseConfig.share.defaultViewSpace, y: CGFloat.statusBarHeight(), width: CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 2, height: 30))
            floatingView?.tag = 9999
            floatingView?.autoDocking = false
            floatingView?.addSubview(fpsLabel)
            fpsLabel.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            floatingView?.isHidden = true
        }
    }
}
