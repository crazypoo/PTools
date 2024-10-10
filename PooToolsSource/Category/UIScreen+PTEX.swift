//
//  UIScreen+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 9/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

extension UIScreen: PTProtocolCompatible {}

public enum UIScreenShotType {
    case Normal
    case Video
}

public extension UIScreen {
    
    //MARK: 獲取屏幕的Size
    /// 獲取屏幕的Size
    static var size: CGSize {
        UIScreen.main.bounds.size
    }
    
    //MARK: 獲取豎屏的尺寸
    ///獲取豎屏的尺寸
    static var portraitSize: CGSize {
        CGSize(width: UIScreen.main.nativeBounds.width / UIScreen.main.nativeScale,
                height: UIScreen.main.nativeBounds.height / UIScreen.main.nativeScale)
    }
    
    static var hasRoundedCorners = UIScreen.main.value(forKey: "_" + "display" + "Corner" + "Radius") as! CGFloat > 0
    
}

public extension PTPOP where Base: UIScreen {
    // MARK: 截屏或者录屏通知
    /// 截屏或者录屏通知
    /// - Parameter action: 事件
    static func detectScreenShot(_ action: @escaping (UIScreenShotType) -> Void) {
        let mainQueue = OperationQueue.main
        NotificationCenter.default.addObserver(forName: UIApplication.userDidTakeScreenshotNotification, object: nil, queue: mainQueue) { _ in
            action(UIScreenShotType.Normal)
        }
        //监听录屏通知,iOS 11后才有录屏
        //如果正在捕获此屏幕（例如，录制、空中播放、镜像等），则为真
        if UIScreen.main.isCaptured {
            action(UIScreenShotType.Video)
        }
        //捕获的屏幕状态发生变化时,会发送UIScreenCapturedDidChange通知,监听该通知
        NotificationCenter.default.addObserver(forName: UIScreen.capturedDidChangeNotification, object: nil, queue: mainQueue) { _ in
            action(UIScreenShotType.Video)
        }
    }
}
