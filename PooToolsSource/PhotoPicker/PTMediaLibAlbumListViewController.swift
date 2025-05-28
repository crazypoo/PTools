//
//  PTMediaLibAlbumListViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 28/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif
import SnapKit
import Photos
import SwifterSwift
import AttributedString
import SafeSFSymbols

class PTMediaLibAlbumListViewController: PTBaseViewController {

    var albumList = [PTMediaLibListModel]()
    var selectedAlbum:PTMediaLibListModel!

    var selectedModelHandler:((PTMediaLibListModel)->Void)?
    
    private lazy var dismissButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(PTMediaLibConfig.share.ablumListBackImage, for: .normal)
        view.addActionHandlers { sender in
            self.navigationController?.popViewController(animated: true)
        }
        return view
    }()
    
    private lazy var collectionView : PTCollectionView = {
        
        let pickerConfig = PTMediaLibConfig.share
        
        let emptyConfig = PTEmptyDataViewConfig()
        emptyConfig.image = UIImage(.exclamationmark.triangle)
        emptyConfig.mainTitleAtt = """
            \(wrap: .embedding("""
            \(PTMediaLibConfig.share.emptyTitle,.foreground(pickerConfig.themeColor),.font(.appfont(size: 20,bold: true)),.paragraph(.alignment(.center)))
            """))
            """
        emptyConfig.secondaryEmptyAtt = """
            \(wrap: .embedding("""
            \(PTMediaLibConfig.share.emptySubDesc,.foreground(pickerConfig.themeColor),.font(.appfont(size: 18)),.paragraph(.alignment(.center)))
            """))
            """
        
        let config = PTCollectionViewConfig()
        config.viewType = .Normal
        config.itemOriginalX = 0
        config.itemHeight = 88
        config.showEmptyAlert = true
        config.emptyViewConfig = emptyConfig
        config.contentBottomSpace = CGFloat.kTabbarSaveAreaHeight

        let view = PTCollectionView(viewConfig: config)
        view.registerClassCells(classs: [PTMediaLibAlbumCell.ID:PTMediaLibAlbumCell.self])
        view.cellInCollection = { collection,sectionModel,indexPath in
            let config = PTMediaLibConfig.share
            if let itemRow = sectionModel.rows?[indexPath.row],let cellModel = itemRow.dataModel as? PTMediaLibListModel,let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTMediaLibAlbumCell {
                cell.albumModel = cellModel
                cell.selectedButton.isSelected = (cellModel.title == self.selectedAlbum.title)
                return cell
            }
            return nil
        }
        view.collectionDidSelect = { collection,sectionModel,indexPath in
            if let itemRow = sectionModel.rows?[indexPath.row],let cellModel = itemRow.dataModel as? PTMediaLibListModel {
                if self.selectedModelHandler != nil {
                    self.navigationController?.popViewController(animated: true)
                }
                self.selectedModelHandler?(cellModel)
            }
        }
        return view
    }()

    fileprivate lazy var fakeNav:UIView = {
        let view = UIView()
        return view
    }()
    
    fileprivate lazy var navTitle:UILabel = {
        let view = UILabel()
        view.font = PTAppBaseConfig.share.navTitleFont
        view.textColor = PTAppBaseConfig.share.navTitleTextColor
        view.textAlignment = .center
        view.numberOfLines = 0
        return view
    }()

    init(albumList: PTMediaLibListModel) {
        selectedAlbum = albumList
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_hideBaseNavBar = true
#else
        navigationController?.navigationBar.isHidden = true
#endif
    }

    override func viewDidLoad() {
        super.viewDidLoad()
                        
        view.addSubviews([fakeNav,collectionView])
        fakeNav.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(CGFloat.kNavBarHeight)
            make.top.equalToSuperview().inset(self.sheetViewController?.options.pullBarHeight ?? 24)
        }
        
        fakeNavSet()
        
        collectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(self.fakeNav.snp.bottom)
        }
        
        if selectedAlbum.models.isEmpty {
            selectedAlbum.refetchPhotos()
        }
        
        UIScreen.pt.detectScreenShot { type in
            switch type {
            case .Normal:
                self.loadAlbumList()
            case .Video:
                break
            }
        }
        
        loadAlbumList()
    }
    
    func fakeNavSet() {
        fakeNav.addSubviews([dismissButton,navTitle])
        dismissButton.snp.makeConstraints { make in
            make.size.equalTo(34)
            make.bottom.equalToSuperview().inset(5)
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
        
        navTitle.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.left.lessThanOrEqualTo(self.dismissButton.snp.right).offset(7.5)
        }
        navTitle.text = PTMediaLibConfig.share.albumListNavName
    }
    
    func loadAlbumList() {
        
        PTMediaLibManager.getPhotoAlbumList(ascending: PTMediaLibUIConfig.share.sortAscending, allowSelectImage: PTMediaLibConfig.share.allowSelectImage, allowSelectVideo: PTMediaLibConfig.share.allowSelectVideo,allowSelectLivePhotoOnly: PTMediaLibConfig.share.allowOnlySelectLivePhoto/*,allowSelectRegularImageOnly: PTMediaLibConfig.share.allowOnlySelectRegularImage*/) { models in
            albumList.removeAll()
            albumList.append(contentsOf: models)
            
            let rows = models.map { PTRows(ID: PTMediaLibAlbumCell.ID,dataModel: $0) }
            let section = PTSection(rows:rows)
            collectionView.showCollectionDetail(collectionData: [section])
        }
    }
}
