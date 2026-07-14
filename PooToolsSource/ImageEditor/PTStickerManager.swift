//
//  PTStickerManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 15/6/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
import Foundation
import SafeSFSymbols
import SnapKit
import SwifterSwift

public struct PTInputTextStyle: Equatable {
    // 保留你原来的背景状态枚举
    public enum BackgroundStyle: Int {
        case normal
        case bg
    }
    
    // 所有的排版属性都装在这里
    public var bgStyle: BackgroundStyle = .normal
    public var alignment: NSTextAlignment = .left
    public var isBold: Bool = true
    public var isItalic: Bool = false
    public var hasUnderline: Bool = false
    public var hasStrikethrough: Bool = false
    public var outputWithTextViewBound: Bool = false
    public var rects:[CGRect] = []
    
    // 供外部快速初始化使用
    public init() {}
    
    // 保留你原来获取按钮图标的优雅属性，完全向后兼容！
    var btnImage: UIImage? {
        switch bgStyle {
        case .normal:
            return UIImage(.f.square)
        case .bg:
            return UIImage(.f.squareFill)
        }
    }
}

public class PTImageStickerView: PTBaseStickerView {
    public var image: UIImage {
        didSet {
            imageView.image = image
        }
    }
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView(image: image)
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    // Convert all states to model.
    public override var state: PTImageStickerState {
        PTImageStickerState(
                id: id,
                image: image,
                originScale: originScale,
                originAngle: originAngle,
                originFrame: originFrame,
                gesScale: gesScale,
                gesRotation: gesRotation,
                totalTranslationPoint: totalTranslationPoint
        )
    }
        
    convenience init(state: PTImageStickerState) {
        self.init(
            id: state.id,
            image: state.image,
            originScale: state.originScale,
            originAngle: state.originAngle,
            originFrame: state.originFrame,
            gesScale: state.gesScale,
            gesRotation: state.gesRotation,
            totalTranslationPoint: state.totalTranslationPoint,
            showBorder: true
        )
    }
    
