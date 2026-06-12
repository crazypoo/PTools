//
//  PTEditInputViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 29/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import SafeSFSymbols

public enum PTInputTextStyle {
    case normal
    case bg
    
    fileprivate var btnImage: UIImage? {
        switch self {
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

    private static let edgeInset: CGFloat = 20
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView(image: image)
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    // Convert all states to model.
    override var state: PTImageStickerState {
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
        
        borderView.addSubview(imageView)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupUIFrameWhenFirstLayout() {
        imageView.frame = bounds.insetBy(dx: Self.edgeInset, dy: Self.edgeInset)
    }
    
    class func calculateSize(image: UIImage, width: CGFloat) -> CGSize {
        let maxSide = width / 2
        let minSide: CGFloat = 100
        let whRatio = image.size.width / image.size.height
        var size: CGSize = .zero
        if whRatio >= 1 {
            let w = min(maxSide, max(minSide, image.size.width))
            let h = w / whRatio
            size = CGSize(width: w, height: h)
        } else {
            let h = min(maxSide, max(minSide, image.size.width))
            let w = h * whRatio
            size = CGSize(width: w, height: h)
        }
        size.width += Self.edgeInset * 2
        size.height += Self.edgeInset * 2
        return size
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
        // Revert zoom scale.
        transform = transform.scaledBy(x: 1 / originScale, y: 1 / originScale)
        // Revert ges scale.
        transform = transform.scaledBy(x: 1 / gesScale, y: 1 / gesScale)
        // Revert ges rotation.
        transform = transform.rotated(by: -gesRotation)
        transform = transform.rotated(by: -originAngle.pt.toPi)
        
        // Recalculate current frame.
        let center = CGPoint(x: frame.midX, y: frame.midY)
        var frame = frame
        frame.origin.x = center.x - newSize.width / 2
        frame.origin.y = center.y - newSize.height / 2
        frame.size = newSize
        self.frame = frame
        
        let oc = CGPoint(x: originFrame.midX, y: originFrame.midY)
        var of = originFrame
        of.origin.x = oc.x - newSize.width / 2
        of.origin.y = oc.y - newSize.height / 2
        of.size = newSize
        originFrame = of
        
        imageView.frame = borderView.bounds.insetBy(dx: Self.edgeInset, dy: Self.edgeInset)
        
        // Readd zoom scale.
        transform = transform.scaledBy(x: originScale, y: originScale)
        // Readd ges scale.
        transform = transform.scaledBy(x: gesScale, y: gesScale)
        // Readd ges rotation.
        transform = transform.rotated(by: gesRotation)
        transform = transform.rotated(by: originAngle.pt.toPi)
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

protocol PTStickerViewAdditional: NSObject {
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
    
    var gesIsEnabled = true
    
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
    
    var state: PTBaseStickertState { fatalError() }
    
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
        let handleSize: CGFloat = 20
        tlHandle.frame = CGRect(x: -handleSize/2, y: -handleSize/2, width: handleSize, height: handleSize)
        trHandle.frame = CGRect(x: bounds.width - handleSize/2, y: -handleSize/2, width: handleSize, height: handleSize)
        blHandle.frame = CGRect(x: -handleSize/2, y: bounds.height - handleSize/2, width: handleSize, height: handleSize)
        brHandle.frame = CGRect(x: bounds.width - handleSize/2, y: bounds.height - handleSize/2, width: handleSize, height: handleSize)
        
        let rotateHandleY: CGFloat = -35
        rotateHandle.frame = CGRect(x: bounds.width/2 - handleSize/2, y: rotateHandleY, width: handleSize, height: handleSize)
        rotateLine.frame = CGRect(x: bounds.width/2 - 1, y: rotateHandleY + handleSize/2, width: 2, height: abs(rotateHandleY) - handleSize/2)
        
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
    }
    
    func setupUIFrameWhenFirstLayout() {}
    
    private func direction(for angle: CGFloat) -> PTBaseStickerView.Direction {
        // 将角度转换为0~360，并对360取余
        let angle = ((Int(angle) % 360) + 360) % 360
        return PTBaseStickerView.Direction(rawValue: angle) ?? .up
    }
    
    @objc func tapAction(_ ges: UITapGestureRecognizer) {
        guard gesIsEnabled else { return }
        
        superview?.bringSubviewToFront(self)
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
            superview?.bringSubviewToFront(self)
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
        let view = UIView()
        view.backgroundColor = .white
        view.layer.borderColor = UIColor.systemBlue.cgColor
        view.layer.borderWidth = 2
        view.layer.cornerRadius = 10
        view.isUserInteractionEnabled = true
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleCornerPan(_:)))
        view.addGestureRecognizer(pan)
        return view
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
    func resetState() {
        onOperation = false
        cleanTimer()
        hideBorder()
    }
    
    func moveToAshbin() {
        cleanTimer()
        removeFromSuperview()
    }
    
    func addScale(_ scale: CGFloat) {
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
    static let fontSize: CGFloat = 32
    
    private static let edgeInset: CGFloat = 10
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView(image: image)
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    var text: String
    
    var textColor: UIColor
    
    var font: UIFont?
    
    var style: PTInputTextStyle
    
    var image: UIImage {
        didSet {
            imageView.image = image
        }
    }

    // Convert all states to model.
    override var state: PTTextStickerState {
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
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupUIFrameWhenFirstLayout() {
        imageView.frame = borderView.bounds.insetBy(dx: Self.edgeInset, dy: Self.edgeInset)
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
        // Revert zoom scale.
        transform = transform.scaledBy(x: 1 / originScale, y: 1 / originScale)
        // Revert ges scale.
        transform = transform.scaledBy(x: 1 / gesScale, y: 1 / gesScale)
        // Revert ges rotation.
        transform = transform.rotated(by: -gesRotation)
        transform = transform.rotated(by: -originAngle.pt.toPi)
        
        // Recalculate current frame.
        let center = CGPoint(x: frame.midX, y: frame.midY)
        var frame = frame
        frame.origin.x = center.x - newSize.width / 2
        frame.origin.y = center.y - newSize.height / 2
        frame.size = newSize
        self.frame = frame
        
        let oc = CGPoint(x: originFrame.midX, y: originFrame.midY)
        var of = originFrame
        of.origin.x = oc.x - newSize.width / 2
        of.origin.y = oc.y - newSize.height / 2
        of.size = newSize
        originFrame = of
        
        imageView.frame = borderView.bounds.insetBy(dx: Self.edgeInset, dy: Self.edgeInset)
        
        // Readd zoom scale.
        transform = transform.scaledBy(x: originScale, y: originScale)
        // Readd ges scale.
        transform = transform.scaledBy(x: gesScale, y: gesScale)
        // Readd ges rotation.
        transform = transform.rotated(by: gesRotation)
        transform = transform.rotated(by: originAngle.pt.toPi)
    }
    
    class func calculateSize(image: UIImage) -> CGSize {
        var size = image.size
        size.width += Self.edgeInset * 2
        size.height += Self.edgeInset * 2
        return size
    }
}

class PTEditInputViewController: PTBaseViewController {
    private static let toolViewHeight: CGFloat = 70
    
    // 用于节流的高频绘制任务
    private var drawBgTask: Task<Void, Never>?
    
    private let image: UIImage?
    
    private var text: String
    
    private var font: UIFont = .boldSystemFont(ofSize: PTTextStickerView.fontSize)
    
    private var currentColor: UIColor {
        didSet {
            refreshTextViewUI()
        }
    }
    
    private var textStyle: PTInputTextStyle
    
    private lazy var cancelBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(PTImageEditorConfig.share.textBackImage, for: .normal)
        btn.addTarget(self, action: #selector(cancelBtnClick), for: .touchUpInside)
        btn.bounds = CGRect(origin: .zero, size: .init(width: 34, height: 34))
        return btn
    }()
    
    private lazy var doneBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(PTImageEditorConfig.share.textSubmitImage, for: .normal)
        btn.addTarget(self, action: #selector(doneBtnClick), for: .touchUpInside)
        btn.layer.masksToBounds = true
        btn.bounds = CGRect(origin: .zero, size: .init(width: 34, height: 34))
        return btn
    }()
    
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.keyboardAppearance = .dark
        textView.returnKeyType = .done
        textView.delegate = self
        textView.backgroundColor = .clear
        textView.tintColor = .white
        textView.textColor = currentColor
        textView.text = text
        textView.font = font
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        textView.textContainer.lineFragmentPadding = 0
        textView.layoutManager.delegate = self
        return textView
    }()
    
    private lazy var toolView = UIView(frame: CGRect(x: 0, y: view.pt.jx_height - Self.toolViewHeight, width: view.pt.jx_width, height: Self.toolViewHeight))
    
    private lazy var textStyleBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.addActionHandlers { _ in
            self.textStyleBtnClick()
        }
        return btn
    }()
    
    private lazy var drawColorButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(UIImage(.paintpalette), for: .normal)
        view.addActionHandlers { sender in
            let colorPicker = PTColorPickerContainerViewController()
            colorPicker.backButton.setImage(PTImageEditorConfig.share.colorPickerBackImage, for: .normal)
            colorPicker.picker.selectedColor = self.currentColor
            colorPicker.selectedColorCallback = { color in
                self.currentColor = color
            }
            self.navigationController?.pushViewController(colorPicker, completion: {
            })
        }
        return view
    }()
        
    private lazy var textLayer = CAShapeLayer()
    
    private let textLayerRadius: CGFloat = 10
    
    private let maxTextCount = 100
    
    /// text, textColor, image, style
    var endInput: ((String, UIColor, UIFont, UIImage?, PTInputTextStyle) -> Void)?
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
    
    override var prefersStatusBarHidden: Bool {
        true
    }
            
    public override func preferredNavigationBarStyle() -> PTNavigationBarStyle {
        return .solid(.clear)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setCustomBackButtonView(cancelBtn)
        setCustomRightButtons(buttons: [doneBtn])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PTGCDManager.shared.delayOnMain(time: 0.35, block: {
            self.changeStatusBar(type: .Dark)
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        changeStatusBar(type: .Auto)
    }

    init(image: UIImage?, text: String? = nil, textColor: UIColor? = nil, font: UIFont? = nil, style: PTInputTextStyle = .normal) {
        self.image = image
        self.text = text ?? ""
        if let font = font {
            self.font = font.withSize(PTTextStickerView.fontSize)
        }
        if let textColor = textColor {
            currentColor = textColor
        } else {
            currentColor = PTImageEditorConfig.share.textStickerDefaultTextColor
        }
        textStyle = style
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIApplication.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIApplication.keyboardWillHideNotification, object: nil)
        
        PTGCDManager.shared.delayOnMain(time: 0.35) {
            self.textView.becomeFirstResponder()
        }
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        let bgImageView = UIImageView(image: image?.pt.blurImage(level: 4))
        bgImageView.frame = view.bounds
        bgImageView.contentMode = .scaleAspectFit
        view.addSubview(bgImageView)
        
        let coverView = UIView(frame: bgImageView.bounds)
        coverView.backgroundColor = .black
        coverView.alpha = 0.4
        bgImageView.addSubview(coverView)
        
        view.addSubviews([textView,toolView])
        
        textView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.height.equalTo(200)
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total + 10)
        }
        
        toolView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight)
            make.height.equalTo(54)
        }
        toolView.addSubviews([textStyleBtn,drawColorButton])
        
