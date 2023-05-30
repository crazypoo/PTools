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
#if canImport(Permission)
import Permission
#endif
#if canImport(HealthKit)
import HealthKit
#endif
#if canImport(HealthPermission)
import HealthPermission
#endif
#if canImport(SpeechPermission)
import SpeechPermission
#endif
#if canImport(FaceIDPermission)
import FaceIDPermission
#endif
#if canImport(LocationWhenInUsePermission)
import LocationWhenInUsePermission
#endif
#if canImport(NotificationPermission)
import NotificationPermission
#endif
#if canImport(RemindersPermission)
import RemindersPermission
#endif
#if canImport(CalendarPermission)
import CalendarPermission
#endif
#if canImport(PhotoLibraryPermission)
import PhotoLibraryPermission
#endif
#if canImport(CameraPermission)
import CameraPermission
#endif
#if canImport(TrackingPermission)
import TrackingPermission
#endif

class PTPermissionCell: PTBaseNormalCell {
    
    static let ID = "PTPermissionCell"
    
#if canImport(Permission)
    var cellStatus:Permission.Status? = .notDetermined
    var cellButtonTapBlock:((_ type:Permission.Kind)->Void)?
#endif
    
    var cellModel:PTPermissionModel?
    {
        didSet{
                    
#if canImport(Permission)
            switch cellModel!.type
            {
            case .tracking:
#if canImport(TrackingPermission)
                if #available(iOS 14.5, *) {
                    self.cellStatus = Permission.tracking.status
                }
#else
#if canImport(Permission)
                self.cellStatus = .notSupported
#endif
#endif
            case .camera:
#if canImport(CameraPermission)
                self.cellStatus = Permission.camera.status
#else
#if canImport(Permission)
                self.cellStatus = .notSupported
#endif
#endif
            case .photoLibrary:
#if canImport(PhotoLibraryPermission)
                self.cellStatus = Permission.photoLibrary.status
#else
#if canImport(Permission)
                self.cellStatus = .notSupported
#endif
#endif
            case .calendar:
#if canImport(CalendarPermission)
                self.cellStatus = Permission.calendar.status
#else
#if canImport(Permission)
                self.cellStatus = .notSupported
#endif
#endif
            case .reminders:
#if canImport(RemindersPermission)
                self.cellStatus = Permission.reminders.status
#else
#if canImport(Permission)
                self.cellStatus = .notSupported
#endif
#endif
            case .notification:
#if canImport(NotificationPermission)
                self.cellStatus = Permission.notification.status
#else
#if canImport(Permission)
                self.cellStatus = .notSupported
#endif
#endif
            case .locationWhenInUse:
#if canImport(LocationWhenInUsePermission)
                self.cellStatus = Permission.locationWhenInUse.status
#else
#if canImport(Permission)
                self.cellStatus = .notSupported
#endif
#endif
            case .faceID:
#if canImport(FaceIDPermission)
                self.cellStatus = Permission.faceID.status
#else
#if canImport(Permission)
                self.cellStatus = .notSupported
#endif
#endif
            case .speech:
#if canImport(SpeechPermission)
                self.cellStatus = Permission.speech.status
#else
#if canImport(Permission)
                self.cellStatus = .notSupported
#endif
#endif
            case .health:
#if canImport(HealthKit) && canImport(HealthPermission)
                self.cellStatus = HealthPermission.status(for: HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!)
#else
#if canImport(Permission)
                self.cellStatus = .notSupported
#endif
#endif
            default:break
            }
#endif
            setButtonStatus()
        }
    }
    
    func setButtonStatus()
    {
        var permissionName = ""
        #if canImport(Permission)
        switch cellModel!.type
        {
        case .tracking:
            permissionName = "用户数据追踪"
            cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_tracking")
        case .camera:
            permissionName = "照相机"
            cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_camera")
        case .photoLibrary:
            permissionName = "相册"
            cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_photoLibrary")
        case .calendar:
            permissionName = "日历"
            cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_calendar")
        case .reminders:
            permissionName = "提醒"
            cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_reminders")
        case .notification:
            permissionName = "通知推送"
            cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_notification")
        case .locationWhenInUse:
            permissionName = "定位"
            cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_location")
        case .locationAlways:
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
        default:break
        }
        #endif
        
        var totalAtt:ASAttributedString = ASAttributedString(string: "")
        
        let att:ASAttributedString =  ASAttributedString("\(permissionName)",.paragraph(.alignment(.left),.lineSpacing(3)),.font(PTAppBaseConfig.share.permissionCellTitleFont),.foreground(PTAppBaseConfig.share.permissionCellTitleTextColor))
        if !(cellModel?.desc ?? "").stringIsEmpty() {
            let descAtt:ASAttributedString =  ASAttributedString("\n\(cellModel!.desc)",.paragraph(.alignment(.left),.lineSpacing(3)),.font(PTAppBaseConfig.share.permissionCellSubtitleFont),.foreground(PTAppBaseConfig.share.permissionCellSubtitleTextColor))
            totalAtt = att + descAtt
        }

        cellTitle.attributed.text = totalAtt
        
#if canImport(Permission)
        switch self.cellStatus {
        case .authorized:
            authorizedButton.isSelected = true
            authorizedButton.isUserInteractionEnabled = false
            authorizedButton.setTitle("已授权", for: .selected)
        case .denied:
            authorizedButton.isSelected = true
            authorizedButton.isUserInteractionEnabled = true
            authorizedButton.setTitleColor(PTAppBaseConfig.share.permissionDeniedColor, for: .selected)
            authorizedButton.setTitle("已拒绝", for: .selected)
            authorizedButton.addActionHandlers(handler: { sender in
                switch self.cellModel!.type
                {
                case .tracking:
#if canImport(TrackingPermission)
                    if #available(iOS 14.5, *) {
                        Permission.tracking.openSettingPage()
                    }
#endif
                case .camera:
#if canImport(CameraPermission)
                    Permission.camera.openSettingPage()
#endif
                case .photoLibrary:
#if canImport(PhotoLibraryPermission)
                    Permission.photoLibrary.openSettingPage()
#endif
                case .calendar:
#if canImport(CalendarPermission)
                    Permission.calendar.openSettingPage()
#endif
                case .reminders:
#if canImport(RemindersPermission)
                    Permission.reminders.openSettingPage()
#endif
                case .notification:
#if canImport(NotificationPermission)
                    Permission.notification.openSettingPage()
#endif
                case .locationWhenInUse:
#if canImport(LocationWhenInUsePermission)
                    Permission.locationWhenInUse.openSettingPage()
#endif
                default:break
                }
            })
        case .notDetermined:
            authorizedButton.isSelected = false
            authorizedButton.isUserInteractionEnabled = true
            authorizedButton.setTitle("询问授权", for: .normal)
            authorizedButton.addActionHandlers(handler: { sender in
                if self.cellButtonTapBlock != nil
                {
                    self.cellButtonTapBlock!(self.cellModel!.type)
                }
            })
        case .notSupported:
            authorizedButton.setTitle("不支持", for: .selected)
            authorizedButton.setTitleColor(PTAppBaseConfig.share.permissionDeniedColor, for: .selected)
            authorizedButton.isSelected = true
            authorizedButton.isUserInteractionEnabled = false
        default:
            break
        }
#endif
    }
    
    fileprivate lazy var authorizedButton:UIButton = {
        let view = UIButton.init(type: .custom)
        view.titleLabel?.font = PTAppBaseConfig.share.permissionAuthorizedButtonFont
        view.setTitleColor(.systemBlue, for: .normal)
        view.setTitle("询问授权", for: .normal)
        view.setTitleColor(.systemBlue, for: .selected)
        view.setTitle("已授权", for: .selected)
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
            make.top.bottom.equalToSuperview().inset(CGFloat.ScaleW(w: 7.5))
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.width.equalTo(UIView.sizeFor(string: "询问授权", font: self.authorizedButton.titleLabel!.font!, height: 24, width: CGFloat(MAXFLOAT)).width + CGFloat.ScaleW(w: 10))
        }
        
        cellIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.bottom.equalToSuperview().inset(CGFloat.ScaleW(w: 5))
            make.width.equalTo(self.cellIcon.snp.height)
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
