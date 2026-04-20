//
//  PTEditImageToolEngine.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 20/4/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
import Harbeth
import SwifterSwift
import CoreImage

public enum PTClipPanEdge {
    case none, top, bottom, left, right, topLeft, topRight, bottomLeft, bottomRight
}

/// 主控制器为引擎提供的上下文数据源 (解耦的关键)
public protocol PTEditImageEngineContext: AnyObject {
    var engineScrollView: UIScrollView { get }
    var engineOriginalImageSize: CGSize { get }
    var engineEditImageSize: CGSize { get }
    var engineEditRect: CGRect { get }
    var engineShouldSwapSize: Bool { get }
    var engineCurrentAngle: CGFloat { get }
    var engineEditorManager: PTMediaEditManager { get }
    var engineEraserCircleView: UIImageView { get }
    
    // 👇 新增：用于马赛克引擎获取原图和将处理好的图片更新回VC
    var engineOriginalImage: UIImage { get }
    var engineCurrentEditImage: UIImage { get }
    func engineUpdateEditImage(_ newImage: UIImage)
    
    // 👇 新增：贴纸引擎需要的专属支持
    /// 主控制器的 View (用于计算垃圾桶的相对坐标)
    var engineMainView: UIView { get }
    /// 主控制器本身 (用于 push 出文字输入控制器)
    var engineViewController: UIViewController { get }
    /// 垃圾桶背景视图
    var engineAshbinView: UIView { get }
    /// 垃圾桶图标视图
    var engineAshbinImgView: UIImageView { get }
    
    // 👇 新增：专门给 Adjust 引擎用的桥梁
    /// 获取不带 Adjust 参数，但包含当前滤镜和马赛克的参考底图
    func engineRequestAdjustReferenceImage() -> UIImage
    /// 当前 VC 里面选中的滤镜基础图 (用于 Adjust 叠加)
    var engineImageWithoutAdjust: UIImage { get }
    
    // 👇 新增：专门给 Filter 引擎用的桥梁
    /// 用于生成滤镜缩略图的基础小图
    var engineThumbnailImage: UIImage? { get }
    /// 当滤镜引擎处理完底图后，通知 VC 更新流水线
    func engineDidUpdateFilteredBaseImage(_ newBaseImage: UIImage)
}

// 所有交互式编辑工具（涂鸦、马赛克等）的通用协议
public protocol PTEditImageToolEngine: AnyObject {
    /// 关联的画布视图（引擎在这个视图上进行渲染）
    var canvasView: UIView { get }
    /// 工具被选中时触发
    func toolDidActivate()
    /// 工具被取消选中时触发
    func toolDidDeactivate()
    /// 处理拖拽手势
    func handlePanGesture(_ pan: UIPanGestureRecognizer)
    /// 撤销/重做操作时，通知引擎刷新图层
    func reloadRenderState()
}

public class PTDrawEngine: NSObject, PTEditImageToolEngine {
    
    // MARK: - 核心视图与状态
    
    public var canvasView: UIView { drawingImageView }
    
