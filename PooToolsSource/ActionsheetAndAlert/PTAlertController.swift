//
//  PTAlertController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/6/15.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
open class PTAlertController: PTBaseViewController {

    // MARK: - Config
    open var config = PTAlertConfig()

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
         PTNSLogConsole("PTAlertController deinit: \(key)")
    }
}

// MARK: - UI Setup
extension PTAlertController {

    override open func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        view.isOpaque = false
        view.layer.drawsAsynchronously = true

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
        guard let rootVC = UIApplication.shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController else { return }

        StatusBarManager.shared.isHidden = rootVC.prefersStatusBarHidden
        StatusBarManager.shared.style = rootVC.preferredStatusBarStyle
        config.supportedInterfaceOrientations = rootVC.supportedInterfaceOrientations
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
}

// MARK: - Style
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
