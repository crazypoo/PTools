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
public class PTSocketManager: NSObject {
    public static let share = PTSocketManager()
    
    open var MaxReConnectTime = 0
    open var ReconnectTime:TimeInterval = 5
    open var networkStatus:NetWorkStatus = .unknown
    public private(set) var socketState: SocketConnectionState = .disconnected
    
    fileprivate var reOpenCount:Int = 0
    fileprivate var request:NSMutableURLRequest!
    fileprivate var webSocket:SRWebSocket?
    private var heartBeatTimer: Timer?

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override init() {
        super.init()
                        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onNetworkStatusChange(notifi:)), name: NSNotification.Name(rawValue: nNetworkStatesChangeNotification), object: nil)
    }
    
    public func socketSet(completion: @escaping (Bool) -> Void) {
        Task {
            let urlString = await Network.socketGobalUrl()
            guard let webSocketUrl = URL(string: urlString),var urlcomponents = URLComponents(url: webSocketUrl, resolvingAgainstBaseURL: false) else {
                completion(false)
                return
            }
            
            urlcomponents.scheme = webSocketUrl.scheme
            guard let url = urlcomponents.url else {
                completion(false)
                return
            }
            self.request = NSMutableURLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringCacheData, timeoutInterval: 1)
            socketState = .connecting
            completion(true)
        }
    }

    @objc func onNetworkStatusChange(notifi:Notification) {
        if webSocket != nil && !networkIsNotReachable() && !isClosed() {
            reConnect()
        }
    }
    
    public func isClosed() -> Bool {
        PTNSLogConsole("socket连接状态---\(webSocket?.readyState.rawValue ?? 0)",levelType: PTLogMode,loggerType: .Network)
        return webSocket?.readyState != .OPEN
    }
    
    public func reConnect() {
        socketState = .reconnecting
        disConnect()
        socketState = .connecting
        connect()
    }
    
    public func disConnect() {
        if webSocket?.readyState == .CLOSING || webSocket?.readyState == .CLOSED {
            return
        }
        
        if let socket = webSocket {
            socket.delegate = nil
            socket.close()
            webSocket = nil
            socketState = .disconnected
        }
    }
    
    public func connect() {
        if webSocket?.readyState == .OPEN {
            disConnect()
        }
        
        webSocket = SRWebSocket(urlRequest: request as URLRequest)
        webSocket?.delegate = self
        webSocket?.open()
        socketState = .connected
    }
    
    public func startReconnect() {
        if !networkIsNotReachable() {
            socketState = .reconnecting
            PTGCDManager.gcdAfter(time: self.ReconnectTime) {
                if !self.isClosed() {
                    self.reOpenCount = 0
                    return
                }
                if self.reOpenCount >= self.MaxReConnectTime {
                    self.reOpenCount = 0
                    return
                }
                self.reConnect()
                self.reOpenCount += 1
            }
        }
    }
    
    public func sendMessage(msg:String) {
        guard webSocket?.readyState == .OPEN else { return }

        do {
            try webSocket?.send(string: msg)
        } catch {
            PTNSLogConsole("\(error.localizedDescription)",levelType: .Error,loggerType: .Network)
        }
    }
    
    func networkIsNotReachable() ->Bool {
        return networkStatus == .notReachable
    }
    
    public func startHeartBeat(timeInterval:TimeInterval = 30,
                               msg:String = "ping") {
        heartBeatTimer?.invalidate()
        heartBeatTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
            self.sendMessage(msg: msg)
        }
    }

    public func stopHeartBeat() {
        heartBeatTimer?.invalidate()
        heartBeatTimer = nil
    }
}

extension PTSocketManager:SRWebSocketDelegate {
    public func webSocket(_ webSocket: SRWebSocket, didReceiveMessage message: Any) {
        PTNSLogConsole("接受到的socket信息:\(message)",levelType: PTLogMode,loggerType: .Network)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: nWebSocketDidReceiveMessageNotification), object: message)
    }
    
    public func webSocketDidOpen(_ webSocket: SRWebSocket) {
        if webSocket.readyState == .OPEN {
            PTNSLogConsole("socket连接成功",levelType: PTLogMode,loggerType: .Network)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: nWebSocketDidConnect), object: nil)
        }
        reOpenCount = 0
    }
    
    public func webSocket(_ webSocket: SRWebSocket, didFailWithError error: any Error) {
        startReconnect()
    }
    
    public func webSocket(_ webSocket: SRWebSocket, didCloseWithCode code: Int, reason: String?, wasClean: Bool) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: nWebSocketDidDisconnect), object: nil)
    }
}

