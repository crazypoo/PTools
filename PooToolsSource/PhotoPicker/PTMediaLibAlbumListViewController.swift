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
#if canImport(PToolsUIFoundation)
import PToolsUIFoundation
#endif
#if SWIFT_PACKAGE
import PToolsSymbols
#endif

#if SWIFT_PACKAGE
import ptools
import PooToolsImagePicker
import PTCameraPermission
#endif

@MainActor
class PTMediaLibAlbumListViewController: PTBaseViewController {

    var albumList = [PTMediaLibListModel]()
    var selectedAlbum: PTMediaLibListModel?

    var selectedModelHandler:((PTMediaLibListModel) -> Void)?
    private var lastAdaptiveLayoutSignature: String?
    private let albumRepository: PTMediaAlbumRepository
    
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
        config.contentBottomSpace = max(0, view.safeAreaInsets.bottom)

        let view = PTCollectionView(viewConfig: config)
        view.cellInCollection = { [weak self] collection,sectionModel,indexPath in
            if let itemRow = sectionModel.rows?[indexPath.row],let cellModel = itemRow.dataModel as? PTMediaLibListModel,let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.reuseID, for: indexPath) as? PTMediaLibAlbumCell {
                cell.albumModel = cellModel
                cell.selectedButton.isSelected = (cellModel.collection.localIdentifier == self?.selectedAlbum?.collection.localIdentifier)
                return cell
            }
            return nil
        }
        view.collectionDidSelect = { [weak self] collection,sectionModel,indexPath in
            if let itemRow = sectionModel.rows?[indexPath.row],let cellModel = itemRow.dataModel as? PTMediaLibListModel {
                if self?.selectedModelHandler != nil {
                    self?.navigationController?.popViewController(animated: true)
                }
                self?.selectedModelHandler?(cellModel)
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
        albumRepository = PTMediaAlbumRepository(options: albumList.selectionOptions)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        changeStatusBar(type: .Dark)
        albumRepository.startObserving()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        albumRepository.stopObserving()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
                        
        view.addSubviews([collectionView,fakeNav])
        let collectionInset_Top:CGFloat = CGFloat.kNavBarHeight
        let collectionInset_Bottom:CGFloat = max(0, view.safeAreaInsets.bottom)
        
        collectionView.contentCollectionView.contentInsetAdjustmentBehavior = .never
        collectionView.contentCollectionView.contentInset.top = collectionInset_Top
        collectionView.contentCollectionView.contentInset.bottom = collectionInset_Bottom
        
        collectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview()
        }

        fakeNav.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(CGFloat.kNavBarHeight)
            make.top.equalToSuperview().inset(CGFloat.statusBarHeight() - (self.sheetViewController?.options.pullBarHeight ?? 0) / 2)
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
        albumRepository.onAlbumsChange = { [weak self] models in
            self?.applyAlbumList(models)
        }
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let region = PTAdaptiveVisibleRegionResolver.region(for: view)
        let horizontalVisibleRect = CGRect(x: region.visibleRect.minX,
                                            y: view.bounds.minY,
                                            width: region.visibleRect.width,
                                            height: view.bounds.height).intersection(view.bounds)
        let visibleRect = horizontalVisibleRect.isEmpty ? view.bounds : horizontalVisibleRect
        let layoutSignature = "\(region.signature)|\(visibleRect.integral)"
        if layoutSignature != lastAdaptiveLayoutSignature {
            lastAdaptiveLayoutSignature = layoutSignature
            // English: Keep album rows inside the visible pane while the fake navigation bar remains full-height.
            // Español: Mantiene las filas de álbum dentro del panel visible mientras la barra falsa conserva toda la altura.
            // 中文：让相册列表行位于可视面板内，同时保留伪导航栏的完整高度背景。
            collectionView.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(visibleRect.minX)
                make.right.equalToSuperview().inset(max(0, view.bounds.width - visibleRect.maxX))
                make.top.equalToSuperview().inset(self.sheetViewController?.options.pullBarHeight ?? 0)
                make.bottom.equalToSuperview()
            }
            // English: Give the fake navigation bar the same local pane as its title and back button.
            // Español: Da a la barra falsa el mismo panel local que usan su título y su botón de regreso.
            // 中文：让伪导航栏与标题和返回按钮使用同一个局部可视面板。
            fakeNav.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(visibleRect.minX)
                make.right.equalToSuperview().inset(max(0, view.bounds.width - visibleRect.maxX))
                make.height.equalTo(CGFloat.kNavBarHeight)
                make.top.equalToSuperview().inset(CGFloat.statusBarHeight() - (self.sheetViewController?.options.pullBarHeight ?? 0) / 2)
            }
        }
        let topInset = max(0, fakeNav.frame.maxY)
        let bottomInset = max(0, view.safeAreaInsets.bottom)
        var inset = collectionView.contentCollectionView.contentInset
        var indicatorInset = collectionView.contentCollectionView.verticalScrollIndicatorInsets
        if inset.top != topInset || inset.bottom != bottomInset {
            inset.top = topInset
            inset.bottom = bottomInset
            collectionView.contentCollectionView.contentInset = inset
        }
        if indicatorInset.bottom != bottomInset {
            indicatorInset.bottom = bottomInset
            collectionView.contentCollectionView.verticalScrollIndicatorInsets = indicatorInset
        }
    }
    
    func loadAlbumList() {
        albumRepository.albums { [weak self] models in
            self?.applyAlbumList(models)
        }
    }

    // English: Render the latest repository snapshot without letting an older fetch overwrite it.
    // Español: Renderiza la instantánea más reciente del repositorio sin permitir que una consulta antigua la sobrescriba.
    // 中文：只渲染 Repository 的最新快照，避免旧查询覆盖新相册列表。
    private func applyAlbumList(_ models: [PTMediaLibListModel]) {
        albumList = models
        let rows = models.map {
            let row = PTRows(dataModel: $0)
            row.cellClass = PTMediaLibAlbumCell.self
            return row
        }
        collectionView.showCollectionDetail(collectionData: [PTSection(rows: rows)])
    }
}
