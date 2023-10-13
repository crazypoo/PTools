//
//  PTControlsViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Combine
import SnapKit

protocol PTVideoEditorControlsViewControllerDelegate: AnyObject {
    func fullscreenButtonWasTapped()
}

final class PTVideoEditorControlsViewController: PTBaseViewController {

    // MARK: Public Properties

    weak var delegate: PTVideoEditorControlsViewControllerDelegate?

    // MARK: Private Properties

    private var timer = Timer()

    private lazy var controlsView: PTVideoEditorControlsView = makeControlsView()

    private var cancellables = Set<AnyCancellable>()

    private let store: PTVideoEditorVideoPlayerStore
    private let isFullscreen: Bool
    private var capabilities: PTVideoEditorVideoPlayerController.Capabilities!
    private let theme: PTVideoEditorVideoPlayerController.Theme

    // MARK: Init

    init(store: PTVideoEditorVideoPlayerStore,
         capabilities: PTVideoEditorVideoPlayerController.Capabilities,
         theme: PTVideoEditorVideoPlayerController.Theme,
         isFullscreen: Bool) {
        self.capabilities = capabilities
        self.isFullscreen = isFullscreen
        self.theme = theme
        self.store = store

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        setupUI()
        setupBindings()
        setupGestureRecognizers()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        scheduleFadeOutTimer()
    }
}

// MARK: Timer

fileprivate extension PTVideoEditorControlsViewController {
    func scheduleFadeOutTimer() {
        timer = Timer.scheduledTimer(timeInterval: 4.0, repeats: false, block: { _ in
            self.controlsView.fadeOut(0.1)
        })
    }

    func rescheduleFadeOutTimer() {
        timer.invalidate()
        scheduleFadeOutTimer()
    }
}

// MARK: Bindings

fileprivate extension PTVideoEditorControlsViewController {
    func setupBindings() {
        store.$playheadProgress
            .filter { _ in self.store.isPlaying }
            .sink { [weak self] currentTime in
                guard let self = self else { return }

                self.controlsView.progressView.progress = self.store.progress
                self.controlsView.durationLabel.text = self.store.formattedDuration
                self.controlsView.currentTimeLabel.text = self.store.formattedCurrentTime
            }
            .store(in: &cancellables)

        store.$isPlaying
            .map { !$0 }
            .assign(to: \.isPaused, weakly: controlsView.playButton)
            .store(in: &cancellables)
    }
}

// MARK: Gestures

fileprivate extension PTVideoEditorControlsViewController {
    func setupGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer { sender in
            if self.controlsView.isHidden {
                self.controlsView.fadeIn(0.1)
                self.scheduleFadeOutTimer()
            } else {
                self.timer.invalidate()
                self.controlsView.fadeOut(0.1)
            }
        }
        tapGestureRecognizer.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGestureRecognizer)

        let doubleTapGestureRecognizer = UITapGestureRecognizer { sender in
            let recognizer = sender as! UITapGestureRecognizer
            self.controlsView.fadeOut(0.1)
            /// - TODO: Implement Seek on double tap
            _ = recognizer.location(in: self.view)
        }
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGestureRecognizer)

        tapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
    }
}

// MARK: UI

fileprivate extension PTVideoEditorControlsViewController {
    func setupUI() {
        setupView()
        setupConstraints()
    }

    func setupView() {
        view.addSubview(controlsView)
    }

    func setupConstraints() {
        controlsView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(CGFloat.statusBarHeight())
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight)
        }
    }

    func makeControlsView() -> PTVideoEditorControlsView {
        let view = PTVideoEditorControlsView(
            capabilities: capabilities,
            theme: theme,
            isFullscreen: isFullscreen
        )
        view.fullscreenButtonAction = { [unowned self] in
            fullscreenButtonTapped()
        }
        view.playButtonAction = { [unowned self] in
            playButtonTapped()
        }

        return view
    }
}

// MARK: Actions

fileprivate extension PTVideoEditorControlsViewController {
    func fullscreenButtonTapped() {
        delegate?.fullscreenButtonWasTapped()
    }

    func playButtonTapped() {
        rescheduleFadeOutTimer()

        if store.isPlaying {
            store.pause()
        } else {
            store.play()
        }
    }
}
