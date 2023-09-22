//
//  PTPingActivityIndicator.swift
//  ZolaFly
//
//  Created by 邓杰豪 on 21/9/23.
//  Copyright © 2023 LYH. All rights reserved.
//

import UIKit

class PTPingActivityIndicator {
    static let shared = PTPingActivityIndicator()
    var statusBarStyle: UIStatusBarStyle = .lightContent

    var isHidden = false {
        willSet {
            PTGCDManager.gcdMain {
                self.mIndicatorWindow.isHidden = newValue
            }
        }
    }

    private init(){
        PTGCDManager.gcdMain {
            self.createUI()
        }
    }

    func update(time: Int) {
        self.mLabel.text = "\(time)ms"
    }

    //MARK: UI
    lazy var mLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var mIndicatorWindow: UIWindow = {
        var window = UIWindow(frame: .zero)
        window.backgroundColor = UIColor.clear
        window.windowLevel = .statusBar + 1
        window.isUserInteractionEnabled = false
        return window
    }()
}

private extension PTPingActivityIndicator {
    func createUI() {
        if #available(iOS 13.0, *) {
            if let windowScene = UIApplication.shared.windows.first?.windowScene, let statusBarManager = windowScene.statusBarManager {
                self.mIndicatorWindow.windowScene = windowScene
                self.mIndicatorWindow.frame = statusBarManager.statusBarFrame
                self.statusBarStyle = statusBarManager.statusBarStyle
            }
        } else {
            self.mIndicatorWindow.frame = UIApplication.shared.statusBarFrame
            self.statusBarStyle = UIApplication.shared.statusBarStyle
        }
        if self.statusBarStyle == .lightContent {
            self.mLabel.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.85)
        } else {
            self.mLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.85)
        }

        self.mIndicatorWindow.addSubview(self.mLabel)
        if self.mIndicatorWindow.frame.size.height > 30 {
            self.mLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
            self.mLabel.centerXAnchor.constraint(equalTo: self.mIndicatorWindow.rightAnchor, constant: -56).isActive = true
            self.mLabel.topAnchor.constraint(equalTo: self.mIndicatorWindow.topAnchor).isActive = true
        } else {
            self.mLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
            self.mLabel.centerXAnchor.constraint(equalTo: self.mIndicatorWindow.centerXAnchor, constant: self.mIndicatorWindow.frame.size.width/8).isActive = true
            self.mLabel.centerYAnchor.constraint(equalTo: self.mIndicatorWindow.centerYAnchor).isActive = true
        }
    }
}
