//
//  PTImagePageControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 22/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Foundation

public typealias ImagePageControlBlock = (_ sender:PTImagePageControl) -> Void

@objcMembers
open class PTImagePageControl: UIControl { // 🚀 1. 彻底升级为 UIControl
    
    // 🚀 2. 统一 API 命名：使用 pageCount 和 progress，与其他组件看齐
    open var pageCount: Int = 0 {
        didSet {
            setupDots()
        }
    }
    
    open var progress: CGFloat = 0 {
        didSet {
            guard pageCount > 0 else { return }
            // 增加边界保护
            let safeProgress = max(0, min(progress, CGFloat(pageCount - 1)))
            let newPage = Int(round(safeProgress))
            
            // 只有当整数页码发生实质改变时，才去触发图片更新，避免浪费性能
            if newPage != previousPage {
                previousPage = newPage
                updateDots()
            }
        }
    }
    
    open var currentPage: Int {
        Int(round(progress))
    }
    
    private var previousPage: Int = 0
    
    // MARK: - Appearance (Dot 图片属性)
    
    public var currentPageImage: Any = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "lldotInActive") {
        didSet { updateDots() }
    }
    public var pageImage: Any = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "lldotActive") {
        didSet { updateDots() }
    }

    public var dotSpacing: CGFloat = 8.0 {
        didSet { setNeedsLayout() } // 仅间距变化，只需重新排版
    }
    
    public var dotBaseSize: CGSize = CGSize(width: 8, height: 4) {
        didSet { setNeedsLayout() }
    }

    private var dots: [UIImageView] = []
    private var dotSizes: [CGSize] = []

    // MARK: - Init
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - State Update
    
    private func setupDots() {
        // 清除舊的 dots
        dots.forEach { $0.removeFromSuperview() }
        dots.removeAll()
        dotSizes.removeAll()

        guard pageCount > 0 else {
            setNeedsLayout()
            return
        }

        // 建立新的 dots
        for i in 0..<pageCount {
            let dot = UIImageView()
            dot.contentMode = .scaleAspectFit
            
            // 先使用 baseSize 占位，防止异步加载前发生布局折叠
            dotSizes.append(dotBaseSize)
            
            // 🚀 防止闭包引起的内存泄漏
            dot.loadImage(contentData: pageImage, loadFinish: { [weak self] value in
                guard let self = self else { return }
                if let imageSize = value.firstImage?.size {
                    self.dotSizes[i] = imageSize
                    self.setNeedsLayout() // 图片加载完成，触发重新计算 Frame
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

    private func updateDots() {
        guard dots.count == pageCount else { return }
        
        for (index, dot) in dots.enumerated() {
            let isCurrent = (index == currentPage)
            let imgData = isCurrent ? currentPageImage : pageImage
            
            // 🚀 同样增加 weak self 保护
            dot.loadImage(contentData: imgData, emptyImage: UIColor.clear.createImageWithColor(), loadFinish: { [weak self] value in
                guard let self = self else { return }
                if let imageSize = value.firstImage?.size {
                    self.dotSizes[index] = imageSize
                    self.setNeedsLayout()
                }
            })
            
            if let imageData = imgData as? UIImage {
                self.dotSizes[index] = imageData.size
            }
        }
        setNeedsLayout()
    }

    // MARK: - Layout
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        guard pageCount > 0, dots.count == pageCount else { return }
        
        let totalWidth = dotSizes.reduce(0) { $0 + $1.width } + CGFloat(max(0, pageCount - 1)) * dotSpacing
        var startX = (bounds.width - totalWidth) / 2
        let centerY = bounds.height / 2

        for (index, dot) in dots.enumerated() {
            let size = dotSizes[index]
            dot.frame = CGRect(x: startX, y: centerY - size.height / 2, width: size.width, height: size.height)
            startX += size.width + dotSpacing
        }
    }
    
    // MARK: - 🚀 新增功能：支持交互点击 (Tap to Page)
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first, pageCount > 1 else { return }
        
        let location = touch.location(in: self)
        
        // 🚀 高级点击算法：由于图片长宽不一，通过计算点击坐标与各图片中心点的最近距离来锁定目标页
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
            
            self.progress = CGFloat(targetPage)
            self.sendActions(for: .valueChanged)
        }
    }

    // 同步獲取圖片
    private static func syncImage(from data: Any) -> UIImage? {
        if let image = data as? UIImage {
            return image
        } else if let name = data as? String {
            return UIImage(named: name)
        } else if let url = data as? URL {
            return try? UIImage(data: Data(contentsOf: url))
        } else {
            return nil
        }
    }
}

public extension PTImagePageControl {
    @objc func addSwitchAction(handler:@escaping ImagePageControlBlock) {
        self.addActionHandler(for: .valueChanged, handler: handler)
    }
}
