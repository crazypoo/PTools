//
//  PTPermissionLocationAlwaysHandler.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import CoreLocation
#if POOTOOLS_SPLIT_PERMISSION_CORE
import PToolsPermissionCore
#endif

@MainActor
class PTPermissionLocationAlwaysHandler: NSObject, @preconcurrency CLLocationManagerDelegate {
    
    // MARK: - Location Manager
    
    lazy var locationManager = CLLocationManager()
    
    @MainActor func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .notDetermined {
            return
        }
        finishRequest()
    }
  
    @MainActor func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .notDetermined {
            return
        }
        finishRequest()
    }
    
    // MARK: - Process
    
    // English: Keep repeated callers attached to the same system authorization flow.
    // Español: Mantén los llamadores repetidos vinculados al mismo flujo de autorización del sistema.
    // 中文：让重复调用方复用同一次系统授权流程。
    private var completionHandlers: [PTActionTask] = []

    // English: Finish once and detach the delegate before forwarding the result to the permission bridge.
    // Español: Finaliza una sola vez y separa el delegado antes de reenviar el resultado al puente de permisos.
    // 中文：在通过权限桥接转发结果前只完成一次，并先解除代理关系。
    private func finishRequest() {
        guard !completionHandlers.isEmpty else { return }
        let completionHandlers = self.completionHandlers
        self.completionHandlers.removeAll(keepingCapacity: false)
        locationManager.delegate = nil
        completionHandlers.forEach { $0() }
    }
    
    @MainActor func requestPermission(_ completionHandler: @escaping PTActionTask) {
        completionHandlers.append(completionHandler)
        
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            locationManager.delegate = self
            locationManager.requestAlwaysAuthorization()
        case .authorizedWhenInUse:
            locationManager.delegate = self
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            finishRequest()
        default:
            finishRequest()
        }
    }
    
    // MARK: - Init
    
    static var shared: PTPermissionLocationAlwaysHandler?
    
    override init() {
        super.init()
    }
    
}
