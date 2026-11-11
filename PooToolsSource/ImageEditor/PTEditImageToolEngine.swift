//
//  PTEditImageToolEngine.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 20/4/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
import Harbeth
import CoreImage
import AVFoundation
import Vision
#if canImport(PToolsCore)
import PToolsCore
#endif

#if SWIFT_PACKAGE
// English: SwiftPM needs direct imports for Core and the shared Harbeth adapter.
// Español: SwiftPM necesita importaciones directas para Core y el adaptador compartido de Harbeth.
// 中文：SwiftPM 需要显式导入 Core 和共享的 Harbeth 适配模块。
import ptools
import PooToolsHarbethKit
#endif

/// 统一下发的画布计算参数
public struct PTCanvasMetrics {
    public let ratio: CGFloat
    public let originalRatio: CGFloat
    public let toImageScale: CGFloat
    public let renderSize: CGSize
}

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

public extension PTEditImageEngineContext {
    
    /// 统一计算：获取画布当前的缩放率、比例和渲染尺寸
    @MainActor func calculateCanvasMetrics(currentViewSize: CGSize, maxImageWidth: CGFloat = 600) -> PTCanvasMetrics {
        guard currentViewSize.width > 0,
              currentViewSize.height > 0,
              currentViewSize.width.isFinite,
              currentViewSize.height.isFinite,
              maxImageWidth > 0,
              maxImageWidth.isFinite,
              engineOriginalImageSize.width > 0,
              engineOriginalImageSize.height > 0,
              engineOriginalImageSize.width.isFinite,
              engineOriginalImageSize.height.isFinite,
              engineEditRect.width > 0,
              engineEditRect.height > 0,
              engineEditRect.width.isFinite,
              engineEditRect.height.isFinite,
              engineEditImageSize.width > 0,
              engineEditImageSize.height > 0,
              engineEditImageSize.width.isFinite,
              engineEditImageSize.height.isFinite else {
            return PTCanvasMetrics(ratio: 1,
                                   originalRatio: 1,
                                   toImageScale: 1,
                                   renderSize: currentViewSize)
        }

        // 利用协议自带的属性进行运算
        let originalRatio = min(engineScrollView.frame.width / engineOriginalImageSize.width, engineScrollView.frame.height / engineOriginalImageSize.height)
        let ratio = min(engineScrollView.frame.width / engineEditRect.width, engineScrollView.frame.height / engineEditRect.height)
        let scale = ratio / originalRatio

        // English: Reject invalid geometry before it reaches a renderer.
        // Español: Rechazamos una geometría inválida antes de enviarla al renderizador.
        // 中文：在进入渲染器前拒绝无效的几何计算结果。
        guard originalRatio.isFinite, originalRatio > 0,
              ratio.isFinite, ratio > 0,
              scale.isFinite, scale > 0 else {
            return PTCanvasMetrics(ratio: 1,
                                   originalRatio: 1,
                                   toImageScale: 1,
                                   renderSize: currentViewSize)
        }
        
        var size = currentViewSize
        size.width /= scale
        size.height /= scale
        
        if engineShouldSwapSize {
            swap(&size.width, &size.height)
        }
        
        var toImageScale = maxImageWidth / size.width
        if engineEditImageSize.width / engineEditImageSize.height > 1 {
            toImageScale = maxImageWidth / size.height
        }

        guard size.width.isFinite, size.height.isFinite,
              size.width > 0, size.height > 0,
              toImageScale.isFinite, toImageScale > 0 else {
            return PTCanvasMetrics(ratio: 1,
                                   originalRatio: 1,
                                   toImageScale: 1,
                                   renderSize: currentViewSize)
        }
        
        return PTCanvasMetrics(
            ratio: ratio,
            originalRatio: originalRatio,
            toImageScale: toImageScale,
            renderSize: size
        )
    }
    
    /// 统一计算：获取橡皮擦 UI 的偏移矩阵
    func calculateEraserTransform(viewTransform: CGAffineTransform, viewSize: CGSize) -> CGAffineTransform {
        var transform: CGAffineTransform = .identity
        let angle = ((Int(engineCurrentAngle) % 360) + 360) % 360
        
        if angle == 90 {
            transform = transform.translatedBy(x: 0, y: -viewSize.width)
        } else if angle == 180 {
            transform = transform.translatedBy(x: -viewSize.width, y: -viewSize.height)
        } else if angle == 270 {
            transform = transform.translatedBy(x: -viewSize.height, y: 0)
        }
        
        return transform.concatenating(viewTransform)
    }
}

extension UITextView {
    @MainActor
    public func getRawTextRects() -> [CGRect] {
        let layoutManager = self.layoutManager
        let textContainer = self.textContainer
        
        // iOS 17 中安全的字形范围获取
        let glyphRange = layoutManager.glyphRange(for: textContainer)
        guard glyphRange.length > 0 else { return [] }
        
        var rects: [CGRect] = []
        let insetLeft = self.textContainerInset.left
        let insetTop = self.textContainerInset.top
        
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
}

/// 专门用于离屏生成文字贴纸图片的工具类
public struct PTTextStickerRenderer {
    
    /// 根据文字、字体、颜色和样式，离屏生成 UIImage
    @MainActor
    public static func generateImage(text: String,
                                     font: UIFont,
                                     textColor: UIColor,
                                     style: PTInputTextStyle,
                                     maxWidth: CGFloat) -> UIImage? {
        let safeWidth = max(1, maxWidth)
        let textView = UITextView(frame: CGRect(x: 0, y: 0, width: safeWidth, height: 1))
        
        // 基础配置与输入页面保持一致。
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false

        var traits = font.fontDescriptor.symbolicTraits
        if style.isBold {
            traits.insert(.traitBold)
        } else {
            traits.remove(.traitBold)
        }
        if style.isItalic {
            traits.insert(.traitItalic)
        } else {
            traits.remove(.traitItalic)
        }
        let styledFont = font.fontDescriptor.withSymbolicTraits(traits).map {
            UIFont(descriptor: $0, size: font.pointSize)
        } ?? font
        let finalTextColor = style.bgStyle == .bg
            ? (textColor == .white ? UIColor.black : UIColor.white)
            : textColor
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = style.alignment
        var attributes: [NSAttributedString.Key: Any] = [
            .font: styledFont,
            .foregroundColor: finalTextColor,
            .paragraphStyle: paragraphStyle,
            .obliqueness: style.isItalic ? 0.25 : 0
        ]
        if style.hasUnderline {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        if style.hasStrikethrough {
            attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        }
        textView.attributedText = NSAttributedString(string: text, attributes: attributes)
        let fittingSize = textView.sizeThatFits(CGSize(width: safeWidth, height: .greatestFiniteMagnitude))
        textView.frame.size.height = max(1, fittingSize.height)
        textView.layoutIfNeeded()

        let rawRects = textView.getRawTextRects()
        guard !rawRects.isEmpty else { return nil }
        var contentRect = rawRects[0]
        rawRects.dropFirst().forEach { contentRect = contentRect.union($0) }
        if style.outputWithTextViewBound {
            contentRect.origin.x = 0
            contentRect.size.width = textView.bounds.width
        }

        if style.bgStyle == .bg {
            let backgroundLayer = CAShapeLayer()
            let backgroundPath = UIBezierPath()
            rawRects.forEach { backgroundPath.append(UIBezierPath(roundedRect: $0, cornerRadius: 10)) }
            backgroundLayer.path = backgroundPath.cgPath
            backgroundLayer.fillColor = textColor.cgColor
            textView.layer.insertSublayer(backgroundLayer, at: 0)
        }

        return UIGraphicsImageRenderer.pt.renderImage(size: contentRect.size) { context in
            context.translateBy(x: -contentRect.minX, y: -contentRect.minY)
            textView.layer.render(in: context)
        }
    }
}

public class PTPassthroughView: UIView {
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        
        // 如果系统判定当前点中的是容器本身（即空白区域）
        if hitView == self {
            // 返回 nil，让触摸事件直接穿透下去，交给底下的视图（比如文字引擎画布或背景图）处理
            return nil
        }
        
