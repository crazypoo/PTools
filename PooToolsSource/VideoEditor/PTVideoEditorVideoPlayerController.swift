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
import Harbeth

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
    
    var c7Player:C7CollectorVideo!
    lazy var originImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .background
        return imageView
    }()
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
        store = PTVideoEditorVideoPlayerStore()
        viewFactory = PTVideoEditorVideoPlayerViewFactory()

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
        UIImage.pt.getVideoFirstImage(asset: item.asset) { image in
            self.originImageView.image = image
        }
        store.load(item)
        c7Player.setupPlayer(store.player)

        if autoPlay {
            play()
        }
    }

    func play() {
        c7Player.play()
//        store.play()
    }

    func pause() {
//        store.pause()
        c7Player.pause()
    }

    func seek(toFraction fraction: Double) {
        let time = store.startTime(forFraction: fraction)
        store.seek(to: time)
    }

    func enterFullscreen() {
        let originalFrame = originImageView.superview?.convert(originImageView.frame, to: nil)
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
        view.backgroundColor = .background

        switch theme.backgroundStyle {
        case .plain(let color):
            view.backgroundColor = color
        case .blurred:
            view.addSubview(backgroundView)
            view.addSubview(blurredView)
        }
        c7Player = C7CollectorVideo(player: playerView.player!, delegate: self)
        view.addSubview(originImageView)

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

        originImageView.snp.makeConstraints { make in
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
        view.backgroundColor = .background
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
        view.backgroundColor = .background
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

extension PTVideoEditorVideoPlayerController: C7CollectorImageDelegate {
    public func preview(_ collector: C7Collector, fliter image: C7Image) {
        self.originImageView.image = image
//        // Simulated dynamic effect.
//        if let filter = self.tuple?.callback?(self.nextTime) {
//            self.video.filters = [filter]
//        }
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

        public var backgroundStyle: Style = .plain(.background)
        public var controlsTintColor: UIColor = .foreground
        public var controlsTintColor_only_white: UIColor = .border
    }

}
