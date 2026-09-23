//
//  PTMediaLibAlbumListViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 28/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import Photos
import AttributedString
import SafeSFSymbols

#if SWIFT_PACKAGE
import ptools
import PooToolsImagePicker
import PTCameraPermission
#endif

class PTMediaLibAlbumListViewController: PTBaseViewController {

    var albumList = [PTMediaLibListModel]()
    var selectedAlbum: PTMediaLibListModel?

    var selectedModelHandler:((PTMediaLibListModel) -> Void)?
    
    private lazy var dismissButton:PTBaseButton = {
        let view = PTBaseButton(type: .custom)
        view.setImage(PTMediaLibUIConfig.share.ablumListBackImage, for: .normal)
        view.addActionHandlers { sender in
            self.navigationController?.popViewController(animated: true)
        }
        view.bounds = CGRectMake(0, 0, PTAppBaseConfig.share.navBarButtonSize, PTAppBaseConfig.share.navBarButtonSize)
        return view
    }()
    
    private lazy var collectionView : PTCollectionView = {
                
        let emptyConfig = PTEmptyDataViewConfig()
        emptyConfig.image = PTMediaLibUIConfig.share.albumEmptyImage
        emptyConfig.mainTitleAtt = """
            \(wrap: .embedding("""
            \(PTMediaLibUIConfig.share.albumEmptyTitle,.foreground(PTMediaLibUIConfig.share.themeColor),.font(PTMediaLibUIConfig.share.albumEmptyTitleFont),.paragraph(.alignment(.center)))
            """))
            """
        emptyConfig.secondaryEmptyAtt = """
            \(wrap: .embedding("""
            \(PTMediaLibUIConfig.share.albumEmptySubDesc,.foreground(PTMediaLibUIConfig.share.themeColor),.font(PTMediaLibUIConfig.share.albumEmptyDescFont),.paragraph(.alignment(.center)))
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
        view.cellInCollection = { collection,sectionModel,indexPath in
            if let itemRow = sectionModel.rows?[indexPath.row],let cellModel = itemRow.dataModel as? PTMediaLibListModel,let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.reuseID, for: indexPath) as? PTMediaLibAlbumCell {
                cell.albumModel = cellModel
                cell.selectedButton.isSelected = (cellModel.title == self.selectedAlbum?.title)
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

    fileprivate lazy var fakeNav:PTNavBar = {
        let view = PTNavBar()
        view.isFakeNav = true
        return view
    }()
    
    fileprivate lazy var navTitle:UILabel = {
        let view = UILabel()
        view.font = PTAppBaseConfig.share.navTitleFont
        view.textColor = PTAppBaseConfig.share.navTitleTextColor
        view.textAlignment = .center
        // English: Keep the navigation title single-line so its intrinsic width is stable.
        // Español: Mantiene el título de navegación en una sola línea para estabilizar su ancho intrínseco.
        // 中文：导航标题使用单行，保证 intrinsic width 稳定。
        view.numberOfLines = 1
        view.lineBreakMode = .byTruncatingTail
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
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
        navigationController?.navigationBar.isHidden = true
        changeStatusBar(type: .Dark)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
                        
        view.addSubviews([collectionView,fakeNav])
        let collectionInset_Top:CGFloat = CGFloat.kNavBarHeight
        let collectionInset_Bottom:CGFloat = CGFloat.kTabbarSaveAreaHeight
        
        collectionView.contentCollectionView.contentInsetAdjustmentBehavior = .never
        collectionView.contentCollectionView.contentInset.top = collectionInset_Top
        collectionView.contentCollectionView.contentInset.bottom = collectionInset_Bottom
        
        collectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview().inset(self.sheetViewController?.options.pullBarHeight ?? 0)
        }

        fakeNav.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(CGFloat.kNavBarHeight)
            make.top.equalToSuperview().inset(self.sheetViewController?.options.pullBarHeight ?? 0)
        }
        
        fakeNavSet()
        

        guard let selectedAlbum else {
            return
        }
        if selectedAlbum.models.isEmpty {
            selectedAlbum.refetchPhotos()
        }
        
        UIScreen.pt.detectScreenShot { type in
            switch type {
            case .Normal:
                PTGCDManager.shared.runOnMain {
                    self.loadAlbumList()
                }
            case .Video:
                break
            }
        }
        
        loadAlbumList()
    }
    
    func fakeNavSet() {
        fakeNav.setLeftButtons([dismissButton])
        // English: Use the measured title mode so the title is centered in the fake bar, not stretched between buttons.
        // Español: Usa el modo de título medido para centrarlo en la barra falsa, sin estirarlo entre los botones.
        // 中文：使用测量标题模式，让标题在伪导航栏中心对齐，而不是在按钮之间被拉伸。
        fakeNav.titleViewMode = .auto
        navTitle.text = PTMediaLibUIConfig.share.albumListNavName
        fakeNav.titleView = navTitle
    }
    
    func loadAlbumList() {
        let options = selectedAlbum?.selectionOptions ?? .current()
        PTMediaLibManager.getPhotoAlbumList(options: options) { models in
            self.albumList.removeAll()
            self.albumList.append(contentsOf: models)
            
            let rows = models.map {
                let row = PTRows(dataModel: $0)
                row.cellClass = PTMediaLibAlbumCell.self
                return row
            }
            let section = PTSection(rows:rows)
            self.collectionView.showCollectionDetail(collectionData: [section])
        }
    }
}
