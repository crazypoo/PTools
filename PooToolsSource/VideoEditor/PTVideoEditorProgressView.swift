//
//  PTVideoEditorProgressView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

final class PTVideoEditorProgressView: UIControl {

    // MARK: Constants

    enum Constants {
        enum CircleLayer {
            static let width: CGFloat = 10.0
        }
    }

    // MARK: Public Properties

    override var bounds: CGRect {
        didSet {
            updateProgressCircleLayerFrame()
            updateCompletedLayerFrame()
            updateBackgroundLayerFrame()
        }
    }

    var progress: Double = 0.0 {
        didSet {
            updateCompletedLayerFrame()
            updateProgressCircleLayerFrame()
        }
    }

    // MARK: Private Properties

    private lazy var progressCircleLayer: CALayer = makeProgressCircleLayer()
    private lazy var completedLayer: CALayer = makeCompletedLayer()
    private lazy var backgroundLayer: CALayer = makeBackgroundLayer()

    private let theme: PTVideoEditorVideoPlayerController.Theme

    // MARK: Init

    init(theme: PTVideoEditorVideoPlayerController.Theme) {
        self.theme = theme

        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        setupUI()
    }
}


// MARK: UI

fileprivate extension PTVideoEditorProgressView {
    func setupUI() {
        setupView()
    }

    func setupView() {
        layer.addSublayer(backgroundLayer)
        layer.addSublayer(completedLayer)
        layer.addSublayer(progressCircleLayer)
    }

    func updateCompletedLayerFrame() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let height = Constants.CircleLayer.width / 4
        completedLayer.frame = CGRect(x: 0,y: (bounds.height - height) / 2,width: bounds.width * CGFloat(progress),height: height)

        CATransaction.commit()
    }

    func updateBackgroundLayerFrame() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let height = Constants.CircleLayer.width / 4
        backgroundLayer.frame = CGRect(x: 0,y: (bounds.height - height) / 2,width: bounds.width - 2,height: height)

        CATransaction.commit()
    }

    func updateProgressCircleLayerFrame() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let newOrigin = CGPoint(x: bounds.width * CGFloat(progress) - progressCircleLayer.frame.width / 2,y: (bounds.height - Constants.CircleLayer.width) / 2)

        progressCircleLayer.frame = CGRect(origin: newOrigin, size: progressCircleLayer.frame.size)

        CATransaction.commit()
    }

    func makeProgressCircleLayer() -> CALayer {
        let layer = CALayer()
        let side = Constants.CircleLayer.width
        layer.frame = CGRect(x: 0 - side / 2,y: (bounds.height - side) / 2,width: side,height: side)
        layer.backgroundColor = theme.controlsTintColor_only_white.cgColor
        layer.cornerRadius = side / 2
        return layer
    }

    func makeCompletedLayer() -> CALayer {
        let layer = CALayer()
        let height = Constants.CircleLayer.width / 2
        layer.frame = CGRect(x: 0,y: (bounds.height - height) / 2,width: 0,height: height)
        layer.backgroundColor = theme.controlsTintColor_only_white.cgColor
        layer.cornerRadius = height / 2
        return layer
    }

    func makeBackgroundLayer() -> CALayer {
        let layer = CALayer()
        let height = Constants.CircleLayer.width / 2
        layer.frame = CGRect(x: 0,y: (bounds.height - height) / 2,width: bounds.width - 2,height: height)
        layer.backgroundColor = theme.controlsTintColor_only_white.withAlphaComponent(0.3).cgColor
        layer.cornerRadius = height / 2
        return layer
    }
}
