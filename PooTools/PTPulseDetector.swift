//
//  PTPulseDetector.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 24/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

let MAX_PERIOD = 1.5
let MIN_PERIOD = 0.1
let MAX_PERIODS_TO_STORE: Int = 20
let AVERAGE_SIZE: Int = 20
let INVALID_PULSE_PERIOD: Float = -1

class PTPulseDetector: NSObject {
    private var upVals = [Float](repeating: 0, count: AVERAGE_SIZE)
    private var downVals = [Float](repeating: 0, count: AVERAGE_SIZE)
    private var upValIndex: Int = 0
    private var downValIndex: Int = 0
    
    private var lastVal: Float = 0
    @objc dynamic var periodStart: Float = 0
    private var periods = [Double](repeating: 0, count: MAX_PERIODS_TO_STORE)
    private var periodTimes = [Double](repeating: 0, count: MAX_PERIODS_TO_STORE)
    
    private var periodIndex: Int = 0
    private var started: Bool = false
    private var freq: Float = 0
    private var average: Float = 0
    
    private var wasDown: Bool = false
    
    func addNewValue(_ newVal: Float, atTime time: Double) -> Float {
        if newVal > 0 {
            upVals[upValIndex] = newVal
            upValIndex += 1
            if upValIndex >= AVERAGE_SIZE {
                upValIndex = 0
            }
        }
        if newVal < 0 {
            downVals[downValIndex] = -newVal
            downValIndex += 1
            if downValIndex >= AVERAGE_SIZE {
                downValIndex = 0
            }
        }
        
        var count: Float = 0
        var total: Float = 0
        for i in 0..<AVERAGE_SIZE {
            if upVals[i] != 0 {
                count += 1
                total += upVals[i]
            }
        }
        let averageUp: Float = total / count
        
        count = 0
        total = 0
        for i in 0..<AVERAGE_SIZE {
            if downVals[i] != 0 {
                count += 1
                total += downVals[i]
            }
        }
        let averageDown: Float = total / count
        
        if newVal < -0.5 * averageDown {
            wasDown = true
        }
        
        if newVal >= 0.5 * averageUp && wasDown {
            wasDown = false
            
            if time - Double(periodStart) < Double(MAX_PERIOD) && time - Double(periodStart) > Double(MIN_PERIOD) {
                periods[periodIndex] = time - Double(periodStart)
                periodTimes[periodIndex] = time
                periodIndex += 1
                if periodIndex >= MAX_PERIODS_TO_STORE {
                    periodIndex = 0
                }
            }
            periodStart = Float(time)
        }
        if newVal < -0.5 * averageDown {
            return -1
        } else if newVal > 0.5 * averageUp {
            return 1
        }
        return 0
    }
    
    func getAverage() -> Float {
        let time = CACurrentMediaTime()
        var total: Double = 0
        var count: Double = 0
        for i in 0..<MAX_PERIODS_TO_STORE {
            if periods[i] != 0 && time - periodTimes[i] < 10 {
                count += 1
                total += periods[i]
            }
        }
        if count > 2 {
            return Float(total / count)
        }
        return INVALID_PULSE_PERIOD
    }
    
    func reset() {
        upVals = [Float](repeating: 0, count: AVERAGE_SIZE)
        downVals = [Float](repeating: 0, count: AVERAGE_SIZE)
        upValIndex = 0
        downValIndex = 0
        
        lastVal = 0
        periodStart = 0
        periods = [Double](repeating: 0, count: MAX_PERIODS_TO_STORE)
        periodTimes = [Double](repeating: 0, count: MAX_PERIODS_TO_STORE)
        
        periodIndex = 0
        started = false
        freq = 0
        average = 0
        
        wasDown = false
    }
}
