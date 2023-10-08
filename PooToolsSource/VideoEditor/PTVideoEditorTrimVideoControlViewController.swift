//
//  PTVideoEditorTrimVideoControlViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Combine
import AVFoundation
import SnapKit
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif

final class PTVideoEditorTrimVideoControlViewController: PTBaseViewController {
    // MARK: Public Properties

    @Published var trimPositions: (Double, Double)

    override var tabBarItem: UITabBarItem! {
        get {
            UITabBarItem(
                title: "Trim",
                image: UIImage.podBundleImage("Trim"),
                selectedImage: UIImage.podBundleImage("Trim")
            )
        }
        set {}
    }

    // MARK: Private Properties

    private lazy var trimmingControlView: PTVideoEditorTrimmingControlView = makeTrimmingControlView()

    private var cancellables = Set<AnyCancellable>()

    private let asset: AVAsset
    private let generator: PTVideoEditorVideoTimeLineGeneratorProtocol

    // MARK: Init

    init(asset: AVAsset,
         trimPositions: (Double, Double),
         generator: PTVideoEditorVideoTimeLineGeneratorProtocol = PTVideoEditorVideoTimeLineGenerator()) {
        self.asset = asset
        self.trimPositions = trimPositions
        self.generator = generator

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_hideBaseNavBar = true
#endif
        setupUI()
        setupBindings()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let track = asset.tracks(withMediaType: AVMediaType.video).first
        let assetSize = track!.naturalSize.applying(track!.preferredTransform)

        let ratio = abs(assetSize.width) / abs(assetSize.height)

        let bounds = trimmingControlView.bounds
        let frameWidth = bounds.height * ratio
        let count = Int(bounds.width / frameWidth) + 1

        generator.videoTimeline(for: asset, in: trimmingControlView.bounds, numberOfFrames: count)
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] images in
                guard let self = self else { return }
                self.updateVideoTimeline(with: images, assetAspectRatio: ratio)
            }
            .store(in: &cancellables)
    }
}

// MARK: Bindings

fileprivate extension PTVideoEditorTrimVideoControlViewController {
    func setupBindings() {
        trimmingControlView.$trimPositions
            .dropFirst(1)
            .assign(to: \.trimPositions, weakly: self)
            .store(in: &cancellables)
    }

    func updateVideoTimeline(with images: [CGImage], assetAspectRatio: CGFloat) {
        guard !trimmingControlView.isConfigured else { return }
        guard !images.isEmpty else { return }

        trimmingControlView.configure(with: images, assetAspectRatio: assetAspectRatio)
    }
}

// MARK: UI

fileprivate extension PTVideoEditorTrimVideoControlViewController {
    func setupUI() {
        setupView()
        setupConstraints()
    }

    func setupView() {
        view.backgroundColor = .white

        view.addSubview(trimmingControlView)
    }

    func setupConstraints() {
        trimmingControlView.snp.makeConstraints { make in
            make.height.equalTo(60)
            make.left.right.equalToSuperview().inset(28)
            make.centerY.equalToSuperview()
        }
    }

    func makeTrimmingControlView() -> PTVideoEditorTrimmingControlView {
        PTVideoEditorTrimmingControlView(trimPositions: trimPositions)
    }
}

