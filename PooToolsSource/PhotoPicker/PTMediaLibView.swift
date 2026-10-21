//
//  PTMediaLibView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 28/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import Photos
import Combine
#if SWIFT_PACKAGE
import PToolsSymbols
#endif
#if canImport(PToolsUIFoundation)
import PToolsUIFoundation
#endif

#if SWIFT_PACKAGE
import ptools
import PooToolsImagePicker
import PTCameraPermission
#endif

// English: Keep the legacy collection completion on MainActor without capturing UIKit in a nonisolated callback.
// Español: Mantiene la finalización heredada de la colección en MainActor sin capturar UIKit en un callback no aislado.
// 中文：让旧版列表完成回调保持在 MainActor，避免在非隔离回调中捕获 UIKit。
@MainActor
private final class PTMediaCollectionFinishBox {
    private let callback: PTCollectionCallback?

    init(_ callback: PTCollectionCallback?) {
        self.callback = callback
    }

    func call(with collectionView: UICollectionView) {
        callback?(collectionView)
    }
}

@MainActor
public class PTMediaLibView: UIView {
    
    // MARK: - Properties
    public var updateTitle: PTActionTask?
    var selectedModelDidUpdate: PTActionTask?
    var selectedCount: ((Int) -> Void)?
    
    // English: Keep the controller reference weak and avoid force-unwrapping during cell reuse.
    // Español: Mantiene débil la referencia al controlador y evita desempaquetados forzados durante la reutilización.
    // 中文：控制器引用使用弱引用，避免 Cell 复用期间发生循环引用和强制解包崩溃。
    weak var currentVc: PTMediaLibViewController?

    // English: The store owns both arrays so view and controller cannot drift apart.
    // Español: El store posee ambos arrays para que la vista y el controlador no se desincronicen.
    // 中文：由 Store 统一持有两个数组，避免 View 和 Controller 数据分叉。
    private let selectionStore: PTMediaSelectionStore
    private let albumRepository: PTMediaAlbumRepository

    var totalModels: [PTMediaModel] {
        get { selectionStore.models }
        set { selectionStore.replaceModels(newValue) }
    }

    var selectedModel: [PTMediaModel] {
        get { selectionStore.selectedModels }
        set { selectionStore.replaceSelectedModels(newValue) }
    }

    var currentAlbum: PTMediaLibListModel? {
        didSet {
            pickerSessionAlbumDidChange(currentAlbum)
            guard let album = currentAlbum else {
                PTMediaPickerTrace.event("album", details: "kind=clear")
                renderedRows = []
                scheduledRows = nil
                renderedAlbumIdentity = nil
                renderedAlbumRevision = 0
                mediaRowsGeneration &+= 1
                collectionView.clearAllData()
                return
            }
            updateTitle?()
            let albumIdentity = album.collection.localIdentifier
            guard renderedAlbumIdentity != albumIdentity || renderedAlbumRevision != album.contentRevision else {
                PTMediaPickerTrace.event("album", details: "kind=unchanged")
                return
            }
            PTMediaPickerTrace.event("album", details: "kind=render,revision=\(album.contentRevision)")
            loadMedia()
        }
    }

    private func pickerSessionAlbumDidChange(_ album: PTMediaLibListModel?) {
        albumRepository.setCurrentAlbum(album)
        currentVc?.setPickerAlbum(album)
    }
    
    private var showCameraCell: Bool {
        let options = effectiveCameraOptions
        return activeSelectionOptions.allowTakePhotoInLibrary
            && (options.allowTakePhoto || options.allowRecordVideo)
            && (currentAlbum?.isCameraRoll ?? false)
    }

    // English: Keep the first load independent from the controller back-reference setup order.
    // Español: Mantiene la primera carga independiente del orden de configuración de la referencia al controlador.
    // 中文：让首次加载不受控制器反向引用设置顺序影响。
    private let selectionOptionsSnapshot: PTMediaLibSelectionOptions

    private var activeSelectionOptions: PTMediaLibSelectionOptions {
        currentVc?.effectiveSelectionOptions ?? selectionOptionsSnapshot
    }

    private var lastGridWidth: CGFloat = 0
    private var lastAdaptiveLayoutSignature: String?
    private var pendingDownloadCancellations: [String: PTMediaRequestCancellation] = [:]
    private var renderedRows: [PTRows] = []
    private var scheduledRows: [PTRows]?
    private var renderedAlbumIdentity: String?
    private var renderedAlbumRevision: UInt64 = 0
    private var mediaRowsGeneration: UInt64 = 0
    private var pendingSavedAssets: [String: PHAsset] = [:]
    private var completedCaptureAssetIDs: Set<String> = []
    private var pendingReplacementAssets: [String: (asset: PHAsset, originalIdentifier: String)] = [:]

