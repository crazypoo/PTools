//
//  UIScrollView+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public extension PTProtocol where Base : UIScrollView
{
    //MARK: 根据偏移量和页数绘制
    ///根据偏移量和页数绘制
    /// 此方法为绘图，根据偏移量和页数可能会递归调用insideraw
    private func snapShotContentScrollPage(index: Int, maxIndex: Int, callback: @escaping () -> Void) {
        self.base.setContentOffset(CGPoint(x: 0, y: CGFloat(index) * self.base.frame.size.height), animated: false)
        let splitFrame = CGRect(x: 0, y: CGFloat(index) * self.base.frame.size.height, width: base.bounds.size.width, height: base.bounds.size.height)
        PTGCDManager.gcdAfter(time: 0.3) {
            self.base.drawHierarchy(in: splitFrame, afterScreenUpdates: true)
            if index < maxIndex {
                self.snapShotContentScrollPage(index: index + 1, maxIndex: maxIndex, callback: callback)
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
        let snapShotView = self.base.snapshotView(afterScreenUpdates: true)
        snapShotView?.frame = CGRect(x: self.base.frame.origin.x, y: self.base.frame.origin.y, width: (snapShotView?.frame.size.width)!, height: (snapShotView?.frame.size.height)!)
        self.base.superview?.addSubview(snapShotView!)
        ///  基的原点偏移
        let originOffset = self.base.contentOffset
        /// 分页
        let page  = floorf(Float(self.base.contentSize.height / self.base.bounds.height))
        /// 打开位图上下文大小为截图的大小
        UIGraphicsBeginImageContextWithOptions(self.base.contentSize, false, UIScreen.main.scale)
        /// 这个方法是一个绘图，里面可能有递归调用
        self.snapShotContentScrollPage(index: 0, maxIndex: Int(page), callback: { () -> Void in
            let screenShotImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            /// 设置原点偏移
            self.base.setContentOffset(originOffset, animated: false)
            snapShotView?.removeFromSuperview()
            /// 获取 snapShotContentScroll 时的回调图像
            completionHandler(screenShotImage)
        })
    }

}