        // 如果点中的是子视图（即具体的图片贴纸 / 文字贴纸），则正常拦截并响应
        return hitView
    }
}

// 所有交互式编辑工具（涂鸦、马赛克等）的通用协议
@MainActor public protocol PTEditImageToolEngine: AnyObject {
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
    private var committedDrawingImage: UIImage?
    private var hasActiveStroke = false
    static let maxDrawLineImageWidth: CGFloat = 600
    
    /// 手势交互状态改变回调 (传回 true 代表开始交互，VC 需隐藏工具栏；false 则显示)
    public var onInteractStateChanged: ((Bool) -> Void)?
    
    // MARK: - 生命周期
    @MainActor
    public init(context: PTEditImageEngineContext) {
        self.context = context
        super.init()
    }
    
    public func toolDidActivate() {
        // 工具激活时的逻辑
    }
    
    public func toolDidDeactivate() {
        // 离开涂鸦工具时，重置橡皮擦状态
        isEraserMode = false
    }
    
    public func reloadRenderState() {
        committedDrawingImage = nil
        hasActiveStroke = false
        drawLine()
    }
    
    // MARK: - 手势路由
    // MARK: - 具体手势实现: 绘制
    
    public func handlePanGesture(_ pan: UIPanGestureRecognizer) {
        guard let context = context else { return }
        let point = pan.location(in: drawingImageView)
        guard point.x.isFinite, point.y.isFinite else { return }
        
        // 🌟 核心：一行代码拿到所有复杂的数学计算结果！
        let metrics = context.calculateCanvasMetrics(currentViewSize: drawingImageView.frame.size)
        
        if pan.state == .began {
            onInteractStateChanged?(true)
            committedDrawingImage = drawingImageView.image
            hasActiveStroke = true
            
            // 计算真实线宽 (橡皮擦模式 vs 普通画笔)
            let zoomScale = context.engineScrollView.zoomScale
            let configuredWidth = PTImageEditorConfig.share.drawLineWidth
            let safeWidth = configuredWidth.isFinite && configuredWidth > 0 ? configuredWidth : 1
            let safeZoomScale = zoomScale.isFinite && zoomScale > 0 ? zoomScale : 1
            let actualWidth = isEraserMode ? (44.0 / safeZoomScale) : (safeWidth / safeZoomScale)
            let pathRatio = metrics.ratio / metrics.originalRatio / metrics.toImageScale
            guard actualWidth.isFinite, actualWidth > 0,
                  pathRatio.isFinite, pathRatio > 0 else {
                hasActiveStroke = false
                return
            }
            
            let path = PTDrawPath(
                pathColor: isEraserMode ? .clear : drawColor,
                pathWidth: actualWidth,
                ratio: pathRatio,
                startPoint: point
            )
            path.isEraser = isEraserMode
            drawPaths.append(path)
            
            if isEraserMode {
                context.engineEraserCircleView.isHidden = false
                // 🌟 一行代码拿到橡皮擦矩阵
                let transform = context.calculateEraserTransform(viewTransform: drawingImageView.transform, viewSize: drawingImageView.frame.size)
                context.engineEraserCircleView.center = point.applying(transform)
                if PTImageEditorConfig.share.tools.contains(.draw) {
                    PTFeedbackCenter.shared.emit(.selectionChanged)
                }
            }
            
        } else if pan.state == .changed {
            // A failed/invalid start must never extend the previous committed stroke.
            guard hasActiveStroke else { return }
            if isEraserMode {
                let transform = context.calculateEraserTransform(viewTransform: drawingImageView.transform, viewSize: drawingImageView.frame.size)
                context.engineEraserCircleView.center = point.applying(transform)
            }
            
            let path = drawPaths.last
            path?.addLine(to: point)
            drawLine()
            
        } else if pan.state == .cancelled || pan.state == .ended {
            onInteractStateChanged?(false)
            context.engineEraserCircleView.isHidden = true
            guard hasActiveStroke else { return }
            guard let path = drawPaths.last else {
                committedDrawingImage = nil
                hasActiveStroke = false
                return
            }
            if pan.state == .cancelled {
                drawPaths.removeLast()
                committedDrawingImage = nil
                hasActiveStroke = false
                drawLine()
            } else if !path.hasMovement {
                drawPaths.removeLast()
                committedDrawingImage = nil
                hasActiveStroke = false
                drawLine()
            } else {
                path.finish()
                committedDrawingImage = nil
                hasActiveStroke = false
                drawLine()
                context.engineEditorManager.storeAction(.draw(path))
            }
        }
    }
        
    // MARK: - 渲染引擎
    
    public func drawLine() {
        guard let context = context else { return }
        
        // 🌟 渲染尺寸计算同样只需一行！
        let metrics = context.calculateCanvasMetrics(currentViewSize: drawingImageView.frame.size)
        let renderSize = CGSize(
            width: metrics.renderSize.width * metrics.toImageScale,
            height: metrics.renderSize.height * metrics.toImageScale
        )
        
        guard renderSize.width.isFinite, renderSize.height.isFinite,
              renderSize.width > 0, renderSize.height > 0 else { return }

        drawingImageView.image = UIGraphicsImageRenderer.pt.renderImage(size: renderSize) { renderContext in
            renderContext.setAllowsAntialiasing(true)
            renderContext.setShouldAntialias(true)
            if self.hasActiveStroke, let baseImage = self.committedDrawingImage {
                baseImage.draw(in: CGRect(origin: .zero, size: renderSize))
                self.drawPaths.last?.drawPath()
            } else {
                for path in self.drawPaths {
                    path.drawPath()
                }
            }
        }
    }
}

public class PTMosaicEngine: NSObject, PTEditImageToolEngine {
    
    // MARK: - 核心视图
    public var canvasView: UIView { mosaicContainerView }
    
    private lazy var mosaicContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        view.clipsToBounds = true
        return view
    }()
    
    /// 底层：放置全屏的马赛克图片
    private lazy var mosaicImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    /// 遮罩层：用户画的线都在这里，利用透明度决定漏出多少马赛克
    private lazy var maskImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    // 🌟 直接复用完美的 PTDrawPath！
    public var mosaicPaths: [PTDrawPath] = []
    public var isEraserMode: Bool = false
    
    private weak var context: PTEditImageEngineContext?
    private var committedMaskImage: UIImage?
    private var hasActiveStroke = false
    private var mosaicSourceImage: UIImage?
    public var onInteractStateChanged: ((Bool) -> Void)?
    
    public init(context: PTEditImageEngineContext) {
        self.context = context
        super.init()
    }
    
    public func toolDidActivate() {
        guard let context = context else { return }
        
        // 1. 生成全屏马赛克底图 (只生成一次)
        let baseImage = context.engineCurrentEditImage
        if mosaicSourceImage !== baseImage || mosaicImageView.image == nil {
            let mosaicImage = baseImage.pt.mosaicImage()
            mosaicImageView.image = mosaicImage
            mosaicSourceImage = mosaicImage == nil ? nil : baseImage
        }
        
        // 2. 绑定遮罩关系：maskImageView 画了黑线的地方（alpha=1）会透出马赛克，透明的地方（alpha=0）隐藏马赛克
        mosaicImageView.frame = mosaicContainerView.bounds
        maskImageView.frame = mosaicContainerView.bounds
        mosaicImageView.mask = maskImageView
        
        if mosaicImageView.superview == nil {
            mosaicContainerView.addSubview(mosaicImageView)
        }
    }
    
