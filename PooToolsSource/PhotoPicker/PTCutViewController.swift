//
//  PTCutViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 29/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import ZXNavigationBar
import SnapKit
import SwifterSwift

extension PTCutViewController {
    enum ClipPanEdge {
        case none
        case top
        case bottom
        case left
        case right
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
}

func deviceSafeAreaInsets() -> UIEdgeInsets {
    var insets: UIEdgeInsets = .zero
    
    if #available(iOS 11, *) {
        insets = AppWindows?.safeAreaInsets ?? .zero
    }
    
    return insets
}

class PTWeakProxy: NSObject {
    private weak var target: NSObjectProtocol?
    
    init(target: NSObjectProtocol) {
        self.target = target
        super.init()
    }
    
    class func proxy(withTarget target: NSObjectProtocol) -> PTWeakProxy {
        return PTWeakProxy(target: target)
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return target
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        return target?.responds(to: aSelector) ?? false
    }
}

class PTCutViewController: PTBaseViewController {
    static let cutRatioHeight: CGFloat = 108
    
    private static let clipRatioItemSize = CGSize(width: 60, height: 70)
    
    /// 取消裁剪时动画frame
    private var cancelClipAnimateFrame: CGRect = .zero
    
    private var viewDidAppearCount = 0
    
    private let originalImage: UIImage
    
    private let clipRatios: [PTImageClipRatio]
    
    private let dimClippedAreaDuringAdjustments: Bool

    private var editImage: UIImage
    
    /// 初次进入界面时候，裁剪范围
    private var editRect: CGRect
    
