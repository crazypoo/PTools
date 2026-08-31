//
//  PTEditImageViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 29/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import Photos
import SwifterSwift
import SafeSFSymbols
import Harbeth

#if SWIFT_PACKAGE
// English: Import the direct module owners used by the standalone ImageEditor target.
// Español: Importamos los módulos propietarios usados por el target independiente de ImageEditor.
// 中文：显式导入独立 ImageEditor target 直接使用的模块所有者。
import ptools
import PooToolsHarbethKit
import PooToolsPhotoPicker
#endif

public class PTEditImageViewController: PTBaseViewController {

    public var editFinishBlock: ((UIImage, PTEditModel?) -> Void)?
    // English: Optional typed completion for success, cancellation, and rendering failure.
    // Español: Finalización tipada opcional para éxito, cancelación y fallo de renderizado.
    // 中文：可选的类型化完成回调，用于区分成功、取消和渲染失败。
    public var editResultBlock: (@MainActor @Sendable (PTImageEditorResult) -> Void)?
    public var backHandler:PTActionTask?
    
    let adjustCollectionViewHeight : CGFloat = 74
    private var animate = false
    private var isScrolling = false
    private var shouldLayout = true
    var originalFrame: CGRect = .zero
    private var isFirstSetContainerFrame = true
    private var adjustTools: [PTHarBethFilter.FiltersTool] = []
    private var currentClipStatus: PTClipStatus
    private var preClipStatus: PTClipStatus
    private var editImageWithoutAdjust: UIImage
    private var filterThumbnailTask: Task<Void, Never>?
    private var lastContainerScrollSize = CGSize.zero
    private var lastContainerEditRect = CGRect.null
    private var lastContainerAngle: CGFloat = .nan

    private lazy var thumbnailImage: UIImage? = {
        let fixLength: CGFloat = 200
        guard originalImage.size.width > 0, originalImage.size.height > 0 else {
            return originalImage
        }
        let scale = min(fixLength / originalImage.size.width, fixLength / originalImage.size.height)
        let size = CGSize(width: max(1, originalImage.size.width * scale),
                          height: max(1, originalImage.size.height * scale))
        return originalImage.pt.resize_vI(size) ?? originalImage
    }()

    private var selectedTool: PTEditImageToolModel?
    lazy var toolsModel:[PTEditImageToolModel] = {
        return toolModelsBase()
    }()
    
    func toolModelsBase() -> [PTEditImageToolModel] {
        let cellModels: [PTEditImageToolModel] = PTImageEditorConfig.share.tools.map { tool in
            let model = PTEditImageToolModel()
            switch tool {
            case .draw:
                model.normalImage = UIImage(.hand.draw)
                model.selectedImage = UIImage(.hand.drawFill)
            case .clip:
                model.normalImage = UIImage(.scissors)
            case .textSticker:
                model.normalImage = UIImage(.pencil)
            case .mosaic:
                model.normalImage = UIImage(.square.grid_2x2)
                model.selectedImage = UIImage(.square.grid_2x2Fill)
                
            case .filter:
                model.normalImage = UIImage(.line._3HorizontalDecreaseCircle)
                model.selectedImage = UIImage(.line._3HorizontalDecreaseCircleFill)

            case .adjust:
                model.normalImage = UIImage(.ellipsis.rectangle)
                model.selectedImage = UIImage(.ellipsis.rectangleFill)
            case .imageSticker:
                model.normalImage = UIImage(.photo.fill)
            }
            model.currentType = tool
            return model
        }
        return cellModels
    }
    
