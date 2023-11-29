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

class PTMediaLibAlbumListViewController: PTBaseViewController {

    var albumList =  [PTMediaLibListModel]()
    var selectedAlbum:PTMediaLibListModel!

    var selectedModelHandler:((PTMediaLibListModel)->Void)?
    
    private lazy var dismissButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage("❌".emojiToImage(emojiFont: .appfont(size: 18)), for: .normal)
        view.addActionHandlers { sender in
            self.returnFrontVC()
        }
        return view
    }()
    
    private lazy var collectionView : PTCollectionView = {
        
        let config = PTCollectionViewConfig()
        config.viewType = .Normal
        config.itemOriginalX = 0
        config.itemHeight = 88

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
        self.selectedAlbum = albumList
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_navBar?.addSubview(dismissButton)
        dismissButton.snp.makeConstraints { make in
            make.size.equalTo(34)
            make.bottom.equalToSuperview().inset(5)
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
#else
        dismissButton.frame = CGRectMake(0, 0, 34, 34)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: dismissButton)
#endif
        
        PHPhotoLibrary.shared().register(self)
        
        view.addSubviews([collectionView])
        collectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
#if POOTOOLS_NAVBARCONTROLLER
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
#else
            make.top.equalToSuperview()
#endif
        }
        
        if self.selectedAlbum.models.isEmpty {
            self.selectedAlbum.refetchPhotos()
        }
        
        loadAlbumList()
    }
    
    func loadAlbumList() {
        
        PTMeidaLibManager.getPhotoAlbumList(ascending: PTMediaLibUIConfig.share.sortAscending, allowSelectImage: PTMediaLibConfig.share.allowSelectImage, allowSelectVideo: PTMediaLibConfig.share.allowSelectVideo) { models in
            self.albumList.removeAll()
            self.albumList.append(contentsOf: models)
            
            var rows = [PTRows]()
            models.enumerated().forEach { index,value in
                let row = PTRows(cls:PTMediaLibAlbumCell.self,ID: PTMediaLibAlbumCell.ID,dataModel: value)
                rows.append(row)
            }
            
            let section = PTSection(rows:rows)
            self.collectionView.showCollectionDetail(collectionData: [section])
        }
    }
}