    private lazy var mainScrollView: UIScrollView = {
        let view = UIScrollView()
        view.alwaysBounceVertical = true
        view.alwaysBounceHorizontal = true
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            view.contentInsetAdjustmentBehavior = .never
        }
        view.delegate = self
        return view
    }()
    
    private lazy var containerView = UIView()
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.image = editImage
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var shadowView: PTClipShadowView = {
        let view = PTClipShadowView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        view.isCircle = selectedRatio.isCircle
        return view
    }()
    
    private lazy var overlayView: PTClipOverlayView = {
        let view = PTClipOverlayView()
        view.isUserInteractionEnabled = false
        view.isCircle = selectedRatio.isCircle
        return view
    }()
    
    private lazy var gridPanGes: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(gridGesPanAction(_:)))
        pan.delegate = self
        return pan
    }()
    
    private lazy var bottomToolView = UIView()
    
    private lazy var bottomShadowLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.black.withAlphaComponent(0.15).cgColor,
            UIColor.black.withAlphaComponent(0.35).cgColor
        ]
        layer.locations = [0, 1]
        return layer
    }()
    
    private lazy var cancelBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage("❌".emojiToImage(emojiFont: .appfont(size: 20)), for: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.addTarget(self, action: #selector(cancelBtnClick), for: .touchUpInside)
        return btn
    }()
    
    private lazy var revertBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitleColor(.white, for: .normal)
        btn.setImage("🔄".emojiToImage(emojiFont: .appfont(size: 20)), for: .normal)
        btn.addTarget(self, action: #selector(revertBtnClick), for: .touchUpInside)
        return btn
    }()
    
    lazy var doneBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage("✅".emojiToImage(emojiFont: .appfont(size: 20)), for: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.addTarget(self, action: #selector(doneBtnClick), for: .touchUpInside)
        return btn
    }()
    
    private lazy var rotateBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage("↩️".emojiToImage(emojiFont: .appfont(size: 20)), for: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.addTarget(self, action: #selector(rotateBtnClick), for: .touchUpInside)
        return btn
    }()
    
    private lazy var ratioCollectionView : PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Custom

        let view = PTCollectionView(viewConfig: config)
        view.customerLayout = { sectionModel in
            var bannerGroupSize : NSCollectionLayoutSize
            var customers = [NSCollectionLayoutGroupCustomItem]()
            var groupW:CGFloat = PTAppBaseConfig.share.defaultViewSpace
            let screenW:CGFloat = 88
            let cellHeight:CGFloat = PTCutViewController.cutRatioHeight
            sectionModel.rows.enumerated().forEach { (index,model) in
                let customItem = NSCollectionLayoutGroupCustomItem.init(frame: CGRect.init(x: PTAppBaseConfig.share.defaultViewSpace + 10 * CGFloat(index) + screenW * CGFloat(index), y: 0, width: screenW, height: cellHeight), zIndex: 1000+index)
                customers.append(customItem)
                groupW += (cellHeight + 10)
            }
            bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(groupW), heightDimension: NSCollectionLayoutDimension.absolute(cellHeight))
            return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
                customers
            })
        }
        view.cellInCollection = { collection,sectionModel,indexPath in
            let config = PTMediaLibConfig.share
            let itemRow = sectionModel.rows[indexPath.row]
            let cellModel = (itemRow.dataModel as! PTImageClipRatio)
            let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTImageCutRatioCell
            
            cell.configureCell(image: self.thumbnailImage ?? self.editImage, ratio: cellModel)
            
            if cellModel == self.selectedRatio {
                cell.titleLabel.textColor = .purple
            } else {
                cell.titleLabel.textColor = .lightGray
            }

            return cell
        }
        view.collectionDidSelect = { collection,sectionModel,indexPath in
            let ratio = self.clipRatios[indexPath.row]
            guard ratio != self.selectedRatio else {
                return
            }
            self.selectedRatio = ratio
            collection.reloadData()
            collection.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            self.calculateClipRect()
            self.layoutInitialImage()
        }
        return view
    }()
    
    private var shouldLayout = true
    
    private var panEdge: PTCutViewController.ClipPanEdge = .none
    
    private var beginPanPoint: CGPoint = .zero
    
    private var clipBoxFrame: CGRect = .zero
    
    private var clipOriginFrame: CGRect = .zero
    
    private var isRotating = false
    
    private var angle: CGFloat = 0
    
    private var selectedRatio: PTImageClipRatio {
        didSet {
            overlayView.isCircle = selectedRatio.isCircle
            shadowView.isCircle = selectedRatio.isCircle
        }
    }
    
    private var thumbnailImage: UIImage?
    
    private lazy var maxClipFrame = calculateMaxClipFrame()
    
    private var minClipSize = CGSize(width: 45, height: 45)
    
    private var resetTimer: Timer?
    
    var animate = true
    /// 用作进入裁剪界面首次动画frame
    var presentAnimateFrame: CGRect?
    /// 用作进入裁剪界面首次动画和取消裁剪时动画的image
    var presentAnimateImage: UIImage?
    
    var dismissAnimateFromRect: CGRect = .zero
    
    var dismissAnimateImage: UIImage?
    
    /// 传回旋转角度，图片编辑区域的rect
    var clipDoneBlock: ((CGFloat, CGRect, PTImageClipRatio) -> Void)?
    
    var cancelClipBlock: (() -> Void)?
    
    override var prefersStatusBarHidden: Bool { true }
    
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    
    deinit {
        cleanTimer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    init(image: UIImage, status: PTClipStatus) {
        originalImage = image
        let configuration = PTMediaEditConfig.share
        clipRatios = configuration.clipRatios
        dimClippedAreaDuringAdjustments = configuration.dimClippedAreaDuringAdjustments
        editRect = status.editRect
        angle = status.angle
        let angle = ((Int(angle) % 360) - 360) % 360
        if angle == -90 {
            editImage = image.pt.rotate(orientation: .left)
        } else if angle == -180 {
            editImage = image.pt.rotate(orientation: .down)
        } else if angle == -270 {
            editImage = image.pt.rotate(orientation: .right)
        } else {
            editImage = image
        }
        var firstEnter = false
        if let ratio = status.ratio {
            selectedRatio = ratio
        } else {
            firstEnter = true
            selectedRatio = PTMediaEditConfig.share.clipRatios.first!
        }
        super.init(nibName: nil, bundle: nil)
        if firstEnter {
            calculateClipRect()
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.zx_navLineViewBackgroundColor = .clear
        self.zx_navBarBackgroundColor = .clear
        self.zx_navBar?.addSubviews([cancelBtn,doneBtn])
        cancelBtn.snp.makeConstraints { make in
            make.size.equalTo(34)
            make.bottom.equalToSuperview().inset(5)
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
        
        doneBtn.snp.makeConstraints { make in
            make.size.bottom.equalTo(self.cancelBtn)
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }

        setupUI()
        generateThumbnailImage()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewDidAppearCount += 1
        if presentingViewController is PTEditImageViewController {
            transitioningDelegate = self
        }
        
        guard viewDidAppearCount == 1 else {
            return
        }
        
        if let presentAnimateFrame = presentAnimateFrame,
           let presentAnimateImage = presentAnimateImage {
            let animateImageView = UIImageView(image: presentAnimateImage)
            animateImageView.contentMode = .scaleAspectFill
            animateImageView.clipsToBounds = true
            animateImageView.frame = presentAnimateFrame
            view.addSubview(animateImageView)
            
            cancelClipAnimateFrame = clipBoxFrame
            UIView.animate(withDuration: 0.25, animations: {
                animateImageView.frame = self.clipBoxFrame
                self.bottomToolView.alpha = 1
                self.rotateBtn.alpha = 1
            }) { _ in
                UIView.animate(withDuration: 0.1, animations: {
                    self.mainScrollView.alpha = 1
                    self.overlayView.alpha = 1
                    self.shadowView.alpha = 1
                }) { _ in
                    animateImageView.removeFromSuperview()
                }
            }
        } else {
            bottomToolView.alpha = 1
            rotateBtn.alpha = 1
            mainScrollView.alpha = 1
            overlayView.alpha = 1
            shadowView.alpha = 1
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard shouldLayout else {
            return
        }
        shouldLayout = false
                
        layoutInitialImage()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        shouldLayout = true
        maxClipFrame = calculateMaxClipFrame()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubviews([mainScrollView,shadowView,overlayView,bottomToolView,ratioCollectionView])
        mainScrollView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview()
        }
        shadowView.snp.makeConstraints { make in
            make.edges.equalTo(self.mainScrollView)
        }
        
        bottomToolView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight)
            make.height.equalTo(54)
        }
        
        ratioCollectionView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.bottomToolView.snp.top)
            make.height.equalTo(PTCutViewController.cutRatioHeight)
        }

        PTGCDManager.gcdAfter(time: 0.1) {
            self.bottomShadowLayer.frame = self.bottomToolView.bounds
            self.bottomToolView.layer.addSublayer(self.bottomShadowLayer)
        }

        mainScrollView.addSubview(containerView)
        containerView.addSubview(imageView)
        
        bottomToolView.addSubviews([revertBtn,rotateBtn])
        revertBtn.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.size.equalTo(44)
            make.bottom.equalToSuperview().inset(5)
        }
        
        rotateBtn.snp.makeConstraints { make in
            make.size.bottom.equalTo(self.revertBtn)
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
                
        view.addGestureRecognizer(gridPanGes)
        mainScrollView.panGestureRecognizer.require(toFail: gridPanGes)
        
        mainScrollView.alpha = 0
        overlayView.alpha = 0
        shadowView.alpha = 0
        bottomToolView.alpha = 0
        rotateBtn.alpha = 0
        
        
        showCutRatio { collectionView in
//            if self.clipRatios.count > 1, let index = self.clipRatios.firstIndex(where: { $0 == self.selectedRatio }) {
//                PTGCDManager.gcdAfter(time: 1) {
//                    collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: false)
//                }
//            }
        }
    }
    
    func showCutRatio(handle:((UICollectionView) -> Void)? = nil) {
        var rows = [PTRows]()
        clipRatios.enumerated().forEach { index,value in
            let row = PTRows(cls:PTImageCutRatioCell.self,ID:PTImageCutRatioCell.ID,dataModel: value)
            rows.append(row)
        }
        let section = PTSection(rows: rows)
        ratioCollectionView.showCollectionDetail(collectionData: [section],finishTask: handle)
    }
    
    private func generateThumbnailImage() {
        let size: CGSize
        let ratio = (editImage.size.width / editImage.size.height)
        let fixLength: CGFloat = 100
        if ratio >= 1 {
            size = CGSize(width: fixLength * ratio, height: fixLength)
        } else {
            size = CGSize(width: fixLength, height: fixLength / ratio)
        }
        thumbnailImage = editImage.pt.resize_vI(size)
    }
    
    /// 计算最大裁剪范围
    private func calculateMaxClipFrame() -> CGRect {
        var insets = deviceSafeAreaInsets()
        insets.top += 20
        var rect = CGRect.zero
        rect.origin.x = 15
        rect.origin.y = insets.top
        rect.size.width = UIScreen.main.bounds.width - 15 * 2
        rect.size.height = UIScreen.main.bounds.height - insets.top - 90 - PTCutViewController.clipRatioItemSize.height - 25
        return rect
    }
    
    private func calculateClipRect() {
        if selectedRatio.whRatio == 0 {
            editRect = CGRect(origin: .zero, size: editImage.size)
        } else {
            let imageSize = editImage.size
            let imageWHRatio = imageSize.width / imageSize.height
            
            var w: CGFloat = 0, h: CGFloat = 0
            if selectedRatio.whRatio >= imageWHRatio {
                w = imageSize.width
                h = w / selectedRatio.whRatio
            } else {
                h = imageSize.height
                w = h * selectedRatio.whRatio
            }
            
            editRect = CGRect(x: (imageSize.width - w) / 2, y: (imageSize.height - h) / 2, width: w, height: h)
        }
    }
    
    private func layoutInitialImage() {
        mainScrollView.minimumZoomScale = 1
        mainScrollView.maximumZoomScale = 1
        mainScrollView.zoomScale = 1
        
        let editSize = editRect.size
        mainScrollView.contentSize = editSize
        let maxClipRect = maxClipFrame
        
        containerView.frame = CGRect(origin: .zero, size: editImage.size)
        imageView.frame = containerView.bounds
        
        // editRect比例，计算editRect所占frame
        let editScale = min(maxClipRect.width / editSize.width, maxClipRect.height / editSize.height)
        let scaledSize = CGSize(width: floor(editSize.width * editScale), height: floor(editSize.height * editScale))
        
        var frame = CGRect.zero
        frame.size = scaledSize
        frame.origin.x = maxClipRect.minX + floor((maxClipRect.width - frame.width) / 2)
        frame.origin.y = maxClipRect.minY + floor((maxClipRect.height - frame.height) / 2)
        
        // 按照edit image进行计算最小缩放比例
        let originalScale = min(maxClipRect.width / editImage.size.width, maxClipRect.height / editImage.size.height)
        // 将 edit rect 相对 originalScale 进行缩放，缩放到图片未放大时候的clip rect
        let scaleEditSize = CGSize(width: editRect.width * originalScale, height: editRect.height * originalScale)
        // 计算缩放后的clip rect相对maxClipRect的比例
        let clipRectZoomScale = min(maxClipRect.width / scaleEditSize.width, maxClipRect.height / scaleEditSize.height)
        
        mainScrollView.minimumZoomScale = originalScale
        mainScrollView.maximumZoomScale = 10
        // 设置当前zoom scale
        let zoomScale = clipRectZoomScale * originalScale
        mainScrollView.zoomScale = zoomScale
        mainScrollView.contentSize = CGSize(width: editImage.size.width * zoomScale, height: editImage.size.height * zoomScale)
        
        changeClipBoxFrame(newFrame: frame)
        
        if (frame.size.width < scaledSize.width - CGFloat.ulpOfOne) || (frame.size.height < scaledSize.height - CGFloat.ulpOfOne) {
            var offset = CGPoint.zero
            offset.x = -floor((mainScrollView.frame.width - scaledSize.width) / 2)
            offset.y = -floor((mainScrollView.frame.height - scaledSize.height) / 2)
            mainScrollView.contentOffset = offset
        }
        
        // edit rect 相对 image size 的 偏移量
        let diffX = editRect.origin.x / editImage.size.width * mainScrollView.contentSize.width
        let diffY = editRect.origin.y / editImage.size.height * mainScrollView.contentSize.height
        mainScrollView.contentOffset = CGPoint(x: -mainScrollView.contentInset.left + diffX, y: -mainScrollView.contentInset.top + diffY)
    }
    
    private func changeClipBoxFrame(newFrame: CGRect) {
        guard clipBoxFrame != newFrame else {
            return
        }
        if newFrame.width < CGFloat.ulpOfOne || newFrame.height < CGFloat.ulpOfOne {
            return
        }
        var frame = newFrame
        let originX = ceil(maxClipFrame.minX)
        let diffX = frame.minX - originX
        frame.origin.x = max(frame.minX, originX)
//        frame.origin.x = floor(max(frame.minX, originX))
        if diffX < -CGFloat.ulpOfOne {
            frame.size.width += diffX
        }
        let originY = ceil(maxClipFrame.minY)
        let diffY = frame.minY - originY
        frame.origin.y = max(frame.minY, originY)
//        frame.origin.y = floor(max(frame.minY, originY))
        if diffY < -CGFloat.ulpOfOne {
            frame.size.height += diffY
        }
        let maxW = maxClipFrame.width + maxClipFrame.minX - frame.minX
        frame.size.width = max(minClipSize.width, min(frame.width, maxW))
//        frame.size.width = floor(max(self.minClipSize.width, min(frame.width, maxW)))
        
        let maxH = maxClipFrame.height + maxClipFrame.minY - frame.minY
        frame.size.height = max(minClipSize.height, min(frame.height, maxH))
//        frame.size.height = floor(max(self.minClipSize.height, min(frame.height, maxH)))
        
        clipBoxFrame = frame
        shadowView.clearRect = frame
        overlayView.frame = frame.insetBy(dx: -PTClipOverlayView.cornerLineWidth, dy: -PTClipOverlayView.cornerLineWidth)
        
        mainScrollView.contentInset = UIEdgeInsets(top: frame.minY, left: frame.minX, bottom: mainScrollView.frame.maxY - frame.maxY, right: mainScrollView.frame.maxX - frame.maxX)
        
        let scale = max(frame.height / editImage.size.height, frame.width / editImage.size.width)
        mainScrollView.minimumZoomScale = scale
        
//        var size = self.mainScrollView.contentSize
//        size.width = floor(size.width)
//        size.height = floor(size.height)
//        self.mainScrollView.contentSize = size
        
        mainScrollView.zoomScale = mainScrollView.zoomScale
    }
    
    @objc private func cancelBtnClick() {
        dismissAnimateFromRect = cancelClipAnimateFrame
        dismissAnimateImage = presentAnimateImage
        cancelClipBlock?()
        dismiss(animated: animate, completion: nil)
    }
    
    @objc private func revertBtnClick() {
        angle = 0
        editImage = originalImage
        calculateClipRect()
        imageView.image = editImage
        layoutInitialImage()
        
        generateThumbnailImage()
        showCutRatio()
    }
    
    @objc private func doneBtnClick() {
        let image = clipImage()
        dismissAnimateFromRect = clipBoxFrame
        dismissAnimateImage = image.clipImage
//        if presentingViewController is ZLCustomCamera {
//            dismiss(animated: animate) {
//                self.clipDoneBlock?(self.angle, image.editRect, self.selectedRatio)
//            }
//        } else {
            clipDoneBlock?(angle, image.editRect, selectedRatio)
            dismiss(animated: animate, completion: nil)
//        }
    }
    
    @objc private func rotateBtnClick() {
        guard !isRotating else {
            return
        }
        angle -= 90
        if angle == -360 {
            angle = 0
        }
        
        isRotating = true
        
        let animateImageView = UIImageView(image: editImage)
        animateImageView.contentMode = .scaleAspectFit
        animateImageView.clipsToBounds = true
        let originFrame = view.convert(containerView.frame, from: mainScrollView)
        animateImageView.frame = originFrame
        view.addSubview(animateImageView)
        
        if selectedRatio.whRatio == 0 || selectedRatio.whRatio == 1 {
            // 自由比例和1:1比例，进行edit rect转换
            
            // 将edit rect转换为相对edit image的rect
            let rect = convertClipRectToEditImageRect()
            // 旋转图片
            editImage = editImage.pt.rotate(orientation: .left)
            // 将rect进行旋转，转换到相对于旋转后的edit image的rect
            editRect = CGRect(x: rect.minY, y: editImage.size.height - rect.minX - rect.width, width: rect.height, height: rect.width)
            // 向右旋转可用下面这行代码
//            editRect = CGRect(x: editImage.size.width - rect.maxY, y: rect.minX, width: rect.height, height: rect.width)
        } else {
            // 其他比例的裁剪框，旋转后都重置edit rect
            
            // 旋转图片
            editImage = editImage.pt.rotate(orientation: .left)
            calculateClipRect()
        }
        
        imageView.image = editImage
        layoutInitialImage()
        
        let toFrame = view.convert(containerView.frame, from: mainScrollView)
        let transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        overlayView.alpha = 0
        shadowView.alpha = 0
        containerView.alpha = 0
        UIView.animate(withDuration: 0.3, animations: {
            animateImageView.transform = transform
            animateImageView.frame = toFrame
        }) { _ in
            animateImageView.removeFromSuperview()
            self.overlayView.alpha = 1
            self.containerView.alpha = 1
            self.shadowView.alpha = 1
            self.isRotating = false
        }
        
        generateThumbnailImage()
        showCutRatio()
    }
    
    @objc private func gridGesPanAction(_ pan: UIPanGestureRecognizer) {
        let point = pan.location(in: view)
        if pan.state == .began {
            startEditing()
            beginPanPoint = point
            clipOriginFrame = clipBoxFrame
            panEdge = calculatePanEdge(at: point)
        } else if pan.state == .changed {
            guard panEdge != .none else {
                return
            }
            updateClipBoxFrame(point: point)
        } else if pan.state == .cancelled || pan.state == .ended {
            panEdge = .none
            startTimer()
        }
    }
    
    private func calculatePanEdge(at point: CGPoint) -> PTCutViewController.ClipPanEdge {
        let frame = clipBoxFrame.insetBy(dx: -30, dy: -30)
        
        let cornerSize = CGSize(width: 60, height: 60)
        let topLeftRect = CGRect(origin: frame.origin, size: cornerSize)
        if topLeftRect.contains(point) {
            return .topLeft
        }
        
        let topRightRect = CGRect(origin: CGPoint(x: frame.maxX - cornerSize.width, y: frame.minY), size: cornerSize)
        if topRightRect.contains(point) {
            return .topRight
        }
        
        let bottomLeftRect = CGRect(origin: CGPoint(x: frame.minX, y: frame.maxY - cornerSize.height), size: cornerSize)
        if bottomLeftRect.contains(point) {
            return .bottomLeft
        }
        
        let bottomRightRect = CGRect(origin: CGPoint(x: frame.maxX - cornerSize.width, y: frame.maxY - cornerSize.height), size: cornerSize)
        if bottomRightRect.contains(point) {
            return .bottomRight
        }
        
        let topRect = CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: cornerSize.height))
        if topRect.contains(point) {
            return .top
        }
        
        let bottomRect = CGRect(origin: CGPoint(x: frame.minX, y: frame.maxY - cornerSize.height), size: CGSize(width: frame.width, height: cornerSize.height))
        if bottomRect.contains(point) {
            return .bottom
        }
        
        let leftRect = CGRect(origin: frame.origin, size: CGSize(width: cornerSize.width, height: frame.height))
        if leftRect.contains(point) {
            return .left
        }
        
        let rightRect = CGRect(origin: CGPoint(x: frame.maxX - cornerSize.width, y: frame.minY), size: CGSize(width: cornerSize.width, height: frame.height))
        if rightRect.contains(point) {
            return .right
        }
        
        return .none
    }
    
    private func updateClipBoxFrame(point: CGPoint) {
        var frame = clipBoxFrame
        let originFrame = clipOriginFrame
        
        var newPoint = point
        newPoint.x = max(maxClipFrame.minX, newPoint.x)
        newPoint.y = max(maxClipFrame.minY, newPoint.y)
        
        let diffX = ceil(newPoint.x - beginPanPoint.x)
        let diffY = ceil(newPoint.y - beginPanPoint.y)
        let ratio = selectedRatio.whRatio
        
        switch panEdge {
        case .left:
            frame.origin.x = originFrame.minX + diffX
            frame.size.width = originFrame.width - diffX
            if ratio != 0 {
                frame.size.height = originFrame.height - diffX / ratio
            }
        case .right:
            frame.size.width = originFrame.width + diffX
            if ratio != 0 {
                frame.size.height = originFrame.height + diffX / ratio
            }
        case .top:
            frame.origin.y = originFrame.minY + diffY
            frame.size.height = originFrame.height - diffY
            if ratio != 0 {
                frame.size.width = originFrame.width - diffY * ratio
            }
        case .bottom:
            frame.size.height = originFrame.height + diffY
            if ratio != 0 {
                frame.size.width = originFrame.width + diffY * ratio
            }
        case .topLeft:
            if ratio != 0 {
//                if abs(diffX / ratio) >= abs(diffY) {
                frame.origin.x = originFrame.minX + diffX
                frame.size.width = originFrame.width - diffX
                frame.origin.y = originFrame.minY + diffX / ratio
                frame.size.height = originFrame.height - diffX / ratio
//                } else {
//                    frame.origin.y = originFrame.minY + diffY
//                    frame.size.height = originFrame.height - diffY
//                    frame.origin.x = originFrame.minX + diffY * ratio
//                    frame.size.width = originFrame.width - diffY * ratio
//                }
            } else {
                frame.origin.x = originFrame.minX + diffX
                frame.size.width = originFrame.width - diffX
                frame.origin.y = originFrame.minY + diffY
                frame.size.height = originFrame.height - diffY
            }
        case .topRight:
            if ratio != 0 {
//                if abs(diffX / ratio) >= abs(diffY) {
                frame.size.width = originFrame.width + diffX
                frame.origin.y = originFrame.minY - diffX / ratio
                frame.size.height = originFrame.height + diffX / ratio
//                } else {
//                    frame.origin.y = originFrame.minY + diffY
//                    frame.size.height = originFrame.height - diffY
//                    frame.size.width = originFrame.width - diffY * ratio
//                }
            } else {
                frame.size.width = originFrame.width + diffX
                frame.origin.y = originFrame.minY + diffY
                frame.size.height = originFrame.height - diffY
            }
        case .bottomLeft:
            if ratio != 0 {
//                if abs(diffX / ratio) >= abs(diffY) {
                frame.origin.x = originFrame.minX + diffX
                frame.size.width = originFrame.width - diffX
                frame.size.height = originFrame.height - diffX / ratio
//                } else {
//                    frame.origin.x = originFrame.minX - diffY * ratio
//                    frame.size.width = originFrame.width + diffY * ratio
//                    frame.size.height = originFrame.height + diffY
//                }
            } else {
                frame.origin.x = originFrame.minX + diffX
                frame.size.width = originFrame.width - diffX
                frame.size.height = originFrame.height + diffY
            }
        case .bottomRight:
            if ratio != 0 {
//                if abs(diffX / ratio) >= abs(diffY) {
                frame.size.width = originFrame.width + diffX
                frame.size.height = originFrame.height + diffX / ratio
//                } else {
//                    frame.size.width += diffY * ratio
//                    frame.size.height += diffY
//                }
            } else {
                frame.size.width = originFrame.width + diffX
                frame.size.height = originFrame.height + diffY
            }
        default:
            break
        }
        
        let minSize: CGSize
        let maxSize: CGSize
        let maxClipFrame: CGRect
        if ratio != 0 {
            if ratio >= 1 {
                minSize = CGSize(width: minClipSize.height * ratio, height: minClipSize.height)
            } else {
                minSize = CGSize(width: minClipSize.width, height: minClipSize.width / ratio)
            }
            if ratio > self.maxClipFrame.width / self.maxClipFrame.height {
                maxSize = CGSize(width: self.maxClipFrame.width, height: self.maxClipFrame.width / ratio)
            } else {
                maxSize = CGSize(width: self.maxClipFrame.height * ratio, height: self.maxClipFrame.height)
            }
            maxClipFrame = CGRect(origin: CGPoint(x: self.maxClipFrame.minX + (self.maxClipFrame.width - maxSize.width) / 2, y: self.maxClipFrame.minY + (self.maxClipFrame.height - maxSize.height) / 2), size: maxSize)
        } else {
            minSize = minClipSize
            maxSize = self.maxClipFrame.size
            maxClipFrame = self.maxClipFrame
        }
        
        frame.size.width = min(maxSize.width, max(minSize.width, frame.size.width))
        frame.size.height = min(maxSize.height, max(minSize.height, frame.size.height))
        
        frame.origin.x = min(maxClipFrame.maxX - minSize.width, max(frame.origin.x, maxClipFrame.minX))
        frame.origin.y = min(maxClipFrame.maxY - minSize.height, max(frame.origin.y, maxClipFrame.minY))
        
        if panEdge == .topLeft || panEdge == .bottomLeft || panEdge == .left, frame.size.width <= minSize.width + CGFloat.ulpOfOne {
            frame.origin.x = originFrame.maxX - minSize.width
        }
        if panEdge == .topLeft || panEdge == .topRight || panEdge == .top, frame.size.height <= minSize.height + CGFloat.ulpOfOne {
            frame.origin.y = originFrame.maxY - minSize.height
        }
        
        changeClipBoxFrame(newFrame: frame)
    }
    
    private func startEditing() {
        cleanTimer()
        if !dimClippedAreaDuringAdjustments {
            shadowView.alpha = 0
        }
        overlayView.isEditing = true
        if rotateBtn.alpha != 0 {
            rotateBtn.layer.removeAllAnimations()
            ratioCollectionView.layer.removeAllAnimations()
            UIView.animate(withDuration: 0.2) {
                self.rotateBtn.alpha = 0
                self.ratioCollectionView.alpha = 0
            }
        }
    }
    
    @objc private func endEditing() {
        overlayView.isEditing = false
        moveClipContentToCenter()
    }
    
    private func startTimer() {
        cleanTimer()
        // TODO: 换target写法
        resetTimer = Timer.scheduledTimer(timeInterval: 0.8, target: PTWeakProxy(target: self), selector: #selector(endEditing), userInfo: nil, repeats: false)
        RunLoop.current.add(resetTimer!, forMode: .common)
    }
    
    private func cleanTimer() {
        resetTimer?.invalidate()
        resetTimer = nil
    }
    
    private func moveClipContentToCenter() {
        let maxClipRect = maxClipFrame
        var clipRect = clipBoxFrame
        
        if clipRect.width < CGFloat.ulpOfOne || clipRect.height < CGFloat.ulpOfOne {
            return
        }
        
        let scale = min(maxClipRect.width / clipRect.width, maxClipRect.height / clipRect.height)
        
        let focusPoint = CGPoint(x: clipRect.midX, y: clipRect.midY)
        let midPoint = CGPoint(x: maxClipRect.midX, y: maxClipRect.midY)
        
        clipRect.size.width = ceil(clipRect.width * scale)
        clipRect.size.height = ceil(clipRect.height * scale)
        clipRect.origin.x = maxClipRect.minX + ceil((maxClipRect.width - clipRect.width) / 2)
        clipRect.origin.y = maxClipRect.minY + ceil((maxClipRect.height - clipRect.height) / 2)
        
        var contentTargetPoint = CGPoint.zero
        contentTargetPoint.x = (focusPoint.x + mainScrollView.contentOffset.x) * scale
        contentTargetPoint.y = (focusPoint.y + mainScrollView.contentOffset.y) * scale
        
        var offset = CGPoint(x: contentTargetPoint.x - midPoint.x, y: contentTargetPoint.y - midPoint.y)
        offset.x = max(-clipRect.minX, offset.x)
        offset.y = max(-clipRect.minY, offset.y)
        UIView.animate(withDuration: 0.3) {
            if scale < 1 - CGFloat.ulpOfOne || scale > 1 + CGFloat.ulpOfOne {
                self.mainScrollView.zoomScale *= scale
                self.mainScrollView.zoomScale = min(self.mainScrollView.maximumZoomScale, self.mainScrollView.zoomScale)
            }

            if self.mainScrollView.zoomScale < self.mainScrollView.maximumZoomScale - CGFloat.ulpOfOne {
                offset.x = min(self.mainScrollView.contentSize.width - clipRect.maxX, offset.x)
                offset.y = min(self.mainScrollView.contentSize.height - clipRect.maxY, offset.y)
                self.mainScrollView.contentOffset = offset
            }
            self.rotateBtn.alpha = 1
            self.ratioCollectionView.alpha = 1
            if !self.dimClippedAreaDuringAdjustments {
                self.shadowView.alpha = 1
            }
            self.changeClipBoxFrame(newFrame: clipRect)
        }
    }
    
    private func clipImage() -> (clipImage: UIImage, editRect: CGRect) {
        let frame = convertClipRectToEditImageRect()
        let clipImage = editImage.pt.clipImage(angle: 0, editRect: frame, isCircle: selectedRatio.isCircle)
        return (clipImage, frame)
    }
    
    private func convertClipRectToEditImageRect() -> CGRect {
        let imageSize = editImage.size
        let contentSize = mainScrollView.contentSize
        let offset = mainScrollView.contentOffset
        let insets = mainScrollView.contentInset
        
        var frame = CGRect.zero
        frame.origin.x = floor((offset.x + insets.left) * (imageSize.width / contentSize.width))
        frame.origin.x = max(0, frame.origin.x)
        
        frame.origin.y = floor((offset.y + insets.top) * (imageSize.height / contentSize.height))
        frame.origin.y = max(0, frame.origin.y)
        
        frame.size.width = ceil(clipBoxFrame.width * (imageSize.width / contentSize.width))
        frame.size.width = min(imageSize.width, frame.width)
        
        frame.size.height = ceil(clipBoxFrame.height * (imageSize.height / contentSize.height))
        frame.size.height = min(imageSize.height, frame.height)
        
        return frame
    }
}

