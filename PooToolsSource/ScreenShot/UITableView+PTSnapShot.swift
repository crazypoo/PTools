//
//  UITableView+PTSnapShot.swift.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 14/11/2025.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit

extension UITableView {
    
    // MARK: - 私有辅助：逐个获取元素截图 (接入了 UIView 的最新接口)
    
    private func takeSnapshotOfTableHeaderView(with configuration: SnapshotConfiguration) -> UIImage? {
        if let rect = self.tableHeaderView?.frame, rect.width > 0, rect.height > 0 {
            self.scrollRectToVisible(rect, animated: false)
            // 调用底层 UIView 刚刚优化过的带 configuration 参数的方法
            return self.takeSnapshotOfFullContent(for: rect, with: configuration)
        }
        return nil
    }

    private func takeSnapshotOfTableFooterView(with configuration: SnapshotConfiguration) -> UIImage? {
        if let rect = self.tableFooterView?.frame, rect.width > 0, rect.height > 0 {
            self.scrollRectToVisible(rect, animated: false)
            return self.takeSnapshotOfFullContent(for: rect, with: configuration)
        }
        return nil
    }

    private func takeSnapshotOfSectionHeaderView(at section: Int, with configuration: SnapshotConfiguration) -> UIImage? {
        let rect = self.rectForHeader(inSection: section)
        if rect.width > 0, rect.height > 0 {
            self.scrollRectToVisible(rect, animated: false)
            return self.takeSnapshotOfFullContent(for: rect, with: configuration)
        }
        return nil
    }

    private func takeSnapshotOfSectionFooterView(at section: Int, with configuration: SnapshotConfiguration) -> UIImage? {
        let rect = self.rectForFooter(inSection: section)
        if rect.width > 0, rect.height > 0 {
            self.scrollRectToVisible(rect, animated: false)
            return self.takeSnapshotOfFullContent(for: rect, with: configuration)
        }
        return nil
    }

    private func takeSnapshotOfCell(at indexPath: IndexPath, with configuration: SnapshotConfiguration) -> UIImage? {
        // 如果 Cell 不在可视范围内，先滚动到该位置触发渲染
        if self.indexPathsForVisibleRows?.contains(indexPath) == false {
            self.scrollToRow(at: indexPath, at: .top, animated: false)
        }
        let cell = self.cellForRow(at: indexPath)
        // Cell 本身也是 UIView，直接调用遵循协议的方法
        return cell?.takeSnapshotOfFullContent(with: configuration)
    }

    // MARK: - 内部图片采集与拼接逻辑
    
    // 拆分出专门用于主线程收集图片数组的方法
    private func internalCollectImages(with configuration: SnapshotConfiguration) -> [UIImage] {
        var shotImages: [UIImage] = []

        if let image = takeSnapshotOfTableHeaderView(with: configuration) {
            shotImages.append(image)
        }

        for section in 0..<self.numberOfSections {
            if let image = takeSnapshotOfSectionHeaderView(at: section, with: configuration) {
                shotImages.append(image)
            }

            let num = self.numberOfRows(inSection: section)
            for row in 0..<num {
                let indexPath = IndexPath(row: row, section: section)
                if let image = takeSnapshotOfCell(at: indexPath, with: configuration) {
                    shotImages.append(image)
                }
            }

            if let image = takeSnapshotOfSectionFooterView(at: section, with: configuration) {
                shotImages.append(image)
            }
        }

        if let image = takeSnapshotOfTableFooterView(with: configuration) {
            shotImages.append(image)
        }

        return shotImages
    }

    // MARK: - SnapshotKitProtocol 协议实现
    
    // 注意：如果在 UIView 扩展中已经加了 @objc 且不方便修改，这里的 override 请保留；
    // 否则直接实现协议方法即可。
    public func tableTakeSnapshotOfVisibleContent(with configuration: SnapshotConfiguration) -> UIImage? {
        var visibleRect = self.bounds
        visibleRect.origin = self.contentOffset
        return self.takeSnapshotOfFullContent(for: visibleRect, with: configuration)
    }

    public func tableTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration) -> UIImage? {
        let originalOffset = self.contentOffset
        
        // 1. 采集所有组件的截图
        let shotImages = self.internalCollectImages(with: configuration)
        self.setContentOffset(originalOffset, animated: false)
        
        guard !shotImages.isEmpty else { return nil }

        // 2. 计算总尺寸
        let totalHeight = shotImages.reduce(0) { $0 + $1.size.height }
        let totalSize = CGSize(width: self.bounds.width, height: totalHeight)

        // 3. 使用现代 API 同步拼接长图
        let format = UIGraphicsImageRendererFormat()
        format.scale = configuration.scale
        format.opaque = configuration.isOpaque
        
        let renderer = UIGraphicsImageRenderer(size: totalSize, format: format)
        return renderer.image { context in
            if let bgColor = self.backgroundColor {
                bgColor.setFill()
                context.fill(CGRect(origin: .zero, size: totalSize))
            }
            
            var imageOffsetFactor: CGFloat = 0
            for image in shotImages {
                image.draw(at: CGPoint(x: 0, y: imageOffsetFactor))
                imageOffsetFactor += image.size.height
            }
        }
    }

    public func tableAsyncTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration, completion: @escaping ((UIImage?) -> Void)) {
        // 真正的异步：主线程采集，后台拼接
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let originalOffset = self.contentOffset
            
            // 步骤 1：在主线程采集团素图片
            let images = self.internalCollectImages(with: configuration)
            self.setContentOffset(originalOffset, animated: false)
            
            guard !images.isEmpty else {
                completion(nil)
                return
            }
            
            // 步骤 2：在后台线程进行大图片拼接渲染，防止卡住主线程
            DispatchQueue.global(qos: .userInitiated).async {
                let totalHeight = images.reduce(0) { $0 + $1.size.height }
                let totalSize = CGSize(width: self.bounds.width, height: totalHeight)
                
                let format = UIGraphicsImageRendererFormat()
                format.scale = configuration.scale
                format.opaque = configuration.isOpaque
                
                let renderer = UIGraphicsImageRenderer(size: totalSize, format: format)
                let finalImage = renderer.image { context in
                    if let bgColor = self.backgroundColor {
                        bgColor.setFill()
                        context.fill(CGRect(origin: .zero, size: totalSize))
                    }
                    var offset: CGFloat = 0
                    for img in images {
                        img.draw(at: CGPoint(x: 0, y: offset))
                        offset += img.size.height
                    }
                }
                
                // 步骤 3：切回主线程回调
                DispatchQueue.main.async {
                    completion(finalImage)
                }
            }
        }
    }
}
