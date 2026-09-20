//
//  PTPermissionBluetooth.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import CoreBluetooth
#if POOTOOLS_SPLIT_PERMISSION_CORE
import PToolsPermissionCore
#endif

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

    // English: Report Bluetooth authorization independently from adapter power and hardware availability.
    // Español: Informa la autorización Bluetooth por separado de la energía y disponibilidad del hardware.
    // 中文：将蓝牙授权与适配器开关状态、硬件可用性分开报告。
    public override var authorizationState: PTPermissionAuthorizationState {
        switch CBCentralManager.authorization {
        case .allowedAlways: return .authorized
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        @unknown default: return .unavailable
        }
    }

    public var bluetoothState: PTBluetoothPermissionState {
        switch PTPermissionBluetoothHandler.shared.currentState {
        case .poweredOn: return .authorized
        case .poweredOff: return .poweredOff
        case .unsupported: return .unsupported
        case .resetting: return .resetting
        case .unauthorized: return .denied
        case .unknown: return .unknown
        @unknown default: return .unknown
        }
    }

    public override func request(completion: @escaping PTActionTask) {
        let finish = PTPermission.makeCompletionOnce(completion)
        PTPermissionBluetoothHandler.shared.requestPermission(completion: finish)
    }

    // English: Release the central manager delegate and pending permission callbacks.
    // Español: Libera el delegado del gestor central y los callbacks de permiso pendientes.
    // 中文：释放中央管理器代理和待处理的权限回调。
    public func invalidate() {
        PTPermissionBluetoothHandler.shared.invalidate()
    }
}
