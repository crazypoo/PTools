//
//  PTImagePageControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 22/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Foundation

public typealias ImagePageControlBlock = (_ sender: PTImagePageControl) -> Void

@objcMembers
open class PTImagePageControl: PTBasePageControl {
    
    private var previousPage: Int = 0
    
    // MARK: - Appearance (Dot 图片属性)
    
    public var currentPageImage: Any = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "lldotInActive") {
        didSet { updateDots() }
    }
    public var pageImage: Any = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "lldotActive") {
        didSet { updateDots() }
    }
    
    public var dotBaseSize: CGSize = CGSize(width: 8, height: 4) {
        didSet { updateLayout() }
    }

    private var dots: [UIImageView] = []
    private var dotSizes: [CGSize] = []

    // MARK: - 重写基类模板方法
    
    override open func updateNumberOfPages(_ count: Int) {
        dots.forEach { $0.removeFromSuperview() }
        dots.removeAll()
        dotSizes.removeAll()

        guard count > 0 else {
            updateLayout()
            return
        }

        for i in 0..<count {
            let dot = UIImageView()
            dot.contentMode = .scaleAspectFit
            
            dotSizes.append(dotBaseSize)
            
            dot.loadImage(contentData: pageImage, loadFinish: { [weak self] value in
                guard let self = self else { return }
                if let imageSize = value.firstImage?.size {
                    self.dotSizes[i] = imageSize
                    self.updateLayout()
                }
            })
            
            if let image = pageImage as? UIImage {
                dotSizes[i] = image.size
            }
            
            addSubview(dot)
            dots.append(dot)
        }

        updateDots()
    }

    override open func updateProgress(_ safeProgress: CGFloat) {
        let newPage = Int(round(safeProgress))
        
        if newPage != previousPage {
            previousPage = newPage
            updateDots()
        }
    }
    
    override open func updateLayout() {
        guard pageCount > 0, dots.count == pageCount else { return }
        
        let totalWidth = dotSizes.reduce(0) { $0 + $1.width } + CGFloat(max(0, pageCount - 1)) * indicatorPadding
        
        var startX = getStartX(totalWidth: totalWidth)
        let centerY = bounds.height / 2

        for (index, dot) in dots.enumerated() {
            let size = dotSizes[index]
            dot.frame = CGRect(x: startX, y: centerY - size.height / 2, width: size.width, height: size.height)
            startX += size.width + indicatorPadding
        }
    }

    // MARK: - 私有方法
    
    private func updateDots() {
        guard dots.count == pageCount else { return }
        
        for (index, dot) in dots.enumerated() {
            let isCurrent = (index == currentPage)
            let imgData = isCurrent ? currentPageImage : pageImage
            
            // 使用 UIView 原生过渡动画来实现图片的柔和交叉溶解（Cross Dissolve）
            UIView.transition(with: dot, duration: 0.25, options: .transitionCrossDissolve, animations: {
                dot.loadImage(contentData: imgData, emptyImage: UIColor.clear.createImageWithColor(), loadFinish: { [weak self] value in
                    guard let self = self else { return }
                    if let imageSize = value.firstImage?.size {
                        self.dotSizes[index] = imageSize
                        self.updateLayout()
                    }
                })
            }, completion: nil)
            
            if let imageData = imgData as? UIImage {
                self.dotSizes[index] = imageData.size
            }
        }
        updateLayout()
    }

    // MARK: - 🚀 独有的高级交互点击 (Tap to Page)
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first, pageCount > 1 else { return }
        
        let location = touch.location(in: self)
        
        var targetPage = currentPage
        var minDistance: CGFloat = .greatestFiniteMagnitude
        
        for (index, dot) in dots.enumerated() {
            let dotCenterX = dot.frame.midX
            let distance = abs(location.x - dotCenterX)
            
            if distance < minDistance {
                minDistance = distance
                targetPage = index
            }
        }
        
        if targetPage != currentPage {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            // 🚀 触发！启用原生动画引擎
            setProgress(CGFloat(targetPage), animated: true)
            self.sendActions(for: .valueChanged)
        }
    }
    
    // MARK: - 🚀 适用于 UIView 的原生动画引擎
    
    public func setProgress(_ newProgress: CGFloat, animated: Bool) {
        guard pageCount > 0 else { return }
        let safeProgress = max(0, min(newProgress, CGFloat(pageCount - 1)))
        
        if animated {
            // 利用 iOS 底层最强大的 UIView.animate
            // 它会自动捕捉 Frame 的变化，并将长宽的拉伸和平移用 0.3 秒平滑过渡过去
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
                self.progress = safeProgress
                self.layoutIfNeeded() // 强制触发布局动画
            }, completion: nil)
        } else {
            self.progress = safeProgress
        }
    }
}

public extension PTImagePageControl {
    @objc func addPageControlAction(handler: @escaping ImagePageControlBlock) {
        self.addActionHandler(for: .valueChanged, handler: handler)
    }
}
