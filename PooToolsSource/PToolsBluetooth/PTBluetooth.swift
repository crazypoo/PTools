// English: Actor-safe CoreBluetooth infrastructure for generic BLE applications.
// Español: Infraestructura CoreBluetooth segura para actores y aplicaciones BLE genéricas.
// 中文：面向通用 BLE 应用的 Actor 安全 CoreBluetooth 基础设施。

import Foundation

#if canImport(CoreBluetooth)
@preconcurrency import CoreBluetooth
#endif

public struct PTBluetoothUUID: RawRepresentable, Codable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue.uppercased() }
    public init(stringLiteral value: String) { self.init(rawValue: value) }
}

public enum PTBluetoothState: String, Codable, Sendable { case idle, scanning, connecting, discoveringServices, discoveringCharacteristics, ready, disconnecting, disconnected, failed }

public enum PTBluetoothDuplicatePolicy: String, Codable, Sendable { case allow, discard }

public enum PTBluetoothReconnectPolicy: Sendable, Codable, Equatable {
    case none
    case immediate(maxAttempts: Int)
    case exponentialBackoff(maxAttempts: Int, baseDelay: TimeInterval, maxDelay: TimeInterval)
}

public struct PTBluetoothScanPolicy: Sendable, Codable {
    public let serviceUUIDs: [PTBluetoothUUID]
    public let duplicatePolicy: PTBluetoothDuplicatePolicy
    public let minimumRSSI: Int?
    public let timeout: TimeInterval?
    public let nameContains: String?

    public init(serviceUUIDs: [PTBluetoothUUID] = [],
                duplicatePolicy: PTBluetoothDuplicatePolicy = .discard,
                minimumRSSI: Int? = nil,
                timeout: TimeInterval? = nil,
                nameContains: String? = nil) {
        self.serviceUUIDs = serviceUUIDs; self.duplicatePolicy = duplicatePolicy; self.minimumRSSI = minimumRSSI
        self.timeout = timeout; self.nameContains = nameContains
    }
}

public struct PTDiscoveredPeripheral: Sendable, Codable, Hashable {
    public let identifier: String
    public let name: String?
    public let rssi: Int
    public let serviceUUIDs: [PTBluetoothUUID]
    public let manufacturerData: Data?

    public init(identifier: String, name: String? = nil, rssi: Int, serviceUUIDs: [PTBluetoothUUID] = [], manufacturerData: Data? = nil) {
        self.identifier = identifier; self.name = name; self.rssi = rssi; self.serviceUUIDs = serviceUUIDs; self.manufacturerData = manufacturerData
    }
}

public struct PTBluetoothCharacteristic: Sendable, Codable, Hashable {
    public let serviceUUID: PTBluetoothUUID
    public let characteristicUUID: PTBluetoothUUID
    public let properties: UInt32
    public init(serviceUUID: PTBluetoothUUID, characteristicUUID: PTBluetoothUUID, properties: UInt32 = 0) {
        self.serviceUUID = serviceUUID; self.characteristicUUID = characteristicUUID; self.properties = properties
    }
}

public struct PTBluetoothDiagnosticsSnapshot: Sendable, Codable, Hashable {
    public let state: PTBluetoothState
    public let discoveredCount: Int
    public let connectedCount: Int
    public let lastRSSI: Int?
    public let sentBytes: Int64
    public let receivedBytes: Int64
    public let errorCount: Int
    public init(state: PTBluetoothState = .idle, discoveredCount: Int = 0, connectedCount: Int = 0, lastRSSI: Int? = nil, sentBytes: Int64 = 0, receivedBytes: Int64 = 0, errorCount: Int = 0) {
        self.state = state; self.discoveredCount = discoveredCount; self.connectedCount = connectedCount; self.lastRSSI = lastRSSI
        self.sentBytes = sentBytes; self.receivedBytes = receivedBytes; self.errorCount = errorCount
    }
}

// English: Configuration for CoreBluetooth central state restoration.
// Español: Configuración para la restauración del estado central de CoreBluetooth.
// 中文：CoreBluetooth 中央管理器状态恢复配置。
public struct PTBluetoothRestorationConfiguration: Sendable, Codable, Hashable {
    public let restoreIdentifier: String

