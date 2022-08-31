//
//  PTMotion.swift
//  PooTools_Example
//
//  Created by jax on 2022/8/31.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import CoreMotion

public typealias PTMotionBlock = (_ step:Int,_ speed:String,_ status:String) -> Void

@objcMembers
public class PTMotion: NSObject {
    public static let share = PTMotion()
    
    public var motionBlock:PTMotionBlock?
    
    fileprivate var operationQueue:OperationQueue = OperationQueue()
    fileprivate var pedometer : CMPedometer = CMPedometer()
    fileprivate var stepCount : Int = 0
    fileprivate var activityManager : CMMotionActivityManager = CMMotionActivityManager()

    func startMotion()
    {
        if !CMPedometer.isStepCountingAvailable() || !CMMotionActivityManager.isActivityAvailable()
        {
            let msg = "哎喲，不能運行哦,僅支持M7以上處理器, 所以暫時只能在iPhone5s以上玩哦."
            PTUtils.base_alertVC(msg:msg,showIn: PTUtils.getCurrentVC(), moreBtn: nil)
            return
        }
        
        if CMPedometer.isStepCountingAvailable()
        {
            self.pedometer.startUpdates(from: Date()) { pedomoterData, error in
                
                if error != nil
                {
                    let data = pedomoterData!
                    self.stepCount = Int(truncating: data.numberOfSteps)
                }
            }
        }
        
        if CMMotionActivityManager.isActivityAvailable()
        {
            self.activityManager.startActivityUpdates(to: self.operationQueue) { activity in
                PTUtils.gcdMain {
                    if self.motionBlock != nil
                    {
                        self.motionBlock!(self.stepCount,self.activityConfidenceString(confidence: activity!.confidence),self.statusForActivity(activity: activity!))
                    }
                }
            }
        }
    }
    
    func statusForActivity(activity:CMMotionActivity) ->String
    {
        var status :NSMutableString = "".nsString.mutableCopy() as! NSMutableString
        if activity.stationary
        {
            status = status.appending("not Moving") as! NSMutableString
        }
        
        if activity.walking
        {
            if status.length > 0
            {
                status.append(", ")
            }
            status = status.appending("on a walking person") as! NSMutableString
        }
        
        if activity.running
        {
            if status.length > 0
            {
                status.append(", ")
            }
            status = status.appending("on a running person") as! NSMutableString
        }
        
        if activity.automotive
        {
            if status.length > 0
            {
                status.append(", ")
            }
            status = status.appending("in a vehicle") as! NSMutableString
        }
        
        if activity.unknown || status.length == 0
        {
            status = status.appending("unknown") as! NSMutableString
        }
        
        return status.description
    }
    
    func activityConfidenceString(confidence:CMMotionActivityConfidence)->String
    {
        switch confidence {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "Heigh"
        default:
            return ""
        }
    }
}
