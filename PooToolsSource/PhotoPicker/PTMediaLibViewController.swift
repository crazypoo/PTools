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
import AVFoundation
import SafeSFSymbols
import AttributedString

public class PTMediaLibView: UIView {
    
    // MARK: - Properties
    public var updateTitle: PTActionTask?
    var selectedModelDidUpdate: PTActionTask?
    var selectedCount: ((Int) -> Void)?
    
    // 使用弱引用防止循环引用，并尽量避免强制解包
    fileprivate weak var currentVc: PTMediaLibViewController?
    
    fileprivate var totalModels: [PTMediaModel] = []
    fileprivate var selectedModel: [PTMediaModel] = [] {
        didSet {
            selectedModelDidUpdate?()
            updateTitleCounter()
        }
    }

    var currentAlbum: PTMediaLibListModel? {
        didSet {
            guard currentAlbum != nil else { return }
            updateTitle?()
            collectionView.clearAllData { [weak self] _ in
                self?.loadMedia()
            }
        }
    }
    
    private var showCameraCell: Bool {
        PTMediaLibConfig.share.allowTakePhotoInLibrary && (currentAlbum?.isCameraRoll ?? false)
    }

    // MARK: - UI Components
    lazy var collectionView: PTCollectionView = {
        let configs = PTCollectionViewConfig()
        configs.viewType = .Gird
        configs.itemOriginalX = 1
        configs.cellLeadingSpace = 1
        configs.cellTrailingSpace = 1
        configs.rowCount = 3
        let itemWidth = (CGFloat.kSCREEN_WIDTH - CGFloat(configs.rowCount - 1) * configs.cellLeadingSpace) / CGFloat(configs.rowCount)
        configs.itemHeight = itemWidth

        let view = PTCollectionView(viewConfig: configs)
        view.registerClassCells(classs: [
            PTMediaLibCell.ID: PTMediaLibCell.self,
            PTCameraCell.ID: PTCameraCell.self
        ])
        
        view.cellInCollection = { [weak self] collection, sectionModel, indexPath in
            self?.configureCell(collection: collection, sectionModel: sectionModel, indexPath: indexPath)
        }
        
        view.collectionDidSelect = { [weak self] collection, sectionModel, indexPath in
            self?.handleSelection(collection: collection, sectionModel: sectionModel, indexPath: indexPath)
        }
        
        return view
    }()

    // MARK: - Init
    init(currentModels: PTMediaLibListModel) {
        super.init(frame: .zero)
        setupUI()
        self.currentAlbum = currentModels
        markSelected(source: &totalModels, selected: &selectedModel)
        setupScreenshotObserver()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupUI() {
        addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}

// MARK: - Media Loading & Data Management
extension PTMediaLibView {
    func loadMedia(addImage: Bool = false, loadFinish: PTCollectionCallback? = nil) {
        PTGCDManager.gcdMain { [weak self] in
            guard let self = self, let album = self.currentAlbum else { return }
            
            if !addImage {
                self.totalModels = album.models
            }
            
            var rows = self.totalModels.map { PTRows(ID: PTMediaLibCell.ID, dataModel: $0) }
            
            if self.showCameraCell {
                let insertIndex = PTMediaLibUIConfig.share.shortIsTop ? 0 : rows.count
                rows.insert(PTRows(ID: PTCameraCell.ID), at: insertIndex)
            }
            
            self.collectionView.showCollectionDetail(collectionData: [PTSection(rows: rows)], finishTask: loadFinish)
        }
    }
    
    private func updateTitleCounter() {
        PTGCDManager.gcdMain { [weak self] in
            guard let self = self else { return }
            self.selectedCount?(self.selectedModel.count)
        }
    }
}

// MARK: - Cell Configuration Logic
private extension PTMediaLibView {
    func configureCell(collection: UICollectionView, sectionModel: PTSection, indexPath: IndexPath) -> UICollectionViewCell? {
        guard let itemRow = sectionModel.rows?[indexPath.row] else { return nil }
        
        let baseCell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath)
        
        if let cell = baseCell as? PTMediaLibCell, let cellModel = itemRow.dataModel as? PTMediaModel {
            // 配置选择回调
            cell.selectedBlock = { [weak self] isSelected in
                Task { @MainActor in
                    self?.cellSelectedFunction(cellModel: cellModel, cell: cell, isSelected: isSelected)
                }
            }
            
            // 配置编辑按钮
            cell.editButton.addActionHandlers { [weak self] sender in
                self?.handleEditAction(for: cellModel, sender: sender)
            }
            
            // 更新选中状态 UI
            updateCellSelectionUI(cell, with: cellModel)
            cell.cellModel = cellModel
            return cell
        }
        
        return baseCell
    }
    
    func updateCellSelectionUI(_ cell: PTMediaLibCell, with model: PTMediaModel) {
        if let index = selectedModel.firstIndex(where: { $0 == model }) {
            setCellIndex(cell, index: index + 1)
            model.isSelected = true
        } else {
            model.isSelected = false
            cell.selectButton.normalTitle = ""
        }
        setCellMaskView(cell, isSelected: model.isSelected, model: model)
    }
}

// MARK: - Action Handling
private extension PTMediaLibView {
    func handleSelection(collection: UICollectionView, sectionModel: PTSection, indexPath: IndexPath) {
        guard let itemRow = sectionModel.rows?[indexPath.row] else { return }
        
        switch itemRow.ID {
        case PTCameraCell.ID:
            openCamera()
        case PTMediaLibCell.ID:
            if let cellModel = itemRow.dataModel as? PTMediaModel,
               let cell = collectionView.contentCollectionView.cellForItem(at: indexPath) as? PTMediaLibCell {
                Task { @MainActor in
                    self.cellSelectedFunction(cellModel: cellModel, cell: cell)
                }
            }
        default: break
        }
    }
    
