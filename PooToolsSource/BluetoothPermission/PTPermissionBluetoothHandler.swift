//
//  PTPermissionBluetoothHandler.swift
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

@MainActor
class PTPermissionBluetoothHandler: NSObject, @preconcurrency CBCentralManagerDelegate {

    private var completion: PTActionTask?
    
    // MARK: - Init
    
    @MainActor static let shared: PTPermissionBluetoothHandler = .init()
    
    override init() {
        super.init()
    }
    
    // MARK: - Manager
    
    var manager: CBCentralManager?
    
    // English: Store the callback and start one central-manager observation for one permission request.
    // Español: Guarda el callback e inicia una sola observación del gestor central para cada solicitud.
    // 中文：保存回调，并为每次权限请求只启动一次中央管理器观察。
    func requestPermission(completion: @escaping PTActionTask) {
        self.completion = completion
        requestUpdate()
    }

    private func requestUpdate() {
        if manager == nil {
            manager = CBCentralManager(delegate: self, queue: nil, options: [:])
        } else {
            manager?.delegate = self
            finishRequest()
        }
    }

    // English: Every terminal Bluetooth state must finish the request; unsupported devices must not leave async callers suspended.
    // Español: Cada estado terminal de Bluetooth debe finalizar la solicitud; un dispositivo no compatible no debe suspender al llamador async.
    // 中文：每个蓝牙终态都必须结束请求，不支持蓝牙的设备不能让 async 调用永久悬挂。
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unauthorized, .unsupported, .unknown:
            // English: Authorization is denied or the device cannot provide Bluetooth; finish with the normalized status.
            // Español: La autorización está denegada o el dispositivo no ofrece Bluetooth; finaliza con el estado normalizado.
            // 中文：蓝牙未授权或设备不支持蓝牙，使用统一状态结束请求。
            finishRequest()
        default:
            // English: Powered-on, powered-off, and resetting are all observable terminal results for this permission probe.
            // Español: Encendido, apagado y reinicio son resultados terminales observables para esta comprobación de permisos.
            // 中文：开启、关闭和重置都属于本次权限探测可观察到的终态。
            finishRequest()
        }
    }

    // English: Clear the callback before invoking it so duplicate delegate events are harmless.
    // Español: Limpia el callback antes de invocarlo para que los eventos duplicados del delegado sean inocuos.
    // 中文：调用前先清空回调，让重复代理事件不会重复完成请求。
    private func finishRequest() {
        guard let completion else { return }
        self.completion = nil
        manager?.delegate = nil
        completion()
    }
}