    public init(restoreIdentifier: String = "PTools.Bluetooth.Central") {
        self.restoreIdentifier = restoreIdentifier
    }
}

// English: A value-only snapshot of peripherals restored by the system.
// Español: Instantánea basada en valores de los periféricos restaurados por el sistema.
// 中文：系统恢复的外设值类型快照。
public struct PTBluetoothRestorationSnapshot: Sendable, Codable, Hashable {
    public let peripheralIdentifiers: [String]

    public init(peripheralIdentifiers: [String] = []) {
        self.peripheralIdentifiers = peripheralIdentifiers
    }
}

public enum PTBluetoothError: Error, LocalizedError, Sendable, Equatable {
    case unavailable
    case poweredOff
    case timeout
    case cancelled
    case peripheralNotFound
    case characteristicUnavailable
    case operationFailed(String)
    public var errorDescription: String? {
        switch self { case .unavailable: "Bluetooth unavailable"; case .poweredOff: "Bluetooth is powered off"; case .timeout: "Bluetooth operation timed out"; case .cancelled: "Bluetooth operation cancelled"; case .peripheralNotFound: "Peripheral not found"; case .characteristicUnavailable: "Characteristic unavailable"; case .operationFailed(let value): value }
    }
}

public struct PTBluetoothConnectionInfo: Sendable, Codable, Hashable {
    public let identifier: String
    public let state: PTBluetoothState
    public init(identifier: String, state: PTBluetoothState) { self.identifier = identifier; self.state = state }
}

#if canImport(CoreBluetooth)
@MainActor
private final class PTCoreBluetoothDriver: NSObject, @preconcurrency CBCentralManagerDelegate, @preconcurrency CBPeripheralDelegate {
    private var central: CBCentralManager!
    private var peripherals: [String: CBPeripheral] = [:]
    private var connectWaiters: [String: CheckedContinuation<Void, Error>] = [:]
    private var readWaiters: [String: CheckedContinuation<Data, Error>] = [:]
    private var writeWaiters: [String: CheckedContinuation<Void, Error>] = [:]
    private var notificationHandlers: [String: @Sendable (Data) -> Void] = [:]
    private var scanHandler: (@Sendable (PTDiscoveredPeripheral) -> Void)?
    private var scanPolicy = PTBluetoothScanPolicy()
    private var restoredPeripheralIdentifiers: Set<String> = []
    private let restorationConfiguration: PTBluetoothRestorationConfiguration?
    private(set) var lastErrorCount = 0
    private(set) var sentBytes: Int64 = 0
    private(set) var receivedBytes: Int64 = 0

    init(restorationConfiguration: PTBluetoothRestorationConfiguration?) {
        self.restorationConfiguration = restorationConfiguration
        super.init()
        var options: [String: Any] = [:]
        if let restorationConfiguration {
            options[CBCentralManagerOptionRestoreIdentifierKey] = restorationConfiguration.restoreIdentifier
        }
        central = CBCentralManager(delegate: self, queue: .main, options: options.isEmpty ? nil : options)
    }

    func startScan(policy: PTBluetoothScanPolicy, handler: @escaping @Sendable (PTDiscoveredPeripheral) -> Void) throws {
        guard central.state == .poweredOn else { throw central.state == .poweredOff ? PTBluetoothError.poweredOff : .unavailable }
        scanPolicy = policy; scanHandler = handler
        central.scanForPeripherals(withServices: policy.serviceUUIDs.map { CBUUID(string: $0.rawValue) }, options: [CBCentralManagerScanOptionAllowDuplicatesKey: policy.duplicatePolicy == .allow])
    }

    func stopScan() { central.stopScan(); scanHandler = nil }

