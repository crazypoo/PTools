//
//  PTDebugShareManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/28.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

enum PTDebugShareManager {

    static func generateFileAndShare(text: String, fileName: String) {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(fileName).txt")

        do {
            try text.write(to: tempURL, atomically: true, encoding: .utf8)
            share(tempURL)
        } catch {
            PTNSLogConsole("Error: \(error.localizedDescription)")
        }
    }

    static func share(_ tempURL: URL) {
        
        let items: [Any] = [tempURL]

        let vc = PTActivityViewController(activityItems: items)
        vc.previewNumberOfLines = 10
        
        let currentVC = PTUtils.getCurrentVC()
        if currentVC is PTSideMenuControl {
            let currentVC = (currentVC as! PTSideMenuControl).contentViewController
            if let presentedVC = currentVC?.presentedViewController {
                vc.presentActionSheet(presentedVC, from: presentedVC.view)
            } else {
                vc.presentActionSheet(currentVC!, from: currentVC!.view)
            }
        } else {
            if let presentedVC = PTUtils.getCurrentVC().presentedViewController {
                vc.presentActionSheet(presentedVC, from: presentedVC.view)
            } else {
                vc.presentActionSheet(PTUtils.getCurrentVC(), from: PTUtils.getCurrentVC().view)
            }
        }
    }
}
