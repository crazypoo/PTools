//
//  SMZDTPermissionCell.swift
//  SMZDT
//
//  Created by jax on 2022/9/3.
//  Copyright © 2022 Respect. All rights reserved.
//

import UIKit
import PermissionsKit
import SwifterSwift
import SnapKit
import SJAttributesStringMaker
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
    
    var cellStatus:Permission.Status? = .notDetermined
    
    var cellButtonTapBlock:((_ type:Permission.Kind)->Void)?
    
    var cellModel:PTPermissionModel?
    {
        didSet{
                        
            switch cellModel!.type
            {
            case .tracking:
#if canImport(TrackingPermission)
                if #available(iOS 14.5, *) {
                    self.cellStatus = Permission.tracking.status
                }
#else
                self.cellStatus = .notSupported
#endif
            case .camera:
#if canImport(CameraPermission)
                self.cellStatus = Permission.camera.status
#else
                self.cellStatus = .notSupported
#endif
            case .photoLibrary:
#if canImport(PhotoLibraryPermission)
                self.cellStatus = Permission.photoLibrary.status
#else
                self.cellStatus = .notSupported
#endif
            case .calendar:
#if canImport(CalendarPermission)
                self.cellStatus = Permission.calendar.status
#else
                self.cellStatus = .notSupported
#endif
            case .reminders:
#if canImport(RemindersPermission)
                self.cellStatus = Permission.reminders.status
#else
                self.cellStatus = .notSupported
#endif
            case .notification:
#if canImport(NotificationPermission)
                self.cellStatus = Permission.notification.status
#else
                self.cellStatus = .notSupported
#endif
            case .locationWhenInUse:
#if canImport(LocationWhenInUsePermission)
                self.cellStatus = Permission.locationWhenInUse.status
#else
                self.cellStatus = .notSupported
#endif
            case .faceID:
#if canImport(FaceIDPermission)
                self.cellStatus = Permission.faceID.status
#else
                self.cellStatus = .notSupported
#endif
            case .speech:
#if canImport(SpeechPermission)
                self.cellStatus = Permission.speech.status
#else
                self.cellStatus = .notSupported
#endif
            case .health:
#if canImport(HealthKit) && canImport(HealthPermission)
                self.cellStatus = HealthPermission.status(for: HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!)
#else
                self.cellStatus = .notSupported
#endif
            default:break
            }
            self.setButtonStatus()
        }
    }
    
    func setButtonStatus()
    {
        var permissionName = ""
        switch self.cellModel!.type
        {
        case .tracking:
            permissionName = "用户数据追踪"
            self.cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_tracking")
        case .camera:
            permissionName = "照相机"
            self.cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_camera")
        case .photoLibrary:
            permissionName = "相册"
            self.cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_photoLibrary")
        case .calendar:
            permissionName = "日历"
            self.cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_calendar")
        case .reminders:
            permissionName = "提醒"
            self.cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_reminders")
        case .notification:
            permissionName = "通知推送"
            self.cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_notification")
        case .locationWhenInUse:
            permissionName = "定位"
            self.cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_location")
        case .speech:
            permissionName = "语音识别"
            self.cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_speech")
        case .health:
            permissionName = "健康"
            self.cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_health")
        case .faceID:
            permissionName = "FaceID"
            self.cellIcon.image = Bundle.imageWithName(imageName: "icon_permission_faceid")
        default:break
        }
        
        self.cellTitle.attributedText = NSMutableAttributedString.sj.makeText({ make in
            make.append(permissionName).font(PTAppBaseConfig.share.permissionCellTitleFont).alignment(.left).textColor(PTAppBaseConfig.share.permissionCellTitleTextColor).lineSpacing(CGFloat.ScaleW(w: 3))
            if !(self.cellModel?.desc ?? "").stringIsEmpty()
            {
                make.append("\n\(self.cellModel!.desc)").font(PTAppBaseConfig.share.permissionCellSubtitleFont).alignment(.left).textColor(PTAppBaseConfig.share.permissionCellSubtitleTextColor)
            }
        })
        
        switch self.cellStatus {
        case .authorized:
            self.authorizedButton.isSelected = true
            self.authorizedButton.isUserInteractionEnabled = false
            self.authorizedButton.setTitle("已授权", for: .selected)
        case .denied:
            self.authorizedButton.isSelected = true
            self.authorizedButton.isUserInteractionEnabled = true
            self.authorizedButton.setTitleColor(PTAppBaseConfig.share.permissionDeniedColor, for: .selected)
            self.authorizedButton.setTitle("已拒绝", for: .selected)
            self.authorizedButton.addActionHandlers(handler: { sender in
                switch self.cellModel!.type
                {
                case .tracking:
                    if #available(iOS 14.5, *) {
                        Permission.tracking.openSettingPage()
                    }
                case .camera:
                    Permission.camera.openSettingPage()
                case .photoLibrary:
                    Permission.photoLibrary.openSettingPage()
                case .calendar:
                    Permission.calendar.openSettingPage()
                case .reminders:
                    Permission.reminders.openSettingPage()
                case .notification:
                    Permission.notification.openSettingPage()
                case .locationWhenInUse:
                    Permission.locationWhenInUse.openSettingPage()
                default:break
                }
            })
        case .notDetermined:
            self.authorizedButton.isSelected = false
            self.authorizedButton.isUserInteractionEnabled = true
            self.authorizedButton.setTitle("询问授权", for: .normal)
            self.authorizedButton.addActionHandlers(handler: { sender in
                if self.cellButtonTapBlock != nil
                {
                    self.cellButtonTapBlock!(self.cellModel!.type)
                }
            })
        case .notSupported:
            self.authorizedButton.setTitle("不支持", for: .selected)
            self.authorizedButton.setTitleColor(PTAppBaseConfig.share.permissionDeniedColor, for: .selected)
            self.authorizedButton.isSelected = true
            self.authorizedButton.isUserInteractionEnabled = false
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
        return view
    }()
    
    fileprivate lazy var cellTitle = self.pt_createLabel(text: "",bgColor: .clear)
    
    fileprivate lazy var cellIcon:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .clear
        
        self.contentView.addSubviews([self.authorizedButton,self.cellIcon,self.cellTitle])
        self.authorizedButton.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(CGFloat.ScaleW(w: 7.5))
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.width.equalTo(PTUtils.sizeFor(string: "询问授权", font: self.authorizedButton.titleLabel!.font!, height: 24, width: CGFloat(MAXFLOAT)).width + CGFloat.ScaleW(w: 10))
        }
        
        self.cellIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.bottom.equalToSuperview().inset(CGFloat.ScaleW(w: 5))
            make.width.equalTo(self.cellIcon.snp.height)
        }
        
        self.cellTitle.snp.makeConstraints { make in
            make.left.equalTo(self.cellIcon.snp.right).offset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.bottom.equalToSuperview()
            make.right.equalTo(self.authorizedButton.snp.left).offset(-PTAppBaseConfig.share.defaultViewSpace)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
