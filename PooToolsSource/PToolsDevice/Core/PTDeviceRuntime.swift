// English: Runtime identity resolution is injectable so simulator and future-device behavior can be tested.
// Español: La resolución de identidad en tiempo de ejecución es inyectable para probar simuladores y dispositivos futuros.
// 中文：运行时身份解析支持注入，便于测试模拟器和未来设备。

import Foundation

#if canImport(Darwin)
import Darwin
#endif

public protocol PTDeviceRuntimeEnvironmentProviding: Sendable {
    var machineIdentifier: String { get }
    var simulatorModelIdentifier: String? { get }
    var isSimulator: Bool { get }
    var architecture: PTDeviceArchitecture { get }
    var operatingSystem: OperatingSystemVersion { get }
    var processorCount: Int { get }
    var physicalMemory: UInt64 { get }
}

public struct PTDeviceRuntimeEnvironment: PTDeviceRuntimeEnvironmentProviding, Sendable {
    public let machineIdentifier: String
    public let simulatorModelIdentifier: String?
    public let isSimulator: Bool
    public let architecture: PTDeviceArchitecture
    public let operatingSystem: OperatingSystemVersion
    public let processorCount: Int
    public let physicalMemory: UInt64

    public init(
        machineIdentifier: String,
        simulatorModelIdentifier: String? = nil,
        isSimulator: Bool,
        architecture: PTDeviceArchitecture,
        operatingSystem: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion,
        processorCount: Int = ProcessInfo.processInfo.processorCount,
        physicalMemory: UInt64 = ProcessInfo.processInfo.physicalMemory
    ) {
        self.machineIdentifier = machineIdentifier
        self.simulatorModelIdentifier = simulatorModelIdentifier
        self.isSimulator = isSimulator
        self.architecture = architecture
        self.operatingSystem = operatingSystem
        self.processorCount = processorCount
        self.physicalMemory = physicalMemory
    }

    public static let live = PTDeviceRuntimeEnvironment(
        machineIdentifier: Self.readMachineIdentifier(),
        simulatorModelIdentifier: Self.readSimulatorModelIdentifier(),
        isSimulator: Self.readIsSimulator(),
        architecture: Self.readArchitecture()
    )

    private static func readSimulatorModelIdentifier() -> String? {
        ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"]
    }

    private static func readIsSimulator() -> Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }

    private static func readArchitecture() -> PTDeviceArchitecture {
        #if arch(arm64)
        .arm64
        #elseif arch(x86_64)
        .x86_64
        #else
        .unknown
        #endif
    }

    private static func readMachineIdentifier() -> String {
        #if canImport(Darwin)
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafeBytes(of: &systemInfo.machine) { rawBuffer in
            rawBuffer
                .compactMap { byte in
                    guard byte != 0 else { return nil }
                    return UnicodeScalar(UInt8(byte))
                }
                .map(String.init)
                .joined()
        }
        #else
        return ProcessInfo.processInfo.environment["HOSTTYPE"] ?? "unknown"
        #endif
    }
}

public enum PTDeviceRuntimeResolver {
    public static func resolve(
        environment: any PTDeviceRuntimeEnvironmentProviding = PTDeviceRuntimeEnvironment.live
    ) -> PTDeviceRuntimeInfo {
        let identifier = environment.simulatorModelIdentifier ?? environment.machineIdentifier
        return PTDeviceRuntimeInfo(
            identifier: identifier,
            environment: environment.isSimulator ? .simulator : .physical,
            architecture: environment.architecture,
            operatingSystem: environment.operatingSystem,
            processorCount: environment.processorCount,
            physicalMemory: environment.physicalMemory
        )
    }
}
