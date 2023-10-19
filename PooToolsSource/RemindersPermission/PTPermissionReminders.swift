//
//  PTPermissionReminders.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import EventKit

public extension PTPermission {

    static var reminders: PTPermissionReminders {
        return PTPermissionReminders()
    }
}

public class PTPermissionReminders: PTPermission {
    
    open override var kind: PTPermission.Kind { .reminders }
    open var usageDescriptionKey: String? { "NSRemindersUsageDescription" }
    open var usageFullAccessDescriptionKey: String? { "NSRemindersFullAccessUsageDescription" }
    
    public override var status: PTPermission.Status {
        switch EKEventStore.authorizationStatus(for: EKEntityType.reminder) {
        case .authorized: return .authorized
        case .denied: return .denied
        case .fullAccess: return .authorized
        case .notDetermined: return .notDetermined
        case .restricted: return .denied
        case .writeOnly: return .authorized
        @unknown default: return .denied
        }
    }
    
    public override func request(completion: @escaping () -> Void) {
        
        let eventStore = EKEventStore()
        
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToReminders { (accessGranted: Bool, error: Error?) in
                PTGCDManager.gcdMain {
                    completion()
                }
            }
        } else {
            eventStore.requestAccess(to: EKEntityType.reminder) { (accessGranted: Bool, error: Error?) in
                PTGCDManager.gcdMain {
                    completion()
                }
            }
        }
    }
}
