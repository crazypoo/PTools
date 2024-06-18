//
//  PTTestVC.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/6/18.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import Network
import ObjectiveC
import Foundation

class PTTestVC: PTBaseViewController {

    let networkSpeedMonitor = NetworkSpeedMonitor()

    override func viewDidLoad() {
        super.viewDidLoad()

        networkSpeedMonitor.startMonitoring()
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateSpeedLabels), userInfo: nil, repeats: true)
    }
    
    @objc func updateSpeedLabels() {
        PTNSLogConsole("\(String(format: "Download Speed: %.2f KB/s", networkSpeedMonitor.downloadSpeed / 1024))")
        PTNSLogConsole("\(String(format: "Upload Speed: %.2f KB/s", networkSpeedMonitor.uploadSpeed / 1024))")
    }
}

class NetworkSpeedMonitor {

    private var connection: NWConnection?
    private var listener: NWListener?
    private var startTime: TimeInterval?
    private var bytesReceived: Int = 0
    private var bytesSent: Int = 0

    var downloadSpeed: Double = 0.0
    var uploadSpeed: Double = 0.0

    func startMonitoring() {
        startListener()
        startConnection()
    }

    func stopMonitoring() {
        connection?.cancel()
        listener?.cancel()
    }

    private func startListener() {
        do {
            listener = try NWListener(using: .tcp, on: 8080)
            listener?.newConnectionHandler = { [weak self] newConnection in
                self?.setupReceive(on: newConnection)
                newConnection.start(queue: .global())
            }
            listener?.start(queue: .global())
        } catch {
            print("Failed to create listener: \(error)")
        }
    }

    private func startConnection() {
        connection = NWConnection(host: "127.0.0.1", port: 8080, using: .tcp)
        connection?.start(queue: .global())
        startSendingData()
    }

    private func startSendingData() {
        guard let connection = connection else { return }
        let data = Data(repeating: 0, count: 1024)
        startTime = Date().timeIntervalSince1970

        connection.send(content: data, completion: .contentProcessed { [weak self] error in
            if error == nil {
                self?.bytesSent += data.count
                self?.calculateUploadSpeed()
                self?.startSendingData()
            }
        })
    }

    private func setupReceive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] data, _, _, error in
            guard let self = self, let data = data, error == nil else { return }
            self.bytesReceived += data.count
            self.calculateDownloadSpeed()
            self.setupReceive(on: connection)
        }
    }

    private func calculateDownloadSpeed() {
        guard let startTime = startTime else { return }
        let elapsedTime = Date().timeIntervalSince1970 - startTime
        downloadSpeed = Double(bytesReceived) / elapsedTime
    }

    private func calculateUploadSpeed() {
        guard let startTime = startTime else { return }
        let elapsedTime = Date().timeIntervalSince1970 - startTime
        uploadSpeed = Double(bytesSent) / elapsedTime
    }
}

class NetworkSpeedURLProtocol: URLProtocol {
    
    private var startTime: Date?
    private var endTime: Date?
    private var dataTask: URLSessionDataTask?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return URLProtocol.property(forKey: "Handled", in: request) == nil
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        startTime = Date()
        let newRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        URLProtocol.setProperty(true, forKey: "Handled", in: newRequest)
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.protocolClasses = [NetworkSpeedURLProtocol.self]
        
        let session = URLSession(configuration: sessionConfig)
        dataTask = session.dataTask(with: newRequest as URLRequest, completionHandler: { data, response, error in
            self.endTime = Date()
            if let data = data {
                self.client?.urlProtocol(self, didLoad: data)
            }
            if let response = response {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let error = error {
                self.client?.urlProtocol(self, didFailWithError: error)
            }
            self.client?.urlProtocolDidFinishLoading(self)
            
            if let startTime = self.startTime, let endTime = self.endTime {
                let elapsedTime = endTime.timeIntervalSince(startTime)
                let downloadSpeed = Double(data?.count ?? 0) / elapsedTime
                PTNetworkSpeedMonitor.shared.addDownloadSpeed(downloadSpeed)
            }
        })
        dataTask?.resume()
    }
    
    override func stopLoading() {
        dataTask?.cancel()
    }
}

class PTNetworkSpeedMonitor {
    
    static let shared = PTNetworkSpeedMonitor()
    
    private var downloadSpeeds: [Double] = []
    private var uploadSpeeds: [Double] = []
    
    private init() {}
    
    func addDownloadSpeed(_ speed: Double) {
        downloadSpeeds.append(speed)
    }
    
    func addUploadSpeed(_ speed: Double) {
        uploadSpeeds.append(speed)
    }
    
    func averageDownloadSpeed() -> Double {
        return downloadSpeeds.reduce(0, +) / Double(downloadSpeeds.count)
    }
    
    func averageUploadSpeed() -> Double {
        return uploadSpeeds.reduce(0, +) / Double(uploadSpeeds.count)
    }
}

extension URLSession {
    
    static let swizzle: Void = {
        let originalSelector1 = #selector(URLSession.dataTask(with:completionHandler:) as (URLSession) -> (URLRequest, @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask)
        let swizzledSelector1 = #selector(swizzled_dataTask(with:completionHandler:))
        
        let originalSelector2 = #selector(URLSession.dataTask(with:) as (URLSession) -> (URLRequest) -> URLSessionDataTask)
        let swizzledSelector2 = #selector(swizzled_dataTask(with:))
        
        if let originalMethod1 = class_getInstanceMethod(URLSession.self, originalSelector1),
           let swizzledMethod1 = class_getInstanceMethod(URLSession.self, swizzledSelector1) {
            method_exchangeImplementations(originalMethod1, swizzledMethod1)
        }
        
        if let originalMethod2 = class_getInstanceMethod(URLSession.self, originalSelector2),
           let swizzledMethod2 = class_getInstanceMethod(URLSession.self, swizzledSelector2) {
            method_exchangeImplementations(originalMethod2, swizzledMethod2)
        }
    }()
    
    @objc func swizzled_dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let modifiedRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        URLProtocol.setProperty(true, forKey: "Handled", in: modifiedRequest)
        return self.swizzled_dataTask(with: modifiedRequest as URLRequest, completionHandler: completionHandler)
    }
    
    @objc func swizzled_dataTask(with request: URLRequest) -> URLSessionDataTask {
        let modifiedRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        URLProtocol.setProperty(true, forKey: "Handled", in: modifiedRequest)
        return self.swizzled_dataTask(with: modifiedRequest as URLRequest)
    }
}
