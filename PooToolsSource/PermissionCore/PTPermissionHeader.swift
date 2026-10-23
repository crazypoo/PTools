//
//  GPPermissionHeader.swift
//  MinaTicket
//
//  Created by jax on 2022/9/6.
//  Copyright © 2022 Hola. All rights reserved.
//

import UIKit
import SnapKit

class PTPermissionHeader: PTBaseCollectionReusableView,@MainActor PTSupplementaryRegisterable {
    static let ID = "GPPermissionHeader"
    static let headerTitle = "\(kAppName ?? "App")所需权限清单"
    static let headerInfo = "以下是App完全正常工作所需的授权清单"
    static public var kind: String { UICollectionView.elementKindSectionHeader }
    static public var reuseID: String { PTPermissionHeader.ID }

    open class func cellHeight()->CGFloat {
        // English: Legacy callers keep the old display-based width; new layouts must provide their container width.
        // Español: Los callers heredados conservan el ancho de pantalla; los diseños nuevos pasan el ancho del contenedor.
        // 中文：旧调用保留屏幕宽度兼容行为；新布局必须传入容器宽度。
        return cellHeight(forWidth: CGFloat.kSCREEN_WIDTH)
    }

    // English: Measure the header in the collection view's own coordinate space.
    // Español: Mide el encabezado en el espacio de coordenadas de su propia colección.
    // 中文：在集合视图自己的坐标系内测量 Header 高度。
    open class func cellHeight(forWidth width: CGFloat) -> CGFloat {
        let contentWidth = max(0, width - PTAppBaseConfig.share.defaultViewSpace)
        let titleHeight = UIView.sizeFor(string: PTPermissionHeader.headerTitle,
                                         font: PTAppBaseConfig.share.permissionTitleFont,
                                         width: contentWidth).height + CGFloat.ScaleW(w: 5)
        let infoHeight = UIView.sizeFor(string: PTPermissionHeader.headerInfo,
                                        font: PTAppBaseConfig.share.permissionSubtitleFont,
                                        width: contentWidth).height + CGFloat.ScaleW(w: 5)
        return titleHeight + infoHeight + CGFloat.ScaleW(w: 5) * 3
    }
    
    fileprivate lazy var titleLabel = pt_createLabel(text: PTPermissionHeader.headerTitle, font: PTAppBaseConfig.share.permissionTitleFont, bgColor: .clear, textColor: PTAppBaseConfig.share.permissionTitleColor, textAlignment: .left)
    fileprivate lazy var infoLabel = pt_createLabel(text: PTPermissionHeader.headerInfo, font: PTAppBaseConfig.share.permissionSubtitleFont, bgColor: .clear, textColor: PTAppBaseConfig.share.permissionSubtitleColor, textAlignment: .left)

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubviews([titleLabel, infoLabel])
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(CGFloat.ScaleW(w: 5))
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
        infoLabel.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(CGFloat.ScaleW(w: 5))
            make.left.right.equalTo(self.titleLabel)
            make.bottom.equalToSuperview().inset(CGFloat.ScaleW(w: 5))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
