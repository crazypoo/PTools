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
    public var mosaicLineWidth: CGFloat = 25
    public var drawLineWidth: CGFloat = 6
    public var backHandler:PTActionTask?
    
    let adjustCollectionViewHeight : CGFloat = 74
    private var animate = false
    private var thumbnailFilterImages: [UIImage] = []
    // Show text and image stickers.
    private lazy var stickersContainer = UIView()
    private var isScrolling = false
    private var shouldLayout = true
    private var hasAdjustedImage = false
    var originalFrame: CGRect = .zero
    private var isFirstSetContainerFrame = true
    private var selectedTool: PTImageEditorConfig.EditTool?
    private var tools: [PTImageEditorConfig.EditTool]!
    private var adjustTools: [PTHarBethFilter.FiltersTool]!
    private var currentClipStatus: PTClipStatus!
    private var preClipStatus: PTClipStatus!
    private var currentAdjustStatus: PTAdjustStatus!
    private var preAdjustStatus: PTAdjustStatus!
    private var preStickerState: PTBaseStickertState?
    private var currentFilter: PTHarBethFilter!
    private var filterImages: [String: UIImage] = [:]
    private var editImageWithoutAdjust: UIImage!
    private var editImageAdjustRef: UIImage?
    private var selectedAdjustTool: PTHarBethFilter.FiltersTool?

    var toolsModel:[PTFusionCellModel]! {
        let cellModels: [PTFusionCellModel] = tools.map { tool in
            let model = PTFusionCellModel()
            switch tool {
            case .draw:
                model.contentIcon = UIImage(.hand.draw)
                model.disclosureIndicatorImage = UIImage(.hand.drawFill)
                
            case .clip:
                model.contentIcon = UIImage(.scissors)
                
            case .textSticker:
                model.contentIcon = UIImage(.pencil)
                
            case .mosaic:
                model.contentIcon = UIImage(.square.grid_2x2)
                model.disclosureIndicatorImage = UIImage(.square.grid_2x2Fill)
                
            case .filter:
                if #available(iOS 15.0, *) {
                    model.contentIcon = UIImage(.line._3HorizontalDecreaseCircle)
                    model.disclosureIndicatorImage = UIImage(.line._3HorizontalDecreaseCircleFill)
                } else {
                    model.contentIcon = UIImage(.f.cursiveCircle)
                    model.disclosureIndicatorImage = UIImage(.f.cursiveCircleFill)
                }
                
            case .adjust:
                model.contentIcon = UIImage(.ellipsis.rectangle)
                model.disclosureIndicatorImage = UIImage(.ellipsis.rectangleFill)
            }
            
            return model
        }
        return cellModels
    }
    
    private lazy var toolCollectionView : PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Gird
        config.itemOriginalX = PTAppBaseConfig.share.defaultViewSpace
        config.rowCount = 6
        config.cellLeadingSpace = 15
        config.itemHeight = 54

        let view = PTCollectionView(viewConfig: config)
        view.registerClassCells(classs: [PTEditToolsCell.ID:PTEditToolsCell.self])
        view.cellInCollection = { collection,sectionModel,indexPath in
            if let itemRow = sectionModel.rows?[indexPath.row],let cellModel = itemRow.dataModel as? PTFusionCellModel,let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTEditToolsCell {
                let cellTools = self.tools[indexPath.row]
                cell.toolModel = cellModel
                cell.imageView.isSelected = self.selectedTool == cellTools
                return cell
            }
            return nil
        }
        view.collectionDidSelect = { collection,sectionModel,indexPath in
            let cellTools = self.tools[indexPath.row]
            switch cellTools {
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
            self.createToolsBar()
        }
        return view
    }()
    
    private lazy var filterCollectionView : PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Custom

        let view = PTCollectionView(viewConfig: config)
        view.registerClassCells(classs: [PTFilterImageCell.ID:PTFilterImageCell.self])
        view.customerLayout = { sectionIndex,sectionModel in
            var bannerGroupSize : NSCollectionLayoutSize
            var customers = [NSCollectionLayoutGroupCustomItem]()
            var groupW:CGFloat = PTAppBaseConfig.share.defaultViewSpace
            let screenW:CGFloat = 88
            let cellHeight:CGFloat = PTCutViewController.cutRatioHeight
            sectionModel.rows?.enumerated().forEach { (index,model) in
                let customItem = NSCollectionLayoutGroupCustomItem(frame: CGRect(x: PTAppBaseConfig.share.defaultViewSpace + 10 * CGFloat(index) + screenW * CGFloat(index), y: 0, width: screenW, height: cellHeight), zIndex: 1000+index)
                customers.append(customItem)
                groupW += (cellHeight + 10)
            }
            bannerGroupSize = NSCollectionLayoutSize(widthDimension: NSCollectionLayoutDimension.absolute(groupW), heightDimension: NSCollectionLayoutDimension.absolute(cellHeight))
            return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
                customers
            })
        }
        view.cellInCollection = { collection,sectionModel,indexPath in
            let config = PTImageEditorConfig.share
            if let itemRow = sectionModel.rows?[indexPath.row],let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTFilterImageCell {
                let cellTools = itemRow.dataModel as! UIImage
                let cellFilter = PTImageEditorConfig.share.filters[indexPath.row]
                cell.imageView.image = cellTools
                cell.nameLabel.text = cellFilter.name
                if self.currentFilter == cellFilter {
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
            self.editorManager.storeAction(.filter(oldFilter: self.currentFilter, newFilter: filter))
            self.changeFilter(filter)
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
            var bannerGroupSize : NSCollectionLayoutSize
            var customers = [NSCollectionLayoutGroupCustomItem]()
            var groupW:CGFloat = PTAppBaseConfig.share.defaultViewSpace
            let screenW:CGFloat = 54
            let cellHeight:CGFloat = self.adjustCollectionViewHeight
            sectionModel.rows?.enumerated().forEach { (index,model) in
                let customItem = NSCollectionLayoutGroupCustomItem(frame: CGRect(x: PTAppBaseConfig.share.defaultViewSpace + 10 * CGFloat(index) + screenW * CGFloat(index), y: 5, width: screenW, height: cellHeight - 10), zIndex: 1000+index)
                customers.append(customItem)
                groupW += (cellHeight + 10)
            }
            bannerGroupSize = NSCollectionLayoutSize(widthDimension: NSCollectionLayoutDimension.absolute(groupW), heightDimension: NSCollectionLayoutDimension.absolute(cellHeight))
            return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
                customers
            })
        }
        view.cellInCollection = { collection,sectionModel,indexPath in
            let config = PTImageEditorConfig.share
            if let itemRow = sectionModel.rows?[indexPath.row],let cellTools = itemRow.dataModel as? PTFusionCellModel,let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTAdjustToolCell {
                cell.nameLabel.text = cellTools.name
                let tool = self.adjustTools[indexPath.row]
                let isSelected = tool == self.selectedAdjustTool
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
            if adjustTool != self.selectedAdjustTool {
                self.changeAdjustTool(adjustTool)
            }
            collection.reloadData()
        }
        return view
    }()
    
    private lazy var adjustSlider : PTAdjustSliderView = {
        let view = PTAdjustSliderView()
        view.isHidden = true
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
        return view
    }()
    
    private lazy var redoButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(PTImageEditorConfig.share.redoNormal, for: .normal)
        view.setImage(PTImageEditorConfig.share.redoDisable.withTintColor(.lightGray), for: .disabled)
        view.addActionHandlers { sender in
            self.editorManager.redoAction()
        }
        return view
    }()
    
    private lazy var doneButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(PTImageEditorConfig.share.submitImage, for: .normal)
        view.addActionHandlers { sender in
            var stickerStates: [PTBaseStickertState] = []
            for view in self.stickersContainer.subviews {
                guard let view = view as? PTBaseStickerView else { continue }
                stickerStates.append(view.state)
            }
            
            var hasEdit = true
            if self.drawPaths.isEmpty,
               self.currentClipStatus.editRect.size == self.imageSize,
               self.currentClipStatus.angle == 0,
               self.mosaicPaths.isEmpty,
               stickerStates.isEmpty,
               self.currentAdjustStatus.allValueIsZero {
                hasEdit = false
            }
            
            var resImage = self.originalImage
            var editModel: PTEditModel?
            
            @MainActor func callback() {
                self.dismiss(animated: self.animate) {
                    self.editFinishBlock?(resImage!, editModel)
                }
            }
            
            guard hasEdit else {
                callback()
                return
            }
            
            PTAlertTipControl.present(title:PTImageEditorConfig.share.doingAlertTitle,icon:.Heart,style: .Normal)
            PTGCDManager.gcdMain {
                resImage = self.buildImage()
                resImage = resImage!.pt.clipImage(
                    angle: self.currentClipStatus.angle,
                    editRect: self.currentClipStatus.editRect,
                    isCircle: self.currentClipStatus.ratio?.isCircle ?? false
                    )
                editModel = PTEditModel(
                    drawPaths: self.drawPaths,
                    mosaicPaths: self.mosaicPaths,
                    clipStatus: self.currentClipStatus,
                    adjustStatus: self.currentAdjustStatus,
                    selectFilter: self.currentFilter,
                    stickers: stickerStates,
                    actions: self.editorManager.actions
                )
                callback()
            }
        }
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

    private lazy var drawingImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = true
        return view
    }()

    private lazy var containerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    private var drawPaths: [PTDrawPath] = [PTDrawPath]()
    private lazy var deleteDrawPaths: [PTDrawPath] = [PTDrawPath]()
    private var mosaicPaths: [PTMosaicPath] = [PTMosaicPath]()

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
            let colorPicker = UIColorPickerViewController()
            colorPicker.delegate = self
            
            // 设置预选颜色
            colorPicker.selectedColor = self.drawColor
            
            // 显示 alpha 通道
            colorPicker.supportsAlpha = true
            
            // 呈现颜色选择器
            colorPicker.modalPresentationStyle = .fullScreen
            self.navigationController?.pushViewController(colorPicker, completion: {
                let colorPickerBack = UIButton(type: .custom)
                colorPickerBack.bounds = CGRectMake(0, 0, 34, 34)
                colorPickerBack.setImage(PTImageEditorConfig.share.colorPickerBackImage, for: .normal)
                colorPickerBack.addActionHandlers { sender in
                    colorPicker.navigationController?.popViewController(animated: true)
                }
                colorPicker.navigationController?.navigationBar.backgroundColor = .clear
                colorPicker.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: colorPickerBack)
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
    private lazy var panGes: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer { sender in
            if let pan = sender as? UIPanGestureRecognizer {
                if self.eraser.isSelected {
                    self.eraserAction(pan)
                    return
                }
                
                if self.selectedTool == .draw {
                    let point = pan.location(in: self.drawingImageView)
                    if pan.state == .began {
                        self.viewToolsBar(show: false)
                        
                        let originalRatio = min(self.mainScrollView.frame.width / self.originalImage.size.width, self.mainScrollView.frame.height / self.originalImage.size.height)
                        let ratio = min(
                            self.mainScrollView.frame.width / self.currentClipStatus.editRect.width,
                            self.mainScrollView.frame.height / self.currentClipStatus.editRect.height
                        )
                        let scale = ratio / originalRatio
                        // 缩放到最初的size
                        var size = self.drawingImageView.frame.size
                        size.width /= scale
                        size.height /= scale
                        if self.shouldSwapSize {
                            swap(&size.width, &size.height)
                        }
                        
                        var toImageScale = PTEditImageViewController.maxDrawLineImageWidth / size.width
                        if self.editImage.size.width / self.editImage.size.height > 1 {
                            toImageScale = PTEditImageViewController.maxDrawLineImageWidth / size.height
                        }
                        
                        let path = PTDrawPath(pathColor: self.drawColor, pathWidth: self.drawLineWidth / self.mainScrollView.zoomScale, defaultLinePath: self.defaultDrawPathWidth, ratio: ratio / originalRatio / toImageScale, startPoint: point)
                        self.drawPaths.append(path)
                    } else if pan.state == .changed {
                        let path = self.drawPaths.last
                        path!.addLine(to: point)
                        self.drawLine()
                    } else if pan.state == .cancelled || pan.state == .ended {
                        self.viewToolsBar(show: true)

                        if let path = self.drawPaths.last {
                            self.editorManager.storeAction(.draw(path))
                        }
                    }
                } else if self.selectedTool == .mosaic {
                    let point = pan.location(in: self.imageView)
                    if pan.state == .began {
                        self.viewToolsBar(show: false)

                        var actualSize = self.currentClipStatus.editRect.size
                        if self.shouldSwapSize {
                            swap(&actualSize.width, &actualSize.height)
                        }
                        let ratio = min(
                            self.mainScrollView.frame.width / self.currentClipStatus.editRect.width,
                            self.mainScrollView.frame.height / self.currentClipStatus.editRect.height
                        )
                        
                        let pathW = self.mosaicLineWidth / self.mainScrollView.zoomScale
                        let path = PTMosaicPath(pathWidth: pathW, ratio: ratio, startPoint: point)
                        
                        self.mosaicImageLayerMaskLayer?.lineWidth = pathW
                        self.mosaicImageLayerMaskLayer?.path = path.path.cgPath
                        self.mosaicPaths.append(path)
                    } else if pan.state == .changed {
                        let path = self.mosaicPaths.last
                        path?.addLine(to: point)
                        self.mosaicImageLayerMaskLayer?.path = path?.path.cgPath
                    } else if pan.state == .cancelled || pan.state == .ended {
                        self.viewToolsBar(show: true)
                        if let path = self.mosaicPaths.last {
                            self.editorManager.storeAction(.mosaic(path))
                        }
                        
                        self.generateNewMosaicImage()
                    }
                }
            }
        }
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        return pan
    }()
    
    var imageMostColor : UIColor!
    // 处理好的马赛克图片
    private var mosaicImage: UIImage?
    // 显示马赛克图片的layer
    private var mosaicImageLayer: CALayer?
    // 显示马赛克图片的layer的mask
    private var mosaicImageLayerMaskLayer: CAShapeLayer?
    private var impactFeedback: UIImpactFeedbackGenerator?

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
        currentAdjustStatus = PTAdjustStatus()
        preAdjustStatus = currentAdjustStatus
        editorManager = PTMediaEditManager(actions: [])
        currentFilter = .cigaussian
        adjustTools = PTImageEditorConfig.share.adjust_tools
        tools = PTImageEditorConfig.share.tools
        editorManager.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let nav = navigationController else { return }
        PTBaseNavControl.GobalNavControl(nav: nav,navColor: .clear)
        changeStatusBar(type: .Dark)
        setCustomBackButtonView(dismissButton)
        setCustomRightButtons(buttons: [doneButton,redoButton,undoButton], rightPadding: 0)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        var size = drawingImageView.frame.size
        if shouldSwapSize {
            swap(&size.width, &size.height)
        }
        
        var toImageScale = PTEditImageViewController.maxDrawLineImageWidth / size.width
        if editImage.size.width / editImage.size.height > 1 {
            toImageScale = PTEditImageViewController.maxDrawLineImageWidth / size.height
        }
        
        let width = drawLineWidth / mainScrollView.zoomScale * toImageScale
        defaultDrawPathWidth = width
        
        PTBaseNavControl.GobalNavControl(nav: navigationController!,navColor: .clear)
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

        view.addSubviews([mainScrollView,toolCollectionView,ashbinView])
        mainScrollView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview()
        }
        mainScrollView.addSubviews([containerView])
        containerView.addSubviews([imageView,drawingImageView,eraserCircleView,stickersContainer])
        
        toolCollectionView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight)
            make.height.equalTo(54)
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
        
        if !drawPaths.isEmpty {
            drawLine()
        }
        if !mosaicPaths.isEmpty {
            generateNewMosaicImage()
        }
        
        if tools.contains(.draw) {
            impactFeedback = UIImpactFeedbackGenerator(style: .light)
        }
        
        if tools.contains(.mosaic) {
            mosaicImage = editImage.pt.mosaicImage()
            
            mosaicImageLayer = CALayer()
            mosaicImageLayer?.contents = mosaicImage?.cgImage
            imageView.layer.addSublayer(mosaicImageLayer!)
            
            mosaicImageLayerMaskLayer = CAShapeLayer()
            mosaicImageLayerMaskLayer?.strokeColor = UIColor.blue.cgColor
            mosaicImageLayerMaskLayer?.fillColor = nil
            mosaicImageLayerMaskLayer?.lineCap = .round
            mosaicImageLayerMaskLayer?.lineJoin = .round
            imageView.layer.addSublayer(mosaicImageLayerMaskLayer!)
            
            mosaicImageLayer?.mask = mosaicImageLayerMaskLayer
        }
        
        if tools.contains(.adjust) {
            if let selectedAdjustTool = selectedAdjustTool {
                changeAdjustTool(selectedAdjustTool)
            }

            adjustSlider.beginAdjust = { [weak self] in
                guard let `self` = self else { return }
                self.preAdjustStatus = self.currentAdjustStatus
            }
            adjustSlider.valueChanged = { [weak self] value in
                self?.adjustValueChanged(value)
            }
            adjustSlider.endAdjust = { [weak self] in
                guard let `self` = self else { return }
                self.editorManager.storeAction(
                    .adjust(oldStatus: self.preAdjustStatus, newStatus: self.currentAdjustStatus)
                )
                self.hasAdjustedImage = true
            }

            editImage = adjustFilterValueSet(filterImage: editImage) ?? editImage
        }

        rotationImageView()
        if tools.contains(.filter) {
            generateFilterImages()
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
        drawingImageView.frame = imageView.frame
        mosaicImageLayer?.frame = imageView.bounds
        mosaicImageLayerMaskLayer?.frame = imageView.bounds
        stickersContainer.frame = imageView.frame
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
        let rows = toolsModel.map { PTRows(ID: PTEditToolsCell.ID,dataModel: $0) }
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
        drawingImageView.transform = transform
    }
    
    private func buildImage() -> UIImage {
        let image = UIGraphicsImageRenderer.pt.renderImage(size: editImage.size) { format in
            format.scale = self.editImage.scale
        } imageActions: { context in
            editImage.draw(at: .zero)
            drawingImageView.image?.draw(in: CGRect(origin: .zero, size: originalImage.size))
            
            if !stickersContainer.subviews.isEmpty {
                let scale = imageSize.width / stickersContainer.frame.width
                stickersContainer.subviews.forEach { view in
                    (view as? PTStickerViewAdditional)?.resetState()
                }
                context.concatenate(CGAffineTransform(scaleX: scale, y: scale))
                stickersContainer.layer.render(in: context)
                context.concatenate(CGAffineTransform(scaleX: 1 / scale, y: 1 / scale))
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
        
        let isSelected = selectedTool != .draw
        if isSelected {
            selectedTool = .draw
        } else {
            selectedTool = nil
        }

        showHandDrawBar(show: isSelected)
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
        let isSelected = selectedTool != .mosaic
        if isSelected {
            selectedTool = .mosaic
        } else {
            selectedTool = nil
        }
        
        generateNewMosaicLayerIfAdjust()
        showHandDrawBar(show: false)
        showFilter(show: false)
        showAdjust(show:false)
    }
        
    private func generateNewMosaicImageLayer() {
        mosaicImage = editImage.pt.mosaicImage()
        
        mosaicImageLayer?.removeFromSuperlayer()
        
        mosaicImageLayer = CALayer()
        mosaicImageLayer?.frame = imageView.bounds
        mosaicImageLayer?.contents = mosaicImage?.cgImage
        imageView.layer.insertSublayer(mosaicImageLayer!, below: mosaicImageLayerMaskLayer)
        
        mosaicImageLayer?.mask = mosaicImageLayerMaskLayer
    }

    private func drawLine() {
        let originalRatio = min(mainScrollView.frame.width / originalImage.size.width, mainScrollView.frame.height / originalImage.size.height)
        let ratio = min(
            mainScrollView.frame.width / currentClipStatus.editRect.width,
            mainScrollView.frame.height / currentClipStatus.editRect.height
        )
        let scale = ratio / originalRatio
        // 缩放到最初的size
        var size = drawingImageView.frame.size
        size.width /= scale
        size.height /= scale
        if shouldSwapSize {
            swap(&size.width, &size.height)
        }
        var toImageScale = PTEditImageViewController.maxDrawLineImageWidth / size.width
        if editImage.size.width / editImage.size.height > 1 {
            toImageScale = PTEditImageViewController.maxDrawLineImageWidth / size.height
        }
        size.width *= toImageScale
        size.height *= toImageScale
        
        
        drawingImageView.image = UIGraphicsImageRenderer.pt.renderImage(size: size) { context in
            context.setAllowsAntialiasing(true)
            context.setShouldAntialias(true)
            for path in self.drawPaths {
                path.drawPath()
            }
        }
    }

    private func eraserAction(_ pan: UIPanGestureRecognizer) {
        // 相对于drawingImageView的point
        let point = pan.location(in: drawingImageView)
        let originalRatio = min(mainScrollView.frame.width / originalImage.size.width, mainScrollView.frame.height / originalImage.size.height)
        let ratio = min(
            mainScrollView.frame.width / currentClipStatus.editRect.width,
            mainScrollView.frame.height / currentClipStatus.editRect.height
        )
        let scale = ratio / originalRatio
        // 缩放到最初的size
        var size = drawingImageView.frame.size
        size.width /= scale
        size.height /= scale
        if shouldSwapSize {
            swap(&size.width, &size.height)
        }
        
        var toImageScale = PTEditImageViewController.maxDrawLineImageWidth / size.width
        if editImage.size.width / editImage.size.height > 1 {
            toImageScale = PTEditImageViewController.maxDrawLineImageWidth / size.height
        }
        
        let pointScale = ratio / originalRatio / toImageScale
        // 转换为drawPath的point
        let drawPoint = CGPoint(x: point.x / pointScale, y: point.y / pointScale)
        if pan.state == .began {
            eraserCircleView.isHidden = false
            impactFeedback?.prepare()
        }
        
        if pan.state == .began || pan.state == .changed {
            var transform: CGAffineTransform = .identity
            
            let angle = ((Int(currentClipStatus.angle) % 360) + 360) % 360
            let drawingImageViewSize = drawingImageView.frame.size
            if angle == 90 {
                transform = transform.translatedBy(x: 0, y: -drawingImageViewSize.width)
            } else if angle == 180 {
                transform = transform.translatedBy(x: -drawingImageViewSize.width, y: -drawingImageViewSize.height)
            } else if angle == 270 {
                transform = transform.translatedBy(x: -drawingImageViewSize.height, y: 0)
            }
            transform = transform.concatenating(drawingImageView.transform)
            eraserCircleView.center = point.applying(transform)
            
            var needDraw = false
            for path in drawPaths {
                if path.path.contains(drawPoint), !deleteDrawPaths.contains(path) {
                    path.willDelete = true
                    deleteDrawPaths.append(path)
                    needDraw = true
                    impactFeedback?.impactOccurred()
                }
            }
            if needDraw {
                drawLine()
            }
        } else {
            eraserCircleView.isHidden = true
            if !deleteDrawPaths.isEmpty {
                editorManager.storeAction(.eraser(deleteDrawPaths))
                drawPaths.removeAll { deleteDrawPaths.contains($0) }
                deleteDrawPaths.removeAll()
                drawLine()
            }
        }
    }

    /// 传入inputImage 和 inputMosaicImage则代表仅想要获取新生成的mosaic图片
    @discardableResult
    private func generateNewMosaicImage(inputImage: UIImage? = nil, inputMosaicImage: UIImage? = nil) -> UIImage? {
        let renderRect = CGRect(origin: .zero, size: originalImage.size)
        
        var midImage = UIGraphicsImageRenderer.pt.renderImage(size: originalImage.size) { format in
            format.scale = self.originalImage.scale
        } imageActions: { context in
            if inputImage != nil {
                inputImage?.draw(in: renderRect)
            } else {
                var drawImage: UIImage?
                if tools.contains(.filter), let image = filterImages[currentFilter.name] {
                    drawImage = image
                } else {
                    drawImage = originalImage
                }
                
                if tools.contains(.adjust), !currentAdjustStatus.allValueIsZero {
                    drawImage = adjustFilterValueSet(filterImage: drawImage) ?? drawImage
                }
                
                drawImage?.draw(in: renderRect)
            }
            
            mosaicPaths.forEach { path in
                context.move(to: path.startPoint)
                path.linePoints.forEach { point in
                    context.addLine(to: point)
                }
                context.setLineWidth(path.path.lineWidth / path.ratio)
                context.setLineCap(.round)
                context.setLineJoin(.round)
                context.setBlendMode(.clear)
                context.strokePath()
            }
        }
        
        guard let midCgImage = midImage.cgImage else { return nil }
        midImage = UIImage(cgImage: midCgImage, scale: editImage.scale, orientation: .up)
        
        let temp = UIGraphicsImageRenderer.pt.renderImage(size: originalImage.size) { format in
            format.scale = self.originalImage.scale
        } imageActions: { _ in
            // 由于生成的mosaic图片可能在边缘区域出现空白部分，导致合成后会有黑边，所以在最下面先画一张原图
            originalImage.draw(in: renderRect)
            (inputMosaicImage ?? mosaicImage)?.draw(in: renderRect)
            midImage.draw(in: renderRect)
        }
        
        guard let cgi = temp.cgImage else { return nil }
        let image = UIImage(cgImage: cgi, scale: editImage.scale, orientation: .up)
        
        if inputImage != nil {
            return image
        }
        
        editImage = image
        imageView.image = image
        mosaicImageLayerMaskLayer?.path = nil
        
        return image
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
        showInputTextVC(font:PTImageEditorConfig.share.textStickerDefaultFont) { [weak self] text, textColor, font, image, style in
            guard !text.isEmpty, let image = image else { return }
            self?.addTextStickersView(text, textColor: textColor, font: font, image: image, style: style)
        }
        selectedTool = nil
        showHandDrawBar(show: false)
        showFilter(show: false)
        showAdjust(show:false)
    }
    
    private func showInputTextVC(_ text: String? = nil, textColor: UIColor? = nil, font: UIFont? = nil, style: PTInputTextStyle = .normal, completion: @escaping (String, UIColor, UIFont, UIImage?, PTInputTextStyle) -> Void) {
        // Calculate image displayed frame on the screen.
        var r = mainScrollView.convert(view.frame, to: containerView)
        r.origin.x += mainScrollView.contentOffset.x / mainScrollView.zoomScale
        r.origin.y += mainScrollView.contentOffset.y / mainScrollView.zoomScale
        let scale = imageSize.width / imageView.frame.width
        r.origin.x *= scale
        r.origin.y *= scale
        r.size.width *= scale
        r.size.height *= scale
        let isCircle = currentClipStatus.ratio?.isCircle ?? false
        let bgImage = buildImage().pt.clipImage(angle: currentClipStatus.angle, editRect: currentClipStatus.editRect, isCircle: isCircle).pt.clipImage(angle: 0, editRect: r, isCircle: isCircle)
        let vc = PTEditInputViewController(image: bgImage, text: text, textColor: textColor, font: font, style: style)
        
        vc.endInput = { text, textColor, font, image, style in
            completion(text, textColor, font, image, style)
        }
        
        self.navigationController?.pushViewController(vc)
    }

    /// Add text sticker
    private func addTextStickersView(_ text: String, textColor: UIColor, font: UIFont, image: UIImage, style: PTInputTextStyle) {
        guard !text.isEmpty else { return }
        
        let scale = mainScrollView.zoomScale
        let size = PTTextStickerView.calculateSize(image: image)
        let originFrame = getStickerOriginFrame(size)
        
        let textSticker = PTTextStickerView(text: text, textColor: textColor, font: font, style: style, image: image, originScale: 1 / scale, originAngle: -currentClipStatus.angle, originFrame: originFrame )
        addSticker(textSticker)
        
        editorManager.storeAction(.sticker(oldState: nil, newState: textSticker.state))
    }
    
    private func addSticker(_ sticker: PTBaseStickerView) {
        stickersContainer.addSubview(sticker)
        sticker.frame = sticker.originFrame
        configSticker(sticker)
    }
    
    private func configSticker(_ sticker: PTBaseStickerView) {
        sticker.delegate = self
        mainScrollView.pinchGestureRecognizer?.require(toFail: sticker.pinchGes)
        mainScrollView.panGestureRecognizer.require(toFail: sticker.panGes)
        panGes.require(toFail: sticker.panGes)
    }

    private func getStickerOriginFrame(_ size: CGSize) -> CGRect {
        let scale = mainScrollView.zoomScale
        // Calculate the display rect of container view.
        let x = (mainScrollView.contentOffset.x - containerView.frame.minX) / scale
        let y = (mainScrollView.contentOffset.y - containerView.frame.minY) / scale
        let w = view.frame.width / scale
        let h = view.frame.height / scale
        // Convert to text stickers container view.
        let r = containerView.convert(CGRect(x: x, y: y, width: w, height: h), to: stickersContainer)
        let originFrame = CGRect(x: r.minX + (r.width - size.width) / 2, y: r.minY + (r.height - size.height) / 2, width: size.width, height: size.height)
        return originFrame
    }

    private func removeSticker(id: String?) {
        guard let id else { return }
        
        for sticker in stickersContainer.subviews.reversed() {
            guard let stickerID = (sticker as? PTBaseStickerView)?.id,
                  stickerID == id else {
                continue
            }
            
            (sticker as? PTBaseStickerView)?.moveToAshbin()
            
            break
        }
    }
}

//MARK: Filter
extension PTEditImageViewController {
    
    private func filterAction() {
        let isSelected = selectedTool != .filter
        if isSelected {
            selectedTool = .filter
        } else {
            selectedTool = nil
        }
        
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
            
            let rows = thumbnailFilterImages.map {
                PTRows(ID:PTFilterImageCell.ID,dataModel: $0)
            }

            let section = PTSection(rows: rows)
            filterCollectionView.showCollectionDetail(collectionData: [section])
        } else {
            filterCollectionView.removeFromSuperview()
        }
    }
    
    private func changeFilter(_ filter: PTHarBethFilter) {
        func adjustImage(_ image: UIImage) -> UIImage {
            guard tools.contains(.adjust), !currentAdjustStatus.allValueIsZero else {
                return image
            }
            
            return adjustFilterValueSet(filterImage: image) ?? image
        }
        
        currentFilter = filter
        if let image = filterImages[currentFilter.name] {
            editImage = adjustImage(image)
            editImageWithoutAdjust = image
        } else {
            
            let image = currentFilter.getCurrentFilterImage(image: originalImage)//currentFilter.applier?(originalImage) ?? originalImage
            editImage = adjustImage(image)
            editImageWithoutAdjust = image
            filterImages[currentFilter.name] = image
        }
        
        if tools.contains(.mosaic) {
            generateNewMosaicImageLayer()
            
            if mosaicPaths.isEmpty {
                imageView.image = editImage
            } else {
                generateNewMosaicImage()
            }
        } else {
            imageView.image = editImage
        }
    }

    private func generateFilterImages() {
        let size: CGSize
        let ratio = (originalImage.size.width / originalImage.size.height)
        let fixLength: CGFloat = 200
        if ratio >= 1 {
            size = CGSize(width: fixLength * ratio, height: fixLength)
        } else {
            size = CGSize(width: fixLength, height: fixLength / ratio)
        }
        let thumbnailImage = originalImage.pt.resize_vI(size) ?? originalImage
        
        PTGCDManager.gcdGobal {
            let filters = PTImageEditorConfig.share.filters
            filters.enumerated().forEach { index,value in
                PTHarBethFilter.share.texureSize = thumbnailImage!.size
                self.thumbnailFilterImages.append(value.getCurrentFilterImage(image: thumbnailImage))
            }
        }
    }
}