    // English: Restrict camera media kinds to the picker policy before presenting the camera.
    // Español: Limita los tipos de medios de la cámara a la política del selector antes de mostrar la cámara.
    // 中文：展示相机前，先用当前选择器策略限制可拍摄的媒体类型。
    private var effectiveCameraOptions: PTMediaLibCameraOptions {
        var options = activeSelectionOptions.cameraOptions
        options.allowTakePhoto = options.allowTakePhoto && activeSelectionOptions.allowSelectImage
        options.allowRecordVideo = options.allowRecordVideo && activeSelectionOptions.allowSelectVideo
        return options
    }

    // MARK: - UI Components
    lazy var collectionView: PTCollectionView = {
        let configs = PTCollectionViewConfig()
        configs.viewType = .Gird
        configs.itemOriginalX = 1
        configs.cellLeadingSpace = 1
        configs.cellTrailingSpace = 1
        configs.rowCount = 3
        configs.itemHeight = 1

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
    init(currentModels: PTMediaLibListModel?,
         selectionOptions: PTMediaLibSelectionOptions? = nil,
         selectionStore: PTMediaSelectionStore? = nil,
         albumRepository: PTMediaAlbumRepository? = nil) {
        self.selectionStore = selectionStore ?? PTMediaSelectionStore()
        self.selectionOptionsSnapshot = selectionOptions ?? currentModels?.selectionOptions ?? .current()
        self.albumRepository = albumRepository ?? PTMediaAlbumRepository(options: self.selectionOptionsSnapshot)
        super.init(frame: .zero)
        self.selectionStore.onChange = { [weak self] in
            self?.selectedModelDidUpdate?()
            self?.refreshCellIndex()
            self?.updateTitleCounter()
        }
        self.albumRepository.onCameraRollChange = { [weak self] album in
            self?.applyRepositoryAlbum(album)
        }
        setupUI()
        self.currentAlbum = currentModels
        self.totalModels = currentModels?.models ?? []
        setupScreenshotObserver()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupUI() {
        addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        let region = PTAdaptiveVisibleRegionResolver.region(for: self)
        let horizontalVisibleRect = CGRect(x: region.visibleRect.minX,
                                            y: bounds.minY,
                                            width: region.visibleRect.width,
                                            height: bounds.height).intersection(bounds)
        let visibleRect = horizontalVisibleRect.isEmpty ? bounds : horizontalVisibleRect
        let layoutSignature = "\(region.signature)|\(visibleRect.integral)"
        if layoutSignature != lastAdaptiveLayoutSignature {
            lastAdaptiveLayoutSignature = layoutSignature
            // English: Keep the photo grid inside the local visible pane while retaining the full-height sheet background.
            // Español: Mantiene la cuadrícula dentro del panel visible local y conserva el fondo de altura completa.
            // 中文：让照片网格保持在当前可视面板内，同时保留全高度的 Sheet 背景。
            collectionView.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(visibleRect.minX)
                make.right.equalToSuperview().inset(max(0, bounds.width - visibleRect.maxX))
                make.top.bottom.equalToSuperview()
            }
        }
        let width = collectionView.contentCollectionView.bounds.width
        guard width > 0, abs(width - lastGridWidth) > 0.5 else { return }
        lastGridWidth = width
        guard let config = collectionView.viewConfig else { return }
        let itemWidth = max(1, (width - CGFloat(config.rowCount - 1) * config.cellLeadingSpace) / CGFloat(max(1, config.rowCount)))
        guard abs(config.itemHeight - itemWidth) > 0.5 else { return }
        config.itemHeight = itemWidth
        collectionView.invalidateRuntimeLayout()
    }

    // English: Register PhotoKit observation only while the picker view is attached to a window.
    // Español: Registra la observación de PhotoKit solo mientras la vista está unida a una ventana.
    // 中文：仅在 Picker 视图挂载到 Window 期间注册 PhotoKit 观察。
    override public func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            cancelPendingDownloads()
            pendingSavedAssets.removeAll(keepingCapacity: true)
            pendingReplacementAssets.removeAll(keepingCapacity: true)
            albumRepository.stopObserving()
        } else {
            albumRepository.startObserving()
        }
    }

    // English: Cancel iCloud selection work before the picker is dismissed.
    // Español: Cancela el trabajo de selección de iCloud antes de cerrar el selector.
    // 中文：关闭 Picker 前取消所有 iCloud 选择任务。
    func cancelPendingDownloads() {
        pendingDownloadCancellations.values.forEach { $0.cancel() }
        pendingDownloadCancellations.removeAll(keepingCapacity: true)
    }
}

// MARK: - Media Loading & Data Management
extension PTMediaLibView {
    func loadMedia(addImage: Bool = false, loadFinish: PTCollectionCallback? = nil) {
        guard let album = currentAlbum else { return }
        if !addImage { totalModels = album.models }

        // English: Keep stable row identities and choose a local update whenever the delta is small.
        // Español: Conserva identidades estables y usa una actualización local cuando el delta es pequeño.
        // 中文：保持稳定行身份，变更规模较小时只执行局部更新。
        var rows = totalModels.map {
            PTRows(ID: PTMediaLibCell.ID,
                   diffId: "asset:\($0.ident)",
                   dataModel: $0)
        }
        if showCameraCell {
            let insertIndex = activeSelectionOptions.cameraCellAtTop ? 0 : rows.count
            rows.insert(PTRows(ID: PTCameraCell.ID, diffId: "camera"), at: insertIndex)
        }
        applyMediaRows(rows, album: album, finish: loadFinish)
    }

