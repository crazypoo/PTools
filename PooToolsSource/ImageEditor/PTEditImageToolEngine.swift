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
import AVFoundation
import Vision

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
        // 利用协议自带的属性进行运算
        let originalRatio = min(engineScrollView.frame.width / engineOriginalImageSize.width, engineScrollView.frame.height / engineOriginalImageSize.height)
        let ratio = min(engineScrollView.frame.width / engineEditRect.width, engineScrollView.frame.height / engineEditRect.height)
        let scale = ratio / originalRatio
        
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
        
        // 1. 创建离屏的 TextView
        // ⚠️ 注意：如果你的 getRawTextRects 是定义在特定的子类中（例如 PTInputTextView），请将 UITextView 替换为你的子类。
        let textView = UITextView(frame: CGRect(x: 0, y: 0, width: maxWidth, height: 10000))
        
        // 2. 基础配置：去除内边距，确保和输入界面的排版引擎行为一致
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        
        // 3. 应用新的文字属性
        textView.text = text
        textView.font = font
        textView.textColor = textColor
        
        // 4. 应用你的 style (如果有对齐方式、行间距等，请在这里配置)
        // 例如：textView.textAlignment = style.alignment 等，根据你的实际业务逻辑补充
        
        // 5. 强制系统立刻进行文字排版计算，产生真实的 Rect 坐标
        textView.layoutIfNeeded()
        
        // --- 👇 下面完全复用你提供的核心渲染逻辑 👇 ---
        var image: UIImage?
        
        if let currentText = textView.text, !currentText.isEmpty {
            // 获取所有的文字精准坐标块
            let rawRects = textView.getRawTextRects()
            
            if !rawRects.isEmpty {
                // 计算所有文字块的并集，得出最终的精准包围盒 (Bounding Box)
                var contentRect = rawRects[0]
                for r in rawRects {
                    contentRect = contentRect.union(r)
                }
                
                if style.outputWithTextViewBound {
                    contentRect.origin.x = 0
                    contentRect.size.width = textView.bounds.width
                }
                
                // 开启画板，尺寸完美贴合文字
                image = UIGraphicsImageRenderer.pt.renderImage(size: contentRect.size) { context in
                    // 🌟 核心魔法：将上下文原点反向平移！
                    // 把包围盒的左上角平移到 (0,0) 位置，确保文字完美居中且不被裁剪
                    context.translateBy(x: -contentRect.minX, y: -contentRect.minY)
                    
                    // 将包含文字和彩色背景块的整个 Layer 渲染进去
                    textView.layer.render(in: context)
                }
            }
        }
        
        return image
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
    private var impactFeedback: UIImpactFeedbackGenerator?
    static let maxDrawLineImageWidth: CGFloat = 600
    
    /// 手势交互状态改变回调 (传回 true 代表开始交互，VC 需隐藏工具栏；false 则显示)
    public var onInteractStateChanged: ((Bool) -> Void)?
    
    // MARK: - 生命周期
    @MainActor
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
    // MARK: - 具体手势实现: 绘制
    
    public func handlePanGesture(_ pan: UIPanGestureRecognizer) {
        guard let context = context else { return }
        let point = pan.location(in: drawingImageView)
        
        // 🌟 核心：一行代码拿到所有复杂的数学计算结果！
        let metrics = context.calculateCanvasMetrics(currentViewSize: drawingImageView.frame.size)
        
        if pan.state == .began {
            onInteractStateChanged?(true)
            impactFeedback?.prepare()
            
            // 计算真实线宽 (橡皮擦模式 vs 普通画笔)
            let strokeWidth = PTImageEditorConfig.share.drawLineWidth / context.engineScrollView.zoomScale
            let actualWidth = isEraserMode ? (44.0 / context.engineScrollView.zoomScale) : strokeWidth
            
            let path = PTDrawPath(
                pathColor: isEraserMode ? .clear : drawColor,
                pathWidth: actualWidth,
                ratio: metrics.ratio / metrics.originalRatio / metrics.toImageScale,
                startPoint: point
            )
            path.isEraser = isEraserMode
            drawPaths.append(path)
            
            if isEraserMode {
                context.engineEraserCircleView.isHidden = false
                // 🌟 一行代码拿到橡皮擦矩阵
                let transform = context.calculateEraserTransform(viewTransform: drawingImageView.transform, viewSize: drawingImageView.frame.size)
                context.engineEraserCircleView.center = point.applying(transform)
                impactFeedback?.impactOccurred()
            }
            
        } else if pan.state == .changed {
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
            if let path = drawPaths.last {
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
        
        drawingImageView.image = UIGraphicsImageRenderer.pt.renderImage(size: renderSize) { renderContext in
            renderContext.setAllowsAntialiasing(true)
            renderContext.setShouldAntialias(true)
            for path in self.drawPaths {
                path.drawPath()
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
    private var impactFeedback: UIImpactFeedbackGenerator?
    public var onInteractStateChanged: ((Bool) -> Void)?
    
    public init(context: PTEditImageEngineContext) {
        self.context = context
        super.init()
        if PTImageEditorConfig.share.tools.contains(.mosaic) {
            impactFeedback = UIImpactFeedbackGenerator(style: .light)
        }
    }
    
    public func toolDidActivate() {
        guard let context = context else { return }
        
        // 1. 生成全屏马赛克底图 (只生成一次)
        let baseImage = context.engineCurrentEditImage
        mosaicImageView.image = baseImage.pt.mosaicImage()
        
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
        drawMask()
    }
    
    // MARK: - 手势路由与实现
    public func handlePanGesture(_ pan: UIPanGestureRecognizer) {
        guard let context = context else { return }
        let point = pan.location(in: mosaicContainerView)
        
        // 🌟 核心：一行代码拿到所有复杂的数学计算结果！
        let metrics = context.calculateCanvasMetrics(currentViewSize: mosaicContainerView.frame.size)
        
        if pan.state == .began {
            onInteractStateChanged?(true)
            impactFeedback?.prepare()
            
            // 计算真实线宽 (橡皮擦模式 vs 马赛克画笔)
            let strokeWidth = PTImageEditorConfig.share.mosaicLineWidth / context.engineScrollView.zoomScale
            let actualWidth = isEraserMode ? (44.0 / context.engineScrollView.zoomScale) : strokeWidth
            
            let path = PTDrawPath(
                pathColor: .black, // Mask 中黑色代表不透明（显示马赛克）
                pathWidth: actualWidth,
                ratio: metrics.ratio / metrics.originalRatio / metrics.toImageScale,
                startPoint: point
            )
            path.isEraser = isEraserMode // 标记身份
            mosaicPaths.append(path)
            
            if isEraserMode {
                context.engineEraserCircleView.isHidden = false
                // 🌟 一行代码拿到橡皮擦矩阵
                let transform = context.calculateEraserTransform(viewTransform: mosaicContainerView.transform, viewSize: mosaicContainerView.frame.size)
                context.engineEraserCircleView.center = point.applying(transform)
                impactFeedback?.impactOccurred()
            }
            
        } else if pan.state == .changed {
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
            
            if let path = mosaicPaths.last {
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
        
        // 将路径渲染为一张带透明度的图片，交给 maskImageView
        maskImageView.image = UIGraphicsImageRenderer.pt.renderImage(size: renderSize) { renderContext in
            renderContext.setAllowsAntialiasing(true)
            renderContext.setShouldAntialias(true)
            for path in self.mosaicPaths {
                path.drawPath() // 会自动处理普通画笔(.normal)和橡皮擦(.clear)的混合模式
            }
        }
    }

    public func updateBaseMosaicImage(_ newBaseImage: UIImage) {
        // 重新生成打好马赛克的全屏底图
        mosaicImageView.image = newBaseImage.pt.mosaicImage()
    }
}

public class PTStickerEngine: NSObject, PTEditImageToolEngine {
    
    // MARK: - 核心视图与状态
    
    public var canvasView: UIView { stickersContainer }
    
    private lazy var stickersContainer: PTPassthroughView = {
        let view = PTPassthroughView()
        view.backgroundColor = .clear
        view.clipsToBounds = false // 允许贴纸部分拖出边界
        return view
    }()
    
    private weak var context: PTEditImageEngineContext?
    private var preStickerState: PTBaseStickertState?
    
    /// 交互状态回调 (用于隐藏/显示主工具栏)
    public var onInteractStateChanged: ((Bool) -> Void)?
    /// 贴纸点击回调
    public var onStickerTapped: ((PTBaseStickerView) -> Void)?
    
    public var currentSelectedSticker: PTBaseStickerView?

    public var onRequestImageSelection: ((_ completion: @escaping (UIImage?) -> Void) -> Void)?
    public var onProcessingStateChanged: ((Bool) -> Void)?
    
    // MARK: - 生命周期
    public init(context: PTEditImageEngineContext) {
        self.context = context
        super.init()
    }
    
    public func toolDidActivate() {
        // 贴纸工具其实是一个“触发器”，激活逻辑交由 VC 处理
    }
    
    public func toolDidDeactivate() {
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
    }
    
    /// 根据 ID 移除对应的贴纸
    private func removeSticker(id: String?) {
        guard let id = id else { return }
        for sticker in stickersContainer.subviews.reversed() {
            guard let stickerView = sticker as? PTBaseStickerView, stickerView.id == id else { continue }
            stickerView.moveToAshbin()
            if currentSelectedSticker === stickerView {
                currentSelectedSticker = nil
            }
            break
        }
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
        let size = PTTextStickerView.calculateSize(image: image,maxLimitSize:maxLimitSize)
        let originFrame = PTBaseStickerView.getStickerOriginFrame(size, current: context, container: stickersContainer)
        
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
        guard mainViewBounds.width > 0, mainViewBounds.height > 0 else { return }
        
        let maxLimitSize = CGSize(width: mainViewBounds.width * 0.5, height: mainViewBounds.height * 0.5)
        let targetSize = PTImageStickerView.calculateSize(image: image, maxLimitSize: maxLimitSize)
        let originFrame = PTBaseStickerView.getStickerOriginFrame(targetSize, current: context, container: stickersContainer)
        
        let imageSticker = PTImageStickerView(
            image: image, originScale: 1.0 / currentZoomScale, originAngle: -context.engineCurrentAngle, originFrame: originFrame
        )
        addSticker(imageSticker)
        context.engineEditorManager.storeAction(.imageSticker(oldState: nil, newState: imageSticker.state))
    }

    public func removeBackgroundForSelectedSticker() {
        guard let imageSticker = currentSelectedSticker as? PTImageStickerView else { return }
        let originalImage = imageSticker.image
        let oldState = imageSticker.state
        
        onProcessingStateChanged?(true)
        Task {
            do {
                if let cutoutImage = try await performForegroundMasking(on: originalImage) {
                    await MainActor.run {
                        UIView.transition(with: imageSticker, duration: 0.35, options: .transitionCrossDissolve) {
                            imageSticker.image = cutoutImage
                        }
                        let maxLimitSize = CGSize(width: (self.context?.engineMainView.bounds.width ?? 0) * 0.5, height: (self.context?.engineMainView.bounds.height ?? 0) * 0.5)
                        let newSize = PTImageStickerView.calculateSize(image: cutoutImage, maxLimitSize: maxLimitSize)
                        imageSticker.changeSize(to: newSize)
                        self.context?.engineEditorManager.storeAction(.imageSticker(oldState: oldState, newState: imageSticker.state))
                        self.onProcessingStateChanged?(false)
                    }
                } else {
                    await MainActor.run { self.onProcessingStateChanged?(false) }
                }
            } catch {
                await MainActor.run { self.onProcessingStateChanged?(false) }
            }
        }
    }

    private func performForegroundMasking(on inputImage: UIImage) async throws -> UIImage? {
        guard let cgImage = inputImage.cgImage else { return nil }
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
        return UIImage(cgImage: outputCGImage, scale: inputImage.scale, orientation: inputImage.imageOrientation)
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
        
        // 为了确保能“铺满”且不被裁剪（Aspect Fit 逻辑），取宽高比中较小的值作为目标缩放倍数。
        // 💡 如果你希望的是强制填满不留白边（Aspect Fill，可能会裁剪部分贴纸内容），请把 min 改成 max。
        let targetScaleX = mainViewBounds.width / baseWidthInMainView
        let targetScaleY = mainViewBounds.height / baseHeightInMainView
        let targetGesScale = min(targetScaleX, targetScaleY)
        
        // 计算从当前缩放到目标缩放，还需要乘多少倍
        let currentScale = max(0.01, sticker.gesScale) // 限制下限，避免除以0
        let scaleMultiplier = targetGesScale / currentScale
        
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
        ashbinView.isHidden = false
        
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
                
        onInteractStateChanged?(false)
        
        let ashbinView = context.engineAshbinView
        ashbinView.layer.removeAllAnimations()
        ashbinView.isHidden = true
        
        var endState: PTBaseStickertState? = sticker.state
        let point = panGes.location(in: context.engineMainView)
        
        if ashbinView.frame.contains(point) {
            sticker.moveToAshbin()
            endState = nil
        }
        
        // 🌟 智能区分：存入对应类型的撤销栈记录
        if sticker is PTTextStickerView {
            context.engineEditorManager.storeAction(.sticker(oldState: preStickerState, newState: endState))
        } else {
            context.engineEditorManager.storeAction(.imageSticker(oldState: preStickerState, newState: endState))
        }
        preStickerState = nil
        
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
        showInputTextVC(text, textColor: textSticker.textColor, font: textSticker.font, style: textSticker.style) { [weak self] text, textColor, font, image, style in
            guard let self = self, let image = image, !text.isEmpty else {
                textSticker.moveToAshbin()
                return
            }
            textSticker.startTimer()
            guard textSticker.text != text || textSticker.textColor != textColor || textSticker.style != style else { return }
            guard let context = self.context else { return }
            
            let maxWidth = context.engineMainView.bounds.width
            let maxLimitSize = CGSize(width: maxWidth * 0.5, height: context.engineMainView.bounds.height * 0.5)
            
            textSticker.text = text
            textSticker.textColor = textColor
            textSticker.font = font
            textSticker.style = style
            textSticker.image = image
            textSticker.changeSize(to: PTTextStickerView.calculateSize(image: image, maxLimitSize: maxLimitSize))
        }
    }
    
    public func sticker(_ imageSticker: PTImageStickerView, editImage currentImage: UIImage) {
        onRequestImageSelection? { [weak self, weak imageSticker] newImage in
            guard let self = self, let imageSticker = imageSticker, let newImage = newImage else { return }
            imageSticker.startTimer()
            imageSticker.image = newImage
            
            let currentScale = max(1.0, imageSticker.gesScale)
            let maxWidth = self.context?.engineMainView.bounds.width ?? UIScreen.main.bounds.width
            let maxHeight = self.context?.engineMainView.bounds.height ?? UIScreen.main.bounds.height
            
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
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.preAdjustStatus = self.currentAdjustStatus
            }
        }
        
        adjustSlider.valueChanged = { [weak self] value in
            self?.adjustValueChanged(value)
        }
        
        adjustSlider.endAdjust = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self, let context = self.context else { return }
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
        Task { @MainActor in
            // 使用缓存的参考底图进行渲染，如果没有则降级使用未 adjustment 的图
            let baseImage = editImageAdjustRef ?? context.engineImageWithoutAdjust
            
            if let image = adjustFilterValueSet(filterImage: baseImage) {
                context.engineUpdateEditImage(image) // 把渲染好的结果还给 VC
            }
        }
    }
    
    // MARK: - Harbeth 滤镜渲染核心
    @MainActor
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
    @MainActor
    public func generateFilterThumbnails() async {
        guard let context = context, let thumbnailImage = context.engineThumbnailImage else { return }
        
        let filters = PTImageEditorConfig.share.filters
        
        // 1. Task.detached 将繁重任务踢到后台
        let thumbnails = await Task.detached(priority: .userInitiated) {
            
            // 🚀 修复核心：使用 withTaskGroup 安全地管理并发任务并收集结果
            // 声明返回类型为 (Int, UIImage?)，Int 用于记录初始索引以保证排序
            return await withTaskGroup(of: (Int, UIImage?).self) { group in
                
                for (index, filter) in filters.enumerated() {
                    group.addTask {
                        // ⚠️ 注意：如果 PTHarBethFilter 单例必须在主线程修改，这里保留 MainActor.run。
                        // 但如果你发现应用依然卡顿，说明图片处理并未真正放到后台，
                        // 后续建议将 PTHarBethFilter 的设计改为支持非主线程实例调用。
                        let image = await MainActor.run {
                            PTHarBethFilter.share.texureSize = thumbnailImage.size
                            return filter.getCurrentFilterImage(image: thumbnailImage)
                        }
                        return (index, image)
                    }
                }
                
                // 安全地收集所有子任务的结果
                var unorderedResults: [(Int, UIImage)] = []
                
                // for await 会等待 group 中的任务一个个完成，并将结果安全地（无数据竞争）追加到数组中
                for await (index, image) in group {
                    if let img = image {
                        unorderedResults.append((index, img))
                    }
                }
                
                // 按照初始的 filters 顺序对结果进行重排
                unorderedResults.sort { $0.0 < $1.0 }
                
                // 剥离索引，只返回纯图片数组
                return unorderedResults.map { $1 }
            }
        }.value
        
        // 2. 方法本身已经是 @MainActor，直接更新属性，UI 绝对安全
        self.thumbnailFilterImages = thumbnails
    }
    
    /// 切换滤镜
    public func changeFilter(_ filter: PTHarBethFilter) {
        guard let context = context else { return }
        Task { @MainActor in
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
    
    @MainActor public func handlePanGesture(_ pan: UIPanGestureRecognizer, in view: UIView) {
        let point = pan.location(in: view)
        
        if pan.state == .began {
            self.onInteractStateChanged?(true)
            self.beginPanPoint = point
            self.clipOriginFrame = self.clipBoxFrame
            self.panEdge = self.calculatePanEdge(at: point)
        } else if pan.state == .changed {
            guard self.panEdge != .none else { return }
            self.updateClipBoxFrame(point: point)
        } else if pan.state == .cancelled || pan.state == .ended {
            self.panEdge = .none
            self.onInteractStateChanged?(false)
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
        onClipBoxFrameChanged?(frame)
    }
}
