// English: PTDevice is a small value-oriented facade over static identity and dynamic system capability checks.
// Español: PTDevice es una fachada pequeña y orientada a valores sobre la identidad estática y las capacidades dinámicas.
// 中文：PTDevice 是面向值的轻量门面，负责静态身份和动态系统能力查询。

import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AVFoundation)
import AVFoundation
#endif

#if canImport(LocalAuthentication)
import LocalAuthentication
#endif

public struct PTDevice: Sendable, CustomStringConvertible, PTDeviceCapabilityProviding {
    public static let current = PTDevice(runtime: PTDeviceRuntimeResolver.resolve())

    public let runtime: PTDeviceRuntimeInfo
    public let model: PTDeviceModel
    public let specification: PTDeviceSpecification?
    public let platform: PTDevicePlatform
    public let family: PTDeviceFamily

    public init(runtime: PTDeviceRuntimeInfo) {
        self.runtime = runtime
        let catalogSpecification = PTDeviceCatalog.specification(for: runtime.identifier)
        let inferredFamily = Self.inferFamily(identifier: runtime.identifier, specification: catalogSpecification)
        let inferredPlatform = Self.inferPlatform(identifier: runtime.identifier, specification: catalogSpecification)
        self.model = catalogSpecification?.model ?? PTDeviceModel("unknown:\(runtime.identifier)")
        self.specification = catalogSpecification
        self.platform = inferredPlatform
        self.family = inferredFamily
    }

    public var identifier: String { runtime.identifier }
    public var environment: PTDeviceEnvironment { runtime.environment }
    public var architecture: PTDeviceArchitecture { runtime.architecture }
    public var isSimulator: Bool { environment == .simulator }
    public var isPad: Bool { family == .iPad }
    public var isPhone: Bool { family == .iPhone }
    public var description: String { specification?.marketingName ?? identifier }

    public func isOneOf(_ models: [PTDeviceModel]) -> Bool {
        models.contains(model)
    }

    public func status(for capability: PTDeviceCapability) async -> PTDeviceCapabilityStatus {
        await PTDeviceCapabilityResolver.status(for: capability, device: self)
    }

    @MainActor
    public var batteryState: PTBatteryState {
        #if canImport(UIKit)
        switch UIDevice.current.batteryState {
        case .unplugged: return .unplugged
        case .charging: return .charging
        case .full: return .full
        case .unknown: return .unknown
        @unknown default: return .unknown
        }
        #else
        return .unknown
        #endif
    }

    @MainActor
    public var batteryLevel: Float {
        #if canImport(UIKit)
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryLevel
        #else
        return -1
        #endif
    }

    public var isFaceIDCapable: Bool {
        if specification?.traits.isFaceIDCapable == true { return true }
        #if canImport(LocalAuthentication)
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else { return false }
        return context.biometryType == .faceID
        #else
        return false
        #endif
    }

    public var isTouchIDCapable: Bool {
        if specification?.traits.isTouchIDCapable == true { return true }
        #if canImport(LocalAuthentication)
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else { return false }
        return context.biometryType == .touchID
        #else
        return false
        #endif
    }

    public var hasBiometricSensor: Bool { isFaceIDCapable || isTouchIDCapable }
    public var hasSensorHousing: Bool { specification?.traits.hasSensorHousing ?? false }
    public var hasRoundedDisplayCorners: Bool { specification?.traits.hasRoundedDisplayCorners ?? false }
    public var has3dTouchSupport: Bool { specification?.traits.has3dTouchSupport ?? false }
    public var supportsWirelessCharging: Bool { specification?.traits.supportsWirelessCharging ?? false }
    public var hasLidarSensor: Bool {
        if specification?.traits.hasLidarSensor == true { return true }
        #if canImport(AVFoundation) && (os(iOS) || os(tvOS) || os(watchOS))
        return AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) != nil
        #else
        return false
        #endif
    }
    public var ppi: Int? { specification?.traits.ppi }

    public var hasCamera: Bool {
        #if canImport(AVFoundation) && (os(iOS) || os(tvOS) || os(watchOS))
        AVCaptureDevice.default(for: .video) != nil
        #else
        false
        #endif
    }

    public var hasWideCamera: Bool {
        #if canImport(AVFoundation) && (os(iOS) || os(tvOS) || os(watchOS))
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil
        #else
        false
        #endif
    }

    public var hasTelephotoCamera: Bool {
        #if canImport(AVFoundation) && (os(iOS) || os(tvOS) || os(watchOS))
        AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back) != nil
        #else
        false
        #endif
    }

    public var hasUltraWideCamera: Bool {
        #if canImport(AVFoundation) && (os(iOS) || os(tvOS) || os(watchOS))
        AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) != nil
        #else
        false
        #endif
    }

    @MainActor
    public var isGuidedAccessSessionActive: Bool {
        #if canImport(UIKit)
        UIAccessibility.isGuidedAccessEnabled
        #else
        false
        #endif
    }

    public static var volumeTotalCapacity: Int64? { volumeValue(.volumeTotalCapacityKey) }
    public static var volumeAvailableCapacity: Int64? { volumeValue(.volumeAvailableCapacityKey) }
    public static var volumeAvailableCapacityForImportantUsage: Int64? { volumeValue(.volumeAvailableCapacityForImportantUsageKey) }
    public static var volumeAvailableCapacityForOpportunisticUsage: Int64? { volumeValue(.volumeAvailableCapacityForOpportunisticUsageKey) }
    public static var volumes: String { String(volumeTotalCapacity ?? 0) }

    private static func volumeValue(_ key: URLResourceKey) -> Int64? {
        guard let values = try? URL(fileURLWithPath: NSHomeDirectory()).resourceValues(forKeys: [key]) else { return nil }
        if let value = values.allValues[key] as? NSNumber { return value.int64Value }
        return values.allValues[key] as? Int64
    }

    private static func inferFamily(identifier: String, specification: PTDeviceSpecification?) -> PTDeviceFamily {
        if let family = specification?.family { return family }
        switch identifier {
        case _ where identifier.hasPrefix("iPhone"): return .iPhone
        case _ where identifier.hasPrefix("iPad"): return .iPad
        case _ where identifier.hasPrefix("iPod"): return .iPod
        case _ where identifier.hasPrefix("Watch"): return .appleWatch
        case _ where identifier.hasPrefix("AppleTV"): return .appleTV
        case _ where identifier.hasPrefix("AudioAccessory"): return .homePod
        case _ where identifier.lowercased().contains("vision"): return .appleVision
        case _ where identifier.hasPrefix("Mac"): return .mac
        default: return .unknown
        }
    }

    private static func inferPlatform(identifier: String, specification: PTDeviceSpecification?) -> PTDevicePlatform {
        if let platform = specification?.platform { return platform }
        switch identifier {
        case _ where identifier.hasPrefix("iPad"): return .iPadOS
        case _ where identifier.hasPrefix("Watch"): return .watchOS
        case _ where identifier.hasPrefix("AppleTV"): return .tvOS
        case _ where identifier.hasPrefix("Mac"): return .macOS
        case _ where identifier.hasPrefix("Reality"): return .visionOS
        case _ where identifier.hasPrefix("iPhone") || identifier.hasPrefix("iPod"): return .iOS
        default: return .unknown
        }
    }
}
