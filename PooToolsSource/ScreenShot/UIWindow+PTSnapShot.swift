//
//  UIWindow+PTSnapShot.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 14/11/2025.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit

extension UIWindow {
    override public func takeSnapshotOfVisibleContent() -> UIImage? {
        return self.takeSnapshotOfFullContent()
    }

    override public func takeSnapshotOfFullContent() -> UIImage? {
        let backgroundColor = self.backgroundColor ?? UIColor.white

        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, 0)

        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.setFillColor(backgroundColor.cgColor)
        context.setStrokeColor(backgroundColor.cgColor)

        // 使用 layer.render(in: context)的方式生成截图时，在iOS 8.0下，UIWindow展示的是WKWebView时，WKWebView区域的内容是一片空白
        // 使用 drawHierarchy 则无此问题
        self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    override public func asyncTakeSnapshotOfFullContent(_ completion: @escaping ((UIImage?) -> Void)) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            let image = self.takeSnapshotOfFullContent()
            completion(image)
        }
    }
}