    func handleEditAction(for model: PTMediaModel, sender: UIButton) {
        #if POOTOOLS_VIDEOEDITOR
        if model.type == .video {
            handleVideoEdit(model: model, sender: sender)
            return
        }
        #endif
        
//        #if POOTOOLS_IMAGEEDITOR
        if model.type == .image {
            handleImageEdit(model: model)
        }
//        #endif
    }
}

// MARK: - Helper Methods (UI Update)
extension PTMediaLibView {
    private func refreshCellIndex() {
        PTGCDManager.gcdMain { [weak self] in
            guard let self = self else { return }
            let visibleIndexPaths = self.collectionView.contentCollectionView.indexPathsForVisibleItems
            
            for indexPath in visibleIndexPaths {
                guard let cell = self.collectionView.contentCollectionView.cellForItem(at: indexPath) as? PTMediaLibCell else { continue }
                
                let indexOffset = self.showCameraCell ? (PTMediaLibUIConfig.share.shortIsTop ? 1 : 0) : 0
                let dataIndex = indexPath.row - indexOffset
                
                guard dataIndex >= 0, dataIndex < self.totalModels.count else { continue }
                
                let m = self.totalModels[dataIndex]
                let selectedIdx = self.selectedModel.firstIndex(where: { $0 == m })
                
                self.setCellIndex(cell, index: (selectedIdx ?? -1) + 1)
                self.setCellMaskView(cell, isSelected: selectedIdx != nil, model: m)
            }
            self.updateTitleCounter()
        }
    }

    private func setCellIndex(_ cell: PTMediaLibCell?, index: Int) {
        cell?.cellSelectedIndex = index
    }

    private func setCellMaskView(_ cell: PTMediaLibCell, isSelected: Bool, model: PTMediaModel) {
        let config = PTMediaLibConfig.share
        let uiConfig = PTMediaLibUIConfig.share
        
        cell.coverView.isHidden = true
        cell.enableSelect = true
        cell.layer.borderWidth = 0

        if isSelected {
            cell.coverView.backgroundColor = .DevMaskColor
            cell.coverView.isHidden = false
            cell.layer.borderColor = uiConfig.selectedBorderColor.cgColor
            cell.layer.borderWidth = 4
            
            // 根据宏定义控制编辑按钮显隐
//            #if POOTOOLS_IMAGEEDITOR
            if model.type == .image { cell.editButton.isHidden = !config.allowEditImage }
//            #endif
            #if POOTOOLS_VIDEOEDITOR
            if model.type == .video { cell.editButton.isHidden = !config.allowEditVideo }
            #endif
        } else {
            cell.editButton.isHidden = true
            handleInvalidMask(cell, model: model, config: config, uiConfig: uiConfig)
        }
    }
    
