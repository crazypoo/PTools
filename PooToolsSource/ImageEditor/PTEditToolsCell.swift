//
//  PTEditToolsCell.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

//MARK: 编辑工具
class PTEditToolsCell: PTBaseNormalCell {
    static let ID = "PTEditToolsCell"
    
    var toolModel:PTFusionCellModel! {
        didSet {
            imageView.loadImage(contentData: toolModel.contentIcon as Any,controlState: .normal)
            imageView.loadImage(contentData: toolModel.disclosureIndicatorImage as Any,controlState: .selected)
        }
    }
    
    lazy var imageView : UIButton = {
        let view = UIButton(type: .custom)
        view.imageView?.contentMode = .scaleAspectFit
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
