//
//  UIScrollView+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public extension PTPOP where Base : UIScrollView {
    
    @MainActor var visibleRect: CGRect {
        let contentWidth = base.contentSize.width - base.contentOffset.x
        let contentHeight = base.contentSize.height - base.contentOffset.y
        return CGRect(
            origin: base.contentOffset,
            size: CGSize(
                width: min(min(base.bounds.size.width, base.contentSize.width), contentWidth),
                height: min(min(base.bounds.size.height, base.contentSize.height), contentHeight)
            )
        )
    }
    
    enum Side {
        case top, bottom, left, right
    }
    
    @MainActor func scrollTo(_ side: Side, animated: Bool) {
        let point: CGPoint
        switch side {
        case .top:
            if base.contentSize.height < base.bounds.height { return }
            point = CGPoint(
                x: base.contentOffset.x,
                y: -(base.contentInset.top + base.safeAreaInsets.top)
            )
        case .bottom:
            if base.contentSize.height < base.bounds.height { return }
            point = CGPoint(
                x: base.contentOffset.x,
                y: max(0, base.contentSize.height - base.bounds.height) + base.contentInset.bottom + base.safeAreaInsets.bottom
            )
        case .left:
            point = CGPoint(x: -base.contentInset.left, y: base.contentOffset.y)
        case .right:
            point = CGPoint(x: max(0, base.contentSize.width - base.bounds.width) + base.contentInset.right, y: base.contentOffset.y)
        }
        base.setContentOffset(point, animated: animated)
    }
    
    //MARK: 根据偏移量和页数绘制
    ///根据偏移量和页数绘制
    /// 此方法为绘图，根据偏移量和页数可能会递归调用insideraw
    @MainActor private func snapShotContentScrollPage(index: Int,
                                           maxIndex: Int,
                                           callback: @escaping PTActionTask) {
        base.setContentOffset(CGPoint(x: 0, y: CGFloat(index) * base.frame.size.height), animated: false)
        let splitFrame = CGRect(x: 0, y: CGFloat(index) * base.frame.size.height, width: base.bounds.size.width, height: base.bounds.size.height)
        PTGCDManager.gcdAfter(time: 0.3) {
            Task { @MainActor in
                base.drawHierarchy(in: splitFrame, afterScreenUpdates: true)
                if index < maxIndex {
                    snapShotContentScrollPage(index: index + 1, maxIndex: maxIndex, callback: callback)
                } else {
                    callback()
                }
            }
        }
    }
    
    /// 获取 ScrollView 长截图
    /// - Parameter completionHandler: 截图完成后的回调，返回生成的 UIImage
    @MainActor
    func snapShotContentScroll(_ completionHandler: @escaping @MainActor @Sendable (_ screenShotImage: UIImage?) -> Void) {
        
        // 1. 安全解包：防止 snapshotView 为 nil 时引发强制解包崩溃
        guard let snapShotView = base.snapshotView(afterScreenUpdates: true) else {
            completionHandler(nil)
            return
        }
        
        // 2. 设置假封面的 frame 并添加到父视图
        snapShotView.frame = CGRect(
            x: base.frame.origin.x,
            y: base.frame.origin.y,
            width: snapShotView.frame.size.width,
            height: snapShotView.frame.size.height
        )
        base.superview?.addSubview(snapShotView)
        
        /// 记录初始的原点偏移
        let originOffset = base.contentOffset
        
        // 3. 安全防护：防止除以 0 的情况发生
        guard base.bounds.height > 0 else {
            snapShotView.removeFromSuperview()
            completionHandler(nil)
            return
        }
        
        // 4. 分页计算：使用 ceil 向上取整，确保即使最后不足一页也能被完整截取
        let page = Int(ceil(base.contentSize.height / base.bounds.height))
        
        /// 打开位图上下文，大小为 ScrollView 的真实内容大小
        UIGraphicsBeginImageContextWithOptions(base.contentSize, false, UIScreen.main.scale)
        
        /// 执行可能包含异步等待的递归绘图方法
        snapShotContentScrollPage(index: 0, maxIndex: page) {
            // 5. 确保结束操作和回调严格在主线程执行
            Task { @MainActor in
                // 从当前上下文获取拼接好的长图
                let screenShotImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext() // 切记关闭上下文，防止内存泄漏
                
                /// 恢复初始偏移量并移除假封面
                base.setContentOffset(originOffset, animated: false)
                snapShotView.removeFromSuperview()
                
                /// 通过回调返回图像
                completionHandler(screenShotImage)
            }
        }
    }

    @MainActor func scrolToLeftAnimation(animation:Bool) {
        var off = base.contentOffset
        off.x = 0 - base.contentInset.left
        base.setContentOffset(off, animated: true)
    }
}
