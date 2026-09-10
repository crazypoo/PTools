//
//  PTPermissionCore.swift
//  PToolsPermissionCore
//
//  Foundation-only permission contracts and exactly-once request bridging.
//  Contratos de permisos basados solo en Foundation y puente de solicitud exactly-once.
//  仅依赖 Foundation 的权限契约与只完成一次的请求桥接。
//

import Foundation
import os.lock

// English: Keep the legacy callback shape available to standalone system-service targets.
// Español: Mantiene disponible la forma de callback heredada para los targets independientes de servicios del sistema.
// 中文：为独立系统服务 target 保留旧版回调形态。
public typealias PTActionTask = @Sendable () -> Void

public enum PTPermissionStatus: Int, CustomStringConvertible, Equatable, Sendable {
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

public enum PTPermissionCalendarAccess: Sendable, Equatable {
    case full
    case write
}

public enum PTPermissionLocationAccess: Sendable, Equatable {
    case whenInUse
    case always
}

public enum PTPermissionKind: Sendable, Equatable {
    case camera
    case notification
    case photoLibrary
    case microphone
    case calendar(access: PTPermissionCalendarAccess)
    case contacts
    case reminders
    case speech
    case location(access: PTPermissionLocationAccess)
    case motion
    case mediaLibrary
    case bluetooth
    case tracking
    case faceID
    case siri
    case health
    case custom(String)

    public var name: String {
        switch self {
        case .camera: return "Camera"
        case .notification: return "Notification"
        case .photoLibrary: return "Photo Library"
        case .microphone: return "Microphone"
        case .calendar(access: .write): return "Calendar Only Write"
        case .calendar(access: .full): return "Calendar"
        case .contacts: return "Contacts"
        case .reminders: return "Reminders"
        case .speech: return "Speech"
        case .location(access: .always): return "Location Always"
        case .location(access: .whenInUse): return "Location When Use"
        case .motion: return "Motion"
        case .mediaLibrary: return "Media Library"
        case .bluetooth: return "Bluetooth"
        case .tracking: return "Tracking"
        case .faceID: return "FaceID"
        case .siri: return "Siri"
        case .health: return "Health"
        case .custom(let value): return value
        }
    }
}

public enum PTPermissionError: Error, Equatable, Sendable, CustomStringConvertible {
    case notSupported
    case requestCancelled
    case missingUsageDescription(String)
    case requestFailed(String)

    public var description: String {
        switch self {
        case .notSupported: return "Permission is not supported."
        case .requestCancelled: return "Permission request was cancelled."
        case .missingUsageDescription(let key): return "Missing usage description: \(key)"
        case .requestFailed(let message): return message
        }
    }
}

public struct PTPermissionResult: Equatable, Sendable {
    public let kind: PTPermissionKind
    public let status: PTPermissionStatus
    public let error: PTPermissionError?
    public let didRequest: Bool

    public init(kind: PTPermissionKind,
                status: PTPermissionStatus,
                error: PTPermissionError? = nil,
                didRequest: Bool = true) {
        self.kind = kind
        self.status = status
        self.error = error
        self.didRequest = didRequest
    }
}

// English: This protocol is MainActor-isolated because concrete services own system objects and delegate callbacks.
// Español: Este protocolo está aislado en MainActor porque los servicios concretos poseen objetos del sistema y callbacks de delegados.
// 中文：该协议隔离在 MainActor，因为具体服务持有系统对象并处理代理回调。
@MainActor
public protocol PTPermissionRequesting: AnyObject {
    var kind: PTPermissionKind { get }
    var status: PTPermissionStatus { get }
    func request(completion: @escaping PTActionTask)
    func requestStatus() async -> PTPermissionStatus
    func request() async -> PTPermissionResult
}

// English: The settings URL is a value-only boundary; UIKit decides how to present it in the optional UI layer.
// Español: La URL de ajustes es un límite de solo valores; UIKit decide cómo presentarla en la capa UI opcional.
// 中文：设置页 URL 是纯值边界，具体展示方式由可选的 UIKit UI 层决定。
public enum PTPermissionSettings {
    public static let applicationURL = URL(string: "app-settings:")
}

// English: Install the UI opener only from a UI-capable integration; the core never imports UIApplication.
// Español: Instala el abridor UI solo desde una integración compatible con UI; el núcleo nunca importa UIApplication.
// 中文：仅由具备 UI 能力的集成安装设置页打开器，Core 不直接导入 UIApplication。
@MainActor
public enum PTPermissionSettingsRouter {
    private static var handler: (@MainActor @Sendable (URL?) -> Void)?

    public static func install(_ handler: @escaping @MainActor @Sendable (URL?) -> Void) {
        self.handler = handler
    }

    public static func open(_ url: URL? = PTPermissionSettings.applicationURL) {
        handler?(url)
    }
}

@MainActor
open class PTPermission: PTPermissionRequesting {
    public typealias Status = PTPermissionStatus
    public typealias Kind = PTPermissionKind
    public typealias CalendarAccess = PTPermissionCalendarAccess
    public typealias LocationAccess = PTPermissionLocationAccess

    open var authorized: Bool { status == .authorized }
    open var denied: Bool { status == .denied }
    open var notDetermined: Bool { status == .notDetermined }
    open var debugName: String { kind.name }

    open var kind: Kind { .custom(String(describing: type(of: self))) }
    open var status: Status { .notSupported }
    open var settingsURL: URL? { PTPermissionSettings.applicationURL }
    open var canBePresentWithCustomInterface: Bool { true }

    // English: Provide a safe fallback for compatibility UIs when the concrete permission target is not linked.
    // Español: Proporciona una alternativa segura para las UI compatibles cuando no se enlaza el target de permiso concreto.
    // 中文：当具体权限 target 未链接时，为兼容 UI 提供安全的兜底状态。
    public static func status(for kind: Kind) -> Status {
        .notSupported
    }

    public init() {}

    // English: The base implementation completes immediately instead of trapping, so an unsupported service cannot crash a caller.
    // Español: La implementación base finaliza inmediatamente en lugar de provocar un trap, para que un servicio no compatible no bloquee al llamador.
    // 中文：基类实现直接完成而不是触发 trap，避免不支持的服务导致调用方崩溃。
    open func request(completion: @escaping PTActionTask) {
        Self.completeRequest(completion)
    }

    public func currentStatus() -> Status { status }

    public nonisolated static func completeRequest(_ completion: @escaping @MainActor @Sendable () -> Void) {
        Task { @MainActor in
            guard !Task.isCancelled else { return }
            completion()
        }
    }

    public func requestStatus() async -> Status {
        if status != .notDetermined {
            return status
        }

        return await withCheckedContinuation { [weak self] continuation in
            let gate = OSAllocatedUnfairLock(initialState: false)
            guard let self else {
                continuation.resume(returning: .notSupported)
                return
            }

            self.request { [weak self] in
                let shouldResume = gate.withLock { didResume in
                    guard !didResume else { return false }
                    didResume = true
                    return true
                }
                guard shouldResume else { return }
                Task { @MainActor in
                    continuation.resume(returning: self?.status ?? .notSupported)
                }
            }
        }
    }

    @discardableResult
    public func request() async -> PTPermissionResult {
        let status = await requestStatus()
        let error: PTPermissionError? = status == .notSupported ? .notSupported : nil
        return PTPermissionResult(kind: kind, status: status, error: error)
    }

    @available(iOSApplicationExtension, unavailable)
    open func openSettingPage() {
        PTPermissionSettingsRouter.open(settingsURL)
    }

    @available(iOSApplicationExtension, unavailable)
    open func openSettings() {
        openSettingPage()
    }
}