    public func toolDidDeactivate() {
        isEraserMode = false
    }
    
    public func reloadRenderState() {
        committedMaskImage = nil
        hasActiveStroke = false
        drawMask()
    }
    
    // MARK: - 手势路由与实现
    public func handlePanGesture(_ pan: UIPanGestureRecognizer) {
        guard let context = context else { return }
        let point = pan.location(in: mosaicContainerView)
        guard point.x.isFinite, point.y.isFinite else { return }
        
        // 🌟 核心：一行代码拿到所有复杂的数学计算结果！
        let metrics = context.calculateCanvasMetrics(currentViewSize: mosaicContainerView.frame.size)
        
        if pan.state == .began {
            onInteractStateChanged?(true)
            committedMaskImage = maskImageView.image
            hasActiveStroke = true
            
            // 计算真实线宽 (橡皮擦模式 vs 马赛克画笔)
            let zoomScale = context.engineScrollView.zoomScale
            let configuredWidth = PTImageEditorConfig.share.mosaicLineWidth
            let safeWidth = configuredWidth.isFinite && configuredWidth > 0 ? configuredWidth : 1
            let safeZoomScale = zoomScale.isFinite && zoomScale > 0 ? zoomScale : 1
            let actualWidth = isEraserMode ? (44.0 / safeZoomScale) : (safeWidth / safeZoomScale)
            let pathRatio = metrics.ratio / metrics.originalRatio / metrics.toImageScale
            guard actualWidth.isFinite, actualWidth > 0,
                  pathRatio.isFinite, pathRatio > 0 else {
                hasActiveStroke = false
                return
            }
            
            let path = PTDrawPath(
                pathColor: .black, // Mask 中黑色代表不透明（显示马赛克）
                pathWidth: actualWidth,
                ratio: pathRatio,
                startPoint: point
            )
            path.isEraser = isEraserMode // 标记身份
            mosaicPaths.append(path)
            
            if isEraserMode {
                context.engineEraserCircleView.isHidden = false
                // 🌟 一行代码拿到橡皮擦矩阵
                let transform = context.calculateEraserTransform(viewTransform: mosaicContainerView.transform, viewSize: mosaicContainerView.frame.size)
                context.engineEraserCircleView.center = point.applying(transform)
                if PTImageEditorConfig.share.tools.contains(.mosaic) {
                    PTFeedbackCenter.shared.emit(.selectionChanged)
                }
            }
            
        } else if pan.state == .changed {
            guard hasActiveStroke else { return }
            if isEraserMode {
                let transform = context.calculateEraserTransform(viewTransform: mosaicContainerView.transform, viewSize: mosaicContainerView.frame.size)
                context.engineEraserCircleView.center = point.applying(transform)
            }
            
            let path = mosaicPaths.last
            path?.addLine(to: point)
            drawMask() // 触发遮罩重绘
            
        } else if pan.state == .cancelled || pan.state == .ended {
            onInteractStateChanged?(false)
            context.engineEraserCircleView.isHidden = true
            guard hasActiveStroke else { return }
            guard let path = mosaicPaths.last else {
                committedMaskImage = nil
                hasActiveStroke = false
                return
            }
            if pan.state == .cancelled {
                mosaicPaths.removeLast()
                committedMaskImage = nil
                hasActiveStroke = false
                drawMask()
            } else if !path.hasMovement {
                mosaicPaths.removeLast()
                committedMaskImage = nil
                hasActiveStroke = false
                drawMask()
            } else {
                path.finish()
                committedMaskImage = nil
                hasActiveStroke = false
                drawMask()
                context.engineEditorManager.storeAction(.mosaic(path)) // 存入撤销栈
            }
        }
    }
    
    // MARK: - 渲染引擎 (渲染遮罩)
    private func drawMask() {
        guard let context = context else { return }
        
        // 🌟 渲染尺寸计算同样只需一行！
        let metrics = context.calculateCanvasMetrics(currentViewSize: mosaicContainerView.frame.size)
        let renderSize = CGSize(
            width: metrics.renderSize.width * metrics.toImageScale,
            height: metrics.renderSize.height * metrics.toImageScale
        )
        
        guard renderSize.width.isFinite, renderSize.height.isFinite,
              renderSize.width > 0, renderSize.height > 0 else { return }

        // 将路径渲染为一张带透明度的图片，交给 maskImageView
        maskImageView.image = UIGraphicsImageRenderer.pt.renderImage(size: renderSize) { renderContext in
            renderContext.setAllowsAntialiasing(true)
            renderContext.setShouldAntialias(true)
            if self.hasActiveStroke, let baseImage = self.committedMaskImage {
                baseImage.draw(in: CGRect(origin: .zero, size: renderSize))
                self.mosaicPaths.last?.drawPath()
            } else {
                for path in self.mosaicPaths {
                    path.drawPath() // 会自动处理普通画笔(.normal)和橡皮擦(.clear)的混合模式
                }
            }
        }
    }

    public func updateBaseMosaicImage(_ newBaseImage: UIImage) {
        // 重新生成打好马赛克的全屏底图
        mosaicImageView.image = newBaseImage.pt.mosaicImage()
        mosaicSourceImage = newBaseImage
    }
}

public class PTStickerEngine: NSObject, PTEditImageToolEngine {
    
    // MARK: - 核心视图与状态
    public var customTextEditorClass: PTTextEditorConfigurable.Type = PTEditInputViewController.self
    public var canvasView: UIView { stickersContainer }
    
    private lazy var stickersContainer: PTPassthroughView = {
        let view = PTPassthroughView()
        view.backgroundColor = .clear
        view.clipsToBounds = false // 允许贴纸部分拖出边界
        return view
    }()
    
    private weak var context: PTEditImageEngineContext?
    private var preStickerState: PTBaseStickertState?
    private var backgroundRemovalTask: Task<Void, Never>?
    private var backgroundRemovalToken = 0
    
    /// 交互状态回调 (用于隐藏/显示主工具栏)
    public var onInteractStateChanged: ((Bool) -> Void)?
    /// 贴纸点击回调
    public var onStickerTapped: ((PTBaseStickerView) -> Void)?
    public var onStickerAdded: ((PTBaseStickerView) -> Void)?
    
    public var currentSelectedSticker: PTBaseStickerView?

    public var onRequestImageSelection: ((_ completion: @escaping (UIImage?) -> Void) -> Void)?
    public var onProcessingStateChanged: ((Bool) -> Void)?
    
    // MARK: - 生命周期
    public init(context: PTEditImageEngineContext) {
        self.context = context
        super.init()
    }

    deinit {
        backgroundRemovalTask?.cancel()
    }
    
    public func toolDidActivate() {
        // 贴纸工具其实是一个“触发器”，激活逻辑交由 VC 处理
    }
    
    public func toolDidDeactivate() {
        backgroundRemovalTask?.cancel()
        backgroundRemovalToken += 1
        // 工具失活时，取消所有贴纸的激活状态(隐藏白边框)
        stickersContainer.subviews.forEach { view in
            (view as? PTStickerViewAdditional)?.resetState()
        }
        currentSelectedSticker = nil
    }
    
    public func handlePanGesture(_ pan: UIPanGestureRecognizer) { }
    
    public func reloadRenderState() { }
    
