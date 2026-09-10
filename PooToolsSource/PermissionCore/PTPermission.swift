//
//  PTPermission.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

#if POOTOOLS_SPLIT_PERMISSION_CORE
import PToolsPermissionCore

// English: Map the legacy umbrella name to the standalone permission contract in SwiftPM only.
// Español: Mapea el nombre heredado del umbrella al contrato de permisos independiente solo en SwiftPM.
// 中文：仅在 SwiftPM 中将旧 umbrella 类型名映射到独立权限契约。
public typealias PTPermission = PToolsPermissionCore.PTPermission

@MainActor
public extension PTPermission {
    var localisedName: String {
        PTPermissionText.permission_name(for: kind)
    }
}
#else
import UIKit
import os.lock
#if POOTOOLS_PERMISSION_HEALTH
import HealthKit
#endif

@MainActor
open class PTPermission {
    
    open var authorized: Bool {
        status == .authorized
    }
    
    open var denied: Bool {
        status == .denied
    }
    
    open var notDetermined: Bool {
        status == .notDetermined
    }
    
    open var debugName: String {
        kind.name
    }
    
    @MainActor open var localisedName: String {
        PTPermissionText.permission_name(for: kind)
    }
    
    /**
     PermissionsKit: Open settings page.
     For most permissions its app page in settings app.
     You can overide it if your permission need open custom page.
     */
    @available(iOSApplicationExtension, unavailable)
    open func openSettingPage() {
        Task { @MainActor in
            PTOpenSystemFunction.openSystemFunction(config:  PTOpenSystemConfig())
        }
    }

    // English: Provide the canonical plural spelling while preserving the historical settings method.
    // Español: Proporciona la grafía plural canónica y conserva el método histórico de ajustes.
    // 中文：提供统一的复数命名，同时保留历史设置入口。
    @available(iOSApplicationExtension, unavailable)
    open func openSettings() {
        openSettingPage()
    }

    // English: Read the current normalized permission state without duplicating status access in callers.
    // Español: Lee el estado de permiso normalizado sin duplicar el acceso al estado en los llamadores.
    // 中文：读取统一的当前权限状态，避免调用方重复访问和映射。
    public func currentStatus() -> Status {
        status
    }
    
    // MARK: Must Ovveride
    
    open var kind: PTPermission.Kind {
        preconditionFailure("This method must be overridden.")
    }
    
    open var status: PTPermission.Status {
        preconditionFailure("This method must be overridden.")
    }
    
    open func request(completion: @escaping PTActionTask) {
        preconditionFailure("This method must be overridden.")
    }

    /// Shared callback bridge for system permission APIs that complete on an
    /// arbitrary queue. Permission subclasses only provide the system call;
    /// this helper owns the MainActor boundary.
    public nonisolated static func completeRequest(_ completion: @escaping PTActionTask) {
        Task { @MainActor in
            completion()
        }
    }

