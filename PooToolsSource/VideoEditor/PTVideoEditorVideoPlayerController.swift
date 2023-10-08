//
//  PTVideoEditorVideoPlayerController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import AVFoundation
import Combine
import SnapKit

public final class PTVideoEditorVideoPlayerController: PTBaseViewController {

    // MARK: Public Properties

    @Published public var currentTime: CMTime = .zero

    public var videoGravity: AVLayerVideoGravity {
        get { playerView.playerLayer.videoGravity }
        set { playerView.playerLayer.videoGravity = newValue }
    }

    @Published public var isPlaying: Bool = false

    public lazy var itemDidPlayToEnd: AnyPublisher<Void, Never> = {
        store.itemDidPlayToEnd
    }()

    public var player: AVPlayer {
        store.player
    }

    // MARK: Private Properties

    private lazy var playerView: PTVideoEditorPlayerView = makePlayerView()
    private lazy var blurredView: UIView = makeBlurredBiew()
    private lazy var backgroundView: PTVideoEditorPlayerView = makeBackgroundView()
    private lazy var controlsViewController: PTVideoEditorControlsViewController = makeControlsViewController()

    private var cancellables = Set<AnyCancellable>()

    private let store: PTVideoEditorVideoPlayerStore
    private let viewFactory: PTVideoEditorVideoPlayerViewFactoryProtocol

    private let theme: Theme
    private let capabilities: Capabilities

    // MARK: Init

    public init(capabilities: Capabilities = .all, 
                theme: Theme = Theme()) {
        self.capabilities = capabilities
        self.theme = theme
        self.store = PTVideoEditorVideoPlayerStore()
        self.viewFactory = PTVideoEditorVideoPlayerViewFactory()

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
    }
}

// MARK: Public

public extension PTVideoEditorVideoPlayerController {
    func load(item: AVPlayerItem, 
              autoPlay: Bool = false) {
        store.load(item)

        if autoPlay {
            play()
        }
    }

    func play() {
        store.play()
    }

    func pause() {
        store.pause()
    }

    func seek(toFraction fraction: Double) {
        let time = store.startTime(forFraction: fraction)
        store.seek(to: time)
    }

    func enterFullscreen() {
        let originalFrame = playerView.superview?.convert(playerView.frame, to: nil)
        let controller = viewFactory.makeFullscreenVideoPlayerController(
            store: store,
            capabilities: .all,
            theme: theme,
            originalFrame: originalFrame
        )
        present(controller, animated: false)
    }
}

// MARK: Binding

fileprivate extension PTVideoEditorVideoPlayerController {
    func setupBindings() {
        store.$isPlaying
            .assign(to: \.isPlaying, weakly: self)
            .store(in: &cancellables)

        store.$playheadProgress
            .assign(to: \.currentTime, weakly: self)
            .store(in: &cancellables)
    }
}

// MARK: UI
fileprivate extension PTVideoEditorVideoPlayerController {
    func setupUI() {
        setupView()
        setupConstraints()
    }

    func setupView() {
        view.backgroundColor = .black

        switch theme.backgroundStyle {
        case .plain(let color):
            view.backgroundColor = color
        case .blurred:
            view.addSubview(backgroundView)
            view.addSubview(blurredView)
        }

        view.addSubview(playerView)

        add(controlsViewController)
    }

    func setupConstraints() {
        if case .blurred = theme.backgroundStyle {
            backgroundView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            blurredView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }

        playerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(CGFloat.statusBarHeight())
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight)
        }
        controlsViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func makePlayerView() -> PTVideoEditorPlayerView {
        let view = PTVideoEditorPlayerView()
        view.player = store.player
        return view
    }

    func makeBlurredBiew() -> UIVisualEffectView {
        let effect = UIBlurEffect(style: .regular)
        let visualEffectView = UIVisualEffectView(effect: effect)
        return visualEffectView
    }

    func makeBackgroundView() -> PTVideoEditorPlayerView {
        let view = PTVideoEditorPlayerView()
        view.playerLayer.videoGravity = .resizeAspectFill
        view.player = store.player
        return view
    }

    func makeControlsViewController() -> PTVideoEditorControlsViewController {
        let controller = viewFactory.makeControlsViewController(
            store: store,
            capabilities: capabilities,
            theme: theme,
            isFullscreen: false)
        controller.delegate = self
        return controller
    }
}

// MARK: Controls View Controller Delegate
extension PTVideoEditorVideoPlayerController: PTVideoEditorControlsViewControllerDelegate {
    func fullscreenButtonWasTapped() {
        enterFullscreen()
    }
}

// MARK: Inner Types
public extension PTVideoEditorVideoPlayerController {

    struct Capabilities: OptionSet {
        public var rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let fullscreen = Capabilities(rawValue: 1 << 0)
        public static let playPause = Capabilities(rawValue: 1 << 1)
        public static let seek = Capabilities(rawValue: 1 << 2)

        public static let none: Capabilities = []
        public static let all: Capabilities = [.fullscreen, .playPause, .seek]
    }

    struct Theme {
        public enum Style {
            case plain(UIColor)
            case blurred
        }

        public init() {}

        public var backgroundStyle: Style = .plain(.black)
        public var controlsTintColor: UIColor = .white
    }

}