    func connect(identifier: String, timeout: TimeInterval) async throws {
        guard let peripheral = peripherals[identifier] else { throw PTBluetoothError.peripheralNotFound }
        guard central.state == .poweredOn else { throw PTBluetoothError.poweredOff }
        peripheral.delegate = self
        central.connect(peripheral)
        try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                connectWaiters[identifier] = continuation
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(timeout))
                    if let continuation = self.connectWaiters.removeValue(forKey: identifier) { continuation.resume(throwing: PTBluetoothError.timeout); self.central.cancelPeripheralConnection(peripheral) }
                }
            }
        }, onCancel: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                if let continuation = self.connectWaiters.removeValue(forKey: identifier) { continuation.resume(throwing: PTBluetoothError.cancelled) }
                if let peripheral = self.peripherals[identifier] { self.central.cancelPeripheralConnection(peripheral) }
            }
        })
    }

    func disconnect(identifier: String) { if let peripheral = peripherals[identifier] { central.cancelPeripheralConnection(peripheral) } }

    func read(identifier: String, service: PTBluetoothUUID, characteristic: PTBluetoothUUID, timeout: TimeInterval) async throws -> Data {
        guard let peripheral = peripherals[identifier], let characteristic = findCharacteristic(peripheral, service: service, characteristic: characteristic) else { throw PTBluetoothError.characteristicUnavailable }
        let key = "\(identifier)|\(service.rawValue)|\(characteristic.uuid.uuidString)"
        peripheral.readValue(for: characteristic)
        return try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
                readWaiters[key] = continuation
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(timeout))
                    if let continuation = self.readWaiters.removeValue(forKey: key) { continuation.resume(throwing: PTBluetoothError.timeout) }
                }
            }
        }, onCancel: { [weak self] in Task { @MainActor in self?.readWaiters.removeValue(forKey: key)?.resume(throwing: PTBluetoothError.cancelled) } })
    }

    func write(_ data: Data, identifier: String, service: PTBluetoothUUID, characteristic: PTBluetoothUUID, withResponse: Bool, timeout: TimeInterval) async throws {
        guard let peripheral = peripherals[identifier], let characteristic = findCharacteristic(peripheral, service: service, characteristic: characteristic) else { throw PTBluetoothError.characteristicUnavailable }
        let key = "\(identifier)|\(service.rawValue)|\(characteristic.uuid.uuidString)"
        peripheral.writeValue(data, for: characteristic, type: withResponse ? .withResponse : .withoutResponse); sentBytes += Int64(data.count)
        guard withResponse else { return }
        try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                writeWaiters[key] = continuation
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(timeout))
                    if let continuation = self.writeWaiters.removeValue(forKey: key) { continuation.resume(throwing: PTBluetoothError.timeout) }
                }
            }
        }, onCancel: { [weak self] in Task { @MainActor in self?.writeWaiters.removeValue(forKey: key)?.resume(throwing: PTBluetoothError.cancelled) } })
    }

    func setNotify(_ enabled: Bool, identifier: String, service: PTBluetoothUUID, characteristic: PTBluetoothUUID, handler: (@Sendable (Data) -> Void)? = nil) throws {
        guard let peripheral = peripherals[identifier], let characteristic = findCharacteristic(peripheral, service: service, characteristic: characteristic) else { throw PTBluetoothError.characteristicUnavailable }
        let key = "\(identifier)|\(service.rawValue)|\(characteristic.uuid.uuidString)"
        if enabled {
            guard let handler else { throw PTBluetoothError.operationFailed("Notification handler is missing") }
            notificationHandlers[key] = handler
        } else {
            notificationHandlers.removeValue(forKey: key)
        }
        peripheral.setNotifyValue(enabled, for: characteristic)
    }

    func diagnostics(state: PTBluetoothState) -> PTBluetoothDiagnosticsSnapshot { .init(state: state, discoveredCount: peripherals.count, connectedCount: peripherals.values.filter { $0.state == .connected }.count, sentBytes: sentBytes, receivedBytes: receivedBytes, errorCount: lastErrorCount) }

    func restorationSnapshot() -> PTBluetoothRestorationSnapshot {
        .init(peripheralIdentifiers: restoredPeripheralIdentifiers.sorted())
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {}

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        let restored = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] ?? []
        restored.forEach {
            let identifier = $0.identifier.uuidString
            peripherals[identifier] = $0
            restoredPeripheralIdentifiers.insert(identifier)
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let name = peripheral.name
        if let required = scanPolicy.nameContains, !(name?.localizedCaseInsensitiveContains(required) ?? false) { return }
        let rssi = RSSI.intValue
        if let minimum = scanPolicy.minimumRSSI, rssi < minimum { return }
        peripherals[peripheral.identifier.uuidString] = peripheral
        let services = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []).map { PTBluetoothUUID(rawValue: $0.uuidString) }
        scanHandler?(.init(identifier: peripheral.identifier.uuidString, name: name, rssi: rssi, serviceUUIDs: services, manufacturerData: advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data))
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        lastErrorCount += 1; connectWaiters.removeValue(forKey: peripheral.identifier.uuidString)?.resume(throwing: error ?? PTBluetoothError.operationFailed("Connection failed"))
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if error != nil { lastErrorCount += 1 }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let key = "\(peripheral.identifier.uuidString)|\(characteristic.service?.uuid.uuidString ?? "")|\(characteristic.uuid.uuidString)"
        if let error { lastErrorCount += 1; readWaiters.removeValue(forKey: key)?.resume(throwing: error); return }
        let data = characteristic.value ?? Data(); receivedBytes += Int64(data.count)
        readWaiters.removeValue(forKey: key)?.resume(returning: data); notificationHandlers[key]?(data)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            lastErrorCount += 1
            connectWaiters.removeValue(forKey: peripheral.identifier.uuidString)?.resume(throwing: error)
            return
        }
        peripheral.services?.forEach { peripheral.discoverCharacteristics(nil, for: $0) }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            lastErrorCount += 1
            connectWaiters.removeValue(forKey: peripheral.identifier.uuidString)?.resume(throwing: error)
            return
        }
        guard let services = peripheral.services, services.allSatisfy({ $0.characteristics != nil }) else { return }
        connectWaiters.removeValue(forKey: peripheral.identifier.uuidString)?.resume()
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        let key = "\(peripheral.identifier.uuidString)|\(characteristic.service?.uuid.uuidString ?? "")|\(characteristic.uuid.uuidString)"
        if let error { lastErrorCount += 1; writeWaiters.removeValue(forKey: key)?.resume(throwing: error) } else { writeWaiters.removeValue(forKey: key)?.resume() }
    }

    private func findCharacteristic(_ peripheral: CBPeripheral, service: PTBluetoothUUID, characteristic: PTBluetoothUUID) -> CBCharacteristic? {
        peripheral.services?.first(where: { $0.uuid.uuidString.caseInsensitiveCompare(service.rawValue) == .orderedSame })?.characteristics?.first(where: { $0.uuid.uuidString.caseInsensitiveCompare(characteristic.rawValue) == .orderedSame })
    }
}
#endif