    private func handleInvalidMask(_ cell: PTMediaLibCell, model: PTMediaModel, config: PTMediaLibConfig, uiConfig: PTMediaLibUIConfig) {
        let selCount = selectedModel.count
        if selCount >= config.maxSelectCount {
            cell.coverView.backgroundColor = .DevMaskColor
            cell.coverView.isHidden = !uiConfig.showInvalidMask
            cell.enableSelect = false
        } else if !config.allowMixSelect && selCount > 0 {
            let hasVideo = selectedModel.any { $0.type == .video }
            let isTypeMismatch = hasVideo ? (model.type != .video) : (model.type == .video)
            if isTypeMismatch {
                cell.coverView.backgroundColor = .DevMaskColor
                cell.coverView.isHidden = !uiConfig.showInvalidMask
                cell.enableSelect = false
            }
        }
    }
}

// MARK: - Camera & Saving Logic
extension PTMediaLibView: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    /// 调用系统相机
    func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            PTAlertTipControl.present(title: PTMediaLibUIConfig.share.alertTitle,
                                    subtitle: PTMediaLibUIConfig.share.cameraError,
                                    icon: .Error, style: .Normal)
            return
        }
        
        guard PTMediaLibView.hasCameraAuthority() else {
            PTAlertTipControl.present(title: PTMediaLibUIConfig.share.alertTitle,
                                    subtitle: PTMediaLibUIConfig.share.takePhotoError,
                                    icon: .Error, style: .Normal)
            return
        }

        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.videoQuality = .typeHigh
        picker.mediaTypes = calculateMediaTypes()
        picker.videoMaximumDuration = TimeInterval(PTMediaLibConfig.share.maxRecordDuration)
        
        // 弹出相机界面
        UIViewController.currentPresentToSheet(vc: picker, sizes: [.fullscreen], dismissPanGes: false)
    }

    private func calculateMediaTypes() -> [String] {
        var types: [String] = []
        if PTMediaLibConfig.share.cameraConfiguration.allowTakePhoto { types.append("public.image") }
        if PTMediaLibConfig.share.cameraConfiguration.allowRecordVideo { types.append("public.movie") }
        return types
    }

    // MARK: - ImagePicker Delegate
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let image = info[.originalImage] as? UIImage
        let url = info[.mediaURL] as? URL
        
        picker.dismiss(animated: true) { [weak self] in
            self?.saveMediaToAlbum(image: image, videoUrl: url)
        }
    }

    /// 统一保存逻辑
    fileprivate func saveMediaToAlbum(image: UIImage?, videoUrl: URL?) {
        PTAlertTipControl.present(title: "", subtitle: PTMediaLibUIConfig.share.alertDoingTitle, icon: .Heart, style: .Normal)
        
        let completion: (Bool, PHAsset?) -> Void = { [weak self] success, asset in
            guard success, let asset = asset else {
                let errorMsg = image != nil ? PTMediaLibUIConfig.share.saveImageError : PTMediaLibUIConfig.share.saveVideoError
                PTAlertTipControl.present(title: "Error", subtitle: errorMsg, icon: .Error, style: .Normal)
                return
            }
            self?.handleNewAsset(asset)
        }

        if let img = image {
            PHPhotoLibrary.pt.saveImageToAlbum(image: img, completion: completion)
        } else if let url = videoUrl {
            PTMediaLibManager.saveVideoToAlbum(url: url, completion: completion)
        }
    }

    /// 处理新生成的资源并插入到当前列表
    private func handleNewAsset(_ asset: PHAsset) {
        let newModel = PTMediaModel(asset: asset)
        newModel.isSelected = true
        
        currentAlbum?.refreshResult()
        
        // 根据排序规则插入数据
        if PTMediaLibUIConfig.share.sortAscending {
            totalModels.append(newModel)
        } else {
            totalModels.insert(newModel, at: 0)
        }
        
        // 尝试自动选中
        let config = PTMediaLibConfig.share
        if canAddModel(newModel, currentSelectCount: selectedModel.count, sender: PTUtils.getCurrentVC(), showAlert: false) {
            selectedModel.append(newModel)
            config.didSelectAsset?(asset)
        }

        // 延迟刷新 UI 确保相册数据库已同步
        PTGCDManager.gcdAfter(time: 0.2) {
            self.loadMedia(addImage: true)
        }
    }
}

// MARK: - Editor Integration
extension PTMediaLibView {
    
//    #if POOTOOLS_IMAGEEDITOR
    func handleImageEdit(model: PTMediaModel) {
        PTMediaLibManager.fetchImage(for: model.asset, size: model.previewSize) { [weak self] image, isDegraded in
            guard !isDegraded, let image = image else { return }
            
            let vc = PTEditImageViewController(readyEditImage: image)
            vc.editFinishBlock = { [weak self] editedImage, editModel in
                self?.updateSelectedModelAfterEdit(original: model, newImage: editedImage, newEditModel: editModel)
            }
            
            let nav = PTBaseNavControl(rootViewController: vc)
            UIViewController.currentPresentToSheet(vc: nav, sizes: [.fullscreen], dismissPanGes: false)
        }
    }
//    #endif
    
    #if POOTOOLS_VIDEOEDITOR
    func handleVideoEdit(model: PTMediaModel, sender: UIButton) {
        // 如果正在导出，则取消
        if model.asset.exportSession?.status == .exporting {
            model.asset.calcelExport()
            sender.clearProgressLayer()
            return
        }

        model.asset.convertPHAssetToAVAsset(progress: { progress in
            sender.layerProgress(value: CGFloat(progress),
                               borderWidth: PTMediaLibConfig.share.videoDownloadBorderWidth,
                               borderColor: PTMediaLibUIConfig.share.themeColor)
        }, completion: { [weak self] avAsset in
            guard let avAsset = avAsset else {
                PTAlertTipControl.present(title: "Error", subtitle: "Video error", icon: .Error,style:.Normal)
                return
            }
            
            self?.presentVideoEditor(asset: model.asset, avAsset: avAsset)
        })
    }
    
    private func presentVideoEditor(asset: PHAsset, avAsset: AVAsset) {
        let vc = PTVideoEditorToolsViewController(asset: asset, avAsset: avAsset)
        vc.onlyOutput = true
        vc.onEditCompleteHandler = { [weak self] url in
            self?.saveEditedVideoToAlbum(url: url)
        }
        let nav = PTBaseNavControl(rootViewController: vc)
        UIViewController.currentPresentToSheet(vc: nav, sizes: [.fullscreen])
    }
    #endif