//MARK: Adjust
extension PTEditImageViewController {
    func adjustActions() {
        let isSelected = selectedTool != .adjust
        if isSelected {
            selectedTool = .adjust
        } else {
            selectedTool = nil
        }

        generateAdjustImageRef()
        showHandDrawBar(show: false)
        showFilter(show: false)
        showAdjust(show:isSelected)
    }
    
    func showAdjust(show:Bool) {
        if show {
            adjustSlider.isHidden = false
            view.addSubviews([adjustCollectionView,adjustSlider])
            adjustCollectionView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalTo(self.toolCollectionView.snp.top)
                make.height.equalTo(self.adjustCollectionViewHeight)
            }

            switch PTImageEditorConfig.share.adjustSliderType {
            case .vertical:
                adjustSlider.frame = CGRect(x: view.pt.jx_width - 60, y: view.pt.jx_height / 2 - 100, width: 60, height: 200)
            case .horizontal:
                adjustSlider.snp.makeConstraints { make in
                    make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace * 2)
                    make.bottom.equalTo(self.adjustCollectionView.snp.top).offset(-20)
                    make.height.equalTo(60)
                }
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
            adjustSlider.removeFromSuperview()
        }
    }
    
    private func adjustValueChanged(_ value: Float) {
        guard let selectedAdjustTool else {
            return
        }
        
        switch selectedAdjustTool {
        case .brightness:
            if currentAdjustStatus.brightness == value {
                return
            }
            
            currentAdjustStatus.brightness = value
        case .contrast:
            if currentAdjustStatus.contrast == value {
                return
            }
            
            currentAdjustStatus.contrast = value
        case .saturation:
            if currentAdjustStatus.saturation == value {
                return
            }
            
            currentAdjustStatus.saturation = value
        default:
            break
        }
        
        adjustStatusChanged()
    }
    
    private func generateAdjustImageRef() {
        editImageAdjustRef = generateNewMosaicImage(inputImage: editImageWithoutAdjust, inputMosaicImage: editImageWithoutAdjust.pt.mosaicImage())
    }
    
    private func generateNewMosaicLayerIfAdjust() {
        defer {
            hasAdjustedImage = false
        }
        
        guard hasAdjustedImage else { return }
        
        generateNewMosaicImageLayer()
        
        if !mosaicPaths.isEmpty {
            generateNewMosaicImage()
        }
    }

    fileprivate func adjustFilterValueSet(filterImage:UIImage?) -> UIImage? {
        var filters = [C7FilterProtocol]()
        let filterManager = PTHarBethFilter.share
        filterManager.tools = PTImageEditorConfig.share.adjust_tools
        filterManager.getFilterResults().enumerated().forEach { index,value in
            if value.filter is C7Luminance {
                let filter = value.callback!(PTHarBethFilter.FiltersTool.brightness.filterValue(currentAdjustStatus.brightness))
                filters.append(filter)
            } else if value.filter is C7Contrast {
                let filter = value.callback!(PTHarBethFilter.FiltersTool.contrast.filterValue(currentAdjustStatus.contrast))
                filters.append(filter)
            } else if value.filter is C7Saturation {
                let filter = value.callback!(PTHarBethFilter.FiltersTool.saturation.filterValue(currentAdjustStatus.saturation))
                filters.append(filter)
            }
        }
        
        let dest = HarbethIO(element: filterImage, filters: filters)
        return try? dest.output()
    }
    
    private func adjustStatusChanged() {
        if let image = adjustFilterValueSet(filterImage: editImageAdjustRef) {
            editImage = image
            imageView.image = editImage
        }
    }
    
    private func changeAdjustTool(_ tool: PTHarBethFilter.FiltersTool) {
        selectedAdjustTool = tool
        switch tool {
        case .brightness:
            adjustSlider.value = currentAdjustStatus.brightness
        case .contrast:
            adjustSlider.value = currentAdjustStatus.contrast
        case .saturation:
            adjustSlider.value = currentAdjustStatus.saturation
        default:
            break
        }
    }
}

