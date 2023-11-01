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
            manager = CBCentralManager(delegate: self, queue: nil, options: [:])
        } else {
            completion()
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unauthorized,.unsupported,.unknown:
            // 用户未授权使用蓝牙
            // 设备不支持蓝牙
            break
        default:
            // 中央管理器已准备好，可以开始扫描外围设备
            // 中央管理器已关闭
            // 中央管理器正在重置
            // 中央管理器状态未知
            // 处理其他未知状态
            completion()
        }
    }
}
