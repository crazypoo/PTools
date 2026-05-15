//
//  PTPingTool.swift
//  ZolaFly
//
//  Created by 邓杰豪 on 21/9/23.
//  Copyright © 2023 LYH. All rights reserved.
//

import Foundation
import UIKit

public enum PTPingTimeInterval: Sendable {
    case second(_ interval: TimeInterval)       //秒
    case millisecond(_ interval: TimeInterval)  //毫秒
    case microsecond(_ interval: TimeInterval)  //微秒

    public var second: TimeInterval {
        switch self {
            case .second(let interval):
                return interval
            case .millisecond(let interval):
                return interval / 1000.0
            case .microsecond(let interval):
                return interval / 1000000.0
        }
    }
}

public struct PTPingResponse: Sendable {
    public var pingAddressIP = ""
    public var responseTime: PTPingTimeInterval = .second(0)
    public var responseBytes: Int = 0
}

// 1. 优化：将回调标记为 @Sendable，确保跨隔离域传递时的线程安全
public typealias PingComplete = @Sendable (PTPingResponse?, (any Error)?) -> Void

public enum NetworkActivityIndicatorStatus: Sendable {
    case auto       //自动显示
    case always     //一直显示
    case none       //不显示
}

public enum PTPingError: Error, Equatable, Sendable {
    case requestError   //发起失败
    case receiveError   //响应失败
    case timeout        //超时
}

struct PTPingItem: Sendable {
    var sendTime = Date()
    var sequence: UInt16 = 0
}

// 2. 核心优化：使用 @MainActor 隔离整个工具类
// 这不仅符合该类重度依赖 RunLoop.main 和更新 UI Indicator 的现状，也彻底解决了状态竞争警告
@MainActor
open class PTPingTool: NSObject {
    open var timeout: PTPingTimeInterval = .millisecond(1000)  //自定义超时时间，默认1000毫秒，设置为0则一直等待
    open var debugLog = true                                   //是否开启日志输出
    open var stopWhenError = false                             //遇到错误停止ping
    open private(set) var isPing = false
    open var isRunning: Bool = false
    open var showNetworkActivityIndicator: NetworkActivityIndicatorStatus = .none              //是否在状态栏显示
    
    open var hostName: String? {
        get {
            pinger.hostName
        }
        set {
            let oldPinger = pinger
            var host = newValue ?? "www.apple.com"
            if host.isEmpty {
                host = "www.apple.com"
            }
            pinger = SimplePing(hostName: host)
            pinger.delegate = self
            if isPing {
                start(pingType: oldPinger.addressStyle, interval: pingInterval, complete: complete)
            }
        }
    }

    private var pinger: SimplePing
    private var pingInterval: PTPingTimeInterval = .second(0)
    private var complete: PingComplete?
    private var lastSendItem: PTPingItem?
    private var lastReciveItem: PTPingItem?
    private var sendTimer: Timer?
    private var checkTimer: Timer?
    private var pingAddressIP = ""

    deinit {
        NotificationCenter.default.removeObserver(self)
        // 确保销毁时清理定时器
//        sendTimer?.invalidate()
//        checkTimer?.invalidate()
    }

    public init(hostName: String? = nil) {
        var host = hostName ?? "www.apple.com"
        if host.isEmpty {
            host = "www.apple.com"
        }
        pinger = SimplePing(hostName: host)
        super.init()
        pinger.delegate = self
    }

    public convenience init(url: URL?) {
        self.init(hostName: url?.host)
    }