public actor PTBluetoothConnection {
    private let identifier: String
    #if canImport(CoreBluetooth)
    private let driver: PTCoreBluetoothDriver
    fileprivate init(identifier: String, driver: PTCoreBluetoothDriver) { self.identifier = identifier; self.driver = driver }
    #else
    init(identifier: String) { self.identifier = identifier }
    #endif

    public func info(state: PTBluetoothState = .ready) -> PTBluetoothConnectionInfo { .init(identifier: identifier, state: state) }

    #if canImport(CoreBluetooth)
    public func read(service: PTBluetoothUUID, characteristic: PTBluetoothUUID, timeout: TimeInterval = 10) async throws -> Data { try await driver.read(identifier: identifier, service: service, characteristic: characteristic, timeout: timeout) }
    public func write(_ data: Data, service: PTBluetoothUUID, characteristic: PTBluetoothUUID, withResponse: Bool = true, timeout: TimeInterval = 10) async throws { try await driver.write(data, identifier: identifier, service: service, characteristic: characteristic, withResponse: withResponse, timeout: timeout) }
    public func notifications(service: PTBluetoothUUID, characteristic: PTBluetoothUUID) -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do { try await self.setNotify(true, service: service, characteristic: characteristic) { continuation.yield($0) } }
                catch { continuation.finish(throwing: error) }
            }
            continuation.onTermination = { _ in Task { try? await self.setNotify(false, service: service, characteristic: characteristic, handler: nil) } }
        }
    }
    public func disconnect() async { await driver.disconnect(identifier: identifier) }

    private func setNotify(_ enabled: Bool,
                           service: PTBluetoothUUID,
                           characteristic: PTBluetoothUUID,
                           handler: (@Sendable (Data) -> Void)? = nil) async throws {
        try await driver.setNotify(enabled, identifier: identifier, service: service, characteristic: characteristic, handler: handler)
    }
    #else
    public func read(service: PTBluetoothUUID, characteristic: PTBluetoothUUID, timeout: TimeInterval = 10) async throws -> Data { throw PTBluetoothError.unavailable }
    public func write(_ data: Data, service: PTBluetoothUUID, characteristic: PTBluetoothUUID, withResponse: Bool = true, timeout: TimeInterval = 10) async throws { throw PTBluetoothError.unavailable }
    public func notifications(service: PTBluetoothUUID, characteristic: PTBluetoothUUID) -> AsyncThrowingStream<Data, Error> { .init { $0.finish(throwing: PTBluetoothError.unavailable) } }
    public func disconnect() {}
    #endif
}

