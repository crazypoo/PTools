//
//  PTTestHeader.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 15/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

class PTTestHeader: PTBaseCollectionReusableView {
    static let ID = "PTTestHeader"
    
    lazy var headerTitle:UILabel = {
        let view = UILabel()
        view.textAlignment = .left
        view.font = .appfont(size: 18,bold: true)
        view.textColor = .black
        return view
    }()
    
    var sectionModel:PTSection? {
        didSet {
            self.headerTitle.text = sectionModel?.headerTitle
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(headerTitle)
        headerTitle.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.bottom.equalToSuperview().inset(5)
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PTTestFooter: PTBaseCollectionReusableView {
    static let ID = "PTTestFooter"
    
    lazy var headerTitle:UILabel = {
        let view = UILabel()
        view.textAlignment = .left
        view.font = .appfont(size: 18,bold: true)
        view.textColor = .black
        view.text = "----------------------------------------"
        return view
    }()
    
    var sectionModel:PTSection? {
        didSet {
            self.headerTitle.text = sectionModel?.headerTitle
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(headerTitle)
        headerTitle.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.bottom.equalToSuperview().inset(5)
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