//MARK: UIScrollViewDelegate
extension PTEditImageViewController:UIScrollViewDelegate {
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
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == mainScrollView else {
            return
        }
        isScrolling = true
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
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

//MARK: UIColorPickerViewControllerDelegate
extension PTEditImageViewController: UIColorPickerViewControllerDelegate {
    public func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        if viewController.checkVCIsPresenting() {
            viewController.dismiss(animated: true) {
                PTGCDManager.gcdMain {
                    self.drawColor = viewController.selectedColor
                }
            }
        } else {
            viewController.navigationController?.popViewController(animated: true) {
                PTGCDManager.gcdMain {
                    self.drawColor = viewController.selectedColor
                }
            }
        }
    }
    
    public func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        self.drawColor = viewController.selectedColor
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
            return (selectedTool == .draw || selectedTool == .mosaic) && !isScrolling
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
        drawPaths.removeLast()
        drawLine()
    }
    
    private func redoDraw(_ path: PTDrawPath) {
        drawPaths.append(path)
        drawLine()
    }
    
    private func undoEraser(_ paths: [PTDrawPath]) {
        paths.forEach { $0.willDelete = false }
        drawPaths.append(contentsOf: paths)
        drawPaths = drawPaths.sorted { $0.index < $1.index }
        drawLine()
    }
    
    private func redoEraser(_ paths: [PTDrawPath]) {
        drawPaths.removeAll { paths.contains($0) }
        drawLine()
    }
    
    private func undoOrRedoClip(_ status: PTClipStatus) {
        clipImage(status: status)
        preClipStatus = status
    }
    
    private func undoMosaic(_ path: PTMosaicPath) {
        mosaicPaths.removeLast()
        generateNewMosaicImage()
    }
    
    private func redoMosaic(_ path: PTMosaicPath) {
        mosaicPaths.append(path)
        generateNewMosaicImage()
    }
    
    private func undoSticker(_ oldState: PTBaseStickertState?, _ newState: PTBaseStickertState?) {
        guard let oldState else {
            removeSticker(id: newState?.id)
            return
        }
        
        removeSticker(id: oldState.id)
        if let sticker = PTBaseStickerView.initWithState(oldState) {
            addSticker(sticker)
        }
    }
    
    private func redoSticker(_ oldState: PTBaseStickertState?, _ newState: PTBaseStickertState?) {
        guard let newState else {
            removeSticker(id: oldState?.id)
            return
        }
        
        removeSticker(id: newState.id)
        if let sticker = PTBaseStickerView.initWithState(newState) {
            addSticker(sticker)
        }
    }
    
    private func undoOrRedoFilter(_ filter: PTHarBethFilter?) {
        guard let filter else { return }
        changeFilter(filter)
        
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
        
        if currentAdjustStatus.brightness != status.brightness {
            adjustTool = .brightness
        } else if currentAdjustStatus.contrast != status.contrast {
            adjustTool = .contrast
        } else if currentAdjustStatus.saturation != status.saturation {
            adjustTool = .saturation
        }
        
        currentAdjustStatus = status
        preAdjustStatus = status
        adjustStatusChanged()
        
        guard let adjustTool else { return }
        
        changeAdjustTool(adjustTool)
        
        guard let index = adjustTools.firstIndex(where: { $0 == adjustTool }) else {
            return
        }
        
        let indexPath = IndexPath(row: index, section: 0)
        adjustCollectionView.contentCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        adjustCollectionView.contentCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        adjustCollectionView.contentCollectionView.reloadData()
    }
}

