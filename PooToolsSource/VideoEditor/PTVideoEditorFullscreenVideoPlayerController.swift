//
//  PTVideoEditorFullscreenVideoPlayerController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import AVFoundation
import Combine
import SnapKit

final class PTVideoEditorFullscreenVideoPlayerController: PTBaseViewController {

    // MARK: Private Properties

    private let animationDuration = 0.3

    private let originalFrame: CGRect?

    private lazy var scrollView: UIScrollView = makeScrollView()
    private lazy var playerView: PTVideoEditorPlayerView = makePlayView()
    private lazy var closeButton: UIButton = makeCloseButton()
    private lazy var controlsViewController: PTVideoEditorControlsViewController = makeControlsViewController()

    private var cancellables = Set<AnyCancellable>()

    private weak var store: PTVideoEditorVideoPlayerStore!
    private let viewFactory: PTVideoEditorVideoPlayerViewFactoryProtocol
    private var capabilities: PTVideoEditorVideoPlayerController.Capabilities!
    private let theme: PTVideoEditorVideoPlayerController.Theme

    // MARK: Init

    init(store: PTVideoEditorVideoPlayerStore,
         viewFactory: PTVideoEditorVideoPlayerViewFactoryProtocol,
         capabilities: PTVideoEditorVideoPlayerController.Capabilities,
         theme: PTVideoEditorVideoPlayerController.Theme,
         originalFrame: CGRect?) {
        self.store = store
        self.viewFactory = viewFactory
        self.originalFrame = originalFrame
        self.theme = theme
        self.capabilities = capabilities

        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        animatePlayerLayerIn()
        animateBackgroundColorIn()
    }

    // MARK: Orientation

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate { context in
            self.playerView.frame = self.view.bounds
        }
    }
}

// MARK: Bindings

fileprivate extension PTVideoEditorFullscreenVideoPlayerController {
//    func setupBindings() {
//        store.state.player.itemDidPlayToEnd
//            .sink { [weak self] in
//                guard let self = self else { return }
//                self.itemDidPlayToEnd()
//            }
//            .store(in: &cancellables)
//    }
//
//    func itemDidPlayToEnd() {
//        store.send(event: .itemDidPlayToEnd)
//    }
}

// MARK: UI

fileprivate extension PTVideoEditorFullscreenVideoPlayerController {
    func setupUI() {
        setupView()
        setupConstraints()
    }

    func setupView() {
        view.backgroundColor = .clear

        view.addSubview(playerView)

        add(controlsViewController)

        if let originalFrame = originalFrame {
            playerView.frame = originalFrame
        }

        view.addSubview(closeButton)
    }

    func setupConstraints() {
        closeButton.snp.makeConstraints { make in
            make.width.height.equalTo(48)
            make.top.equalToSuperview().inset(CGFloat.statusBarHeight() + 4)
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }

        controlsViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func animatePlayerLayerIn() {
        UIView.animate(withDuration: animationDuration) {
            self.playerView.frame = self.view.bounds
        }
    }

    func animatePlayerLayerOut() {
        UIView.animate(withDuration: animationDuration) {
            if let originalFrame = self.originalFrame {
                self.playerView.frame = originalFrame
            }
        }
    }

    func animateBackgroundColorIn() {
        UIView.animate(withDuration: animationDuration) {
            self.view.backgroundColor = .black
        }
    }

    func animateBackgroundColorOut() {
        UIView.animate(withDuration: animationDuration) {
            self.view.backgroundColor = .clear
        }
    }

    func makeScrollView() -> UIScrollView {
        let view = UIScrollView()
        return view
    }

    func makePlayView() -> PTVideoEditorPlayerView {
        let view = PTVideoEditorPlayerView()
        view.player = store.player
        return view
    }

    func makeCloseButton() -> UIButton {
        let button = UIButton()
        let image = UIImage.podBundleImage("Close_white")
        button.setImage(image, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 12.0, left: 12.0, bottom: 12.0, right: 12.0)
        button.addActionHandlers { sender in
            self.close()
        }
        return button
    }

    func makeControlsViewController() -> PTVideoEditorControlsViewController {
        let controller = viewFactory.makeControlsViewController(store: store, capabilities: capabilities, theme: theme, isFullscreen: true)
        controller.delegate = self
        return controller
    }
}

// MARK: Actions

fileprivate extension PTVideoEditorFullscreenVideoPlayerController {
    func close() {
        animatePlayerLayerOut()

        PTGCDManager.gcdAfter(time: animationDuration) {
            self.dismiss(animated: false)
        }
    }
}

// MARK: Controls View Controller Delegate

extension PTVideoEditorFullscreenVideoPlayerController: PTVideoEditorControlsViewControllerDelegate {
    func fullscreenButtonWasTapped() {
        close()
    }
}

