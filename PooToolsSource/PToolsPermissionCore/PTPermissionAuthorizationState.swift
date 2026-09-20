//
//  PTPermissionAuthorizationState.swift
//  PToolsPermissionCore
//
//  English: Normalized permission states shared by all system-service adapters.
//  Español: Estados de permiso normalizados compartidos por todos los adaptadores de servicios del sistema.
//  中文：所有系统服务适配器共享的统一权限状态。
//

import Foundation

#if !POOTOOLS_COCOAPODS

// English: Keep detailed states separate from the legacy four-value status so limited and provisional access is not lost.
// Español: Mantén los estados detallados separados del estado heredado de cuatro valores para no perder el acceso limitado o provisional.
// 中文：将详细状态与旧版四值状态分离，避免丢失受限、临时授权等信息。
public enum PTPermissionAuthorizationState: String, CaseIterable, Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
    case limited
    case unavailable
    case provisional
    case ephemeral

    public var isGranted: Bool {
        switch self {
        case .authorized, .limited, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied, .restricted, .unavailable:
            return false
        }
    }
}

// English: Describe Bluetooth hardware state without conflating it with authorization.
// Español: Describe el estado del hardware Bluetooth sin confundirlo con la autorización.
// 中文：描述蓝牙硬件状态，避免与授权状态混为一谈。
public enum PTBluetoothPermissionState: String, CaseIterable, Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
    case poweredOff
    case unsupported
    case resetting
    case unknown
}

// English: Keep biometric availability details available without exposing LocalAuthentication objects across actors.
// Español: Mantén los detalles de disponibilidad biométrica sin cruzar actores con objetos de LocalAuthentication.
// 中文：保留生物识别可用性详情，同时不让 LocalAuthentication 对象跨 actor 传递。
public enum PTFaceIDPermissionState: String, CaseIterable, Equatable, Sendable {
    case available
    case notEnrolled
    case lockedOut
    case passcodeFallback
    case unavailable
    case unknown
}
#endif
