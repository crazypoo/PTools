//
//  PTSocketManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/4/3.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SocketRocket

public let nNetworkStatesChangeNotification = "nNetworkStatesChangeNotification"
public let nWebSocketDidReceiveMessageNotification = "nWebSocketDidReceiveMessageNotification"
public let nWebSocketDidConnect = "nWebSocketDidConnect"
public let nWebSocketDidDisconnect = "nWebSocketDidDisconnect"

public enum SocketConnectionState {
    case connected
    case disconnected
    case connecting
    case reconnecting
}

@objcMembers
public final class PTSocketManager: NSObject {

    // MARK: - Singleton
    public static let share = PTSocketManager()
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(onNetworkStatusChange(_:)), name: NSNotification.Name(rawValue: nNetworkStatesChangeNotification), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        disConnect()
    }

    // MARK: - Public Config
    public var MaxReConnectTime: Int = 5
    public var ReconnectTime: TimeInterval = 5
    public private(set) var socketState: SocketConnectionState = .disconnected
    public var networkStatus: NetWorkStatus = .unknown

    // MARK: - Private Properties
    private var request: NSMutableURLRequest?
    private var webSocket: SRWebSocket?
    private var reOpenCount: Int = 0
    private var heartBeatTimer: Timer?

    // MARK: - State Check
    private var isConnectingOrConnected: Bool {
        guard let socket = webSocket else { return false }
        return socket.readyState == .OPEN || socket.readyState == .CONNECTING
    }

    private func isClosed() -> Bool {
        guard let socket = webSocket else { return true }
        return socket.readyState == .CLOSED || socket.readyState == .CLOSING
    }

    // MARK: - Setup
    public func socketSet(completion: @escaping (Bool) -> Void) {
        Task {
            let urlString = await Network.socketGobalUrl()
            guard let url = URL(string: urlString) else {
                completion(false)
                return
            }

            let req = NSMutableURLRequest(
                url: url,
                cachePolicy: .reloadIgnoringCacheData,
                timeoutInterval: 5
            )
            self.request = req
            completion(true)
        }
    }

    // MARK: - Connect Control
    public func connect() {
        guard let request else { return }
        guard !isConnectingOrConnected else { return }

        socketState = .connecting

        let socket = SRWebSocket(urlRequest: request as URLRequest)
        socket.delegate = self
        socket.open()
        webSocket = socket
    }

    public func disConnect() {
        guard let socket = webSocket else { return }

        socket.delegate = nil
        socket.close()
        webSocket = nil

        stopHeartBeat()
        socketState = .disconnected
    }

    public func reConnect() {
        guard !networkIsNotReachable() else { return }
        guard isClosed() else { return }

        if reOpenCount >= MaxReConnectTime {
            reOpenCount = 0
            return
        }

        socketState = .reconnecting
        reOpenCount += 1

        disConnect()

        DispatchQueue.main.asyncAfter(deadline: .now() + ReconnectTime) {
            self.connect()
        }
    }

    // MARK: - Network
    @objc private func onNetworkStatusChange(_ notifi: Notification) {
        guard !networkIsNotReachable() else { return }
        reConnect()
    }

    private func networkIsNotReachable() -> Bool {
        switch networkStatus {
        case .notReachable:
            return true
        default:
            return false
        }
    }

    // MARK: - Send
    public func sendMessage(_ msg: String) {
        guard webSocket?.readyState == .OPEN else { return }
        try? webSocket?.send(string: msg)
    }

    // MARK: - HeartBeat
    public func startHeartBeat(interval: TimeInterval = 30, msg: String = "ping") {
        stopHeartBeat()
        heartBeatTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.sendMessage(msg)
        }
    }

    public func stopHeartBeat() {
        heartBeatTimer?.invalidate()
        heartBeatTimer = nil
    }
}

// MARK: - SRWebSocketDelegate
extension PTSocketManager: SRWebSocketDelegate {

    public func webSocketDidOpen(_ webSocket: SRWebSocket) {
        socketState = .connected
        reOpenCount = 0

        NotificationCenter.default.post(name: NSNotification.Name(rawValue: nWebSocketDidConnect), object: nil)
    }

    public func webSocket(_ webSocket: SRWebSocket, didReceiveMessage message: Any) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: nWebSocketDidReceiveMessageNotification), object: message)
    }

    public func webSocket(_ webSocket: SRWebSocket, didFailWithError error: Error) {
        reConnect()
    }

    public func webSocket(_ webSocket: SRWebSocket, didCloseWithCode code: Int, reason: String?, wasClean: Bool) {
        socketState = .disconnected

        NotificationCenter.default.post(name: NSNotification.Name(rawValue: nWebSocketDidDisconnect),object: nil)

        reConnect()
    }
}
