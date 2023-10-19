//
//  PTPermissionBluetoothHandler.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import CoreBluetooth

class PTPermissionBluetoothHandler: NSObject, CBCentralManagerDelegate {
    
    var completion: ()->Void = {}
    
    // MARK: - Init
    
    static let shared: PTPermissionBluetoothHandler = .init()
    
    override init() {
        super.init()
    }
    
    // MARK: - Manager
    
    var manager: CBCentralManager?
    
    func reqeustUpdate() {
        if manager == nil {
            self.manager = CBCentralManager(delegate: self, queue: nil, options: [:])
        } else {
            completion()
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if #available(iOS 13.0, tvOS 13, *) {
            switch central.authorization {
            case .notDetermined:
                break
            default:
                self.completion()
            }
        } else {
            switch CBPeripheralManager.authorizationStatus() {
            case .notDetermined:
                break
            default:
                self.completion()
            }
        }
    }
}
