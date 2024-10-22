//
//  PTPermissionContacts.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import Contacts

public extension PTPermission {

    static var contacts: PTPermissionContacts {
        PTPermissionContacts()
    }
}

public class PTPermissionContacts: PTPermission {
    
    open override var kind: PTPermission.Kind { .contacts }
    open var usageDescriptionKey: String? { "NSContactsUsageDescription" }
    
    public override var status: PTPermission.Status {
        let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        if #available(iOS 18.0, *), authorizationStatus == .limited {
            return .authorized
        }
        switch authorizationStatus {
        case .authorized: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .denied
        case .limited: return .authorized
        @unknown default: return .denied
        }
    }
    
    public override func request(completion: @escaping () -> Void) {
        let store = CNContactStore()
        store.requestAccess(for: .contacts, completionHandler: { (granted, error) in
            PTGCDManager.gcdMain {
                completion()
            }
        })
    }
}
