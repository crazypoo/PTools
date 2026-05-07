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

// 补充：Delegate 协议，提供更清晰的回调
public protocol PTSocketManagerDelegate: AnyObject {
    func socketDidConnect()
    func socketDidDisconnect()
    func socketDidReceiveMessage(_ message: Any)
}

@objcMembers
public final class PTSocketManager: NSObject {

    // MARK: - Singleton
    public static let share = PTSocketManager()
    
    // MARK: - Delegates
    // 支持多代理（使用 NSHashTable 避免强引用）
    private var delegates = NSHashTable<AnyObject>.weakObjects()

    // MARK: - Public Config
    public var maxReConnectCount: Int = 10
    public private(set) var socketState: SocketConnectionState = .disconnected
    public var networkStatus: NetWorkStatus = .unknown // 假设外部定义了 NetWorkStatus

    // MARK: - Private Properties
    private var request: NSMutableURLRequest?
    private var webSocket: SRWebSocket?
    private var reOpenCount: Int = 0
    
    // 线程安全队列
    private let socketQueue = DispatchQueue(label: "com.ptsocket.queue", qos: .default)
    
    // 消息缓存队列
    private var messageQueue: [Any] = []
    
    // 心跳与超时
    private var heartBeatTimer: DispatchSourceTimer?
    private let heartBeatInterval: TimeInterval = 30
    private var lastReceiveMessageTime: TimeInterval = 0
    private let timeoutThreshold: TimeInterval = 90 // 超过90秒未收到任何消息判定为假死

    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(onNetworkStatusChange(_:)), name: NSNotification.Name(rawValue: nNetworkStatesChangeNotification), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        disConnect()
    }

    // MARK: - Delegate Management
    public func addDelegate(_ delegate: PTSocketManagerDelegate) {
        socketQueue.async {
            self.delegates.add(delegate as AnyObject)
        }
    }

    public func removeDelegate(_ delegate: PTSocketManagerDelegate) {
        socketQueue.async {
            self.delegates.remove(delegate as AnyObject)
        }
    }

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
            // 假设 Network.socketGlobalUrl() 是你的异步获取 URL 的方法
            let urlString = await Network.socketGobalUrl()
            guard let url = URL(string: urlString) else {
                DispatchQueue.main.async { completion(false) }
                return
            }

            let req = NSMutableURLRequest(
                url: url,
                cachePolicy: .reloadIgnoringCacheData,
                timeoutInterval: 10 // 稍微增加握手超时时间
            )
            self.request = req
            DispatchQueue.main.async { completion(true) }
        }
    }

    // MARK: - Connect Control
    public func connect() {
        socketQueue.async { [weak self] in
            guard let self = self, let request = self.request else { return }
            guard !self.isConnectingOrConnected else { return }

            self.socketState = .connecting
            
            let socket = SRWebSocket(urlRequest: request as URLRequest)
            // 将 SocketRocket 的回调绑定到我们的私有队列，避免阻塞主线程
            socket.delegateDispatchQueue = self.socketQueue
            socket.delegate = self
            socket.open()
            self.webSocket = socket
        }
    }

    public func disConnect(clearQueue: Bool = true) {
        socketQueue.async { [weak self] in
            guard let self = self, let socket = self.webSocket else { return }

            socket.delegate = nil
            socket.close()
            self.webSocket = nil

            self.stopHeartBeat()
            self.socketState = .disconnected
            
            if clearQueue {
                self.messageQueue.removeAll()
            }
        }
    }

    public func reConnect() {
        socketQueue.async { [weak self] in
            guard let self = self else { return }
            guard !self.networkIsNotReachable() else { return }
            guard self.isClosed() else { return }

            if self.reOpenCount >= self.maxReConnectCount {
                self.reOpenCount = 0
                PTNSLogConsole("PTSocketManager: 重连次数达到上限")
                return
            }

            self.socketState = .reconnecting
            self.reOpenCount += 1

            // 核心优化：指数退避重连延时 (例如：2, 4, 8, 16... 秒)
            // 限制最大重连间隔为 60 秒
            let delay = min(pow(2.0, Double(self.reOpenCount)), 60.0)
            
            self.disConnect(clearQueue: false) // 重连时不清理消息队列

            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                self.connect()
            }
        }
    }

    // MARK: - Network
    @objc private func onNetworkStatusChange(_ notifi: Notification) {
        guard !networkIsNotReachable() else {
            disConnect(clearQueue: false)
            return
        }
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
    public func sendMessage(_ msg: Any) {
        socketQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.webSocket?.readyState == .OPEN {
                switch msg {
                case let msgString as String:
                    try? self.webSocket?.send(string:msgString)
                case let msgData as Data:
                    try? self.webSocket?.send(data: msgData)
                default:
                    PTNSLogConsole("PTSocketManager: 发送失败，不支持的消息类型，仅支持 String 或 Data")
                }
            } else {
                // 核心优化：断网或重连时，将消息存入队列暂存 (可选：可限制队列最大长度防止内存溢出)
                if self.messageQueue.count < 1000 {
                    self.messageQueue.append(msg)
                }
            }
        }
    }
    
    private func flushMessageQueue() {
        guard !messageQueue.isEmpty else { return }
        for msg in messageQueue {
            switch msg {
            case let msgString as String:
                try? self.webSocket?.send(string:msgString)
            case let msgData as Data:
                try? self.webSocket?.send(data: msgData)
            default:
                PTNSLogConsole("PTSocketManager: 发送失败，不支持的消息类型，仅支持 String 或 Data")
            }
        }
        messageQueue.removeAll()
    }

    // MARK: - HeartBeat & Timeout Detection
    public func startHeartBeat() {
        stopHeartBeat()
        lastReceiveMessageTime = Date().timeIntervalSince1970
        
        // 使用 GCD Timer 替代 NSTimer，确保在后台线程也能精准运行
        heartBeatTimer = DispatchSource.makeTimerSource(queue: socketQueue)
        heartBeatTimer?.schedule(deadline: .now() + heartBeatInterval, repeating: heartBeatInterval)
        heartBeatTimer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            // 发送心跳 Ping
            // 使用 SocketRocket 自带的 Ping 机制比发送 "ping" 字符串更规范 (TCP 层)
            try? self.webSocket?.sendPing(nil)
            
            // 检查假死状态
            let currentTime = Date().timeIntervalSince1970
            if currentTime - self.lastReceiveMessageTime > self.timeoutThreshold {
                PTNSLogConsole("PTSocketManager: 心跳超时，判定为假死，准备重连")
                self.reConnect()
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
        reOpenCount = 0
        lastReceiveMessageTime = Date().timeIntervalSince1970
        
        // 发送堆积的消息
        flushMessageQueue()
        // 开启心跳
        startHeartBeat()

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: nWebSocketDidConnect), object: nil)
            for delegate in self.delegates.allObjects {
                (delegate as? PTSocketManagerDelegate)?.socketDidConnect()
            }
        }
    }

    public func webSocket(_ webSocket: SRWebSocket, didReceiveMessage message: Any) {
        // 更新最后活跃时间
        lastReceiveMessageTime = Date().timeIntervalSince1970
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: nWebSocketDidReceiveMessageNotification), object: message)
            for delegate in self.delegates.allObjects {
                (delegate as? PTSocketManagerDelegate)?.socketDidReceiveMessage(message)
            }
        }
    }
    
    // 收到 Pong 的回调
    public func webSocket(_ webSocket: SRWebSocket, didReceivePong pongPayload: Data?) {
        lastReceiveMessageTime = Date().timeIntervalSince1970
    }

    public func webSocket(_ webSocket: SRWebSocket, didFailWithError error: Error) {
        reConnect()
    }

    public func webSocket(_ webSocket: SRWebSocket, didCloseWithCode code: Int, reason: String?, wasClean: Bool) {
        socketState = .disconnected

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: nWebSocketDidDisconnect),object: nil)
            for delegate in self.delegates.allObjects {
                (delegate as? PTSocketManagerDelegate)?.socketDidDisconnect()
            }
        }
        reConnect()
    }
}