    let toolCollectionHeight:CGFloat = 54
    private lazy var toolCollectionView : PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Custom
        let view = PTCollectionView(viewConfig: config)
        view.customerLayout = { sectionIndex,sectionModel in
            return UICollectionView.horizontalLayout(data: sectionModel.rows,itemOriginalX: PTAppBaseConfig.share.defaultViewSpace,itemWidth: self.toolCollectionHeight,itemHeight: self.toolCollectionHeight,topContentSpace: 0,bottomContentSpace: 0,itemLeadingSpace: 15)
        }
        view.cellInCollection = { collection,sectionModel,indexPath in
            if let itemRow = sectionModel.rows?[indexPath.row],let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.reuseID, for: indexPath) as? PTEditToolsCell {
                let cellTools = self.toolsModel[indexPath.row]
                cell.toolModel = cellTools
                return cell
            }
            return nil
        }
        view.collectionDidSelect = { collection,sectionModel,indexPath in
            // 找出之前被选中的那个 Model 的索引 (假设你记录了，或者遍历找一下)
            guard let oldSelectedIndex = self.toolsModel.firstIndex(where: { $0.isSelected }) else {
                self.toolsModel[indexPath.row].isSelected = true
                self.selectedTool(indexPath: indexPath)
                return
            }
            let oldIndexPath = IndexPath(row: oldSelectedIndex, section: indexPath.section)
            
            // 只有当点击的不是同一个才执行
            if oldSelectedIndex != indexPath.row {
                // 修改本地数据源状态
                self.toolsModel[oldSelectedIndex].isSelected = false
                self.toolsModel[indexPath.row].isSelected = true
                
                // 取出这两个位置对应的底层 PTRows 模型
                if let oldRowModel = self.toolCollectionView.getRow(at: oldIndexPath),
                   let newRowModel = self.toolCollectionView.getRow(at: indexPath) {
                    
                    // 🌟 关键：只把这两个 Row 传进去刷新！
                    // 因为没有清空整个 Layout 缓存，滚动条绝对不会跳动，且性能极高！
                    self.toolCollectionView.reloadRows([oldRowModel, newRowModel], in: indexPath.section)
                }
                self.selectedTool(indexPath: indexPath)
            } else {
                self.toolsModel[indexPath.row].isSelected = false
                self.selectedTool(indexPath: indexPath)
            }
        }
        return view
    }()
    
    func selectedTool(indexPath:IndexPath) {
        guard toolsModel.indices.contains(indexPath.row) else { return }
        switch toolsModel[indexPath.row].currentType {
        case .draw:
            showHandDrawAction()
        case .clip:
            showClipAction()
        case .textSticker:
            showTextAction()
        case .mosaic:
            mosaicAction()
        case .filter:
            filterAction()
        case .adjust:
            adjustActions()
        case .imageSticker:
            showImageAction()
        }
    }
    
    private lazy var filterCollectionView : PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Custom

        let view = PTCollectionView(viewConfig: config)
        view.registerClassCells(classs: [PTFilterImageCell.ID:PTFilterImageCell.self])
        view.customerLayout = { sectionIndex,sectionModel in
            return UICollectionView.horizontalLayout(data: sectionModel.rows,itemOriginalX: PTAppBaseConfig.share.defaultViewSpace,itemWidth: 88,itemHeight: PTCutViewController.cutRatioHeight,topContentSpace: 0,bottomContentSpace: 0,itemLeadingSpace: 10)
        }
        view.cellInCollection = { collection,sectionModel,indexPath in
            let config = PTImageEditorConfig.share
            let filters = PTImageEditorConfig.share.filters
            if filters.indices.contains(indexPath.row),
               let itemRow = sectionModel.rows?[indexPath.row],
               let cellTools = itemRow.dataModel as? UIImage,
               let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTFilterImageCell {
                let cellFilter = filters[indexPath.row]
                cell.imageView.image = cellTools
                cell.nameLabel.text = cellFilter.name
                if self.filterEngine.currentFilter == cellFilter {
                    cell.nameLabel.textColor = config.themeColor
                } else {
                    cell.nameLabel.textColor = .lightGray
                }
                return cell
            }
            return nil
        }
        view.collectionDidSelect = { collection,sectionModel,indexPath in
            let filters = PTImageEditorConfig.share.filters
            guard filters.indices.contains(indexPath.row) else { return }
            let filter = filters[indexPath.row]
            let oldFilter = self.filterEngine.currentFilter
            guard oldFilter != filter else { return }
            self.editorManager.storeAction(.filter(oldFilter: oldFilter, newFilter: filter))
            self.filterEngine.changeFilter(filter)

            var rows = [PTRows]()
            for index in Set([filters.firstIndex(where: { $0 === oldFilter }), indexPath.row].compactMap { $0 }) {
                if let row = self.filterCollectionView.getRow(at: IndexPath(row: index, section: 0)) {
                    rows.append(row)
                }
            }
            if !rows.isEmpty {
                self.filterCollectionView.reloadRows(rows, in: 0)
            }
        }
        return view
    }()

    private lazy var adjustCollectionView : PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Custom

        let view = PTCollectionView(viewConfig: config)
        view.registerClassCells(classs: [PTAdjustToolCell.ID:PTAdjustToolCell.self])
        view.customerLayout = { sectionIndex,sectionModel in
            return UICollectionView.horizontalLayout(data: sectionModel.rows,itemOriginalX: PTAppBaseConfig.share.defaultViewSpace,itemWidth: 54,itemHeight: self.adjustCollectionViewHeight - 10,topContentSpace: 5,bottomContentSpace: 0,itemLeadingSpace: 10)
        }
        view.cellInCollection = { collection,sectionModel,indexPath in
            let config = PTImageEditorConfig.share
            if let itemRow = sectionModel.rows?[indexPath.row],let cellTools = itemRow.dataModel as? PTFusionCellModel,let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTAdjustToolCell {
                cell.nameLabel.text = cellTools.name
                let tool = self.adjustTools[indexPath.row]
                let isSelected = tool == self.adjustEngine.selectedAdjustTool
                if isSelected {
                    cell.nameLabel.textColor = config.themeColor
                    cell.imageView.loadImage(contentData: cellTools.disclosureIndicatorImage as Any)
                } else {
                    cell.nameLabel.textColor = .lightGray
                    cell.imageView.loadImage(contentData: cellTools.contentIcon as Any)
                }
                cell.imageView.contentMode = .scaleAspectFit

                return cell
            }
            return nil
        }
        view.collectionDidSelect = { collection,sectionModel,indexPath in
            let adjustTool = self.adjustTools[indexPath.row]
            let oldTool = self.adjustEngine.selectedAdjustTool
            if adjustTool != self.adjustEngine.selectedAdjustTool {
                self.adjustEngine.changeAdjustTool(adjustTool) // 转交引擎处理
            }

            var rows = [PTRows]()
            for index in Set([oldTool.flatMap { self.adjustTools.firstIndex(of: $0) }, indexPath.row].compactMap { $0 }) {
                if let row = self.adjustCollectionView.getRow(at: IndexPath(row: index, section: 0)) {
                    rows.append(row)
                }
            }
            if !rows.isEmpty {
                self.adjustCollectionView.reloadRows(rows, in: 0)
            }
        }
        return view
    }()
    
    private lazy var dismissButton:PTBaseButton = {
        let view = PTBaseButton(type: .custom)
        view.setImage(PTImageEditorConfig.share.backImage, for: .normal)
        view.addActionHandlers { sender in
            self.cancelEditingIfNeeded()
            self.returnFrontVC()
            self.backHandler?()
        }
        return view
    }()
    
    private lazy var undoButton:PTBaseButton = {
        let view = PTBaseButton(type: .custom)
        view.setImage(PTImageEditorConfig.share.undoNormal, for: .normal)
        view.setImage(PTImageEditorConfig.share.undoDisable, for: .disabled)
        view.addActionHandlers { sender in
            self.editorManager.undoAction()
        }
        view.bounds = CGRect(origin: .zero, size: .init(width: PTAppBaseConfig.share.navBarButtonSize, height: PTAppBaseConfig.share.navBarButtonSize))
        return view
    }()
    
    private lazy var redoButton:PTBaseButton = {
        let view = PTBaseButton(type: .custom)
        view.setImage(PTImageEditorConfig.share.redoNormal, for: .normal)
        view.setImage(PTImageEditorConfig.share.redoDisable.withTintColor(.lightGray), for: .disabled)
        view.addActionHandlers { sender in
            self.editorManager.redoAction()
        }
        view.bounds = CGRect(origin: .zero, size: .init(width: PTAppBaseConfig.share.navBarButtonSize, height: PTAppBaseConfig.share.navBarButtonSize))
        return view
    }()
    
    func doneAction() {
        guard !isFinishing else { return }
        isFinishing = true
        hasDeliveredResult = false
        finishTask?.cancel()

        finishTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.finishTask = nil }
            var stickerStates: [PTBaseStickertState] = []
            for view in self.stickerEngine.canvasView.subviews {
                guard let view = view as? PTBaseStickerView else { continue }
                stickerStates.append(view.state)
            }
                        
            var hasEdit = true
            if self.drawEngine.drawPaths.isEmpty,
               self.currentClipStatus.editRect.size == self.imageSize,
               self.currentClipStatus.angle == 0,
               self.mosaicEngine.mosaicPaths.isEmpty,
               stickerStates.isEmpty,
               self.adjustEngine.currentAdjustStatus.allValueIsZero,
               self.filterEngine.currentFilter.type == .none {
                hasEdit = false
            }
            
            guard hasEdit else {
                self.editFinishBlock?(self.originalImage, nil)
                self.deliverResult(.success(image: self.originalImage, model: nil))
                self.isFinishing = false
                self.dismiss(animated: self.animate)
                return
            }

            // English: Show a lightweight progress notice while the edited image is rendered.
            // Español: Muestra un aviso ligero mientras se renderiza la imagen editada.
            // 中文：渲染编辑结果时显示轻量进度提示。
            PTAlertTipsViewController.tipsAlertShow(title: PTImageEditorConfig.share.doingAlertTitle, icon: .Heart)

            // English: Yield once so the progress notice can complete its layout.
            // Español: Cede una vez para que el aviso pueda terminar su diseño.
            // 中文：主动让出一次主线程执行机会，确保提示视图完成布局。
            await Task.yield()

            guard !Task.isCancelled else {
                self.isFinishing = false
                return
            }

            // English: Render and crop on the main actor because the editor owns UIKit layers.
            // Español: Renderiza y recorta en el actor principal porque el editor posee capas de UIKit.
            // 中文：编辑器持有 UIKit 图层，因此在主 actor 完成合成和裁剪。
            let renderedImage = self.buildImage()
            let clippedImage = renderedImage.pt.clipImage(
                angle: self.currentClipStatus.angle,
                editRect: self.currentClipStatus.editRect,
                isCircle: self.currentClipStatus.ratio?.isCircle ?? false
            )

            guard let resImage = self.applyOutputPolicy(to: clippedImage) else {
                self.deliverResult(.failure(.outputTooLarge))
                self.isFinishing = false
                return
            }

            let editModel = PTEditModel(
                drawPaths: self.drawEngine.drawPaths,
                mosaicPaths: self.mosaicEngine.mosaicPaths,
                clipStatus: self.currentClipStatus,
                adjustStatus: self.adjustEngine.currentAdjustStatus,
                selectFilter: self.filterEngine.currentFilter,
                stickers: stickerStates,
                actions: self.editorManager.actions
            )

            // English: Preserve the legacy callback and additionally publish the typed result.
            // Español: Conserva el callback heredado y publica también el resultado tipado.
            // 中文：保留旧完成回调，同时发送新的类型化结果。
            self.editFinishBlock?(resImage, editModel)
            self.deliverResult(.success(image: resImage, model: editModel))
            self.isFinishing = false
            self.dismiss(animated: self.animate)
        }
    }

    // English: Deliver one terminal result per editing attempt to prevent duplicate callbacks.
    // Español: Entrega un único resultado terminal por intento para evitar callbacks duplicados.
    // 中文：每次编辑尝试只发送一次终态结果，避免完成回调重复触发。
    private func deliverResult(_ result: PTImageEditorResult) {
        guard !hasDeliveredResult else { return }
        hasDeliveredResult = true
        editResultBlock?(result)
    }

    // English: Cancel the in-flight export without affecting the legacy back callback.
    // Español: Cancela la exportación activa sin afectar el callback de retroceso existente.
    // 中文：取消正在进行的导出，同时保留原有返回回调行为。
    private func cancelEditingIfNeeded() {
        finishTask?.cancel()
        finishTask = nil
        guard isFinishing || !hasDeliveredResult else { return }
        isFinishing = false
        deliverResult(.cancelled)
    }
    
    private lazy var doneButton:PTBaseButton = {
        let view = PTBaseButton(type: .custom)
        view.setImage(PTImageEditorConfig.share.submitImage, for: .normal)
        view.addActionHandlers { _ in
            self.doneAction()
        }
        view.bounds = CGRect(origin: .zero, size: .init(width: PTAppBaseConfig.share.navBarButtonSize, height: PTAppBaseConfig.share.navBarButtonSize))
        return view
    }()
    
    public lazy var mainScrollView: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .black
        view.minimumZoomScale = PTImageEditorConfig.share.minimumZoomScale
        view.maximumZoomScale = 3
        view.delegate = self
        return view
    }()
    
    private var editImage: UIImage
    private let originalImage: UIImage
    /// 是否允许交换图片宽高
    private var shouldSwapSize: Bool {
        currentClipStatus.angle.pt.toPi.truncatingRemainder(dividingBy: .pi) != 0
    }
    var imageSize: CGSize {
        if shouldSwapSize {
            return CGSize(width: originalImage.size.height, height: originalImage.size.width)
        } else {
            return originalImage.size
        }
    }
    lazy var imageView:UIImageView = {
        let view = UIImageView(image: originalImage)
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.backgroundColor = .black
        return view
    }()

    private lazy var containerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    private lazy var circleMaskLayer: CAShapeLayer = {
        CAShapeLayer()
    }()

    private lazy var drawBar:UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var eraser:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(UIImage(.eraser), for: .normal)
        view.setImage(UIImage(.eraser.fill), for: .selected)
        view.addActionHandlers { sender in
            switch self.selectedTool?.currentType {
            case .draw,.mosaic:
                sender.isSelected = !sender.isSelected
                self.eraserCircleView.isHidden = !sender.isSelected
            case .imageSticker:
                self.stickerEngine.removeBackgroundForSelectedSticker()
            default:break
            }
        }
        return view
    }()
    
    private lazy var drawDismissButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(PTImageEditorConfig.share.backImage, for: .normal)
        view.addActionHandlers { sender in
            self.activeEngine?.toolDidDeactivate()
            self.activeEngine = nil
            
            self.showHandDrawBar(show: false)
            self.viewToolsBar(show: true)
        }
        view.isHidden = true
        view.isUserInteractionEnabled = false
        return view
    }()
    
    static let maxDrawLineImageWidth: CGFloat = 600
    private lazy var drawColor:UIColor = .systemRed
    private var defaultDrawPathWidth: CGFloat = 0
    private lazy var drawColorButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(UIImage(.paintpalette), for: .normal)
        view.addActionHandlers { sender in
            self.navigationController?.navigationBar.alpha = 1
            let colorPicker = PTColorPickerContainerViewController()
            colorPicker.backButton.setImage(PTImageEditorConfig.share.colorPickerBackImage, for: .normal)
            colorPicker.picker.selectedColor = self.drawColor
            colorPicker.selectedColorCallback = { color in
                self.drawEngine.drawColor = color
            }
            self.navigationController?.pushViewController(colorPicker, completion: {
            })
            colorPicker.viewDismiss = {
                PTGCDManager.shared.runOnMain {
                    if let engine = self.activeEngine {
                        self.navigationController?.navigationBar.alpha = 0
                    }
                }
            }
        }
        return view
    }()
    
    public lazy var eraserCircleView: UIImageView = {
        var eraserImage = UIImage()
        eraserImage = UIImage(.eraser)
        let imageView = UIImageView(image: eraserImage)
        imageView.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        imageView.isHidden = true
        return imageView
    }()
    
    private var editorManager: PTMediaEditManager

    private var isFinishing = false
    private var finishTask: Task<Void, Never>?
    private var hasDeliveredResult = false
    
    /// 记录当前正在使用的工具引擎
    private var activeEngine: PTEditImageToolEngine?
    
    /// 涂鸦引擎
    private lazy var drawEngine: PTDrawEngine = {
        let engine = PTDrawEngine(context: self)
        engine.onInteractStateChanged = { [weak self] isInteracting in
            self?.viewToolsBar(show: !isInteracting)
        }
        return engine
    }()
    
    /// 马赛克引擎
    private lazy var mosaicEngine: PTMosaicEngine = {
        let engine = PTMosaicEngine(context: self)
        engine.onInteractStateChanged = { [weak self] isInteracting in
            self?.viewToolsBar(show: !isInteracting)
        }
        return engine
    }()

    /// 贴纸大管家引擎
    private lazy var stickerEngine: PTStickerEngine = {
        let engine = PTStickerEngine(context: self)
        engine.onInteractStateChanged = { [weak self] isInteracting in
            self?.viewToolsBar(show: !isInteracting)
        }
        engine.onRequestImageSelection = { [weak self] completion in
            // 把引擎的接收闭包存起来，然后去开相册
            self?.openImagePicker(forReplacement: completion)
        }
        engine.onProcessingStateChanged = { [weak self] isProcessing in
            if isProcessing {
                PTNSLogConsole("正在进行智能抠图...")
            } else {
                // 隐藏 Loading HUD
                PTNSLogConsole("抠图完成")
            }
        }
        return engine
    }()

    /// 调节参数引擎
    private lazy var adjustEngine: PTAdjustEngine = {
        return PTAdjustEngine(context: self)
    }()

    /// 滤镜引擎
    private lazy var filterEngine: PTFilterEngine = {
        return PTFilterEngine(context: self)
    }()

    private var imageReplacementCompletion: ((UIImage?) -> Void)?
    
    private lazy var panGes: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer { sender in
            if let pan = sender as? UIPanGestureRecognizer {
                // 告诉涂鸦引擎，当前是否处于橡皮擦模式
                self.drawEngine.isEraserMode = self.eraser.isSelected
                self.mosaicEngine.isEraserMode = self.eraser.isSelected
                // 🔥 核心魔法：VC 不再关心具体手势计算，直接抛给当前活跃的引擎！
                self.activeEngine?.handlePanGesture(pan)
            }
        }
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        return pan
    }()
    
    public lazy var ashbinView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray
        view.layer.cornerRadius = 15
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()
    public lazy var ashbinImgView = UIImageView(image: UIImage(.trash), highlightedImage: UIImage(.trash.fill))

    public override func preferredNavigationBarStyle() -> PTNavigationBarStyle {
        return .solid(.clear)
    }

    public init(readyEditImage: UIImage) {
        var readyEditImage = readyEditImage
        
        if readyEditImage.scale != 1,let cgImages = readyEditImage.cgImage {
            readyEditImage = readyEditImage.pt.resize_vI(CGSize(width: cgImages.width, height: cgImages.height), scale: 1) ?? readyEditImage
        }
        
        originalImage = readyEditImage.pt.fixOrientation()
        editImage = originalImage
        editImageWithoutAdjust = originalImage
        
        currentClipStatus = PTClipStatus(editRect: CGRect(origin: .zero, size: originalImage.size))
        preClipStatus = currentClipStatus
        editorManager = PTMediaEditManager(actions: [])
        adjustTools = PTImageEditorConfig.share.adjust_tools

        super.init(nibName: nil, bundle: nil)
        editorManager.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        filterThumbnailTask?.cancel()
        finishTask?.cancel()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setCustomBackButtonView(dismissButton)
        setCustomRightButtons(buttons: [doneButton,redoButton,undoButton])
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
                
        var size = self.drawEngine.drawingImageView.frame.size
        if shouldSwapSize {
            swap(&size.width, &size.height)
        }

        guard size.width.isFinite, size.height.isFinite,
              size.width > 0, size.height > 0,
              editImage.size.width.isFinite, editImage.size.height.isFinite,
              editImage.size.width > 0, editImage.size.height > 0,
              mainScrollView.zoomScale.isFinite, mainScrollView.zoomScale > 0 else {
            defaultDrawPathWidth = PTImageEditorConfig.share.drawLineWidth
            return
        }

        var toImageScale = PTEditImageViewController.maxDrawLineImageWidth / size.width
        if editImage.size.width / editImage.size.height > 1 {
            toImageScale = PTEditImageViewController.maxDrawLineImageWidth / size.height
        }
        
        let width = PTImageEditorConfig.share.drawLineWidth / mainScrollView.zoomScale * toImageScale
        defaultDrawPathWidth = width
        
        PTGCDManager.shared.delayOnMain(time: 0.35, block: {
            self.changeStatusBar(type: .Dark)
        })
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        filterThumbnailTask?.cancel()
        if isFinishing {
            cancelEditingIfNeeded()
        }
        changeStatusBar(type: .Auto)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        resetContainerViewFrame()
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        shouldLayout = true
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        
        redoButton.isEnabled = (editorManager.actions.count != editorManager.redoActions.count)
        undoButton.isEnabled = !editorManager.actions.isEmpty

        adjustEngine.adjustSlider.isHidden = true
        view.addSubviews([mainScrollView,toolCollectionView,ashbinView,adjustEngine.adjustSlider])
        mainScrollView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview()
        }
        mainScrollView.addSubviews([containerView])
        
        containerView.addSubviews([imageView,mosaicEngine.canvasView,drawEngine.canvasView,eraserCircleView,stickerEngine.canvasView])
        
        toolCollectionView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight)
            make.height.equalTo(self.toolCollectionHeight)
        }
        
        let deleteInfo = PTImageEditorConfig.share.deleteAlertTitle
        let stringFont:UIFont = .appfont(size: 12)
        let ashBinViewHeight:CGFloat = 88
        let stringW = UIView.sizeFor(string: deleteInfo, font: stringFont,height: ashBinViewHeight).width + 20
        ashbinView.snp.makeConstraints { make in
            make.width.equalTo(stringW)
            make.height.equalTo(ashBinViewHeight)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarHeight_Total + 100)
        }
        
        let asbinTipLabel = UILabel()
        asbinTipLabel.font = stringFont
        asbinTipLabel.textAlignment = .center
        asbinTipLabel.textColor = .white
        asbinTipLabel.text = deleteInfo
        asbinTipLabel.numberOfLines = 2
        asbinTipLabel.lineBreakMode = .byCharWrapping

        ashbinView.addSubviews([ashbinImgView,asbinTipLabel])
        ashbinImgView.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset(10)
        }
        
        asbinTipLabel.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview().inset(10)
        }
        // 设置 Slider 的位置 (把之前 VC 里关于 adjustSlider.frame 的设置搬过来)
        switch PTImageEditorConfig.share.adjustSliderType {
        case .vertical:
            adjustEngine.adjustSlider.frame = CGRect(x: view.pt.jx_width - 60, y: view.pt.jx_height / 2 - 100, width: 60, height: 200)
        case .horizontal:
            adjustEngine.adjustSlider.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace * 2)
                make.bottom.equalTo(self.adjustCollectionView.snp.top).offset(-20)
                make.height.equalTo(60)
            }
        }

        rotationImageView()
                
        createToolsBar()
        view.addGestureRecognizer(panGes)
        mainScrollView.panGestureRecognizer.require(toFail: panGes)
    }
                
    private func resetContainerViewFrame() {
        let editRect = currentClipStatus.editRect
        let scrollViewSize = mainScrollView.frame.size
        guard editRect.width > 0, editRect.height > 0,
              scrollViewSize.width > 0, scrollViewSize.height > 0,
              editRect.width.isFinite, editRect.height.isFinite else { return }

        let needsLayout = shouldLayout
            || isFirstSetContainerFrame
            || lastContainerScrollSize != scrollViewSize
            || lastContainerEditRect != editRect
            || lastContainerAngle != currentClipStatus.angle
        guard needsLayout else { return }

        lastContainerScrollSize = scrollViewSize
        lastContainerEditRect = editRect
        lastContainerAngle = currentClipStatus.angle
        shouldLayout = false
        let shouldResetZoom = isFirstSetContainerFrame
        isFirstSetContainerFrame = false
        if shouldResetZoom {
            mainScrollView.setZoomScale(1, animated: false)
        }

        imageView.image = editImage
        let editSize = editRect.size
        let ratio = min(scrollViewSize.width / editSize.width, scrollViewSize.height / editSize.height)
        let w = ratio * editSize.width * mainScrollView.zoomScale
        let h = ratio * editSize.height * mainScrollView.zoomScale
        
        let y: CGFloat = max(0, (scrollViewSize.height - h) / 2)
        containerView.frame = CGRect(x: max(0, (scrollViewSize.width - w) / 2), y: y, width: w, height: h)
        mainScrollView.contentSize = containerView.frame.size
        if currentClipStatus.ratio?.isCircle == true {
            let path = UIBezierPath(arcCenter: CGPoint(x: w / 2, y: h / 2), radius: w / 2, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            circleMaskLayer.frame = containerView.bounds
            circleMaskLayer.path = path.cgPath
            containerView.layer.mask = circleMaskLayer
        } else {
            containerView.layer.mask = nil
        }
        let scaleImageOrigin = CGPoint(x: -editRect.origin.x * ratio, y: -editRect.origin.y * ratio)
        let scaleImageSize = CGSize(width: imageSize.width * ratio, height: imageSize.height * ratio)
        imageView.frame = CGRect(origin: scaleImageOrigin, size: scaleImageSize)
        drawEngine.canvasView.frame = imageView.frame
        mosaicEngine.canvasView.frame = imageView.frame
        stickerEngine.canvasView.frame = imageView.frame
        // 针对于长图的优化
        if (editRect.height / editRect.width) > (view.frame.height / view.frame.width * 1.1) {
            let widthScale = w > 0 ? view.frame.width / w : 1
            mainScrollView.maximumZoomScale = max(1, widthScale)
            if shouldResetZoom {
                mainScrollView.zoomScale = max(1, widthScale)
                mainScrollView.contentOffset = .zero
            }
        } else if editRect.width / editRect.height > 1 {
            mainScrollView.maximumZoomScale = h > 0 ? max(3, view.frame.height / h) : 3
        }
        originalFrame = view.convert(containerView.frame, from: mainScrollView)
        isScrolling = false
    }

    func createToolsBar() {
        let rows = toolsModel.map {
            let row = PTRows(dataModel: $0)
            row.cellClass = PTEditToolsCell.self
            return row
        }
        let section = PTSection(rows: rows)
        toolCollectionView.showCollectionDetail(collectionData: [section])
    }
    
    func viewToolsBar(show:Bool) {
        if show {
            UIView.animate(withDuration: 0.25) {
                self.toolCollectionView.alpha = 1
                self.navigationController?.navigationBar.alpha = 1
            }
        } else {
            UIView.animate(withDuration: 0.25) {
                self.toolCollectionView.alpha = 0
                self.navigationController?.navigationBar.alpha = 0
            }
        }
    }
        
    private func rotationImageView() {
        let transform = CGAffineTransform(rotationAngle: (currentClipStatus.angle / 180 * .pi))
        imageView.transform = transform
    }
    
    // English: Downsample only the final result so crop coordinates remain in the editor's source space.
    // Español: Reduce la muestra solo del resultado final para conservar las coordenadas del recorte.
    // 中文：只对最终结果降采样，确保裁剪坐标仍使用编辑器原始坐标系。
    private func applyOutputPolicy(to image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage,
              cgImage.width > 0,
              cgImage.height > 0 else {
            return nil
        }

        let maximums: (pixelCount: Double, dimension: Double)?
        switch PTImageEditorConfig.share.outputPolicy {
        case .original:
            return image
        case .safe:
            maximums = (24_000_000, 16_384)
        case let .custom(maximumPixelCount, maximumDimension):
            guard maximumPixelCount > 0, maximumDimension > 0 else { return nil }
            maximums = (Double(maximumPixelCount), Double(maximumDimension))
        }

        let width = Double(cgImage.width)
        let height = Double(cgImage.height)
        let pixelCount = width * height
        guard width.isFinite, height.isFinite,
              pixelCount.isFinite, pixelCount > 0,
              let maximums,
              maximums.pixelCount.isFinite,
              maximums.dimension.isFinite else {
            return nil
        }

        let dimensionScale = maximums.dimension / max(width, height)
        let pixelScale = sqrt(maximums.pixelCount / pixelCount)
        let scale = min(1, dimensionScale, pixelScale)
        guard scale.isFinite, scale > 0 else { return nil }
        guard scale < 0.999 else { return image }

        let targetSize = CGSize(width: CGFloat(max(1, floor(width * scale))),
                                height: CGFloat(max(1, floor(height * scale))))
        guard targetSize.width.isFinite, targetSize.height.isFinite else { return nil }
        return image.pt.resize_vI(targetSize, scale: 1)
    }

    private func buildImage() -> UIImage {
        let image = UIGraphicsImageRenderer.pt.renderImage(size: editImage.size) { format in
            format.scale = self.editImage.scale
        } imageActions: { context in
            // 【新增】：加入 autoreleasepool 保护内存
            autoreleasepool {
                editImage.draw(at: .zero)
                
                // 👇 新增：把马赛克画进去
                if !mosaicEngine.mosaicPaths.isEmpty, mosaicEngine.canvasView.frame.width > 0 {
                    let scale = imageSize.width / mosaicEngine.canvasView.frame.width
                    if scale.isFinite, scale > 0 {
                        context.concatenate(CGAffineTransform(scaleX: scale, y: scale))
                        mosaicEngine.canvasView.layer.render(in: context)
                        context.concatenate(CGAffineTransform(scaleX: 1 / scale, y: 1 / scale))
                    }
                }
                
                // 👇 新增：把涂鸦画笔画进去
                if !drawEngine.drawPaths.isEmpty, drawEngine.canvasView.frame.width > 0 {
                    let scale = imageSize.width / drawEngine.canvasView.frame.width
                    if scale.isFinite, scale > 0 {
                        context.concatenate(CGAffineTransform(scaleX: scale, y: scale))
                        drawEngine.canvasView.layer.render(in: context)
                        context.concatenate(CGAffineTransform(scaleX: 1 / scale, y: 1 / scale))
                    }
                }

                if !stickerEngine.canvasView.subviews.isEmpty, stickerEngine.canvasView.frame.width > 0 {
                    let scale = imageSize.width / stickerEngine.canvasView.frame.width
                    let stickerViews = stickerEngine.canvasView.subviews.compactMap { $0 as? PTBaseStickerView }
                    let exportAppearances = stickerViews.map { $0.prepareForExport() }
                    defer {
                        zip(stickerViews, exportAppearances).forEach { sticker, appearance in
                            sticker.restoreAfterExport(appearance)
                        }
                    }
                    if scale.isFinite, scale > 0 {
                        context.concatenate(CGAffineTransform(scaleX: scale, y: scale))
                        stickerEngine.canvasView.layer.render(in: context)
                        context.concatenate(CGAffineTransform(scaleX: 1 / scale, y: 1 / scale))
                    }
                }
            }
        }
        
        guard let cgi = image.cgImage else {
            return editImage
        }
        return UIImage(cgImage: cgi, scale: editImage.scale, orientation: .up)
    }
    
    public func editImageShow(vc:UIViewController) {
        let nav = PTBaseNavControl(rootViewController: self)
        nav.modalPresentationStyle = .fullScreen
        vc.showDetailViewController(nav, sender: nil)
    }
}