    // MARK: - 通用贴纸管理 (核心复用)
    /// 统一的添加贴纸底层方法
    private func addSticker(_ sticker: PTBaseStickerView) {
        guard let context = context else { return }
        stickersContainer.addSubview(sticker)
        sticker.frame = sticker.originFrame
        
        sticker.delegate = self
        // 解决手势冲突
        context.engineScrollView.pinchGestureRecognizer?.require(toFail: sticker.pinchGes)
        context.engineScrollView.panGestureRecognizer.require(toFail: sticker.panGes)
        
        currentSelectedSticker = sticker
        onStickerAdded?(sticker)
    }
    
    /// 根据 ID 移除对应的贴纸
    private func removeSticker(id: String?) {
        guard let id = id else { return }
        for sticker in stickersContainer.subviews.reversed() {
            guard let stickerView = sticker as? PTBaseStickerView, stickerView.id == id else { continue }
            if currentSelectedSticker === stickerView {
                backgroundRemovalTask?.cancel()
                backgroundRemovalToken += 1
            }
            stickerView.moveToAshbin()
            if currentSelectedSticker === stickerView {
                currentSelectedSticker = nil
                onInteractStateChanged?(false)
            }
            break
        }
    }
    
    /// 供外部调用：移除当前选中的贴纸（例如：点击外部工具栏的“删除”按钮）
    public func removeCurrentSelectedSticker() {
        // 1. 确保当前有选中的贴纸，并且能获取到上下文
        guard let sticker = currentSelectedSticker, let context = context else { return }
        
        // 2. 记录即将被删除的贴纸状态，用于支持撤销 (Undo)
        let oldState = sticker.state
        
        // 3. 🌟 智能区分：存入对应类型的撤销栈记录
        // 因为是删除操作，所以新的状态 (newState) 是 nil
        if sticker is PTTextStickerView {
            context.engineEditorManager.storeAction(.sticker(oldState: oldState, newState: nil))
        } else {
            context.engineEditorManager.storeAction(.imageSticker(oldState: oldState, newState: nil))
        }
        
        // 4. 执行移除逻辑 (复用贴纸自身封装好的销毁方法，自动清理视图和定时器)
        sticker.moveToAshbin()
        
        // 5. 清空当前选中的指针
        currentSelectedSticker = nil
        
        // 6. 如果外部有监听交互状态，可以通知外部刷新 UI (例如恢复底部栏等)
        onInteractStateChanged?(false)
    }

    // MARK: - 文字贴纸专属业务
    // MARK: - 贴纸增删改查
    public func createTextSticker(text: String? = nil, textColor: UIColor? = nil, font: UIFont? = nil, style: PTInputTextStyle = PTInputTextStyle()) {
        showInputTextVC(text, textColor: textColor, font: font, style: style) { [weak self] newText, newColor, newFont, image, newStyle in
            guard let self = self, !newText.isEmpty, let image = image else { return }
            self.addTextStickersView(newText, textColor: newColor, font: newFont, image: image, style: newStyle)
        }
    }
    
    private func addTextStickersView(_ text: String, textColor: UIColor, font: UIFont, image: UIImage, style: PTInputTextStyle) {
        guard let context = context else { return }
        let mainViewBounds = context.engineMainView.bounds
        guard mainViewBounds.width > 0, mainViewBounds.height > 0 else {
            PTNSLogConsole("错误：engineMainView 尚未正确布局")
            return
        }
        
        let maxLimitSize = CGSize(width: mainViewBounds.width * 0.5, height: mainViewBounds.height * 0.5)
        let scale = context.engineScrollView.zoomScale
        guard scale.isFinite, scale > 0,
              maxLimitSize.width.isFinite, maxLimitSize.height.isFinite,
              maxLimitSize.width > 0, maxLimitSize.height > 0 else { return }
        let size = PTTextStickerView.calculateSize(image: image,maxLimitSize:maxLimitSize)
        let originFrame = PTBaseStickerView.getStickerOriginFrame(size, current: context, container: stickersContainer)
        guard size.width > 0, size.height > 0,
              originFrame.origin.x.isFinite, originFrame.origin.y.isFinite,
              originFrame.width.isFinite, originFrame.height.isFinite,
              originFrame.width > 0, originFrame.height > 0 else { return }
        
        let textSticker = PTTextStickerView(
            text: text, textColor: textColor, font: font, style: style, image: image,
            originScale: 1 / scale, originAngle: -context.engineCurrentAngle, originFrame: originFrame
        )
        
        addSticker(textSticker)
        context.engineEditorManager.storeAction(.sticker(oldState: nil, newState: textSticker.state))
    }
    
    private func showInputTextVC(_ text: String? = nil, textColor: UIColor? = nil, font: UIFont? = nil, style: PTInputTextStyle = PTInputTextStyle(), completion: @escaping (String, UIColor, UIFont, UIImage?, PTInputTextStyle) -> Void) {
        guard let context = context else { return }
        
        let scrollView = context.engineScrollView
        let containerWidth = stickersContainer.frame.width
        let zoomScale = scrollView.zoomScale
        guard containerWidth.isFinite, containerWidth > 0,
              context.engineOriginalImageSize.width.isFinite,
              context.engineOriginalImageSize.width > 0,
              zoomScale.isFinite, zoomScale > 0 else { return }
        var r = scrollView.convert(context.engineMainView.frame, to: stickersContainer)
        r.origin.x += scrollView.contentOffset.x / zoomScale
        r.origin.y += scrollView.contentOffset.y / zoomScale
        
        let scale = context.engineOriginalImageSize.width / containerWidth
        guard scale.isFinite, scale > 0 else { return }
        r.origin.x *= scale
        r.origin.y *= scale
        r.size.width *= scale
        r.size.height *= scale
        
        // 获取高斯模糊的背景底图
        let bgImage = context.engineCurrentEditImage.pt.clipImage(angle: 0, editRect: r, isCircle: false)
        
        let vc = customTextEditorClass.init(image: bgImage, text: text, textColor: textColor, font: font, style: style)
        vc.endInput = { text, textColor, font, image, style in
            completion(text, textColor, font, image, style)
        }
        
        context.engineViewController.navigationController?.pushViewController(vc, animated: true)
    }

    public func updateSelectedTextSticker(newFont: UIFont? = nil, newColor: UIColor? = nil, newStyle: PTInputTextStyle? = nil) {
        guard let textSticker = currentSelectedSticker as? PTTextStickerView else { return }
        guard let context = self.context else { return }
        
        let oldState = textSticker.state
        
        let targetFont = newFont ?? (textSticker.font ?? .boldSystemFont(ofSize: PTTextStickerView.fontSize))
        let targetColor = newColor ?? textSticker.textColor
        let targetStyle = newStyle ?? textSticker.style
        let currentText = textSticker.text
        
        let maxWidth = context.engineMainView.bounds.width
        
        guard let newImage = PTTextStickerRenderer.generateImage(text: currentText, font: targetFont, textColor: targetColor, style: targetStyle, maxWidth: maxWidth) else { return }
        
        textSticker.font = targetFont
        textSticker.textColor = targetColor
        textSticker.style = targetStyle
        textSticker.image = newImage
        
        let mainViewBounds = context.engineMainView.bounds
        let maxLimitSize = CGSize(width: mainViewBounds.width * 0.5, height: mainViewBounds.height * 0.5)
        let newSize = PTTextStickerView.calculateSize(image: newImage, maxLimitSize: maxLimitSize)
        textSticker.changeSize(to: newSize)
        
        context.engineEditorManager.storeAction(.sticker(oldState: oldState, newState: textSticker.state))
    }

    // MARK: - 图片贴纸专属业务
        
