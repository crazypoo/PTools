//
//  UIScrollView+PTSnapShot.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 14/11/2025.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit

extension UIScrollView {

    // MARK: - SnapshotKitProtocol 实现 (覆盖 UIView 的默认实现)

    public func scrollTakeSnapshotOfVisibleContent(with configuration: SnapshotConfiguration) -> UIImage? {
        // 获取当前可视区域的 rect
        var visibleRect = self.bounds
        visibleRect.origin = self.contentOffset

        // 直接复用我们在 UIView 中写好的高精度局部截图逻辑
        return self.takeSnapshotOfFullContent(for: visibleRect, with: configuration)
    }

    public func scrollTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration) -> UIImage? {
        let originalFrame = self.frame
        let originalOffset = self.contentOffset

        // 展开 Frame 以显示完整内容
        self.frame = CGRect(origin: originalFrame.origin, size: self.contentSize)
        self.contentOffset = .zero

        // 使用现代的 UIGraphicsImageRenderer API
        let format = UIGraphicsImageRendererFormat()
        format.scale = configuration.scale
        format.opaque = configuration.isOpaque || (self.isOpaque && self.layer.cornerRadius == 0)

        let renderer = UIGraphicsImageRenderer(size: self.contentSize, format: format)
        let backgroundColor = self.backgroundColor ?? UIColor.white

        let image = renderer.image { context in
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: self.contentSize))
            // 绘制层次结构
            self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        }

        // 恢复原始状态
        self.frame = originalFrame
        self.contentOffset = originalOffset

        return image
    }

    public func scrollAsyncTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration, completion: @escaping ((UIImage?) -> Void)) {
        let originalOffset = self.contentOffset

        // 【修复】使用 ceil 向上取整，保证剩余不足一页的内容也能被截取到
        let pageNum = Int(ceil(self.contentSize.height / self.bounds.height))

        guard pageNum > 0 else {
            completion(nil)
            return
        }

        // 开始递归采集每一页的截图图片
        self.drawScreenshotOfPageContent(0, maxIndex: pageNum, configuration: configuration, collectedImages: []) { [weak self] images in
            guard let self = self else { return }
            
            // 恢复原始偏移量
            self.contentOffset = originalOffset

            // 将耗时的图片拼接操作放到后台线程执行
            DispatchQueue.global(qos: .userInitiated).async {
                let totalSize = self.contentSize
                let format = UIGraphicsImageRendererFormat()
                format.scale = configuration.scale
                format.opaque = configuration.isOpaque || (self.isOpaque && self.layer.cornerRadius == 0)

                let renderer = UIGraphicsImageRenderer(size: totalSize, format: format)
                let backgroundColor = self.backgroundColor ?? UIColor.white

                let finalImage = renderer.image { context in
                    backgroundColor.setFill()
                    context.fill(CGRect(origin: .zero, size: totalSize))

                    var currentY: CGFloat = 0
                    for img in images {
                        img.draw(at: CGPoint(x: 0, y: currentY))
                        currentY += img.size.height
                    }
                }

                // 切回主线程通过闭包返回最终生成的长图
                DispatchQueue.main.async {
                    completion(finalImage)
                }
            }
        }
    }

    // MARK: - 私有辅助方法：递归截取单页并收集

    private func drawScreenshotOfPageContent(_ index: Int, maxIndex: Int, configuration: SnapshotConfiguration, collectedImages: [UIImage], completion: @escaping ([UIImage]) -> Void) {
        
        // 结束条件：已截取完所有页
        if index >= maxIndex {
            completion(collectedImages)
            return
        }

        // 滚动到当前需要截取的页
        let yOffset = CGFloat(index) * self.bounds.size.height
        self.setContentOffset(CGPoint(x: 0, y: yOffset), animated: false)

        // 延迟 0.3 秒，等待渲染（特别是网络图片、动效等）完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            var currentImages = collectedImages
            
            // 直接利用我们在 UIView 中写好的 takeSnapshotOfFullContent(for:with:) 截取当前 bounds
            if let pageImage = self.takeSnapshotOfFullContent(for: self.bounds, with: configuration) {
                currentImages.append(pageImage)
            }

            // 递归截取下一页
            self.drawScreenshotOfPageContent(index + 1, maxIndex: maxIndex, configuration: configuration, collectedImages: currentImages, completion: completion)
        }
    }
}
