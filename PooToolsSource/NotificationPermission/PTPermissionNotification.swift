//
//  PTPermissionNotification.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

@preconcurrency import UserNotifications

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
        guard let authorizationStatus = fetchAuthorizationStatus() else { return .notDetermined }
        switch authorizationStatus {
        case .authorized: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .provisional: return .authorized
        case .ephemeral: return .authorized
        @unknown default: return .denied
        }
    }
    
    private func fetchAuthorizationStatus() -> UNAuthorizationStatus? {
        var notificationSettings: UNNotificationSettings?
        let semaphore = DispatchSemaphore(value: 0)
        PTGCDManager.gcdGobalNormal {
            UNUserNotificationCenter.current().getNotificationSettings { setttings in
                notificationSettings = setttings
                semaphore.signal()
            }
        }
        semaphore.wait()
        return notificationSettings?.authorizationStatus
    }
    
    public override func request(completion: @escaping PTActionTask) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in
            PTGCDManager.gcdMain {
                completion()
            }
        }
    }
}
