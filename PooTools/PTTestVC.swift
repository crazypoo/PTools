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
