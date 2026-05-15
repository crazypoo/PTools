//
//  PTSocketManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/4/3.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
@preconcurrency import SocketRocket

public let nNetworkStatesChangeNotification = Notification.Name("nNetworkStatesChangeNotification")
public let nWebSocketDidReceiveMessageNotification = Notification.Name("nWebSocketDidReceiveMessageNotification")
public let nWebSocketDidConnect = Notification.Name("nWebSocketDidConnect")
public let nWebSocketDidDisconnect = Notification.Name("nWebSocketDidDisconnect")

// 枚举遵守 Sendable，确保跨线程传递安全
public enum SocketConnectionState: Sendable {
    case connected
    case disconnected
    case connecting
    case reconnecting
}

// 内部使用的线程安全消息类型
private enum SocketMessage: Sendable {
    case string(String)
    case data(Data)
}

// 3. Delegate 强制绑定 MainActor，确保业务层的 UI 更新绝对安全
@MainActor
public protocol PTSocketManagerDelegate: AnyObject {
    func socketDidConnect()
    func socketDidDisconnect()
    // 限制抛出的 message 必须是 Sendable 的 (通常是 String 或 Data)
    func socketDidReceiveMessage(_ message: Sendable)
}

// 4. 声明 @unchecked Sendable。我们通过内部的 socketQueue 串行队列手动保证了线程安全
@objcMembers
public final class PTSocketManager: NSObject, @unchecked Sendable {

    // MARK: - Singleton
    public static let share = PTSocketManager()
    
    // MARK: - Delegates
    private var delegates = NSHashTable<AnyObject>.weakObjects()

    // 内部串行队列，所有核心逻辑均在此队列执行
    private let socketQueue = DispatchQueue(label: "com.ptsocket.queue", qos: .default)

    // MARK: - Public Config (线程安全改造)
    private var _maxReConnectCount: Int = 10
    public var maxReConnectCount: Int {
        get { socketQueue.sync { _maxReConnectCount } }
        set { socketQueue.async { [weak self] in self?._maxReConnectCount = newValue } }
    }
    
    private var _socketState: SocketConnectionState = .disconnected
    public var socketState: SocketConnectionState {
        socketQueue.sync { _socketState }
    }
    
    private var _networkStatus: NetWorkStatus = .unknown // 假设外部定义了 NetWorkStatus
    public var networkStatus: NetWorkStatus {
        get { socketQueue.sync { _networkStatus } }
        set {
            socketQueue.async { [weak self] in
                guard let self = self else { return }
                self._networkStatus = newValue
                if self.networkIsNotReachable() {
                    self.disConnect(clearQueue: false)
                } else {
                    self.reConnect()
                }
            }
        }
    }

    // MARK: - Private Properties
    // 弃用 NSMutableURLRequest，改用原生 Sendable 的 URLRequest
    private var request: URLRequest?
    private var webSocket: SRWebSocket?
    private var reOpenCount: Int = 0
    private var messageQueue: [SocketMessage] = []
    
