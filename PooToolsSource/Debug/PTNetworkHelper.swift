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

final class PTNetworkHelper {
    static let shared = PTNetworkHelper()

    var mainColor: UIColor
    var protobufTransferMap: [String: [String]]?
    var isNetworkEnable: Bool

    var floatingView : PFloatingButton?
    lazy var speedLabel : UILabel = {
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

    func enable() {
        guard !isNetworkEnable else { return }
        isNetworkEnable = true
        PTCustomHTTPProtocol.start()
        floatingButtonCreate()
        measurementsTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateSpeedLabels), userInfo: nil, repeats: true)
    }

    func disable() {
        guard isNetworkEnable else { return }
        isNetworkEnable = false
        PTCustomHTTPProtocol.stop()
        if let floatingView = floatingView {
            floatingView.removeFromSuperView()
            self.floatingView = nil
        }
        measurementsTimer?.invalidate()
        measurementsTimer = nil
    }
    
    private func floatingButtonCreate() {
        if floatingView == nil {
            floatingView = PFloatingButton(view: AppWindows as Any, frame: CGRect(x: PTAppBaseConfig.share.defaultViewSpace, y: CGFloat.statusBarHeight() + 30, width: 100, height: 40))
            floatingView?.tag = PTNetworkFloatingTap
            floatingView?.autoDocking = false
            floatingView?.addSubview(speedLabel)
            speedLabel.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
    
    @objc private func updateSpeedLabels() {
        let downloadSpeed = PTNetworkSpeedMonitor.shared.averageDownloadSpeed() / 1024
        let uploadSpeed = PTNetworkSpeedMonitor.shared.averageUploadSpeed() / 1024

        PTNetworkHelper.shared.speedLabel.text = String(format: "↑ %.2f KB/s\n↓ %.2f KB/s",uploadSpeed, downloadSpeed)
    }
}
