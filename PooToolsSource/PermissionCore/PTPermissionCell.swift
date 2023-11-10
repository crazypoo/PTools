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
    var cellButtonTapBlock:((_ type:PTPermission.Kind)->Void)?
    
    var cellModel:PTPermissionModel? {
        didSet {
            PTGCDManager.gcdMain() {
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
    #if POOTOOLS_PERMISSION_MIC
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
        var permissionName = ""
        switch cellModel!.type {
        case .tracking:
            permissionName = "用户数据追踪"
            cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_tracking")
        case .camera:
            permissionName = "照相机"
            cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_camera")
        case .photoLibrary:
            permissionName = "相册"
            cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_photoLibrary")
        case .calendar(access: .full):
            permissionName = "完全使用日历"
            cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_calendar")
        case .calendar(access: .write):
            permissionName = "写入数据到日历"
            cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_calendar")
        case .reminders:
            permissionName = "提醒"
            cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_reminders")
        case .notification:
            permissionName = "通知推送"
            cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_notification")
        case .location(access: .whenInUse):
            permissionName = "须要时使用定位"
            cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_location")
        case .location(access: .always):
            permissionName = "保持使用定位"
            cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_location")
        case .speech:
            permissionName = "语音识别"
            cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_speech")
        case .health:
            permissionName = "健康"
            cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_health")
        case .faceID:
            permissionName = "FaceID"
            cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_faceid")
        case .motion:
            permissionName = "运动数据"
            cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_motion")
        case .contacts:
            permissionName = "通讯录"
            cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_contact")
        case .microphone:
            permissionName = "麦克风"
            cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_mic")
        case .mediaLibrary:
            permissionName = "多媒体"
            cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_media")
        case .bluetooth:
            permissionName = "蓝牙"
            cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_bluetooth")
        case .siri:
            permissionName = "Siri"
            cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_siri")
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
            authorizedButton.isUserInteractionEnabled = false
        case .denied:
            authorizedButton.isSelected = true
            authorizedButton.setTitle("已拒绝", for: .normal)
            authorizedButton.setTitleColor(PTAppBaseConfig.share.permissionDeniedColor, for: .normal)
            authorizedButton.isUserInteractionEnabled = true
            authorizedButton.addActionHandlers(handler: { sender in
                switch self.cellModel!.type {
                case .tracking:
#if POOTOOLS_PERMISSION_TRACKING
                    if #available(iOS 14.0, *) {
                        PTPermission.tracking.openSettingPage()
                    }
#endif
                case .camera:
#if POOTOOLS_PERMISSION_CAMERA
                    PTPermission.camera.openSettingPage()
#endif
                case .photoLibrary:
#if POOTOOLS_PERMISSION_PHOTO
                    PTPermission.photoLibrary.openSettingPage()
#endif
                case .calendar(access: .full):
#if POOTOOLS_PERMISSION_CALENDAR
                    PTPermission.calendar(access: .full).openSettingPage()
#endif
                case .calendar(access: .write):
#if POOTOOLS_PERMISSION_CALENDAR
                    PTPermission.calendar(access: .write).openSettingPage()
#endif
                case .reminders:
#if POOTOOLS_PERMISSION_REMINDERS
                    PTPermission.reminders.openSettingPage()
#endif
                case .notification:
#if POOTOOLS_PERMISSION_NOTIFICATION
                    PTPermission.notification.openSettingPage()
#endif
                case .location(access: .whenInUse):
#if POOTOOLS_PERMISSION_LOCATION
                    PTPermission.location(access: .whenInUse).openSettingPage()
#endif
                case .location(access: .always):
#if POOTOOLS_PERMISSION_LOCATION
                    PTPermission.location(access: .always).openSettingPage()
#endif
                case .motion:
#if POOTOOLS_PERMISSION_MOTION
                    PTPermission.motion.openSettingPage()
#endif
                case .faceID:
#if POOTOOLS_PERMISSION_FACEIDPERMISSION
                    PTPermission.faceID.openSettingPage()
#endif
                case .health:
#if POOTOOLS_PERMISSION_HEALTH
                    PTPermission.health.openSettingPage()
#endif
                case .speech:
#if POOTOOLS_PERMISSION_SPEECH
                    PTPermission.speech.openSettingPage()
#endif
                case .contacts:
#if POOTOOLS_PERMISSION_CONTACTS
                    PTPermission.contacts.openSettingPage()
#endif
                case .microphone:
#if POOTOOLS_PERMISSION_MIC
                    PTPermission.microphone.openSettingPage()
#endif
                case .mediaLibrary:
#if POOTOOLS_PERMISSION_MEDIA
                    PTPermission.mediaLibrary.openSettingPage()
#endif
                case .bluetooth:
#if POOTOOLS_PERMISSION_BLUETOOTH
                    PTPermission.bluetooth.openSettingPage()
#endif
                case .siri:
#if POOTOOLS_PERMISSION_SIRI
                    PTPermission.siri.openSettingPage()
#endif
                default:break
                }
            })
        case .notDetermined:
            authorizedButton.isSelected = false
            authorizedButton.isUserInteractionEnabled = true
            authorizedButton.addActionHandlers(handler: { sender in
                if self.cellButtonTapBlock != nil {
                    self.cellButtonTapBlock!(self.cellModel!.type)
                }
            })
        case .notSupported:
            authorizedButton.isEnabled = false
            authorizedButton.isUserInteractionEnabled = false
        default:
            break
        }
    }
    
    fileprivate lazy var authorizedButton:UIButton = {
        let view = UIButton.init(type: .custom)
        view.titleLabel?.font = PTAppBaseConfig.share.permissionAuthorizedButtonFont
        view.setTitleColor(.systemBlue, for: .normal)
        view.setTitle("询问授权", for: .normal)
        view.setTitleColor(.systemBlue, for: .selected)
        view.setTitle("已授权", for: .selected)
        view.setTitle("不支持", for: .disabled)
        view.setTitleColor(PTAppBaseConfig.share.permissionNotSupportColor, for: .disabled)
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
            make.width.equalTo(UIView.sizeFor(string: "询问授权", font: self.authorizedButton.titleLabel!.font!, height: 24).width + CGFloat.ScaleW(w: 10))
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
