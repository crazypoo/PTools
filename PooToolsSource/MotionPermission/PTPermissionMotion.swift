//
//  PTPermissionMotion.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import CoreMotion

public extension PTPermission {
    
    static var motion: PTPermissionMotion {
        PTPermissionMotion()
    }
}

public class PTPermissionMotion: PTPermission {
    
    open override var kind: PTPermission.Kind { .motion }
    open var usageDescriptionKey: String? { "NSMotionUsageDescription" }
    
    public override var status: PTPermission.Status {
        switch CMMotionActivityManager.authorizationStatus() {
        case .authorized: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .denied
        @unknown default: return .denied
        }
    }
    
    public override func request(completion: @escaping PTActionTask) {
        let manager = CMMotionActivityManager()
        let today = Date()
        
        manager.queryActivityStarting(from: today, to: today, to: OperationQueue.main, withHandler: { (activities: [CMMotionActivity]?, error: Error?) -> () in
            PTGCDManager.gcdMain {
                completion()
            }
            manager.stopActivityUpdates()
        })
    }
}
