//
//  PTVideoEditorVideoTimeLineView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

class PTVideoEditorVideoTimeLineView: UIView {

    // MARK: Init

    init() {
        super.init(frame: .zero)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: Public

extension PTVideoEditorVideoTimeLineView {
    func configure(with frames: [CGImage],
                   assetAspectRatio: CGFloat) {
        subviews.forEach { $0.removeFromSuperview() }
        
        let width = bounds.height * assetAspectRatio

        frames.enumerated().forEach { index,value in
            let imageView = UIImageView()
            imageView.image = UIImage(cgImage: value, scale: 1.0, orientation: .up)
            addSubview(imageView)

            imageView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.width.equalTo(width)
                make.left.equalToSuperview().inset(CGFloat(index) * width)
            }
        }
    }
}

// MARK: UI

fileprivate extension PTVideoEditorVideoTimeLineView {
    func setupUI() {
        setupView()
        setupConstraints()
    }

    func setupView() {
        clipsToBounds = true
    }

    func setupConstraints() {

    }
}
