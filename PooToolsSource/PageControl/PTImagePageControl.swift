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
@MainActor
open class PTImagePageControl: PTBasePageControl {
    
    private var previousPage: Int = 0
    private var contentGeneration: UInt = 0
    
    // MARK: - Appearance (Dot 图片属性)
    
    public var currentPageImage: Any = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "lldotInActive") {
        didSet {
            contentGeneration &+= 1
            updateDots(at: currentPage)
        }
    }
    public var pageImage: Any = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "lldotActive") {
        didSet {
            contentGeneration &+= 1
            updateDots()
        }
    }

    public var dotBaseSize: CGSize = CGSize(width: 8, height: 4) {
        didSet {
            guard dotBaseSize.width.isFinite,
                  dotBaseSize.height.isFinite,
                  dotBaseSize.width >= 0,
                  dotBaseSize.height >= 0 else {
                dotBaseSize = oldValue
                return
            }
            updateLayout()
        }
    }

    private var dots: [UIImageView] = []
    private var dotSizes: [CGSize] = []

    // MARK: - 重写基类模板方法
    
    override open func updateNumberOfPages(_ count: Int) {
        contentGeneration &+= 1
        let generation = contentGeneration
        dots.forEach { $0.removeFromSuperview() }
        dots.removeAll()
        dotSizes.removeAll()
        previousPage = 0

        guard count > 0 else {
            updateLayout()
            return
        }

        for i in 0..<count {
            let dot = UIImageView()
            dot.contentMode = .scaleAspectFit
            
            dotSizes.append(dotBaseSize)
            
            if let image = pageImage as? UIImage {
                dotSizes[i] = image.size
            }
            
            addSubview(dot)
            dots.append(dot)

            dot.loadImage(contentData: pageImage, loadFinish: { [weak self] value in
                guard let self = self else { return }
                guard self.contentGeneration == generation,
                      self.dots.indices.contains(i),
                      self.dots[i] === dot,
                      let imageSize = value.firstImage?.size,
                      imageSize.width.isFinite,
                      imageSize.height.isFinite,
                      imageSize.width > 0,
                      imageSize.height > 0 else { return }
                self.dotSizes[i] = imageSize
                self.updateLayout()
            })
        }

        updateDots()
    }

    override open func updateProgress(_ safeProgress: CGFloat) {
        let newPage = Int(round(safeProgress))
        
        if newPage != previousPage {
            let oldPage = previousPage
            previousPage = newPage
            updateDots(at: oldPage)
            updateDots(at: newPage)
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
    
    private func updateDots(at page: Int? = nil) {
        guard dots.count == pageCount else { return }
        if let page {
            updateDot(at: page)
        } else {
            for index in dots.indices {
                updateDot(at: index)
            }
        }
        updateLayout()
    }

    /// English: Update only the dot whose visual state changed and ignore stale image callbacks.
    /// Español: Actualiza solo el punto cuyo estado visual cambió e ignora callbacks de imágenes obsoletos.
    /// 中文：只更新视觉状态发生变化的圆点，并忽略过期的图片回调。
    private func updateDot(at index: Int) {
        guard dots.indices.contains(index) else { return }
        let dot = dots[index]
        let imageData = index == currentPage ? currentPageImage : pageImage
        let generation = contentGeneration

        if let image = imageData as? UIImage,
           image.size.width.isFinite, image.size.height.isFinite,
           image.size.width > 0, image.size.height > 0 {
            dotSizes[index] = image.size
        }

        UIView.transition(with: dot,
                          duration: UIAccessibility.isReduceMotionEnabled ? 0 : 0.25,
                          options: [.transitionCrossDissolve, .beginFromCurrentState, .allowAnimatedContent]) {
            dot.loadImage(contentData: imageData,
                          emptyImage: UIColor.clear.createImageWithColor(),
                          loadFinish: { [weak self = self, weak dot = dot] value in
                guard let self,
                      let dot,
                      self.contentGeneration == generation,
                      self.dots.indices.contains(index),
                      self.dots[index] === dot,
                      let imageSize = value.firstImage?.size,
                      imageSize.width.isFinite,
                      imageSize.height.isFinite,
                      imageSize.width > 0,
                      imageSize.height > 0 else { return }
                self.dotSizes[index] = imageSize
                self.updateLayout()
            })
        }
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
    
    override open func setProgress(_ newProgress: CGFloat, animated: Bool) {
        guard pageCount > 0 else { return }
        super.setProgress(newProgress, animated: animated)
    }
}

public extension PTImagePageControl {
    @objc func addPageControlAction(handler: @escaping ImagePageControlBlock) {
        self.addActionHandler(for: .valueChanged, handler: handler)
    }
}