    public lazy var drawingImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = true
        return view
    }()
    
    /// 涂鸦路径集合
    public var drawPaths: [PTDrawPath] = []
    /// 橡皮擦删除池 (已应用 Set 提升至 O(1) 性能)
    public var deleteDrawPaths: Set<PTDrawPath> = []
    
    public var drawColor: UIColor = .systemRed
    public var defaultDrawPathWidth: CGFloat = 0
    public var isEraserMode: Bool = false
    
    // MARK: - 内部依赖
    
    private weak var context: PTEditImageEngineContext?
    private var impactFeedback: UIImpactFeedbackGenerator?
    static let maxDrawLineImageWidth: CGFloat = 600
    
    /// 手势交互状态改变回调 (传回 true 代表开始交互，VC 需隐藏工具栏；false 则显示)
    public var onInteractStateChanged: ((Bool) -> Void)?
    
    // MARK: - 生命周期
    
    public init(context: PTEditImageEngineContext) {
        self.context = context
        super.init()
        if PTImageEditorConfig.share.tools.contains(.draw) {
            impactFeedback = UIImpactFeedbackGenerator(style: .light)
        }
    }
    
    public func toolDidActivate() {
        // 工具激活时的逻辑
    }
    
    public func toolDidDeactivate() {
        // 离开涂鸦工具时，重置橡皮擦状态
        isEraserMode = false
    }
    
    public func reloadRenderState() {
        drawLine()
    }
    
    // MARK: - 手势路由
    
    public func handlePanGesture(_ pan: UIPanGestureRecognizer) {
        guard let context = context else { return }
        
        if isEraserMode {
            handleEraserGesture(pan, context: context)
        } else {
            handleDrawGesture(pan, context: context)
        }
    }
    
    // MARK: - 具体手势实现: 绘制
    
    private func handleDrawGesture(_ pan: UIPanGestureRecognizer, context: PTEditImageEngineContext) {
        let point = pan.location(in: drawingImageView)
        let scrollView = context.engineScrollView
        let originalImageSize = context.engineOriginalImageSize
        let editRect = context.engineEditRect
        
        if pan.state == .began {
            onInteractStateChanged?(true) // 通知 VC 隐藏工具栏
            
            let originalRatio = min(scrollView.frame.width / originalImageSize.width, scrollView.frame.height / originalImageSize.height)
            let ratio = min(scrollView.frame.width / editRect.width, scrollView.frame.height / editRect.height)
            let scale = ratio / originalRatio
            
            var size = drawingImageView.frame.size
            size.width /= scale
            size.height /= scale
            if context.engineShouldSwapSize {
                swap(&size.width, &size.height)
            }
            
            var toImageScale = Self.maxDrawLineImageWidth / size.width
            if context.engineEditImageSize.width / context.engineEditImageSize.height > 1 {
                toImageScale = Self.maxDrawLineImageWidth / size.height
            }
            
            let path = PTDrawPath(
                pathColor: drawColor,
                pathWidth: PTImageEditorConfig.share.drawLineWidth / scrollView.zoomScale,
                defaultLinePath: defaultDrawPathWidth,
                ratio: ratio / originalRatio / toImageScale,
                startPoint: point
            )
            drawPaths.append(path)
            
        } else if pan.state == .changed {
            let path = drawPaths.last
            path?.addLine(to: point)
            drawLine()
            
        } else if pan.state == .cancelled || pan.state == .ended {
            onInteractStateChanged?(false) // 通知 VC 恢复工具栏
            if let path = drawPaths.last {
                context.engineEditorManager.storeAction(.draw(path))
            }
        }
    }
    
    // MARK: - 具体手势实现: 橡皮擦
    
    private func handleEraserGesture(_ pan: UIPanGestureRecognizer, context: PTEditImageEngineContext) {
        let point = pan.location(in: drawingImageView)
        let scrollView = context.engineScrollView
        let originalImageSize = context.engineOriginalImageSize
        let editRect = context.engineEditRect
        let eraserCircleView = context.engineEraserCircleView
        
        let originalRatio = min(scrollView.frame.width / originalImageSize.width, scrollView.frame.height / originalImageSize.height)
        let ratio = min(scrollView.frame.width / editRect.width, scrollView.frame.height / editRect.height)
        let scale = ratio / originalRatio
        
        var size = drawingImageView.frame.size
        size.width /= scale
        size.height /= scale
        if context.engineShouldSwapSize {
            swap(&size.width, &size.height)
        }
        
        var toImageScale = Self.maxDrawLineImageWidth / size.width
        if context.engineEditImageSize.width / context.engineEditImageSize.height > 1 {
            toImageScale = Self.maxDrawLineImageWidth / size.height
        }
        
        let pointScale = ratio / originalRatio / toImageScale
        let drawPoint = CGPoint(x: point.x / pointScale, y: point.y / pointScale)
        
        if pan.state == .began {
            eraserCircleView.isHidden = false
            impactFeedback?.prepare()
        }
        
        if pan.state == .began || pan.state == .changed {
            var transform: CGAffineTransform = .identity
            let angle = ((Int(context.engineCurrentAngle) % 360) + 360) % 360
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
                    deleteDrawPaths.insert(path) // O(1) 插入
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
                context.engineEditorManager.storeAction(.eraser(Array(deleteDrawPaths)))
                drawPaths.removeAll { deleteDrawPaths.contains($0) }
                deleteDrawPaths.removeAll()
                drawLine()
            }
        }
    }
    
    // MARK: - 渲染引擎
    
    public func drawLine() {
        guard let context = context else { return }
        let scrollView = context.engineScrollView
        let originalImageSize = context.engineOriginalImageSize
        let editRect = context.engineEditRect
        
        let originalRatio = min(scrollView.frame.width / originalImageSize.width, scrollView.frame.height / originalImageSize.height)
        let ratio = min(scrollView.frame.width / editRect.width, scrollView.frame.height / editRect.height)
        let scale = ratio / originalRatio
        
        var size = drawingImageView.frame.size
        size.width /= scale
        size.height /= scale
        if context.engineShouldSwapSize {
            swap(&size.width, &size.height)
        }
        
        var toImageScale = Self.maxDrawLineImageWidth / size.width
        if context.engineEditImageSize.width / context.engineEditImageSize.height > 1 {
            toImageScale = Self.maxDrawLineImageWidth / size.height
        }
        size.width *= toImageScale
        size.height *= toImageScale
        
        drawingImageView.image = UIGraphicsImageRenderer.pt.renderImage(size: size) { renderContext in
            renderContext.setAllowsAntialiasing(true)
            renderContext.setShouldAntialias(true)
            for path in self.drawPaths {
                path.drawPath()
            }
        }
    }
}

public class PTMosaicEngine: NSObject, PTEditImageToolEngine {
    
    // MARK: - 核心视图与图层
    
    /// 马赛克的渲染容器
    public var canvasView: UIView { mosaicContainerView }
    
