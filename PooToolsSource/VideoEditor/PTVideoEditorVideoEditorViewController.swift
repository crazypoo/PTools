//
//  PTVideoEditorVideoEditorViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Combine
import AVFoundation
import SnapKit

public final class PTVideoEditorVideoEditorViewController: PTBaseViewController {

    // MARK: Published Properties

    public var onEditCompleted = PassthroughSubject<(AVPlayerItem, PTVideoEdit), Never>()

    // MARK: Private Properties

    private lazy var saveButtonItem: UIBarButtonItem = makeSaveButtonItem()
    private lazy var dismissButtonItem: UIBarButtonItem = makeDismissButtonItem()

    private lazy var videoPlayerController: PTVideoEditorVideoPlayerController = makeVideoPlayerController()
    private lazy var playButton: PTVideoEditorPlayPauseButton = makePlayButton()

    private lazy var timeStack: UIStackView = makeTimeStack()
    private lazy var currentTimeLabel: UILabel = makeCurrentTimeLabel()
    private lazy var durationLabel: UILabel = makeDurationLabel()

    private lazy var fullscreenButton: UIButton = makeFullscreenButton()
    private lazy var controlsStack: UIStackView = makeControlsStack()
    private lazy var videoTimelineViewController: PTVideoEditorTimeLineViewController = makeVideoTimelineViewController()
    private lazy var videoControlListController: PTVideoEditorVideoControlListController = makeVideoControlListControllers()
    private lazy var videoControlViewController: PTVideoEditorVideoControlViewController = makeVideoControlViewController()

    private var videoControlHeightConstraint: NSLayoutConstraint!

    private var cancellables = Set<AnyCancellable>()
    private var durationUpdateCancellable: Cancellable?

    private let store: PTVideoEditorVideoEditorStore
    private let viewFactory: PTVideoEditorViewFactoryProtocol

    // MARK: Init

    public init(asset: AVAsset, 
                videoEdit: PTVideoEdit? = nil) {
        self.store = PTVideoEditorVideoEditorStore(asset: asset, videoEdit: videoEdit)
        self.viewFactory = PTVideoEditorVideoViewFactory()

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Life Cycle

    public override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupBindings()

        #if targetEnvironment(simulator)
        print("Warning: Cropping only works on real device and has been disabled on simulator")
        #endif
    }
}

// MARK: Bindings

fileprivate extension PTVideoEditorVideoEditorViewController {
    func subscribeToDurationUpdate(for item: AVPlayerItem) {
        durationUpdateCancellable?.cancel()
        durationUpdateCancellable = item
            .publisher(for: \.duration)
            .sink { [weak self] playheadProgress in
                guard let self = self else { return }
                self.updateDurationLabel()
            }
    }

    func setupBindings() {
        store.$playheadProgress
            .sink { [weak self] playheadProgress in
                guard let self = self else { return }
                self.updateCurrentTimeLabel()
            }
            .store(in: &cancellables)
        
        store.$editedPlayerItem
            .sink { [weak self] item in
                guard let self = self else { return }
                self.videoPlayerController.load(item: item, autoPlay: false)
                self.videoTimelineViewController.generateTimeline(for: item.asset)
                self.subscribeToDurationUpdate(for: item)
            }
            .store(in: &cancellables)

        videoPlayerController.$currentTime
            .assign(to: \.playheadProgress, weakly: store)
            .store(in: &cancellables)

        videoPlayerController.$isPlaying
            .sink { [weak self] isPlaying in
                guard let self = self else { return }
                self.playButton.isPaused = !isPlaying
            }
            .store(in: &cancellables)

        store.$isSeeking
            .filter { $0 }
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.videoPlayerController.pause()
            }.store(in: &cancellables)

        store.$currentSeekingValue
            .filter { [weak self] _ in
                guard let self = self else { return false }
                return self.store.isSeeking
            }
            .sink { [weak self] seekingValue in
                guard let self = self else { return }
                self.videoPlayerController.seek(toFraction: seekingValue)
            }
            .store(in: &cancellables)

        videoControlListController.didSelectVideoControl
            .sink { [weak self] videoControl in
                guard let self = self else { return }
                self.presentVideoControlController(for: videoControl)
            }
            .store(in: &cancellables)

        videoControlViewController.$speed
            .dropFirst(1)
            .assign(to: \.speed, weakly: store)
            .store(in: &cancellables)

        videoControlViewController.$trimPositions
            .dropFirst(1)
            .assign(to: \.trimPositions, weakly: store)
            .store(in: &cancellables)

        videoControlViewController.$croppingPreset
            .dropFirst(1)
            .assign(to: \.croppingPreset, weakly: store)
            .store(in: &cancellables)

        videoControlViewController.onDismiss
            .sink { [unowned self] _ in
                self.animateVideoControlViewControllerOut()
            }
            .store(in: &cancellables)
    }
}

