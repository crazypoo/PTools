//
//  PTTagCell.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/6/15.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

class PTTagCell: PTBaseNormalCell {
    static let ID = "PTTagCell"
    
    var cellModel:PTTagLayoutModel! {
        didSet {
            tagLabel.text = cellModel.name
            tagLabel.textColor = cellModel.contentTextColor
            tagLabel.font = cellModel.contentFont
        }
    }
    
    lazy var tagLabel:UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.viewCorner(radius: 0,borderWidth: 1,borderColor: .random)
        contentView.addSubviews([tagLabel])
        tagLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    @MainActor required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