    private lazy var mosaicContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        return view
    }()
    
    public var mosaicPaths: [PTMosaicPath] = []
    
    private var mosaicImage: UIImage?
    private var mosaicImageLayer: CALayer?
    private var mosaicImageLayerMaskLayer: CAShapeLayer?
    
    // MARK: - 内部依赖
    
    private weak var context: PTEditImageEngineContext?
    
    // 🔥 新增：GPU 渲染上下文。复用同一个 Context 能极大提升性能
    private lazy var ciContext: CIContext = {
        // 强制使用 GPU (Metal) 渲染，拒绝 CPU 软解
        return CIContext(options: [.useSoftwareRenderer: false])
    }()
    
    /// 手势交互状态改变回调 (传回 true 代表开始交互，VC 需隐藏工具栏；false 则显示)
    public var onInteractStateChanged: ((Bool) -> Void)?
    
    // MARK: - 生命周期
    
    public init(context: PTEditImageEngineContext) {
        self.context = context
        super.init()
    }
    
    public func toolDidActivate() {
        // 激活时，准备好马赛克图层
        generateNewMosaicImageLayer()
    }
    
    public func toolDidDeactivate() {
        // 离开时，如果有未烘焙的图层，可以选择清理或保持
    }
    
    public func reloadRenderState() {
        // 撤销/重做时触发，重新生成马赛克图
        generateNewMosaicImage()
    }
    
    // MARK: - 手势路由
    
    public func handlePanGesture(_ pan: UIPanGestureRecognizer) {
        guard let context = context else { return }
        
        let point = pan.location(in: mosaicContainerView)
        
        if pan.state == .began {
            onInteractStateChanged?(true) // 通知 VC 隐藏工具栏
            
            var actualSize = context.engineEditRect.size
            if context.engineShouldSwapSize {
                swap(&actualSize.width, &actualSize.height)
            }
            let ratio = min(
                context.engineScrollView.frame.width / context.engineEditRect.width,
                context.engineScrollView.frame.height / context.engineEditRect.height
            )
            
            let pathW = PTImageEditorConfig.share.mosaicLineWidth / context.engineScrollView.zoomScale
            let path = PTMosaicPath(pathWidth: pathW, ratio: ratio, startPoint: point)
            
            mosaicImageLayerMaskLayer?.lineWidth = pathW
            mosaicImageLayerMaskLayer?.path = path.path.cgPath
            mosaicPaths.append(path)
            
        } else if pan.state == .changed {
            let path = mosaicPaths.last
            path?.addLine(to: point)
            mosaicImageLayerMaskLayer?.path = path?.path.cgPath
            
        } else if pan.state == .cancelled || pan.state == .ended {
            onInteractStateChanged?(false) // 通知 VC 恢复工具栏
            
            if let path = mosaicPaths.last {
                context.engineEditorManager.storeAction(.mosaic(path))
            }
            
            // 手指抬起，烘焙马赛克到图片
            generateNewMosaicImage()
        }
    }
    
    // MARK: - 渲染引擎 (包含修复过 OOM 内存尖峰的逻辑)
    
    /// 准备马赛克图层与遮罩
    public func generateNewMosaicImageLayer() {
        guard let context = context else { return }
        let currentEditImage = context.engineCurrentEditImage
        
        // 注: 这里调用了原图的 pt.mosaicImage() 扩展方法
        mosaicImage = currentEditImage.pt.mosaicImage()
        
        mosaicImageLayer?.removeFromSuperlayer()
        
        mosaicImageLayer = CALayer()
        mosaicImageLayer?.frame = mosaicContainerView.bounds
        mosaicImageLayer?.contents = mosaicImage?.cgImage
        
        mosaicImageLayerMaskLayer = CAShapeLayer()
        mosaicImageLayerMaskLayer?.strokeColor = UIColor.blue.cgColor
        mosaicImageLayerMaskLayer?.fillColor = nil
        mosaicImageLayerMaskLayer?.lineCap = .round
        mosaicImageLayerMaskLayer?.lineJoin = .round
        mosaicImageLayerMaskLayer?.frame = mosaicContainerView.bounds
        
        mosaicContainerView.layer.addSublayer(mosaicImageLayer!)
        mosaicImageLayer?.mask = mosaicImageLayerMaskLayer
    }
    
    /// 极速生成黑白遮罩 (Mask)：黑色代表原图，白色代表马赛克区域
    private func generateMaskImage(size: CGSize) -> UIImage? {
        // 对于遮罩，单通道灰度图即可，不需要占用巨大内存的 RGB 画布
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            // 背景填黑
            ctx.cgContext.setFillColor(UIColor.black.cgColor)
            ctx.cgContext.fill(CGRect(origin: .zero, size: size))
            
            // 笔刷填白
            ctx.cgContext.setStrokeColor(UIColor.white.cgColor)
            ctx.cgContext.setLineCap(.round)
            ctx.cgContext.setLineJoin(.round)
            
            // 快速绘制路径
            for path in mosaicPaths {
                ctx.cgContext.beginPath()
                ctx.cgContext.move(to: path.startPoint)
                for point in path.linePoints {
                    ctx.cgContext.addLine(to: point)
                }
                ctx.cgContext.setLineWidth(path.path.lineWidth / path.ratio)
                ctx.cgContext.strokePath()
            }
        }
    }
    
    /// 核心合成函数：将用户划过的马赛克路径合成到最终图片上
    @discardableResult
    public func generateNewMosaicImage(inputImage: UIImage? = nil, inputMosaicImage: UIImage? = nil) -> UIImage? {
        guard let context = context else { return nil }
        
        let originalImage = inputImage ?? context.engineCurrentEditImage
        let bgMosaicImage = inputMosaicImage ?? self.mosaicImage
        
        guard let bgMosaicImage = bgMosaicImage else { return nil }
        
        return autoreleasepool {
            // 1. 将 UIImage 转为 GPU 友好的 CIImage (几乎不消耗时间，只是创建指针)
            guard let backgroundCI = CIImage(image: originalImage),
                  let foregroundCI = CIImage(image: bgMosaicImage),
                  let maskUIImage = generateMaskImage(size: originalImage.size),
                  let maskCI = CIImage(image: maskUIImage) else {
                return nil
            }
            
            // 2. 调用硬件级混合滤镜：CIBlendWithMask
            guard let blendFilter = CIFilter(name: "CIBlendWithMask") else { return nil }
            blendFilter.setValue(foregroundCI, forKey: kCIInputImageKey) // 前景：全屏马赛克
            blendFilter.setValue(backgroundCI, forKey: kCIInputBackgroundImageKey) // 背景：清晰原图
            blendFilter.setValue(maskCI, forKey: kCIInputMaskImageKey) // 遮罩：刚才画的黑白路径
            
            // 3. 让 GPU 渲染出结果
            guard let outputCI = blendFilter.outputImage,
                  let cgImage = ciContext.createCGImage(outputCI, from: outputCI.extent) else {
                return nil
            }
            
            // 4. 转回 UIImage 并更新到屏幕
            let finalImage = UIImage(cgImage: cgImage, scale: originalImage.scale, orientation: originalImage.imageOrientation)
            
            if inputImage == nil {
                mosaicImageLayerMaskLayer?.path = nil
                context.engineUpdateEditImage(finalImage)
            }
            
            return finalImage
        }
    }
}