    private func applyMediaRows(_ rows: [PTRows],
                                album: PTMediaLibListModel,
                                finish: PTCollectionCallback?) {
        let oldRows = scheduledRows ?? renderedRows
        let oldIDs = oldRows.map(\.diffId)
        let newIDs = rows.map(\.diffId)
        let albumIdentity = album.collection.localIdentifier
        let albumRevision = album.contentRevision
        let sameAlbum = renderedAlbumIdentity == albumIdentity ||
            (renderedAlbumIdentity == nil && scheduledRows != nil && currentAlbum?.collection.localIdentifier == albumIdentity)
        let anchor = sameAlbum ? captureScrollAnchor(in: oldRows) : nil
        mediaRowsGeneration &+= 1
        let applyGeneration = mediaRowsGeneration
        let transactionID = UUID().uuidString
        scheduledRows = rows
        PTMediaPickerTrace.event("collectionApplyEnqueued", details: "transaction=\(transactionID),revision=\(albumRevision),rows=\(rows.count),selected=\(selectionStore.selectedCount)")

        let finishBox = PTMediaCollectionFinishBox(finish)
        let complete: PTActionTask = { [weak self, finishBox, anchor, rows, albumIdentity, albumRevision, applyGeneration, transactionID] in
            PTMainActorBridge.perform { [weak self, finishBox] in
                guard let self else { return }
                guard self.mediaRowsGeneration == applyGeneration,
                      self.currentAlbum?.collection.localIdentifier == albumIdentity,
                      self.currentAlbum?.contentRevision == albumRevision else {
                    PTMediaPickerTrace.event("collectionApplyDropped", details: "transaction=\(transactionID),reason=stale")
                    return
                }
                self.renderedAlbumIdentity = albumIdentity
                self.renderedAlbumRevision = albumRevision
                self.renderedRows = rows
                self.scheduledRows = nil
                if let anchor {
                    self.restoreScrollAnchor(anchor, in: rows)
                }
                PTMediaPickerTrace.event("collectionApplyCommitted", details: "transaction=\(transactionID),revision=\(albumRevision),rows=\(rows.count)")
                finishBox.call(with: self.collectionView.contentCollectionView)
            }
        }

        if sameAlbum, oldIDs == newIDs {
            let changedRows = rows.enumerated().compactMap { index, row -> PTRows? in
                guard index < oldRows.count else { return row }
                guard mediaRowRevision(oldRows[index]) != mediaRowRevision(row) else { return nil }
                return row
            }
            if !changedRows.isEmpty {
                PTMediaPickerTrace.event("rows", details: "kind=content,count=\(changedRows.count)")
                collectionView.updateRows(changedRows, reload: true, completion: complete)
            } else {
                renderedAlbumIdentity = albumIdentity
                renderedAlbumRevision = albumRevision
                renderedRows = rows
                finishBox.call(with: collectionView.contentCollectionView)
            }
            return
        }

        if sameAlbum,
           let insertedRange = appendRange(oldIDs: oldIDs, newIDs: newIDs) {
            let insertedRows = Array(rows[insertedRange])
            PTMediaPickerTrace.event("rows", details: "kind=append,count=\(insertedRows.count),index=\(insertedRange.lowerBound)")
            collectionView.insertRows(insertedRows,
                                       at: IndexPath(item: insertedRange.lowerBound, section: 0),
                                       completion: complete)
            return
        }

        if sameAlbum,
           oldIDs.count == newIDs.count + 1,
           isSubsequence(newIDs, of: oldIDs) {
            let removedIndex = oldIDs.firstIndex { !newIDs.contains($0) } ?? oldIDs.count - 1
            PTMediaPickerTrace.event("rows", details: "kind=delete,index=\(removedIndex)")
            collectionView.deleteRows([oldRows[removedIndex]], from: 0, completion: complete)
            return
        }

        if sameAlbum {
            PTMediaPickerTrace.event("rows", details: "kind=batchReplace,count=\(rows.count)")
            collectionView.replaceRows(in: 0,
                                       with: rows,
                                       animated: true,
                                       completion: complete)
        } else {
            PTMediaPickerTrace.event("rows", details: "kind=replace,count=\(rows.count)")
            collectionView.showCollectionDetail(collectionData: [PTSection(rows: rows)],
                                                finishTask: { _ in complete() })
        }
    }

    private func mediaRowRevision(_ row: PTRows) -> String {
        if let model = row.dataModel as? PTMediaModel {
            return model.sourceRevisionKey
        }
        return "\(row.ID)|\(row.diffHash)"
    }

    private func isSubsequence(_ smaller: [String], of larger: [String]) -> Bool {
        var index = 0
        for value in larger where index < smaller.count {
            if value == smaller[index] { index += 1 }
        }
        return index == smaller.count
    }

