//
//  PTAdjustToolCell.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

// MARK: Adjust cell
class PTAdjustToolCell: PTBaseNormalCell {
    static let ID = "PTAdjustToolCell"

    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .appfont(size: 12)
        label.textColor = .white
        label.textAlignment = .center
        label.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        label.layer.shadowOffset = .zero
        label.layer.shadowOpacity = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()
    
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.isUserInteractionEnabled = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubviews([imageView,nameLabel])
        imageView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(7.5)
            make.height.equalTo(imageView.snp.width)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.bottom.left.right.equalToSuperview().inset(7.5)
            make.top.equalTo(self.imageView.snp.bottom)
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
