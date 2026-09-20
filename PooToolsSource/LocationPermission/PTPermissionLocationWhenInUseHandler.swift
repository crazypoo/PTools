//
//  PTPermissionLocationWhenInUseHandler.swift
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
class PTPermissionLocationWhenInUseHandler: NSObject, @preconcurrency CLLocationManagerDelegate {
    
    // MARK: - Location Manager
    
    lazy var locationManager = CLLocationManager()
    
#if !os(visionOS)
    @MainActor func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .notDetermined {
            return
        }
        finishRequest()
    }
#endif

    @MainActor @available(iOS 14.0, macOS 11.0, watchOS 7.0, tvOS 14.0, visionOS 1.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .notDetermined {
            return
        }
        finishRequest()
    }
    
    // MARK: - Process
    
    // English: Keep every caller while one system prompt is active instead of overwriting the previous callback.
    // Español: Conserva todos los llamadores mientras el diálogo del sistema está activo en lugar de sobrescribir el callback anterior.
    // 中文：系统弹窗进行期间保留所有调用方，避免新的请求覆盖旧回调。
    private var completionHandlers: [PTActionTask] = []

    // English: Finish once and release the delegate as soon as authorization reaches a terminal state.
    // Español: Finaliza una sola vez y libera el delegado cuando la autorización llega a un estado terminal.
    // 中文：授权进入终态后只完成一次，并立即释放代理，避免重复回调和代理滞留。
    private func finishRequest() {
        guard !completionHandlers.isEmpty else { return }
        let completionHandlers = self.completionHandlers
        self.completionHandlers.removeAll(keepingCapacity: false)
        locationManager.delegate = nil
        completionHandlers.forEach { $0() }
    }
    
    @MainActor func requestPermission(_ completionHandler: @escaping PTActionTask) {
        completionHandlers.append(completionHandler)
        
        let status: CLAuthorizationStatus = {
            #if os(visionOS)
            locationManager.authorizationStatus
            #elseif os(macOS)
            locationManager.authorizationStatus
            #else
            locationManager.authorizationStatus
            #endif
        }()

        switch status {
        case .notDetermined:
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            finishRequest()
        default:
            finishRequest()
        }
    }
    
    // MARK: - Init
    
    @MainActor static var shared: PTPermissionLocationWhenInUseHandler?
    
    override init() {
        super.init()
    }
    
}