    // English: Return only the new media range while keeping a camera row at either edge stable.
    // Español: Devuelve solo el rango multimedia nuevo y mantiene estable la fila de cámara en cualquier extremo.
    // 中文：仅返回新增媒体范围，同时保持首尾两种相机 Cell 位置稳定。
    private func appendRange(oldIDs: [String], newIDs: [String]) -> Range<Int>? {
        guard newIDs.count > oldIDs.count else { return nil }
        let cameraID = "camera"
        let oldHasTrailingCamera = oldIDs.last == cameraID && newIDs.last == cameraID
        let oldMediaCount = oldHasTrailingCamera ? oldIDs.count - 1 : oldIDs.count
        let newMediaCount = oldHasTrailingCamera ? newIDs.count - 1 : newIDs.count
        guard newMediaCount > oldMediaCount,
              oldMediaCount >= 0,
              Array(oldIDs.prefix(oldMediaCount)) == Array(newIDs.prefix(oldMediaCount)) else {
            return nil
        }
        return oldMediaCount..<newMediaCount
    }

    private struct PTMediaScrollAnchor {
        let rowID: String
        let offset: CGFloat
    }

    // English: Capture one visible asset so multi-row PhotoKit updates do not move the user's browsing position.
    // Español: Captura un recurso visible para que las actualizaciones de varias filas no muevan la posición del usuario.
    // 中文：记录一个可见媒体，避免多 Row PhotoKit 更新改变用户当前浏览位置。
    private func captureScrollAnchor(in rows: [PTRows]) -> PTMediaScrollAnchor? {
        let collection = collectionView.contentCollectionView
        let candidates = collection.indexPathsForVisibleItems.compactMap { indexPath -> (PTRows, UICollectionViewLayoutAttributes)? in
            guard indexPath.section == 0,
                  let cell = collection.cellForItem(at: indexPath) as? PTMediaLibCell,
                  let assetID = cell.representedAssetID,
                  let row = rows.first(where: { $0.diffId == "asset:\(assetID)" }),
                  let attributes = collection.layoutAttributesForItem(at: indexPath) else {
                return nil
            }
            return (row, attributes)
        }
        guard let candidate = candidates.min(by: { $0.1.frame.minY < $1.1.frame.minY }) else { return nil }
        return PTMediaScrollAnchor(rowID: candidate.0.diffId,
                                   offset: candidate.1.frame.minY - collection.contentOffset.y)
    }

    // English: Restore the captured anchor after the serialized Diffable transaction completes.
    // Español: Restaura el ancla capturada cuando termina la transacción Diffable serializada.
    // 中文：在串行 Diffable 事务完成后恢复之前记录的滚动锚点。
    private func restoreScrollAnchor(_ anchor: PTMediaScrollAnchor,
                                     in rows: [PTRows]) {
        guard let item = rows.firstIndex(where: { $0.diffId == anchor.rowID }) else { return }
        let collection = collectionView.contentCollectionView
        collection.layoutIfNeeded()
        let indexPath = IndexPath(item: item, section: 0)
        guard let attributes = collection.layoutAttributesForItem(at: indexPath) else { return }
        let targetOffset = attributes.frame.minY - anchor.offset
        let minOffset = -collection.adjustedContentInset.top
        let maxOffset = max(minOffset,
                            collection.contentSize.height - collection.bounds.height + collection.adjustedContentInset.bottom)
        let y = min(max(targetOffset, minOffset), maxOffset)
        collection.setContentOffset(CGPoint(x: collection.contentOffset.x, y: y), animated: false)
    }

    private func applyRepositoryAlbum(_ album: PTMediaLibListModel) {
        guard currentAlbum?.isCameraRoll != false else { return }
        currentAlbum = album
        currentVc?.setPickerAlbum(album)
        consumePendingAssets(in: album)
    }

    private func consumePendingAssets(in album: PTMediaLibListModel) {
        for (identifier, asset) in Array(pendingSavedAssets) {
            guard let model = album.models.first(where: { $0.ident == identifier }) else { continue }
            guard selectionStore.selectedIndexMap()[identifier] == nil,
                  !selectionStore.pendingIdentifiers.contains(identifier) else {
                pendingSavedAssets.removeValue(forKey: identifier)
                completedCaptureAssetIDs.insert(identifier)
                continue
            }
            guard canAddModel(model,
                              currentSelectCount: selectionStore.reservedCount,
                              sender: currentVc,
                              showAlert: false,
                              selectionOptions: activeSelectionOptions,
                              selectionStore: selectionStore) else {
                pendingSavedAssets.removeValue(forKey: identifier)
                completedCaptureAssetIDs.insert(identifier)
                PTMediaPickerTrace.event("captureAutoRejected", details: "assetIDPresent=true,reason=selectionPolicy")
                continue
            }
            if selectionStore.completeSelection(for: model) {
                PTMediaLibConfig.share.didSelectAsset?(asset)
                PTMediaPickerTrace.event("captureAutoSelected", details: "assetIDPresent=true,selectedCount=\(selectionStore.selectedCount)")
            }
            pendingSavedAssets.removeValue(forKey: identifier)
            completedCaptureAssetIDs.insert(identifier)
        }

        for (identifier, pending) in Array(pendingReplacementAssets) {
            guard let model = album.models.first(where: { $0.ident == identifier }) else { continue }
            if let original = selectedModel.first(where: { $0.ident == pending.originalIdentifier }) {
                selectionStore.replaceSelection(original, with: model)
            } else {
                selectionStore.completeSelection(for: model)
            }
            PTMediaLibConfig.share.didSelectAsset?(pending.asset)
            pendingReplacementAssets.removeValue(forKey: identifier)
        }
        refreshCellIndex()
    }
    