    public func addImageSticker(_ image: UIImage) {
        guard let context = context else { return }
        let mainViewBounds = context.engineMainView.bounds
        let currentZoomScale = context.engineScrollView.zoomScale
        guard mainViewBounds.width > 0, mainViewBounds.height > 0,
              currentZoomScale.isFinite, currentZoomScale > 0 else { return }
        
        let maxLimitSize = CGSize(width: mainViewBounds.width * 0.5, height: mainViewBounds.height * 0.5)
        let targetSize = PTImageStickerView.calculateSize(image: image, maxLimitSize: maxLimitSize)
        let originFrame = PTBaseStickerView.getStickerOriginFrame(targetSize, current: context, container: stickersContainer)
        
        let imageSticker = PTImageStickerView(
            image: image, originScale: 1.0 / currentZoomScale, originAngle: -context.engineCurrentAngle, originFrame: originFrame
        )
        addSticker(imageSticker)
        context.engineEditorManager.storeAction(.imageSticker(oldState: nil, newState: imageSticker.state))
    }

    @MainActor
    public func removeBackgroundForSelectedSticker() {
        guard let imageSticker = currentSelectedSticker as? PTImageStickerView else { return }
        let originalImage = imageSticker.image
        let oldState = imageSticker.state
        guard let imageData = originalImage.pngData() else {
            onProcessingStateChanged?(false)
            return
        }

        backgroundRemovalTask?.cancel()
        backgroundRemovalToken += 1
        let token = backgroundRemovalToken
        
        onProcessingStateChanged?(true)
        backgroundRemovalTask = Task { @MainActor [weak self, weak imageSticker] in
            guard let self else { return }
            defer {
                if token == self.backgroundRemovalToken {
                    self.onProcessingStateChanged?(false)
                }
            }

            let resultData = try? await Task.detached(priority: .userInitiated) {
                try Self.performForegroundMasking(data: imageData)
            }.value

            guard let imageSticker,
                  let resultData,
                  let cutoutImage = UIImage(data: resultData),
                  !Task.isCancelled,
                  token == self.backgroundRemovalToken,
                  self.currentSelectedSticker === imageSticker,
                  imageSticker.superview != nil else {
                return
            }

            UIView.transition(with: imageSticker, duration: 0.35, options: .transitionCrossDissolve) {
                imageSticker.image = cutoutImage
            }
            let maxLimitSize = CGSize(width: (self.context?.engineMainView.bounds.width ?? 0) * 0.5,
                                      height: (self.context?.engineMainView.bounds.height ?? 0) * 0.5)
            let newSize = PTImageStickerView.calculateSize(image: cutoutImage, maxLimitSize: maxLimitSize)
            imageSticker.changeSize(to: newSize)
            self.context?.engineEditorManager.storeAction(.imageSticker(oldState: oldState, newState: imageSticker.state))
        }
    }

    nonisolated private static func performForegroundMasking(data: Data) throws -> Data? {
        guard let inputImage = UIImage(data: data), let cgImage = inputImage.cgImage else { return nil }
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        guard let observation = request.results?.first else { return nil }
        let maskPixelBuffer = try observation.generateScaledMaskForImage(forInstances: observation.allInstances, from: handler)
        
        let originalCIImage = CIImage(cgImage: cgImage)
        let maskCIImage = CIImage(cvPixelBuffer: maskPixelBuffer)
        let bgCIImage = CIImage(color: .clear).cropped(to: originalCIImage.extent)
        
        guard let filter = CIFilter(name: "CIBlendWithMask") else { return nil }
        filter.setValue(originalCIImage, forKey: kCIInputImageKey)
        filter.setValue(bgCIImage, forKey: kCIInputBackgroundImageKey)
        filter.setValue(maskCIImage, forKey: kCIInputMaskImageKey)
        
        guard let outputCIImage = filter.outputImage else { return nil }
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else { return nil }
        return UIImage(cgImage: outputCGImage, scale: inputImage.scale, orientation: inputImage.imageOrientation).pngData()
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
}

extension PTStickerEngine {
    // MARK: - 通用图层及撤销重做控制
    public func bringSelectedToFront() {
        guard let sticker = currentSelectedSticker else { return }
        stickersContainer.bringSubviewToFront(sticker)
    }

    public func sendSelectedToBack() {
        guard let sticker = currentSelectedSticker else { return }
        stickersContainer.sendSubviewToBack(sticker)
    }

    public func centerSelectedHorizontally() {
        guard let sticker = currentSelectedSticker, let context = context else { return }
        let targetPoint = context.engineMainView.convert(CGPoint(x: context.engineMainView.bounds.midX, y: 0), to: stickersContainer)
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) { sticker.center.x = targetPoint.x }
    }
    
    public func centerSelectedVertically() {
        guard let sticker = currentSelectedSticker, let context = context else { return }
        let targetPoint = context.engineMainView.convert(CGPoint(x: 0, y: context.engineMainView.bounds.midY), to: stickersContainer)
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) { sticker.center.y = targetPoint.y }
    }
    
    /// 将选中贴纸上移一层
    public func moveSelectedOneLayerUp() {
        guard let sticker = currentSelectedSticker else { return }
        
        // 获取当前贴纸在容器中的索引
        guard let currentIndex = stickersContainer.subviews.firstIndex(of: sticker) else { return }
        let totalCount = stickersContainer.subviews.count
        
        // 如果它还不是最顶层，就和它上面的那层交换位置
        if currentIndex < totalCount - 1 {
            stickersContainer.exchangeSubview(at: currentIndex, withSubviewAt: currentIndex + 1)
        }
    }
    
    /// 将选中贴纸下移一层
    public func moveSelectedOneLayerDown() {
        guard let sticker = currentSelectedSticker else { return }
        
        // 获取当前贴纸在容器中的索引
        guard let currentIndex = stickersContainer.subviews.firstIndex(of: sticker) else { return }
        
        // 如果它还不是最底层，就和它下面的那层交换位置
        if currentIndex > 0 {
            stickersContainer.exchangeSubview(at: currentIndex, withSubviewAt: currentIndex - 1)
        }
    }
    
    /// 将选中贴纸铺满整个主视图（居中并等比放大适配）
    public func fillSelectedStickerToScreen() {
        guard let sticker = currentSelectedSticker, let context = context else { return }
        
        // 1. 获取主视图的绝对中心，并转换到贴纸容器的坐标系下
        let targetCenter = context.engineMainView.convert(
            CGPoint(x: context.engineMainView.bounds.midX, y: context.engineMainView.bounds.midY),
            to: stickersContainer
        )
        
        // 2. 计算缩放倍数
        // 贴纸的基础物理大小（需乘动画底图的 zoomScale 来还原真实视觉尺寸）
        let baseWidthInMainView = sticker.bounds.width * context.engineScrollView.zoomScale
        let baseHeightInMainView = sticker.bounds.height * context.engineScrollView.zoomScale
        
        let mainViewBounds = context.engineMainView.bounds

        // English: Stop before calculating a scale from incomplete layout information.
        // Español: Detenemos el cálculo si el layout aún no proporciona dimensiones válidas.
        // 中文：如果布局尚未提供有效尺寸，则停止计算缩放比例。
        guard baseWidthInMainView.isFinite, baseHeightInMainView.isFinite,
              baseWidthInMainView > 0, baseHeightInMainView > 0,
              mainViewBounds.width.isFinite, mainViewBounds.height.isFinite,
              mainViewBounds.width > 0, mainViewBounds.height > 0 else { return }
        
        // 为了确保能“铺满”且不被裁剪（Aspect Fit 逻辑），取宽高比中较小的值作为目标缩放倍数。
        // 💡 如果你希望的是强制填满不留白边（Aspect Fill，可能会裁剪部分贴纸内容），请把 min 改成 max。
        let targetScaleX = mainViewBounds.width / baseWidthInMainView
        let targetScaleY = mainViewBounds.height / baseHeightInMainView
        let targetGesScale = min(targetScaleX, targetScaleY)
        guard targetGesScale.isFinite, targetGesScale > 0 else { return }
        
        // 计算从当前缩放到目标缩放，还需要乘多少倍
        let currentScale = max(0.01, sticker.gesScale) // 限制下限，避免除以0
        let scaleMultiplier = targetGesScale / currentScale
        guard scaleMultiplier.isFinite, scaleMultiplier > 0 else { return }
        
        // 3. 执行丝滑的动画
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
            // 移到中心
            sticker.center = targetCenter
            
            // 🌟 核心：在现有的 Transform 基础上再叠加缩放。
            // 这样做的好处是：无论用户之前把贴纸旋转了多少度，旋转角度都会被完美保留！
            sticker.transform = sticker.transform.scaledBy(x: scaleMultiplier, y: scaleMultiplier)
            
            // 同步更新贴纸底层的数据模型，防止下次手指捏合时画面发生跳动
            sticker.gesScale = targetGesScale
        }
    }
}