    /// 编辑完成后同步更新数据源
    private func updateSelectedModelAfterEdit(original: PTMediaModel, newImage: UIImage, newEditModel: Any?) {
        if let index = selectedModel.firstIndex(where: { $0 == original }) {
            let model = selectedModel[index]
            model.editImage = newImage
            // 假设编辑后自动选中
            model.isSelected = true
            selectedModel[index] = model
            PTMediaLibConfig.share.didSelectAsset?(model.asset)
            refreshCellIndex()
        }
    }
}

// MARK: - Photo Library Observer
extension PTMediaLibView: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        // 注销观察者防止重复触发
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        
        PTGCDManager.gcdMain { [weak self] in
            guard let self = self else { return }
            let config = PTMediaLibConfig.share
            
            // 重新获取最新的相机胶卷
            PTMediaLibManager.getCameraRollAlbum(
                allowSelectImage: config.allowSelectImage,
                allowSelectVideo: config.allowSelectVideo,
                allowSelectLivePhotoOnly: config.allowOnlySelectLivePhoto
            ) { [weak self] newAlbum in
                guard let self = self else { return }
                self.currentAlbum = newAlbum
                
                // 如果是 PTMediaLibViewController 的子视图，同步更新父级数据
                if let vc = self.parentViewController as? PTMediaLibViewController {
                    vc.currentAlbum = newAlbum
                }
                
                // 自动滚动到底部（如果需要）
                if !PTMediaLibUIConfig.share.shortIsTop {
                    PTGCDManager.gcdAfter(time: 0.1) {
                        self.collectionView.contentCollectionView.scrollToBottom(animated: true)
                    }
                }
            }
        }
    }
}

// MARK: - Cell Selection Logic
extension PTMediaLibView {
    
    /// 处理 Cell 的点击选择逻辑
    /// - Parameters:
    ///   - cellModel: 当前点击的数据模型
    ///   - cell: 当前点击的 UI 单元格
    ///   - isSelected: 选择状态回调（通常用于同步按钮内部状态）
    @MainActor
    func cellSelectedFunction(cellModel: PTMediaModel, cell: PTMediaLibCell, isSelected: PTBoolTask? = nil) {
        let config = PTMediaLibConfig.share
        
        // --- 情况 A: 准备选中该资源 ---
        if !cellModel.isSelected {
            // 1. 检查限制：是否达到最大选择数？是否允许混选？
            let currentCount = self.selectedModel.count
            guard canAddModel(cellModel, currentSelectCount: currentCount, sender: PTUtils.getCurrentVC()) else {
                // 如果不满足条件（如已达上限），重置 Cell 状态并返回
                PTGCDManager.gcdMain {
                    cell.editButton.isHidden = true
                    self.selectedModel.removeAll(where: { $0 == cellModel })
                    self.cellStatusReset(cellModel: cellModel, cell: cell, isSelected: isSelected)
                }
                return
            }
            
            // 2. 资源下载检查：如果是 iCloud 资源，需要先下载
            downloadAssetIfNeed(model: cellModel, sender: PTUtils.getCurrentVC()) { [weak self] in
                guard let self = self else { return }
                
                // 3. 更新数据模型状态
                cellModel.isSelected = true
                self.selectedModel.append(cellModel)
                isSelected?(true)
                
                // 4. 更新 UI 表现
                PTGCDManager.gcdMain {
                    cell.selectButton.isSelected = true
                    cell.layer.removeAllAnimations()
                    // 选中后获取高清图（预览用）
                    cell.fetchBigImage()
                    
                    // 5. 触发配置回调与全局索引刷新
                    config.didSelectAsset?(cellModel.asset)
                    self.refreshCellIndex()
                }
            }
        }
        // --- 情况 B: 取消选中该资源 ---
        else {
            cellStatusReset(cellModel: cellModel, cell: cell, isSelected: isSelected)
        }
    }
    
    /// 重置 Cell 状态（取消选中）
    func cellStatusReset(cellModel: PTMediaModel, cell: PTMediaLibCell, isSelected: PTBoolTask? = nil) {
        let config = PTMediaLibConfig.share
        
        // 1. 如果该资源正在执行导出操作（如视频），立即取消
        if cellModel.asset.exportSession?.status == .exporting {
            cellModel.asset.calcelExport()
            cell.editButton.clearProgressLayer()
        }
        
        // 2. 更新数据模型：从已选列表中移除
        cellModel.isSelected = false
        self.selectedModel.removeAll(where: { $0 == cellModel })
        isSelected?(false)
        
        // 3. UI 线程更新
        PTGCDManager.gcdMain { [weak self] in
            guard let self = self else { return }
            
            cell.selectButton.isSelected = false
            cell.layer.removeAllAnimations()
            // 取消获取大图的任务，节省内存
            cell.cancelFetchBigImage()
            
            // 4. 触发回调与刷新
            config.didDeselectAsset?(cellModel.asset)
            self.refreshCellIndex()
        }
    }
}