    // 统一权限状态映射，避免列表 Cell 和业务入口各自维护一份系统权限判断。
    // Unifica el mapeo de estados para que las celdas y las entradas de negocio no mantengan lógica duplicada.
    // Centralize permission status mapping so cells and business entry points do not duplicate it.
    public static func status(for kind: Kind) -> Status {
        switch kind {
        case .tracking:
#if POOTOOLS_PERMISSION_TRACKING
            return tracking.status
#else
            return .notSupported
#endif
        case .camera:
#if POOTOOLS_PERMISSION_CAMERA
            return camera.status
#else
            return .notSupported
#endif
        case .photoLibrary:
#if POOTOOLS_PERMISSION_PHOTO
            return photoLibrary.status
#else
            return .notSupported
#endif
        case .calendar(access: .full):
#if POOTOOLS_PERMISSION_CALENDAR
            return calendar(access: .full).status
#else
            return .notSupported
#endif
        case .calendar(access: .write):
#if POOTOOLS_PERMISSION_CALENDAR
            return calendar(access: .write).status
#else
            return .notSupported
#endif
        case .reminders:
#if POOTOOLS_PERMISSION_REMINDERS
            return reminders.status
#else
            return .notSupported
#endif
        case .notification:
#if POOTOOLS_PERMISSION_NOTIFICATION
            return notification.status
#else
            return .notSupported
#endif
        case .location(access: .whenInUse):
#if POOTOOLS_PERMISSION_LOCATION
            return location(access: .whenInUse).status
#else
            return .notSupported
#endif
        case .location(access: .always):
#if POOTOOLS_PERMISSION_LOCATION
            return location(access: .always).status
#else
            return .notSupported
#endif
        case .faceID:
#if POOTOOLS_PERMISSION_FACEIDPERMISSION
            return faceID.status
#else
            return .notSupported
#endif
        case .speech:
#if POOTOOLS_PERMISSION_SPEECH
            return speech.status
#else
            return .notSupported
#endif
        case .health:
#if POOTOOLS_PERMISSION_HEALTH
            guard let quantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) else {
                return .notSupported
            }
            return PTPermissionHealth.status(for: quantityType)
#else
            return .notSupported
#endif
        case .motion:
#if POOTOOLS_PERMISSION_MOTION
            return motion.status
#else
            return .notSupported
#endif
        case .contacts:
#if POOTOOLS_PERMISSION_CONTACTS
            return contacts.status
#else
            return .notSupported
#endif
        case .microphone:
#if POOTOOLS_PERMISSION_MIC
            return microphone.status
#else
            return .notSupported
#endif
        case .mediaLibrary:
#if POOTOOLS_PERMISSION_MEDIA
            return mediaLibrary.status
#else
            return .notSupported
#endif
        case .bluetooth:
#if POOTOOLS_PERMISSION_BLUETOOTH
            return bluetooth.status
#else
            return .notSupported
#endif
        case .siri:
#if POOTOOLS_PERMISSION_SIRI
            return siri.status
#else
            return .notSupported
#endif
        }
    }

    // English: Convert callback-based system permission APIs into an exactly-once MainActor result.
    // Español: Convierte las APIs de permisos basadas en callbacks en un resultado exactly-once en MainActor.
    // 中文：将基于回调的系统权限 API 转换为只完成一次的 MainActor 结果。
    public func requestStatus() async -> Status {
        await withCheckedContinuation { [weak self] continuation in
            let completionLock = OSAllocatedUnfairLock(initialState: false)
            guard let self else {
                continuation.resume(returning: .notSupported)
                return
            }
            self.request { [weak self] in
                let shouldResume = completionLock.withLock { didResume in
                    guard !didResume else { return false }
                    didResume = true
                    return true
                }
                guard shouldResume else { return }
                Task { @MainActor [weak self] in
                    continuation.resume(returning: self?.status ?? .notSupported)
                }
            }
        }
    }

    /// English: Preserve the old async API while routing it through the typed status result.
    /// Español: Conserva la API async antigua y la enruta mediante el resultado tipado de estado.
    /// 中文：保留旧 async API，并统一转发到类型化状态结果。
    public func request() async {
        _ = await requestStatus()
    }
    
    open var canBePresentWithCustomInterface: Bool {
        true
    }
    
    // MARK: Internal
    
    public init() {}
    
    // MARK: - Models
    
    @objc public enum Status: Int, CustomStringConvertible, Sendable {
        
        case authorized
        case denied
        case notDetermined
        case notSupported
        
        public var description: String {
            switch self {
            case .authorized: return "authorized"
            case .denied: return "denied"
            case .notDetermined: return "not determined"
            case .notSupported: return "not supported"
            }
        }
    }
    
    public enum Kind: Sendable {
        
        case camera
        case notification
        case photoLibrary
        case microphone
        case calendar(access: CalendarAccess)
        case contacts
        case reminders
        case speech
        case location(access: LocationAccess)
        case motion
        case mediaLibrary
        case bluetooth
        case tracking
        case faceID
        case siri
        case health
        
        public var name: String {
            switch self {
            case .camera:
                return "Camera"
            case .photoLibrary:
                return "Photo Library"
            case .microphone:
                return "Microphone"
            case .calendar(access: .write):
                return "Calendar Only Write"
            case .calendar(access: .full):
                return "Calendar"
            case .contacts:
                return "Contacts"
            case .reminders:
                return "Reminders"
            case .speech:
                return "Speech"
            case .location(access: .always):
                return "Location Always"
            case .location(access: .whenInUse):
                return "Location When Use"
            case .motion:
                return "Motion"
            case .mediaLibrary:
                return "Media Library"
            case .bluetooth:
                return "Bluetooth"
            case .notification:
                return "Notification"
            case .tracking:
                return "Tracking"
            case .faceID:
                return "FaceID"
            case .siri:
                return "Siri"
            case .health:
                return "Health"
            }
        }
    }
    
    public enum CalendarAccess: Sendable {
        
        case full
        case write
    }
    
    public enum LocationAccess: Sendable {
        
        case whenInUse
        case always
    }
}
#endif
