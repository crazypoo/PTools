//
//  PTLaunchTimeTracker.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

enum PTLaunchTimeTracker {
    static var launchStartTime: TimeInterval?

    static func measureAppStartUpTime() {
        // 设置kinfo结构体并获取当前进程信息
        var kinfo = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        let mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]

        // 创建mib的局部拷贝，避免内存访问冲突
        var localMib = mib

        // 确保sysctl调用成功
        let sysctlResult = sysctl(&localMib, u_int(localMib.count), &kinfo, &size, nil, 0)
        guard sysctlResult == 0 else {
            PTNSLogConsole("sysctl failed with error: \(sysctlResult)")
            return
        }

        // 获取进程启动时间
        let startTime = kinfo.kp_proc.p_starttime
        var currentTime = timeval()
        gettimeofday(&currentTime, nil)

        // 将秒和微秒转换为毫秒
        let currentTimeMilliseconds = TimeInterval(currentTime.tv_sec) * 1000 + TimeInterval(currentTime.tv_usec) / 1000.0
        let processTimeMilliseconds = TimeInterval(startTime.tv_sec) * 1000 + TimeInterval(startTime.tv_usec) / 1000.0

        // 确保 processTimeMilliseconds 小于 currentTimeMilliseconds
        guard processTimeMilliseconds <= currentTimeMilliseconds else {
            PTNSLogConsole("Process start time is in the future, check for clock sync issues.")
            return
        }

        // 计算应用启动时间并转换为秒
        launchStartTime = (currentTimeMilliseconds - processTimeMilliseconds) / 1000.0
    }
}
