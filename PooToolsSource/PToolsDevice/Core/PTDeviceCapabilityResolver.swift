// English: Capability checks use public Apple APIs and report uncertainty instead of guessing from a model name.
// Español: Las capacidades usan APIs públicas de Apple e informan incertidumbre en vez de adivinar por el modelo.
// 中文：能力检测使用 Apple 公开 API，无法确认时返回未知，不根据机型名称猜测。

import Foundation

#if canImport(AVFoundation)
import AVFoundation
#endif

#if canImport(CoreMotion)
import CoreMotion
#endif

#if canImport(CoreLocation)
import CoreLocation
#endif

#if canImport(CoreNFC)
import CoreNFC
#endif

public enum PTDeviceCapabilityResolver {
    public static func status(for capability: PTDeviceCapability, device: PTDevice) async -> PTDeviceCapabilityStatus {
        if device.isSimulator {
            switch capability {
            case .location, .externalDisplay:
                return .available
            case .camera:
                #if canImport(AVFoundation)
                return AVCaptureDevice.default(for: .video) == nil ? .unavailableOnSimulator : .available
                #else
                return .unavailableOnSimulator
                #endif
            default:
                return .unavailableOnSimulator
            }
        }

        switch capability {
        case .camera:
            #if canImport(AVFoundation) && (os(iOS) || os(tvOS) || os(watchOS))
            return AVCaptureDevice.default(for: .video) == nil ? .unavailable : .available
            #else
            return .unsupported
            #endif
        case .microphone:
            #if canImport(AVFoundation) && (os(iOS) || os(tvOS) || os(watchOS))
            return AVAudioApplication.shared.recordPermission == .denied ? .permissionDenied : .available
            #else
            return .unsupported
            #endif
        case .biometrics:
            return device.hasBiometricSensor ? .available : .unsupported
        case .faceID:
            return device.isFaceIDCapable ? .available : .unsupported
        case .touchID:
            return device.isTouchIDCapable ? .available : .unsupported
        case .nfc:
            #if canImport(CoreNFC)
            return NFCNDEFReaderSession.readingAvailable ? .available : .unsupported
            #else
            return .unsupported
            #endif
        case .motion:
            #if canImport(CoreMotion) && (os(iOS) || os(tvOS) || os(watchOS))
            return CMMotionManager().isDeviceMotionAvailable ? .available : .unsupported
            #else
            return .unsupported
            #endif
        case .location:
            #if canImport(CoreLocation)
            return CLLocationManager.locationServicesEnabled() ? .available : .restricted
            #else
            return .unsupported
            #endif
        case .cellular:
            #if canImport(CoreTelephony)
            return .available
            #else
            return .unsupported
            #endif
        case .lidar:
            return device.hasLidarSensor ? .available : .unsupported
        case .spatialTracking, .handTracking:
            return device.platform == .visionOS ? .available : .unsupported
        case .externalDisplay:
            return .available
        }
    }
}

public struct PTSystemDeviceCapabilityProvider: PTDeviceCapabilityProviding {
    public let device: PTDevice

    public init(device: PTDevice = .current) {
        self.device = device
    }

    public func status(for capability: PTDeviceCapability) async -> PTDeviceCapabilityStatus {
        await PTDeviceCapabilityResolver.status(for: capability, device: device)
    }
}
