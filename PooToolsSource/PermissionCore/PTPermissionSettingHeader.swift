//
//  PTPermissionSettingHeader.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

class PTPermissionSettingHeader: PTBaseCollectionReusableView {
    static let ID = "PTPermissionSettingHeader"
    
    static let headerHeight:CGFloat = 34
    
    var headerModel:PTPermissionModel! {
        didSet {
            titleView.text = PTPermissionText.permission_name(for: headerModel.type)
        }
    }
    
    lazy var titleView : UILabel = {
        let view = UILabel()
        view.textAlignment = .left
        view.font = PTPermissionStatic.share.permissionSettingFont
        view.textColor = .lightGray
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubviews([titleView])
        titleView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(PTPermissionSettingHeader.headerHeight)
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
