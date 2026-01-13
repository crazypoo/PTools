//
//  PTVideoEditorHandleLayer.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

class PTVideoEditorHandleLayer: CALayer {
    enum Side {
        case left
        case right
    }

    private lazy var imageLayer: CALayer = makeImageLayer()
    private let side: Side

    init(side: Side) {
        self.side = side

        super.init()

        backgroundColor = UIColor.border.cgColor
    }

    override init(layer: Any) {
        side = .left
        
        super.init(layer: layer)
    }

    override func layoutSublayers() {
        super.layoutSublayers()

        addSublayer(imageLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeImageLayer() -> CALayer {
        let layer = CALayer()
        let image = side == .left ? PTVideoEditorConfig.share.trimLeftImage.cgImage : PTVideoEditorConfig.share.trimRightImage.cgImage
        layer.frame = CGRect(x: 0, y: 0, width: 6, height: 16)
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.position = CGPoint(x: bounds.midX, y: bounds.midY)

        let maskLayer = CALayer()
        maskLayer.frame = layer.bounds
        maskLayer.contents = image
        maskLayer.contentsGravity = .resizeAspect
        layer.mask = maskLayer
        layer.backgroundColor = UIColor.black.cgColor

        return layer
    }
}
