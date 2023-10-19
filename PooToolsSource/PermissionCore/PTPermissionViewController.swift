//
//  PTPermissionViewController.swift
//  PT
//
//  Created by jax on 2022/9/3.
//  Copyright © 2022 Respect. All rights reserved.
//

import UIKit
import ZXNavigationBar
import SnapKit
#if POOTOOLS_PERMISSION_HEALTH
import HealthKit
#endif

public let uPermission = "uPermission"

@objcMembers
public class PTPermissionViewController: PTBaseViewController {
    
    public let appfirst : String = (UserDefaults.standard.value(forKey: uPermission) == nil) ? "0" : (UserDefaults.standard.value(forKey: uPermission) as! String)
    
    fileprivate var permissions:[PTPermissionModel]?
    
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
        cConfig.itemHeight = PTAppBaseConfig.share.baseCellHeight
        cConfig.headerWidthOffset = PTAppBaseConfig.share.defaultViewSpace
        cConfig.decorationItemsType = .Corner
        cConfig.decorationItemsEdges = NSDirectionalEdgeInsets.init(top: 0, leading: PTAppBaseConfig.share.defaultViewSpace, bottom: 0, trailing: PTAppBaseConfig.share.defaultViewSpace)
        
        let view = PTCollectionView(viewConfig: cConfig)
        view.headerInCollection = { kind,collectionView,model,indexPath in
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: model.headerID!, for: indexPath) as! PTPermissionHeader
            return header
        }
        view.cellInCollection = { collectionView ,dataModel,indexPath in
            let itemRow = dataModel.rows[indexPath.row]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTPermissionCell
            cell.cellModel  = (itemRow.dataModel as! PTPermissionModel)
            cell.cellButtonTapBlock = { type in
                switch type {
                case .tracking:
    #if POOTOOLS_PERMISSION_TRACKING
                    if #available(iOS 14.0, *) {
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
            return cell
        }

        return view
    }()

    public init(datas:[PTPermissionModel]) {
        super.init(nibName: nil, bundle: nil)
        permissions = datas
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UserDefaults.standard.set("1", forKey: uPermission)
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if viewDismissBlock != nil {
            viewDismissBlock!()
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_navBarBackgroundColorAlpha = 0
        self.zx_hideBaseNavBar = true
#endif
        
        let closeButton = UIButton.init(type: .close)
        view?.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.width.height.equalTo(34)
            make.top.equalToSuperview().inset(CGFloat.statusBarHeight() + 5)
        }
        closeButton.addActionHandlers(handler: { sender in
            self.returnFrontVC {
                if self.viewDismissBlock != nil {
                    self.viewDismissBlock!()
                }
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
            if #available(iOS 14.0, *) {
#if POOTOOLS_PERMISSION_TRACKING
                PTPermission.tracking.request {
                    self.trackingRequest = true
                }
#endif
            } else {
                showRequestFunction()
            }
        } else {
            showRequestFunction()
        }
    }
    
    func showRequestFunction() {
        permissions?.enumerated().forEach({ index,value in
            switch value.type {
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
            default:
                break
            }
        })
    }
    
    func showDetail() {
        var mSections = [PTSection]()
        
        var permissionRows = [PTRows]()
        permissions?.enumerated().forEach({ index,value in
            let row = PTRows.init(title: value.name,content: value.desc,cls: PTPermissionCell.self,ID: PTPermissionCell.ID,dataModel: value)
            permissionRows.append(row)
        })
        
        let section = PTSection.init(headerCls:PTPermissionHeader.self,headerID:PTPermissionHeader.ID,headerHeight:PTPermissionHeader.cellHeight(),rows: permissionRows)
        mSections.append(section)
        
        self.newCollectionView.layoutIfNeeded()
        self.newCollectionView.showCollectionDetail(collectionData: mSections)
    }
}