    private func updateTitleCounter() {
        Task { @MainActor [weak self] in
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
            cell.selectionOptions = activeSelectionOptions

            // English: Configure selection without adding another target during reuse.
            // Español: Configura la selección sin añadir otro target durante la reutilización.
            // 中文：配置选择回调时不在复用过程中重复添加 target。
            cell.selectedBlock = { [weak self] isSelected in
                self?.cellSelectedFunction(cellModel: cellModel, cell: cell, isSelected: isSelected)
            }
            
            // English: Replace the cell-owned action instead of stacking handlers on every render.
            // Español: Reemplaza la acción de la celda en lugar de acumular handlers en cada renderizado.
            // 中文：只替换 Cell 自己持有的动作，避免每次渲染叠加回调。
            cell.editAction = { [weak self] sender in
                self?.handleEditAction(for: cellModel, sender: sender)
            }
            
            cell.cellModel = cellModel
            updateCellSelectionUI(cell, with: cellModel)
            return cell
        }
        
        return baseCell
    }
    
    func updateCellSelectionUI(_ cell: PTMediaLibCell, with model: PTMediaModel) {
        let projection = selectionStore.selectionProjection(for: model.ident)
        renderSelectionState(cell, model: model, selectedOrder: projection.order)
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
               let cell = collectionView.contentCollectionView.cellForItem(at: indexPath) as? PTMediaLibCell,
               cell.representedAssetID == cellModel.ident {
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
        
        #if POOTOOLS_IMAGEEDITOR
        if model.type == .image {
            handleImageEdit(model: model)
        }
        #endif
    }
}

// MARK: - Helper Methods (UI Update)
extension PTMediaLibView {
    private func refreshCellIndex() {
        let visibleIndexPaths = collectionView.contentCollectionView.indexPathsForVisibleItems

        for indexPath in visibleIndexPaths {
            guard let cell = collectionView.contentCollectionView.cellForItem(at: indexPath) as? PTMediaLibCell,
                  let assetID = cell.representedAssetID,
                  let model = cell.cellModel,
                  model.ident == assetID else { continue }
            let projection = selectionStore.selectionProjection(for: assetID)
            renderSelectionState(cell, model: model, selectedOrder: projection.order)
        }
    }

    private func renderSelectionState(_ cell: PTMediaLibCell,
                                      model: PTMediaModel,
                                      selectedOrder: Int?) {
        let uiConfig = PTMediaLibUIConfig.share
        let isSelected = selectedOrder != nil
        model.isSelected = isSelected
        let canSelect = isSelected || canSelectUnselectedModel(model)
        var canEdit = false
        #if POOTOOLS_IMAGEEDITOR
        if isSelected, model.type == .image { canEdit = activeSelectionOptions.allowEditImage }
        #endif
        #if POOTOOLS_VIDEOEDITOR
        if isSelected, model.type == .video { canEdit = activeSelectionOptions.allowEditVideo }
        #endif
        cell.applySelectionPresentation(isSelected: isSelected,
                                        order: selectedOrder,
                                        canSelect: canSelect,
                                        canEdit: canEdit,
                                        showInvalidMask: !isSelected && !canSelect && uiConfig.showInvalidMask,
                                        borderColor: uiConfig.selectedBorderColor)
    }

    private func canSelectUnselectedModel(_ model: PTMediaModel) -> Bool {
        let options = activeSelectionOptions
        guard selectionStore.reservedCount < options.maxSelectCount else { return false }
        guard !options.allowMixSelect, selectionStore.reservedCount > 0 else {
            return true
        }
        let selectedHasVideo = (selectedModel + Array(selectionStore.pendingModels.values)).contains { $0.type == .video }
        return selectedHasVideo == (model.type == .video)
    }
}

// MARK: - Camera & Saving Logic
extension PTMediaLibView {
    
    // English: Request permission once, then present the embedded camera with a typed result path.
    // Español: Solicita el permiso una vez y presenta la cámara integrada con un resultado tipado.
    // 中文：只请求一次权限，再通过类型化结果路径展示嵌入式相机。
    /// 调用系统相机
    func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            PTAlertTipsViewController.tipsAlertShow(title: PTMediaLibUIConfig.share.alertTitle,subtitle: PTMediaLibUIConfig.share.cameraError, icon: .Error)
            return
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            guard await PTSystemMediaPicker.requestCameraAccess() else {
                PTAlertTipsViewController.tipsAlertShow(title: PTMediaLibUIConfig.share.alertTitle,
                                                        subtitle: PTMediaLibUIConfig.share.takePhotoError,
                                                        icon: .Error)
                return
            }