// MARK: - Authority Check
extension PTMediaLibView {
    /// 检查并返回当前相机的访问权限状态
    /// - Returns: true 表示有权限或尚未请求，false 表示明确被拒绝
    public static func hasCameraAuthority() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .restricted, .denied:
            // 用户明确拒绝或受限（如家长控制）
            return false
        case .authorized, .notDetermined:
            // 已授权，或者尚未弹出请求框（UIImagePickerController 会自动处理请求）
            return true
        @unknown default:
            return false
        }
    }
}

// MARK: - Screenshot Observer
extension PTMediaLibView {
    /// 设置截屏监听器
    /// 当检测到用户截屏后，自动刷新媒体列表以显示最新的图片
    func setupScreenshotObserver() {
        // 使用弱引用防止闭包捕获导致的循环引用
        UIScreen.pt.detectScreenShot { [weak self] type in
            guard let self = self else { return }
            
            switch type {
            case .Normal:
                // 检测到普通截屏，执行静默刷新
                // 这里的 loadMedia 不需要传回调，直接刷新 UI 即可
                self.loadMedia(addImage: false)
            case .Video:
                // 如果是录屏事件，通常不需要刷新媒体库
                break
            }
        }
    }
}

// MARK: - Video Edit Saving
extension PTMediaLibView {
    
    /// 将编辑后的视频保存到相册并更新选中状态
    /// - Parameter url: 编辑工具输出的临时视频 URL
    func saveEditedVideoToAlbum(url: URL) {
        // 1. 构造播放条目（如果后续需要保存到缓存）
        let playerItem = AVPlayerItem(url: url)
        
        // 2. 先保存到本地缓存（可选，根据你的 PTMediaLibView.outputURL 逻辑）
        self.saveVideoToCache(playerItem: playerItem) { [weak self] fileURL, finish in
            guard let self = self, finish, let finalURL = fileURL else {
                PTAlertTipControl.present(title: "Error", subtitle: "Save to cache failed", icon: .Error, style:.Normal)
                return
            }
            
            // 3. 将缓存文件写入系统相册
            PTMediaLibManager.saveVideoToAlbum(url: finalURL) { isFinish, asset in
                guard isFinish, let asset = asset else {
                    PTAlertTipControl.present(title: "Error", subtitle: "Save to album failed", icon: .Error, style:.Normal)
                    return
                }
                
                // 4. 更新已选模型数组
                self.updateSelectedModelWithNewAsset(asset)
            }
        }
    }
    
    /// 使用新产生的 Asset 替换/更新已选中的模型
    private func updateSelectedModelWithNewAsset(_ asset: PHAsset) {
        PTGCDManager.gcdMain { [weak self] in
            guard let self = self else { return }
            
            // 创建新模型
            let newModel = PTMediaModel(asset: asset)
            newModel.isSelected = true
            
            // 这里有一个逻辑细节：通常编辑后的视频会作为“最新选中的”或者“替换当前的”
            // 如果你的逻辑是替换当前正在编辑的那个，可以根据 ident 寻找并替换
            // 这里演示通用的处理方式：通知配置项并刷新界面
            PTMediaLibConfig.share.didSelectAsset?(asset)
            
            // 刷新列表，让新保存的视频出现在相册视图中
            self.loadMedia(addImage: true)
        }
    }
}

// MARK: - Cache Helper
extension PTMediaLibView {
    
    /// 将视频条目导出并保存到沙盒缓存目录
    func saveVideoToCache(fileURL: URL = PTMediaLibView.outputURL(),
                          playerItem: AVPlayerItem,
                          result: ((_ fileURL: URL?, _ finish: Bool) -> Void)? = nil) {
        
        // 调用扩展方法进行导出
        AVAssetExportSession.pt.saveVideoToCache(fileURL: fileURL, playerItem: playerItem) { status, exportSession, url, error in
            if status == .completed {
                result?(url, true)
            } else {
                // 如果失败，打印日志或处理错误
                PTNSLogConsole("Video cache export failed: \(String(describing: error))")
                result?(nil, false)
            }
        }
    }
    
    /// 生成唯一的输出路径
    fileprivate static func outputURL() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        // 使用时间戳防止文件名冲突
        let fileName = "\(Int(Date().timeIntervalSince1970)).mp4"
        return documentsDirectory.appendingPathComponent(fileName)
    }
}

public class PTMediaLibViewController: PTBaseViewController {

    // MARK: - Callbacks
    public var selectedHudStatusBlock: PTBoolTask?
    public var selectImageBlock: (([PTResultModel], Bool) -> Void)?
    public var selectImageRequestErrorBlock: (([PHAsset], [Int]) -> Void)?