extension PTCutViewController {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == gridPanGes else {
            return true
        }
        let point = gestureRecognizer.location(in: view)
        let frame = overlayView.frame
        let innerFrame = frame.insetBy(dx: 22, dy: 22)
        let outerFrame = frame.insetBy(dx: -22, dy: -22)
        
        if innerFrame.contains(point) || !outerFrame.contains(point) {
            return false
        }
        return true
    }
}

extension PTCutViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        startEditing()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        guard scrollView == mainScrollView else {
            return
        }
        if !scrollView.isDragging {
            startTimer()
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView == mainScrollView else {
            return
        }
        startEditing()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == mainScrollView else {
            return
        }
        startTimer()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == mainScrollView else {
            return
        }
        if !decelerate {
            startTimer()
        }
    }
}

extension PTCutViewController: UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PTTransitioningAnimation()
    }
}

class PTClipShadowView: UIView {
    var isCircle = false {
        didSet {
            (layer as? PTClipShadowViewLayer)?.isCircle = isCircle
        }
    }
    
    var clearRect: CGRect = .zero {
        didSet {
            (layer as? PTClipShadowViewLayer)?.clearRect = clearRect
        }
    }
    
    override class var layerClass: AnyClass {
        return PTClipShadowViewLayer.self
    }
    
