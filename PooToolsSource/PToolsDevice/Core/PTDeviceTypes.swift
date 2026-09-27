// English: Foundation-only value contracts for device identity and capabilities.
// Español: Contratos de valor basados solo en Foundation para la identidad y las capacidades.
// 中文：仅依赖 Foundation 的设备身份和能力值类型契约。

import Foundation

public enum PTDevicePlatform: String, CaseIterable, Codable, Sendable {
    case iOS
    case iPadOS
    case tvOS
    case watchOS
    case macOS
    case visionOS
    case unknown
}

public enum PTDeviceFamily: String, CaseIterable, Codable, Sendable {
    case iPhone
    case iPad
    case iPod
    case appleTV
    case appleWatch
    case mac
    case homePod
    case appleVision
    case unknown
}

public enum PTDeviceEnvironment: String, Codable, Sendable {
    case physical
    case simulator
}

public enum PTDeviceArchitecture: String, Codable, Sendable {
    case arm64
    case x86_64
    case unknown
}

public enum PTDeviceFormFactor: String, Codable, Sendable {
    case phone
    case tablet
    case mediaPlayer
    case watch
    case desktop
    case speaker
    case headset
    case unknown
}

public struct PTDeviceModel: RawRepresentable, Hashable, Codable, Sendable, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }

    public var description: String { rawValue }

    public var isUnknown: Bool {
        rawValue.hasPrefix("unknown:")
    }
}

public struct PTDeviceStaticTraits: Codable, Hashable, Sendable {
    public let hasSensorHousing: Bool
    public let hasRoundedDisplayCorners: Bool
    public let has3dTouchSupport: Bool
    public let supportsWirelessCharging: Bool
    public let hasLidarSensor: Bool
    public let isFaceIDCapable: Bool
    public let isTouchIDCapable: Bool
    public let ppi: Int?

    public init(
        hasSensorHousing: Bool = false,
        hasRoundedDisplayCorners: Bool = false,
        has3dTouchSupport: Bool = false,
        supportsWirelessCharging: Bool = false,
        hasLidarSensor: Bool = false,
        isFaceIDCapable: Bool = false,
        isTouchIDCapable: Bool = false,
        ppi: Int? = nil
    ) {
        self.hasSensorHousing = hasSensorHousing
        self.hasRoundedDisplayCorners = hasRoundedDisplayCorners
        self.has3dTouchSupport = has3dTouchSupport
        self.supportsWirelessCharging = supportsWirelessCharging
        self.hasLidarSensor = hasLidarSensor
        self.isFaceIDCapable = isFaceIDCapable
        self.isTouchIDCapable = isTouchIDCapable
        self.ppi = ppi
    }
}

public struct PTDeviceSpecification: Codable, Hashable, Sendable {
    public let model: PTDeviceModel
    public let marketingName: String
    public let identifiers: [String]
    public let family: PTDeviceFamily
    public let platform: PTDevicePlatform
    public let releaseYear: Int?
    public let formFactor: PTDeviceFormFactor
    public let processorFamily: String?
    public let traits: PTDeviceStaticTraits

    public init(
        model: PTDeviceModel,
        marketingName: String,
        identifiers: [String],
        family: PTDeviceFamily,
        platform: PTDevicePlatform,
        releaseYear: Int? = nil,
        formFactor: PTDeviceFormFactor,
        processorFamily: String? = nil,
        traits: PTDeviceStaticTraits = .init()
    ) {
        self.model = model
        self.marketingName = marketingName
        self.identifiers = identifiers
        self.family = family
        self.platform = platform
        self.releaseYear = releaseYear
        self.formFactor = formFactor
        self.processorFamily = processorFamily
        self.traits = traits
    }
}

public struct PTDeviceRuntimeInfo: Sendable {
    public let identifier: String
    public let environment: PTDeviceEnvironment
    public let architecture: PTDeviceArchitecture
    public let operatingSystem: OperatingSystemVersion
    public let processorCount: Int
    public let physicalMemory: UInt64

    public init(
        identifier: String,
        environment: PTDeviceEnvironment,
        architecture: PTDeviceArchitecture,
        operatingSystem: OperatingSystemVersion,
        processorCount: Int,
        physicalMemory: UInt64
    ) {
        self.identifier = identifier
        self.environment = environment
        self.architecture = architecture
        self.operatingSystem = operatingSystem
        self.processorCount = processorCount
        self.physicalMemory = physicalMemory
    }
}

public enum PTBatteryState: String, Codable, Sendable {
    case unknown
    case unplugged
    case charging
    case full
}

public enum PTDeviceCapability: String, CaseIterable, Codable, Sendable {
    case camera
    case microphone
    case biometrics
    case faceID
    case touchID
    case nfc
    case motion
    case location
    case cellular
    case lidar
    case spatialTracking
    case handTracking
    case externalDisplay
}

public enum PTDeviceCapabilityStatus: String, Codable, Sendable {
    case available
    case unavailable
    case unsupported
    case unavailableOnSimulator
    case permissionDenied
    case restricted
    case unknown
}

public protocol PTDeviceCapabilityProviding: Sendable {
    func status(for capability: PTDeviceCapability) async -> PTDeviceCapabilityStatus
}
