//
//  PTPermissionViewController.swift
//  PT
//
//  Created by jax on 2022/9/3.
//  Copyright © 2022 Respect. All rights reserved.
//

import UIKit
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif
import SnapKit
#if POOTOOLS_PERMISSION_HEALTH
import HealthKit
#endif
import DeviceKit

@objcMembers
public class PTPermissionStatic:NSObject {
    public static let share = PTPermissionStatic()
    public var permissionModels:[PTPermissionModel] = [PTPermissionModel]()
    public var permissionSettingFont:UIFont = .appfont(size: 16)
}

@objcMembers
public class PTPermissionViewController: PTBaseViewController {
    
    fileprivate var permissions:[PTPermissionModel]!
    fileprivate var permissionStatic = PTPermissionStatic.share
    
    public var viewDismissBlock:PTActionTask?
    
    fileprivate var trackingRequest:Bool? {
        didSet {
            if trackingRequest! {
                showRequestFunction()
            }
        }
    }
    
    private lazy var newCollectionView:PTCollectionView = {
        let cConfig = PTCollectionViewConfig()
        cConfig.viewType = .Normal
        cConfig.itemOriginalX = PTAppBaseConfig.share.defaultViewSpace
        cConfig.itemHeight = 88
        cConfig.headerWidthOffset = PTAppBaseConfig.share.defaultViewSpace
        cConfig.decorationItemsType = .Corner
        cConfig.decorationItemsEdges = NSDirectionalEdgeInsets(top: 0, leading: PTAppBaseConfig.share.defaultViewSpace, bottom: 0, trailing: PTAppBaseConfig.share.defaultViewSpace)
        
        let view = PTCollectionView(viewConfig: cConfig)
        view.registerClassCells(classs: [PTPermissionCell.ID:PTPermissionCell.self])
        view.registerSupplementaryView(classs: [PTPermissionHeader.ID:PTPermissionHeader.self], kind: UICollectionView.elementKindSectionHeader)
        view.decorationViewReset = { collection,view,kind,indexPath,sectionModel in
            if Gobal_device_info.isPad {
                if kind == PTBaseDecorationView_Corner.ID {
                    view.frame = CGRectMake(cConfig.decorationItemsEdges.leading, 0, self.view.frame.size.width - cConfig.decorationItemsEdges.leading - cConfig.decorationItemsEdges.trailing, CGFloat(self.permissions.count * 88) + PTPermissionHeader.cellHeight())
                } else if kind == UICollectionView.elementKindSectionHeader {
                    view.frame = CGRectMake(cConfig.decorationItemsEdges.leading, 0, self.view.frame.size.width - cConfig.decorationItemsEdges.leading - cConfig.decorationItemsEdges.trailing, PTPermissionHeader.cellHeight())
                }
            }
        }
        
        view.headerInCollection = { kind,collectionView,model,indexPath in
            if let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: model.headerID!, for: indexPath) as? PTPermissionHeader {
                return header
            }
            return nil
        }
        view.cellInCollection = { collectionView ,dataModel,indexPath in
            if let itemRow = dataModel.rows?[indexPath.row],let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTPermissionCell,let cellModel = itemRow.dataModel as? PTPermissionModel {
                cell.cellModel  = cellModel
                return cell
            }
            return nil
        }
        
        view.collectionDidSelect = { collectionView, sectionModel, indexPath in
            if let itemRow = sectionModel.rows?[indexPath.row],let cellModel = itemRow.dataModel as? PTPermissionModel, let cell = collectionView.cellForItem(at: indexPath) as? PTPermissionCell {
                switch cell.cellStatus {
                case .authorized:
                    break
                case .denied:
                    switch cellModel.type {
                    case .tracking:
    #if POOTOOLS_PERMISSION_TRACKING
                        PTPermission.tracking.openSettingPage()
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
                case .notDetermined:
                    self.permissionRequest(type: cellModel.type)
                case .notSupported:
                    break
                default:
                    break
                }
            }
        }
        return view
    }()
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PTCoreUserDefultsWrapper.AppFirstPermissionShowed = true
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        viewDismissBlock?()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_navBarBackgroundColorAlpha = 0
        self.zx_hideBaseNavBar = true
#endif
        
        permissions = permissionStatic.permissionModels
        
