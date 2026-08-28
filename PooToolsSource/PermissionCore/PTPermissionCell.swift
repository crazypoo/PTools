//
//  SMZDTPermissionCell.swift
//  SMZDT
//
//  Created by jax on 2022/9/3.
//  Copyright © 2022 Respect. All rights reserved.
//

import UIKit
import SwifterSwift
import SnapKit
import AttributedString

#if POOTOOLS_PERMISSION_HEALTH
import HealthKit
#endif

class PTPermissionCell: PTBaseNormalCell {
    
    static let ID = "PTPermissionCell"
    
    var cellStatus:PTPermission.Status? = .notDetermined
    
    var cellModel:PTPermissionModel? {
        didSet {
            Task { @MainActor in
                guard let cellModel = self.cellModel else {
                    self.cellStatus = .notDetermined
                    return
                }
                self.cellStatus = PTPermission.status(for: cellModel.type)
                self.setButtonStatus()
            }
        }
    }
    
    func setButtonStatus() {
        guard let cellModel else { return }
        let permissionName = PTPermissionText.permission_name(for: cellModel.type)
        switch cellModel.type {
        case .tracking:
            cellIcon.image = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_permission_tracking")
        case .camera:
            cellIcon.image = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_permission_camera")
        case .photoLibrary:
            cellIcon.image = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_permission_photoLibrary")
        case .calendar(access: .full):
            cellIcon.image = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_permission_calendar")
        case .calendar(access: .write):
            cellIcon.image = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_permission_calendar")
        case .reminders:
            cellIcon.image = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_permission_reminders")
        case .notification:
            cellIcon.image = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_permission_notification")
        case .location(access: .whenInUse):
            cellIcon.image = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_permission_location")
        case .location(access: .always):
            cellIcon.image = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_permission_location")
        case .speech:
            cellIcon.image = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_permission_speech")
        case .health:
            cellIcon.image = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_permission_health")
        case .faceID:
            cellIcon.image = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_permission_faceid")
        case .motion:
            cellIcon.image = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_permission_motion")
        case .contacts:
            cellIcon.image = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_permission_contact")
        case .microphone:
            cellIcon.image = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_permission_mic")
        case .mediaLibrary:
            cellIcon.image = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_permission_media")
        case .bluetooth:
            cellIcon.image = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_permission_bluetooth")
        case .siri:
            cellIcon.image = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_permission_siri")
        }
        
        var totalAtt:ASAttributedString = ASAttributedString(string: "")
        
        let att:ASAttributedString =  ASAttributedString("\(permissionName)",.paragraph(.alignment(.left),.lineSpacing(3)),.font(PTAppBaseConfig.share.permissionCellTitleFont),.foreground(PTAppBaseConfig.share.permissionCellTitleTextColor))
        if !cellModel.desc.stringIsEmpty() {
            let descAtt:ASAttributedString =  ASAttributedString("\n\(cellModel.desc)",.paragraph(.alignment(.left),.lineSpacing(3)),.font(PTAppBaseConfig.share.permissionCellSubtitleFont),.foreground(PTAppBaseConfig.share.permissionCellSubtitleTextColor))
            totalAtt = att + descAtt
        }
        
        cellTitle.attributed.text = totalAtt
        
        switch cellStatus {
        case .authorized:
            authorizedButton.isSelected = true
        case .denied:
            authorizedButton.isSelected = true
            authorizedButton.setTitle("PT Permission rejected".localized(), for: .normal)
            authorizedButton.setTitleColor(PTAppBaseConfig.share.permissionDeniedColor, for: .normal)
        case .notDetermined:
            authorizedButton.isSelected = false
        case .notSupported:
            authorizedButton.isEnabled = false
        default:
            break
        }
    }
    
    fileprivate lazy var authorizedButton:UIButton = {
        let view = UIButton(type: .custom)
        view.titleLabel?.font = PTAppBaseConfig.share.permissionAuthorizedButtonFont
        view.setTitleColor(.systemBlue, for: .normal)
        view.setTitle("PT Permission Not determined".localized(), for: .normal)
        view.setTitleColor(.systemBlue, for: .selected)
        view.setTitle("PT Permission authorized".localized(), for: .selected)
        view.setTitle("PT Permission Not support".localized(), for: .disabled)
        view.setTitleColor(PTAppBaseConfig.share.permissionNotSupportColor, for: .disabled)
        view.isUserInteractionEnabled = false
        return view
    }()
    
    fileprivate lazy var cellTitle = pt_createLabel(text: "",bgColor: .clear)
    
    fileprivate lazy var cellIcon:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        
        contentView.addSubviews([authorizedButton, cellIcon, cellTitle])
        authorizedButton.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(10)
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            let buttonFont = self.authorizedButton.titleLabel?.font ?? UIFont.systemFont(ofSize: UIFont.labelFontSize)
            make.width.equalTo(UIView.sizeFor(string: "PT Permission Not support".localized(), font: buttonFont, height: 24).width + CGFloat.ScaleW(w: 10))
        }
        
        cellIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.size.equalTo(44)
            make.centerY.equalToSuperview()
        }
        
        cellTitle.snp.makeConstraints { make in
            make.left.equalTo(self.cellIcon.snp.right).offset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.bottom.equalToSuperview()
            make.right.equalTo(self.authorizedButton.snp.left).offset(-PTAppBaseConfig.share.defaultViewSpace)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
