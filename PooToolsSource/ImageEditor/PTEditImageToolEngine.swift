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

    /// 核心合成函数：将用户划过的马赛克路径合成到最终图片上
    @discardableResult
    public func generateNewMosaicImage(inputImage: UIImage? = nil, inputMosaicImage: UIImage? = nil) -> UIImage? {
        guard let context = context else { return nil }
        
        let originalImage = context.engineOriginalImage
        let editImage = context.engineCurrentEditImage
        
        // 【关键】：加入 autoreleasepool 保护内存，防止大图 OOM
        return autoreleasepool {
            let renderRect = CGRect(origin: .zero, size: originalImage.size)
            
            var midImage = UIGraphicsImageRenderer.pt.renderImage(size: originalImage.size) { format in
                format.scale = originalImage.scale
            } imageActions: { ctx in
                
                if inputImage != nil {
                    inputImage?.draw(in: renderRect)
                } else {
                    // 如果外部没有传入源图片，默认拿当前的编辑底图
                    editImage.draw(in: renderRect)
                }
                
                // 将收集到的所有马赛克路径绘制到上下文
                mosaicPaths.forEach { path in
                    ctx.move(to: path.startPoint)
                    path.linePoints.forEach { point in
                        ctx.addLine(to: point)
                    }
                    ctx.setLineWidth(path.path.lineWidth / path.ratio)
                    ctx.setLineCap(.round)
                    ctx.setLineJoin(.round)
                    ctx.setBlendMode(.clear)
                    ctx.strokePath()
                }
            }
            
            guard let midCgImage = midImage.cgImage else { return nil }
            midImage = UIImage(cgImage: midCgImage, scale: editImage.scale, orientation: .up)
            
            let temp = UIGraphicsImageRenderer.pt.renderImage(size: originalImage.size) { format in
                format.scale = originalImage.scale
            } imageActions: { _ in
                // 先画原图打底，防止边缘因为抗锯齿出现黑边
                originalImage.draw(in: renderRect)
                (inputMosaicImage ?? mosaicImage)?.draw(in: renderRect)
                midImage.draw(in: renderRect)
            }
            
            guard let cgi = temp.cgImage else { return nil }
            let finalImage = UIImage(cgImage: cgi, scale: editImage.scale, orientation: .up)
            
            if inputImage != nil {
                return finalImage
            }
            
            // 更新内部状态并清理 Mask 路径
            mosaicImageLayerMaskLayer?.path = nil
            
            // 将新生成的带有马赛克的图片更新回主控制器
            context.engineUpdateEditImage(finalImage)
            
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
    public func generateFilterThumbnails(completion: @escaping () -> Void) {
        guard let context = context, let thumbnailImage = context.engineThumbnailImage else { return }
        
        PTGCDManager.gcdGobal {
            let filters = PTImageEditorConfig.share.filters
            var thumbnails: [UIImage] = []
            
            filters.forEach { filter in
                PTHarBethFilter.share.texureSize = thumbnailImage.size
                thumbnails.append(filter.getCurrentFilterImage(image: thumbnailImage))
            }
            
            PTGCDManager.gcdMain {
                self.thumbnailFilterImages = thumbnails
                completion()
            }
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
