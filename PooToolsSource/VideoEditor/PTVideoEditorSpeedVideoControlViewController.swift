//
//  PTVideoEditorSpeedVideoControlViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Combine
import SnapKit
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif

class PTVideoEditorSpeedVideoControlViewController: PTFloatingBaseViewController {

    // MARK: Public Properties

    @Published var speed: Double

    @Published var isUpdating: Bool = false

    // MARK: Private Properties

    private lazy var slider: PTVideoEditorSlider = makeSlider()

    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    init(speed: Double) {
        self.speed = speed
        
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
}

// MARK: Bindings

fileprivate extension PTVideoEditorSpeedVideoControlViewController {
    func setupBindings() {
        slider.$value
            .assign(to: \.speed, weakly: self)
            .store(in: &cancellables)
    }
}

// MARK: UI

fileprivate extension PTVideoEditorSpeedVideoControlViewController {
    func setupUI() {
        setupView()
        setupConstraints()
    }

    func setupView() {
        view.backgroundColor = .background
        
        view.addSubview(slider)
    }

    func setupConstraints() {
        let inset: CGFloat = 28.0

        slider.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(inset)
            make.height.equalTo(48)
            make.centerY.equalToSuperview()
        }
    }

    func makeSlider() -> PTVideoEditorSlider {
        let slider = PTVideoEditorSlider()
        slider.value = speed
        slider.range = .stepped(values: [0.25, 0.5, 0.75, 1.0, 2.0, 5.0, 10.0])
        slider.isContinuous = false

        return slider
    }
}