public class PTStickerEngine: NSObject, PTEditImageToolEngine {
    
    // MARK: - 核心视图与状态
    
    public var canvasView: UIView { stickersContainer }
    
    private lazy var stickersContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.clipsToBounds = false // 允许贴纸部分拖出边界
        return view
    }()
    
    private weak var context: PTEditImageEngineContext?
    private var preStickerState: PTBaseStickertState?
    
    /// 交互状态回调 (用于隐藏/显示主工具栏)
    public var onInteractStateChanged: ((Bool) -> Void)?
    
    // MARK: - 生命周期
    
    public init(context: PTEditImageEngineContext) {
        self.context = context
        super.init()
    }
    
    public func toolDidActivate() {
        // 贴纸工具其实是一个“触发器”，激活时通常是为了弹出文字输入框或图片选择器
        // 引擎可以保持挂起，这里什么都不用做，直接由 VC 调用 createTextSticker()
    }
    
    public func toolDidDeactivate() {
        // 工具失活时，取消所有贴纸的激活状态(隐藏白边框)
        stickersContainer.subviews.forEach { view in
            (view as? PTStickerViewAdditional)?.resetState()
        }
    }
    
    public func handlePanGesture(_ pan: UIPanGestureRecognizer) {
        // 贴纸自带手势，不需要通过主控制器派发，留空即可
    }
    
    public func reloadRenderState() {
        // 预留给未来整体刷新贴纸层的接口
    }
    
    // MARK: - 贴纸增删改查
    
    public func createTextSticker(text: String? = nil, textColor: UIColor? = nil, font: UIFont? = nil, style: PTInputTextStyle = .normal) {
        showInputTextVC(text, textColor: textColor, font: font, style: style) { [weak self] newText, newColor, newFont, image, newStyle in
            guard let self = self, !newText.isEmpty, let image = image else { return }
            self.addTextStickersView(newText, textColor: newColor, font: newFont, image: image, style: newStyle)
        }
    }
    
    private func addTextStickersView(_ text: String, textColor: UIColor, font: UIFont, image: UIImage, style: PTInputTextStyle) {
        guard let context = context else { return }
        
        let scale = context.engineScrollView.zoomScale
        let size = PTTextStickerView.calculateSize(image: image)
        let originFrame = getStickerOriginFrame(size)
        
        let textSticker = PTTextStickerView(
            text: text, textColor: textColor, font: font, style: style, image: image,
            originScale: 1 / scale, originAngle: -context.engineCurrentAngle, originFrame: originFrame
        )
        
        addSticker(textSticker)
        context.engineEditorManager.storeAction(.sticker(oldState: nil, newState: textSticker.state))
    }
    
    private func addSticker(_ sticker: PTBaseStickerView) {
        guard let context = context else { return }
        stickersContainer.addSubview(sticker)
        sticker.frame = sticker.originFrame
        
        sticker.delegate = self
        // 解决手势冲突
        context.engineScrollView.pinchGestureRecognizer?.require(toFail: sticker.pinchGes)
        context.engineScrollView.panGestureRecognizer.require(toFail: sticker.panGes)
    }
    
    private func getStickerOriginFrame(_ size: CGSize) -> CGRect {
        guard let context = context else { return .zero }
        let scale = context.engineScrollView.zoomScale
        let scrollView = context.engineScrollView
        
        // 计算当前屏幕在图片上的居中显示区域
        let x = (scrollView.contentOffset.x - stickersContainer.frame.minX) / scale
        let y = (scrollView.contentOffset.y - stickersContainer.frame.minY) / scale
        let w = context.engineMainView.frame.width / scale
        let h = context.engineMainView.frame.height / scale
        
        // 转换坐标系并居中
        let r = context.engineMainView.convert(CGRect(x: x, y: y, width: w, height: h), to: stickersContainer)
        return CGRect(x: r.minX + (r.width - size.width) / 2, y: r.minY + (r.height - size.height) / 2, width: size.width, height: size.height)
    }
    
    // MARK: - Undo & Redo 引擎接口
    
    public func undoOrRedoSticker(oldState: PTBaseStickertState?, newState: PTBaseStickertState?, isUndo: Bool) {
        if isUndo {
            if let oldState = oldState {
                removeSticker(id: newState?.id ?? oldState.id)
                if let sticker = PTBaseStickerView.initWithState(oldState) { addSticker(sticker) }
            } else {
                removeSticker(id: newState?.id)
            }
        } else {
            if let newState = newState {
                removeSticker(id: oldState?.id ?? newState.id)
                if let sticker = PTBaseStickerView.initWithState(newState) { addSticker(sticker) }
            } else {
                removeSticker(id: oldState?.id)
            }
        }
    }
    
    private func removeSticker(id: String?) {
        guard let id = id else { return }
        for sticker in stickersContainer.subviews.reversed() {
            guard let stickerView = sticker as? PTBaseStickerView, stickerView.id == id else { continue }
            stickerView.moveToAshbin()
            break
        }
    }
    
    // MARK: - 文字输入控制器调配
    
    private func showInputTextVC(_ text: String? = nil, textColor: UIColor? = nil, font: UIFont? = nil, style: PTInputTextStyle = .normal, completion: @escaping (String, UIColor, UIFont, UIImage?, PTInputTextStyle) -> Void) {
        guard let context = context else { return }
        
        let scrollView = context.engineScrollView
        var r = scrollView.convert(context.engineMainView.frame, to: stickersContainer)
        r.origin.x += scrollView.contentOffset.x / scrollView.zoomScale
        r.origin.y += scrollView.contentOffset.y / scrollView.zoomScale
        
        let scale = context.engineOriginalImageSize.width / stickersContainer.frame.width
        r.origin.x *= scale
        r.origin.y *= scale
        r.size.width *= scale
        r.size.height *= scale
        
        // 获取高斯模糊的背景底图
        let bgImage = context.engineCurrentEditImage.pt.clipImage(angle: 0, editRect: r, isCircle: false)
        
        let vc = PTEditInputViewController(image: bgImage, text: text, textColor: textColor, font: font, style: style)
        vc.endInput = { text, textColor, font, image, style in
            completion(text, textColor, font, image, style)
        }
        
        context.engineViewController.navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - PTStickerViewDelegate (核心交互与垃圾桶动画)
extension PTStickerEngine: PTStickerViewDelegate {
    
    public func stickerBeginOperation(_ sticker: PTBaseStickerView) {
        guard let context = context else { return }
        preStickerState = sticker.state
        
        onInteractStateChanged?(true) // 通知 VC 隐藏底部栏
        
        let ashbinView = context.engineAshbinView
        ashbinView.layer.removeAllAnimations()
        ashbinView.isHidden = false
        
        var frame = ashbinView.frame
        let diff = context.engineMainView.frame.height - frame.minY
        frame.origin.y += diff
        ashbinView.frame = frame
        frame.origin.y -= diff
        
        UIView.animate(withDuration: 0.25) {
            ashbinView.frame = frame
        }
        
        stickersContainer.subviews.forEach { view in
            if view !== sticker {
                (view as? PTStickerViewAdditional)?.resetState()
                (view as? PTStickerViewAdditional)?.gesIsEnabled = false
            }
        }
    }
    
    public func stickerOnOperation(_ sticker: PTBaseStickerView, panGes: UIPanGestureRecognizer) {
        guard let context = context else { return }
        let point = panGes.location(in: context.engineMainView)
        let ashbinView = context.engineAshbinView
        let ashbinImgView = context.engineAshbinImgView
        
        if ashbinView.frame.contains(point) {
            ashbinView.backgroundColor = .gray
            ashbinImgView.isHighlighted = true
            if sticker.alpha == 1 {
                sticker.layer.removeAllAnimations()
                UIView.animate(withDuration: 0.25) { sticker.alpha = 0.5 }
            }
        } else {
            ashbinView.backgroundColor = .systemRed
            ashbinImgView.isHighlighted = false
            if sticker.alpha != 1 {
                sticker.layer.removeAllAnimations()
                UIView.animate(withDuration: 0.25) { sticker.alpha = 1 }
            }
        }
    }
    
    public func stickerEndOperation(_ sticker: PTBaseStickerView, panGes: UIPanGestureRecognizer) {
        guard let context = context else { return }
        
        onInteractStateChanged?(false) // 通知 VC 恢复底部栏
        
        let ashbinView = context.engineAshbinView
        ashbinView.layer.removeAllAnimations()
        ashbinView.isHidden = true
        
        var endState: PTBaseStickertState? = sticker.state
        let point = panGes.location(in: context.engineMainView)
        
        if ashbinView.frame.contains(point) {
            sticker.moveToAshbin()
            endState = nil
        }
        
        context.engineEditorManager.storeAction(.sticker(oldState: preStickerState, newState: endState))
        preStickerState = nil
        
        stickersContainer.subviews.forEach { view in
            (view as? PTStickerViewAdditional)?.gesIsEnabled = true
        }
    }
    
    public func stickerDidTap(_ sticker: PTBaseStickerView) {
        stickersContainer.subviews.forEach { view in
            if view !== sticker {
                (view as? PTStickerViewAdditional)?.resetState()
            }
        }
    }
    
    public func sticker(_ textSticker: PTTextStickerView, editText text: String) {
        showInputTextVC(text, textColor: textSticker.textColor, font: textSticker.font, style: textSticker.style) { text, textColor, font, image, style in
            guard let image = image, !text.isEmpty else {
                textSticker.moveToAshbin()
                return
            }
            
            textSticker.startTimer()
            guard textSticker.text != text || textSticker.textColor != textColor || textSticker.style != style else { return }
            
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

public class PTAdjustEngine: NSObject, PTEditImageToolEngine {
    
    // MARK: - 核心视图与状态
    
    /// Adjust 工具没有直接覆盖在图片上的 Canvas，它的 UI 是调节滑块
    public var canvasView: UIView { UIView() } // 占位空视图即可
    
    /// 核心调节滑块
    public lazy var adjustSlider: PTAdjustSliderView = {
        let view = PTAdjustSliderView()
        view.isHidden = true
        return view
    }()
    
    public var currentAdjustStatus = PTAdjustStatus()
    public var preAdjustStatus = PTAdjustStatus()
    public var selectedAdjustTool: PTHarBethFilter.FiltersTool?
    
    // 用于实时渲染的参考底图（由 VC 提供）
    private var editImageAdjustRef: UIImage?
    private var hasAdjustedImage = false
    
    private weak var context: PTEditImageEngineContext?
    
    // MARK: - 生命周期
    
    public init(context: PTEditImageEngineContext) {
        self.context = context
        super.init()
        setupSliderCallbacks()
    }
    
    private func setupSliderCallbacks() {
        adjustSlider.beginAdjust = { [weak self] in
            guard let self = self else { return }
            self.preAdjustStatus = self.currentAdjustStatus
        }
        
        adjustSlider.valueChanged = { [weak self] value in
            self?.adjustValueChanged(value)
        }
        
        adjustSlider.endAdjust = { [weak self] in
            guard let self = self, let context = self.context else { return }
            context.engineEditorManager.storeAction(
                .adjust(oldStatus: self.preAdjustStatus, newStatus: self.currentAdjustStatus)
            )
            self.hasAdjustedImage = true
        }
    }
    
    public func toolDidActivate() {
        adjustSlider.isHidden = false
        // 🔥 核心：激活时，向 VC 索要最新的参考底图！
        editImageAdjustRef = context?.engineRequestAdjustReferenceImage()
    }
    
    public func toolDidDeactivate() {
        adjustSlider.isHidden = true
    }
    
    public func handlePanGesture(_ pan: UIPanGestureRecognizer) {
        // Adjust 工具的手势由 slider 自己内部消化，这里不需要处理图片上的 Pan 手势
    }
    
    public func reloadRenderState() {
        // 触发 Undo/Redo 时，重新渲染图片
        adjustStatusChanged()
    }
    
    // MARK: - 调节业务逻辑
    
    public func changeAdjustTool(_ tool: PTHarBethFilter.FiltersTool) {
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
    
    private func adjustValueChanged(_ value: Float) {
        guard let selectedAdjustTool = selectedAdjustTool else { return }
        
        switch selectedAdjustTool {
        case .brightness:
            if currentAdjustStatus.brightness == value { return }
            currentAdjustStatus.brightness = value
        case .contrast:
            if currentAdjustStatus.contrast == value { return }
            currentAdjustStatus.contrast = value
        case .saturation:
            if currentAdjustStatus.saturation == value { return }
            currentAdjustStatus.saturation = value
        default:
            break
        }
        
        adjustStatusChanged()
    }
    
    private func adjustStatusChanged() {
        guard let context = context else { return }
        
        // 使用缓存的参考底图进行渲染，如果没有则降级使用未 adjustment 的图
        let baseImage = editImageAdjustRef ?? context.engineImageWithoutAdjust
        
        if let image = adjustFilterValueSet(filterImage: baseImage) {
            context.engineUpdateEditImage(image) // 把渲染好的结果还给 VC
        }
    }
    
    // MARK: - Harbeth 滤镜渲染核心
    
    public func adjustFilterValueSet(filterImage: UIImage?) -> UIImage? {
        guard !currentAdjustStatus.allValueIsZero else { return filterImage }
        
        var filters = [C7FilterProtocol]()
        let filterManager = PTHarBethFilter.share
        filterManager.tools = PTImageEditorConfig.share.adjust_tools
        
        filterManager.getFilterResults().enumerated().forEach { index, value in
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
}

public class PTFilterEngine: NSObject, PTEditImageToolEngine {
    
    // MARK: - 核心状态
    
    public var canvasView: UIView { UIView() } // 滤镜只有底部菜单，没有覆盖图层
    
    public var currentFilter: PTHarBethFilter = .cigaussian
    public var thumbnailFilterImages: [UIImage] = []
    
    private lazy var filterCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        // 【关键配置】：限制最多在内存中保留 6 张滤镜大图。
        // 假设一张千万像素的图解压后占 30MB，6张最多 180MB，完全在安全线内。
        // 当存入第 7 张时，系统会自动把最旧的一张剔除。
        cache.countLimit = 6
        return cache
    }()

    private weak var context: PTEditImageEngineContext?
    
    // MARK: - 生命周期
    
    public init(context: PTEditImageEngineContext) {
        self.context = context
        super.init()
    }
    
    public func toolDidActivate() {
        // 唤醒时不需要特殊操作，由 VC 去展示 CollectionView
    }
    
    public func toolDidDeactivate() { }
    public func handlePanGesture(_ pan: UIPanGestureRecognizer) { }
    
    public func reloadRenderState() {
        changeFilter(currentFilter)
    }
    
    // MARK: - 滤镜业务逻辑
    
    /// 异步生成底部菜单所需的滤镜缩略图
    public func generateFilterThumbnails() async {
        guard let context = context, let thumbnailImage = context.engineThumbnailImage else { return }
        
        let filters = PTImageEditorConfig.share.filters
        
        // 1. Task.detached 会将繁重的图片处理任务踢到后台子线程，绝不阻塞主线程 UI
        let thumbnails = await Task.detached(priority: .userInitiated) {
            var results: [UIImage] = []
            
            for filter in filters {
                PTHarBethFilter.share.texureSize = thumbnailImage.size
                results.append(filter.getCurrentFilterImage(image: thumbnailImage))
            }
            return results
        }.value // .value 会等待后台任务执行完毕并返回结果
        
        // 2. 切回主线程 (MainActor) 更新属性，确保 UI 安全
        await MainActor.run {
            self.thumbnailFilterImages = thumbnails
        }
    }
    
    /// 切换滤镜
    public func changeFilter(_ filter: PTHarBethFilter) {
        guard let context = context else { return }
        currentFilter = filter
        
        let resultImage: UIImage
        let cacheKey = filter.name.nsString // 转换为 NSString 作为 Key
        // 1. 优先从安全的 NSCache 中读取
        if let cachedImage = filterCache.object(forKey: cacheKey) {
            resultImage = cachedImage
        } else {
            // 2. 缓存没命中，调用底层算法重新生成
            resultImage = filter.getCurrentFilterImage(image: context.engineOriginalImage)
            // 3. 存入 NSCache
            filterCache.setObject(resultImage, forKey: cacheKey)
        }
        
        // 把应用了滤镜的干净底图，交回给大堂经理 (VC) 去跑流水线！
        context.engineDidUpdateFilteredBaseImage(resultImage)
    }
}

/// 裁剪引擎向 VC 索要环境变量的协议
public protocol PTClipEngineContext: AnyObject {
    var engineMaxClipFrame: CGRect { get }
    var engineMinClipSize: CGSize { get }
}

public class PTClipEngine: NSObject {
    
    // MARK: - 引擎内部状态
    
    public var clipBoxFrame: CGRect = .zero
    public var selectedRatio: PTImageClipRatio
    
    private var panEdge: PTClipPanEdge = .none
    private var beginPanPoint: CGPoint = .zero
    private var clipOriginFrame: CGRect = .zero
    
    private weak var context: PTClipEngineContext?
    
    // MARK: - 回调接口 (通知 VC 更新 UI)
    
    /// 当拖拽开始或结束时，通知 VC 隐藏/显示底部工具栏
    public var onInteractStateChanged: ((Bool) -> Void)?
    
    /// 当计算出新的裁剪框 Frame 时，通知 VC 刷新遮罩和滚动视图
    public var onClipBoxFrameChanged: ((CGRect) -> Void)?
    
    // MARK: - 生命周期
    
    public init(context: PTClipEngineContext, initialRatio: PTImageClipRatio) {
        self.context = context
        self.selectedRatio = initialRatio
        super.init()
    }
    
    // MARK: - 核心拖拽手势处理
    
    public func handlePanGesture(_ pan: UIPanGestureRecognizer, in view: UIView) {
        let point = pan.location(in: view)
        
        if pan.state == .began {
            onInteractStateChanged?(true)
            beginPanPoint = point
            clipOriginFrame = clipBoxFrame
            panEdge = calculatePanEdge(at: point)
        } else if pan.state == .changed {
            guard panEdge != .none else { return }
            updateClipBoxFrame(point: point)
        } else if pan.state == .cancelled || pan.state == .ended {
            panEdge = .none
            onInteractStateChanged?(false)
        }
    }
    
    // MARK: - 纯数学计算：边缘判定
    
    private func calculatePanEdge(at point: CGPoint) -> PTClipPanEdge {
        let frame = clipBoxFrame.insetBy(dx: -30, dy: -30)
        let cornerSize = CGSize(width: 60, height: 60)
        
        // 四角判定
        if CGRect(origin: frame.origin, size: cornerSize).contains(point) { return .topLeft }
        if CGRect(origin: CGPoint(x: frame.maxX - cornerSize.width, y: frame.minY), size: cornerSize).contains(point) { return .topRight }
        if CGRect(origin: CGPoint(x: frame.minX, y: frame.maxY - cornerSize.height), size: cornerSize).contains(point) { return .bottomLeft }
        if CGRect(origin: CGPoint(x: frame.maxX - cornerSize.width, y: frame.maxY - cornerSize.height), size: cornerSize).contains(point) { return .bottomRight }
        
        // 四边判定
        if CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: cornerSize.height)).contains(point) { return .top }
        if CGRect(origin: CGPoint(x: frame.minX, y: frame.maxY - cornerSize.height), size: CGSize(width: frame.width, height: cornerSize.height)).contains(point) { return .bottom }
        if CGRect(origin: frame.origin, size: CGSize(width: cornerSize.width, height: frame.height)).contains(point) { return .left }
        if CGRect(origin: CGPoint(x: frame.maxX - cornerSize.width, y: frame.minY), size: CGSize(width: cornerSize.width, height: frame.height)).contains(point) { return .right }
        
        return .none
    }
    
    // MARK: - 纯数学计算：边框限制与比例缩放
    
    private func updateClipBoxFrame(point: CGPoint) {
        guard let context = context else { return }
        
        var frame = clipBoxFrame
        let originFrame = clipOriginFrame
        
        let maxClipFrame = context.engineMaxClipFrame
        let minClipSize = context.engineMinClipSize
        
        var newPoint = point
        newPoint.x = max(maxClipFrame.minX, newPoint.x)
        newPoint.y = max(maxClipFrame.minY, newPoint.y)
        
        let diffX = ceil(newPoint.x - beginPanPoint.x)
        let diffY = ceil(newPoint.y - beginPanPoint.y)
        let ratio = selectedRatio.whRatio
        
        // --- 下面就是你原代码里那 100 行硬核数学运算，现在全被隔离在这里了 ---
        switch panEdge {
        case .left:
            frame.origin.x = originFrame.minX + diffX
            frame.size.width = originFrame.width - diffX
            if ratio != 0 { frame.size.height = originFrame.height - diffX / ratio }
        case .right:
            frame.size.width = originFrame.width + diffX
            if ratio != 0 { frame.size.height = originFrame.height + diffX / ratio }
        case .top:
            frame.origin.y = originFrame.minY + diffY
            frame.size.height = originFrame.height - diffY
            if ratio != 0 { frame.size.width = originFrame.width - diffY * ratio }
        case .bottom:
            frame.size.height = originFrame.height + diffY
            if ratio != 0 { frame.size.width = originFrame.width + diffY * ratio }
        case .topLeft:
            if ratio != 0 {
                frame.origin.x = originFrame.minX + diffX
                frame.size.width = originFrame.width - diffX
                frame.origin.y = originFrame.minY + diffX / ratio
                frame.size.height = originFrame.height - diffX / ratio
            } else {
                frame.origin.x = originFrame.minX + diffX
                frame.size.width = originFrame.width - diffX
                frame.origin.y = originFrame.minY + diffY
                frame.size.height = originFrame.height - diffY
            }
        case .topRight:
            if ratio != 0 {
                frame.size.width = originFrame.width + diffX
                frame.origin.y = originFrame.minY - diffX / ratio
                frame.size.height = originFrame.height + diffX / ratio
            } else {
                frame.size.width = originFrame.width + diffX
                frame.origin.y = originFrame.minY + diffY
                frame.size.height = originFrame.height - diffY
            }
        case .bottomLeft:
            if ratio != 0 {
                frame.origin.x = originFrame.minX + diffX
                frame.size.width = originFrame.width - diffX
                frame.size.height = originFrame.height - diffX / ratio
            } else {
                frame.origin.x = originFrame.minX + diffX
                frame.size.width = originFrame.width - diffX
                frame.size.height = originFrame.height + diffY
            }
        case .bottomRight:
            if ratio != 0 {
                frame.size.width = originFrame.width + diffX
                frame.size.height = originFrame.height + diffX / ratio
            } else {
                frame.size.width = originFrame.width + diffX
                frame.size.height = originFrame.height + diffY
            }
        default: break
        }
        
        let minSize: CGSize
        let maxSize: CGSize
        let actualMaxClipFrame: CGRect
        
        if ratio != 0 {
            if ratio >= 1 {
                minSize = CGSize(width: minClipSize.height * ratio, height: minClipSize.height)
            } else {
                minSize = CGSize(width: minClipSize.width, height: minClipSize.width / ratio)
            }
            if ratio > maxClipFrame.width / maxClipFrame.height {
                maxSize = CGSize(width: maxClipFrame.width, height: maxClipFrame.width / ratio)
            } else {
                maxSize = CGSize(width: maxClipFrame.height * ratio, height: maxClipFrame.height)
            }
            actualMaxClipFrame = CGRect(origin: CGPoint(x: maxClipFrame.minX + (maxClipFrame.width - maxSize.width) / 2, y: maxClipFrame.minY + (maxClipFrame.height - maxSize.height) / 2), size: maxSize)
        } else {
            minSize = minClipSize
            maxSize = maxClipFrame.size
            actualMaxClipFrame = maxClipFrame
        }
        
        frame.size.width = min(maxSize.width, max(minSize.width, frame.size.width))
        frame.size.height = min(maxSize.height, max(minSize.height, frame.size.height))
        
        frame.origin.x = min(actualMaxClipFrame.maxX - minSize.width, max(frame.origin.x, actualMaxClipFrame.minX))
        frame.origin.y = min(actualMaxClipFrame.maxY - minSize.height, max(frame.origin.y, actualMaxClipFrame.minY))
        
        if panEdge == .topLeft || panEdge == .bottomLeft || panEdge == .left, frame.size.width <= minSize.width + CGFloat.ulpOfOne {
            frame.origin.x = originFrame.maxX - minSize.width
        }
        if panEdge == .topLeft || panEdge == .topRight || panEdge == .top, frame.size.height <= minSize.height + CGFloat.ulpOfOne {
            frame.origin.y = originFrame.maxY - minSize.height
        }
        
        // 计算完毕，更新内部状态并回调给 VC 进行 UI 刷新
//        clipBoxFrame = frame
        onClipBoxFrameChanged?(frame)
    }
}