//MARK: About draw
extension PTEditImageViewController {
    private func showHandDrawAction() {
        
        let tool = self.toolsModel.first(where: { $0.currentType == .draw } )
        let toolsSelected = tool?.isSelected ?? false
        selectedTool = toolsSelected ? tool : nil
        // 引擎切换逻辑        
        activeEngine?.toolDidDeactivate()
        activeEngine = toolsSelected ? drawEngine : nil
        activeEngine?.toolDidActivate()
        
        showHandDrawBar(show: toolsSelected)
        showFilter(show: false)
        showAdjust(show:false)
    }
    
    func showHandDrawBar(show:Bool,isMosaic:Bool = false) {
        if show {
            view.addSubviews([drawBar,drawDismissButton])
            drawDismissButton.snp.makeConstraints { make in
                make.size.equalTo(PTAppBaseConfig.share.navBarButtonSize)
                make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                make.top.equalToSuperview().inset(CGFloat.statusBarHeight() + (CGFloat.kNavBarHeight - PTAppBaseConfig.share.navBarButtonSize) / 2)
            }
            drawBar.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(54)
                make.bottom.equalTo(self.toolCollectionView.snp.top)
            }
            
            var subs = [UIView]()
            switch selectedTool?.currentType {
            case .draw:
                subs = [eraser,drawColorButton]
            case .mosaic:
                subs = [eraser]
            case .imageSticker,.textSticker:
                subs = [eraser]
            default:
                subs = []
            }
            
            drawBar.addSubviews(subs)
            eraser.snp.makeConstraints { make in
                make.size.equalTo(44)
                make.centerY.equalToSuperview()
                switch selectedTool?.currentType {
                case .draw:
                    make.right.equalTo(self.drawBar.snp.centerX).offset(-15)
                case .mosaic:
                    make.centerX.equalToSuperview()
                case .imageSticker,.textSticker:
                    make.centerX.equalToSuperview()
                default:break
                }
            }
            
            switch selectedTool?.currentType {
            case .draw:
                drawColorButton.snp.makeConstraints { make in
                    make.size.centerY.equalTo(self.eraser)
                    make.left.equalTo(self.drawBar.snp.centerX).offset(15)
                }
            default:break
            }

            drawDismissButton.isHidden = false
            drawDismissButton.isUserInteractionEnabled = true
        } else {
            drawDismissButton.removeFromSuperview()
            drawBar.removeFromSuperview()
        }
    }
            
    private func mosaicAction() {
        let isSelected = selectedTool?.currentType != .mosaic
        let tool = self.toolsModel.first(where: { $0.currentType == .mosaic } )
        selectedTool = isSelected ? tool : nil
        
        // 引擎切换逻辑
        activeEngine?.toolDidDeactivate()
        activeEngine = isSelected ? mosaicEngine : nil
        activeEngine?.toolDidActivate()

        showHandDrawBar(show: isSelected, isMosaic: true)
        showFilter(show: false)
        showAdjust(show:false)
    }
}

