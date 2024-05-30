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

    var albumList =  [PTMediaLibListModel]()
    var selectedAlbum:PTMediaLibListModel!

    var selectedModelHandler:((PTMediaLibListModel)->Void)?
    
    private lazy var dismissButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage("❌".emojiToImage(emojiFont: .appfont(size: 20)), for: .normal)
        view.addActionHandlers { sender in
            self.returnFrontVC()
        }
        return view
    }()
    
    private lazy var collectionView : PTCollectionView = {
        
        let pickerConfig = PTMediaLibConfig.share
        
        let emptyConfig = PTEmptyDataViewConfig()
        emptyConfig.image = UIImage(.exclamationmark.triangle)
        emptyConfig.mainTitleAtt = """
            \(wrap: .embedding("""
            \("PT Alert Opps".localized(),.foreground(pickerConfig.themeColor),.font(.appfont(size: 20,bold: true)),.paragraph(.alignment(.center)))
            """))
            """
        emptyConfig.secondaryEmptyAtt = """
            \(wrap: .embedding("""
            \("PT Photo picker empty media".localized(),.foreground(pickerConfig.themeColor),.font(.appfont(size: 18)),.paragraph(.alignment(.center)))
            """))
            """
        
        let config = PTCollectionViewConfig()
        config.viewType = .Normal
        config.itemOriginalX = 0
        config.itemHeight = 88
        config.showEmptyAlert = true
        config.emptyViewConfig = emptyConfig

        let view = PTCollectionView(viewConfig: config)
        view.cellInCollection = { collection,sectionModel,indexPath in
            let config = PTMediaLibConfig.share
            let itemRow = sectionModel.rows[indexPath.row]
            let cellModel = (itemRow.dataModel as! PTMediaLibListModel)
            let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTMediaLibAlbumCell
            cell.albumModel = cellModel
            cell.selectedButton.isSelected = (cellModel.title == self.selectedAlbum.title)
            return cell
        }
        view.collectionDidSelect = { collection,sectionModel,indexPath in
            let itemRow = sectionModel.rows[indexPath.row]
            let cellModel = (itemRow.dataModel as! PTMediaLibListModel)

            if self.selectedModelHandler != nil {
                self.selectedModelHandler!(cellModel)
                self.returnFrontVC()
            }
        }
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
#else
        PTBaseNavControl.GobalNavControl(nav: navigationController!,navColor: PTAppBaseConfig.share.navBackgroundColor)
#endif
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_navTitle = "PT Photo picker album list title".localized()
        self.zx_navTitleColor = PTAppBaseConfig.share.navTitleTextColor
        self.zx_navTitleFont = PTAppBaseConfig.share.navTitleFont
        self.zx_navBar?.addSubview(dismissButton)
        dismissButton.snp.makeConstraints { make in
            make.size.equalTo(34)
            make.bottom.equalToSuperview().inset(5)
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
        
#else
        dismissButton.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: dismissButton)
        
        self.title = "PT Photo picker album list title".localized()
#endif
        
        view.addSubviews([collectionView])
        collectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview()
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
    
    func loadAlbumList() {
        
        PTMediaLibManager.getPhotoAlbumList(ascending: PTMediaLibUIConfig.share.sortAscending, allowSelectImage: PTMediaLibConfig.share.allowSelectImage, allowSelectVideo: PTMediaLibConfig.share.allowSelectVideo) { models in
            albumList.removeAll()
            albumList.append(contentsOf: models)
            
            var rows = [PTRows]()
            models.enumerated().forEach { index,value in
                let row = PTRows(cls:PTMediaLibAlbumCell.self,ID: PTMediaLibAlbumCell.ID,dataModel: value)
                rows.append(row)
            }
            
            let section = PTSection(rows:rows)
            collectionView.showCollectionDetail(collectionData: [section])
        }
    }
}