    override func action(for layer: CALayer, forKey event: String) -> CAAction? {
        guard event == #keyPath(PTClipShadowViewLayer.clearRect),
              let action = super.action(for: layer, forKey: #keyPath(backgroundColor)) as? CAAnimation,
              let animation: CABasicAnimation = (action.copy() as? CABasicAnimation) else {
            return super.action(for: layer, forKey: event)
        }
        animation.keyPath = #keyPath(PTClipShadowViewLayer.clearRect)
        animation.fromValue = (layer as? PTClipShadowViewLayer)?.clearRect
        animation.toValue = clearRect
        layer.add(animation, forKey: #keyPath(PTClipShadowViewLayer.clearRect))
        return animation
    }
    
    override func draw(_ layer: CALayer, in ctx: CGContext) {
        guard let shadowLayer = layer as? PTClipShadowViewLayer else {
            return super.draw(layer, in: ctx)
        }
        ctx.setFillColor(UIColor(white: 0, alpha: 0.7).cgColor)
        ctx.fill(layer.frame)
        if !isCircle {
            ctx.clear(shadowLayer.clearRect)
        } else {
            ctx.setBlendMode(.clear)
            ctx.setFillColor(UIColor.clear.cgColor)
            ctx.fillEllipse(in: shadowLayer.clearRect)
        }
    }
}

class PTClipShadowViewLayer: CALayer {
    @NSManaged var clearRect: CGRect
    @NSManaged var isCircle: Bool
    override class func needsDisplay(forKey key: String) -> Bool {
        return super.needsDisplay(forKey: key) || key == #keyPath(clearRect) || key == #keyPath(isCircle)
    }
}

// MARK: 裁剪网格视图
class PTClipOverlayView: UIView {
    static let cornerLineWidth: CGFloat = 3
    
    private var cornerBoldLines: [UIView] = []
    
    private var velLines: [UIView] = []
    
    private var horLines: [UIView] = []
    
    var isCircle = false {
        didSet {
            guard oldValue != isCircle else {
                return
            }
            setNeedsDisplay()
        }
    }
    
    var isEditing = false {
        didSet {
            guard isCircle else {
                return
            }
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        clipsToBounds = false
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        context?.setStrokeColor(UIColor.white.cgColor)
        context?.setLineWidth(1)
        context?.beginPath()
        
        let circleDiff: CGFloat = (3 - 2 * sqrt(2)) * (rect.width - 2 * PTClipOverlayView.cornerLineWidth) / 6
        
        var dw: CGFloat = 3
        for i in 0..<4 {
            let isInnerLine = isCircle && 1...2 ~= i
            context?.move(to: CGPoint(x: rect.origin.x + dw, y: PTClipOverlayView.cornerLineWidth + (isInnerLine ? circleDiff : 0)))
            context?.addLine(to: CGPoint(x: rect.origin.x + dw, y: rect.height - PTClipOverlayView.cornerLineWidth - (isInnerLine ? circleDiff : 0)))
            dw += (rect.size.width - 6) / 3
        }

        var dh: CGFloat = 3
        for i in 0..<4 {
            let isInnerLine = isCircle && 1...2 ~= i
            context?.move(to: CGPoint(x: PTClipOverlayView.cornerLineWidth + (isInnerLine ? circleDiff : 0), y: rect.origin.y + dh))
            context?.addLine(to: CGPoint(x: rect.width - PTClipOverlayView.cornerLineWidth - (isInnerLine ? circleDiff : 0), y: rect.origin.y + dh))
            dh += (rect.size.height - 6) / 3
        }

        context?.strokePath()

        context?.setLineWidth(PTClipOverlayView.cornerLineWidth)

        let boldLineLength: CGFloat = 20
        // 左上
        context?.move(to: CGPoint(x: 0, y: 1.5))
        context?.addLine(to: CGPoint(x: boldLineLength, y: 1.5))

        context?.move(to: CGPoint(x: 1.5, y: 0))
        context?.addLine(to: CGPoint(x: 1.5, y: boldLineLength))

        // 右上
        context?.move(to: CGPoint(x: rect.width - boldLineLength, y: 1.5))
        context?.addLine(to: CGPoint(x: rect.width, y: 1.5))

        context?.move(to: CGPoint(x: rect.width - 1.5, y: 0))
        context?.addLine(to: CGPoint(x: rect.width - 1.5, y: boldLineLength))

        // 左下
        context?.move(to: CGPoint(x: 1.5, y: rect.height - boldLineLength))
        context?.addLine(to: CGPoint(x: 1.5, y: rect.height))

        context?.move(to: CGPoint(x: 0, y: rect.height - 1.5))
        context?.addLine(to: CGPoint(x: boldLineLength, y: rect.height - 1.5))

        // 右下
        context?.move(to: CGPoint(x: rect.width - boldLineLength, y: rect.height - 1.5))
        context?.addLine(to: CGPoint(x: rect.width, y: rect.height - 1.5))

        context?.move(to: CGPoint(x: rect.width - 1.5, y: rect.height - boldLineLength))
        context?.addLine(to: CGPoint(x: rect.width - 1.5, y: rect.height))

        context?.strokePath()

        context?.setShadow(offset: CGSize(width: 1, height: 1), blur: 0)
    }
}