//MARK: Cut
extension PTEditImageViewController {
    func showClipAction() {
        
        preClipStatus = currentClipStatus
        
        let currentEditImage = buildImage()
        let vc = PTCutViewController(image: currentEditImage, status: currentClipStatus)
        let rect = mainScrollView.convert(containerView.frame, to: view)
        vc.presentAnimateFrame = rect
        vc.presentAnimateImage = currentEditImage.pt.clipImage(angle: currentClipStatus.angle, editRect: currentClipStatus.editRect, isCircle: currentClipStatus.ratio?.isCircle ?? false)
        vc.clipDoneBlock = { [weak self] angle, editRect, selectRatio in
            guard let `self` = self else { return }
            let oldStatus = self.preClipStatus
            self.clipImage(status: PTClipStatus(angle: angle, editRect: editRect, ratio: selectRatio))
            let oldRatio = oldStatus.ratio
            let newRatio = self.currentClipStatus.ratio
            let ratioChanged: Bool
            switch (oldRatio, newRatio) {
            case (nil, nil):
                ratioChanged = false
            case let (old?, new?):
                ratioChanged = old != new
            default:
                ratioChanged = true
            }
            if oldStatus.angle != self.currentClipStatus.angle
                || oldStatus.editRect != self.currentClipStatus.editRect
                || ratioChanged {
                self.editorManager.storeAction(.clip(oldStatus: oldStatus, newStatus: self.currentClipStatus))
            }
            self.mainScrollView.alpha = 1
        }
        
        self.navigationController?.pushViewController(vc)
        
        toolsModel.first(where: { $0.currentType == .clip })?.isSelected = false
        selectedTool = nil
        showHandDrawBar(show: false)
        showFilter(show: false)
        showAdjust(show:false)
    }

