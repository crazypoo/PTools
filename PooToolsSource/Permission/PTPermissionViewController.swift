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
#if canImport(Permission)
import Permission
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

public let uPermission = "uPermission"

@objcMembers
public class PTPermissionViewController: PTBaseViewController {
    
    public let appfirst : String = (UserDefaults.standard.value(forKey: uPermission) == nil) ? "0" : (UserDefaults.standard.value(forKey: uPermission) as! String)
    
    fileprivate var permissions:[PTPermissionModel]?
    
    public var viewDismissBlock:PTActionTask?
    
    fileprivate var trackingRequest:Bool?
    {
        didSet
        {
            if trackingRequest!
            {
                showRequestFunction()
            }
        }
    }
    
    var mSections = [PTSection]()
    func comboLayout()->UICollectionViewCompositionalLayout
    {
        let layout = UICollectionViewCompositionalLayout.init { section, environment in
            self.generateSection(section: section)
        }
        layout.register(PTBaseDecorationView_Corner.self, forDecorationViewOfKind: "background")
        return layout
    }
    
    func generateSection(section:NSInteger)->NSCollectionLayoutSection
    {
        let sectionModel = mSections[section]

        var group : NSCollectionLayoutGroup
        let behavior : UICollectionLayoutSectionOrthogonalScrollingBehavior = .continuous

        let bannerItemSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.fractionalWidth(1), heightDimension: NSCollectionLayoutDimension.fractionalHeight(1))
        let bannerItem = NSCollectionLayoutItem.init(layoutSize: bannerItemSize)
        
        var bannerGroupSize : NSCollectionLayoutSize
        
        bannerItem.contentInsets = NSDirectionalEdgeInsets.init(top: 0, leading: PTAppBaseConfig.share.defaultViewSpace, bottom: 0, trailing: PTAppBaseConfig.share.defaultViewSpace)
        bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(CGFloat.kSCREEN_WIDTH), heightDimension: NSCollectionLayoutDimension.absolute(PTAppBaseConfig.share.baseCellHeight * CGFloat(sectionModel.rows.count)))
        group = NSCollectionLayoutGroup.vertical(layoutSize: bannerGroupSize, subitem: bannerItem, count: sectionModel.rows.count)


        var sectionInsets = NSDirectionalEdgeInsets.init(top: 0, leading: 0, bottom: 0, trailing: 0)
        var laySection = NSCollectionLayoutSection(group: group)
        laySection.orthogonalScrollingBehavior = behavior
        laySection.contentInsets = sectionInsets

        sectionInsets = NSDirectionalEdgeInsets.init(top: 0, leading: 0, bottom: 0, trailing: 0)
        laySection = NSCollectionLayoutSection(group: group)
        laySection.orthogonalScrollingBehavior = behavior
        laySection.contentInsets = sectionInsets
        laySection.supplementariesFollowContentInsets = false
        
        let headerSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 2), heightDimension: NSCollectionLayoutDimension.absolute(sectionModel.headerHeight ?? CGFloat.leastNormalMagnitude))
        let headerItem = NSCollectionLayoutBoundarySupplementaryItem.init(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .topTrailing)
        laySection.boundarySupplementaryItems = [headerItem]
        let backItem = NSCollectionLayoutDecorationItem.background(elementKind: "background")
        backItem.contentInsets = NSDirectionalEdgeInsets.init(top: 0, leading: PTAppBaseConfig.share.defaultViewSpace, bottom: 0, trailing: PTAppBaseConfig.share.defaultViewSpace)
        laySection.decorationItems = [backItem]

        return laySection
    }

    private lazy var viewCollection : UICollectionView = {
        let view = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: self.comboLayout())
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = .clear
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
        
        if viewDismissBlock != nil
        {
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
            self.navigationController?.dismiss(animated: true){
                if self.viewDismissBlock != nil
                {
                    self.viewDismissBlock!()
                }
            }
        })

        view.addSubview(viewCollection)
        viewCollection.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
#if POOTOOLS_NAVBARCONTROLLER
            make.top.equalTo(self.zx_navBar!.snp.bottom)
#else
            make.top.equalToSuperview()
