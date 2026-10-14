//
//  PTTextField.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 30/3/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
#if SWIFT_PACKAGE
import ptools
#endif

@objcMembers
public class PTTextCustomRightViewConfig: NSObject {
    open var size: CGSize = .zero
    open var image: Any?
    open var rightSpace: CGFloat = 5
}

@MainActor
@objcMembers
public class PTTextField: UITextField {
    
    // MARK: - 属性配置
    
    open var leftSpace: CGFloat = 0 {
        didSet {
            // 当左侧间距改变时，通知系统重新布局文本区域
            setNeedsLayout()
        }
    }

    // English: Expose the shared leading inset name while keeping the legacy leftSpace API.
    // Español: Expone el nombre compartido de margen inicial y conserva la API heredada leftSpace.
    // 中文：提供统一的 leadingSpace 名称，同时保留旧的 leftSpace API。
    open var leadingSpace: CGFloat {
        get { leftSpace }
        set { leftSpace = max(0, newValue) }
    }

    // English: Keep the composite field's text geometry compatible with TextFieldEffects.
    // Español: Mantiene la geometría del texto compatible con TextFieldEffects.
    // 中文：让复合输入框的文本几何配置与 TextFieldEffects 保持一致。
    open var textEditingEdges: UIEdgeInsets = .zero {
        didSet { setNeedsLayout() }
    }

    // English: Bridge the shared input configuration without changing the right-action contract.
    // Español: Conecta la configuración compartida sin cambiar el contrato de la acción derecha.
    // 中文：接入统一输入配置，同时不改变右侧按钮行为契约。
    open var inputAppearance = PTInputAppearance() {
        didSet {
            leadingSpace = inputAppearance.leadingSpace
            textEditingEdges = inputAppearance.textEditingEdges
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
        let rect = super.textRect(forBounds: bounds)
        return applyInputInsets(to: rect, bounds: bounds)
    }
    
    /// 控制编辑状态下文字的输入区域（实现 leftSpace）
    public override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        return applyInputInsets(to: rect, bounds: bounds)
    }

    // English: Apply each inset exactly once and keep the result inside valid bounds.
    // Español: Aplica cada margen una sola vez y mantiene el resultado dentro de límites válidos.
    // 中文：每个内边距只计算一次，并保证结果始终处于有效边界内。
    private func applyInputInsets(to rect: CGRect, bounds: CGRect) -> CGRect {
        var resolved = rect.inset(by: textEditingEdges)
        let space = max(0, leftSpace)
        guard space > 0 else {
            resolved.size.width = max(0, resolved.width)
            resolved.size.height = max(0, resolved.height)
            return resolved
        }

        let direction = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute)
        let safeSpace = min(space, max(0, resolved.width))
        if direction == .rightToLeft {
            resolved.size.width = max(0, resolved.width - safeSpace)
        } else {
            resolved.origin.x += safeSpace
            resolved.size.width = max(0, resolved.width - safeSpace)
        }
        resolved.size.height = max(0, resolved.height)
        return resolved
    }
}