    private func clipImage(status: PTClipStatus) {
        let oldAngle = currentClipStatus.angle
        if oldAngle != status.angle {
            currentClipStatus.angle = status.angle
            rotationImageView()
        }
        
        currentClipStatus.editRect = status.editRect
        currentClipStatus.ratio = status.ratio
        resetContainerViewFrame()
    }

    func finishClipDismissAnimate() {
        mainScrollView.alpha = 1
        UIView.animate(withDuration: 0.1) {
            self.toolCollectionView.alpha = 1
            self.navigationController?.navigationBar.alpha = 1
        }
    }
}

//MARK: TextInput
extension PTEditImageViewController {
    func showTextAction() {
        stickerEngine.createTextSticker(font: PTImageEditorConfig.share.textStickerDefaultFont)
        toolsModel.first(where: { $0.currentType == .textSticker })?.isSelected = false
        selectedTool = nil
        activeEngine?.toolDidDeactivate()
        activeEngine = nil
        showHandDrawBar(show: false)
        showFilter(show: false)
        showAdjust(show:false)
    }
}

//MARK: ImageInput
extension PTEditImageViewController {
    func showImageAction() {
        let tool = self.toolsModel.first(where: { $0.currentType == .imageSticker } )
        let toolsSelected = tool?.isSelected ?? false
        selectedTool = toolsSelected ? tool : nil
        if toolsSelected {
            openImagePicker(forReplacement: nil)
        }
        // 引擎切换逻辑
        activeEngine?.toolDidDeactivate()
        activeEngine = toolsSelected ? stickerEngine : nil
        activeEngine?.toolDidActivate()
        
        showHandDrawBar(show: toolsSelected)
        showFilter(show: false)
        showAdjust(show:false)
    }
    
