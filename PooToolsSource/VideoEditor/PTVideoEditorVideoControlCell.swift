//
//  PTVideoEditorVideoControlCell.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

final class PTVideoEditorVideoControlCell: PTBaseNormalCell {
    // MARK: Private Properties
    
    private lazy var buttonView : BKLayoutButton = {
        let view = BKLayoutButton()
        view.layoutStyle = .upImageDownTitle
        view.setMidSpacing(10)
        view.setTitleColor(.black, for: .normal)
        view.titleLabel?.font = .appfont(size: 12)
        view.setImageSize(CGSizeMake(30, 30))
        view.isUserInteractionEnabled = false
        return view
    }()

    private var viewModel: PTVideoEditorVideoControlCellViewModel!

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubviews([buttonView])
        buttonView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Bindings

extension PTVideoEditorVideoControlCell {
    func configure(with viewModel: PTVideoEditorVideoControlCellViewModel) {
        buttonView.setTitle(viewModel.name, for: .normal)
        buttonView.setImage(UIImage.podBundleImage(viewModel.imageName), for: .normal)

        self.viewModel = viewModel
    }
}