    init(id: String = UUID().uuidString,
         image: UIImage,
         originScale: CGFloat,
         originAngle: CGFloat,
         originFrame: CGRect,
         gesScale: CGFloat = 1,
         gesRotation: CGFloat = 0,
         totalTranslationPoint: CGPoint = .zero,
         showBorder: Bool = true) {
        self.image = image
        super.init(id: id,
                   originScale: originScale,
                   originAngle: originAngle,
                   originFrame: originFrame,
                   gesScale: gesScale,
                   gesRotation: gesRotation,
                   totalTranslationPoint: totalTranslationPoint,
                   showBorder: showBorder)
        
        borderView.insertSubview(imageView, at: 0)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupUIFrameWhenFirstLayout() {
        imageView.frame = bounds.insetBy(dx: PTImageEditorConfig.share.staticEdgeInset, dy: PTImageEditorConfig.share.staticEdgeInset)
    }
        
    override func tapAction(_ ges: UITapGestureRecognizer) {
        guard gesIsEnabled else { return }
        
        // 如果当前是选中激活状态（边框显示且定时器有效），再次点击触发替换图片
        if let timer = timer, timer.isValid {
            delegate?.sticker(self, editImage: image)
        } else {
            // 否则执行父类的选中逻辑（显示边框）
            super.tapAction(ges)
        }
    }
    
    func changeSize(to newSize: CGSize) {
        // 1. ✅ 核心修复：永远不要在有 transform 的情况下修改 frame！
        // 直接修改 bounds.size，UIKit 会自动以当前的 center 为中心，保留 transform 进行缩放
        var newBounds = self.bounds
        newBounds.size = newSize
        self.bounds = newBounds
        
        // 2. 同步更新 originFrame，保证后续手势操作（如平移、重置等）的基准数据是正确的
        let oc = CGPoint(x: originFrame.midX, y: originFrame.midY)
        var of = originFrame
        of.origin.x = oc.x - newSize.width / 2
        of.origin.y = oc.y - newSize.height / 2
        of.size = newSize
        originFrame = of
        
        // 3. 更新内部 imageView 的大小，使其贴合新 bounds 并保留边距
        imageView.frame = self.bounds.insetBy(dx: PTImageEditorConfig.share.staticEdgeInset, dy: PTImageEditorConfig.share.staticEdgeInset)
        
        // 4. 强制触发父类 layoutSubviews
        // 这一步非常重要，它会让父类重新根据新的 bounds.width 准确计算顶部“旋转遥控器”和 4 个角手柄的位置
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
}

@MainActor public protocol PTStickerViewDelegate: NSObject {
    /// Called when scale or rotate or move.
    func stickerBeginOperation(_ sticker: PTBaseStickerView)
    
    /// Called during scale or rotate or move.
    func stickerOnOperation(_ sticker: PTBaseStickerView, panGes: UIPanGestureRecognizer)
    
    /// Called after scale or rotate or move.
    func stickerEndOperation(_ sticker: PTBaseStickerView, panGes: UIPanGestureRecognizer)
    
    /// Called when tap sticker.
    func stickerDidTap(_ sticker: PTBaseStickerView)
    
    func sticker(_ textSticker: PTTextStickerView, editText text: String)
    
    func sticker(_ imageSticker: PTImageStickerView, editImage image: UIImage)
}

public protocol PTStickerViewAdditional: NSObject {
    var gesIsEnabled: Bool { get set }
    
    func resetState()
    
    func moveToAshbin()
    
    func addScale(_ scale: CGFloat)
}

public class PTBaseStickerView: UIView, UIGestureRecognizerDelegate {
    private enum Direction: Int {
        case up = 0
        case right = 90
        case bottom = 180
        case left = 270
    }
    
    var id: String
    
    var borderWidth = 1 / UIScreen.main.scale
    
    var firstLayout = true
    
    let originScale: CGFloat
    
    let originAngle: CGFloat
    
    var maxGesScale: CGFloat
    
    var originTransform: CGAffineTransform = .identity
    
    var timer: Timer?
    
    var totalTranslationPoint: CGPoint = .zero
    
    var gesTranslationPoint: CGPoint = .zero
    
    var gesRotation: CGFloat = 0
    
    var gesScale: CGFloat = 1
    
    var onOperation = false
    
    public var gesIsEnabled = true
    
    var originFrame: CGRect
    
    lazy var tapGes = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
    
    lazy var pinchGes: UIPinchGestureRecognizer = {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinchAction(_:)))
        pinch.delegate = self
        return pinch
    }()
    
