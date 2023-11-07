//
//  UIScrollView+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public extension PTPOP where Base : UIScrollView {
    
    var visibleRect: CGRect {
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
    
    func scrollTo(_ side: Side, animated: Bool) {
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
    private func snapShotContentScrollPage(index: Int,
                                           maxIndex: Int,
                                           callback: @escaping PTActionTask) {
        base.setContentOffset(CGPoint(x: 0, y: CGFloat(index) * base.frame.size.height), animated: false)
        let splitFrame = CGRect(x: 0, y: CGFloat(index) * base.frame.size.height, width: base.bounds.size.width, height: base.bounds.size.height)
        PTGCDManager.gcdAfter(time: 0.3) {
            base.drawHierarchy(in: splitFrame, afterScreenUpdates: true)
            if index < maxIndex {
                snapShotContentScrollPage(index: index + 1, maxIndex: maxIndex, callback: callback)
            } else {
                callback()
            }
        }
    }
    
    //MARK: 获取ScrollView的contentScroll长图像
    /// 获取ScrollView的contentScroll长图像
    /// - Parameters:
    ///  - completionHandler: 获取闭包
    func snapShotContentScroll(_ completionHandler: @escaping (_ screenShotImage: UIImage?) -> Void) {
        /// 放一个假的封面
        let snapShotView = base.snapshotView(afterScreenUpdates: true)
        snapShotView?.frame = CGRect(x: base.frame.origin.x, y: base.frame.origin.y, width: (snapShotView?.frame.size.width)!, height: (snapShotView?.frame.size.height)!)
        base.superview?.addSubview(snapShotView!)
        ///  基的原点偏移
        let originOffset = base.contentOffset
        /// 分页
        let page  = floorf(Float(base.contentSize.height / base.bounds.height))
        /// 打开位图上下文大小为截图的大小
        UIGraphicsBeginImageContextWithOptions(base.contentSize, false, UIScreen.main.scale)
        /// 这个方法是一个绘图，里面可能有递归调用
        snapShotContentScrollPage(index: 0, maxIndex: Int(page)) {
            let screenShotImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            /// 设置原点偏移
            base.setContentOffset(originOffset, animated: false)
            snapShotView?.removeFromSuperview()
            /// 获取 snapShotContentScroll 时的回调图像
            completionHandler(screenShotImage)
        }
    }
    
    func scrolToLeftAnimation(animation:Bool) {
        var off = base.contentOffset
        off.x = 0 - base.contentInset.left
        base.setContentOffset(off, animated: true)
    }
}