            let picker = PTMediaLibCameraContainerViewController()
            picker.cameraOptions = self.effectiveCameraOptions
            picker.handleNewAssetCallback = { [weak self] asset in
                self?.handleNewAsset(asset)
            }
            // 弹出相机界面
            self.currentVc?.currentPresentToSheet(vc: picker, sizes: [.fullscreen], dismissPanGes: false)
        }
    }

    /// 统一保存逻辑
    @MainActor
    func saveMediaToAlbum(image: UIImage?,
                          videoUrl: URL?,
                          ownedTemporaryURL: URL? = nil) {
        PTMediaSaveUI.save(image: image,
                           videoURL: videoUrl,
                           onSuccess: { [weak self] asset in
                               if let ownedTemporaryURL {
                                   try? FileManager.default.removeItem(at: ownedTemporaryURL)
                               }
                               self?.handleNewAsset(asset)
                           },
                           onFailure: { _ in
                               if let ownedTemporaryURL {
                                   try? FileManager.default.removeItem(at: ownedTemporaryURL)
                               }
                           })
    }

    /// 处理新生成的资源并插入到当前列表
    private func handleNewAsset(_ asset: PHAsset) {
        // English: Refetch PhotoKit first, then render one authoritative snapshot instead of guessing an insert index.
        // Español: Vuelve a consultar PhotoKit primero y renderiza una instantánea única en lugar de adivinar un índice.
        // 中文：先重新获取 PhotoKit 结果，再渲染唯一快照，不再猜测插入下标。
        let identifier = asset.localIdentifier
        guard !identifier.isEmpty,
              !completedCaptureAssetIDs.contains(identifier),
              selectionStore.selectedIndexMap()[identifier] == nil,
              pendingSavedAssets[identifier] == nil else { return }
        pendingSavedAssets[identifier] = asset
        PTMediaPickerTrace.event("captureSaved", details: "assetIDPresent=true")
        albumRepository.requestRefresh(reason: .captureSaved)
    }
}

// MARK: - Editor Integration
extension PTMediaLibView {
    
    #if POOTOOLS_IMAGEEDITOR
    func handleImageEdit(model: PTMediaModel) {
        let container = collectionView.contentCollectionView
        let targetSize = model.previewSize(in: container.bounds,
                                           scale: container.window?.screen.scale ?? container.traitCollection.displayScale)
        PTMediaLibManager.requestImage(for: model.asset, targetSize: targetSize) { [weak self] result in
            PTGCDManager.shared.runOnMain { [weak self] in
                guard !result.isDegraded, let image = result.image else { return }
                
                let vc = PTEditImageViewController(readyEditImage: image)
                vc.editFinishBlock = { [weak self] editedImage, editModel in
                    self?.updateSelectedModelAfterEdit(original: model, newImage: editedImage, newEditModel: editModel)
                }
                
                let nav = PTBaseNavControl(rootViewController: vc)
                self?.currentVc?.currentPresentToSheet(vc: nav, sizes: [.fullscreen], dismissPanGes: false)
            }
        }
    }
    #endif
    
    #if POOTOOLS_VIDEOEDITOR
    func handleVideoEdit(model: PTMediaModel, sender: UIButton) {
        // 如果正在导出，则取消
        if model.asset.exportSession?.status == .exporting {
            model.asset.calcelExport()
            sender.clearProgressLayer()
            return
        }

        model.asset.convertPHAssetToAVAsset(progress: { progress in
            PTGCDManager.shared.runOnMain {
                sender.layerProgress(value: CGFloat(progress),
                                   borderWidth: PTMediaLibConfig.share.videoDownloadBorderWidth,
                                   borderColor: PTMediaLibUIConfig.share.themeColor)
            }
        }, completion: { [weak self] avAsset in
            PTGCDManager.shared.runOnMain { [weak self] in
                guard let avAsset = avAsset else {
                    PTAlertTipsViewController.tipsAlertShow(title: "Error",subtitle: "Video error", icon: .Error)
                    return
                }
                
                self?.presentVideoEditor(asset: model.asset, avAsset: avAsset.asset)
            }
        })
    }
    
