//
//  PTVideoEditorTimeLineViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import AVFoundation
import Combine
import SnapKit

final class PTVideoEditorTimeLineViewController: PTBaseViewController {

    @Published var isSeeking: Bool = false

    @Published var seekerValue: Double = 0.0

    // MARK: Private Properties

    private lazy var scrollView: UIScrollView = makeScrollView()
    private lazy var videoTimelineView: PTVideoEditorVideoTimeLineView = makeVideoTimeline()
    private lazy var carretLayer: CALayer = makeCarretLayer()

    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    private let store: PTVideoEditorVideoEditorStore
    
    init(store: PTVideoEditorVideoEditorStore) {
        self.store = store

        super.init(nibName: nil, bundle: nil)

        setupUI()
        setupBindings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCarretLayerFrame()

        let horizontal = view.bounds.width / 2
        scrollView.contentInset = UIEdgeInsets(top: 0, left: horizontal, bottom: 0, right: horizontal)
    }
}

extension PTVideoEditorTimeLineViewController {
    func generateTimeline(for asset: AVAsset) {
        let rect = CGRect(x: 0, y: 0, width: view.bounds.width, height: 64.0)
        store.videoTimeline(for: asset, in: rect)
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] images in
                guard let self = self else { return }
                self.updateVideoTimeline(with: images, assetAspectRatio: self.store.assetAspectRatio)
            }.store(in: &cancellables)

        scrollView.contentSize = CGSize(width: view.bounds.width, height: 64.0)
    }
}

// MARK: Bindings

fileprivate extension PTVideoEditorTimeLineViewController {
    func setupBindings() {
        store.$playheadProgress
            .sink { [weak self] playheadProgress in
                guard let self = self else { return }
                if !self.isSeeking {
                    self.updateScrollViewContentOffset(fractionCompleted: self.store.fractionCompleted)
                }
            }
            .store(in: &cancellables)

        $seekerValue
            .assign(to: \.currentSeekingValue, weakly: store)
            .store(in: &cancellables)

        $isSeeking
            .assign(to: \.isSeeking, weakly: store)
            .store(in: &cancellables)
    }

    func updateVideoTimeline(with images: [CGImage], assetAspectRatio: CGFloat) {
        guard !images.isEmpty else { return }

        videoTimelineView.configure(with: images, assetAspectRatio: assetAspectRatio)

        updateScrollViewContentOffset(fractionCompleted: .zero)
    }

    func updateScrollViewContentOffset(fractionCompleted: Double) {
        let x = scrollView.contentSize.width * CGFloat(fractionCompleted) - (scrollView.contentSize.width / 2)
        let point = CGPoint(x: x, y: 0)
        scrollView.setContentOffset(point, animated: false)
    }
}

// MARK: UI

fileprivate extension PTVideoEditorTimeLineViewController {
    func setupUI() {
        setupView()
        setupConstraints()
    }

    func setupView() {
        self.view.backgroundColor = .clear
        view.addSubview(scrollView)
        scrollView.addSubview(videoTimelineView)
        view.layer.addSublayer(carretLayer)
    }

    func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        videoTimelineView.snp.makeConstraints { make in
            make.height.equalTo(64)
            make.width.equalTo(CGFloat.kSCREEN_WIDTH)
            make.centerY.centerX.equalTo(scrollView)
        }
    }

    func makeScrollView() -> UIScrollView {
        let view = UIScrollView()
        view.delegate = self
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        return view
    }

    func makeVideoTimeline() -> PTVideoEditorVideoTimeLineView {
        let view = PTVideoEditorVideoTimeLineView()
        return view
    }

    func makeCarretLayer() -> CALayer {
        let layer = CALayer()
        layer.backgroundColor = #colorLiteral(red: 0.1137254902, green: 0.1137254902, blue: 0.1215686275, alpha: 1).cgColor
        layer.cornerRadius = 1.0
        return layer
    }

    func updateCarretLayerFrame() {
        let width: CGFloat = 2.0
        let height: CGFloat = 160.0
        let x = view.bounds.midX - width / 2
        let y = (view.bounds.height - height) / 2
        carretLayer.frame = CGRect(x: x, y: y, width: width, height: height)
    }
}

// MARK: ScrollView Delegate

extension PTVideoEditorTimeLineViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isSeeking = true
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isSeeking = false
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            isSeeking = false
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        seekerValue = Double((scrollView.contentOffset.x + (scrollView.contentSize.width / 2)) / scrollView.contentSize.width)
    }
}
