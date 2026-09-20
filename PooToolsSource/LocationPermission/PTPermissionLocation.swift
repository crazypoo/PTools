//
//  PTPermissionLocation.swift
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

public extension PTPermission {
    
    static func location(access: LocationAccess) -> PTPermissionLocation {
        PTPermissionLocation(kind: .location(access: access))
    }
}

// English: Keep reduced and full location accuracy as a value-only state.
// Español: Conserva la precisión reducida y completa como un estado basado en valores.
// 中文：将 reduced/full 定位精度表示为纯值状态。
public enum PTLocationAccuracyState: String, Sendable {
    case full
    case reduced
    case unavailable
}

public class PTPermissionLocation: PTPermission {
    
    private var _kind: PTPermission.Kind
    private var accuracyManager: CLLocationManager?
    
    // MARK: - Init
    
    init(kind: PTPermission.Kind) {
        _kind = kind
    }
    
    open override var kind: PTPermission.Kind { _kind }
    open var usageDescriptionKey: String? {
        switch _kind {
        case .location(let access):
            switch access {
            case .whenInUse:
                return "NSLocationWhenInUseUsageDescription"
            case .always:
                return "NSLocationAlwaysAndWhenInUseUsageDescription"
            }
        default:
            // English: The factory only creates location kinds; return no key instead of crashing on an invalid internal value.
            // Español: La fábrica solo crea tipos de ubicación; devuelve ninguna clave en lugar de bloquear ante un valor interno inválido.
            // 中文：工厂只会创建定位类型，内部值异常时返回空键，不让权限查询崩溃。
            return nil
        }
    }
    
    public override var status: PTPermission.Status {
        let result: CLAuthorizationStatus
        let locationManager = CLLocationManager()
        result = locationManager.authorizationStatus
        let authorizationStatus: CLAuthorizationStatus = result

        switch authorizationStatus {
            #if os(iOS)
        case .authorized: return .authorized
            #endif
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .denied
        case .authorizedAlways:
            if case .location(let access) = _kind, access == .always {
                return .authorized
            }
            return .denied
        case .authorizedWhenInUse:
            if case .location(let access) = _kind, access == .whenInUse {
                return .authorized
            }
            return .denied
        @unknown default: return .denied
        }
    }

    // English: Preserve restricted access as restricted instead of collapsing it into denied.
    // Español: Conserva el acceso restringido como restringido en lugar de convertirlo en denegado.
    // 中文：保留 restricted 状态，不再将其错误折叠为 denied。
    public override var authorizationState: PTPermissionAuthorizationState {
        let status = CLLocationManager().authorizationStatus
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorizedAlways:
            if case .location(let access) = _kind, access == .always { return .authorized }
            return .denied
        case .authorizedWhenInUse:
            if case .location(let access) = _kind, access == .whenInUse { return .authorized }
            return .denied
        #if os(iOS)
        case .authorized:
            return .authorized
        #endif
        @unknown default:
            return .unavailable
        }
    }
    
    public var isPrecise: Bool {
        #if os(iOS)
        switch CLLocationManager().accuracyAuthorization {
        case .fullAccuracy: return true
        case .reducedAccuracy: return false
        @unknown default: return false
        }
        #else
        return false
        #endif
    }

    public var accuracyState: PTLocationAccuracyState {
        #if os(iOS)
        switch CLLocationManager().accuracyAuthorization {
        case .fullAccuracy: return .full
        case .reducedAccuracy: return .reduced
        @unknown default: return .unavailable
        }
        #else
        return .unavailable
        #endif
    }

    @available(iOS 14.0, *)
    public func requestTemporaryFullAccuracy(purposeKey: String, completion: @escaping PTActionTask) {
        let manager = CLLocationManager()
        accuracyManager = manager
        let finish = PTPermission.makeCompletionOnce(completion)
        manager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: purposeKey) { _ in
            finish()
            Task { @MainActor in
                self.accuracyManager = nil
            }
        }
    }
    
    public override func request(completion: @escaping PTActionTask) {
        let finish = PTPermission.makeCompletionOnce(completion)
        switch _kind {
        case .location(let access):
            switch access {
            case .whenInUse:
                if PTPermissionLocationWhenInUseHandler.shared == nil {
                    PTPermissionLocationWhenInUseHandler.shared = PTPermissionLocationWhenInUseHandler()
                }
                PTPermissionLocationWhenInUseHandler.shared?.requestPermission {
                    // English: The system callback may outlive the request call; keep cleanup on MainActor.
                    // Español: El callback del sistema puede sobrevivir a la llamada; mantiene la limpieza en MainActor.
                    // 中文：系统回调可能晚于请求调用返回，因此统一在 MainActor 上完成回收。
#if POOTOOLS_SPLIT_PERMISSION_CORE
                    PTPermission.completeRequest { @MainActor in
                        finish()
                        PTPermissionLocationWhenInUseHandler.shared = nil
                    }
#else
                    PTMainActorBridge.perform {
                        finish()
                        PTPermissionLocationWhenInUseHandler.shared = nil
                    }
#endif
                }
            case .always:
                if PTPermissionLocationAlwaysHandler.shared == nil {
                    PTPermissionLocationAlwaysHandler.shared = PTPermissionLocationAlwaysHandler()
                }
                PTPermissionLocationAlwaysHandler.shared?.requestPermission {
                    // English: Use the same callback bridge for both location authorization modes.
                    // Español: Usa el mismo puente de callback para los dos modos de autorización de ubicación.
                    // 中文：两种定位授权模式统一使用同一个回调桥接入口。
#if POOTOOLS_SPLIT_PERMISSION_CORE
                    PTPermission.completeRequest { @MainActor in
                        finish()
                        PTPermissionLocationAlwaysHandler.shared = nil
                    }
#else
                    PTMainActorBridge.perform {
                        finish()
                        PTPermissionLocationAlwaysHandler.shared = nil
                    }
#endif
                }
        }
        default:
            // English: Complete unexpected input safely so a malformed internal kind cannot suspend the caller.
            // Español: Finaliza de forma segura una entrada inesperada para que un tipo interno erróneo no suspenda al llamador.
            // 中文：安全完成异常输入，避免错误的内部类型让调用方永久等待。
#if POOTOOLS_SPLIT_PERMISSION_CORE
            finish()
#else
            PTMainActorBridge.perform(finish)
#endif
        }
    }
}