    private func openImagePicker(forReplacement completion: ((UIImage?) -> Void)?) {
        self.imageReplacementCompletion = completion

        let vc = PTMediaLibViewController()
        vc.selectionOptions = .singleImage
        vc.mediaLibShow()
        vc.selectImageBlock = { [weak self] item,isOriginal in
            guard let self else { return }
            defer {
                self.imageReplacementCompletion = nil
            }
            if let completion = self.imageReplacementCompletion {
                if let image = item.first?.image {
                    completion(image)
                } else {
                    completion(nil)
                }
            } else {
                if let image = item.first?.image {
                    self.stickerEngine.addImageSticker(image)
                }
            }
        }
    }
}

//MARK: Filter
extension PTEditImageViewController {
    
    private func filterAction() {
        let isSelected = selectedTool?.currentType != .filter
        let tool = self.toolsModel.first(where: { $0.currentType == .filter } )
        selectedTool = isSelected ? tool : nil
        
        activeEngine?.toolDidDeactivate()
        activeEngine = isSelected ? filterEngine : nil
        activeEngine?.toolDidActivate()

        showHandDrawBar(show: false)
        showFilter(show: isSelected)
        showAdjust(show:false)
    }

    func showFilter(show:Bool) {
        if show {
            view.addSubview(filterCollectionView)
            filterCollectionView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalTo(self.toolCollectionView.snp.top)
                make.height.equalTo(PTCutViewController.cutRatioHeight)
            }
            
            reloadFilterItems()

            if filterEngine.thumbnailFilterImages.count != PTImageEditorConfig.share.filters.count {
                filterThumbnailTask?.cancel()
                filterThumbnailTask = Task { @MainActor [weak self] in
                    guard let self else { return }
                    await self.filterEngine.generateFilterThumbnails()
                    guard !Task.isCancelled else { return }
                    self.reloadFilterItems()
                }
            }
        } else {
            filterThumbnailTask?.cancel()
            filterCollectionView.removeFromSuperview()
        }
    }

    private func reloadFilterItems() {
        let rows = filterEngine.thumbnailFilterImages.map {
            PTRows(ID: PTFilterImageCell.ID, dataModel: $0)
        }
        filterCollectionView.showCollectionDetail(collectionData: [PTSection(rows: rows)])
    }
}

