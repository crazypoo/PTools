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

@objcMembers
public class PTSocketManager: NSObject {
    public static let share = PTSocketManager()
    
    open var socketAddress:String = ""
    open var socketAddress_dev:String = ""
    open var MaxReConnectTime = 0
    open var ReconnectTime:TimeInterval = 5
    open var networkStatus:NetWorkStatus = .unknown

    fileprivate var reOpenCount:Int = 0
    fileprivate var request:NSMutableURLRequest!
    fileprivate var webSocket:SRWebSocket?

    //MARK: socket服务器URL
    open class func gobalUrl() -> String {
        if UIApplication.applicationEnvironment() != .appStore {
            PTNSLogConsole("PTSocketURLMode:\(PTSocketURLMode)",levelType: PTLogMode,loggerType: .Network)
            switch PTSocketURLMode {
            case .Development:
                let url_debug:String = PTCoreUserDefultsWrapper.AppSocketUrl
                if url_debug.isEmpty {
                    return PTSocketManager.share.socketAddress_dev
                } else {
                    return url_debug
                }
            case .Test:
                return PTSocketManager.share.socketAddress_dev
            case .Distribution:
                return PTSocketManager.share.socketAddress
            }
        } else {
            return PTSocketManager.share.socketAddress
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override init() {
        super.init()
                        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onNetworkStatusChange(notifi:)), name: NSNotification.Name(rawValue: nNetworkStatesChangeNotification), object: nil)
    }
    
    public func socketSet() {
        let urlString = PTSocketManager.gobalUrl()
        let webSocketUrl = URL(string: urlString)
        var urlcomponents = URLComponents(url: webSocketUrl!, resolvingAgainstBaseURL: false)
        urlcomponents!.scheme = webSocketUrl?.scheme
        
        let url = urlcomponents!.url
        self.request = NSMutableURLRequest(url: url!, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringCacheData, timeoutInterval: 1)
    }

    @objc func onNetworkStatusChange(notifi:Notification) {
        if webSocket != nil && !networkIsNotReachable() && !isClosed() {
            reConnect()
        }
    }
    
    public func isClosed() -> Bool {
        PTNSLogConsole("socket连接状态---\(webSocket?.readyState.rawValue ?? 0)",levelType: PTLogMode,loggerType: .Network)
        if webSocket?.readyState != .OPEN {
            return true
        }
        return false
    }
    
    public func reConnect() {
        disConnect()
        connect()
    }
    
    public func disConnect() {
        if webSocket?.readyState == .CLOSING || webSocket?.readyState == .CLOSED {
            return
        }
        
        if webSocket != nil {
            webSocket?.close()
            webSocket = nil
        }
    }
    
    public func connect() {
        if webSocket?.readyState == .OPEN {
            disConnect()
        }
        
        webSocket = SRWebSocket(urlRequest: request as URLRequest)
        webSocket?.delegate = self
        webSocket?.open()
    }
    
    public func startReconnect() {
        if !networkIsNotReachable() {
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
        if webSocket?.readyState == .OPEN {
            do {
                try webSocket?.send(string: msg)
            } catch {
                PTNSLogConsole("\(error.localizedDescription)",levelType: .Error,loggerType: .Network)
            }
        }
    }
    
    func networkIsNotReachable() ->Bool {
        return PTSocketManager.share.networkStatus == .notReachable
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
        startReconnect()
    }
}

