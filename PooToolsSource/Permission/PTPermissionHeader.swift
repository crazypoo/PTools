//
//  GPPermissionHeader.swift
//  MinaTicket
//
//  Created by jax on 2022/9/6.
//  Copyright © 2022 Hola. All rights reserved.
//

import UIKit
import SnapKit

class PTPermissionHeader: PTBaseCollectionReusableView {
    static let ID = "GPPermissionHeader"
    static let headerTitle = "\(kAppName!)所需权限清单"
    static let headerInfo = "以下是App完全正常工作所需的授权清单"

    open class func cellHeight()->CGFloat
    {
        let titleHeight = UIView.sizeFor(string: PTPermissionHeader.headerTitle, font: PTAppBaseConfig.share.permissionTitleFont, height: CGFloat(MAXFLOAT), width: CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace).height + CGFloat.ScaleW(w: 5)
        let infoHeight = UIView.sizeFor(string: PTPermissionHeader.headerInfo, font: PTAppBaseConfig.share.permissionSubtitleFont, height: CGFloat(MAXFLOAT), width: CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace).height + CGFloat.ScaleW(w: 5)
        return titleHeight + infoHeight + CGFloat.ScaleW(w: 5) * 3
    }
    
    fileprivate lazy var titleLabel = self.pt_createLabel(text: PTPermissionHeader.headerTitle, font: PTAppBaseConfig.share.permissionTitleFont, bgColor: .clear, textColor: PTAppBaseConfig.share.permissionTitleColor, textAlignment: .left)
    fileprivate lazy var infoLabel = self.pt_createLabel(text: PTPermissionHeader.headerInfo, font: PTAppBaseConfig.share.permissionSubtitleFont, bgColor: .clear, textColor: PTAppBaseConfig.share.permissionSubtitleColor, textAlignment: .left)

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubviews([self.titleLabel,self.infoLabel])
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(CGFloat.ScaleW(w: 5))
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
        self.infoLabel.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(CGFloat.ScaleW(w: 5))
            make.left.right.equalTo(self.titleLabel)
            make.bottom.equalToSuperview().inset(CGFloat.ScaleW(w: 5))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
