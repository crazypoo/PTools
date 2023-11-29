//
//  PTMediaLibViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 28/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift
import SnapKit
import Photos
import Combine

func markSelected(source: inout [PTMediaModel], selected: inout [PTMediaModel]) {
    guard !selected.isEmpty else {
        return
    }
    
    var selIds: [String: Bool] = [:]
    var selEditImage: [String: UIImage] = [:]
    var selEditModel: [String: PTEditModel] = [:]
    var selIdAndIndex: [String: Int] = [:]
    
    for (index, m) in selected.enumerated() {
        selIds[m.ident] = true
        selEditImage[m.ident] = m.editImage
        selEditModel[m.ident] = m.editImageModel
        selIdAndIndex[m.ident] = index
    }
    
    source.forEach { m in
        if selIds[m.ident] == true {
            m.isSelected = true
            m.editImage = selEditImage[m.ident]
            m.editImageModel = selEditModel[m.ident]
            selected[selIdAndIndex[m.ident]!] = m
        } else {
            m.isSelected = false
        }
    }
}

func canAddModel(_ model: PTMediaModel, currentSelectCount: Int, sender: UIViewController?, showAlert: Bool = true) -> Bool {
    let config = PTMediaLibConfig.share
    
    guard config.canSelectAsset?(model.asset) ?? true else {
        return false
    }
    
    if currentSelectCount >= config.maxSelectCount {
        if showAlert {
            PTAlertTipControl.present(title: "Opps!",subtitle:"选择数量大于\(config.maxSelectCount)",icon:.Error,style:.Normal)
        }
        return false
    }
    
    if currentSelectCount > 0,
       !config.allowMixSelect,
       model.type == .video {
        return false
    }
    
    guard model.type == .video else {
        return true
    }
    
    if model.second > config.maxSelectVideoDuration {
        if showAlert {
            PTAlertTipControl.present(title: "Opps!",subtitle:"视频时间大于\(config.maxSelectVideoDuration)",icon:.Error,style:.Normal)
        }
        return false
    }
    
    if model.second < config.minSelectVideoDuration {
        if showAlert {
            PTAlertTipControl.present(title: "Opps!",subtitle:"视频时间小于\(config.minSelectVideoDuration)",icon:.Error,style:.Normal)
        }
        return false
    }
    
    guard config.minSelectVideoDataSize > 0 || config.maxSelectVideoDataSize != .greatestFiniteMagnitude,
          let size = model.dataSize else {
        return true
    }
    
    if size > config.maxSelectVideoDataSize {
        if showAlert {
            let value = Int(round(config.maxSelectVideoDataSize / 1024))
            PTAlertTipControl.present(title: "Opps!",subtitle:"视频大小大于\(String(value))",icon:.Error,style:.Normal)
        }
        return false
    }
    
    if size < config.minSelectVideoDataSize {
        if showAlert {
            let value = Int(round(config.minSelectVideoDataSize / 1024))
            PTAlertTipControl.present(title: "Opps!",subtitle:"视频大小小于\(String(value))",icon:.Error,style:.Normal)
        }
        return false
    }
    
    return true
}

func downloadAssetIfNeed(model: PTMediaModel, sender: UIViewController?, completion: @escaping (() -> Void)) {
    let config = PTMediaLibConfig.share
    guard model.type == .video,
          model.asset.pt.isInCloud,
          config.downloadVideoBeforeSelecting else {
        completion()
        return
    }

    var requestAssetID: PHImageRequestID?
        
    var counts:Int = 0
    Timer.scheduledTimer(timeInterval: 1, repeats: true) { timer in
        counts += 1
        if counts >= Int(Network.share.netRequsetTime) {
            PTAlertTipControl.present(title: "Opps!",subtitle:"获取超时",icon:.Error,style:.Normal)

            if let requestAssetID = requestAssetID {
                PHImageManager.default().cancelImageRequest(requestAssetID)
            }
            
            timer.invalidate()
        }
    }
    
    requestAssetID = PTMeidaLibManager.fetchVideo(for: model.asset, completion: { _, _, isDegraded in
        
        if !isDegraded {
            completion()
        }
    })
}


