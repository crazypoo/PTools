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
        mLabel.text = "\(time)ms"
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
        if let windowScene = AppWindows?.windowScene, let statusBarManager = windowScene.statusBarManager {
            mIndicatorWindow.windowScene = windowScene
            mIndicatorWindow.frame = statusBarManager.statusBarFrame
            statusBarStyle = statusBarManager.statusBarStyle
        }
        
        if statusBarStyle == .lightContent {
            mLabel.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.85)
        } else {
            mLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.85)
        }

        mIndicatorWindow.addSubview(mLabel)
        if mIndicatorWindow.frame.size.height > 30 {
            mLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
            mLabel.centerXAnchor.constraint(equalTo: mIndicatorWindow.rightAnchor, constant: -56).isActive = true
            mLabel.topAnchor.constraint(equalTo: mIndicatorWindow.topAnchor).isActive = true
        } else {
            mLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
            mLabel.centerXAnchor.constraint(equalTo: mIndicatorWindow.centerXAnchor, constant: mIndicatorWindow.frame.size.width/8).isActive = true
            mLabel.centerYAnchor.constraint(equalTo: mIndicatorWindow.centerYAnchor).isActive = true
        }
    }
}
