// English: Foundation and Network connectivity contracts for Swift 6 applications.
// Español: Contratos de conectividad basados en Foundation y Network para aplicaciones Swift 6.
// 中文：面向 Swift 6 应用的 Foundation 与 Network 连通性契约。

import Foundation

#if canImport(Network)
// English: Network is a system framework; keep its non-Sendable path object inside this adapter.
// Español: Network es un framework del sistema; el objeto de ruta no Sendable queda confinado en este adaptador.
// 中文：Network 属于系统框架；将不可 Sendable 的路径对象限制在此适配层内。
@preconcurrency import Network
#endif

public enum PTConnectivityStatus: String, Codable, Sendable, Equatable {
    case satisfied
    case unsatisfied
    case requiresConnection
    case unknown
}

public enum PTConnectivityInterface: String, Codable, Sendable, Hashable {
    case wifi
    case cellular
    case wiredEthernet
    case loopback
    case other
}

public struct PTConnectivitySnapshot: Codable, Sendable, Equatable {
    public let status: PTConnectivityStatus
    public let interfaces: Set<PTConnectivityInterface>
    public let isExpensive: Bool
    public let isConstrained: Bool
    public let timestamp: Date

    public init(status: PTConnectivityStatus = .unknown,
                interfaces: Set<PTConnectivityInterface> = [],
                isExpensive: Bool = false,
                isConstrained: Bool = false,
                timestamp: Date = Date()) {
        self.status = status
        self.interfaces = interfaces
        self.isExpensive = isExpensive
        self.isConstrained = isConstrained
        self.timestamp = timestamp
    }

    public var isReachable: Bool { status == .satisfied }
}

public struct PTConnectivityDiagnosticsSnapshot: Codable, Sendable, Equatable {
    public let current: PTConnectivitySnapshot
    public let transitionCount: UInt64
    public let lastOfflineDate: Date?
    public let lastRecoveryDate: Date?

    public init(current: PTConnectivitySnapshot,
                transitionCount: UInt64,
                lastOfflineDate: Date?,
                lastRecoveryDate: Date?) {
        self.current = current
        self.transitionCount = transitionCount
        self.lastOfflineDate = lastOfflineDate
        self.lastRecoveryDate = lastRecoveryDate
    }
}

// English: Keep Network consumers testable without requiring a live NWPathMonitor.
// Español: Mantén testeables los consumidores de Network sin exigir un NWPathMonitor real.
// 中文：让 Network 调用方可以使用测试替身，而不强制依赖真实 NWPathMonitor。
public protocol PTConnectivityProviding: Sendable {
    func current() async -> PTConnectivitySnapshot
    func diagnostics() async -> PTConnectivityDiagnosticsSnapshot
    func snapshots() async -> AsyncStream<PTConnectivitySnapshot>
}

public actor PTConnectivityMonitor: PTConnectivityProviding {
    public static let shared = PTConnectivityMonitor()

    private var snapshot = PTConnectivitySnapshot()
    private var transitionCount: UInt64 = 0
    private var lastOfflineDate: Date?
    private var lastRecoveryDate: Date?
    private var observers: [UUID: AsyncStream<PTConnectivitySnapshot>.Continuation] = [:]
    private var hasStarted = false

#if canImport(Network)
    private var pathMonitor: NWPathMonitor?
    private var monitorQueue: DispatchQueue?
#endif

    public init() {}

    public func start() {
        guard !hasStarted else { return }
        hasStarted = true

#if canImport(Network)
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "com.pootools.connectivity", qos: .utility)
        monitor.pathUpdateHandler = { [weak self] path in
            let snapshot = Self.snapshot(from: path)
            Task { await self?.publish(snapshot) }
        }
        monitor.start(queue: queue)
        pathMonitor = monitor
        monitorQueue = queue
#endif
    }

    public func stop() {
#if canImport(Network)
        pathMonitor?.cancel()
        pathMonitor = nil
        monitorQueue = nil
#endif
        hasStarted = false
    }

    public func current() -> PTConnectivitySnapshot {
        start()
        return snapshot
    }

    public func diagnostics() -> PTConnectivityDiagnosticsSnapshot {
        PTConnectivityDiagnosticsSnapshot(current: snapshot,
                                           transitionCount: transitionCount,
                                           lastOfflineDate: lastOfflineDate,
                                           lastRecoveryDate: lastRecoveryDate)
    }

    public func snapshots() -> AsyncStream<PTConnectivitySnapshot> {
        start()
        let id = UUID()
        return AsyncStream { continuation in
            observers[id] = continuation
            continuation.yield(snapshot)
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { await self?.removeObserver(id) }
            }
        }
    }

    private func removeObserver(_ id: UUID) {
        observers[id] = nil
    }

    private func publish(_ newSnapshot: PTConnectivitySnapshot) {
        let oldStatus = snapshot.status
        if oldStatus != newSnapshot.status {
            transitionCount &+= 1
            if newSnapshot.isReachable {
                lastRecoveryDate = newSnapshot.timestamp
            } else if oldStatus == .satisfied {
                lastOfflineDate = newSnapshot.timestamp
            }
        }
        snapshot = newSnapshot
        for continuation in observers.values {
            continuation.yield(newSnapshot)
        }
    }

#if canImport(Network)
    private static func snapshot(from path: NWPath) -> PTConnectivitySnapshot {
        let status: PTConnectivityStatus
        switch path.status {
        case .satisfied:
            status = .satisfied
        case .unsatisfied:
            status = .unsatisfied
        case .requiresConnection:
            status = .requiresConnection
        @unknown default:
            status = .unknown
        }

        var interfaces = Set<PTConnectivityInterface>()
        for interface in [NWInterface.InterfaceType.wifi,
                          .cellular,
                          .wiredEthernet,
                          .loopback,
                          .other] where path.usesInterfaceType(interface) {
            switch interface {
            case .wifi:
                interfaces.insert(.wifi)
            case .cellular:
                interfaces.insert(.cellular)
            case .wiredEthernet:
                interfaces.insert(.wiredEthernet)
            case .loopback:
                interfaces.insert(.loopback)
            case .other:
                interfaces.insert(.other)
            @unknown default:
                interfaces.insert(.other)
            }
        }

        return PTConnectivitySnapshot(status: status,
                                      interfaces: interfaces,
                                      isExpensive: path.isExpensive,
                                      isConstrained: path.isConstrained)
    }
#endif
}
