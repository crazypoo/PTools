//
//  UIImage+PTFaceAware.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 29/5/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
import Foundation
import Vision
import ObjectiveC

// 用于关联对象的安全 Key 存储（避免 Swift 6 全局变量并发警告）
private enum AssociatedKeys {
    @MainActor static var debugKey: Void?
    @MainActor static var closureKey: Void?
}

// 闭包包装器：用于在关联对象中安全存储 Swift 闭包
internal class FaceAwareClosureWrapper {
    var closure: () -> Void
    init(_ closure: @escaping () -> Void) {
        self.closure = closure
    }
}

@IBDesignable
@MainActor // 确保整个扩展均在主线程 actor 上安全运行
extension UIImageView {

    @IBInspectable
    /// 是否开启调试模式（会在检测到的人脸周围绘制红框）
    public var debugFaceAware: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.debugKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.debugKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    @IBInspectable
    /// 是否自动聚焦到人脸
    public var focusOnFaces: Bool {
        get {
            return sublayer() != nil
        }
        set {
            set(image: self.image, focusOnFaces: newValue)
        }
    }

    /// 聚焦完成后触发的回调闭包
    public var didFocusOnFaces: (() -> Void)? {
        get {
            let wrapper = objc_getAssociatedObject(self, &AssociatedKeys.closureKey) as? FaceAwareClosureWrapper
            return wrapper?.closure
        }
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(self, &AssociatedKeys.closureKey, FaceAwareClosureWrapper(newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else {
                objc_setAssociatedObject(self, &AssociatedKeys.closureKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }

    public func set(image: UIImage?, focusOnFaces: Bool) {
        guard focusOnFaces else {
            self.removeImageLayer(image: image)
            return
        }
        setImageAndFocusOnFaces(image: image)
    }

    private func setImageAndFocusOnFaces(image: UIImage?) {
        guard let image = image else { return }

        // 创建异步任务，自动继承当前的 @MainActor 上下文
        Task {
            // 1. 在后台线程进行高强度的人脸识别工作
            let faceRects = await self.detectFacesInBackground(image: image)
            
            // 2. 自动安全的返回主线程执行以下 UI 逻辑
            guard !faceRects.isEmpty else {
                if self.debugFaceAware { PTNSLogConsole("No faces found") }
                self.removeImageLayer(image: image)
                return
            }

            if self.debugFaceAware {
                PTNSLogConsole("Found \(faceRects.count) faces")
            }

            let imgSize = CGSize(width: image.cgImage?.width ?? 0, height: image.cgImage?.height ?? 0)
            guard imgSize.width > 0 && imgSize.height > 0 else { return }

            self.applyFaceDetection(for: faceRects, size: imgSize, image: image)
        }
    }

    /// 使用 nonisolated 确保该耗时方法在系统的全局协同线程池（后台）中运行，绝不卡顿UI
    nonisolated private func detectFacesInBackground(image: UIImage) async -> [CGRect] {
        guard let cgImage = image.cgImage else { return [] }
        
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            guard let results = request.results else { return [] }
            
            let width = CGFloat(cgImage.width)
            let height = CGFloat(cgImage.height)
            
            // 将 Vision 的归一化坐标（左下角为原点 0,0）转换为图层的像素坐标（左上角为原点 0,0）
            return results.map { face in
                let box = face.boundingBox
                let x = box.origin.x * width
                let y = (1.0 - box.origin.y - box.size.height) * height
                let w = box.size.width * width
                let h = box.size.height * height
                return CGRect(x: x, y: y, width: w, height: h)
            }
        } catch {
            return []
        }
    }

    private func applyFaceDetection(for faceRects: [CGRect], size: CGSize, image: UIImage) {
        // 将所有检测到的人脸区域合并为一个复合的大矩形
        var compoundRect = faceRects[0]
        for rect in faceRects.dropFirst() {
            compoundRect = compoundRect.union(rect)
        }

        var offset = CGPoint.zero
        var finalSize = size
        let boundsSize = self.bounds.size

        guard boundsSize.width > 0 && boundsSize.height > 0 else { return }

        // 核心对齐与裁剪算法（完全同步执行，杜绝竞态条件）
        if size.width / size.height > boundsSize.width / boundsSize.height {
            // 图片太宽：以高度为基准缩放，水平裁剪两侧
            let centerX = compoundRect.minX + compoundRect.width / 2.0
            finalSize.height = boundsSize.height
            finalSize.width = (size.width / size.height) * finalSize.height

            let scaledCenterX = (finalSize.width / size.width) * centerX
            offset.x = scaledCenterX - boundsSize.width * 0.5
            
            // 边界约束
            if offset.x < 0 {
                offset.x = 0
            } else if offset.x + boundsSize.width > finalSize.width {
                offset.x = finalSize.width - boundsSize.width
            }
            offset.x = -offset.x
        } else {
            // 图片太高：以宽度为基准缩放，垂直裁剪上下
            let centerY = compoundRect.minY + compoundRect.height / 2.0
            finalSize.width = boundsSize.width
            finalSize.height = (size.height / size.width) * finalSize.width

            let scaledCenterY = (finalSize.width / size.width) * centerY
            // 引入黄金比例进行微调偏移
            offset.y = scaledCenterY - boundsSize.height * (1.0 - 0.618)
            
            // 边界约束（已修复原版代码中破坏比例的 Bug）
            if offset.y < 0 {
                offset.y = 0
            } else if offset.y + boundsSize.height > finalSize.height {
                offset.y = finalSize.height - boundsSize.height
            }
            offset.y = -offset.y
        }

        // 判断是否需要绘制调试红框
        let finalImage: UIImage
        if self.debugFaceAware {
            finalImage = drawDebugRectangles(from: image, size: size, faceRects: faceRects)
        } else {
            finalImage = image
        }

        // 更新 UI 视图与图层
        self.image = finalImage
        let layer = self.imageLayer()
        layer.contents = finalImage.cgImage
        layer.frame = CGRect(origin: offset, size: finalSize)
        
        self.didFocusOnFaces?()
    }

    private func drawDebugRectangles(from image: UIImage, size: CGSize, faceRects: [CGRect]) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            image.draw(at: .zero)
            let ctx = context.cgContext
            ctx.setStrokeColor(UIColor.red.cgColor)
            ctx.setLineWidth(3)

            for rect in faceRects {
                ctx.addRect(rect)
                ctx.drawPath(using: .stroke)
            }
        }
    }

    private func imageLayer() -> CALayer {
        if let layer = sublayer() {
            return layer
        }

        let subLayer = CALayer()
        subLayer.name = "AspectFillFaceAware"
        subLayer.actions = ["contents": NSNull(), "bounds": NSNull(), "position": NSNull()]
        layer.addSublayer(subLayer)
        return subLayer
    }

    private func removeImageLayer(image: UIImage?) {
        self.sublayer()?.removeFromSuperlayer()
        self.image = image
    }

    private func sublayer() -> CALayer? {
        return layer.sublayers?.first { $0.name == "AspectFillFaceAware" }
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        if focusOnFaces {
            setImageAndFocusOnFaces(image: self.image)
        }
    }
}
