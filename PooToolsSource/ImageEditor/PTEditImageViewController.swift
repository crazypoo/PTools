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

public class PTEditImageViewController: PTBaseViewController {

    public var editFinishBlock: ((UIImage, PTEditModel?) -> Void)?
    public var backHandler:PTActionTask?
    
    let adjustCollectionViewHeight : CGFloat = 74
    private var animate = false
    private var isScrolling = false
    private var shouldLayout = true
    var originalFrame: CGRect = .zero
    private var isFirstSetContainerFrame = true
    private var adjustTools: [PTHarBethFilter.FiltersTool]!
    private var currentClipStatus: PTClipStatus!
    private var preClipStatus: PTClipStatus!
    private var editImageWithoutAdjust: UIImage!

    private lazy var thumbnailImage: UIImage? = {
        let size: CGSize
        let ratio = (originalImage.size.width / originalImage.size.height)
        let fixLength: CGFloat = 200
        
        if ratio >= 1 {
            size = CGSize(width: fixLength * ratio, height: fixLength)
        } else {
            size = CGSize(width: fixLength, height: fixLength / ratio)
        }
        
        // 使用你原有的扩展方法进行缩放
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
            return UICollectionView.girdCollectionLayout(data: sectionModel.rows, itemHeight: self.toolCollectionHeight,cellRowCount:6,originalX: PTAppBaseConfig.share.defaultViewSpace,cellLeadingSpace: 15)
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
            let cellTools = self.toolsModel[indexPath.row]
            for i in self.toolsModel.indices {
                self.toolsModel[i].isSelected = i == indexPath.row
            }
            self.toolCollectionView.reloadSections(at: [0]) {
                switch cellTools.currentType {
                case .draw:
                    self.showHandDrawAction()
                case .clip:
                    self.showClipAction()
                case .textSticker:
                    self.showTextAction()
                case .mosaic:
                    self.mosaicAction()
                case .filter:
                    self.filterAction()
                case .adjust:
                    self.adjustActions()
                }
            }
        }
        return view
    }()
    
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
            if let itemRow = sectionModel.rows?[indexPath.row],let cellTools = itemRow.dataModel as? UIImage,let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTFilterImageCell {
                let cellFilter = PTImageEditorConfig.share.filters[indexPath.row]
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
            let filter = PTImageEditorConfig.share.filters[indexPath.row]
            self.editorManager.storeAction(.filter(oldFilter: self.filterEngine.currentFilter, newFilter: filter))
            self.filterEngine.changeFilter(filter)
            collection.reloadData()
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
            if adjustTool != self.adjustEngine.selectedAdjustTool {
                self.adjustEngine.changeAdjustTool(adjustTool) // 转交引擎处理
            }
            collection.reloadData()
        }
        return view
    }()
    
    private lazy var dismissButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(PTImageEditorConfig.share.backImage, for: .normal)
        view.addActionHandlers { sender in
            self.returnFrontVC()
            self.backHandler?()
        }
        return view
    }()
    
    private lazy var undoButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(PTImageEditorConfig.share.undoNormal, for: .normal)
        view.setImage(PTImageEditorConfig.share.undoDisable, for: .disabled)
        view.addActionHandlers { sender in
            self.editorManager.undoAction()
        }
        view.bounds = CGRect(origin: .zero, size: .init(width: 34, height: 34))
        return view
    }()
    
    private lazy var redoButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(PTImageEditorConfig.share.redoNormal, for: .normal)
        view.setImage(PTImageEditorConfig.share.redoDisable.withTintColor(.lightGray), for: .disabled)
        view.addActionHandlers { sender in
            self.editorManager.redoAction()
        }
        view.bounds = CGRect(origin: .zero, size: .init(width: 34, height: 34))
        return view
    }()
    
    private lazy var doneButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(PTImageEditorConfig.share.submitImage, for: .normal)
        view.addActionHandlers { sender in
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
               self.adjustEngine.currentAdjustStatus.allValueIsZero {
                hasEdit = false
            }
            
            guard hasEdit else {
                self.dismiss(animated: self.animate) {
                    self.editFinishBlock?(self.originalImage, nil)
                }
                return
            }

            // 2. 弹出提示框
            PTAlertTipsViewController.tipsAlertShow(title: PTImageEditorConfig.share.doingAlertTitle, icon: .Heart)

            // 3. 🚀 开启现代并发任务进行图片合成
            Task { @MainActor in
                // 巧妙的机制：让出当前线程的控制权 (极短暂睡眠)，确保系统的 RunLoop 有时间把上面那句 HUD 渲染到屏幕上
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                
                // 开始合成大图 (buildImage 内部有图层渲染，必须在 MainActor 执行)
                var resImage = self.buildImage()
                resImage = resImage.pt.clipImage(
                    angle: self.currentClipStatus.angle,
                    editRect: self.currentClipStatus.editRect,
                    isCircle: self.currentClipStatus.ratio?.isCircle ?? false
                )
                
                let editModel = PTEditModel(
                    drawPaths: self.drawEngine.drawPaths,
                    mosaicPaths: self.mosaicEngine.mosaicPaths,
                    clipStatus: self.currentClipStatus,
                    adjustStatus: self.adjustEngine.currentAdjustStatus,
                    selectFilter: self.filterEngine.currentFilter,
                    stickers: stickerStates,
                    actions: self.editorManager.actions
                )
                
                // 合成完毕，直接 dismiss
                self.dismiss(animated: self.animate) {
                    self.editFinishBlock?(resImage, editModel)
                }
            }
        }
        view.bounds = CGRect(origin: .zero, size: .init(width: 34, height: 34))
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
    
    private var editImage: UIImage!
    private var originalImage: UIImage!
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

    private lazy var drawBar:UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var eraser:UIButton = {
        let view = UIButton(type: .custom)
        if #available(iOS 16.0, *) {
            view.setImage(UIImage(.eraser), for: .normal)
            view.setImage(UIImage(.eraser.fill), for: .selected)
        } else {
            view.setImage(UIImage(.clear), for: .normal)
            view.setImage(UIImage(.clear.fill), for: .selected)
        }
        view.addActionHandlers { sender in
            sender.isSelected = !sender.isSelected
        }
        return view
    }()
    
    static let maxDrawLineImageWidth: CGFloat = 600
    private lazy var drawColor:UIColor = .systemRed
    private var defaultDrawPathWidth: CGFloat = 0
    private lazy var drawColorButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(UIImage(.paintpalette), for: .normal)
        view.addActionHandlers { sender in
            let colorPicker = PTColorPickerContainerViewController()
            colorPicker.backButton.setImage(PTImageEditorConfig.share.colorPickerBackImage, for: .normal)
            colorPicker.picker.selectedColor = self.drawColor
            colorPicker.selectedColorCallback = { color in
                self.drawEngine.drawColor = color
            }
            self.navigationController?.pushViewController(colorPicker, completion: {
            })
        }
        return view
    }()
    
    public lazy var eraserCircleView: UIImageView = {
        var eraserImage = UIImage()
        if #available(iOS 16.0, *) {
            eraserImage = UIImage(.eraser)
        } else {
            eraserImage = UIImage(.clear)
        }
        let imageView = UIImageView(image: eraserImage)
        imageView.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        imageView.isHidden = true
        return imageView
    }()
    
    private var editorManager: PTMediaEditManager!
    
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

    private lazy var panGes: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer { sender in
            if let pan = sender as? UIPanGestureRecognizer {
                // 告诉涂鸦引擎，当前是否处于橡皮擦模式
                self.drawEngine.isEraserMode = self.eraser.isSelected
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
        super.init(nibName: nil, bundle: nil)
        var readyEditImage = readyEditImage
        
        if readyEditImage.scale != 1,let cgImages = readyEditImage.cgImage {
            readyEditImage = readyEditImage.pt.resize_vI(CGSize(width: cgImages.width, height: cgImages.height), scale: 1) ?? readyEditImage
        }
        
        originalImage = readyEditImage.pt.fixOrientation()
        editImage = originalImage
        editImageWithoutAdjust = originalImage
        
        currentClipStatus = PTClipStatus(editRect: CGRect(origin: .zero, size: readyEditImage.size))
        preClipStatus = currentClipStatus
        editorManager = PTMediaEditManager(actions: [])
        adjustTools = PTImageEditorConfig.share.adjust_tools
        editorManager.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        
        var toImageScale = PTEditImageViewController.maxDrawLineImageWidth / size.width
        if editImage.size.width / editImage.size.height > 1 {
            toImageScale = PTEditImageViewController.maxDrawLineImageWidth / size.height
        }
        
        let width = PTImageEditorConfig.share.drawLineWidth / mainScrollView.zoomScale * toImageScale
        defaultDrawPathWidth = width
        
        PTGCDManager.gcdAfter(time: 0.35, block: {
            self.changeStatusBar(type: .Dark)
        })
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
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
        undoButton.isEnabled = !(editorManager.actions.count > 0)

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
        if PTImageEditorConfig.share.tools.contains(.filter) {
            Task { @MainActor in
                // await 会在这里挂起等待，直到后台滤镜全算完，才会执行下一行，而不会卡住屏幕！
                await filterEngine.generateFilterThumbnails()
                self.filterCollectionView.contentCollectionView.reloadData()
            }
        }
                
        createToolsBar()
        view.addGestureRecognizer(panGes)
        mainScrollView.panGestureRecognizer.require(toFail: panGes)
    }
                
    private func resetContainerViewFrame() {
        mainScrollView.setZoomScale(1, animated: true)
        imageView.image = editImage
        let editRect = currentClipStatus.editRect
        let editSize = editRect.size
        let scrollViewSize = mainScrollView.frame.size
        let ratio = min(scrollViewSize.width / editSize.width, scrollViewSize.height / editSize.height)
        let w = ratio * editSize.width * mainScrollView.zoomScale
        let h = ratio * editSize.height * mainScrollView.zoomScale
        
        let y: CGFloat = max(0, (scrollViewSize.height - h) / 2)
        containerView.frame = CGRect(x: max(0, (scrollViewSize.width - w) / 2), y: y, width: w, height: h)
        mainScrollView.contentSize = containerView.frame.size
        if currentClipStatus.ratio?.isCircle == true {
            let mask = CAShapeLayer()
            let path = UIBezierPath(arcCenter: CGPoint(x: w / 2, y: h / 2), radius: w / 2, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            mask.path = path.cgPath
            containerView.layer.mask = mask
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
            let widthScale = view.frame.width / w
            mainScrollView.maximumZoomScale = widthScale
            mainScrollView.zoomScale = widthScale
            mainScrollView.contentOffset = .zero
        } else if editRect.width / editRect.height > 1 {
            mainScrollView.maximumZoomScale = max(3, view.frame.height / h)
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
        toolCollectionView.layer.removeAllAnimations()
        navigationController?.navigationBar.layer.removeAllAnimations()
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
    
    private func buildImage() -> UIImage {
        let image = UIGraphicsImageRenderer.pt.renderImage(size: editImage.size) { format in
            format.scale = self.editImage.scale
        } imageActions: { context in
            // 【新增】：加入 autoreleasepool 保护内存
            autoreleasepool {
                editImage.draw(at: .zero)
                
                if !stickerEngine.canvasView.subviews.isEmpty {
                    let scale = imageSize.width / stickerEngine.canvasView.frame.width
                    stickerEngine.canvasView.subviews.forEach { view in
                        (view as? PTStickerViewAdditional)?.resetState()
                    }
                    context.concatenate(CGAffineTransform(scaleX: scale, y: scale))
                    stickerEngine.canvasView.layer.render(in: context)
                    context.concatenate(CGAffineTransform(scaleX: 1 / scale, y: 1 / scale))
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
        
        selectedTool = self.toolsModel.first(where: { $0.currentType == .draw } )
        let toolsSelected = selectedTool?.isSelected ?? false
        // 引擎切换逻辑        
        activeEngine?.toolDidDeactivate()
        activeEngine = toolsSelected ? drawEngine : nil
        activeEngine?.toolDidActivate()

        
        showHandDrawBar(show: toolsSelected)
        showFilter(show: false)
        showAdjust(show:false)
    }
    
    func showHandDrawBar(show:Bool) {
        if show {
            view.addSubview(drawBar)
            drawBar.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(54)
                make.bottom.equalTo(self.toolCollectionView.snp.top)
            }
            
            drawBar.addSubviews([eraser,drawColorButton])
            eraser.snp.makeConstraints { make in
                make.size.equalTo(44)
                make.centerY.equalToSuperview()
                make.right.equalTo(self.drawBar.snp.centerX).offset(-15)
            }
            
            drawColorButton.snp.makeConstraints { make in
                make.size.centerY.equalTo(self.eraser)
                make.left.equalTo(self.drawBar.snp.centerX).offset(15)
            }
        } else {
            drawBar.removeFromSuperview()
        }
    }
            
    private func mosaicAction() {
        let isSelected = selectedTool?.currentType != .mosaic
        selectedTool = self.toolsModel.first(where: { $0.currentType == .mosaic } )
        
        // 引擎切换逻辑
        activeEngine?.toolDidDeactivate()
        activeEngine = isSelected ? mosaicEngine : nil
        activeEngine?.toolDidActivate()

        showHandDrawBar(show: false)
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
            self.clipImage(status: PTClipStatus(angle: angle, editRect: editRect, ratio: selectRatio))
            self.editorManager.storeAction(.clip(oldStatus: self.preClipStatus, newStatus: self.currentClipStatus))
            self.mainScrollView.alpha = 1
        }
        
        self.navigationController?.pushViewController(vc)
        
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
        selectedTool = nil
        activeEngine?.toolDidDeactivate()
        activeEngine = nil
        showHandDrawBar(show: false)
        showFilter(show: false)
        showAdjust(show:false)
    }
}

//MARK: Filter
extension PTEditImageViewController {
    
    private func filterAction() {
        let isSelected = selectedTool?.currentType != .filter
        selectedTool = self.toolsModel.first(where: { $0.currentType == .filter } )
        
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
            
            let rows = self.filterEngine.thumbnailFilterImages.map {
                PTRows(ID:PTFilterImageCell.ID,dataModel: $0)
            }

            let section = PTSection(rows: rows)
            filterCollectionView.showCollectionDetail(collectionData: [section])
        } else {
            filterCollectionView.removeFromSuperview()
        }
    }
}

//MARK: Adjust
extension PTEditImageViewController {
    func adjustActions() {
        let isSelected = selectedTool?.currentType != .adjust
        selectedTool = self.toolsModel.first(where: { $0.currentType == .adjust } )

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
extension PTEditImageViewController: PTMediaEditorManagerDelegate {
    func editorManager(_ manager: PTMediaEditManager, didUpdateActions actions: [PTMediaEditorAction], redoActions: [PTMediaEditorAction]) {
        undoButton.isEnabled = !actions.isEmpty
        redoButton.isEnabled = actions.count != redoActions.count
    }
    
    func editorManager(_ manager: PTMediaEditManager, undoAction action: PTMediaEditorAction) {
        switch action {
        case let .draw(path):
            undoDraw(path)
        case let .eraser(paths):
            undoEraser(paths)
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
        }
    }
    
    func editorManager(_ manager: PTMediaEditManager, redoAction action: PTMediaEditorAction) {
        switch action {
        case let .draw(path):
            redoDraw(path)
        case let .eraser(paths):
            redoEraser(paths)
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
        }
    }
    
    private func undoDraw(_ path: PTDrawPath) {
        drawEngine.drawPaths.removeLast()
        drawEngine.reloadRenderState() // 通知引擎重绘
    }
    
    private func redoDraw(_ path: PTDrawPath) {
        drawEngine.drawPaths.append(path)
        drawEngine.reloadRenderState()
    }
    
    private func undoEraser(_ paths: [PTDrawPath]) {
        paths.forEach { $0.willDelete = false }
        drawEngine.drawPaths.append(contentsOf: paths)
        drawEngine.drawPaths.sort { $0.index < $1.index }
        drawEngine.reloadRenderState()
    }
    
    private func redoEraser(_ paths: [PTDrawPath]) {
        drawEngine.drawPaths.removeAll { paths.contains($0) }
        drawEngine.reloadRenderState()
    }
    
    private func undoOrRedoClip(_ status: PTClipStatus) {
        clipImage(status: status)
        preClipStatus = status
    }
    
    private func undoMosaic(_ path: PTMosaicPath) {
        mosaicEngine.mosaicPaths.removeLast()
        mosaicEngine.reloadRenderState()
    }
    
    private func redoMosaic(_ path: PTMosaicPath) {
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
        guard let filter else { return }
        filterEngine.changeFilter(filter) // 引擎会处理并触发 rebuildRenderPipeline
        let filters = PTImageEditorConfig.share.filters
        
        guard let index = filters.firstIndex(where: { $0.name == filter.name }) else {
            return
        }
        
        let indexPath = IndexPath(row: index, section: 0)
        
        filterCollectionView.contentCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
        filterCollectionView.contentCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
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
        adjustCollectionView.contentCollectionView.reloadData()
    }
}

extension PTEditImageViewController: PTEditImageEngineContext {
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
        return mosaicEngine.generateNewMosaicImage(
            inputImage: editImageWithoutAdjust,
            inputMosaicImage: editImageWithoutAdjust.pt.mosaicImage()
        ) ?? editImageWithoutAdjust
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
        self.editImage = adjustedImage // 暂时保存这个状态
        
        // 第三站：通知马赛克引擎更新它底层的原图图层
        if PTImageEditorConfig.share.tools.contains(.mosaic) {
            mosaicEngine.generateNewMosaicImageLayer()
            
            if mosaicEngine.mosaicPaths.isEmpty {
                // 如果没有马赛克，直接显示调色后的图
                self.imageView.image = self.editImage
            } else {
                // 如果有马赛克，让马赛克引擎把以前的马赛克重新烘焙到新图上！
                mosaicEngine.generateNewMosaicImage()
            }
        } else {
            self.imageView.image = self.editImage
        }
    }
}
