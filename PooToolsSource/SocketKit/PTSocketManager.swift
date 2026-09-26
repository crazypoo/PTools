// English: Compatibility facade backed by the native PTWebSocketClient.
// Español: Fachada de compatibilidad respaldada por PTWebSocketClient nativo.
// 中文：由原生 PTWebSocketClient 支撑的兼容门面。

import Foundation
import UIKit

public extension Notification.Name {
    static let ptNetworkStatesChange = Notification.Name("nNetworkStatesChangeNotification")
    static let ptWebSocketDidReceiveMessage = Notification.Name("nWebSocketDidReceiveMessageNotification")
    static let ptWebSocketDidConnect = Notification.Name("nWebSocketDidConnect")
    static let ptWebSocketDidDisconnect = Notification.Name("nWebSocketDidDisconnect")
}

public let nNetworkStatesChangeNotification = Notification.Name.ptNetworkStatesChange
public let nWebSocketDidReceiveMessageNotification = Notification.Name.ptWebSocketDidReceiveMessage
public let nWebSocketDidConnect = Notification.Name.ptWebSocketDidConnect
public let nWebSocketDidDisconnect = Notification.Name.ptWebSocketDidDisconnect

public enum SocketConnectionState: Sendable {
    case connected
    case disconnected
    case connecting
    case reconnecting
}

@MainActor
public protocol PTSocketManagerDelegate: AnyObject, Sendable {
    func socketDidConnect()
    func socketDidDisconnect()
    func socketDidReceiveMessage(_ message: Sendable)
}

@MainActor
public final class PTSocketManager: NSObject {
    public static let share = PTSocketManager()

    private var delegates = NSHashTable<AnyObject>.weakObjects()
    private var client: PTWebSocketClient?
    private var eventTask: Task<Void, Never>?
    private var socketURL: URL?
    private var _socketState: SocketConnectionState = .disconnected
    private var _networkStatus: NetworkStatus = .unknown
    private var _maxReConnectCount = 10
    private var heartbeatEnabled = true

    public var maxReConnectCount: Int {
        get { _maxReConnectCount }
        set { _maxReConnectCount = max(0, newValue) }
    }

    public var socketState: SocketConnectionState { _socketState }

    public var networkStatus: NetworkStatus {
        get { _networkStatus }
        set {
            _networkStatus = newValue
            let isAvailable: Bool
            if case .notReachable = newValue { isAvailable = false } else { isAvailable = true }
            guard let client else { return }
            Task { await client.updateConnectivity(isAvailable: isAvailable) }
        }
    }

    private override init() {
        super.init()
    }

    deinit {
        eventTask?.cancel()
        if let client {
            Task { await client.disconnect(clearQueue: true) }
        }
    }

    public func addDelegate(_ delegate: PTSocketManagerDelegate) {
        delegates.add(delegate)
    }

    public func removeDelegate(_ delegate: PTSocketManagerDelegate) {
        delegates.remove(delegate)
    }

    public func socketSet(completion: @escaping @Sendable (Bool) -> Void) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let urlString = await Network.socketGlobalURL()
            guard let url = URL(string: urlString), let scheme = url.scheme?.lowercased(), scheme == "ws" || scheme == "wss" else {
                completion(false)
                return
            }
            socketURL = url
            eventTask?.cancel()
            if let oldClient = client { Task { await oldClient.disconnect(clearQueue: true) } }
            let configuration = PTWebSocketConfiguration(url: url,
                                                          maxReconnectAttempts: maxReConnectCount,
                                                          automaticallyReconnect: true,
                                                          heartbeat: PTWebSocketHeartbeatConfiguration(enabled: heartbeatEnabled))
            let newClient = PTWebSocketClient(configuration: configuration)
            client = newClient
            startEventBridge(for: newClient)
            completion(true)
        }
    }

    public func connect() {
        guard let client else { return }
        _socketState = .connecting
        Task { @MainActor [weak self, client] in
            do {
                try await client.connect()
            } catch {
                self?._socketState = .disconnected
            }
        }
    }

    public func disConnect(clearQueue: Bool = true) {
        guard let client else {
            _socketState = .disconnected
            return
        }
        _socketState = .disconnected
        Task { await client.disconnect(clearQueue: clearQueue) }
    }

    public func reConnect() {
        guard let client else { return }
        _socketState = .reconnecting
        Task { @MainActor [weak self, client] in
            do {
                try await client.reconnect()
            } catch {
                self?._socketState = .disconnected
            }
        }
    }

    public func sendMessage(_ msg: Sendable) {
        let message: PTWebSocketMessage
        if let value = msg as? String {
            message = .text(value)
        } else if let value = msg as? Data {
            message = .data(value)
        } else {
            return
        }
        guard let client else { return }
        Task { try? await client.send(message) }
    }

    public func startHeartBeat() {
        heartbeatEnabled = true
        guard let client else { return }
        Task { await client.setHeartbeatEnabled(true) }
    }

    public func stopHeartBeat() {
        heartbeatEnabled = false
        guard let client else { return }
        Task { await client.setHeartbeatEnabled(false) }
    }

    private func startEventBridge(for client: PTWebSocketClient) {
        eventTask = Task { @MainActor [weak self, client] in
            guard let self else { return }
            for await event in client.events {
                guard !Task.isCancelled else { return }
                consume(event)
            }
        }
    }

    private func consume(_ event: PTWebSocketEvent) {
        switch event {
        case .connecting:
            _socketState = .connecting
        case .connected:
            _socketState = .connected
            NotificationCenter.default.post(name: .ptWebSocketDidConnect, object: nil)
            for delegate in delegates.allObjects {
                (delegate as? PTSocketManagerDelegate)?.socketDidConnect()
            }
        case .message(let message):
            let value: Sendable
            switch message {
            case .text(let text): value = text
            case .data(let data): value = data
            }
            NotificationCenter.default.post(name: .ptWebSocketDidReceiveMessage, object: value)
            for delegate in delegates.allObjects {
                (delegate as? PTSocketManagerDelegate)?.socketDidReceiveMessage(value)
            }
        case .reconnecting:
            _socketState = .reconnecting
        case .disconnected:
            _socketState = .disconnected
            NotificationCenter.default.post(name: .ptWebSocketDidDisconnect, object: nil)
            for delegate in delegates.allObjects {
                (delegate as? PTSocketManagerDelegate)?.socketDidDisconnect()
            }
        case .failed:
            _socketState = .disconnected
        case .pong:
            break
        }
    }
}
