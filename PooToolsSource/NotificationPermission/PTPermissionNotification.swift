//
//  PTPermissionNotification.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

@preconcurrency import UserNotifications

private final class ResultBox<T>: @unchecked Sendable {
    var value: T?
    init() {}
}

public extension PTPermission {
    
    static var notification: PTPermissionNotification {
        PTPermissionNotification()
    }
}

public class PTPermissionNotification: PTPermission {
    
    open override var kind: PTPermission.Kind { .notification }
    
    @MainActor public func authorizationStatus() async throws -> PTPermission.Status {
        return try await withCheckedThrowingContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                switch settings.authorizationStatus {
                case .authorized:
                    continuation.resume(returning: PTPermission.Status.authorized)
                case .denied:
                    continuation.resume(returning: PTPermission.Status.denied)
                case .notDetermined:
                    continuation.resume(returning: PTPermission.Status.notDetermined)
                case .provisional:
                    continuation.resume(returning: PTPermission.Status.authorized)
                case .ephemeral:
                    continuation.resume(returning: PTPermission.Status.authorized)
                @unknown default:
                    continuation.resume(returning: PTPermission.Status.denied)
                }
            }
        }
    }
    
    public override var status: PTPermission.Status {
        let authorizationStatus = fetchAuthorizationStatus()
        switch authorizationStatus {
        case .authorized: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .provisional: return .authorized
        case .ephemeral: return .authorized
        @unknown default: return .denied
        }
    }
    
    private func fetchAuthorizationStatus() -> UNAuthorizationStatus {
        let box = ResultBox<UNAuthorizationStatus>()
        let semaphore = DispatchSemaphore(value: 0)
        
        // 2. 优化点：直接调用系统 API，无需再包一层 runOnBackground
        // 系统内部会自动在子线程获取设置并回调
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            box.value = settings.authorizationStatus
            semaphore.signal()
        }
        
        semaphore.wait()
        return box.value ?? .notDetermined
    }
    
    public override func request(completion: @escaping PTActionTask) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in
            PTGCDManager.shared.runOnMain {
                completion()
            }
        }
    }
}
