//
//  PSecurityStrategy.swift
//  Diou
//
//  Created by ken lam on 2021/10/9.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit

public let effectTag = 19999

@objcMembers
public class PSecurityStrategy: NSObject {
    
    // 动态获取当前活跃的 KeyWindow (适配 iOS 13+ 且更安全)
    private class var keyWindow: UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    class public func addBlurEffect() {
        DispatchQueue.main.async { // 替换为你自己封装的 PTGCDManager.gcdMain
            guard let window = self.keyWindow else { return }
            
            // 如果已经存在，避免重复添加
            if window.viewWithTag(effectTag) != nil { return }
            
            // 1. 创建截图 ImageView
            let imageView = UIImageView(frame: window.bounds)
            imageView.tag = effectTag
            imageView.contentMode = .scaleAspectFill
            imageView.image = screenShot()
            
            // 2. 将高斯模糊视图直接盖在 ImageView 上
            let blurView = SSBlurView(frame: imageView.bounds)
            blurView.style = .extraLight
            imageView.addSubview(blurView)
            
            // 3. 添加到 Window
            window.addSubview(imageView)
            
            // 4. 执行模糊动画
            blurView.enable(animated: true)
        }
    }
    
    class public func removeBlurEffect() {
        DispatchQueue.main.async {
            guard let window = self.keyWindow,
                  let effectView = window.viewWithTag(effectTag) else {
                return
            }
            
            UIView.animate(withDuration: 0.2, animations: {
                effectView.alpha = 0
            }) { _ in
                effectView.removeFromSuperview()
            }
        }
    }
    
    class public func screenShot() -> UIImage? {
        guard let window = self.keyWindow else { return nil }
        
        // 使用现代的 UIGraphicsImageRenderer，性能更好，自动处理 Scale 和广色域
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let image = renderer.image { context in
            // drawHierarchy 比 layer.render(in:) 在截取含 UIVisualEffectView 等视图时更准确、更快速
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
        }
        return image
    }
}