//MARK: Adjust
extension PTEditImageViewController {
    func adjustActions() {
        let isSelected = selectedTool?.currentType != .adjust
        let tool = self.toolsModel.first(where: { $0.currentType == .adjust } )
        selectedTool = isSelected ? tool : nil

        // 引擎切换
        activeEngine?.toolDidDeactivate()
        activeEngine = isSelected ? adjustEngine : nil
        activeEngine?.toolDidActivate() // 激活时引擎会自动向我们要ReferenceImage
        
        showHandDrawBar(show: false)
        showFilter(show: false)
        showAdjust(show:isSelected)
    }
    
    func showAdjust(show:Bool) {
        if show {
            adjustEngine.adjustSlider.isHidden = false
            view.addSubviews([adjustCollectionView])
            adjustCollectionView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalTo(self.toolCollectionView.snp.top)
                make.height.equalTo(self.adjustCollectionViewHeight)
            }
            
            let rows = adjustTools.map {
                let model = PTFusionCellModel()
                switch $0 {
                case .brightness:
                    model.contentIcon = UIImage(.light.min)
                    model.disclosureIndicatorImage = UIImage(.light.max)
                    model.name = PTImageEditorConfig.share.adjustBrightnessString
                case .saturation:
                    model.contentIcon = UIImage(.drop)
                    model.disclosureIndicatorImage = UIImage(.drop.fill)
                    model.name = PTImageEditorConfig.share.adjustSaturationString
                default:
                    model.contentIcon = UIImage(.circle)
                    model.disclosureIndicatorImage = UIImage(.circle.fill)
                    model.name = PTImageEditorConfig.share.adjustContrastString
                }
                return PTRows(ID:PTAdjustToolCell.ID,dataModel: model)
            }
            
            let section = PTSection(rows: rows)
            adjustCollectionView.showCollectionDetail(collectionData: [section])

        } else {
            adjustCollectionView.removeFromSuperview()
            adjustEngine.adjustSlider.isHidden = true
        }
    }
}

//MARK: UIScrollViewDelegate
extension PTEditImageViewController {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        containerView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = (scrollView.frame.width > scrollView.contentSize.width) ? (scrollView.frame.width - scrollView.contentSize.width) * 0.5 : 0
        let offsetY = (scrollView.frame.height > scrollView.contentSize.height) ? (scrollView.frame.height - scrollView.contentSize.height) * 0.5 : 0
        containerView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        isScrolling = false
    }
    
    public override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        guard scrollView == mainScrollView else {
            return
        }
        isScrolling = true
    }
    
    public override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        super.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
        guard scrollView == mainScrollView else {
            return
        }
        isScrolling = decelerate
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == mainScrollView else {
            return
        }
        isScrolling = false
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView == mainScrollView else {
            return
        }
        isScrolling = false
    }
}

// MARK: UIGestureRecognizerDelegate
extension PTEditImageViewController {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer {
            if toolCollectionView.alpha == 1 {
                let p = gestureRecognizer.location(in: view)
                return !toolCollectionView.frame.contains(p)
            } else if filterCollectionView.alpha == 1 {
                let p = gestureRecognizer.location(in: view)
                return !filterCollectionView.frame.contains(p)
            } else if adjustCollectionView.alpha == 1 {
                let p = gestureRecognizer.location(in: view)
                return !adjustCollectionView.frame.contains(p)
            } else {
                return true
            }
        } else if gestureRecognizer is UIPanGestureRecognizer {
            guard let selectedTool = selectedTool else {
                return false
            }
            return (selectedTool.currentType == .draw || selectedTool.currentType == .mosaic) && !isScrolling
        }
        
        return true
    }
}

// MARK: unod & redo
extension PTEditImageViewController: @MainActor PTMediaEditorManagerDelegate {
    public func editorManager(_ manager: PTMediaEditManager, didUpdateActions actions: [PTMediaEditorAction], redoActions: [PTMediaEditorAction]) {
        undoButton.isEnabled = !actions.isEmpty
        redoButton.isEnabled = actions.count != redoActions.count
    }
    
    public func editorManager(_ manager: PTMediaEditManager, undoAction action: PTMediaEditorAction) {
        switch action {
        case let .draw(path):
            undoDraw(path)
        case let .clip(oldStatus, _):
            undoOrRedoClip(oldStatus)
        case let .sticker(oldState, newState):
            undoSticker(oldState, newState)
        case let .mosaic(path):
            undoMosaic(path)
        case let .filter(oldFilter, _):
            undoOrRedoFilter(oldFilter)
        case let .adjust(oldStatus, _):
            undoOrRedoAdjust(oldStatus)
        case let .imageSticker(oldState, newState):
            undoSticker(oldState, newState)
        }
    }
    