public class PTMediaLibView:UIView {
        
    /// Callback for photos that failed to parse
    /// block params
    ///  - params1: failed assets.
    ///  - params2: index for asset
    public var selectImageRequestErrorBlock: (([PHAsset], [Int]) -> Void)?

    private lazy var fetchImageQueue = OperationQueue()

    private var isSelectOriginal = false
    /// Success callback
    /// block params
    ///  - params1: result models
    ///  - params2: is full image
    public var selectImageBlock: (([PTResultModel], Bool) -> Void)?

    var showCameraCell: Bool {
        if PTMediaLibConfig.share.allowTakePhotoInLibrary, currentAlbum!.isCameraRoll {
            return true
        }
        return false
    }

    private var videoEdit: PTVideoEdit?
    fileprivate var cancellables = Set<AnyCancellable>()
    
    var selectedCount:((Int)->Void)?
    
    private var totalModels = [PTMediaModel]()
    var selectedModel: [PTMediaModel] = []

    var currentAlbum:PTMediaLibListModel? {
        didSet {
            if currentAlbum != nil {
                let config = PTMediaLibConfig.share
                totalModels.removeAll()
                var rows = [PTRows]()
                var totalPhotos = PTMeidaLibManager.fetchPhoto(in: currentAlbum!.result, ascending: false, allowSelectImage: config.allowSelectImage, allowSelectVideo: config.allowSelectVideo,limitCount: config.maxPreviewCount)
                markSelected(source: &totalPhotos, selected: &self.selectedModel)
                self.totalModels.append(contentsOf: totalPhotos)
                self.totalModels.enumerated().forEach { index,value in
                    let row = PTRows(cls:PTMediaLibCell.self,ID: PTMediaLibCell.ID,dataModel: value)
                    rows.append(row)
                }
                
                if self.showCameraCell {
                    let row = PTRows(cls:PTFusionCell.self,ID: PTFusionCell.ID)
                    rows.insert(row, at: 0)
                }
                let section = PTSection(rows: rows)
                self.collectionView.showCollectionDetail(collectionData: [section])
            }
        }
    }
    