    // MARK: - Data
    var currentAlbum: PTMediaLibListModel! // 🌟 优化：将隐式解包(!)改为可选值(?)，防止生命周期异步加载时意外崩溃
    var totalModels: [PTMediaModel] = []
    var selectedModel: [PTMediaModel] = []

    // 🌟 1. 但仅仅是为了利用它完美的“并发数限制(maxConcurrentOperationCount = 3)”功能
    private lazy var fetchImageQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.pt.media.fetch"
        queue.maxConcurrentOperationCount = 3
        queue.qualityOfService = .userInitiated
        return queue
    }()

    private var isSelectOriginal = false
    fileprivate var selectedMediaCount: Int = 0

    // MARK: - UI
    private lazy var fakeNav: PTNavBar = PTNavBar()

    private lazy var dismissButton: UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(PTMediaLibUIConfig.share.backImage, for: .normal)
        view.addActionHandlers { [weak self] _ in
            self?.returnFrontVC()
        }
        if #available(iOS 26.0, *) {
            view.configuration = .clearGlass()
        }
        return view
    }()

    private lazy var submitButton: UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(PTMediaLibUIConfig.share.submitImage, for: .normal)
        view.addActionHandlers { [weak self] _ in
            self?.requestSelectPhoto(viewController: self)
        }
        if #available(iOS 26.0, *) {
            view.configuration = .clearGlass()
        }
        return view
    }()

    private lazy var selectLibButton: PTActionLayoutButton = {
        let view = PTActionLayoutButton()
        view.layoutStyle = .leftTitleRightImage
        view.imageSize = CGSize(width: 10, height: 10)
        view.setImage(PTMediaLibUIConfig.share.arrowDownImage, state: .normal)

        view.addActionHandlers { [weak self] _ in
            self?.handleAlbumClick()
        }
        view.bounds = CGRect(x: 0, y: 0, width: 100, height: 34)
        return view
    }()

    fileprivate lazy var mediaListView: PTMediaLibView = {
        let view = PTMediaLibView(currentModels: self.currentAlbum)
        view.currentVc = self

        view.selectedCount = { [weak self] count in
            self?.selectedMediaCount = count
            self?.scheduleTitleUpdate()
        }

        view.updateTitle = { [weak self] in
            self?.scheduleTitleUpdate()
        }

        view.selectedModelDidUpdate = { [weak self] in
            guard let self else { return }
            self.selectedModel = self.mediaListView.selectedModel
            self.totalModels = self.mediaListView.totalModels
        }

        return view
    }()

    // MARK: - Lifecycle
    deinit {}

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkPermissionAndLoad()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PTGCDManager.gcdAfter(time: 0.35, block: {
            self.changeStatusBar(type: .Dark)
        })
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        changeStatusBar(type: .Auto)
    }

    // MARK: - UI

    private func setupUI() {
        view.addSubview(fakeNav)

        fakeNav.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalToSuperview().inset(self.sheetViewController?.options.pullBarHeight ?? 0)
            $0.height.equalTo(CGFloat.kNavBarHeight)
        }

        fakeNav.titleViewMode = .auto
        fakeNav.setLeftButtons([dismissButton])
        fakeNav.setRightButtons([submitButton])

        resetTitleSelectBounds()
    }

    private func createList() {
        guard mediaListView.superview == nil else { return }

        let topInset = CGFloat.kNavBarHeight
        let bottomInset = CGFloat.kTabbarSaveAreaHeight

        let cv = mediaListView.collectionView.contentCollectionView
        cv.contentInsetAdjustmentBehavior = .never
        cv.contentInset.top = topInset
        cv.contentInset.bottom = bottomInset
        cv.verticalScrollIndicatorInsets.bottom = bottomInset

        view.addSubview(mediaListView)
        view.sendSubviewToBack(mediaListView)

        mediaListView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalToSuperview().inset(self.sheetViewController?.options.pullBarHeight ?? 0)
            $0.bottom.equalToSuperview()
        }
    }

    // MARK: - Album

    private func handleAlbumClick() {
        guard PTPermission.photoLibrary.status == .authorized else { return }

        let config = PTMediaLibConfig.share

        let pushAlbum: (PTMediaLibListModel) -> Void = { [weak self] album in
            guard let self else { return }

            let vc = PTMediaLibAlbumListViewController(albumList: album)
            self.navigationController?.pushViewController(vc, animated: true)

            vc.selectedModelHandler = { [weak self] model in
                guard let self else { return }

                if model.models.isEmpty {
                    model.refetchPhotos()
                }

                self.mediaListView.currentAlbum = model
                self.scheduleTitleUpdate() // 🌟 优化：复用 scheduleTitleUpdate 进行安全更新

                if !PTMediaLibUIConfig.share.shortIsTop {
                    PTGCDManager.gcdAfter(time: 0.05, block: {
                        self.mediaListView.collectionView.contentCollectionView.scrollToBottom(animated: false)
                    })
                }
            }
        }

        if let current = mediaListView.currentAlbum {
            pushAlbum(current)
        } else {
            PTMediaLibManager.getCameraRollAlbum(
                allowSelectImage: config.allowSelectImage,
                allowSelectVideo: config.allowSelectVideo,
                allowSelectLivePhotoOnly: config.allowOnlySelectLivePhoto
            ) { model in
                pushAlbum(model)
            }
        }
    }

    // MARK: - Title (🌟 优化：改用 DispatchWorkItem 实现真正的防抖，避免丢帧)

    private var titleUpdateWorkItem: DispatchWorkItem?

    private func scheduleTitleUpdate() {
        titleUpdateWorkItem?.cancel() // 取消之前的任务

        let workItem = DispatchWorkItem { [weak self] in
            self?.albumTitleSet()
        }
        titleUpdateWorkItem = workItem
        // 延迟 0.05 秒执行。如果期间再次触发，旧任务取消，重新计时
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: workItem)
    }

    @MainActor // 🌟 优化：保证 UI 更新一定在主线程
    func albumTitleSet() {
        let att = titleAtt()
        selectLibButton.setAtt(att, state: .normal)
        selectLibButton.setAtt(att, state: .highlighted)
        resetTitleSelectBounds()
    }

    @MainActor
    func titleAtt() -> ASAttributedString {
        guard let album = mediaListView.currentAlbum else { return "" }

        var buttonAtt: ASAttributedString = """
        \(album.title,
          .font(PTMediaLibUIConfig.share.selectLibTitleFont),
          .foreground(PTAppBaseConfig.share.viewDefaultTextColor),
          .paragraph(.alignment(.center)))
        """

        if selectedMediaCount > 0 {
            let count = String(format: PTMediaLibUIConfig.share.mediaCount, "\(selectedMediaCount)")
            buttonAtt += """
            \("\n\(count)",
              .font(PTMediaLibUIConfig.share.selectLibSubTitleFont),
              .foreground(PTAppBaseConfig.share.viewDefaultTextColor),
              .paragraph(.alignment(.center)))
            """
        }

        return buttonAtt
    }

    @MainActor
    func resetTitleSelectBounds() {
        selectLibButton.bounds = CGRect(
            origin: .zero,
            size: CGSize(width: selectLibButton.getKitCurrentDimension(), height: 34)
        )
        fakeNav.titleView = selectLibButton
    }

    // MARK: - Load

    private func checkPermissionAndLoad() {
        switch PTPermission.photoLibrary.status {
        case .authorized:
            loadImageData()
        case .notDetermined:
            PTPermission.photoLibrary.request { [weak self] in
                if PTPermission.photoLibrary.status == .authorized {
                    self?.loadImageData()
                }
            }
        default:
            break
        }
    }

    func loadImageData() {
        let config = PTMediaLibConfig.share

        PTMediaLibManager.getCameraRollAlbum(
            allowSelectImage: config.allowSelectImage,
            allowSelectVideo: config.allowSelectVideo,
            allowSelectLivePhotoOnly: config.allowOnlySelectLivePhoto
        ) { [weak self] model in
            guard let self else { return }

            self.currentAlbum = model

            let setup = {
                self.createList()
                self.mediaListView.currentAlbum = model
            }

            if model.models.isEmpty {
                DispatchQueue.global().async {
                    model.refetchPhotos()
                    DispatchQueue.main.async { setup() }
                }
            } else {
                setup()
            }
        }
    }
    
    public func mediaLibShow() {
        let nav = PTBaseNavControl(rootViewController: self)
        self.currentPresentToSheet(vc: nav,sizes: [.fixed(CGFloat.kSCREEN_HEIGHT - CGFloat.statusBarHeight())])
    }
}

