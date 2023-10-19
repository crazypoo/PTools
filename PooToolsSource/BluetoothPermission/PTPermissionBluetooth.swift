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
        return PTPermissionBluetooth()
    }
}

public class PTPermissionBluetooth: PTPermission {
    
    open override var kind: PTPermission.Kind { .bluetooth }
    open var usageDescriptionKey: String? { "NSBluetoothAlwaysUsageDescription" }
    
    public override var status: PTPermission.Status {
        if #available(iOS 13.1, tvOS 13.1, *) {
            switch CBCentralManager.authorization {
            case .allowedAlways: return .authorized
            case .notDetermined: return .notDetermined
            case .restricted: return .denied
            case .denied: return .denied
            @unknown default: return .denied
            }
        } else if #available(iOS 13.0, tvOS 13.0, *) {
            switch CBCentralManager().authorization {
            case .allowedAlways: return .authorized
            case .notDetermined: return .notDetermined
            case .restricted: return .denied
            case .denied: return .denied
            @unknown default: return .denied
            }
        } else {
            switch CBPeripheralManager.authorizationStatus() {
            case .authorized: return .authorized
            case .denied: return .denied
            case .restricted: return .denied
            case .notDetermined: return .notDetermined
            @unknown default: return .denied
            }
        }
    }
    
    public override func request(completion: @escaping () -> Void) {
        PTPermissionBluetoothHandler.shared.completion = completion
        PTPermissionBluetoothHandler.shared.reqeustUpdate()
    }
}
