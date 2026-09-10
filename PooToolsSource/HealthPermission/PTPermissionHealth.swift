//
//  PTPermissionHealth.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import HealthKit
#if POOTOOLS_SPLIT_PERMISSION_CORE
import PToolsPermissionCore
#endif

public extension PTPermission {
    
    static var health: PTPermissionHealth {
        PTPermissionHealth()
    }
}

public class PTPermissionHealth: PTPermission {
    
    open override var kind: PTPermission.Kind { .health }
    
    open var readingUsageDescriptionKey: String? { "NSHealthUpdateUsageDescription" }
    open var writingUsageDescriptionKey: String? { "NSHealthShareUsageDescription" }
    
    public static func status(for type: HKObjectType) -> PTPermission.Status {
        switch HKHealthStore().authorizationStatus(for: type) {
        case .sharingAuthorized: return .authorized
        case .sharingDenied: return .denied
        case .notDetermined: return .notDetermined
        @unknown default: return .denied
        }
    }
    
    public static func request(forReading readingTypes: Set<HKObjectType>, writing writingTypes: Set<HKSampleType>, completion: @escaping PTActionTask) {
        HKHealthStore().requestAuthorization(toShare: writingTypes, read: readingTypes) { _, _ in
            PTPermission.completeRequest(completion)
        }
    }
    
    public override var canBePresentWithCustomInterface: Bool { false }
    
    // MARK: - Locked
    
    @available(*, unavailable)
    open override var authorized: Bool {
        // English: Health authorization requires an object type; return a safe fallback for base-class dispatch.
        // Español: La autorización de Health requiere un tipo de objeto; devuelve una alternativa segura para el despacho de la clase base.
        // 中文：Health 授权需要具体对象类型，基类动态分派时返回安全兜底值。
        false
    }
    
    @available(*, unavailable)
    open override var denied: Bool { false }
    
    @available(*, unavailable)
    open override var notDetermined: Bool { false }
    
    @available(*, unavailable)
    public override var status: PTPermission.Status { .notSupported }
    
    @available(*, unavailable)
    open override func request(completion: @escaping PTActionTask) {
        // English: Finish immediately so an erased health permission cannot trap or suspend an async caller.
        // Español: Finaliza inmediatamente para que un permiso Health borrado no bloquee ni provoque un trap al llamador async.
        // 中文：立即完成请求，避免类型擦除后的 Health 权限触发崩溃或让异步调用永久等待。
        PTPermission.completeRequest(completion)
    }
}
