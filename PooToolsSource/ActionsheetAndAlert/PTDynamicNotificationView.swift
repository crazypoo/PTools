//
//  PTDynamicNotificationView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 6/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

@MainActor
public class PTDynamicNotificationView: UIView {

    public var hideHandler: PTActionTask?

    private let contentHeight: CGFloat = 160
    private let autoDismiss = PTAlertTipsAutoDismiss()
    private var didCallHideHandler = false

    private lazy var cameraArea: UIView = UIView()
    private lazy var contentViews: UIView = UIView()
    private let showTime: TimeInterval
    private let canTap: Bool

    public init(showTimes: TimeInterval = 3,
                canTap: Bool = true,
                content: ((UIView) -> Void)) {
        showTime = showTimes
        self.canTap = canTap
        super.init(frame: .zero)

        backgroundColor = PTDarkModeOption.colorLightDark(
            lightColor: .white,
            darkColor: .Black25PercentColor
        )
        viewCorner(radius: 15)
        addSubviews([cameraArea, contentViews])
        cameraArea.snp.makeConstraints { make in
            make.width.equalTo(CGFloat.ScaleW(w: 104))
            make.height.equalTo(CGFloat.ScaleW(w: 36.67))
            make.centerX.top.equalToSuperview()
        }
        contentViews.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(cameraArea.snp.bottom)
        }
        content(contentViews)

        if canTap {
            let tap = UITapGestureRecognizer { [weak self] _ in
                self?.hideNotification()
            }
            addGestureRecognizer(tap)
        }
    }

    override init(frame: CGRect) {
        showTime = 3
        canTap = true
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func showNotification() {
        guard let window = activeWindow else { return }
        showNotification(in: window)
    }

    public func showNotification(in containerView: UIView) {
        autoDismiss.beginPresentation()
        didCallHideHandler = false
        if superview !== containerView {
            removeFromSuperview()
            containerView.addSubview(self)
        }
        snp.remakeConstraints { make in
            make.left.right.equalToSuperview().inset(10)
            make.height.equalTo(contentHeight)
            make.top.equalTo(containerView.safeAreaLayoutGuide.snp.top).offset(10)
        }

        alpha = 1
        PTAnimationFunction.animationIn(
            animationView: self,
            animationType: .Top,
            transformValue: contentHeight
        )
        autoDismiss.schedule(after: showTime) { [weak self] in
            self?.hideNotification()
        }
    }

    public func hideNotification() {
        guard autoDismiss.beginDismiss() else { return }

        PTAnimationFunction.animationOut(
            animationView: self,
            animationType: .Top,
            toValue: -(contentHeight + 10),
            animation: { [weak self] in
                PTGCDManager.shared.runOnMain {
                    self?.alpha = 0
                }
            },
            completion: { [weak self] _ in
                guard let self else { return }
                PTGCDManager.shared.runOnMain {
                    self.removeFromSuperview()
                    guard !self.didCallHideHandler else { return }
                    self.didCallHideHandler = true
                    let handler = self.hideHandler
                    self.hideHandler = nil
                    handler?()
                }
            }
        )
    }

    private var activeWindow: UIWindow? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        return scenes
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
            ?? scenes.first(where: { $0.activationState == .foregroundActive })?.windows
                .first(where: { !$0.isHidden })
    }
}
