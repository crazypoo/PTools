//
//  PTPermissionCalendar.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import EventKit

public extension PTPermission {
    
    static func calendar(access: CalendarAccess) -> PTPermissionCalendar {
        PTPermissionCalendar(kind: .calendar(access: access))
    }
}

public class PTPermissionCalendar: PTPermission {
    
    private var _kind: PTPermission.Kind
    
    // MARK: - Init
    
    init(kind: PTPermission.Kind) {
        _kind = kind
    }
    
    open override var kind: PTPermission.Kind { _kind }
    open var usageDescriptionKey: String? {
        if #available(iOS 17, *) {
            switch kind {
            case .calendar(let access):
                switch access {
                case .full:
                    return "NSCalendarsFullAccessUsageDescription"
                case .write:
                    return "NSCalendarsWriteOnlyAccessUsageDescription"
                }
            default:
                fatalError()
            }
        } else {
            return "NSCalendarsUsageDescription"
        }
    }
    
    public override var status: PTPermission.Status {
        // Fix when status first time response with other state.
        let _ = EKEventStore.authorizationStatus(for: EKEntityType.event)
        
        switch EKEventStore.authorizationStatus(for: EKEntityType.event) {
        case .authorized: return .authorized
        case .denied: return .denied
        case .fullAccess: return .authorized
        case .notDetermined: return .notDetermined
        case .restricted: return .denied
        case .writeOnly:
            if #available(iOS 17, *) {
                switch kind {
                case .calendar(let access):
                    switch access {
                    case .full:
                        return .denied
                    case .write:
                        return .authorized
                    }
                default:
                    fatalError()
                }
            } else {
                return .authorized
            }
        @unknown default: return .denied
        }
    }
    
    public override func request(completion: @escaping PTActionTask) {
        
        let eventStore = EKEventStore()
        
        if #available(iOS 17.0, *) {
            
            let requestWriteOnly = {
                eventStore.requestWriteOnlyAccessToEvents { (accessGranted: Bool, error: Error?) in
                    PTGCDManager.gcdMain {
                        completion()
                    }
                }
            }
            
            let requestFull = {
                eventStore.requestFullAccessToEvents { (accessGranted: Bool, error: Error?) in
                    PTGCDManager.gcdMain {
                        completion()
                    }
                }
            }
            
            switch kind {
            case .calendar(let access):
                if access == .write {
                    requestWriteOnly()
                } else {
                    requestFull()
                }
            default:
                requestFull()
            }
        } else {
            eventStore.requestAccess(to: EKEntityType.event) { (accessGranted: Bool, error: Error?) in
                PTGCDManager.gcdMain {
                    completion()
                }
            }
        }
    }
}
