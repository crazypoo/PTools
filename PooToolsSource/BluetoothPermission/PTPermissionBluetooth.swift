//
//  PTPermissionBluetooth.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import CoreBluetooth
import CloudKit

public extension PTPermission {
    
    static var bluetooth: PTPermissionBluetooth {
        PTPermissionBluetooth()
    }
}

public class PTPermissionBluetooth: PTPermission {
    
    open override var kind: PTPermission.Kind { .bluetooth }
    open var usageDescriptionKey: String? { "NSBluetoothAlwaysUsageDescription" }
    
    public override var status: PTPermission.Status {
        switch CBCentralManager.authorization {
        case .allowedAlways: return .authorized
        case .notDetermined: return .notDetermined
        case .restricted: return .denied
        case .denied: return .denied
        @unknown default: return .denied
        }
    }
    
    public override func request(completion: @escaping PTActionTask) {
        PTPermissionBluetoothHandler.shared.completion = completion
        PTGCDManager.gcdMain {
            PTPermissionBluetoothHandler.shared.reqeustUpdate()
        }
    }
}