// MARK: - PTStickerViewDelegate (核心交互与垃圾桶动画)
extension PTStickerEngine: PTStickerViewDelegate {
    
    public func stickerBeginOperation(_ sticker: PTBaseStickerView) {
        guard let context = context else { return }
        preStickerState = sticker.state
        currentSelectedSticker = sticker

        onInteractStateChanged?(true)
        
        let ashbinView = context.engineAshbinView
        ashbinView.layer.removeAllAnimations()
        let isDragging = sticker.panGes.state == .began || sticker.panGes.state == .changed
        ashbinView.isHidden = !isDragging
        guard isDragging else { return }

        var frame = ashbinView.frame
        let diff = context.engineMainView.frame.height - frame.minY
        frame.origin.y += diff
        ashbinView.frame = frame
        frame.origin.y -= diff
        
        UIView.animate(withDuration: 0.25) { ashbinView.frame = frame }
        
        stickersContainer.subviews.forEach { view in
            if view !== sticker {
                (view as? PTStickerViewAdditional)?.resetState()
                (view as? PTStickerViewAdditional)?.gesIsEnabled = false
            }
        }
    }

    public func stickerOnOperation(_ sticker: PTBaseStickerView, panGes: UIPanGestureRecognizer) {
        guard let context = context else { return }
        let ashbinView = context.engineAshbinView
        let ashbinImgView = context.engineAshbinImgView
        guard panGes.state == .changed else {
            ashbinImgView.isHighlighted = false
            sticker.alpha = 1
            return
        }
        let point = panGes.location(in: context.engineMainView)

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
                
        onInteractStateChanged?(false)
        
        let ashbinView = context.engineAshbinView
        ashbinView.layer.removeAllAnimations()
        ashbinView.isHidden = true
        
        var endState: PTBaseStickertState? = sticker.state
        let point = panGes.location(in: context.engineMainView)
        
        if panGes.state == .ended && ashbinView.frame.contains(point) {
            sticker.moveToAshbin()
            endState = nil
            if currentSelectedSticker === sticker { currentSelectedSticker = nil }
        }
        
        let oldState = preStickerState
        preStickerState = nil
        if let old = oldState, let new = endState,
           old.originFrame == new.originFrame,
           old.gesScale == new.gesScale,
           old.gesRotation == new.gesRotation,
           old.totalTranslationPoint == new.totalTranslationPoint {
            // An unchanged gesture must not create an Undo entry.
        } else if sticker is PTTextStickerView {
            context.engineEditorManager.storeAction(.sticker(oldState: oldState, newState: endState))
        } else {
            context.engineEditorManager.storeAction(.imageSticker(oldState: oldState, newState: endState))
        }
        
        stickersContainer.subviews.forEach { view in
            (view as? PTStickerViewAdditional)?.gesIsEnabled = true
        }
    }
    
    public func stickerDidTap(_ sticker: PTBaseStickerView) {
        currentSelectedSticker = sticker
        stickersContainer.subviews.forEach { view in
            if view !== sticker {
                (view as? PTStickerViewAdditional)?.resetState()
            }
        }
        onStickerTapped?(sticker)
    }
    
    public func sticker(_ textSticker: PTTextStickerView, editText text: String) {
        showInputTextVC(text, textColor: textSticker.textColor, font: textSticker.font, style: textSticker.style) { [weak self, weak textSticker] text, textColor, font, image, style in
            guard let self, let textSticker, let context = self.context,
                  textSticker.superview != nil else { return }
            let oldState = textSticker.state
            if text.isEmpty || image == nil {
                textSticker.moveToAshbin()
                if self.currentSelectedSticker === textSticker { self.currentSelectedSticker = nil }
                context.engineEditorManager.storeAction(.sticker(oldState: oldState, newState: nil))
                return
            }
            guard let image else { return }
            guard textSticker.text != text
                    || textSticker.textColor != textColor
                    || textSticker.style != style
                    || textSticker.font?.fontName != font.fontName
                    || textSticker.font?.pointSize != font.pointSize else {
                textSticker.startTimer()
                return
            }

            let maxWidth = context.engineMainView.bounds.width
            let maxLimitSize = CGSize(width: maxWidth * 0.5,
                                      height: context.engineMainView.bounds.height * 0.5)
            textSticker.text = text
            textSticker.textColor = textColor
            textSticker.font = font
            textSticker.style = style
            textSticker.image = image
            textSticker.changeSize(to: PTTextStickerView.calculateSize(image: image, maxLimitSize: maxLimitSize))
            textSticker.startTimer()
            context.engineEditorManager.storeAction(.sticker(oldState: oldState, newState: textSticker.state))
        }
    }

    public func sticker(_ imageSticker: PTImageStickerView, editImage currentImage: UIImage) {
        onRequestImageSelection? { [weak self, weak imageSticker] newImage in
            guard let self = self,
                  let context = self.context,
                  let imageSticker = imageSticker,
                  let newImage = newImage else { return }
            guard imageSticker.superview != nil, imageSticker.image !== newImage else { return }
            let oldState = imageSticker.state
            imageSticker.startTimer()
            imageSticker.image = newImage
            
            let currentScale = max(1.0, imageSticker.gesScale)
            let maxWidth = context.engineMainView.bounds.width
            let maxHeight = context.engineMainView.bounds.height
            guard maxWidth > 0, maxHeight > 0 else { return }
            
            let maxLimitSize = CGSize(width: (maxWidth * 0.5) / currentScale, height: (maxHeight * 0.4) / currentScale)
            let newSize = PTImageStickerView.calculateSize(image: newImage, maxLimitSize: maxLimitSize)
            imageSticker.changeSize(to: newSize)
            
            // 安全回弹
            let visualTopY = imageSticker.center.y - (newSize.height * imageSticker.gesScale) / 2
            let safeTopMargin: CGFloat = 90
            if visualTopY < safeTopMargin {
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
                    imageSticker.center.y += (safeTopMargin - visualTopY)
                }
            }
            context.engineEditorManager.storeAction(.imageSticker(oldState: oldState, newState: imageSticker.state))
        }
    }
}

public class PTAdjustEngine: NSObject, PTEditImageToolEngine {
    
    // MARK: - 核心视图与状态
    
    /// Adjust 工具没有直接覆盖在图片上的 Canvas，它的 UI 是调节滑块
    private let emptyCanvasView = UIView()
    public var canvasView: UIView { emptyCanvasView }
    
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
    private var adjustmentRenderTask: Task<Void, Never>?
    
    // MARK: - 生命周期
    
    public init(context: PTEditImageEngineContext) {
        self.context = context
        super.init()
        setupSliderCallbacks()
    }

    deinit {
        adjustmentRenderTask?.cancel()
    }
    
