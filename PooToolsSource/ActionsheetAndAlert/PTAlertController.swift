//
//  PTAlertController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/6/15.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif

@objcMembers
open class PTAlertController: PTBaseViewController {

    open var config = PTAlertConfig()
    
    open var key: String {
        "\(Unmanaged.passUnretained(self).toOpaque())"
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        let keyWindow = AppWindows

        if let prefersStatusBarHidden = keyWindow?.rootViewController?.prefersStatusBarHidden {
            StatusBarManager.shared.isHidden = prefersStatusBarHidden
        }
        if let preferredStatusBarStyle = keyWindow?.rootViewController?.preferredStatusBarStyle {
            StatusBarManager.shared.style = preferredStatusBarStyle
        }
        if let supportedInterfaceOrientations = keyWindow?.rootViewController?.supportedInterfaceOrientations {
            config.supportedInterfaceOrientations = supportedInterfaceOrientations
        }
    }
    
    @available(*, unavailable)
    @MainActor required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PTAlertController {
    override open var overrideUserInterfaceStyle: UIUserInterfaceStyle {
        set {
            super.overrideUserInterfaceStyle = newValue
        }
        get {
            .init(rawValue: config.userInterfaceStyleOverride.rawValue) ?? .light
        }
    }
}

extension PTAlertController {
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_hideBaseNavBar = true
#else
        navigationController?.navigationBar.isHidden = true
#endif
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
}

extension PTAlertController {

    override open var shouldAutorotate: Bool {
        config.shouldAutorotate
    }

    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        config.supportedInterfaceOrientations
    }
}

extension PTAlertController: PTAlertProtocol {
    public func showAnimation(completion: PTActionTask? = nil) { }

    public func dismissAnimation(completion: PTActionTask? = nil) { }
}
