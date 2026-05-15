//
//  PTNetworkHelper.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

let PTNetworkFloatingTap = 9998

// MARK: - 全局网络监控控制助手
final class PTNetworkHelper {
    static let shared = PTNetworkHelper()

    var mainColor: UIColor
    var protobufTransferMap: [String: [String]]?
    var isNetworkEnable: Bool

    var floatingView: PFloatingButton?
    lazy var speedLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .black
        label.textColor = .white
        label.numberOfLines = 0
        label.font = .appfont(size: 10)
        label.textAlignment = .center
        return label
    }()
    var measurementsTimer: Timer?

    private init() {
        self.mainColor = UIColor(hexString: "#42d459") ?? UIColor.green
        self.isNetworkEnable = false
    }

    @MainActor func enable() {
        guard !isNetworkEnable else { return }
        isNetworkEnable = true
        PTCustomHTTPProtocol.start()
        floatingButtonCreate()
        // 开启每秒刷新悬浮窗网速显示的定时器
        measurementsTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateSpeedLabels), userInfo: nil, repeats: true)
    }

    func disable() {
        guard isNetworkEnable else { return }
        isNetworkEnable = false
        PTCustomHTTPProtocol.stop()
        if let floatingView = floatingView {
            floatingView.removeFromSuperview()
            self.floatingView = nil
        }
        measurementsTimer?.invalidate()
        measurementsTimer = nil
    }
    
    @MainActor private func floatingButtonCreate() {
        if floatingView == nil {
            floatingView = PFloatingButton(inView: PTConsoleWindow.shared, frame: CGRect(x: PTAppBaseConfig.share.defaultViewSpace, y: CGFloat.statusBarHeight() + 30, width: 100, height: 40))
            floatingView?.tag = PTNetworkFloatingTap
            floatingView?.autoDocking = false
            floatingView?.addSubview(speedLabel)
            speedLabel.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
    
    @objc private func updateSpeedLabels() {
        // 安全读取第一步重构的线程安全测速池数据
        let downloadSpeed = PTNetworkSpeedMonitor.shared.averageDownloadSpeed() / 1024.0
        let uploadSpeed = PTNetworkSpeedMonitor.shared.averageUploadSpeed() / 1024.0

        PTNetworkHelper.shared.speedLabel.text = String(format: "↑ %.2f KB/s\n↓ %.2f KB/s", uploadSpeed, downloadSpeed)
    }
}