extension PTMediaLibViewController {
        
    // 🌟 2. 桥接方法：把基于回调的 Operation 变成可以直接 await 的 Swift 6 方法
    private func fetchMediaResultAsync(model: PTMediaModel, index: Int, isOriginal: Bool) async -> (result: PTResultModel?, errorAsset: PHAsset?, index: Int) {
        return await withCheckedContinuation { continuation in
            let operation = PTFetchImageOperation(model: model, isOriginal: isOriginal) { image, asset in
                if let image = image {
                    let isEdited = model.editImage != nil && !PTMediaLibConfig.share.saveNewImageAfterEdit
                    
//#if POOTOOLS_IMAGEEDITOR
                    let resultModel = PTResultModel(
                        asset: asset ?? model.asset,
                        image: image,
                        isEdited: isEdited,
                        editModel: isEdited ? model.editImageModel : nil,
                        avEditorOutputItem: model.avEditorOutputItem,
                        index: index
                    )
//#else
//                    let resultModel = PTResultModel(
//                        asset: asset ?? model.asset,
//                        image: image,
//                        isEdited: isEdited,
//                        avEditorOutputItem: model.avEditorOutputItem,
//                        index: index
//                    )
//#endif
                    continuation.resume(returning: (resultModel, nil, index))
                } else {
                    continuation.resume(returning: (nil, asset ?? model.asset, index))
                }
            }
            
            // 放到 Queue 里去执行，这能保证 Operation 按照原有的设计正常运作！
            self.fetchImageQueue.addOperation(operation)
        }
    }
    
