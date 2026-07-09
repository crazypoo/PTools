//
//  PTEditToolsCell.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

public class PTEditImageToolModel:NSObject,@unchecked Sendable {
    public var normalImage:UIImage = UIImage()
    public var selectedImage:UIImage?
    public var currentType:PTImageEditorConfig.EditTool = .draw
    public var isSelected:Bool = false
}

//MARK: 编辑工具
class PTEditToolsCell: PTBaseNormalCell {
    static let ID = "PTEditToolsCell"
    
    var toolModel:PTEditImageToolModel! {
        didSet {
            imageView.setImage(toolModel.normalImage, state: .normal)
            imageView.setImage(toolModel.selectedImage, state: .selected)
            imageView.isSelected = toolModel.isSelected
        }
    }
    
    lazy var imageView : PTActionLayoutButton = {
        let view = PTActionLayoutButton()
        view.layoutStyle = .image
        view.imageSize = CGSize(width: 33, height: 33)
        view.imageContentMode = .scaleAspectFit
        view.isSelected = false
        view.isUserInteractionEnabled = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubviews([imageView])
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(5)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
