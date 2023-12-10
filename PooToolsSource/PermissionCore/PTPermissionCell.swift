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
            PTGCDManager.gcdMain {
                switch self.cellModel!.type {
                case .tracking:
    #if POOTOOLS_PERMISSION_TRACKING
                    if #available(iOS 14.0, *) {
                        self.cellStatus = PTPermission.tracking.status
                    }
    #else
                    self.cellStatus = .notSupported
    #endif
                case .camera:
    #if POOTOOLS_PERMISSION_CAMERA
                    self.cellStatus = PTPermission.camera.status
    #else
                    self.cellStatus = .notSupported
    #endif
                case .photoLibrary:
    #if POOTOOLS_PERMISSION_PHOTO
                    self.cellStatus = PTPermission.photoLibrary.status
    #else
                    self.cellStatus = .notSupported
    #endif
                case .calendar(access: .full):
    #if POOTOOLS_PERMISSION_CALENDAR
                    self.cellStatus = PTPermission.calendar(access: .full).status
    #else
                    self.cellStatus = .notSupported
    #endif
                case .calendar(access: .write):
    #if POOTOOLS_PERMISSION_CALENDAR
                    self.cellStatus = PTPermission.calendar(access: .write).status
    #else
                    self.cellStatus = .notSupported
    #endif
                case .reminders:
    #if POOTOOLS_PERMISSION_REMINDERS
                    self.cellStatus = PTPermission.reminders.status
    #else
                    self.cellStatus = .notSupported
    #endif
                case .notification:
    #if POOTOOLS_PERMISSION_NOTIFICATION
                    self.cellStatus = PTPermission.notification.status
    #else
                    self.cellStatus = .notSupported
    #endif
                case .location(access: .whenInUse):
    #if POOTOOLS_PERMISSION_LOCATION
                    self.cellStatus = PTPermission.location(access: .whenInUse).status
    #else
                    self.cellStatus = .notSupported
    #endif
                case .location(access: .always):
    #if POOTOOLS_PERMISSION_LOCATION
                    self.cellStatus = PTPermission.location(access: .always).status
    #else
                    self.cellStatus = .notSupported
    #endif
                case .faceID:
    #if POOTOOLS_PERMISSION_FACEIDPERMISSION
                    self.cellStatus = PTPermission.faceID.status
    #else
                    self.cellStatus = .notSupported
    #endif
                case .speech:
    #if POOTOOLS_PERMISSION_SPEECH
                    self.cellStatus = PTPermission.speech.status
    #else
                    self.cellStatus = .notSupported
    #endif
                case .health:
    #if POOTOOLS_PERMISSION_HEALTH
                    self.cellStatus = PTPermissionHealth.status(for: HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!)
    #else
                    self.cellStatus = .notSupported
    #endif
                case .motion:
    #if POOTOOLS_PERMISSION_MOTION
                    self.cellStatus = PTPermission.motion.status
    #else
                    self.cellStatus = .notSupported
    #endif
                case .contacts:
    #if POOTOOLS_PERMISSION_CONTACTS
                    self.cellStatus = PTPermission.contacts.status
    #else
                    self.cellStatus = .notSupported
    #endif
                case .microphone:
    #if POOTOOLS_PERMISSION_MIC
                    self.cellStatus = PTPermission.microphone.status
    #else
                    self.cellStatus = .notSupported
    #endif
                case .mediaLibrary:
    #if POOTOOLS_PERMISSION_MEDIA
                    self.cellStatus = PTPermission.mediaLibrary.status
    #else
                    self.cellStatus = .notSupported
    #endif
                case .bluetooth:
    #if POOTOOLS_PERMISSION_BLUETOOTH
                    self.cellStatus = PTPermission.bluetooth.status
    #else
                    self.cellStatus = .notSupported
    #endif
                case .siri:
    #if POOTOOLS_PERMISSION_SIRI
                    self.cellStatus = PTPermission.siri.status
    #else
                    self.cellStatus = .notSupported
    #endif
                default:break
                }
                self.setButtonStatus()
            }
        }
    }
    
    func setButtonStatus() {
        let permissionName = PTPermissionText.permission_name(for: cellModel!.type)
        switch cellModel!.type {
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
        default:break
        }
        
        var totalAtt:ASAttributedString = ASAttributedString(string: "")
        
        let att:ASAttributedString =  ASAttributedString("\(permissionName)",.paragraph(.alignment(.left),.lineSpacing(3)),.font(PTAppBaseConfig.share.permissionCellTitleFont),.foreground(PTAppBaseConfig.share.permissionCellTitleTextColor))
        if !(cellModel?.desc ?? "").stringIsEmpty() {
            let descAtt:ASAttributedString =  ASAttributedString("\n\(cellModel!.desc)",.paragraph(.alignment(.left),.lineSpacing(3)),.font(PTAppBaseConfig.share.permissionCellSubtitleFont),.foreground(PTAppBaseConfig.share.permissionCellSubtitleTextColor))
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
        let view = UIButton.init(type: .custom)
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
            make.width.equalTo(UIView.sizeFor(string: "PT Permission Not support".localized(), font: self.authorizedButton.titleLabel!.font!, height: 24).width + CGFloat.ScaleW(w: 10))
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