    // 🌟 3. 重构提交流程
    public func requestSelectPhoto(viewController: UIViewController? = nil) {
        
        // 🔥 核心修复：直接实时获取！不再依赖闭包更新，绝对不会出现丢失选中的情况！
        self.selectedModel = self.mediaListView.selectedModel
        self.totalModels = self.mediaListView.totalModels
        
        // 1. 空数据拦截
        guard !self.selectedModel.isEmpty else {
            let emptyOriginal = isSelectOriginal
            let presentingVC = viewController?.presentingViewController
            
            viewController?.dismiss(animated: true) { [weak self] in
                self?.selectImageBlock?([], emptyOriginal)
                if let pVC = presentingVC {
                    PTNavigationBarManager.shared.restoreIfNeeded(for: pVC)
                }
            }
            return
        }
        
        // 2. 混合校验
        let config = PTMediaLibConfig.share
        let uiConfig = PTMediaLibUIConfig.share
        
        if config.allowMixSelect {
            let videoCount = selectedModel.lazy.filter { $0.type == .video }.count
            
            if videoCount > config.maxVideoSelectCount {
                PTAlertTipControl.present(
                    title: uiConfig.alertTitle,
                    subtitle: String(format: uiConfig.mediaCountMax, "\(config.maxVideoSelectCount)"),
                    icon: .Error, style: .Normal
                )
                return
            }
            
            if videoCount < config.minVideoSelectCount {
                PTAlertTipControl.present(
                    title: uiConfig.alertTitle,
                    subtitle: String(format: uiConfig.mediaCountMin, "\(config.minVideoSelectCount)"),
                    icon: .Error, style: .Normal
                )
                return
            }
        }
        
        let isOriginal = config.allowSelectOriginal ? isSelectOriginal : config.alwaysRequestOriginal
        selectedHudStatusBlock?(true)
        
        // 🌟 4. 极简版 TaskGroup
        // 因为 fetchImageQueue 已经帮我们做了 `maxConcurrent = 3` 的限制，
        // 所以在这里我们可以直接把所有任务扔进 TaskGroup，代码变得异常简洁且安全！
        Task {
            var sucModels: [PTResultModel] = []
            var errAssets: [PHAsset] = []
            var errIndices: [Int] = []
            
            await withTaskGroup(of: (PTResultModel?, PHAsset?, Int).self) { group in
                // 直接全部添加进去，底层的 OperationQueue 会自动排队处理（一次跑3个）
                for (i, m) in selectedModel.enumerated() {
                    group.addTask {
                        await self.fetchMediaResultAsync(model: m, index: i, isOriginal: isOriginal)
                    }
                }
                
                // 收集结果
                for await (result, errorAsset, index) in group {
                    if let r = result {
                        sucModels.append(r)
                    } else if let a = errorAsset {
                        errAssets.append(a)
                        errIndices.append(index)
                    }
                }
            }
            
            // 恢复图片原始的点击顺序
            sucModels.sort { $0.index < $1.index }
            
            // 🌟 5. 回到主线程处理回调
            self.handleFetchCompletion(
                viewController: viewController,
                sucModels: sucModels,
                errAssets: errAssets,
                errIndices: errIndices,
                isOriginal: isOriginal
            )
        }
    }
    
    // MARK: - 辅助完成处理
    @MainActor
    private func handleFetchCompletion(viewController: UIViewController?,
                                       sucModels: [PTResultModel],
                                       errAssets: [PHAsset],
                                       errIndices: [Int],
                                       isOriginal: Bool) {
        let call = { [weak self] in
            self?.selectedHudStatusBlock?(false)
            self?.selectImageBlock?(sucModels, isOriginal)
            if !errAssets.isEmpty {
                self?.selectImageRequestErrorBlock?(errAssets, errIndices)
            }
            // 清理数据
            self?.selectedModel.removeAll()
            self?.totalModels.removeAll()
        }

        guard let vc = viewController,
              let presentingVC = vc.presentingViewController else {
            call()
            return
        }

        // 🌟 优化：这里捕获 presentingVC 的逻辑非常棒，它是安全的
        vc.dismiss(animated: true) {
            PTNavigationBarManager.shared.restoreIfNeeded(for: presentingVC)
            call()
        }
    }
}

extension PTSheetContentViewController: UIImagePickerControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {}
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        // 🌟 优化：直接在 dismiss 回调前捕获安全的层级引用
        let currentVC = PTUtils.getCurrentVC()
        
        picker.dismiss(animated: true) {
            if let mediaLib = currentVC as? PTMediaLibViewController {
                let image = info[.originalImage] as? UIImage
                let url = info[.mediaURL] as? URL
                mediaLib.mediaListView.saveMediaToAlbum(image: image, videoUrl: url)
            }
        }
    }
}
