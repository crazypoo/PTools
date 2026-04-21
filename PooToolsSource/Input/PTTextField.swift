//
//  PTTextField.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 30/3/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

@objcMembers
public class PTTextCustomRightViewConfig: NSObject {
    open var size: CGSize = .zero
    open var image: Any?
    open var rightSpace: CGFloat = 5
}

@objcMembers
public class PTTextField: UITextField {
    
    // MARK: - 属性配置
    
    open var leftSpace: CGFloat = 0 {
        didSet {
            // 当左侧间距改变时，通知系统重新布局文本区域
            setNeedsLayout()
        }
    }
    
    open var rightTapBlock: PTActionTask?
    
    public var rightConfig: PTTextCustomRightViewConfig? {
        didSet {
            // 配置发生变化时，更新右侧视图内容，系统会自动触发位置重新计算
            setupRightView()
        }
    }
    
    // 懒加载右侧按钮
    private lazy var customRight: UIButton = {
        let view = UIButton(type: .custom)
        view.addActionHandlers { [weak self] sender in
            self?.rightTapBlock?()
        }
        return view
    }()
    
    // MARK: - 初始化及视图配置
    
    private func setupRightView() {
        // 安全解包，如果 config 为 nil 或者图片为空，则隐藏右侧视图
        guard let config = rightConfig,
              let img = config.image,
              !String(describing: img).isEmpty else { // 假设你有对应的 isEmpty 扩展逻辑
            self.rightView = nil
            self.rightViewMode = .never
            return
        }
        
        // 直接将按钮设为 rightView，位置和间距交由 rightViewRect 控制
        customRight.loadImage(contentData: img)
        self.clearButtonMode = .never
        self.rightView = customRight
        self.rightViewMode = .always
    }
    
    // MARK: - UITextField 原生排版方法重写 (核心优化点)
    
    /// 动态计算右侧视图 (rightView) 的位置和大小
    public override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        // 如果没有配置，使用默认逻辑
        guard let config = rightConfig else {
            return super.rightViewRect(forBounds: bounds)
        }
        
        // 动态计算高度和宽度，防止超出 TextField 的自身边界
        let finalHeight = min(config.size.height, bounds.height)
        var finalWidth = config.size.width
        
        // 防止右侧视图太宽，覆盖了左侧内容
        let maxAvailableWidth = bounds.width - leftSpace - config.rightSpace
        if finalWidth > maxAvailableWidth {
            finalWidth = max(0, maxAvailableWidth)
        }
        
        // 计算 X 和 Y 的坐标 (自带 rightSpace 的偏移)
        let yPos = (bounds.height - finalHeight) / 2.0
        let xPos = bounds.width - finalWidth - config.rightSpace
        
        return CGRect(x: xPos, y: yPos, width: finalWidth, height: finalHeight)
    }
    
    /// 控制非编辑状态下文字的显示区域（实现 leftSpace）
    public override func textRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.textRect(forBounds: bounds)
        if leftSpace > 0 {
            rect.origin.x += leftSpace
            rect.size.width -= leftSpace
        }
        return rect
    }
    
    /// 控制编辑状态下文字的输入区域（实现 leftSpace）
    public override func editingRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.editingRect(forBounds: bounds)
        if leftSpace > 0 {
            rect.origin.x += leftSpace
            rect.size.width -= leftSpace
        }
        return rect
    }
}