public actor PTBluetoothCentral {
    public static let shared = PTBluetoothCentral()
    private var state: PTBluetoothState = .idle
    #if canImport(CoreBluetooth)
    private var driver: PTCoreBluetoothDriver?
    #endif
    private let restorationConfiguration: PTBluetoothRestorationConfiguration?

    public init(restorationConfiguration: PTBluetoothRestorationConfiguration? = nil) {
        self.restorationConfiguration = restorationConfiguration
    }

    public func scan(policy: PTBluetoothScanPolicy = .init()) -> AsyncStream<PTDiscoveredPeripheral> {
        AsyncStream { continuation in
            continuation.onTermination = { _ in Task { await self.stopScan() } }
            Task {
                #if canImport(CoreBluetooth)
                do {
                    let driver = await self.makeDriver()
                    self.state = .scanning
                    try await driver.startScan(policy: policy) { continuation.yield($0) }
                    if let timeout = policy.timeout { try? await Task.sleep(for: .seconds(timeout)); await self.stopScan() }
                } catch { continuation.finish() }
                #else
                continuation.finish()
                #endif
            }
        }
    }

    public func stopScan() async {
        #if canImport(CoreBluetooth)
        await driver?.stopScan()
        #endif
        state = .idle
    }

    public func connect(to peripheral: PTDiscoveredPeripheral, timeout: TimeInterval = 15, reconnect: PTBluetoothReconnectPolicy = .none) async throws -> PTBluetoothConnection {
        #if canImport(CoreBluetooth)
        let driver = await makeDriver(); state = .connecting
        var attempt = 0
        while true {
            do { try await driver.connect(identifier: peripheral.identifier, timeout: timeout); state = .ready; return PTBluetoothConnection(identifier: peripheral.identifier, driver: driver) }
            catch {
                attempt += 1
                let delay: TimeInterval?
                switch reconnect { case .none: delay = nil; case .immediate(let max): delay = attempt <= max ? 0 : nil; case .exponentialBackoff(let max, let base, let maxDelay): delay = attempt <= max ? min(maxDelay, base * pow(2, Double(attempt - 1))) : nil }
                guard let delay else { state = .failed; throw error }
                try await Task.sleep(for: .seconds(delay))
            }
        }
        #else
        throw PTBluetoothError.unavailable
        #endif
    }

    public func diagnostics() async -> PTBluetoothDiagnosticsSnapshot {
        #if canImport(CoreBluetooth)
        return await makeDriver().diagnostics(state: state)
        #else
        return .init(state: state)
        #endif
    }

    public func restorationSnapshot() async -> PTBluetoothRestorationSnapshot {
        #if canImport(CoreBluetooth)
        return await makeDriver().restorationSnapshot()
        #else
        return .init()
        #endif
    }

    #if canImport(CoreBluetooth)
    private func makeDriver() async -> PTCoreBluetoothDriver {
        if let driver { return driver }
        let driver = await MainActor.run { PTCoreBluetoothDriver(restorationConfiguration: restorationConfiguration) }
        self.driver = driver
        return driver
    }
    #endif
}