    public func editorManager(_ manager: PTMediaEditManager, redoAction action: PTMediaEditorAction) {
        switch action {
        case let .draw(path):
            redoDraw(path)
        case let .clip(_, newStatus):
            undoOrRedoClip(newStatus)
        case let .sticker(oldState, newState):
            redoSticker(oldState, newState)
        case let .mosaic(path):
            redoMosaic(path)
        case let .filter(_, newFilter):
            undoOrRedoFilter(newFilter)
        case let .adjust(_, newStatus):
            undoOrRedoAdjust(newStatus)
        case let .imageSticker(oldState, newState):
            redoSticker(oldState, newState)
        }
    }
    
    private func undoDraw(_ path: PTDrawPath) {
        guard let index = drawEngine.drawPaths.lastIndex(where: { $0 == path }) else { return }
        drawEngine.drawPaths.remove(at: index)
        drawEngine.reloadRenderState() // 通知引擎重绘
    }
    
    private func redoDraw(_ path: PTDrawPath) {
        guard !drawEngine.drawPaths.contains(path) else { return }
        drawEngine.drawPaths.append(path)
        drawEngine.reloadRenderState()
    }
        
    private func undoOrRedoClip(_ status: PTClipStatus) {
        clipImage(status: status)
        preClipStatus = status
    }
    
    private func undoMosaic(_ path: PTDrawPath) {
        guard let index = mosaicEngine.mosaicPaths.lastIndex(where: { $0 == path }) else { return }
        mosaicEngine.mosaicPaths.remove(at: index)
        mosaicEngine.reloadRenderState()
    }
    
    private func redoMosaic(_ path: PTDrawPath) {
        guard !mosaicEngine.mosaicPaths.contains(path) else { return }
        mosaicEngine.mosaicPaths.append(path)
        mosaicEngine.reloadRenderState()
    }
    
    private func undoSticker(_ oldState: PTBaseStickertState?, _ newState: PTBaseStickertState?) {
        stickerEngine.undoOrRedoSticker(oldState: oldState, newState: newState, isUndo: true)
    }
    
    private func redoSticker(_ oldState: PTBaseStickertState?, _ newState: PTBaseStickertState?) {
        stickerEngine.undoOrRedoSticker(oldState: oldState, newState: newState, isUndo: false)
    }
            
    private func undoOrRedoFilter(_ filter: PTHarBethFilter?) {
        let filter = filter ?? .none
        filterEngine.changeFilter(filter) // 引擎会处理并触发 rebuildRenderPipeline
        let filters = PTImageEditorConfig.share.filters
        
        guard let index = filters.firstIndex(where: { $0.name == filter.name }) else {
            return
        }
        
        let indexPath = IndexPath(row: index, section: 0)
        
        filterCollectionView.contentCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
        filterCollectionView.contentCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        if let row = filterCollectionView.getRow(at: indexPath) {
            filterCollectionView.reloadRows([row], in: 0)
        }
    }
    
    private func undoOrRedoAdjust(_ status: PTAdjustStatus) {
        var adjustTool: PTHarBethFilter.FiltersTool?
        
        if adjustEngine.currentAdjustStatus.brightness != status.brightness {
            adjustTool = .brightness
        } else if adjustEngine.currentAdjustStatus.contrast != status.contrast {
            adjustTool = .contrast
        } else if adjustEngine.currentAdjustStatus.saturation != status.saturation {
            adjustTool = .saturation
        }
        
        adjustEngine.currentAdjustStatus = status
        adjustEngine.preAdjustStatus = status
        adjustEngine.reloadRenderState() // 通知引擎刷新渲染
        
        guard let adjustTool else { return }
        adjustEngine.changeAdjustTool(adjustTool)
        guard let index = adjustTools.firstIndex(where: { $0 == adjustTool }) else {
            return
        }
        
        let indexPath = IndexPath(row: index, section: 0)
        adjustCollectionView.contentCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        adjustCollectionView.contentCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        if let row = adjustCollectionView.getRow(at: indexPath) {
            adjustCollectionView.reloadRows([row], in: 0)
        }
    }
}

extension PTEditImageViewController: @MainActor PTEditImageEngineContext {
    public var engineScrollView: UIScrollView { mainScrollView }
    public var engineOriginalImageSize: CGSize { originalImage.size }
    public var engineEditImageSize: CGSize { editImage.size }
    public var engineEditRect: CGRect { currentClipStatus.editRect }
    public var engineShouldSwapSize: Bool { shouldSwapSize }
    public var engineCurrentAngle: CGFloat { currentClipStatus.angle }
    public var engineEditorManager: PTMediaEditManager { editorManager }
    public var engineEraserCircleView: UIImageView { eraserCircleView }
    
    public var engineOriginalImage: UIImage { originalImage }
    public var engineCurrentEditImage: UIImage { editImage }
    
    // 接收马赛克引擎烘焙好的新图片
    public func engineUpdateEditImage(_ newImage: UIImage) {
        self.editImage = newImage
        self.imageView.image = newImage
    }
    
    public var engineMainView: UIView { view }
    public var engineViewController: UIViewController { self }
    public var engineAshbinView: UIView { ashbinView }
    public var engineAshbinImgView: UIImageView { ashbinImgView }
    
    public var engineImageWithoutAdjust: UIImage { editImageWithoutAdjust }
        
    // 这个就是核心桥梁：当 Adjust 激活时，VC 调动 Mosaic 引擎为它生成专属底图
    public func engineRequestAdjustReferenceImage() -> UIImage {
        // 利用马赛克引擎暴露的方法生成图
        return editImageWithoutAdjust
//        return mosaicEngine.generateNewMosaicImage(
//            inputImage: editImageWithoutAdjust,
//            inputMosaicImage: editImageWithoutAdjust.pt.mosaicImage()
//        ) ?? editImageWithoutAdjust
    }
    
    public var engineThumbnailImage: UIImage? { thumbnailImage }
        
    // 当滤镜引擎把图做好了交给我们时：
    public func engineDidUpdateFilteredBaseImage(_ newBaseImage: UIImage) {
        self.editImageWithoutAdjust = newBaseImage
        self.rebuildRenderPipeline() // 启动渲染流水线！
    }
}

extension PTEditImageViewController {
    
    /// 重新构建图像渲染流水线：Filter -> Adjust -> Mosaic
    private func rebuildRenderPipeline() {
        // 第一站：拿到刚刚经过滤镜处理的纯净底图
        let baseImage = self.editImageWithoutAdjust
        
        // 第二站：送进参数调节引擎 (如果亮度/饱和度都是0，它会直接原样返回)
        let adjustedImage = adjustEngine.adjustFilterValueSet(filterImage: baseImage) ?? baseImage
        self.editImage = adjustedImage
        
        // 第三站：直接更新主画布
        self.imageView.image = self.editImage
        
        // 第四站：通知马赛克引擎更新它的模糊底图（防止原图加了滤镜，但马赛克还是原来的颜色）
        if PTImageEditorConfig.share.tools.contains(.mosaic) {
            mosaicEngine.updateBaseMosaicImage(self.editImage)
        }
    }
}
