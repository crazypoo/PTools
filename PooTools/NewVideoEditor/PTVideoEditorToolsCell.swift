//
//  PTVideoEditorToolsCell.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 13/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

class PTVideoEditorToolsCell: PTBaseNormalCell {
    // MARK: Private Properties
    static let ID = "PTVideoEditorToolsCell"
    
    lazy var buttonView : PTLayoutButton = {
        let view = PTLayoutButton()
        view.layoutStyle = .upImageDownTitle
        view.midSpacing = 10
        view.imageSize = CGSizeMake(30, 30)
        view.normalTitleColor = PTDarkModeOption.colorLightDark(lightColor: .darkText, darkColor: .white)
        view.normalTitleFont = .appfont(size: 12)
        view.selectedTitleColor = PTVideoEditorConfig.share.themeColor
        view.selectedTitleFont = .appfont(size: 12)
        view.isUserInteractionEnabled = false
        view.isSelected = false
        return view
    }()

    private var viewModel: PTVideoEditorToolsModel!

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
extension PTVideoEditorToolsCell {
    func configure(with viewModel: PTVideoEditorToolsModel) {
        buttonView.normalTitle = viewModel.title
        buttonView.selectedTitle = viewModel.title
        buttonView.normalImage = Bundle.podBundleImage(bundleName:PTVideoEditorPodBundleName,imageName:viewModel.titleImageName).withRenderingMode(.alwaysOriginal).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .darkText, darkColor: .white))
        buttonView.selectedImage = Bundle.podBundleImage(bundleName:PTVideoEditorPodBundleName,imageName:viewModel.titleImageName).withRenderingMode(.alwaysOriginal).withTintColor(PTVideoEditorConfig.share.themeColor)
        self.viewModel = viewModel
    }
}