        let closeButton = UIButton(type: .close)
        view?.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.width.height.equalTo(34)
            make.top.equalToSuperview().inset(CGFloat.statusBarHeight() + 5)
        }
        closeButton.addActionHandlers(handler: { sender in
            self.returnFrontVC {
                self.viewDismissBlock?()
            }
        })
        
        view.addSubview(newCollectionView)
        newCollectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(closeButton.snp.bottom).offset(10)
        }
        
        showDetail()
        
        var haveTracking:Bool? = false
        for ( _ ,value) in permissions!.enumerated() {
            if value.type.name == PTPermission.Kind.tracking.name {
                haveTracking = true
                break
            }
        }
        
        if haveTracking! {
#if POOTOOLS_PERMISSION_TRACKING
                PTPermission.tracking.request {
                    self.trackingRequest = true
                }
#endif
        } else {
            showRequestFunction()
        }
    }
    
    func showRequestFunction() {
        permissions.enumerated().forEach({ index,value in
            permissionRequest(showTracking: false,type: value.type)
        })
    }
    
    func showDetail() {
        var mSections = [PTSection]()
        let permissionRows = permissions.map { PTRows(ID: PTPermissionCell.ID,dataModel: $0) }
        let section = PTSection(headerID:PTPermissionHeader.ID,headerHeight:PTPermissionHeader.cellHeight(),rows: permissionRows)
        mSections.append(section)
        
        newCollectionView.layoutIfNeeded()
        newCollectionView.showCollectionDetail(collectionData: mSections)
    }
    
    func permissionRequest(showTracking:Bool? = true,type:PTPermission.Kind) {
        switch type {
        case .tracking:
#if POOTOOLS_PERMISSION_TRACKING
            if !showTracking! {
                PTPermission.tracking.request {
                    self.showDetail()
                }
            }
#endif
        case .camera:
#if POOTOOLS_PERMISSION_CAMERA
            PTPermission.camera.request {
                self.showDetail()
            }
#endif
        case .photoLibrary:
#if POOTOOLS_PERMISSION_PHOTO
            PTPermission.photoLibrary.request {
                self.showDetail()
            }
#endif
        case .calendar(access: .full):
#if POOTOOLS_PERMISSION_CALENDAR
            PTPermission.calendar(access: .full).request {
                self.showDetail()
            }
#endif
        case .calendar(access: .write):
#if POOTOOLS_PERMISSION_CALENDAR
            PTPermission.calendar(access: .write).request {
                self.showDetail()
            }
#endif
        case .reminders:
#if POOTOOLS_PERMISSION_REMINDERS
            PTPermission.reminders.request {
                self.showDetail()
            }
#endif
        case .notification:
#if POOTOOLS_PERMISSION_NOTIFICATION
            PTPermission.notification.request {
                self.showDetail()
            }
#endif
        case .location(access: .whenInUse):
#if POOTOOLS_PERMISSION_LOCATION
            PTPermission.location(access: .whenInUse).request {
                self.showDetail()
            }
#endif
        case .location(access: .always):
#if POOTOOLS_PERMISSION_LOCATION
            PTPermission.location(access: .always).request {
                self.showDetail()
            }
#endif
        case .health:
#if POOTOOLS_PERMISSION_HEALTH
            PTPermissionHealth.request(forReading: [HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!],writing:Set<HKSampleType>()) {
                self.showDetail()
            }
#endif
        case .speech:
#if POOTOOLS_PERMISSION_SPEECH
            PTPermission.speech.request {
                self.showDetail()
            }
#endif
        case .faceID:
#if POOTOOLS_PERMISSION_FACEIDPERMISSION
            PTPermission.faceID.request {
                self.showDetail()
            }
#endif
        case .motion:
#if POOTOOLS_PERMISSION_MOTION
            PTPermission.motion.request {
                self.showDetail()
            }
#endif
        case .contacts:
#if POOTOOLS_PERMISSION_CONTACTS
            PTPermission.contacts.request {
                self.showDetail()
            }
#endif
        case .microphone:
#if POOTOOLS_PERMISSION_MIC
            PTPermission.microphone.request {
                self.showDetail()
            }
#endif
        case .mediaLibrary:
#if POOTOOLS_PERMISSION_MEDIA
            PTPermission.mediaLibrary.request {
                self.showDetail()
            }
#endif
        case .bluetooth:
#if POOTOOLS_PERMISSION_BLUETOOTH
            PTPermission.bluetooth.request {
                self.showDetail()
            }
#endif
        case .siri:
#if POOTOOLS_PERMISSION_SIRI
            PTPermission.siri.request {
                self.showDetail()
            }
#endif
        }
    }
    
    public func permissionShow(vc:UIViewController) {
        modalPresentationStyle = .formSheet
        vc.showDetailViewController(self, sender: nil)
    }
}
