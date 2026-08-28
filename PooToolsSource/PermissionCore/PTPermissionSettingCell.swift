//
//  PTPermissionSettingCell.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import AttributedString
import SafeSFSymbols
#if POOTOOLS_PERMISSION_HEALTH
import HealthKit
#endif

class PTPermissionSettingCell: PTBaseNormalCell {
    static let ID = "PTPermissionSettingCell"
    
    static let CellHeight:CGFloat = 44
    
    var cellModel:PTPermissionModel? {
        didSet {
            guard let cellModel else { return }
            let cellStatus = PTPermission.status(for: cellModel.type)

            var statusText = ""
            var statusColor:UIColor = .lightGray
            switch cellStatus {
            case .authorized:
                statusText = "PT Permission authorized".localized()
                statusColor = .systemBlue
            case .denied:
                statusText = "PT Permission rejected".localized()
                statusColor = .systemRed
            case .notDetermined:
                statusText = "PT Permission Not determined".localized()
                statusColor = .lightGray
            case .notSupported:
                statusText = "PT Permission Not support".localized()
                statusColor = .systemYellow
            default:
                break
            }
            infoLabel.text = cellModel.desc
            let statusAtt:ASAttributedString = """
            \(wrap: .embedding("""
            \("PT Permission Status title".localized(),.foreground(PTAppBaseConfig.share.viewDefaultTextColor),.font(PTPermissionStatic.share.permissionSettingFont),.paragraph(.alignment(.left)))\(statusText,.foreground(statusColor),.font(PTPermissionStatic.share.permissionSettingFont),.paragraph(.alignment(.left)))
            """))
            """
            statusLabel.attributed.text = statusAtt
            
            let tap = UITapGestureRecognizer { sender in
                PTOpenSystemFunction.jumpCurrentAppSetting()
            }
            settingView.addGestureRecognizer(tap)
        }
    }
    
    lazy var infoLabel : UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = PTPermissionStatic.share.permissionSettingFont
        view.textAlignment = .left
        view.textColor = PTAppBaseConfig.share.viewDefaultTextColor
        return view
    }()
    
    lazy var line1:UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()

    lazy var statusLabel : UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }()
    
    lazy var line2:UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()
    
    lazy var settingView:UIView = {
        let view = UIView()
        return view
    }()
    
    lazy var settingLabel:UILabel = {
        let view = UILabel()
        view.textColor = .systemBlue
        view.font = PTPermissionStatic.share.permissionSettingFont
        view.textAlignment = .left
        view.text = "PT Permission Go setting".localized()
        return view
    }()
    
    lazy var settingImage:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.image = UIImage(.chevron.right).withTintColor(PTAppBaseConfig.share.viewDefaultTextColor)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = PTAppBaseConfig.share.baseCellBackgroundColor
        
        contentView.addSubviews([infoLabel,line1,statusLabel,line2,settingView])
        infoLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.equalToSuperview().inset(10)
        }
        
        line1.snp.makeConstraints { make in
            make.left.right.equalTo(self.infoLabel)
            make.height.equalTo(1)
            make.top.equalTo(self.infoLabel.snp.bottom).offset(10)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(self.line1.snp.bottom)
            make.left.right.equalTo(self.infoLabel)
            make.height.equalTo(PTPermissionSettingCell.CellHeight)
        }
        
        line2.snp.makeConstraints { make in
            make.left.right.equalTo(self.infoLabel)
            make.height.equalTo(1)
            make.top.equalTo(self.statusLabel.snp.bottom)
        }
        
        settingView.snp.makeConstraints { make in
            make.top.equalTo(self.line2.snp.bottom)
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(PTPermissionSettingCell.CellHeight)
        }
        
        createSettingViews()
        contentView.viewCorner(radius: 10,borderWidth: 0,borderColor: .clear)
    }
    
    func createSettingViews() {
        settingView.addSubviews([settingImage,settingLabel])
        settingImage.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
        
        settingLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.bottom.equalToSuperview()
            make.right.equalTo(self.settingImage.snp.left).offset(-10)
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
