//
//  PTLabel.swift
//  Diou
//
//  Created by ken lam on 2021/10/7.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit

@objc public enum PTVerticalAlignment: Int {
    case top
    case middle
    case bottom
}

@objc public enum PTStrikeThroughAlignment: Int {
    case top
    case middle
    case bottom
}

@objcMembers
public class PTLabel: UILabel {
        
    // MARK: - 属性配置 (Properties)
    
    /// 垂直对齐方式
    public var verticalAlignment: PTVerticalAlignment = .middle {
        didSet {
            // 性能优化：仅当新值与旧值不同时，才要求系统重绘
            if verticalAlignment != oldValue {
                self.setNeedsDisplay()
            }
        }
    }
    
    /// 划线的垂直对齐方式
    public var strikeThroughAlignment: PTStrikeThroughAlignment = .middle {
        didSet {
            if strikeThroughAlignment != oldValue {
                self.setNeedsDisplay()
            }
        }
    }
    
    /// 是否开启划线功能
    public var strikeThroughEnabled: Bool = false {
        didSet {
            if strikeThroughEnabled != oldValue {
                self.setNeedsDisplay()
            }
        }
    }
    
    /// 划线的颜色，默认与系统红色一致
    public var strikeThroughColor: UIColor = .systemRed {
        didSet {
            if strikeThroughColor != oldValue {
                self.setNeedsDisplay()
            }
        }
    }
    
    // MARK: - 初始化 (Initialization)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        // 修复：移除 fatalError，使组件支持在 Xib/Storyboard 中安全使用
        super.init(coder: coder)
    }
    
    // MARK: - 核心计算与绘制 (Layout & Drawing)
    
    /// 计算文本在 Label 中的实际边框边界
    public override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        var textRect = super.textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines)
        
        // 调整垂直方向的起始点位置
        switch verticalAlignment {
        case .top:
            textRect.origin.y = bounds.origin.y
        case .bottom:
            textRect.origin.y = bounds.origin.y + bounds.size.height - textRect.size.height
        case .middle:
            // 保证严格的数学居中
            textRect.origin.y = bounds.origin.y + (bounds.size.height - textRect.size.height) / 2.0
        }
        
        return textRect
    }
    
    /// 实际绘制文本及附加图形（划线）
    public override func drawText(in rect: CGRect) {
        // 1. 获取调整对齐后的实际文本矩形
        let actualRect = textRect(forBounds: rect, limitedToNumberOfLines: numberOfLines)
        
        // 2. 首先让父类将文字绘制在这个正确的矩形框内
        super.drawText(in: actualRect)
        
        // 3. 绘制划线（安全地获取图形上下文，避免在计算布局时触发崩溃）
        if strikeThroughEnabled, let context = UIGraphicsGetCurrentContext() {
            let strikeWidth = actualRect.size.width
            var lineRect: CGRect = .zero
            
            // 计算线条的位置（基于已经对齐的文字区域 actualRect）
            switch strikeThroughAlignment {
            case .top:
                lineRect = CGRect(x: actualRect.origin.x, y: actualRect.origin.y, width: strikeWidth, height: 1)
            case .bottom:
                lineRect = CGRect(x: actualRect.origin.x, y: actualRect.origin.y + actualRect.size.height, width: strikeWidth, height: 1)
            case .middle:
                lineRect = CGRect(x: actualRect.origin.x, y: actualRect.origin.y + actualRect.size.height / 2.0, width: strikeWidth, height: 1)
            }
            
            // 执行绘制
            context.setFillColor(strikeThroughColor.cgColor)
            context.fill(lineRect)
        }
    }
}
