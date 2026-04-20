//
//  PTEditImageToolEngine.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 20/4/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit

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
    public var drawLineWidth: CGFloat = 6
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
                pathWidth: drawLineWidth / scrollView.zoomScale,
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
    public var mosaicLineWidth: CGFloat = 25
    
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
            
            let pathW = mosaicLineWidth / context.engineScrollView.zoomScale
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
