//
//  PTPermissionNotification.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

@preconcurrency import UserNotifications
import os.lock
#if POOTOOLS_SPLIT_PERMISSION_CORE
import PToolsPermissionCore
#endif

public extension PTPermission {
    
    static var notification: PTPermissionNotification {
        PTPermissionNotification()
    }
}

public class PTPermissionNotification: PTPermission {

    private var cachedAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    public private(set) var isCriticalAlertAuthorized = false
    
    open override var kind: PTPermission.Kind { .notification }
    
    @MainActor public func authorizationStatus() async throws -> PTPermission.Status {
        _ = await refreshAuthorizationState()
        return status
    }
    
    public override var status: PTPermission.Status {
        switch cachedAuthorizationStatus {
        case .authorized: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .provisional: return .authorized
        case .ephemeral: return .authorized
        @unknown default: return .denied
        }
    }
    
    // English: Never block a caller with a semaphore; refresh settings through the system callback and publish a value snapshot.
    // Español: Nunca bloquees al llamador con un semáforo; actualiza mediante el callback del sistema y publica un snapshot de valores.
    // 中文：不再使用信号量阻塞调用方，通过系统回调异步刷新并发布值快照。
    @MainActor
    public func refreshAuthorizationState() async -> PTPermissionAuthorizationState {
        let snapshot = await withCheckedContinuation { continuation in
            let gate = OSAllocatedUnfairLock(initialState: false)
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                let shouldResume = gate.withLock { didResume in
                    guard !didResume else { return false }
                    didResume = true
                    return true
                }
                guard shouldResume else { return }
                continuation.resume(returning: (settings.authorizationStatus, settings.criticalAlertSetting == .enabled))
            }
        }
        cachedAuthorizationStatus = snapshot.0
        isCriticalAlertAuthorized = snapshot.1
        return normalizedState(for: snapshot.0)
    }

    @MainActor
    public func requestAuthorization() async -> PTPermissionAuthorizationState {
        await withCheckedContinuation { continuation in
            let gate = OSAllocatedUnfairLock(initialState: false)
            UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { _, _ in
                let shouldResume = gate.withLock { didResume in
                    guard !didResume else { return false }
                    didResume = true
                    return true
                }
                guard shouldResume else { return }
                continuation.resume()
            }
        }
        return await refreshAuthorizationState()
    }

    public override var authorizationState: PTPermissionAuthorizationState {
        normalizedState(for: cachedAuthorizationStatus)
    }

    // English: Expose notification capabilities as value state instead of leaking UNNotificationSettings across actors.
    // Español: Expone las capacidades de notificaciones como valores sin filtrar UNNotificationSettings entre actores.
    // 中文：以值类型暴露通知能力，避免让 UNNotificationSettings 跨 actor 传递。
    public var supportsProvisionalAuthorization: Bool { true }

    private func normalizedState(for status: UNAuthorizationStatus) -> PTPermissionAuthorizationState {
        switch status {
        case .authorized: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .provisional: return .provisional
        case .ephemeral: return .ephemeral
        @unknown default: return .unavailable
        }
    }
    
    public override func request(completion: @escaping PTActionTask) {
        let finish = PTPermission.makeCompletionOnce(completion)
        Task { @MainActor in
            _ = await requestAuthorization()
            finish()
        }
    }
}
