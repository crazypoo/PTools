//
//  PTNetworkHelper.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class PTNetworkHelper {
    static let shared = PTNetworkHelper()

    var mainColor: UIColor
    var protobufTransferMap: [String: [String]]?
    var isNetworkEnable: Bool

    private init() {
        self.mainColor = UIColor(hexString: "#42d459") ?? UIColor.green
        self.isNetworkEnable = false
    }

    func enable() {
        guard !isNetworkEnable else { return }
        isNetworkEnable = true
        PTCustomHTTPProtocol.start()
    }

    func disable() {
        guard isNetworkEnable else { return }
        isNetworkEnable = false
        PTCustomHTTPProtocol.stop()
    }
}