    private func setupSliderCallbacks() {
        adjustSlider.beginAdjust = { [weak self] in
            PTMainActorBridge.perform { [weak self] in
                self?.preAdjustStatus = self?.currentAdjustStatus ?? PTAdjustStatus()
            }
        }
        
        adjustSlider.valueChanged = { [weak self] value in
            self?.adjustValueChanged(value)
        }
        
        adjustSlider.endAdjust = { [weak self] in
            PTMainActorBridge.perform { [weak self] in
                guard let self, let context = self.context else { return }
                guard self.preAdjustStatus.brightness != self.currentAdjustStatus.brightness
                        || self.preAdjustStatus.contrast != self.currentAdjustStatus.contrast
                        || self.preAdjustStatus.saturation != self.currentAdjustStatus.saturation else { return }
                context.engineEditorManager.storeAction(
                    .adjust(oldStatus: self.preAdjustStatus, newStatus: self.currentAdjustStatus)
                )
                self.hasAdjustedImage = true
            }
        }
    }
    
    public func toolDidActivate() {
        adjustSlider.isHidden = false
        // 🔥 核心：激活时，向 VC 索要最新的参考底图！
        editImageAdjustRef = context?.engineRequestAdjustReferenceImage()
    }
    
    public func toolDidDeactivate() {
        adjustSlider.isHidden = true
        adjustmentRenderTask?.cancel()
    }
    
    public func handlePanGesture(_ pan: UIPanGestureRecognizer) {
        // Adjust 工具的手势由 slider 自己内部消化，这里不需要处理图片上的 Pan 手势
    }
    
    public func reloadRenderState() {
        // 触发 Undo/Redo 时，重新渲染图片
        adjustmentRenderTask?.cancel()
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
        
        // English: Coalesce slider events into one main-actor render per run-loop turn.
        // Español: Agrupamos los eventos del control en un renderizado del actor principal por ciclo.
        // 中文：将滑块高频事件合并为每个运行循环只执行一次主线程渲染。
        adjustmentRenderTask?.cancel()
        adjustmentRenderTask = Task { @MainActor [weak self] in
            await Task.yield()
            guard let self, !Task.isCancelled else { return }
            self.adjustStatusChanged()
        }
    }
    
    private func adjustStatusChanged() {
        guard let context = context else { return }
        // 使用缓存的参考底图进行渲染，如果没有则降级使用未 adjustment 的图。
        let baseImage = editImageAdjustRef ?? context.engineImageWithoutAdjust
        if let image = adjustFilterValueSet(filterImage: baseImage) {
            context.engineUpdateEditImage(image)
        }
    }
    
    // MARK: - Harbeth 滤镜渲染核心
    @MainActor
    public func adjustFilterValueSet(filterImage: UIImage?) -> UIImage? {
        guard !currentAdjustStatus.allValueIsZero else { return filterImage }
        
        var filters = [C7FilterProtocol]()
        for tool in PTImageEditorConfig.share.adjust_tools {
            let result = tool.getFilterResult(texture: nil)
            guard let callback = result.callback else { continue }
            switch tool {
            case .brightness:
                filters.append(callback(tool.filterValue(currentAdjustStatus.brightness)))
            case .contrast:
                filters.append(callback(tool.filterValue(currentAdjustStatus.contrast)))
            case .saturation:
                filters.append(callback(tool.filterValue(currentAdjustStatus.saturation)))
            default:
                break
            }
        }
        
        let dest = HarbethIO(element: filterImage, filters: filters)
        return try? dest.output()
    }
}

public class PTFilterEngine: NSObject, PTEditImageToolEngine {
    
    // MARK: - 核心状态
    
    private let emptyCanvasView = UIView()
    public var canvasView: UIView { emptyCanvasView }

    public var currentFilter: PTHarBethFilter = .none
    public var thumbnailFilterImages: [UIImage] = []
    private var filterRenderTask: Task<Void, Never>?
    private var filterSourceIdentity: ObjectIdentifier?
    
    // English: Filter previews use an explicit bounded cache policy.
    // Español: Las previsualizaciones de filtros usan una política de caché acotada explícita.
    // 中文：滤镜预览使用明确的有界缓存策略。
    private let filterCachePolicy = PTCachePolicy(countLimit: 6,
                                                   costLimit: 96 * 1024 * 1024,
                                                   namespace: "image-editor-filter")
    private lazy var filterCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = filterCachePolicy.countLimit
        cache.totalCostLimit = filterCachePolicy.costLimit
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
    
    public func toolDidDeactivate() {
        filterRenderTask?.cancel()
    }
    public func handlePanGesture(_ pan: UIPanGestureRecognizer) { }

    deinit {
        filterRenderTask?.cancel()
    }
    
    public func reloadRenderState() {
        changeFilter(currentFilter)
    }
    
    // MARK: - 滤镜业务逻辑
    
    /// 异步生成底部菜单所需的滤镜缩略图
    @MainActor
    public func generateFilterThumbnails() async {
        guard let context = context, let thumbnailImage = context.engineThumbnailImage else { return }
        
        let filters = PTImageEditorConfig.share.filters
        
        var thumbnails = [UIImage]()
        thumbnails.reserveCapacity(filters.count)

        for filter in filters {
            guard !Task.isCancelled else { return }
            let image = filter.type == .none
                ? thumbnailImage
                : filter.getCurrentFilterImage(image: thumbnailImage)
            thumbnails.append(image)
            await Task.yield()
        }

        guard !Task.isCancelled else { return }
        self.thumbnailFilterImages = thumbnails
    }
    
