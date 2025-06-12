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
    
    // Dot 圖片屬性（可傳 UIImage, String 等）
    public var currentPageImage: Any = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "lldotInActive")
    public var pageImage: Any = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "lldotActive")

    open override var numberOfPages: Int {
        didSet {
            setupDots()
        }
    }

    open override var currentPage: Int {
        didSet {
            updateDots()
        }
    }

    public var dotSpacing: CGFloat = 8.0 {
        didSet {
            updateDots()
        }
    }
    
    public var dotBaseSize:CGSize = CGSizeMake(8, 4)

    private var dots: [UIImageView] = []
    private var dotSize: [CGSize] = []// default fallback

    // 初始化
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setupDots() {
        // 清除舊的 dots
        for dot in dots {
            dot.removeFromSuperview()
        }
        dots.removeAll()
        dotSize.removeAll()

        // 建立新的 dots
        for i in 0..<numberOfPages {
            let dot = UIImageView()
            dot.loadImage(contentData: pageImage, loadFinish:  { images, image in
                self.dotSize[i] = (image?.size ?? self.dotBaseSize)
            })
            addSubview(dot)
            dots.append(dot)
            if let pageImage = pageImage as? UIImage {
                dotSize.append(pageImage.size)
            } else {
                dotSize.append(dotBaseSize)
            }
        }

        updateDots()
        setNeedsLayout()
    }

    private func updateDots() {
        for (index, dot) in dots.enumerated() {
            let imgData = (index == currentPage) ? currentPageImage : pageImage
            dot.loadImage(contentData: imgData, emptyImage: UIColor.clear.createImageWithColor(),loadFinish: { images,image in
                self.dotSize[index] = image?.size ?? self.dotBaseSize
            })
            if let imageData = imgData as? UIImage {
                self.dotSize[index] = imageData.size
            }
        }
        setNeedsLayout()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        let totalWidth = dotSize.reduce(0) { $0 + $1.width } + CGFloat(numberOfPages - 1) * dotSpacing
        var startX = (bounds.width - totalWidth) / 2
        let centerY = bounds.height / 2

        for (index,_) in dots.enumerated() {
            let dotSize = dotSize[index]
            self.dots[index].frame = CGRect(x: startX, y: centerY - dotSize.height / 2, width: dotSize.width, height: dotSize.height)
            startX += dotSize.width + dotSpacing
        }
    }

    // 同步獲取圖片（根據你原本的 Any 類型處理方式擴展）
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