    private lazy var collectionView : PTCollectionView = {
        
        let config = PTCollectionViewConfig()
        config.viewType = .Gird
        config.itemOriginalX = 0
        config.cellLeadingSpace = 1
        config.rowCount = 3
        let itemHeight:CGFloat = (CGFloat.kSCREEN_WIDTH - CGFloat(config.rowCount - 1) * config.cellLeadingSpace) / CGFloat(config.rowCount)
        config.itemHeight = itemHeight

        let view = PTCollectionView(viewConfig: config)
        view.cellInCollection = { collection,sectionModel,indexPath in
            let config = PTMediaLibConfig.share

            let itemRow = sectionModel.rows[indexPath.row]
            if itemRow.ID == PTMediaLibCell.ID {
                let cellModel = (itemRow.dataModel as! PTMediaModel)
                let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTMediaLibCell
                cell.cellModel = cellModel
                cell.selectedBlock = { [weak self] isSelected in
                    guard let `self` = self else { return }

                    if !cellModel.isSelected {
                        guard canAddModel(cellModel, currentSelectCount: self.selectedModel.count, sender: PTUtils.getCurrentVC()) else { return }
                        downloadAssetIfNeed(model: cellModel, sender: PTUtils.getCurrentVC()) {
                            if !self.shouldDirectEdit(cellModel) {
                                cellModel.isSelected = true
                                self.selectedModel.append(cellModel)
                                isSelected(true)
                                config.didSelectAsset?(cellModel.asset)
                                self.refreshCellIndex()
                            }
                        }
                    } else {
                        cellModel.isSelected = false
                        self.selectedModel.removeAll(where: { $0 == cellModel })
                        isSelected(false)
                        config.didDeselectAsset?(cellModel.asset)
                        self.refreshCellIndex()
                    }
                }
                
                if let index = self.selectedModel.firstIndex(where: { $0 == cellModel }) {
                    self.setCellIndex(cell, index: index + 1)
                } else {
                    cell.selectButton.normalTitle = ""
                }
                
                self.setCellMaskView(cell, isSelected: cellModel.isSelected, model: cellModel)

                cell.editButton.addActionHandlers { sender in
                    switch cellModel.type {
                    case .video:
                        let _ = PTMeidaLibManager.fetchAVAsset(forVideo: cellModel.asset) { avAsset, parma in
                            if avAsset != nil {
                                let controller = PTVideoEditorVideoEditorViewController(asset: avAsset!, videoEdit: self.videoEdit)
                                controller.onEditCompleted
                                    .sink {  editedPlayerItem, videoEdit in
                                        self.videoEdit = videoEdit
                                        
                                        for (index, selM) in self.selectedModel.enumerated() {
                                            if cellModel == selM {
                                                selM.avEditorOutputItem = editedPlayerItem
                                                self.selectedModel[index] = selM
                                                self.requestSelectPhoto()
                                                break
                                            }
                                        }
                                    }
                                    .store(in: &self.cancellables)
                                let nav = PTBaseNavControl(rootViewController: controller)
                                nav.modalPresentationStyle = .fullScreen
                                PTUtils.getCurrentVC().present(nav, animated: true)
                            }
                        }
                    default:
                        PTMeidaLibManager.fetchImage(for: cellModel.asset, size: cellModel.previewSize) { image, isDegraded in
                            if !isDegraded {
                                if let image = image {
                                    let vc = PTEditImageViewController(readyEditImage: image)
                                    vc.editFinishBlock = { ei ,editImageModel in
                                        cellModel.isSelected = true
                                        cellModel.editImage = ei
                                        cellModel.editImageModel = editImageModel
                                        PTMediaLibConfig.share.didSelectAsset?(cellModel.asset)
                                        self.requestSelectPhoto()
                                    }
                                    let nav = PTBaseNavControl(rootViewController: vc)
                                    nav.modalPresentationStyle = .fullScreen
                                    PTUtils.getCurrentVC().present(nav, animated: true)
                                }
                            }
                        }
                    }
                }
                return cell
            } else {
                let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTFusionCell
                cell.contentView.backgroundColor = .random
                return cell
            }
        }
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        loadMedia()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func loadMedia() {
        
        totalModels.removeAll()
        
        let config = PTMediaLibConfig.share
        PTMeidaLibManager.getCameraRollAlbum(allowSelectImage: config.allowSelectImage, allowSelectVideo: config.allowSelectVideo) { model in
            var totalPhotos = PTMeidaLibManager.fetchPhoto(in: model.result, ascending: false, allowSelectImage: config.allowSelectImage, allowSelectVideo: config.allowSelectVideo,limitCount: config.maxPreviewCount)
            markSelected(source: &totalPhotos, selected: &self.selectedModel)
            self.currentAlbum = model
        }
    }
    
    private func refreshCellIndex() {
//        let config = ZLPhotoConfiguration.default()
//        let uiConfig = ZLPhotoUIConfiguration.default()
//
//        let cameraIsEnable = arrSelectedModels.count < config.maxSelectCount
//        cameraBtn.alpha = cameraIsEnable ? 1 : 0.3
//        cameraBtn.isEnabled = cameraIsEnable
//
//        let showIndex = config.showSelectedIndex
//        let showMask = uiConfig.showSelectedMask || uiConfig.showInvalidMask
//
//        guard showIndex || showMask else {
//            return
//        }
        
        let visibleIndexPaths = collectionView.contentCollectionView.indexPathsForVisibleItems
        
        visibleIndexPaths.forEach { indexPath in
            guard let cell = collectionView.contentCollectionView.cellForItem(at: indexPath) as? PTMediaLibCell else {
                return
            }
            let m = totalModels[indexPath.row]
            
            var idx = 0
            var isSelected = false
            for (index, selM) in selectedModel.enumerated() {
                if m == selM {
                    idx = index + 1
                    isSelected = true
                    break
                }
            }
//            if showIndex {
                setCellIndex(cell, index: idx)
//            }
//            if showMask {
                setCellMaskView(cell, isSelected: isSelected, model: m)
//            }
            
            setTitleButton()
        }
    }
    
    private func setTitleButton() {
        PTGCDManager.gcdMain {
            if self.selectedCount != nil {
                self.selectedCount!(self.selectedModel.count)
            }
        }
    }
    
    private func setCellIndex(_ cell: PTMediaLibCell?, index: Int) {
//        guard ZLPhotoConfiguration.default().showSelectedIndex else {
//            return
//        }
        
        cell?.cellSelectedIndex = index
    }
    
    private func setCellMaskView(_ cell: PTMediaLibCell, isSelected: Bool, model: PTMediaModel) {
        cell.coverView.isHidden = true
        cell.enableSelect = true
        let config = PTMediaLibConfig.share
        let uiConfig = PTMediaLibUIConfig.share
//

        if isSelected {
            cell.coverView.backgroundColor = .DevMaskColor
            cell.coverView.isHidden = false
            cell.editButton.isHidden = false
//            if uiConfig.showSelectedBorder {
            cell.layer.borderColor = UIColor.purple.cgColor
                cell.layer.borderWidth = 4
//            }
        } else {
            cell.editButton.isHidden = true
            let selCount = selectedModel.count
            if selCount < config.maxSelectCount {
                if config.allowMixSelect {
                    let videoCount = selectedModel.filter { $0.type == .video }.count
                    if videoCount >= config.maxVideoSelectCount, model.type == .video {
                        cell.coverView.backgroundColor = .DevMaskColor
                        cell.coverView.isHidden = !uiConfig.showInvalidMask
                        cell.enableSelect = false
                    } else if (config.maxSelectCount - selCount) <= (config.minVideoSelectCount - videoCount), model.type != .video {
                        cell.coverView.backgroundColor = .DevMaskColor
                        cell.coverView.isHidden = !uiConfig.showInvalidMask
                        cell.enableSelect = false
                    }
                } else if selCount > 0 {
                    cell.coverView.backgroundColor = .DevMaskColor
                    cell.coverView.isHidden = (!uiConfig.showInvalidMask || model.type != .video)
                    cell.enableSelect = model.type != .video
                }
            } else if selCount >= config.maxSelectCount {
                cell.coverView.backgroundColor = .DevMaskColor
                cell.coverView.isHidden = !uiConfig.showInvalidMask
                cell.enableSelect = false
            }
//            if uiConfig.showSelectedBorder {
                cell.layer.borderWidth = 0
//            }
        }
    }
    
    private func shouldDirectEdit(_ model: PTMediaModel) -> Bool {
        let config = PTMediaLibConfig.share
        
        let canEditImage = config.editAfterSelectThumbnailImage &&
            config.allowEditImage &&
            config.maxSelectCount == 1 &&
            model.type.rawValue < PTMediaModel.MediaType.video.rawValue
        
        let canEditVideo = (config.editAfterSelectThumbnailImage &&
            config.allowEditVideo &&
            model.type == .video &&
            config.maxSelectCount == 1) ||
            (config.allowEditVideo &&
                model.type == .video &&
                !config.allowMixSelect &&
                config.cropVideoAfterSelectThumbnail)
        
        // 当前未选择图片 或已经选择了一张并且点击的是已选择的图片
        let flag = selectedModel.isEmpty || (selectedModel.count == 1 && selectedModel.first?.ident == model.ident)
        
//        if canEditImage, flag {
//            showEditImageVC(model: model)
//        } else if canEditVideo, flag {
//            showEditVideoVC(model: model)
//        }
        
        return flag && (canEditImage || canEditVideo)
    }

    public func requestSelectPhoto(viewController: UIViewController? = nil) {
        guard !selectedModel.isEmpty else {
            selectImageBlock?([], isSelectOriginal)
            viewController?.dismiss(animated: true, completion: nil)
            return
        }
        
        let config = PTMediaLibConfig.share
        
        if config.allowMixSelect {
            let videoCount = selectedModel.filter { $0.type == .video }.count
            
            if videoCount > config.maxVideoSelectCount {
                PTAlertTipControl.present(title: "Opps!",subtitle:"视频选择数量大于\(config.maxVideoSelectCount)",icon:.Error,style:.Normal)
                return
            } else if videoCount < config.minVideoSelectCount {
                PTAlertTipControl.present(title: "Opps!",subtitle:"视频选择数量小于\(config.minVideoSelectCount)",icon:.Error,style:.Normal)
                return
            }
        }
        
        PTAlertTipControl.present(title: "",subtitle:"处理中请稍候",icon:.Heart,style:.Normal)
        
                
        let isOriginal = config.allowSelectOriginal ? isSelectOriginal : config.alwaysRequestOriginal
        
        let callback = { [weak self] (sucModels: [PTResultModel], errorAssets: [PHAsset], errorIndexs: [Int]) in
            
            func call() {
                self?.selectImageBlock?(sucModels, isOriginal)
                if !errorAssets.isEmpty {
                    self?.selectImageRequestErrorBlock?(errorAssets, errorIndexs)
                }
            }
            
            if let vc = viewController {
                vc.dismiss(animated: true) {
                    call()
                }
            } else {
                call()
            }
            
            self?.selectedModel.removeAll()
            self?.totalModels.removeAll()
        }
        
        var results: [PTResultModel?] = Array(repeating: nil, count: selectedModel.count)
        var errorAssets: [PHAsset] = []
        var errorIndexs: [Int] = []
        
        var sucCount = 0
        let totalCount = selectedModel.count
        
        for (i, m) in selectedModel.enumerated() {
            let operation = PTFetchImageOperation(model: m, isOriginal: isOriginal) { image, asset in
                
                sucCount += 1
                
                if let image = image {
                    let isEdited = m.editImage != nil && !config.saveNewImageAfterEdit
                    let model = PTResultModel(
                        asset: asset ?? m.asset,
                        image: image,
                        isEdited: isEdited,
                        editModel: isEdited ? m.editImageModel : nil,
                        avEditorOutputItem: m.avEditorOutputItem,
                        index: i
                    )
                    results[i] = model
                    PTNSLogConsole("PTPhotoBrowser: suc request \(i)")
                } else {
                    errorAssets.append(m.asset)
                    errorIndexs.append(i)
                    PTNSLogConsole("PTPhotoBrowser: failed request \(i)")
                }
                
                guard sucCount >= totalCount else { return }
                
                callback(results.compactMap { $0 },errorAssets,errorIndexs)
            }
            fetchImageQueue.addOperation(operation)
        }
    }
}

extension PTMediaLibView:PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        PTGCDManager.gcdMain {
            self.loadMedia()
        }
    }
}