    /// 切换滤镜
    public func changeFilter(_ filter: PTHarBethFilter) {
        filterRenderTask?.cancel()
        currentFilter = filter
        filterRenderTask = Task { @MainActor [weak self] in
            await Task.yield()
            guard let self, !Task.isCancelled, let context = self.context else { return }

            let sourceImage = context.engineOriginalImage
            let sourceIdentity = ObjectIdentifier(sourceImage)
            if self.filterSourceIdentity != sourceIdentity {
                self.filterCache.removeAllObjects()
                self.filterSourceIdentity = sourceIdentity
            }
            let cacheKey = "\(filter.type.rawValue)-\(Int(sourceImage.size.width))-\(Int(sourceImage.size.height))-\(Int(sourceImage.scale))".nsString
            let resultImage: UIImage
            if filter.type == .none {
                resultImage = sourceImage
            } else if let cachedImage = self.filterCache.object(forKey: cacheKey) {
                resultImage = cachedImage
            } else {
                resultImage = filter.getCurrentFilterImage(image: sourceImage)
                let cost = max(1, Int(sourceImage.size.width * sourceImage.size.height * 4))
                self.filterCache.setObject(resultImage, forKey: cacheKey, cost: cost)
            }

            guard !Task.isCancelled else { return }
            context.engineDidUpdateFilteredBaseImage(resultImage)
        }
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
    
    // MARK: - 裁剪框命中检测

    /// 使用与手势开始时相同的规则命中边缘，避免整张图片的拖动被裁剪框手势抢占。
    @MainActor public func canBeginPan(at point: CGPoint) -> Bool {
        hitTestPanEdge(at: point) != .none
    }

    private func hitTestPanEdge(at point: CGPoint) -> PTClipPanEdge {
        let frame = clipBoxFrame
        guard frame.width.isFinite, frame.height.isFinite,
              frame.width > 0, frame.height > 0,
              point.x.isFinite, point.y.isFinite else { return .none }

        let hitSlop: CGFloat = 24
        guard frame.insetBy(dx: -hitSlop, dy: -hitSlop).contains(point) else { return .none }

        let left = abs(point.x - frame.minX)
        let right = abs(point.x - frame.maxX)
        let top = abs(point.y - frame.minY)
        let bottom = abs(point.y - frame.maxY)
        let horizontal = min(left, right) <= hitSlop
        let vertical = min(top, bottom) <= hitSlop

        if horizontal && vertical {
            if left <= right {
                return top <= bottom ? .topLeft : .bottomLeft
            }
            return top <= bottom ? .topRight : .bottomRight
        }
        if horizontal { return left <= right ? .left : .right }
        if vertical { return top <= bottom ? .top : .bottom }
        return .none
    }

    // MARK: - 拖拽处理

    @MainActor public func handlePanGesture(_ pan: UIPanGestureRecognizer, in view: UIView) {
        let point = pan.location(in: view)

        switch pan.state {
        case .began:
            panEdge = hitTestPanEdge(at: point)
            guard panEdge != .none else { return }
            beginPanPoint = point
            clipOriginFrame = clipBoxFrame
            onInteractStateChanged?(true)
        case .changed:
            guard panEdge != .none, let context else { return }
            let delta = CGPoint(x: point.x - beginPanPoint.x, y: point.y - beginPanPoint.y)
            let next = Self.resizedClipFrame(
                from: clipOriginFrame,
                edge: panEdge,
                translation: delta,
                aspectRatio: selectedRatio.whRatio,
                inside: context.engineMaxClipFrame,
                minimumSize: context.engineMinClipSize
            )
            guard next != clipBoxFrame else { return }
            onClipBoxFrameChanged?(next)
        case .ended, .cancelled, .failed:
            guard panEdge != .none else { return }
            panEdge = .none
            onInteractStateChanged?(false)
        default:
            break
        }
    }

    /// 在拖拽起点的几何状态上计算每一帧，保证锚点固定，避免累积误差和越界。
    /// 固定比例的四个角同时响应水平/垂直位移；边缘沿对应轴缩放并保持另一轴居中。
    static func resizedClipFrame(
        from original: CGRect,
        edge: PTClipPanEdge,
        translation: CGPoint,
        aspectRatio: CGFloat,
        inside bounds: CGRect,
        minimumSize: CGSize
    ) -> CGRect {
        guard edge != .none,
              original.width.isFinite, original.height.isFinite,
              original.width > 0, original.height > 0,
              bounds.width.isFinite, bounds.height.isFinite,
              bounds.width > 0, bounds.height > 0,
              translation.x.isFinite, translation.y.isFinite else { return original }

        func clamp(_ value: CGFloat, _ low: CGFloat, _ high: CGFloat) -> CGFloat {
            min(max(value, low), max(low, high))
        }

        let isLeft = edge == .left || edge == .topLeft || edge == .bottomLeft
        let isRight = edge == .right || edge == .topRight || edge == .bottomRight
        let isTop = edge == .top || edge == .topLeft || edge == .topRight
        let isBottom = edge == .bottom || edge == .bottomLeft || edge == .bottomRight
        let minWidth = max(1, minimumSize.width)
        let minHeight = max(1, minimumSize.height)

        guard aspectRatio.isFinite, aspectRatio > 0 else {
            // 自由裁剪：只移动手指选中的边，另一边保持在原位置。
            var minX = original.minX
            var maxX = original.maxX
            var minY = original.minY
            var maxY = original.maxY

            if isLeft { minX = clamp(original.minX + translation.x, bounds.minX, original.maxX - minWidth) }
            if isRight { maxX = clamp(original.maxX + translation.x, original.minX + minWidth, bounds.maxX) }
            if isTop { minY = clamp(original.minY + translation.y, bounds.minY, original.maxY - minHeight) }
            if isBottom { maxY = clamp(original.maxY + translation.y, original.minY + minHeight, bounds.maxY) }

            return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }

        let ratio = aspectRatio
        let isCorner = (isLeft || isRight) && (isTop || isBottom)
        let isHorizontalSide = edge == .left || edge == .right
        let isVerticalSide = edge == .top || edge == .bottom

        let horizontalWidthDelta = isLeft ? -translation.x : (isRight ? translation.x : 0)
        let verticalWidthDelta = isTop ? -translation.y * ratio : (isBottom ? translation.y * ratio : 0)
        // 四角按手指主导的轴响应；单边始终按对应轴响应。
        let widthDelta: CGFloat
        if isCorner {
            widthDelta = abs(horizontalWidthDelta) >= abs(verticalWidthDelta)
                ? horizontalWidthDelta : verticalWidthDelta
        } else {
            widthDelta = isHorizontalSide ? horizontalWidthDelta : verticalWidthDelta
        }

        let availableWidth: CGFloat
        let availableHeight: CGFloat
        if isCorner {
            availableWidth = isLeft ? original.maxX - bounds.minX : bounds.maxX - original.minX
            availableHeight = isTop ? original.maxY - bounds.minY : bounds.maxY - original.minY
        } else if isHorizontalSide {
            availableWidth = isLeft ? original.maxX - bounds.minX : bounds.maxX - original.minX
            availableHeight = 2 * min(original.midY - bounds.minY, bounds.maxY - original.midY)
        } else if isVerticalSide {
            availableWidth = 2 * min(original.midX - bounds.minX, bounds.maxX - original.midX)
            availableHeight = isTop ? original.maxY - bounds.minY : bounds.maxY - original.minY
        } else {
            return original
        }

        let maxAllowedWidth = min(availableWidth, availableHeight * ratio)
        guard maxAllowedWidth.isFinite, maxAllowedWidth > 0 else { return original }
        // 视口比最小裁剪尺寸更小时，以实际可用范围为准。
        let minAllowedWidth = min(maxAllowedWidth, max(minWidth, minHeight * ratio))
        let width = clamp(original.width + widthDelta, minAllowedWidth, maxAllowedWidth)
        let height = width / ratio

        let x: CGFloat
        let y: CGFloat
        if isLeft {
            x = original.maxX - width
        } else if isRight {
            x = original.minX
        } else {
            x = original.midX - width / 2
        }
        if isTop {
            y = original.maxY - height
        } else if isBottom {
            y = original.minY
        } else {
            y = original.midY - height / 2
        }

        let result = CGRect(x: x, y: y, width: width, height: height)
        guard result.minX >= bounds.minX - 0.001,
              result.minY >= bounds.minY - 0.001,
              result.maxX <= bounds.maxX + 0.001,
              result.maxY <= bounds.maxY + 0.001 else { return original }
        return result
    }

    /// 自动居中时以图片内容中的同一个点为锚，始终更新 offset（包括最大缩放倍率）。
    static func centeredContentOffset(
        focusInViewport: CGPoint,
        oldContentOffset: CGPoint,
        oldZoomScale: CGFloat,
        newZoomScale: CGFloat,
        newClipFrame: CGRect,
        contentSize: CGSize
    ) -> CGPoint {
        guard oldZoomScale.isFinite, oldZoomScale > 0,
              newZoomScale.isFinite, newZoomScale > 0,
              contentSize.width.isFinite, contentSize.height.isFinite,
              contentSize.width > 0, contentSize.height > 0 else { return oldContentOffset }

        let imageX = (focusInViewport.x + oldContentOffset.x) / oldZoomScale
        let imageY = (focusInViewport.y + oldContentOffset.y) / oldZoomScale
        let minX = -newClipFrame.minX
        let minY = -newClipFrame.minY
        let maxX = max(minX, contentSize.width - newClipFrame.maxX)
        let maxY = max(minY, contentSize.height - newClipFrame.maxY)
        return CGPoint(
            x: min(max(imageX * newZoomScale - newClipFrame.midX, minX), maxX),
            y: min(max(imageY * newZoomScale - newClipFrame.midY, minY), maxY)
        )
    }
}