        textStyleBtn.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.centerY.equalToSuperview()
            make.right.equalTo(self.toolView.snp.centerX).offset(-15)
        }
        
        drawColorButton.snp.makeConstraints { make in
            make.size.centerY.equalTo(self.textStyleBtn)
            make.left.equalTo(self.toolView.snp.centerX).offset(15)
        }
        
        // 这个要放到这里，不能放到懒加载里，因为放到懒加载里会触发layoutManager(_:, didCompleteLayoutFor:,atEnd)，导致循环调用
        textView.textAlignment = .left
        
        refreshTextViewUI()
    }
    
    private func refreshTextViewUI() {
        textStyleBtn.setImage(textStyle.btnImage, for: .normal)
        textStyleBtn.setImage(textStyle.btnImage, for: .highlighted)
        
        drawTextBackground()
        
        guard textStyle == .bg else {
            textView.textColor = currentColor
            return
        }
        
        if currentColor == .white {
            textView.textColor = .black
        } else if currentColor == .black {
            textView.textColor = .white
        } else {
            textView.textColor = .white
        }
    }
    
    @objc private func textStyleBtnClick() {
        if textStyle == .normal {
            textStyle = .bg
        } else {
            textStyle = .normal
        }
        
        refreshTextViewUI()
    }
    
    @objc private func cancelBtnClick() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func doneBtnClick() {
        textView.tintColor = .clear
        textView.endEditing(true)

        var image: UIImage?
        
        if !textView.text.isEmpty {
            for subview in textView.subviews {
                if NSStringFromClass(subview.classForCoder) == "_UITextContainerView" {
                    let size = textView.sizeThatFits(subview.frame.size)
                    image = UIGraphicsImageRenderer.pt.renderImage(size: size) { context in
                        if textStyle == .bg {
                            textLayer.render(in: context)
                        }

                        subview.layer.render(in: context)
                    }
                }
            }
        }
        
        endInput?(textView.text, currentColor, font, image, textStyle)
        navigationController?.popViewController()
    }
    
    @objc private func keyboardWillShow(_ notify: Notification) {
        let rect = notify.userInfo?[UIApplication.keyboardFrameEndUserInfoKey] as? CGRect
        let keyboardH = rect?.height ?? 366
        let duration: TimeInterval = notify.userInfo?[UIApplication.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        
        let toolViewFrame = CGRect(x: 0, y: view.pt.jx_height - keyboardH - Self.toolViewHeight, width: view.pt.jx_width, height: Self.toolViewHeight)
        
        var textViewFrame = textView.frame
        textViewFrame.size.height = toolViewFrame.minY - textViewFrame.minY - 20
        
        UIView.animate(withDuration: max(duration, 0.25)) {
            self.toolView.frame = toolViewFrame
            self.textView.frame = textViewFrame
        }
    }
    
    @objc private func keyboardWillHide(_ notify: Notification) {
        let duration: TimeInterval = notify.userInfo?[UIApplication.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        
        let toolViewFrame = CGRect(
            x: 0,
            y: view.pt.jx_height - deviceSafeAreaInsets().bottom - Self.toolViewHeight,
            width: view.pt.jx_width,
            height: Self.toolViewHeight
        )
        
        var textViewFrame = textView.frame
        textViewFrame.size.height = toolViewFrame.minY - textViewFrame.minY - 20
        
        UIView.animate(withDuration: max(duration, 0.25)) {
            self.toolView.frame = toolViewFrame
            self.textView.frame = textViewFrame
        }
    }
}

// MARK: Draw text layer
extension PTEditInputViewController {
    
    @MainActor
    private func drawTextBackground() {
        guard textStyle == .bg, !textView.text.isEmpty else {
            textLayer.removeFromSuperlayer()
            return
        }
        
        // 取消上一次的任务（防手抖节流）
        drawBgTask?.cancel()
        
        // 开启 Swift 6 原生主线程 Task 进行节流
        drawBgTask = Task { @MainActor [weak self] in
            guard let self else { return }
            
            // 节流：等待 30 毫秒（iOS 16+ 现代 API）。
            // 如果用户这 30ms 内又打字了，Task 会被 cancel，抛出 CancellationError 并退出
            do {
                try await Task.sleep(for: .milliseconds(30))
            } catch {
                return // 任务被取消，直接退出
            }
            
            // 再次校验任务状态
            guard !Task.isCancelled else { return }
            // 获取原生排版矩形 (全部在安全的 MainActor 下执行)
            let rawRects = self.getRawTextRects()
            guard !rawRects.isEmpty else { return }
            
            let currentRadius = self.textLayerRadius
            let fillColor = self.currentColor.cgColor
            
            // 数学计算（数据量极小，主线程运算耗时极短，彻底避免并发隔离崩溃）
            let optimizedRects = Self.optimizeRects(rawRects, radius: currentRadius)
            let cgPath = Self.buildPath(from: optimizedRects, radius: currentRadius)
            
            // 光速渲染，关闭隐式动画省去开销
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            
            self.textLayer.path = cgPath
            self.textLayer.fillColor = fillColor
            if self.textLayer.superlayer == nil {
                self.textView.layer.insertSublayer(self.textLayer, at: 0)
            }
            
            CATransaction.commit()
        }
    }
    
    @MainActor
    private func getRawTextRects() -> [CGRect] {
        let layoutManager = textView.layoutManager
        let textContainer = textView.textContainer
        
        // iOS 17 中安全的字形范围获取
        let glyphRange = layoutManager.glyphRange(for: textContainer)
        guard glyphRange.length > 0 else { return [] }
        
        var rects: [CGRect] = []
        let insetLeft = textView.textContainerInset.left
        let insetTop = textView.textContainerInset.top
        
        layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { _, usedRect, _, _, _ in
            // 过滤无用的幽灵矩形
            guard usedRect.width > 0 && usedRect.height > 0 else { return }
            
            rects.append(CGRect(x: usedRect.minX - 10 + insetLeft,
                                y: usedRect.minY - 8 + insetTop,
                                width: usedRect.width + 20,
                                height: usedRect.height + 16))
        }
        return rects
    }
    
    // 纯静态方法，断开与控制器的关联，满足 Swift 6 Sendable 严格要求
    private static func buildPath(from rects: [CGRect], radius: CGFloat) -> CGPath {
        let path = UIBezierPath()
        for (index, rect) in rects.enumerated() {
            if index == 0 {
                path.move(to: CGPoint(x: rect.minX, y: rect.minY + radius))
                path.addArc(withCenter: CGPoint(x: rect.minX + radius, y: rect.minY + radius), radius: radius, startAngle: .pi, endAngle: .pi * 1.5, clockwise: true)
                path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
                path.addArc(withCenter: CGPoint(x: rect.maxX - radius, y: rect.minY + radius), radius: radius, startAngle: .pi * 1.5, endAngle: .pi * 2, clockwise: true)
            } else {
                let preRect = rects[index - 1]
                if rect.maxX > preRect.maxX {
                    path.addLine(to: CGPoint(x: preRect.maxX, y: rect.minY - radius))
                    path.addArc(withCenter: CGPoint(x: preRect.maxX + radius, y: rect.minY - radius), radius: radius, startAngle: -.pi, endAngle: -.pi * 1.5, clockwise: false)
                    path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
                    path.addArc(withCenter: CGPoint(x: rect.maxX - radius, y: rect.minY + radius), radius: radius, startAngle: .pi * 1.5, endAngle: .pi * 2, clockwise: true)
                } else if rect.maxX < preRect.maxX {
                    path.addLine(to: CGPoint(x: preRect.maxX, y: preRect.maxY - radius))
                    path.addArc(withCenter: CGPoint(x: preRect.maxX - radius, y: preRect.maxY - radius), radius: radius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
                    path.addLine(to: CGPoint(x: rect.maxX + radius, y: preRect.maxY))
                    path.addArc(withCenter: CGPoint(x: rect.maxX + radius, y: preRect.maxY + radius), radius: radius, startAngle: -.pi / 2, endAngle: -.pi, clockwise: false)
                } else {
                    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + radius))
                }
            }
            
            if index == rects.count - 1 {
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
                path.addArc(withCenter: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius), radius: radius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
                path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
                path.addArc(withCenter: CGPoint(x: rect.minX + radius, y: rect.maxY - radius), radius: radius, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
                
                let firstRect = rects[0]
                path.addLine(to: CGPoint(x: firstRect.minX, y: firstRect.minY + radius))
                path.close()
            }
        }
        return path.cgPath
    }

    // 纯静态方法，断开与控制器的关联
    private static func optimizeRects(_ rects: [CGRect], radius: CGFloat) -> [CGRect] {
        guard rects.count > 1 else { return rects }
        var result = rects
        let threshold = radius * 2
        
        for i in 1..<result.count {
            let pre = result[i - 1]
            let curr = result[i]
            if curr.width > pre.width && (curr.width - pre.width) < threshold {
                result[i - 1].size.width = curr.width
            } else if curr.width < pre.width && (pre.width - curr.width) < threshold {
                result[i].size.width = pre.width
            }
        }
        
        for i in (1..<result.count).reversed() {
            let pre = result[i - 1]
            let curr = result[i]
            if curr.width > pre.width && (curr.width - pre.width) < threshold {
                result[i - 1].size.width = curr.width
            } else if curr.width < pre.width && (pre.width - curr.width) < threshold {
                result[i].size.width = pre.width
            }
        }
        
        return result
    }
}

extension PTEditInputViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let markedTextRange = textView.markedTextRange
        guard markedTextRange == nil || (markedTextRange?.isEmpty ?? true) else {
            return
        }
        
        let text = textView.text ?? ""
        if text.count > maxTextCount {
            let endIndex = text.index(text.startIndex, offsetBy: maxTextCount)
            textView.text = String(text[..<endIndex])
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == String.newline {
            doneBtnClick()
            return false
        }
        return true
    }
}

extension PTEditInputViewController: @MainActor NSLayoutManagerDelegate {
    func layoutManager(_ layoutManager: NSLayoutManager, didCompleteLayoutFor textContainer: NSTextContainer?, atEnd layoutFinishedFlag: Bool) {
        guard layoutFinishedFlag else {
            return
        }
        
        drawTextBackground()
    }
}