public class PTMediaLibViewController: PTFloatingBaseViewController {

    public var selectImageBlock: (([PTResultModel], Bool) -> Void)?

    private lazy var fakeNav:UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var dismissButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage("❌".emojiToImage(emojiFont: .appfont(size: 18)), for: .normal)
        view.addActionHandlers { sender in
            self.returnFrontVC()
        }
        return view
    }()
    
    private lazy var submitButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage("✅".emojiToImage(emojiFont: .appfont(size: 18)), for: .normal)
        view.addActionHandlers { sender in
            self.mediaListView.requestSelectPhoto(viewController: self)
            self.mediaListView.selectImageBlock = self.selectImageBlock
        }
        return view
    }()
    
    private lazy var selectLibButton:PTLayoutButton = {
        let view = PTLayoutButton()
        view.layoutStyle = .leftTitleRightImage
        view.imageSize = CGSize(width: 10, height: 10)
        view.normalImage = "🔽".emojiToImage(emojiFont: .appfont(size: 10))
        view.normalTitle = "全部照片"
        view.normalTitleColor = PTAppBaseConfig.share.viewDefaultTextColor
        view.normalSubTitleColor = PTAppBaseConfig.share.viewDefaultTextColor
        view.normalTitleFont = .appfont(size: 15)
        view.addActionHandlers { sender in
            PHPhotoLibrary.shared().unregisterChangeObserver(self)
            
            let config = PTMediaLibConfig.share
            
            if self.mediaListView.currentAlbum != nil {
                let vc = PTMediaLibAlbumListViewController(albumList: self.mediaListView.currentAlbum!)
                let nav = PTBaseNavControl(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true)
                vc.selectedModelHandler = { model in
                    self.selectLibButton.normalTitle = "\(model.title)"
                    self.mediaListView.currentAlbum = model
                }
            } else {
                PTMeidaLibManager.getCameraRollAlbum(allowSelectImage: config.allowSelectImage, allowSelectVideo: config.allowSelectVideo) { model in
                    let vc = PTMediaLibAlbumListViewController(albumList: model)
                    let nav = PTBaseNavControl(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true)
                    vc.selectedModelHandler = { model in
                        self.selectLibButton.normalTitle = "\(model.title)"
                        self.mediaListView.currentAlbum = model
                    }
                }
            }
        }
        return view
    }()
    
    private lazy var mediaListView : PTMediaLibView = {
        let view = PTMediaLibView()
        view.selectedCount = { index in
            if index > 0 {
                self.selectLibButton.normalSubTitleFont = .appfont(size: 12)
                self.selectLibButton.normalSubTitle = "选择了\(index)张"
            } else {
                self.selectLibButton.normalSubTitle = ""
            }
        }
        return view
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubviews([fakeNav,mediaListView])
        fakeNav.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(8)
            make.height.equalTo(44)
        }
        
        createNavSubs()
        
        mediaListView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(self.fakeNav.snp.bottom)
        }
    }
    
    func createNavSubs() {
        fakeNav.addSubviews([dismissButton,submitButton,selectLibButton])
        dismissButton.snp.makeConstraints { make in
            make.size.equalTo(34)
            make.bottom.equalToSuperview().inset(5)
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
        
        submitButton.snp.makeConstraints { make in
            make.size.bottom.equalTo(self.dismissButton)
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
        
        selectLibButton.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
        }
    }
        
    public func meidaLibShow(panGesDelegate:(UIViewController & UIGestureRecognizerDelegate)? = PTUtils.getCurrentVC() as! PTBaseViewController) {
#if POOTOOLS_FLOATINGPANEL
        if panGesDelegate != nil {
            PTUtils.getCurrentVC().sheetPresent_floating(modalViewController: self, type: .large, scale: 1,panGesDelegate:panGesDelegate) {
                
            } dismissCompletion: {
                
            }
        } else {
            showMediaLib()
        }
#else
        showMediaLib()
#endif
        
        if #available(iOS 14.0, *), PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited {
            PHPhotoLibrary.shared().register(self)
        }
    }
    
    private func showMediaLib() {
        if #available(iOS 15.0,*) {
            PTUtils.getCurrentVC().sheetPresent(modalViewController: self, type: .large, scale: 1) {
                
            }
        } else {
            PTUtils.getCurrentVC().present(self, animated: true)
        }
    }
}
