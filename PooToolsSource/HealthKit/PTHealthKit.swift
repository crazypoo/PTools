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
        self.kitSetting()
    }
    
    func dataTypesToRead()->Set<HKObjectType>
    {
        
        return [HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!]
    }

    func kitSetting()
    {
        if HKHealthStore.isHealthDataAvailable()
        {
            let types = self.dataTypesToRead()
            
            self.healthStore.requestAuthorization(toShare: nil, read: types) { success, error in
                if !success
                {
                    PTNSLogConsole("You didn't allow HealthKit to access these read data types. In your app, try to handle this error gracefully when a user decides not to provide access. The error was: \(String(describing: error)). If you're using a simulator, try it on a device.")
                    return
                }
                
                PTGCDManager.gcdMain {
                    PTNSLogConsole("The user allow the app to read information about SetpCount.")
                }
            }
        }
        else
        {
            PTNSLogConsole("HKHealthStore is not available")
        }
        
        self.stepAll()
    }
    
    func stepAll()
    {
        let calendar = NSCalendar.current
        var interval = DateComponents()
        interval.day = 1
        var anchorComponents = calendar.dateComponents([.day,.month,.year], from: Date())
        anchorComponents.hour = 0
        let anchorDate = calendar.date(from: anchorComponents)
        let quantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
        let query = HKStatisticsCollectionQuery(quantityType: quantityType!, quantitySamplePredicate: nil,options: .cumulativeSum, anchorDate: anchorDate!, intervalComponents: interval)
        query.initialResultsHandler = { querys, results, error in
            if error != nil
            {
                PTNSLogConsole("*** An error occurred while calculating the statistics: \(error!.localizedDescription) ***")
            }
                        
            let todayDate = String.currentDate().toDate()!.date
            let endDate = String.currentDate().toDate()!.dateAtEndOf(.day).date

            results?.enumerateStatistics(from: todayDate, to: endDate, with: { result, stop in
                let quantity = result.sumQuantity()
                if quantity != nil
                {
                    let value = quantity?.doubleValue(for: .count())
                    self.stepCounts += value!
                }
                self.isLoad = true
                PTGCDManager.gcdMain {
                    if self.loadBlock != nil
                    {
                        self.loadBlock!(self.isLoad,self.stepCounts)
                    }
                }
            })
        }
        self.healthStore.execute(query)
    }
}