// MARK: PTStickerViewDelegate
extension PTEditImageViewController: PTStickerViewDelegate {
    func stickerBeginOperation(_ sticker: PTBaseStickerView) {
        preStickerState = sticker.state
        
        viewToolsBar(show: false)
        ashbinView.layer.removeAllAnimations()
        ashbinView.isHidden = false
        var frame = ashbinView.frame
        let diff = view.frame.height - frame.minY
        frame.origin.y += diff
        ashbinView.frame = frame
        frame.origin.y -= diff
        UIView.animate(withDuration: 0.25) {
            self.ashbinView.frame = frame
        }
        
        stickersContainer.subviews.forEach { view in
            if view !== sticker {
                (view as? PTStickerViewAdditional)?.resetState()
                (view as? PTStickerViewAdditional)?.gesIsEnabled = false
            }
        }
    }
    
    func stickerOnOperation(_ sticker: PTBaseStickerView, panGes: UIPanGestureRecognizer) {
        let point = panGes.location(in: view)
        if ashbinView.frame.contains(point) {
            ashbinView.backgroundColor = .gray
            ashbinImgView.isHighlighted = true
            if sticker.alpha == 1 {
                sticker.layer.removeAllAnimations()
                UIView.animate(withDuration: 0.25) {
                    sticker.alpha = 0.5
                }
            }
        } else {
            ashbinView.backgroundColor = .systemRed
            ashbinImgView.isHighlighted = false
            if sticker.alpha != 1 {
                sticker.layer.removeAllAnimations()
                UIView.animate(withDuration: 0.25) {
                    sticker.alpha = 1
                }
            }
        }
    }
    
