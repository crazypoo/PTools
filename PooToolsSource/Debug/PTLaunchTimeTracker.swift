//
//  PTLaunchTimeTracker.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

enum PTLaunchTimeTracker {
    static var launchStartTime: Double?

    // FIXME: - Sometimes processTimeMilliseconds, doesnt return the correct value.
    static func measureAppStartUpTime() {
        var kinfo = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        sysctl(&mib, u_int(mib.count), &kinfo, &size, nil, 0)

        let startTime = kinfo.kp_proc.p_starttime
        var currentTime = timeval()
        gettimeofday(&currentTime, nil)

        let currentTimeMilliseconds =
            Double(currentTime.tv_sec) * 1000 + Double(currentTime.tv_usec) / 1000.0
        let processTimeMilliseconds =
            Double(startTime.tv_sec) * 1000 + Double(startTime.tv_usec) / 1000.0

        launchStartTime = (currentTimeMilliseconds - processTimeMilliseconds) / 1000.0
    }
}