// MARK: UI

fileprivate extension PTVideoEditorVideoEditorViewController {
    func setupUI() {
        setupNavigationItems()
        setupView()
        setupConstraints()
    }

    func setupNavigationItems() {
        let lNegativeSeperator = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        lNegativeSeperator.width = 10

        let rNegativeSeperator = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        rNegativeSeperator.width = 10

        navigationItem.rightBarButtonItems = [rNegativeSeperator, saveButtonItem]
        navigationItem.leftBarButtonItems = [lNegativeSeperator, dismissButtonItem]
    }

    func setupView() {
        view.backgroundColor = .background

        add(videoPlayerController)
        view.addSubview(controlsStack)
        add(videoTimelineViewController)
        add(videoControlListController)
    }

    func setupConstraints() {
        videoPlayerController.view.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(controlsStack.snp.top)
        }

        playButton.snp.makeConstraints { make in
            make.width.height.equalTo(44)
        }
        
        fullscreenButton.snp.makeConstraints { make in
            make.width.height.equalTo(44)
        }

        controlsStack.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(videoTimelineViewController.view.snp.top)
        }

        videoTimelineViewController.view.snp.makeConstraints { make in
            make.height.equalTo(220)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(60 + CGFloat.kTabbarSaveAreaHeight)
        }

        videoControlListController.view.snp.makeConstraints { make in
            make.height.equalTo(60)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight)
        }
    }

    func updateDurationLabel() {
        var durationInSeconds = videoPlayerController.player.currentItem?.duration.seconds ?? 0.0
        durationInSeconds = durationInSeconds.isNaN ? 0.0 : durationInSeconds
        let formattedDuration = durationInSeconds >= 3600 ?
            DateComponentsFormatter.longDurationFormatter.string(from: durationInSeconds) ?? "" :
            DateComponentsFormatter.shortDurationFormatter.string(from: durationInSeconds) ?? ""

        durationLabel.text = formattedDuration
    }

    func updateCurrentTimeLabel() {
        let currentTimeInSeconds = videoPlayerController.currentTime.seconds
        let formattedCurrentTime = currentTimeInSeconds >= 3600 ?
            DateComponentsFormatter.longDurationFormatter.string(from: currentTimeInSeconds) ?? "" :
            DateComponentsFormatter.shortDurationFormatter.string(from: currentTimeInSeconds) ?? ""

        currentTimeLabel.text = formattedCurrentTime
    }

    func makeSaveButtonItem() -> UIBarButtonItem {
        let image = UIImage.podBundleImage("Check")
        let buttonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(save))
        buttonItem.tintColor = #colorLiteral(red: 0.1137254902, green: 0.1137254902, blue: 0.1215686275, alpha: 1)
        return buttonItem
    }

    func makeDismissButtonItem() -> UIBarButtonItem {
        let imageName = isModal ? "Close" : "Back"
        let image = UIImage.podBundleImage(imageName)
        let buttonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(cancel))
        buttonItem.tintColor = #colorLiteral(red: 0.1137254902, green: 0.1137254902, blue: 0.1215686275, alpha: 1)
        return buttonItem
    }

    func makeVideoPlayerController() -> PTVideoEditorVideoPlayerController {
        let controller = viewFactory.makeVideoPlayerController()
        return controller
    }

    func makePlayButton() -> PTVideoEditorPlayPauseButton {
        let button = PTVideoEditorPlayPauseButton()
        button.addActionHandlers { sender in
            self.playButtonTapped()
        }
        button.tintColor = #colorLiteral(red: 0.1137254902, green: 0.1137254902, blue: 0.1215686275, alpha: 1)
        button.imageEdgeInsets = .init(top: 13, left: 15, bottom: 13, right: 15)
        return button
    }

    func makeTimeStack() -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [
            currentTimeLabel,
            makeSeparatorLabel(),
            durationLabel
        ])

        return stack
    }

    func makeSeparatorLabel() -> UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.text = " | "
        label.font = .systemFont(ofSize: 13.0)
        label.textColor = .foreground
        return label
    }

    func makeDurationLabel() -> UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.text = "0:00"
        label.font = .systemFont(ofSize: 13.0)
        label.textColor = .foreground
        return label
    }

    func makeCurrentTimeLabel() -> UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.text = "0:00"
        label.font = .systemFont(ofSize: 13.0)
        label.textColor = .foreground
        return label
    }

    func makeFullscreenButton() -> UIButton {
        let button = UIButton()
        let image = UIImage.podBundleImage("EnterFullscreen")
        button.addActionHandlers { sender in
            self.fullscreenButtonTapped()
        }
        button.setImage(image, for: .normal)
        button.tintColor = #colorLiteral(red: 0.1137254902, green: 0.1137254902, blue: 0.1215686275, alpha: 1)
        button.imageEdgeInsets = .init(top: 14, left: 13, bottom: 14, right: 13)
        return button
    }

    func makeControlsStack() -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [
            playButton,
            timeStack,
            fullscreenButton
        ])

        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30)

        stack.axis = .horizontal
        stack.distribution = .equalSpacing

        return stack
    }

    func makeVideoTimelineViewController() -> PTVideoEditorTimeLineViewController {
        viewFactory.makeVideoTimelineViewController(store: store)
    }

    func makeVideoControlListControllers() -> PTVideoEditorVideoControlListController {
        viewFactory.makeVideoControlListController(store: store)
    }

    func makeVideoControlViewController() -> PTVideoEditorVideoControlViewController {
        viewFactory.makeVideoControlViewController(asset: store.originalAsset, speed: store.speed, trimPositions: store.trimPositions)
    }

    func presentVideoControlController(for videoControl: PTVideoEditorVideoControl) {
        if videoControlViewController.view.superview == nil {
            
            var height: CGFloat = 0
            switch videoControl {
            case .crop:
                height = 250.0
            default:
                height = 210.0
            }
            let offset = -(height + view.safeAreaInsets.bottom)

            add(videoControlViewController)

            videoControlViewController.view.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(height)
                make.bottom.equalToSuperview().inset(offset)
            }
            self.view.layoutIfNeeded()
        }

        let viewModel = PTVideoEditorVideoControlViewModel(videoControl: videoControl)
        videoControlViewController.configure(with: viewModel)

        animateVideoControlViewControllerIn()
    }

    func animateVideoControlViewControllerIn() {
        let y = -(videoControlViewController.view.bounds.height + view.safeAreaInsets.bottom)
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.videoControlViewController.view.transform = CGAffineTransform(translationX: 0, y: y)
        })
    }

    func animateVideoControlViewControllerOut() {
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.videoControlViewController.view.transform = .identity
        })
    }
}

// MARK: Actions

fileprivate extension PTVideoEditorVideoEditorViewController {
    @objc func fullscreenButtonTapped() {
        videoPlayerController.enterFullscreen()
    }

    @objc func playButtonTapped() {
        if videoPlayerController.isPlaying {
            videoPlayerController.pause()
        } else {
            videoPlayerController.play()
        }
    }

    @objc func save() {
        let item = AVPlayerItem(asset: store.editedPlayerItem.asset)

        #if !targetEnvironment(simulator)
        item.videoComposition = store.editedPlayerItem.videoComposition
        #endif

        onEditCompleted.send((item, store.videoEdit))
        dismiss(animated: true)
    }

    @objc func cancel() {
        UIAlertController.base_alertVC(title: "是否确定要离开",msg: "离开后将不会保存",okBtns: ["确定"],cancelBtn: "取消") {
        } moreBtn: { index, title in
            self.returnFrontVC()
        }
    }
}
