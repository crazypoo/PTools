//
//  PTPermissionHealth.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import HealthKit

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
    
    public static func request(forReading readingTypes: Set<HKObjectType>, writing writingTypes: Set<HKSampleType>, completion: @escaping () -> Void) {
        HKHealthStore().requestAuthorization(toShare: writingTypes, read: readingTypes) { _, _ in
            PTGCDManager.gcdMain {
                completion()
            }
        }
    }
    
    public override var canBePresentWithCustomInterface: Bool { false }
    
    // MARK: - Locked
    
    @available(*, unavailable)
    open override var authorized: Bool { fatalError() }
    
    @available(*, unavailable)
    open override var denied: Bool { fatalError() }
    
    @available(*, unavailable)
    open override var notDetermined: Bool { fatalError() }
    
    @available(*, unavailable)
    public override var status: PTPermission.Status { fatalError() }
    
    @available(*, unavailable)
    open override func request(completion: @escaping ()->Void) { fatalError() }
}
