//
//  PTVideoEditorControlsView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

let PTVideoEditorPodBundleName = "PTVideoEditorResources"

final class PTVideoEditorControlsView: UIView {

    // MARK: Public Properties

    lazy var playButton: PTVideoEditorPlayPauseButton = makePlayButton()
    lazy var durationLabel: UILabel = makeDurationLabel()
    lazy var currentTimeLabel: UILabel = makeCurrentTimeLabel()
    lazy var fullscreenButton: UIButton = makeFullscreenButton()
    lazy var progressView: PTVideoEditorProgressView = makeProgressView()

    var playButtonAction: (() -> Void)?
    var fullscreenButtonAction: (() -> Void)?

    // MARK: Private Properties

    private let isFullscreen: Bool
    private var capabilities: PTVideoEditorVideoPlayerController.Capabilities!
    private let theme: PTVideoEditorVideoPlayerController.Theme

    init(capabilities: PTVideoEditorVideoPlayerController.Capabilities,
         theme: PTVideoEditorVideoPlayerController.Theme,
         isFullscreen: Bool) {
        self.capabilities = capabilities
        self.theme = theme
        self.isFullscreen = isFullscreen

        super.init(frame: .zero)

        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: UI

fileprivate extension PTVideoEditorControlsView {
    func setupUI() {
        setupView()
        setupConstraints()
    }

    func setupView() {
                        
        if capabilities.contains(.playPause) {
            addSubview(playButton)
        }

        if capabilities.contains(.fullscreen) {
            addSubview(fullscreenButton)
        }

        if capabilities.contains(.seek) {
            addSubviews([durationLabel,currentTimeLabel,progressView])
        }
        
        if capabilities.contains(.all) {
            addSubviews([playButton,fullscreenButton,durationLabel,currentTimeLabel,progressView])
        }
    }

    func setupConstraints() {
        if capabilities.contains(.playPause) {
            playButton.snp.makeConstraints { make in
                make.width.height.equalTo(88)
                make.centerX.centerY.equalToSuperview()
            }
        }

        if capabilities.contains(.fullscreen) {
            fullscreenButton.snp.makeConstraints { make in
                make.width.height.equalTo(44)
                make.top.equalToSuperview().inset(10)
                make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            }
        }

        if capabilities.contains(.seek) {
            progressView.snp.makeConstraints { make in
                make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight + 10)
                make.left.equalToSuperview().inset(26)
                make.height.equalTo(34)
            }

            currentTimeLabel.snp.makeConstraints { make in
                make.left.equalTo(progressView)
                make.bottom.equalTo(progressView.snp.top)
            }

            durationLabel.snp.makeConstraints { make in
                make.right.equalTo(progressView)
                make.bottom.equalTo(progressView.snp.top)
            }
        }

        if capabilities.contains(.fullscreen) && capabilities.contains(.seek) {
            progressView.snp.makeConstraints { make in
                make.right.equalTo(fullscreenButton.snp.left).offset(-10)
            }
        } else if capabilities.contains(.seek) {
            progressView.snp.makeConstraints { make in
                make.right.equalToSuperview().inset(26)
            }
        }
        
        if capabilities.contains(.all) {
            playButton.snp.makeConstraints { make in
                make.width.height.equalTo(88)
                make.centerX.centerY.equalToSuperview()
            }

            fullscreenButton.snp.makeConstraints { make in
                make.width.height.equalTo(44)
                make.top.equalToSuperview().inset(10)
                make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            }

            progressView.snp.makeConstraints { make in
                make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight + 10)
                make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                make.height.equalTo(34)
            }

            currentTimeLabel.snp.makeConstraints { make in
                make.left.equalTo(progressView)
                make.bottom.equalTo(progressView.snp.top)
            }

            durationLabel.snp.makeConstraints { make in
                make.right.equalTo(progressView)
                make.bottom.equalTo(progressView.snp.top)
            }
        }
    }

    func makePlayButton() -> PTVideoEditorPlayPauseButton {
        let button = PTVideoEditorPlayPauseButton()
        button.addActionHandlers { sender in
            self.playButtonTapped()
        }
        button.imageEdgeInsets = UIEdgeInsets(top: 15, left: 16, bottom: 15, right: 16)
        button.tintColor = theme.controlsTintColor
        return button
    }

    func makeFullscreenButton() -> UIButton {
        let button = UIButton()
        let name = isFullscreen ? "ExitFullscreen" : "EnterFullscreen"
        let image = UIImage.podBundleImage(name,bundleName:PTVideoEditorPodBundleName)
        button.addActionHandlers { sender in
            self.fullscreenButtonTapped()
        }
        button.setImage(image, for: .normal)
        button.tintColor = theme.controlsTintColor
        return button
    }

    func makeProgressView() -> PTVideoEditorProgressView {
        let view = PTVideoEditorProgressView(theme: theme)
        return view
    }

    func makeDurationLabel() -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13.0)
        label.text = "0:00"
        label.textColor = theme.controlsTintColor
        return label
    }

    func makeCurrentTimeLabel() -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13.0)
        label.text = "0:00"
        label.textColor = theme.controlsTintColor
        return label
    }
}

// MARK: Actions

fileprivate extension PTVideoEditorControlsView {
    @objc func playButtonTapped() {
        playButtonAction?()
    }

    @objc func fullscreenButtonTapped() {
        fullscreenButtonAction?()
    }
}


public extension UIStackView {
    func setBackgroundColor(_ color: UIColor) {
        let subView = UIView(frame: bounds)
        subView.backgroundColor = color
        subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(subView, at: 0)
    }
}
