//
//  PTVideoEditorVideoControlViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Combine
import AVFoundation
import SnapKit
import SwifterSwift
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif

class PTVideoEditorVideoControlViewController: PTBaseViewController {

    // MARK: Public Properties

    @Published var speed: Double
    @Published var trimPositions: (Double, Double)
    @Published var croppingPreset: PTVideoEditorCroppingPreset?

    @Published var onDismiss = PassthroughSubject<Void, Never>()

    // MARK: Private Properties

    private lazy var borderTop: UIView = makeBorderTop()

    private lazy var titleStack:BKLayoutButton = {
        let view = BKLayoutButton()
        view.layoutStyle = .leftImageRightTitle
        view.setMidSpacing(10)
        view.setTitleColor(.black, for: .normal)
        view.titleLabel?.font = .appfont(size: 12)
        view.setImageSize(CGSizeMake(20, 20))
        view.isUserInteractionEnabled = false
        return view
    }()
    private lazy var dismissButton: UIButton = makeDismissButton()

    private lazy var speedVideoControlViewController: PTVideoEditorSpeedVideoControlViewController = makeSpeedVideoControlViewController()
    private lazy var trimVideoControlViewController: PTVideoEditorTrimVideoControlViewController = makeTrimVideoControlViewController()
    private lazy var audioVideoControlViewController: PTVideoEditorSpeedVideoControlViewController = makeSpeedVideoControlViewController()
    private lazy var cropVideoControlViewController: PTVideoEditorCropVideoControlViewController = makeCropVideoControlViewController()

    private var currentVideoControlViewController: UIViewController?

    private var cancellables = Set<AnyCancellable>()

    private let asset: AVAsset
    private let viewFactory: PTVideoEditorViewFactoryProtocol

    // MARK: Init

    init(asset: AVAsset,
         speed: Double,
         trimPositions: (Double, Double),
         viewFactory: PTVideoEditorViewFactoryProtocol) {
        self.asset = asset
        self.speed = speed
        self.trimPositions = trimPositions
        self.viewFactory = viewFactory

        super.init(nibName: nil, bundle: nil)

        setupUI()
        setupBindings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_hideBaseNavBar = true
#endif

    }
}

// MARK: Bindings

fileprivate extension PTVideoEditorVideoControlViewController {
    func setupBindings() {
        speedVideoControlViewController.$speed
            .dropFirst(1)
            .assign(to: \.speed, weakly: self)
            .store(in: &cancellables)

        trimVideoControlViewController.$trimPositions
            .dropFirst(1)
            .assign(to: \.trimPositions, weakly: self)
            .store(in: &cancellables)

        cropVideoControlViewController.didSelectCroppingPreset
            .assign(to: \.croppingPreset, weakly: self)
            .store(in: &cancellables)
    }
}

extension PTVideoEditorVideoControlViewController {
    func configure(with viewModel: PTVideoEditorVideoControlViewModel) {
        titleStack.setTitle(viewModel.title, for: .normal)
        titleStack.setImage(UIImage.podBundleImage(viewModel.titleImageName), for: .normal)

        currentVideoControlViewController?.remove()

        let videoControlViewController = videoControlViewController(for: viewModel.videoControl)

        add(videoControlViewController)

        videoControlViewController.view.snp.makeConstraints { make in
            make.top.equalTo(titleStack.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(dismissButton.snp.top)
        }
        currentVideoControlViewController = videoControlViewController
    }
}

// MARK: UI

fileprivate extension PTVideoEditorVideoControlViewController {
    func setupUI() {
        setupView()
        setupConstraints()
    }

    func setupView() {
        view.addSubviews([borderTop,titleStack,dismissButton])

        view.backgroundColor = .white
    }

    func setupConstraints() {
        borderTop.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(1)
        }

        titleStack.snp.makeConstraints { make in
            make.top.equalTo(borderTop.snp.bottom).offset(20)
            make.height.equalTo(20)
            make.centerX.equalToSuperview()
        }

        dismissButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight + 10)
            make.right.equalToSuperview().inset(30)
        }
    }

    func makeBorderTop() -> UIView {
        let view = UIView()
        view.backgroundColor = .border
        return view
    }

    func videoControlViewController(for videoControl: PTVideoEditorVideoControl) -> UIViewController {
        switch videoControl {
        case .crop:
            return cropVideoControlViewController
        case .speed:
            return speedVideoControlViewController
        case .trim:
            return trimVideoControlViewController
        }
    }

    func makeSpeedVideoControlViewController() -> PTVideoEditorSpeedVideoControlViewController {
        viewFactory.makeSpeedVideoControlViewController(speed: speed)
    }

    func makeTrimVideoControlViewController() -> PTVideoEditorTrimVideoControlViewController {
        viewFactory.makeTrimVideoControlViewController(asset: asset, trimPositions: trimPositions)
    }

    func makeCropVideoControlViewController() -> PTVideoEditorCropVideoControlViewController {
        viewFactory.makeCropVideoControlViewController()
    }

    func makeDismissButton() -> UIButton {
        let button = UIButton()
        let image = UIImage.podBundleImage("Check")
        button.setImage(image, for: .normal)
        button.tintColor = #colorLiteral(red: 0.1137254902, green: 0.1137254902, blue: 0.1215686275, alpha: 1)
        button.addActionHandlers { sender in
            self.cancel()
        }
        return button
    }
}

// MARK: Actions

fileprivate extension PTVideoEditorVideoControlViewController {
    func cancel() {
        onDismiss.send()
    }
}

