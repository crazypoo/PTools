//
//  PTAlertController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/6/15.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

@MainActor
@objcMembers
open class PTAlertController: PTBaseViewController {

    // MARK: - Config
    open var config = PTAlertConfig()
    weak var preferredWindowScene: UIWindowScene?
    private var sourceStatusBarHidden = false
    private var sourceStatusBarStyle: UIStatusBarStyle = .default

    // MARK: - Identity（更安全）
    open lazy var key: String = UUID().uuidString

    // MARK: - Lifecycle
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    @available(*, unavailable)
    @MainActor required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        // 调试建议打开
//         PTNSLogConsole("PTAlertController deinit: \(key)")
    }
}

// MARK: - UI Setup
extension PTAlertController {

    override open func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        view.isOpaque = false
        syncSystemUI()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
}

// MARK: - System Sync
private extension PTAlertController {

    func syncSystemUI() {
        guard let scene = viewIfLoaded?.window?.windowScene,
              let rootVC = scene.windows
                .first(where: {
                    $0.windowLevel == .normal &&
                    $0.rootViewController != nil
                })?.rootViewController else { return }

        config.supportedInterfaceOrientations = rootVC.supportedInterfaceOrientations
        sourceStatusBarHidden = rootVC.prefersStatusBarHidden
        sourceStatusBarStyle = rootVC.preferredStatusBarStyle
    }
}

// MARK: - Rotation
extension PTAlertController {

    override open var shouldAutorotate: Bool {
        config.shouldAutorotate
    }

    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        config.supportedInterfaceOrientations
    }

    override open var prefersStatusBarHidden: Bool {
        sourceStatusBarHidden
    }

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        sourceStatusBarStyle
    }
}

// MARK: - Style
extension PTAlertController {
    override open var overrideUserInterfaceStyle: UIUserInterfaceStyle {
        set {
            super.overrideUserInterfaceStyle = newValue
            config.userInterfaceStyleOverride = PTAlertConfig.PTUserInterfaceStyle(rawValue: newValue.rawValue) ?? .unspecified
        }
        get {
            .init(rawValue: config.userInterfaceStyleOverride.rawValue) ?? .unspecified
        }
    }
}

// MARK: - Control
extension PTAlertController {

    /// 主动关闭（推荐使用）
    public func dismissSelf(completion: PTActionTask? = nil) {
        PTAlertManager.dismiss(self.key, completion: completion)
    }
}

// MARK: - Protocol
extension PTAlertController: PTAlertProtocol {

    open func showAnimation(completion: PTActionTask? = nil) {
        completion?()
    }

    open func dismissAnimation(completion: PTActionTask? = nil) {
        completion?()
    }
}