    func stickerEndOperation(_ sticker: PTBaseStickerView, panGes: UIPanGestureRecognizer) {
        viewToolsBar(show: true)
        ashbinView.layer.removeAllAnimations()
        ashbinView.isHidden = true
        
        var endState: PTBaseStickertState? = sticker.state
        
        let point = panGes.location(in: view)
        if ashbinView.frame.contains(point) {
            sticker.moveToAshbin()
            endState = nil
        }
        
        editorManager.storeAction(.sticker(oldState: preStickerState, newState: endState))
        preStickerState = nil
        
        stickersContainer.subviews.forEach { view in
            (view as? PTStickerViewAdditional)?.gesIsEnabled = true
        }
    }
    
    func stickerDidTap(_ sticker: PTBaseStickerView) {
        stickersContainer.subviews.forEach { view in
            if view !== sticker {
                (view as? PTStickerViewAdditional)?.resetState()
            }
        }
    }
    
    func sticker(_ textSticker: PTTextStickerView, editText text: String) {
        showInputTextVC(text, textColor: textSticker.textColor, font: textSticker.font, style: textSticker.style) { text, textColor, font, image, style in
            guard let image = image, !text.isEmpty else {
                textSticker.moveToAshbin()
                return
            }
            
            textSticker.startTimer()
            guard textSticker.text != text || textSticker.textColor != textColor || textSticker.style != style else {
                return
            }
            textSticker.text = text
            textSticker.textColor = textColor
            textSticker.font = font
            textSticker.style = style
            textSticker.image = image
            let newSize = PTTextStickerView.calculateSize(image: image)
            textSticker.changeSize(to: newSize)
        }
    }
}
