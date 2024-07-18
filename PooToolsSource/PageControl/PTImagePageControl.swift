//
//  PTImagePageControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 22/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Foundation

@objcMembers
open class PTImagePageControl: UIPageControl {
    
    // 图片属性
    open var currentPageImage:Any = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "lldotInActive")
    open var pageImage:Any = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "lldotActive")

        // 页码和间距
    open override var numberOfPages: Int {
        didSet {
            setupDots()
        }
    }

    open override var currentPage: Int  {
        didSet {
            updateDots()
        }
    }
    
    var dotSpacing: CGFloat = 8.0 {
        didSet {
            setupDots()
        }
    }
    
    // 私有属性
    private var dots: [UIImageView] = []

    // 初始化方法
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupDots() {
        // 移除旧的 dots
        for dot in dots {
            dot.removeFromSuperview()
        }
        dots.removeAll()
        
        // 添加新的 dots
        for _ in 0..<numberOfPages {
            let dot = UIImageView()
            dot.loadImage(contentData: pageImage)
            addSubview(dot)
            dots.append(dot)
        }
        setNeedsLayout()
        updateDots()
    }
    
    private func updateDots() {
        for (index, dot) in dots.enumerated() {
            dot.loadImage(contentData: (index == currentPage) ? currentPageImage : pageImage)
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        
        Task {
            let results = await PTLoadImageFunction.loadImage(contentData: currentPageImage)
        
            let totalWidth = CGFloat(numberOfPages - 1) * dotSpacing + CGFloat(numberOfPages) * (results.1?.size.width ?? 0)
            var startX = (bounds.width - totalWidth) / 2
            let centerY = bounds.height / 2
            
            for dot in dots {
                dot.sizeToFit()
                dot.center = CGPoint(x: startX + dot.frame.width / 2, y: centerY)
                startX += dot.frame.width + dotSpacing
            }
        }
    }
}