    // 心跳与超时 (使用现代 Task 架构)
    private var heartBeatTask: Task<Void, Never>?
    private let heartBeatInterval: TimeInterval = 30
    private var lastReceiveMessageTime: TimeInterval = 0
    private let timeoutThreshold: TimeInterval = 90

    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(onNetworkStatusChange(_:)), name: nNetworkStatesChangeNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        disConnect()
    }

    // MARK: - Delegate Management
    public func addDelegate(_ delegate: PTSocketManagerDelegate) {
        socketQueue.async { [weak self] in
            self?.delegates.add(delegate as AnyObject)
        }
    }

    public func removeDelegate(_ delegate: PTSocketManagerDelegate) {
        socketQueue.async { [weak self] in
            self?.delegates.remove(delegate as AnyObject)
        }
    }

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
    // 5. 闭包参数增加 @Sendable 约束
    public func socketSet(completion: @escaping @Sendable (Bool) -> Void) {
        Task {
            let urlString = await Network.socketGobalUrl()
            guard let url = URL(string: urlString) else {
                Task { @MainActor in completion(false) }
                return
            }

            let req = URLRequest(
                url: url,
                cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                timeoutInterval: 10
            )
            
            self.socketQueue.async { [weak self] in
                self?.request = req
                Task { @MainActor in completion(true) }
            }
        }
    }

    // MARK: - Connect Control
    public func connect() {
        socketQueue.async { [weak self] in
            guard let self = self, let request = self.request else { return }
            guard !self.isConnectingOrConnected else { return }

            self._socketState = .connecting
            
            let socket = SRWebSocket(urlRequest: request)
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
            self._socketState = .disconnected
            
            if clearQueue {
                self.messageQueue.removeAll()
            }
        }
    }

    public func reConnect() {
        socketQueue.async { [weak self] in
            guard let self = self else { return }
            guard !self.networkIsNotReachable() else { return }
            guard self.isClosed else { return }

            if self.reOpenCount >= self._maxReConnectCount {
                self.reOpenCount = 0
                print("PTSocketManager: 重连次数达到上限")
                return
            }

            self._socketState = .reconnecting
            self.reOpenCount += 1

            let delay = min(pow(2.0, Double(self.reOpenCount)), 60.0)
            self.disConnect(clearQueue: false)

            // 6. 拥抱现代并发，使用 Task.sleep 替代 DispatchQueue.asyncAfter
            Task {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                self.connect()
            }
        }
    }

    // MARK: - Network
    @objc private func onNetworkStatusChange(_ notifi: Notification) {
        socketQueue.async { [weak self] in
            guard let self = self else { return }
            if self.networkIsNotReachable() {
                self.disConnect(clearQueue: false)
            } else {
                self.reConnect()
            }
        }
    }

    private func networkIsNotReachable() -> Bool {
        switch networkStatus {
        case .notReachable: return true
        default: return false
        }
    }

    // MARK: - Send
    // 继续支持 Any 传参（避免破坏现有业务代码），但在内部安全剥离为 Sendable
    public func sendMessage(_ msg: Sendable) {
        socketQueue.async { [weak self] in
            guard let self = self else { return }
            
            let socketMsg: SocketMessage
            if let stringMsg = msg as? String {
                socketMsg = .string(stringMsg)
            } else if let dataMsg = msg as? Data {
                socketMsg = .data(dataMsg)
            } else {
                print("PTSocketManager: 发送失败，不支持的消息类型")
                return
            }
            
            self.handleSend(socketMsg)
        }
    }
    
    private func handleSend(_ msg: SocketMessage) {
        if self.webSocket?.readyState == .OPEN {
            switch msg {
            case .string(let str): try? self.webSocket?.send(string: str)
            case .data(let data): try? self.webSocket?.send(data: data)
            }
        } else {
            if self.messageQueue.count < 1000 {
                self.messageQueue.append(msg)
            }
        }
    }
    
    private func flushMessageQueue() {
        guard !messageQueue.isEmpty else { return }
        for msg in messageQueue {
            switch msg {
            case .string(let str): try? self.webSocket?.send(string: str)
            case .data(let data): try? self.webSocket?.send(data: data)
            }
        }
        messageQueue.removeAll()
    }

    // MARK: - HeartBeat & Timeout Detection
    public func startHeartBeat() {
        stopHeartBeat()
        lastReceiveMessageTime = Date().timeIntervalSince1970
        
        // 7. 使用 Task 实现心跳循环，不仅代码清晰，且避免了 Timer 的内存泄漏风险
        heartBeatTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    // 每隔 interval 秒执行一次
                    try await Task.sleep(nanoseconds: UInt64((self?.heartBeatInterval ?? 30) * 1_000_000_000))
                    guard !Task.isCancelled else { break }
                    
                    self?.socketQueue.async {
                        guard let self = self else { return }
                        try? self.webSocket?.sendPing(nil)
                        
                        let currentTime = Date().timeIntervalSince1970
                        if currentTime - self.lastReceiveMessageTime > self.timeoutThreshold {
                            print("PTSocketManager: 心跳超时，判定为假死，准备重连")
                            self.reConnect()
                        }
                    }
                } catch {
                    break // 休眠被取消时直接退出循环
                }
            }
        }
    }

    public func stopHeartBeat() {
        heartBeatTask?.cancel()
        heartBeatTask = nil
    }
}

// MARK: - SRWebSocketDelegate
extension PTSocketManager: SRWebSocketDelegate {

    public func webSocketDidOpen(_ webSocket: SRWebSocket) {
        _socketState = .connected
        reOpenCount = 0
        lastReceiveMessageTime = Date().timeIntervalSince1970
        
        flushMessageQueue()
        startHeartBeat()

        // 8. 先在串行队列安全提取 delegates 数组，再推送到主线程执行（完美避开数据竞争）
        let currentDelegates = self.delegates.allObjects
        Task { @MainActor in
            NotificationCenter.default.post(name: nWebSocketDidConnect, object: nil)
            for delegate in currentDelegates {
                (delegate as? PTSocketManagerDelegate)?.socketDidConnect()
            }
        }
    }

    public func webSocket(_ webSocket: SRWebSocket, didReceiveMessage message: Any) {
        lastReceiveMessageTime = Date().timeIntervalSince1970
        
        // 解析合法的 Sendable 类型再抛出
        let sendableMessage: Sendable
        if let str = message as? String {
            sendableMessage = str
        } else if let data = message as? Data {
            sendableMessage = data
        } else {
            return
        }
        
        let currentDelegates = self.delegates.allObjects
        Task { @MainActor in
            NotificationCenter.default.post(name: nWebSocketDidReceiveMessageNotification, object: sendableMessage)
            for delegate in currentDelegates {
                (delegate as? PTSocketManagerDelegate)?.socketDidReceiveMessage(sendableMessage)
            }
        }
    }
    
    public func webSocket(_ webSocket: SRWebSocket, didReceivePong pongPayload: Data?) {
        lastReceiveMessageTime = Date().timeIntervalSince1970
    }

    public func webSocket(_ webSocket: SRWebSocket, didFailWithError error: Error) {
        reConnect()
    }

    public func webSocket(_ webSocket: SRWebSocket, didCloseWithCode code: Int, reason: String?, wasClean: Bool) {
        _socketState = .disconnected

        let currentDelegates = self.delegates.allObjects
        Task { @MainActor in
            NotificationCenter.default.post(name: nWebSocketDidDisconnect, object: nil)
            for delegate in currentDelegates {
                (delegate as? PTSocketManagerDelegate)?.socketDidDisconnect()
            }
        }
        reConnect()
    }
}
