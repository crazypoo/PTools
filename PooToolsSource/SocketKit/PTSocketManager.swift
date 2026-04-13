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
public final class PTSocketManager: NSObject,@unchecked Sendable {

    // MARK: - Singleton
    public static let share = PTSocketManager()
    
    private override init() {
        super.init()
        // 监听网络状态变化
        NotificationCenter.default.addObserver(self, selector: #selector(onNetworkStatusChange(_:)), name: NSNotification.Name(rawValue: nNetworkStatesChangeNotification), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        disConnect()
    }

    // MARK: - Public Config
    /// 最大重连次数
    public var maxReConnectTime: Int = 5
    /// 基础重连间隔时间（秒）
    public var baseReconnectTime: TimeInterval = 5
    /// 对外暴露的连接状态
    public private(set) var socketState: SocketConnectionState = .disconnected
    /// 当前网络状态
    public var networkStatus: NetWorkStatus = .unknown

    // MARK: - Private Properties
    private var request: URLRequest?
    private var webSocket: SRWebSocket?
    private var reOpenCount: Int = 0
    
    /// GCD 级别的心跳定时器，比 Timer 更稳定
    private var heartBeatTimer: DispatchSourceTimer?
    /// 重连工作项，用于防抖（取消多余的重连请求）
    private var reconnectWorkItem: DispatchWorkItem?

    // MARK: - State Check
    private var isConnectingOrConnected: Bool {
        guard let socket = webSocket else { return false }
        return socket.readyState == .OPEN || socket.readyState == .CONNECTING
    }

    private var isClosed: Bool {
        guard let socket = webSocket else { return true }
        return socket.readyState == .CLOSED || socket.readyState == .CLOSING
    }

    // MARK: - Setup
    // 注意：如果您的 completion 会在多个并发上下文中调用，建议为其也加上 @Sendable
    public func socketSet(completion: @escaping @Sendable (Bool) -> Void) {
        Task { [weak self] in
            // 假设 Network.socketGobalUrl() 是一个异步方法
            let urlString = await Network.socketGobalUrl()
            
            guard let url = URL(string: urlString) else {
                DispatchQueue.main.async { completion(false) }
                return
            }

            // ✨ 修复点：直接使用 URLRequest (Struct)，它天生遵循 Sendable 协议
            // 如果后续需要添加 Header 等信息，将其声明为 var 即可：
            // req.addValue("Bearer token", forHTTPHeaderField: "Authorization")
            let req = URLRequest(
                url: url,
                cachePolicy: .reloadIgnoringCacheData,
                timeoutInterval: 5
            )
            
            // 安全地将遵循 Sendable 的 req 传递回主线程
            DispatchQueue.main.async {
                self?.request = req
                completion(true)
            }
        }
    }

    // MARK: - Connect Control
    public func connect() {
        guard let request = request else { return }
        guard !isConnectingOrConnected else { return }

        socketState = .connecting

        // 每次重新连接前，清理旧的 Socket
        cleanUpSocket()

        let socket = SRWebSocket(urlRequest: request)
        socket.delegate = self
        
        // 建议在一个专门的网络队列中打开和接收回调，如果不设置则默认在主线程
        // socket.setDelegateDispatchQueue(DispatchQueue.global())
        
        socket.open()
        webSocket = socket
    }

    public func disConnect() {
        cleanUpSocket()
        reOpenCount = 0 // 主动断开时，重置重连次数
        socketState = .disconnected
        reconnectWorkItem?.cancel() // 取消任何正在等待的重连任务
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: nWebSocketDidDisconnect), object: nil)
        }
    }
    
    /// 内部方法：只清理底层 socket 和心跳，不修改外层暴露的业务状态
    private func cleanUpSocket() {
        guard let socket = webSocket else { return }
        socket.delegate = nil
        socket.close()
        webSocket = nil
        stopHeartBeat()
    }

    public func reConnect() {
        // 如果网络不可用，暂不重连，等待网络恢复通知
        guard !networkIsNotReachable() else { return }
        // 限制最大重连次数
        guard reOpenCount < maxReConnectTime else {
            reOpenCount = 0
            socketState = .disconnected
            PTNSLogConsole("❌ WebSocket: 超过最大重连次数，放弃连接")
            return
        }

        socketState = .reconnecting
        reOpenCount += 1

        // 清理旧连接，但保留 reconnecting 状态
        cleanUpSocket()

        // 1. 取消上一次还没来得及执行的重连任务（防止并发重连堆积）
        reconnectWorkItem?.cancel()

        // 2. 创建新的重连任务
        let workItem = DispatchWorkItem { [weak self] in
            self?.connect()
        }
        reconnectWorkItem = workItem

        // 3. 计算退避延迟时间（如 5s, 10s, 15s），防止频繁打点服务器
        let delay = baseReconnectTime * TimeInterval(reOpenCount)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        PTNSLogConsole("⏳ WebSocket: 准备第 \(reOpenCount) 次重连，延迟 \(delay) 秒")
    }

    // MARK: - Network
    @objc private func onNetworkStatusChange(_ notifi: Notification) {
        guard !networkIsNotReachable() else {
            // 如果网络断开，暂停重连并断开当前连接
            cleanUpSocket()
            socketState = .disconnected
            return
        }
        
        // 网络恢复，如果之前是断开状态，则尝试重连
        if socketState != .connected {
            reOpenCount = 0 // 网络恢复时，重置重试次数，立即尝试连接
            reConnect()
        }
    }

    private func networkIsNotReachable() -> Bool {
        switch networkStatus {
        case .notReachable:
            return true
        default:
            return false
        }
    }

    // MARK: - Send Message
    public func sendMessage(_ msg: String) {
        guard webSocket?.readyState == .OPEN else { return }
        try? webSocket?.send(string: msg)
    }
    
    /// 发送原生的 WebSocket Ping 帧（推荐的保活方式）
    public func sendNativePing() {
        guard webSocket?.readyState == .OPEN else { return }
        try? webSocket?.sendPing(nil)
    }

    // MARK: - HeartBeat
    public func startHeartBeat(interval: TimeInterval = 30, useNativePing: Bool = false, msg: String = "ping") {
        stopHeartBeat()
        
        // 使用 GCD Timer 保证后台/无 RunLoop 环境下的稳定性
        let queue = DispatchQueue(label: "com.socket.heartbeat", attributes: .concurrent)
        heartBeatTimer = DispatchSource.makeTimerSource(queue: queue)
        heartBeatTimer?.schedule(deadline: .now() + interval, repeating: interval)
        
        heartBeatTimer?.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                if useNativePing {
                    self?.sendNativePing()
                } else {
                    self?.sendMessage(msg)
                }
            }
        }
        heartBeatTimer?.resume()
    }

    public func stopHeartBeat() {
        heartBeatTimer?.cancel()
        heartBeatTimer = nil
    }
}

