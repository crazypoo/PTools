//
//  WKWebView+PTSnapShot.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 14/11/2025.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit
import WebKit

extension WKWebView {
    
    // MARK: - SnapshotKitProtocol 实现
    
    public func wkTakeSnapshotOfVisibleContent(with configuration: SnapshotConfiguration) -> UIImage? {
        // WKWebView 的可见区域截图，必须使用 drawHierarchy，否则会出现白屏
        let format = UIGraphicsImageRendererFormat()
        format.scale = configuration.scale
        format.opaque = configuration.isOpaque || (self.isOpaque && self.layer.cornerRadius == 0)

        let renderer = UIGraphicsImageRenderer(bounds: self.bounds, format: format)
        return renderer.image { context in
            if let bgColor = self.backgroundColor {
                bgColor.setFill()
                context.fill(self.bounds)
            }
            self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        }
    }

    public func wkTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration) -> UIImage? {
        // 实例化我们刚刚升级过的打印渲染器
        let renderer = PTWebViewPrintPageRenderer(formatter: self.viewPrintFormatter(), contentSize: self.scrollView.contentSize)
        // 传入配置参数，生成高清长图
        let image = renderer.printContentToImage(with: configuration)
        return image
    }
    
    public func wkAsyncTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration, completion: @escaping ((UIImage?) -> Void)) {
        let originalOffset = self.scrollView.contentOffset

        // 【修复点】：将 floorf 替换为 ceil，确保如果存在半页内容也不会被漏掉
        let pageNum = Int(ceil(self.scrollView.contentSize.height / self.scrollView.bounds.height))

        // 预加载所有页面，触发前端的懒加载（Lazy Loading）策略
        self.loadPageContent(0, maxIndex: pageNum, completion: { [weak self] in
            guard let self = self else { return }
            
            self.scrollView.contentOffset = CGPoint.zero
            
            // 留出 0.5 秒时间给网页进行最终的 DOM 渲染和视图重排
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // UIPrintFormatter 必须在主线程获取和渲染
                let renderer = PTWebViewPrintPageRenderer(formatter: self.viewPrintFormatter(), contentSize: self.scrollView.contentSize)
                let image = renderer.printContentToImage(with: configuration)
                
                // 恢复原有的滚动位置并回调
                self.scrollView.contentOffset = originalOffset
                completion(image)
            }
        })
    }

    // MARK: - 私有辅助方法
    
    private func loadPageContent(_ index: Int, maxIndex: Int, completion: @escaping () -> Void) {
        // 滚动到指定区域以触发网页内的懒加载事件
        let yOffset = CGFloat(index) * self.scrollView.frame.size.height
        self.scrollView.setContentOffset(CGPoint(x: 0, y: yOffset), animated: false)
        
        // 延迟 1 秒，给网页内的 JS 懒加载脚本和网络图片请求留出时间
        // 注意：如果实际使用中网页图片很多且网络慢，这个时间可能还需要加大
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if index < maxIndex {
                self.loadPageContent(index + 1, maxIndex: maxIndex, completion: completion)
            } else {
                completion()
            }
        }
    }
}