    /// 开始ping请求
    /// - Parameters:
    ///   - pingType: ping的类型
    ///   - interval: 是否重复定时ping
    ///   - complete: 请求的回调
    public func start(pingType: AddressStyle = .any, interval: PTPingTimeInterval = .second(0), complete: PingComplete? = nil) {
        //移除消息订阅
        NotificationCenter.default.removeObserver(self)
        //切到后台
        NotificationCenter.default.addObserver(self, selector: #selector(_didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        //切到前台
        NotificationCenter.default.addObserver(self, selector: #selector(_didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        //开始请求
        pingStart(pingType: pingType, interval: interval, complete: complete)
    }

    //结束ping
    public func stop() {
        //移除消息订阅
        NotificationCenter.default.removeObserver(self)
        //移除顶部状态栏显示
        if showNetworkActivityIndicator == .auto || showNetworkActivityIndicator == .none {
            PTPingActivityIndicator.shared.isHidden = true
        } else {
            PTPingActivityIndicator.shared.isHidden = false
        }
        //结束状态
        pingStop()
    }
}

private extension PTPingTool {
    /// 开始ping请求
    func pingStart(pingType: AddressStyle = .any, interval: PTPingTimeInterval = .second(0), complete: PingComplete? = nil) {
        pingStop()
        if showNetworkActivityIndicator == .auto || showNetworkActivityIndicator == .always {
            PTPingActivityIndicator.shared.isHidden = false
        } else {
            PTPingActivityIndicator.shared.isHidden = true
        }

        pingInterval = interval
        self.complete = complete
        pinger.addressStyle = pingType
        pinger.start()
        isRunning = true

        if interval.second > 0 {
            // 3. 修复闭包并发捕获：在 Timer 闭包内部声明 @MainActor，确保对 self 的访问安全
            sendTimer = Timer(timeInterval: interval.second, repeats: true, block: { [weak self, pingType, interval, complete] (_) in
                            
                // 内层的 Task 同样需要声明捕获这些变量
                Task { @MainActor [weak self, pingType, interval, complete] in
                    guard let self = self else { return }
                    self.pingStart(pingType: pingType, interval: interval, complete: complete)
                }
            })
        }
    }

    func pingStop() {
        pingComplete()
        //停止发送ping
        sendTimer?.invalidate()
        sendTimer = nil
        isRunning = false
    }

    //ping完成一次之后的清理，ping成功或失败均会调用
    func pingComplete() {
        pinger.stop()
        isPing = false
        lastSendItem = nil
        lastReciveItem = nil
        pingAddressIP = ""
        //检测超时的timer停止
        checkTimer?.invalidate()
        checkTimer = nil
    }

    @objc func _didEnterBackground() {
        if debugLog {
            PTNSLogConsole("didEnterBackground: stop ping", levelType: PTLogMode, loggerType: .network)
        }
        pingStop()
    }

    @objc func _didBecomeActive() {
        if debugLog {
            PTNSLogConsole("didBecomeActive: ping resume", levelType: PTLogMode, loggerType: .network)
        }
        start(pingType: pinger.addressStyle, interval: pingInterval, complete: complete)
    }

    func sendPingData() {
        guard !isPing else { return }
        pinger.sendPing(data: nil)
    }

    func displayAddressForAddress(address: NSData) -> String {
        var hostStr = [Int8](repeating: 0, count: Int(NI_MAXHOST))

        let success = getnameinfo(
            address.bytes.assumingMemoryBound(to: sockaddr.self),
            socklen_t(address.length),
            &hostStr,
            socklen_t(hostStr.count),
            nil,
            0,
            NI_NUMERICHOST
        ) == 0
        let result: String
        if success {
            result = String(cString: hostStr)
        } else {
            result = "?"
        }
        return result
    }

    func shortErrorFromError(error: NSError) -> String {
        if error.domain == kCFErrorDomainCFNetwork as String && error.code == Int(CFNetworkErrors.cfHostErrorUnknown.rawValue) {
            if let failureObj = error.userInfo[kCFGetAddrInfoFailureKey as String] {
                if let failureNum = failureObj as? NSNumber {
                    if failureNum.intValue != 0 {
                        let f = gai_strerror(Int32(failureNum.intValue))
                        if f != nil {
                            return String(cString: f!)
                        }
                    }
                }
            }
        }
        if let result = error.localizedFailureReason {
            return result
        }
        return error.localizedDescription
    }
}

extension PTPingTool: SimplePingDelegate {
    
    // 代理方法将由 SimplePing 在其调度的 RunLoop (此处为 Main) 上触发，受 @MainActor 保护
    nonisolated public func simplePing(_ pinger: SimplePing, didStart address: Data) {
        Task { @MainActor in
            self.pingAddressIP = self.displayAddressForAddress(address: NSData(data: address))
            if self.debugLog {
                PTNSLogConsole("ping: ", self.pingAddressIP, levelType: PTLogMode, loggerType: .network)
            }
            //发送一次ping
            self.sendPingData()
        }
    }

    nonisolated public func simplePing(_ pinger: SimplePing, didFail error: Error) {
        Task { @MainActor in
            if self.debugLog {
                PTNSLogConsole("ping failed: ", self.shortErrorFromError(error: error as NSError), levelType: .error, loggerType: .network)
            }
            PTPingActivityIndicator.shared.update(time: 460)
            if let complete = self.complete {
                complete(nil, PTPingError.requestError)
            }
            //标记完成
            self.pingComplete()
            //停止ping
            if self.stopWhenError {
                self.pingStop()
            }
        }
    }

    nonisolated public func simplePing(_ pinger: SimplePing, didSendPacket packet: Data, sequenceNumber: UInt16) {
        Task { @MainActor in
            if self.debugLog {
                PTNSLogConsole("ping sent \(packet.count) data bytes, icmp_seq=\(sequenceNumber)", levelType: PTLogMode, loggerType: .network)
            }
            self.isPing = true
            self.lastSendItem = PTPingItem(sendTime: Date(), sequence: sequenceNumber)
            
            //发送数据之后监测是否超时
            if self.timeout.second > 0 {
                self.checkTimer?.invalidate()
                self.checkTimer = nil
                
                // 确保在主线程上下文安全解包 self 和处理超时逻辑
                self.checkTimer = Timer(timeInterval: self.timeout.second, repeats: false, block: { [weak self] (_) in
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        if self.lastSendItem?.sequence != self.lastReciveItem?.sequence {
                            PTPingActivityIndicator.shared.update(time: 460)
                            //超时
                            if let complete = self.complete {
                                complete(nil, PTPingError.timeout)
                            }
                            //标记完成
                            self.pingComplete()
                            //停止ping
                            if self.stopWhenError {
                                self.pingStop()
                            }
                        }
                    }
                })
                if let timer = self.checkTimer {
                    RunLoop.main.add(timer, forMode: .common)
                }
            }
        }
    }

    nonisolated public func simplePing(_ pinger: SimplePing, didFailToSendPacket packet: Data, sequenceNumber: UInt16, error: Error) {
        Task { @MainActor in
            if self.debugLog {
                PTNSLogConsole("ping send error: ", sequenceNumber, self.shortErrorFromError(error: error as NSError), levelType: .error, loggerType: .network)
            }
            PTPingActivityIndicator.shared.update(time: 460)
            if let complete = self.complete {
                complete(nil, PTPingError.receiveError)
            }
            self.pingComplete()
            if self.stopWhenError {
                self.pingStop()
            }
        }
    }

    nonisolated public func simplePing(_ pinger: SimplePing, didReceivePingResponsePacket packet: Data, sequenceNumber: UInt16) {
        Task { @MainActor in
            if let sendPingItem = self.lastSendItem {
                let time = Date().timeIntervalSince(sendPingItem.sendTime).truncatingRemainder(dividingBy: 1) * 1000
                if self.debugLog {
                    PTNSLogConsole("\(packet.count) bytes from \(self.pingAddressIP): icmp_seq=\(sequenceNumber) time=\(time)ms", levelType: PTLogMode, loggerType: .network)
                }
                PTPingActivityIndicator.shared.update(time: Int(time))
                if let complete = self.complete {
                    let response = PTPingResponse(pingAddressIP: self.pingAddressIP, responseTime: .millisecond(time), responseBytes: packet.count)
                    complete(response, nil)
                }
                self.lastReciveItem = PTPingItem(sendTime: Date(), sequence: sequenceNumber)
                self.pingComplete()
            }
        }
    }

    nonisolated public func simplePing(_ pinger: SimplePing, didReceiveUnexpectedPacket packet: Data) {
        Task { @MainActor in
            if self.debugLog {
                PTNSLogConsole("unexpected receive packet, size=\(packet.count)", levelType: PTLogMode, loggerType: .network)
            }
            self.pingComplete()
            if self.stopWhenError {
                self.pingStop()
            }
        }
    }
}