// MARK: - SRWebSocketDelegate
extension PTSocketManager: SRWebSocketDelegate {

    public func webSocketDidOpen(_ webSocket: SRWebSocket) {
        socketState = .connected
        reOpenCount = 0 // 连接成功，重置计数器
        
        // 可以在这里自动启动心跳
        // startHeartBeat()

        // ✨ 优化：确保在主线程发送状态通知
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: nWebSocketDidConnect), object: self)
        }
    }

    public func webSocket(_ webSocket: SRWebSocket, didReceiveMessage message: Any) {
        // ✨ 优化：1. 切回主线程 2. 将数据放入 userInfo 字典中
        DispatchQueue.main.async {
            let userInfo: [String: Any] = ["data": message]
            NotificationCenter.default.post(
                name: NSNotification.Name(rawValue: nWebSocketDidReceiveMessageNotification),
                object: self,
                userInfo: userInfo
            )
        }
    }

    public func webSocket(_ webSocket: SRWebSocket, didFailWithError error: Error) {
        PTNSLogConsole("❌ WebSocket Did Fail With Error: \(error.localizedDescription)")
        reConnect()
    }

    public func webSocket(_ webSocket: SRWebSocket, didCloseWithCode code: Int, reason: String?, wasClean: Bool) {
        PTNSLogConsole("🔌 WebSocket Closed. Code: \(code), Reason: \(reason ?? "None")")
        if code != SRStatusCode.codeNormal.rawValue {
            reConnect()
        } else {
            socketState = .disconnected
            // ✨ 优化：确保在主线程发送断开通知
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: nWebSocketDidDisconnect), object: self)
            }
        }
    }
    
    // 如果收到服务端的 Pong 回复，可以在这里处理
    public func webSocket(_ webSocket: SRWebSocket, didReceivePong pongPayload: Data?) {
         PTNSLogConsole("✅ Received Pong from Server")
    }
}
