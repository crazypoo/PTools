//
//  PTHealthKit.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/12.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import HealthKit
import SwiftDate

public typealias StepBlock = (_ isLoad:Bool,_ stepCount:Double) -> Void

public class PTHealthKit: NSObject {
    public static let share = PTHealthKit()
    
    var isLoad:Bool = false
    var stepCounts:Double = 0
    lazy var healthStore:HKHealthStore = {
        let store = HKHealthStore()
        return store
    }()

    public var loadBlock:StepBlock?
    
    public override init() {
        super.init()
        kitSetting()
    }
    
    func dataTypesToRead()->Set<HKObjectType> {

        [HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!]
    }

    func kitSetting() {
        if HKHealthStore.isHealthDataAvailable() {
            let types = dataTypesToRead()
            
            healthStore.requestAuthorization(toShare: nil, read: types) { success, error in
                if !success {
                    PTNSLogConsole("You didn't allow HealthKit to access these read data types. In your app, try to handle this error gracefully when a user decides not to provide access. The error was: \(String(describing: error)). If you're using a simulator, try it on a device.",levelType: .Error,loggerType: .Health)
                    return
                }
            }
        } else {
            PTNSLogConsole("HKHealthStore is not available",levelType: .Error,loggerType: .Health)
        }
        
        stepAll()
    }
    
    func stepAll() {
        let calendar = NSCalendar.current
        var interval = DateComponents()
        interval.day = 1
        var anchorComponents = calendar.dateComponents([.day,.month,.year], from: Date())
        anchorComponents.hour = 0
        let anchorDate = calendar.date(from: anchorComponents)
        let quantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
        let query = HKStatisticsCollectionQuery(quantityType: quantityType!, quantitySamplePredicate: nil,options: .cumulativeSum, anchorDate: anchorDate!, intervalComponents: interval)
        query.initialResultsHandler = { querys, results, error in
            if error != nil {
                PTNSLogConsole("*** An error occurred while calculating the statistics: \(error!.localizedDescription) ***",levelType: .Error,loggerType: .Health)
            }
                        
            let todayDate = String.currentDate().toDate()!.date
            let endDate = String.currentDate().toDate()!.dateAtEndOf(.day).date

            results?.enumerateStatistics(from: todayDate, to: endDate, with: { result, stop in
                let quantity = result.sumQuantity()
                if quantity != nil {
                    let value = quantity?.doubleValue(for: .count())
                    self.stepCounts += value!
                }
                self.isLoad = true
                PTGCDManager.gcdMain {
                    self.loadBlock?(self.isLoad,self.stepCounts)
                }
            })
        }
        healthStore.execute(query)
    }
    
    @available(iOS 18.0,watchOS 11.0,*)
    public func updateWorkoutEffortScore(_ sample:HKQuantitySample,workout:HKWorkout,newScore:Double,completion:@escaping (Bool) -> Swift.Void) {
        PTNSLogConsole("updateWorkoutEfforcore samle from: %@", sample.sourceRevision.source.bundleIdentifier)
        let healthStore = HKHealthStore()
        let sampleType = HKQuantityType.quantityType(forIdentifier: .workoutEffortScore)!
        healthStore.delete(sample) { (success,error2) in
            if let error2 = error2 {
                PTNSLogConsole("cannot delete this sample: %@",error2.localizedDescription)
                completion(false)
                return
            }
            
            let newSample = HKQuantitySample(type: sampleType, quantity: HKQuantity(unit: HKUnit.appleEffortScore(), doubleValue: newScore), start: sample.startDate, end: sample.endDate)
            
            healthStore.save(newSample) { success, error in
                if let error = error {
                    PTNSLogConsole(">> health store save failed %@",error.localizedDescription)
                }
                
                if success {
                    HKHealthStore().relateWorkoutEffortSample(newSample, with: workout, activity: nil) { reSuccess, reError in
                        if let reError = reError {
                            PTNSLogConsole("relateWorkoutEffortSample failed: %@",reError.localizedDescription)
                        } else {
                            PTNSLogConsole("relateWorkoutEffortSample success")
                        }
                    }
                }
                completion(success)
            }
        }
    }
    
    @available(iOS 18.0,watchOS 11.0,*)
    public func addWordoutEffortScore(_ workout:HKWorkout,score:Double,completion:@escaping (Bool) -> Swift.Void) {
        let healthStore = HKHealthStore()
        let sampleType = HKQuantityType.quantityType(forIdentifier: .workoutEffortScore)!
        let newSample = HKQuantitySample(type: sampleType, quantity: HKQuantity(unit: HKUnit.appleEffortScore(), doubleValue: score), start: workout.startDate, end: workout.endDate)
        healthStore.save(newSample) { success, error in
            if let error = error {
                PTNSLogConsole(">> healthstore save failed %@",error.localizedDescription)
            }
            if success {
                HKHealthStore().relateWorkoutEffortSample(newSample, with: workout, activity: nil) { reSuccess, reError in
                    if let reError = reError {
                        PTNSLogConsole("relateWorkoutEffortSample failed: %@",reError.localizedDescription)
                    } else {
                        PTNSLogConsole("relateWorkoutEffortSample success")
                    }
                }
            }
            completion(success)
        }
    }
}