    lazy var panGes: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
        pan.delegate = self
        return pan
    }()
    
    public var state: PTBaseStickertState { fatalError() }
    
    var borderView: UIView { self }
    
    weak var delegate: PTStickerViewDelegate?
    
    private lazy var rotateLine: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        return view
    }()
    
    private lazy var tlHandle = createCornerHandle() // 左上
    private lazy var trHandle = createCornerHandle() // 右上
    private lazy var blHandle = createCornerHandle() // 左下
    private lazy var brHandle = createCornerHandle() // 右下

    private lazy var rotateHandle: UIView = {
        let view = createCornerHandle()
        // 给旋转手柄单独挂载旋转手势
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleRotatePan(_:)))
        view.addGestureRecognizer(pan)
        return view
    }()
    
    // MARK: - 拖拽状态记录器
    private var startDistance: CGFloat = 0
    private var startGesScale: CGFloat = 1
    private var fixedPointAbs: CGPoint = .zero
    private var startCenter: CGPoint = .zero
    
    private var startAngle: CGFloat = 0
    private var startGesRotation: CGFloat = 0

    deinit { }
    
    public class func calculateSize(image: UIImage, maxLimitSize: CGSize) -> CGSize {
        // 1. 预留出边距空间，计算图片真正可以占据的极限大小
        let imageLimitWidth = maxLimitSize.width - (PTImageEditorConfig.share.staticEdgeInset * 2)
        let imageLimitHeight = maxLimitSize.height - (PTImageEditorConfig.share.staticEdgeInset * 2)
        
        // 兜底：防止极限大小过小
        let safeMaxWidth = max(imageLimitWidth, 50)
        let safeMaxHeight = max(imageLimitHeight, 50)
        
        let imageRatio = image.size.width / image.size.height
        let limitRatio = safeMaxWidth / safeMaxHeight
        
        var targetSize = CGSize.zero
        if imageRatio > limitRatio {
            // 图片偏宽，以宽为基准等比例缩小
            targetSize.width = safeMaxWidth
            targetSize.height = safeMaxWidth / imageRatio
        } else {
            // 图片偏高，以高为基准等比例缩小
            targetSize.height = safeMaxHeight
            targetSize.width = safeMaxHeight * imageRatio
        }
        
        // 2. 最终返回的 Sticker 整体尺寸必须把内边距加回来！
        targetSize.width += PTImageEditorConfig.share.staticEdgeInset * 2
        targetSize.height += PTImageEditorConfig.share.staticEdgeInset * 2
        
        return targetSize
    }
    
    public class func getStickerOriginFrame(_ size: CGSize,current: PTEditImageEngineContext?,container:PTPassthroughView) -> CGRect {
        guard let context = current else { return .zero }
        
        // 1. 直接获取 engineMainView 自身的中心点 (相对自身 bounds)
        let mainViewCenter = CGPoint(
            x: context.engineMainView.bounds.midX,
            y: context.engineMainView.bounds.midY
        )
        
        // 2. 将该中心点转换到 imageStickersContainer 的坐标系下
        let centerInContainer = context.engineMainView.convert(mainViewCenter, to: container)
        
        // 3. 根据转换后的中心点和传入的 size，推算出完美的 CGRect
        return CGRect(
            x: centerInContainer.x - size.width / 2,
            y: centerInContainer.y - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    class func initWithState(_ state: PTBaseStickertState) -> PTBaseStickerView? {
        if let state = state as? PTTextStickerState {
            return PTTextStickerView(state: state)
        } else if let state = state as? PTImageStickerState {
            return PTImageStickerView(state: state)
        } else {
            return nil
        }
    }
    
    init(id: String = UUID().uuidString,
         originScale: CGFloat,
         originAngle: CGFloat,
         originFrame: CGRect,
         gesScale: CGFloat = 1,
         gesRotation: CGFloat = 0,
         totalTranslationPoint: CGPoint = .zero,
         showBorder: Bool = true) {
        self.id = id
        self.originScale = originScale
        self.originAngle = originAngle
        self.originFrame = originFrame
        maxGesScale = 4 / originScale
        super.init(frame: .zero)
        
        self.gesScale = gesScale
        self.gesRotation = gesRotation
        self.totalTranslationPoint = totalTranslationPoint
        
        borderView.layer.borderWidth = borderWidth
        
        addGestureRecognizer(tapGes)
        addGestureRecognizer(pinchGes)
        
        let rotationGes = UIRotationGestureRecognizer(target: self, action: #selector(rotationAction(_:)))
        rotationGes.delegate = self
        addGestureRecognizer(rotationGes)
        
        addGestureRecognizer(panGes)
        tapGes.require(toFail: panGes)
        
        borderView.addSubviews([rotateLine, tlHandle, trHandle, blHandle, brHandle, rotateHandle])
        if showBorder {
            startTimer()
        } else {
            hideBorder()
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // 🌟 布局 5 个点和连接线
        let handleSize: CGFloat = 44
        // 设置所有手柄的绝对尺寸
        [tlHandle, trHandle, blHandle, brHandle, rotateHandle].forEach {
            $0.bounds = CGRect(x: 0, y: 0, width: handleSize, height: handleSize)
        }
        
        // 设置所有手柄的中心点坐标
        tlHandle.center = CGPoint(x: 0, y: 0)
        trHandle.center = CGPoint(x: bounds.width, y: 0)
        blHandle.center = CGPoint(x: 0, y: bounds.height)
        brHandle.center = CGPoint(x: bounds.width, y: bounds.height)
        
        let rotateHandleY: CGFloat = -45
        rotateHandle.center = CGPoint(x: bounds.width/2, y: rotateHandleY)
        
        // 连线的布局
        rotateLine.bounds = CGRect(x: 0, y: 0, width: 2, height: abs(rotateHandleY) - 10)
        rotateLine.center = CGPoint(x: bounds.width/2, y: rotateHandleY / 2 + 5)

        guard firstLayout else { return }
        
        // 初始矩阵计算逻辑保持不变
        transform = transform.rotated(by: originAngle.pt.toPi)
        if totalTranslationPoint != .zero {
            let direction = direction(for: originAngle)
            if direction == .right {
                transform = transform.translatedBy(x: totalTranslationPoint.y, y: -totalTranslationPoint.x)
            } else if direction == .bottom {
                transform = transform.translatedBy(x: -totalTranslationPoint.x, y: -totalTranslationPoint.y)
            } else if direction == .left {
                transform = transform.translatedBy(x: -totalTranslationPoint.y, y: totalTranslationPoint.x)
            } else {
                transform = transform.translatedBy(x: totalTranslationPoint.x, y: totalTranslationPoint.y)
            }
        }
        transform = transform.scaledBy(x: originScale, y: originScale)
        originTransform = transform
        
        if gesScale != 1 { transform = transform.scaledBy(x: gesScale, y: gesScale) }
        if gesRotation != 0 { transform = transform.rotated(by: gesRotation) }
        
        firstLayout = false
        setupUIFrameWhenFirstLayout()
        
        updateHandlesScale()
    }
    
    private func updateHandlesScale() {
        // 计算当前贴纸受到的总缩放力
        let totalScale = originScale * gesScale
        guard totalScale > 0 else { return }
        
        // 施加逆向倍数（比如贴纸放大了 2 倍，手柄就缩小 0.5 倍，视觉上就抵消了）
        let inverseScale = 1.0 / totalScale
        let inverseTransform = CGAffineTransform(scaleX: inverseScale, y: inverseScale)
        
        tlHandle.transform = inverseTransform
        trHandle.transform = inverseTransform
        blHandle.transform = inverseTransform
        brHandle.transform = inverseTransform
        rotateHandle.transform = inverseTransform
        
        // 线条只需抵消 X 轴宽度即可，Y 轴高度保持跟随贴纸
        rotateLine.transform = CGAffineTransform(scaleX: inverseScale, y: 1.0)
    }

    func setupUIFrameWhenFirstLayout() {}
    
    private func direction(for angle: CGFloat) -> PTBaseStickerView.Direction {
        // 将角度转换为0~360，并对360取余
        let angle = ((Int(angle) % 360) + 360) % 360
        return PTBaseStickerView.Direction(rawValue: angle) ?? .up
    }
    
    @objc func tapAction(_ ges: UITapGestureRecognizer) {
        guard gesIsEnabled else { return }
        
//        superview?.bringSubviewToFront(self)
        delegate?.stickerDidTap(self)
        startTimer()
    }
    
    @objc func pinchAction(_ ges: UIPinchGestureRecognizer) {
        guard gesIsEnabled else { return }
        
        let scale = min(maxGesScale, gesScale * ges.scale)
        ges.scale = 1
        
        var scaleChanged = false
        if scale != gesScale {
            gesScale = scale
            scaleChanged = true
        }
        
        if ges.state == .began {
            setOperation(true)
        } else if ges.state == .changed {
            if scaleChanged {
                updateTransform()
            }
        } else if ges.state == .ended || ges.state == .cancelled {
            // 当有拖动时，在panAction中执行setOperation(false)
            if gesTranslationPoint == .zero {
                setOperation(false)
            }
        }
    }
    
    @objc func rotationAction(_ ges: UIRotationGestureRecognizer) {
        guard gesIsEnabled else { return }
        
        gesRotation += ges.rotation
        ges.rotation = 0
        
        if ges.state == .began {
            setOperation(true)
        } else if ges.state == .changed {
            updateTransform()
        } else if ges.state == .ended || ges.state == .cancelled {
            if gesTranslationPoint == .zero {
                setOperation(false)
            }
        }
    }
    
    @objc func panAction(_ ges: UIPanGestureRecognizer) {
        guard gesIsEnabled else { return }
        
        let point = ges.translation(in: superview)
        gesTranslationPoint = CGPoint(x: point.x / originScale, y: point.y / originScale)
        
        if ges.state == .began {
            setOperation(true)
        } else if ges.state == .changed {
            updateTransform()
        } else if ges.state == .ended || ges.state == .cancelled {
            totalTranslationPoint.x += point.x
            totalTranslationPoint.y += point.y
            setOperation(false)
            let direction = direction(for: originAngle)
            if direction == .right {
                originTransform = originTransform.translatedBy(x: gesTranslationPoint.y, y: -gesTranslationPoint.x)
            } else if direction == .bottom {
                originTransform = originTransform.translatedBy(x: -gesTranslationPoint.x, y: -gesTranslationPoint.y)
            } else if direction == .left {
                originTransform = originTransform.translatedBy(x: -gesTranslationPoint.y, y: gesTranslationPoint.x)
            } else {
                originTransform = originTransform.translatedBy(x: gesTranslationPoint.x, y: gesTranslationPoint.y)
            }
            gesTranslationPoint = .zero
        }
    }
    
    func setOperation(_ isOn: Bool) {
        if isOn, !onOperation {
            onOperation = true
            cleanTimer()
            borderView.layer.borderColor = UIColor.systemBlue.cgColor // 边框改为蓝色
            setHandlesHidden(false) // 显示 5 个点
//            superview?.bringSubviewToFront(self)
            delegate?.stickerBeginOperation(self)
        } else if !isOn, onOperation {
            onOperation = false
            startTimer()
            delegate?.stickerEndOperation(self, panGes: panGes)
        }
    }
    
    func updateTransform() {
        var transform = originTransform
        let direction = direction(for: originAngle)
        if direction == .right {
            transform = transform.translatedBy(x: gesTranslationPoint.y, y: -gesTranslationPoint.x)
        } else if direction == .bottom {
            transform = transform.translatedBy(x: -gesTranslationPoint.x, y: -gesTranslationPoint.y)
        } else if direction == .left {
            transform = transform.translatedBy(x: -gesTranslationPoint.y, y: gesTranslationPoint.x)
        } else {
            transform = transform.translatedBy(x: gesTranslationPoint.x, y: gesTranslationPoint.y)
        }
        transform = transform.scaledBy(x: gesScale, y: gesScale)
        transform = transform.rotated(by: gesRotation)
        self.transform = transform
        updateHandlesScale()
        delegate?.stickerOnOperation(self, panGes: panGes)
    }
    
    @objc private func hideBorder() {
        setHandlesHidden(true)
    }
    
    private func setHandlesHidden(_ hidden: Bool) {
        [tlHandle, trHandle, blHandle, brHandle, rotateHandle, rotateLine].forEach { $0.isHidden = hidden }
    }

    func startTimer() {
        cleanTimer()
        borderView.layer.borderColor = UIColor.systemBlue.cgColor
        setHandlesHidden(false)
        timer = Timer.scheduledTimer(timeInterval: 2, target: PTWeakProxy(target: self), selector: #selector(hideBorder), userInfo: nil, repeats: false)
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    private func cleanTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: UIGestureRecognizerDelegate
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
        
    private func createCornerHandle() -> UIView {
        // 1. 创建一个透明的、足够大的容器作为手势接收器 (44x44 是最佳触摸区域)
        let handleView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        handleView.backgroundColor = .clear // 透明，纯粹用来“接客”响应手势
        handleView.isUserInteractionEnabled = true
        
        // 2. 内部真正显示的小圆点 (20x20)
        let visibleDot = UIView(frame: CGRect(x: 12, y: 12, width: 20, height: 20))
        visibleDot.backgroundColor = .white
        visibleDot.layer.borderColor = UIColor.systemBlue.cgColor
        visibleDot.layer.borderWidth = 2
        visibleDot.layer.cornerRadius = 10
        visibleDot.isUserInteractionEnabled = false // 关掉交互，让外层 handleView 接管手势
        
        // 保证贴纸缩放时，圆点始终在 44x44 容器的正中心
        visibleDot.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        
        handleView.addSubview(visibleDot)
        
        // 3. 将手势挂载到大的透明容器上
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleCornerPan(_:)))
        handleView.addGestureRecognizer(pan)
        return handleView
    }
    
    @objc private func handleCornerPan(_ ges: UIPanGestureRecognizer) {
        guard gesIsEnabled, let superview = self.superview, let handle = ges.view else { return }
        
        let point = ges.location(in: superview)
        
        if ges.state == .began {
            setOperation(true)
            cleanTimer()
            
            // 1. 寻找对角点作为绝对固定点 (Fixed Point)
            let fixedHandle: UIView
            if handle === tlHandle { fixedHandle = brHandle }
            else if handle === trHandle { fixedHandle = blHandle }
            else if handle === blHandle { fixedHandle = trHandle }
            else { fixedHandle = tlHandle }
            
            // 2. 记录初始状态参数
            startCenter = self.center
            fixedPointAbs = self.convert(fixedHandle.center, to: superview) // 获取固定点在画布上的绝对坐标
            startDistance = hypot(point.x - fixedPointAbs.x, point.y - fixedPointAbs.y) // 获取手指到固定点的初始距离
            startGesScale = gesScale
            
        } else if ges.state == .changed {
            if startDistance == 0 { return }
            
            // 3. 计算手指与固定点的当前距离
            let currentDistance = hypot(point.x - fixedPointAbs.x, point.y - fixedPointAbs.y)
            let ratio = currentDistance / startDistance // 距离变化率就是缩放率
            
            // 4. 计算并限制新的缩放倍数
            gesScale = max(0.1, min(maxGesScale, startGesScale * ratio))
            
            // 5. 核心：补偿位移计算。因为 scaling 默认是以 center 为锚点的，所以我们需要把 center 偏移过去，从而保证 fixedPoint 视觉上没有移动。
            let actualScaleRatio = gesScale / startGesScale
            // 算出中心点到固定点的向量
            let vX = fixedPointAbs.x - startCenter.x
            let vY = fixedPointAbs.y - startCenter.y
            // 补偿位移 = 向量 * (1 - 缩放比例)
            let deltaCX = vX * (1 - actualScaleRatio)
            let deltaCY = vY * (1 - actualScaleRatio)
            
            // 将绝对位移转换为相对 originScale 的位移
            gesTranslationPoint = CGPoint(x: deltaCX / originScale, y: deltaCY / originScale)
            updateTransform()
            
        } else if ges.state == .ended || ges.state == .cancelled {
            // 6. 拖拽结束时，将临时补偿位移固化到基础矩阵中
            let actualScaleRatio = gesScale / startGesScale
            let vX = fixedPointAbs.x - startCenter.x
            let vY = fixedPointAbs.y - startCenter.y
            let deltaCX = vX * (1 - actualScaleRatio)
            let deltaCY = vY * (1 - actualScaleRatio)
            
            let direction = direction(for: originAngle)
            if direction == .right {
                originTransform = originTransform.translatedBy(x: gesTranslationPoint.y, y: -gesTranslationPoint.x)
            } else if direction == .bottom {
                originTransform = originTransform.translatedBy(x: -gesTranslationPoint.x, y: -gesTranslationPoint.y)
            } else if direction == .left {
                originTransform = originTransform.translatedBy(x: -gesTranslationPoint.y, y: gesTranslationPoint.x)
            } else {
                originTransform = originTransform.translatedBy(x: gesTranslationPoint.x, y: gesTranslationPoint.y)
            }
            
            // 将增量追加到大管家 totalTranslationPoint 中
            totalTranslationPoint.x += deltaCX
            totalTranslationPoint.y += deltaCY
            
            gesTranslationPoint = .zero
            startTimer()
        }
    }
    
    // MARK: - 🌟 核心算法 2：顶部独立旋转
    
    @objc private func handleRotatePan(_ ges: UIPanGestureRecognizer) {
        guard gesIsEnabled, let superview = self.superview else { return }
        
        let point = ges.location(in: superview)
        let center = self.center
        
        if ges.state == .began {
            setOperation(true)
            cleanTimer()
            // 记录手指在画布上的绝对角度
            startAngle = atan2(point.y - center.y, point.x - center.x)
            startGesRotation = gesRotation
            
        } else if ges.state == .changed {
            // 计算当前手势偏离初始手势的角度差，并累加到初始旋转角上
            let currentAngle = atan2(point.y - center.y, point.x - center.x)
            gesRotation = startGesRotation + (currentAngle - startAngle)
            updateTransform()
            
        } else if ges.state == .ended || ges.state == .cancelled {
            startTimer()
        }
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 如果当前视图被隐藏、透明或禁止交互，按系统默认处理
        guard !isHidden && alpha > 0.01 && isUserInteractionEnabled else {
            return nil
        }
        
        // 倒序遍历所有子视图（后添加的视图在最上面，优先响应）
        for subview in subviews.reversed() {
            // 确保子视图没有被隐藏且允许交互
            guard !subview.isHidden && subview.isUserInteractionEnabled && subview.alpha > 0.01 else {
                continue
            }
            
            // 将触摸点转换到子视图的坐标系中
            let subPoint = subview.convert(point, from: self)
            // 询问子视图：这个点是否在你（或你的子视图）身上？
            if let result = subview.hitTest(subPoint, with: event) {
                return result
            }
        }
        
        // 如果子视图都没命中，再检查自己
        return super.hitTest(point, with: event)
    }
}

extension PTBaseStickerView: @MainActor PTStickerViewAdditional {
    public func resetState() {
        onOperation = false
        cleanTimer()
        hideBorder()
    }
    
    public func moveToAshbin() {
        cleanTimer()
        removeFromSuperview()
    }
    
    public func addScale(_ scale: CGFloat) {
        // Revert zoom scale.
        transform = transform.scaledBy(x: 1 / originScale, y: 1 / originScale)
        // Revert ges scale.
        transform = transform.scaledBy(x: 1 / gesScale, y: 1 / gesScale)
        // Revert ges rotation.
        transform = transform.rotated(by: -gesRotation)
        
        var origin = frame.origin
        origin.x *= scale
        origin.y *= scale
        
        let newSize = CGSize(width: frame.width * scale, height: frame.height * scale)
        let newOrigin = CGPoint(x: frame.minX + (frame.width - newSize.width) / 2, y: frame.minY + (frame.height - newSize.height) / 2)
        let diffX: CGFloat = (origin.x - newOrigin.x)
        let diffY: CGFloat = (origin.y - newOrigin.y)
        
        let direction = direction(for: originAngle)
        if direction == .right {
            transform = transform.translatedBy(x: diffY, y: -diffX)
            originTransform = originTransform.translatedBy(x: diffY / originScale, y: -diffX / originScale)
        } else if direction == .bottom {
            transform = transform.translatedBy(x: -diffX, y: -diffY)
            originTransform = originTransform.translatedBy(x: -diffX / originScale, y: -diffY / originScale)
        } else if direction == .left {
            transform = transform.translatedBy(x: -diffY, y: diffX)
            originTransform = originTransform.translatedBy(x: -diffY / originScale, y: diffX / originScale)
        } else {
            transform = transform.translatedBy(x: diffX, y: diffY)
            originTransform = originTransform.translatedBy(x: diffX / originScale, y: diffY / originScale)
        }
        totalTranslationPoint.x += diffX
        totalTranslationPoint.y += diffY
        
        transform = transform.scaledBy(x: scale, y: scale)
        
        // Readd zoom scale.
        transform = transform.scaledBy(x: originScale, y: originScale)
        // Readd ges scale.
        transform = transform.scaledBy(x: gesScale, y: gesScale)
        // Readd ges rotation.
        transform = transform.rotated(by: gesRotation)
        
        gesScale *= scale
        maxGesScale *= scale
    }
}

public class PTTextStickerView: PTBaseStickerView {
    public static let fontSize: CGFloat = 32
        
    private lazy var imageView: UIImageView = {
        let view = UIImageView(image: image)
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    public var text: String
    
    public var textColor: UIColor
    
    public var font: UIFont?
    
    public var style: PTInputTextStyle
    
    public var image: UIImage {
        didSet {
            imageView.image = image
        }
    }

    // Convert all states to model.
    public override var state: PTTextStickerState {
        PTTextStickerState(id: id,
                           text: text,
                           textColor: textColor,
                           font: font,
                           style: style,
                           image: image,
                           originScale: originScale,
                           originAngle: originAngle,
                           originFrame: originFrame,
                           gesScale: gesScale,
                           gesRotation: gesRotation,
                           totalTranslationPoint: totalTranslationPoint)
    }
        
    convenience init(state: PTTextStickerState) {
        self.init(id: state.id,
                  text: state.text,
                  textColor: state.textColor,
                  font: state.font,
                  style: state.style,
                  image: state.image,
                  originScale: state.originScale,
                  originAngle: state.originAngle,
                  originFrame: state.originFrame,
                  gesScale: state.gesScale,
                  gesRotation: state.gesRotation,
                  totalTranslationPoint: state.totalTranslationPoint,
                  showBorder: true)
    }
    
    init(id: String = UUID().uuidString,
         text: String,
         textColor: UIColor,
         font: UIFont?,
         style: PTInputTextStyle,
         image: UIImage,
         originScale: CGFloat,
         originAngle: CGFloat,
         originFrame: CGRect,
         gesScale: CGFloat = 1,
         gesRotation: CGFloat = 0,
         totalTranslationPoint: CGPoint = .zero,
         showBorder: Bool = true) {
        self.text = text
        self.textColor = textColor
        self.font = font
        self.style = style
        self.image = image
        super.init(
            id: id,
            originScale: originScale,
            originAngle: originAngle,
            originFrame: originFrame,
            gesScale: gesScale,
            gesRotation: gesRotation,
            totalTranslationPoint: totalTranslationPoint,
            showBorder: showBorder
        )
        
        borderView.addSubview(imageView)
        borderView.sendSubviewToBack(imageView)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupUIFrameWhenFirstLayout() {
        imageView.frame = borderView.bounds.insetBy(dx: PTImageEditorConfig.share.staticEdgeInset, dy: PTImageEditorConfig.share.staticEdgeInset)
    }
    
    override func tapAction(_ ges: UITapGestureRecognizer) {
        guard gesIsEnabled else { return }
        
        if let timer = timer, timer.isValid {
            delegate?.sticker(self, editText: text)
        } else {
            super.tapAction(ges)
        }
    }
    
    func changeSize(to newSize: CGSize) {
        // ✅ 核心修复：永远不要在有 transform 的情况下修改 frame！
        // 直接修改 bounds.size，UIKit 会自动以当前的 center 为中心进行缩放
        var newBounds = self.bounds
        newBounds.size = newSize
        self.bounds = newBounds
        
        // 更新原状态的 originFrame 保持同步
        let oc = CGPoint(x: originFrame.midX, y: originFrame.midY)
        var of = originFrame
        of.origin.x = oc.x - newSize.width / 2
        of.origin.y = oc.y - newSize.height / 2
        of.size = newSize
        originFrame = of
        
        // 更新内部 imageView 的大小
        imageView.frame = self.bounds.insetBy(dx: PTImageEditorConfig.share.staticEdgeInset, dy: PTImageEditorConfig.share.staticEdgeInset)
    }
}
