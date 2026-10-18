//
//  PTPingActivityIndicator.swift
//  ZolaFly
//
//  Created by 邓杰豪 on 21/9/23.
//  Copyright © 2023 LYH. All rights reserved.
//

import UIKit
#if canImport(PToolsConstraintLayout)
import PToolsConstraintLayout
#endif
import SnapKit
#if SWIFT_PACKAGE
import ptools
#endif

@MainActor
class PTPingActivityIndicator {
    static let shared = PTPingActivityIndicator()
    var statusBarStyle: UIStatusBarStyle = .lightContent

    var isHidden = false {
        willSet {
            Task { @MainActor in
                self.mIndicatorWindow.isHidden = newValue
            }
        }
    }

    private init(){
        Task { @MainActor in
            self.createUI()
        }
    }

    func update(time: Int) {
        mLabel.text = "\(time)ms"
    }

    //MARK: UI
    lazy var mLabel: UILabel = {
        let label = UILabel()
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
    @MainActor func createUI() {
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
            mLabel.ptLayout.makeConstraints { make in
                make.centerX.equalTo(mIndicatorWindow.ptLayout.trailing).offset(-56)
                make.top.equalToSuperview()
            }
        } else {
            mLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
            mLabel.ptLayout.makeConstraints { make in
                make.centerX.equalToSuperview().offset(mIndicatorWindow.frame.size.width / 8)
                make.centerY.equalToSuperview()
            }
        }
    }
}