    private func presentVideoEditor(asset: PHAsset, avAsset: AVAsset) {
        let vc = PTVideoEditorToolsViewController(asset: asset, avAsset: avAsset)
        vc.onlyOutput = true
        vc.onEditCompleteHandler = { [weak self] url in
            self?.saveEditedVideoToAlbum(url: url, replacing: asset)
        }
        let nav = PTBaseNavControl(rootViewController: vc)
        currentVc?.currentPresentToSheet(vc: nav, sizes: [.fullscreen])
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

// MARK: - Cell Selection Logic
extension PTMediaLibView {
    
    /// 处理 Cell 的点击选择逻辑
    /// - Parameters:
    ///   - cellModel: 当前点击的数据模型
    ///   - cell: 当前点击的 UI 单元格
    ///   - isSelected: 选择状态回调（通常用于同步按钮内部状态）
    func cellSelectedFunction(cellModel: PTMediaModel,
                              cell: PTMediaLibCell,
                              isSelected: (@MainActor @Sendable (Bool) -> Void)? = nil) {
        let config = PTMediaLibConfig.share
        guard cell.representedAssetID == cellModel.ident,
              cell.cellModel?.ident == cellModel.ident else { return }
        let isCurrentlySelected = selectionStore.isSelected(cellModel)
        guard !selectionStore.pendingIdentifiers.contains(cellModel.ident) else { return }
        PTMediaPickerTrace.event("selectionOnly", details: "assetIDPresent=true,selected=\(isCurrentlySelected)")
        
        // --- 情况 A: 准备选中该资源 ---
        if !isCurrentlySelected {
            // 1. 检查限制：是否达到最大选择数？是否允许混选？
            let currentCount = selectionStore.reservedCount
            guard canAddModel(cellModel,
                              currentSelectCount: currentCount,
                              sender: currentVc,
                              selectionOptions: activeSelectionOptions,
                              selectionStore: selectionStore) else {
                // 如果不满足条件（如已达上限），重置 Cell 状态并返回
                Task { @MainActor in
                    cell.editButton.isHidden = true
                    self.selectionStore.removeSelection(for: cellModel)
                    self.cellStatusReset(cellModel: cellModel, cell: cell, isSelected: isSelected)
                }
                return
            }

            guard let reservation = selectionStore.reserveSelection(for: cellModel) else { return }

            let continueSelection: @MainActor @Sendable () -> Void = { [weak self, weak cell] in
                guard let self, let cell,
                      cell.representedAssetID == cellModel.ident,
                      cell.cellModel?.ident == cellModel.ident else { return }
                self.startDownloadSelection(for: cellModel,
                                            cell: cell,
                                            reservation: reservation,
                                            isSelected: isSelected,
                                            config: config)
            }

            let options = activeSelectionOptions
            let hasVideoSizeConstraint = cellModel.type == .video &&
                (options.minSelectVideoDataSize > 0 ||
                 options.maxSelectVideoDataSize != .greatestFiniteMagnitude)
            if hasVideoSizeConstraint, cellModel.dataSize == nil {
                // English: Unknown video size cannot pass a configured limit; validate it before any final selection callback.
                // Español: Un tamaño de vídeo desconocido no puede superar un límite configurado; se valida antes del callback final.
                // 中文：配置了体积限制时，未知视频大小不能直接通过，必须在最终选择回调前校验。
                let sizeRequest = PTMediaLibManager.requestAssetSize(for: cellModel.asset) { [weak self] size in
                    guard let self else { return }
                    self.pendingDownloadCancellations.removeValue(forKey: cellModel.ident)
                    guard self.selectionStore.isReservationActive(reservation) else { return }
                    guard let size else {
                        self.selectionStore.cancelSelection(for: cellModel, reservation: reservation)
                        isSelected?(false)
                        self.refreshCellIndex()
                        return
                    }
                    cellModel.setDataSize(size)
                    guard canAddModel(cellModel,
                                      currentSelectCount: self.selectionStore.reservedCount,
                                      sender: self.currentVc,
                                      selectionOptions: options,
                                      selectionStore: self.selectionStore) else {
                        self.selectionStore.cancelSelection(for: cellModel, reservation: reservation)
                        isSelected?(false)
                        self.refreshCellIndex()
                        return
                    }
                    continueSelection()
                }
                if let sizeRequest {
                    pendingDownloadCancellations[cellModel.ident] = sizeRequest
                }
            } else {
                continueSelection()
            }
        }
        // --- 情况 B: 取消选中该资源 ---
        else {
            cellStatusReset(cellModel: cellModel, cell: cell, isSelected: isSelected)
        }
    }

    // English: Keep cloud download and final selection completion in one path after optional size validation.
    // Español: Mantiene la descarga en la nube y la finalización de selección en una sola ruta tras validar el tamaño.
    // 中文：可选体积校验完成后，云端下载和最终选中回调统一走同一条路径。
    private func startDownloadSelection(for cellModel: PTMediaModel,
                                        cell: PTMediaLibCell,
                                        reservation: PTMediaSelectionReservation,
                                        isSelected: (@MainActor @Sendable (Bool) -> Void)?,
                                        config: PTMediaLibConfig) {
        let download = downloadAssetIfNeededCancellable(model: cellModel,
                                                         sender: currentVc,
                                                         selectionOptions: activeSelectionOptions) { [weak self] success in
            self?.pendingDownloadCancellations.removeValue(forKey: cellModel.ident)
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard self.selectionStore.isReservationActive(reservation) else { return }
                guard success else {
                    self.selectionStore.cancelSelection(for: cellModel, reservation: reservation)
                    isSelected?(false)
                    self.refreshCellIndex()
                    return
                }
                let finalContext = ptMediaSelectionContext(for: cellModel,
                                                           store: self.selectionStore,
                                                           options: self.activeSelectionOptions)
                guard PTMediaSelectionPolicy.violation(for: finalContext) == nil else {
                    self.selectionStore.cancelSelection(for: cellModel, reservation: reservation)
                    isSelected?(false)
                    self.refreshCellIndex()
                    return
                }
                cellModel.isSelected = true
                guard self.selectionStore.completeSelection(for: cellModel, reservation: reservation) else { return }
                isSelected?(true)
                cell.layer.removeAllAnimations()
                config.didSelectAsset?(cellModel.asset)
                self.refreshCellIndex()
            }
        }
        if let download {
            pendingDownloadCancellations[cellModel.ident] = download
        }
    }
    
    /// 重置 Cell 状态（取消选中）
    func cellStatusReset(cellModel: PTMediaModel,
                         cell: PTMediaLibCell,
                         isSelected: (@MainActor @Sendable (Bool) -> Void)? = nil) {
        let config = PTMediaLibConfig.share
        
        // 1. 如果该资源正在执行导出操作（如视频），立即取消
        if cellModel.asset.exportSession?.status == .exporting {
            cellModel.asset.calcelExport()
            cell.editButton.clearProgressLayer()
        }
        
        pendingDownloadCancellations.removeValue(forKey: cellModel.ident)?.cancel()

        // 2. 更新数据模型：从已选列表中移除
        self.selectionStore.removeSelection(for: cellModel)
        isSelected?(false)
        
        // 3. UI 线程更新
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
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
    // English: Keep the legacy query as a compatibility wrapper around the shared permission source.
    // Español: Mantén esta consulta heredada como un adaptador de compatibilidad sobre la fuente común de permisos.
    // 中文：保留这个旧查询作为公共权限来源的兼容包装器。
    /// 检查并返回当前相机的访问权限状态
    /// - Returns: true 表示有权限或尚未请求，false 表示明确被拒绝
    public static func hasCameraAuthority() -> Bool {
        switch PTPermission.camera.status {
        case .authorized, .notDetermined:
            return true
        case .denied, .notSupported:
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
                PTGCDManager.shared.runOnMain {
                    self.albumRepository.requestRefresh(reason: .screenshot)
                }
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
    func saveEditedVideoToAlbum(url: URL, replacing originalAsset: PHAsset) {
        // Keep the exported file owned by this flow until PhotoKit finishes reading it.
        // Mantener el archivo exportado bajo el control de este flujo hasta que PhotoKit termine de leerlo.
        // 在 PhotoKit 完成读取前，由当前流程持有导出文件，避免临时 URL 提前失效。
        let temporaryURL = PTMediaLibView.outputURL()
        // 1. 构造播放条目（如果后续需要保存到缓存）
        let playerItem = AVPlayerItem(url: url)
        
        // 2. 先保存到本地缓存（可选，根据你的 PTMediaLibView.outputURL 逻辑）
        self.saveVideoToCache(fileURL: temporaryURL, playerItem: playerItem) { [weak self] fileURL, finish in
            guard let self = self, finish, let finalURL = fileURL else {
                try? FileManager.default.removeItem(at: temporaryURL)
                PTAlertTipsViewController.tipsAlertShow(title: "Error",subtitle: "Save to cache failed", icon: .Error)
                return
            }
            
            // 3. 将缓存文件写入系统相册
            Task { @MainActor in
                PTMediaSaveService.save(videoURL: finalURL) { result in
                    // English: Remove the exported cache file after PhotoKit has finished reading it.
                    // Español: Elimina el archivo exportado después de que PhotoKit termine de leerlo.
                    // 中文：PhotoKit 读取完成后再删除导出缓存文件。
                    try? FileManager.default.removeItem(at: finalURL)
                    switch result {
                    case .success(let asset):
                        self.updateSelectedModelWithNewAsset(asset, replacing: originalAsset)
                    case .failure:
                        PTAlertTipsViewController.tipsAlertShow(title: "Error",subtitle: "Save to album failed", icon: .Error)
                    }
                }
            }
        }
    }
    
    /// 使用新产生的 Asset 替换/更新已选中的模型
    private func updateSelectedModelWithNewAsset(_ asset: PHAsset, replacing originalAsset: PHAsset) {
        let identifier = asset.localIdentifier
        guard !identifier.isEmpty,
              selectionStore.selectedIndexMap()[identifier] == nil,
              pendingReplacementAssets[identifier] == nil else { return }
        pendingReplacementAssets[identifier] = (asset, originalAsset.localIdentifier)
        PTMediaPickerTrace.event("editSaved", details: "assetIDPresent=true")
        albumRepository.requestRefresh(reason: .editSaved)
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
        // English: Use a UUID in Caches so temporary exports cannot collide or be backed up.
        // Español: Usa un UUID en Caches para evitar colisiones y copias de seguridad innecesarias.
        // 中文：使用 Caches 目录和 UUID，避免临时导出文件冲突并避免被备份。
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return cacheDirectory.appendingPathComponent("PToolsMedia-\(UUID().uuidString).mp4")
    }
}


