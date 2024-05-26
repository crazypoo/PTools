//
//  PTDebugPerformanceToolKit.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/26.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class PTDebugPerformanceToolKit {
    
    static let shared = PTDebugPerformanceToolKit.init()
    
    static func generate() {
        UIApplication.shared.perform(Selector(("_performMemoryWarning")))

        for _ in 0...1200 {
            var p: [UnsafeMutableRawPointer] = []
            var allocatedMB = 0
            p.append(malloc(1048576))
            memset(p[allocatedMB], 0, 1048576)
            allocatedMB += 1
        }
    }
    
    private  var floatingView : PFloatingButton?
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
            if floatingView != nil {
                return !floatingView!.isHidden
            } else {
                return false
            }
        } set {
            if floatingView != nil {
                floatingView!.isHidden = !newValue
            }
        }
    }

    var measurementsTimer: Timer?
    let measurementsLimit = 120
    var currentMeasurementIndex = 0

    var cpuMeasurements: [CGFloat] = []
    var currentCPU: CGFloat = 0
    var maxCPU: CGFloat = 0

    var fpsCounter = PTFPSTool.shared
    var currentFPS: CGFloat = 0
    var minFPS: CGFloat = 9999
    var maxFPS: CGFloat = 0
    var fpsMeasurements: [CGFloat] = []

    var currentMemory: CGFloat = 0
    var maxMemory: CGFloat = 0
    var memoryMeasurements: [CGFloat] = []

    var timeBetweenMeasurements: TimeInterval = 1
    var controllerMarked: TimeInterval = 120

    var performanceDataUpdateCallBack:((PTDebugPerformanceToolKit)->Void)?
    
    init() {
        setupPerformanceMeasurement()
    }
    
    deinit {
        performanceClose()
    }
    
    func performanceClose() {
        measurementsTimer?.invalidate()
        measurementsTimer = nil
        fpsCounter.close()
    }
    
    func performanceRestart() {
        fpsCounter.open()
        measurementsTimer = Timer(
            timeInterval: 1.0, target: self, selector: #selector(updateMeasurements), userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(measurementsTimer!, forMode: .common)
    }
    
    func setupPerformanceMeasurement() {
        performanceRestart()
        // Additional setup for measurements
        cpuMeasurements = Array(repeating: 0, count: measurementsLimit)
        memoryMeasurements = Array(repeating: 0, count: measurementsLimit)
        fpsMeasurements = Array(repeating: 0, count: measurementsLimit)
        
        floatingButtonCreate()
    }
    
    @objc private func updateMeasurements() {
        // CPU measurements
        currentCPU = cpu()
        cpuMeasurements = array(cpuMeasurements, byAddingMeasurement: currentCPU)
        maxCPU = max(maxCPU, currentCPU)

        // Memory measurements
        currentMemory = memory()
        memoryMeasurements = array(memoryMeasurements, byAddingMeasurement: currentMemory)
        maxMemory = max(maxMemory, currentMemory)

        // FPS measurements
        currentFPS = fps()
        fpsMeasurements = array(fpsMeasurements, byAddingMeasurement: currentFPS)
        if !currentFPS.isZero {
            minFPS = min(minFPS, currentFPS)
        }
        maxFPS = max(maxFPS, currentFPS)

        PTGCDManager.gcdMain {
            self.updateFloatingView()
        }
        
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
        var threadsList = UnsafeMutablePointer(mutating: [thread_act_t]())
        var threadsCount = mach_msg_type_number_t(0)
        let threadsResult = withUnsafeMutablePointer(to: &threadsList) {
            $0.withMemoryRebound(to: thread_act_array_t?.self, capacity: 1) {
                task_threads(mach_task_self_, $0, &threadsCount)
            }
        }

        if threadsResult == KERN_SUCCESS {
            for index in 0..<threadsCount {
                var threadInfo = thread_basic_info()
                var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
                let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        thread_info(
                            threadsList[Int(index)], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount
                        )
                    }
                }

                guard infoResult == KERN_SUCCESS else {
                    break
                }

                let threadBasicInfo = threadInfo as thread_basic_info
                if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                    totalUsageOfCPU =
                        (totalUsageOfCPU + (Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0))
                }
            }
        }

        vm_deallocate(
            mach_task_self_, vm_address_t(UInt(bitPattern: threadsList)),
            vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride)
        )
        return totalUsageOfCPU
    }

    private func memory() ->CGFloat {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        return kerr == KERN_SUCCESS ? CGFloat(info.resident_size) / 1024.0 / 1024.0 : 0
    }

    private func fps() -> CGFloat {
        CGFloat(fpsCounter.fpsValue)
    }
    
    private func updateFloatingView() {
        if floatingView != nil {
            fpsLabel.text = "CPU:\(String(format: "%.1lf%%", currentCPU)) Memory:\(String(format: "%.1lfMB", currentMemory)) FPS:\(String(format: "%.0lf", currentFPS))"
        }
    }
    
    private func floatingButtonCreate() {
        if floatingView == nil {
            floatingView = PFloatingButton.init(view: AppWindows as Any, frame: CGRect(x: PTAppBaseConfig.share.defaultViewSpace, y: CGFloat.statusBarHeight(), width: CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 2, height: 30))
            floatingView?.adjustsImageWhenHighlighted = false
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