#endif
        }
        
        showDetail()
        
        var haveTracking:Bool? = false
        for ( _ ,value) in permissions!.enumerated()
        {
#if canImport(Permission)
            if value.type == .tracking
            {
                haveTracking = true
                break
            }
#endif
        }
        
        if haveTracking!
        {
            if #available(iOS 14.5, *) {
#if canImport(TrackingPermission)
                Permission.tracking.request {
                    self.trackingRequest = true
                }
#endif
            }
            else
            {
                showRequestFunction()
            }
        }
        else
        {
            showRequestFunction()
        }
    }
    
    func showRequestFunction()
    {
        permissions?.enumerated().forEach({ index,value in
#if canImport(Permission)
            switch value.type {
            case .camera:
#if canImport(CameraPermission)
                Permission.camera.request {
                    self.showDetail()
                }
#endif
            case .photoLibrary:
#if canImport(PhotoLibraryPermission)
                Permission.photoLibrary.request {
                    self.showDetail()
                }
#endif
            case .calendar:
#if canImport(CalendarPermission)
                Permission.calendar.request {
                    self.showDetail()
                }
#endif
            case .reminders:
#if canImport(RemindersPermission)
                Permission.reminders.request {
                    self.showDetail()
                }
#endif
            case .notification:
#if canImport(NotificationPermission)
                Permission.notification.request {
                    self.showDetail()
                }
#endif
            case .locationWhenInUse:
#if canImport(LocationWhenInUsePermission)
                Permission.locationWhenInUse.request {
                    self.showDetail()
                }
#endif
            case .health:
#if canImport(HealthPermission)
                Permission.health.request {
                    self.showDetail()
                }
#endif
            case .speech:
#if canImport(SpeechPermission)
                Permission.speech.request {
                    self.showDetail()
                }
#endif
            case .faceID:
#if canImport(FaceIDPermission)
                Permission.faceID.request {
                    self.showDetail()
                }
#endif
            default:
                break
            }
#endif
        })

    }
    
    func showDetail()
    {
        mSections.removeAll()
        
        var permissionRows = [PTRows]()
        permissions?.enumerated().forEach({ index,value in
            let row = PTRows.init(title: value.name,content: value.desc,cls: PTPermissionCell.self,ID: PTPermissionCell.ID,dataModel: value)
            permissionRows.append(row)
        })
        
        let section = PTSection.init(headerCls:PTPermissionHeader.self,headerID:PTPermissionHeader.ID,headerHeight:PTPermissionHeader.cellHeight(),rows: permissionRows)
        mSections.append(section)
        viewCollection.pt_register(by: mSections)
        viewCollection.reloadData()
    }
}

extension PTPermissionViewController : UICollectionViewDelegate,UICollectionViewDataSource
{
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        mSections.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mSections[section].rows.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let itemSec = mSections[indexPath.section]
        if kind == UICollectionView.elementKindSectionHeader
        {
            if itemSec.headerID == PTPermissionHeader.ID
            {
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: itemSec.headerID!, for: indexPath) as! PTPermissionHeader
                return header
            }
            return UICollectionReusableView()
        }
        else
        {
            return UICollectionReusableView()
        }
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let itemSec = mSections[indexPath.section]
        let itemRow = itemSec.rows[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTPermissionCell
        cell.cellModel  = (itemRow.dataModel as! PTPermissionModel)
#if canImport(Permission)
        cell.cellButtonTapBlock = { type in
            switch type {
            case .tracking:
#if canImport(TrackingPermission)
                if #available(iOS 14.5, *) {
                    Permission.tracking.request {
                        self.showDetail()
                    }
                }
#endif
            case .camera:
#if canImport(CameraPermission)
                Permission.camera.request {
                    self.showDetail()
                }
#endif
            case .photoLibrary:
#if canImport(PhotoLibraryPermission)
                Permission.photoLibrary.request {
                    self.showDetail()
                }
#endif
            case .calendar:
#if canImport(CalendarPermission)
                Permission.calendar.request {
                    self.showDetail()
                }
#endif
            case .reminders:
#if canImport(RemindersPermission)
                Permission.reminders.request {
                    self.showDetail()
                }
#endif
            case .notification:
#if canImport(NotificationPermission)
                Permission.notification.request {
                    self.showDetail()
                }
#endif
            case .locationWhenInUse:
#if canImport(LocationWhenInUsePermission)
                Permission.locationWhenInUse.request {
                    self.showDetail()
                }
#endif
            case .health:
#if canImport(HealthPermission)
                Permission.health.request {
                    self.showDetail()
                }
#endif
            case .speech:
#if canImport(SpeechPermission)
                Permission.speech.request {
                    self.showDetail()
                }
#endif
            case .faceID:
#if canImport(FaceIDPermission)
                Permission.faceID.request {
                    self.showDetail()
                }
#endif
            default:
                break
            }
        }
#endif
        return cell
    }
    
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    }
}
