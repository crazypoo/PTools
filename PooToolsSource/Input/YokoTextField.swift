//
//  YokoTextField.swift
//  TextFieldEffects
//
//  Created by Raúl Riera on 30/01/2015.
//  Copyright (c) 2015 Raul Riera. All rights reserved.
//

import UIKit

/// 一个继承自 TextFieldEffects 的自定义输入框 (Yoko 风格)。
/// 特效表现：拥有一个炫酷的 3D 背景板。未激活时背景板向后翻折隐藏；激活时背景板带有弹簧效果地翻转到正面。
@IBDesignable open class YokoTextField: TextFieldEffects {
    
    // MARK: - 可视化属性 (IBInspectable)
    
    /// 占位符文字的颜色。
    /// 默认值为黑色 (如果未设置则维持原样)。
    @IBInspectable dynamic open var placeholderColor: UIColor? {
        didSet {
            updatePlaceholder()
        }
    }
    
    /// 占位符上浮后的字体缩放比例。
    /// 相对于输入框原本字体大小的比例，默认为 0.7。
    @IBInspectable dynamic open var placeholderFontScale: CGFloat = 0.7 {
        didSet {
            updatePlaceholder()
        }
    }
    
    /// 3D 翻转前景/背景板的颜色。
    /// 默认值为黑色。
    @IBInspectable dynamic open var foregroundColor: UIColor = .black {
        didSet {
            updateForeground()
        }
    }
    
    // MARK: - 原生属性重写
    
    override open var placeholder: String? {
        didSet {
            updatePlaceholder()
        }
    }
    
    override open var bounds: CGRect {
        didSet {
            updateForeground()
            updatePlaceholder()
        }
    }
    
    // MARK: - 私有配置参数
    
    /// 执行 3D 翻转的视图载体
    private let foregroundView = UIView()
    /// 附加在 foregroundView 上的边框图层
    private let foregroundLayer = CALayer()
    
    /// 边框的粗细
    private let borderThickness: CGFloat = 3
    /// 占位符的内边距偏移量
    private let placeholderInsets = CGPoint(x: 6, y: 6)
    /// 实际输入文本的内边距偏移量
    private let textFieldInsets = CGPoint(x: 6, y: 6)
    
    // MARK: - TextFieldEffects 生命周期实现
    
    override open func drawViewsForRect(_ rect: CGRect) {
        updateForeground()
        updatePlaceholder()
        
        // 安全检查：防止在多次调用重绘时重复叠加视图和图层，避免内存泄漏
        if foregroundView.superview == nil {
            insertSubview(foregroundView, at: 0) // 将 3D 背景板插在最底层
        }
        if placeholderLabel.superview == nil {
            addSubview(placeholderLabel)
        }
        if foregroundLayer.superlayer == nil {
            layer.insertSublayer(foregroundLayer, at: 0)
        }
    }
    
    override open func animateViewsForTextEntry() {
        // 进入输入状态：3D 视图通过弹簧动画恢复到原始（正面）状态
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.6, options: .beginFromCurrentState, animations: {
            
            self.foregroundView.layer.transform = CATransform3DIdentity
            
        }, completion: { _ in
            self.animationCompletionHandler?(.textEntry)
        })
        
        // 将边框图层调整为未填充状态的形态
        foregroundLayer.frame = rectForBorder(foregroundView.frame, isFilled: false)
    }
    
    override open func animateViewsForTextDisplay() {
        let isTextEmpty = text?.isEmpty ?? true
        
        if isTextEmpty {
            // 退出输入状态：执行 3D 翻折动画
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.6, options: .beginFromCurrentState, animations: {
                
                self.foregroundLayer.frame = self.rectForBorder(self.foregroundView.frame, isFilled: true)
                // 应用沿 X 轴向后翻转 90 度的 3D 变换矩阵
                self.foregroundView.layer.transform = self.rotationAndPerspectiveTransformForView(self.foregroundView)
                
            }, completion: { _ in
                self.animationCompletionHandler?(.textDisplay)
            })
        }
    }
    
    // MARK: - 内部私有方法 (Private)
    
    /// 安全获取当前字体，防止崩溃
    private var currentFont: UIFont {
        return font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
    }
    
    /// 更新 3D 前景视图和它的边框样式
    private func updateForeground() {
        foregroundView.frame = rectForForeground(frame)
        foregroundView.isUserInteractionEnabled = false // 确保不阻挡输入事件
        
        // 默认状态下应用 3D 翻折
        foregroundView.layer.transform = rotationAndPerspectiveTransformForView(foregroundView)
        foregroundView.backgroundColor = foregroundColor
        
        foregroundLayer.borderWidth = borderThickness
        // 根据基础颜色计算一个稍微暗一点的边框颜色（亮度乘以 0.8）
        foregroundLayer.borderColor = colorWithBrightnessFactor(foregroundColor, factor: 0.8).cgColor
        foregroundLayer.frame = rectForBorder(foregroundView.frame, isFilled: true)
    }
    
    /// 更新占位符状态
    private func updatePlaceholder() {
        placeholderLabel.font = placeholderFontFromFont(currentFont)
        placeholderLabel.text = placeholder
        placeholderLabel.textColor = placeholderColor
        placeholderLabel.sizeToFit()
        layoutPlaceholderInTextRect()
        
        let isTextNotEmpty = text?.isNotEmpty ?? false
        if isFirstResponder || isTextNotEmpty {
            animateViewsForTextEntry()
        }
    }
    
    /// 根据设定的缩放比例计算占位符的字体大小
    private func placeholderFontFromFont(_ font: UIFont) -> UIFont {
        return UIFont(descriptor: font.fontDescriptor, size: font.pointSize * placeholderFontScale)
    }
    
    /// 计算 3D 视图的基础 Frame (给文本和边框留出空间)
    private func rectForForeground(_ bounds: CGRect) -> CGRect {
        // 使用安全解包的 currentFont
        return CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height - currentFont.lineHeight + textFieldInsets.y - borderThickness)
    }
    
    /// 计算边框的 Frame，处理翻折前后的尺寸变化
    private func rectForBorder(_ bounds: CGRect, isFilled: Bool) -> CGRect {
        var newRect = CGRect(x: 0, y: bounds.size.height, width: bounds.size.width, height: isFilled ? borderThickness : 0)
        
        // 如果视图当前被进行了 3D 变换，调整 Y 坐标以保持视觉连贯
        if !CATransform3DIsIdentity(foregroundView.layer.transform) {
            newRect.origin = CGPoint(x: 0, y: bounds.origin.y)
        }
        
        return newRect
    }
    
    /// 布局占位符，使其正确显示在文本区域内
    private func layoutPlaceholderInTextRect() {
        let textRect = self.textRect(forBounds: bounds)
        var originX = textRect.origin.x
        
        switch textAlignment {
        case .center:
            originX += textRect.size.width / 2 - placeholderLabel.bounds.width / 2
        case .right:
            originX += textRect.size.width - placeholderLabel.bounds.width
        default:
            break
        }
        
        placeholderLabel.frame = CGRect(x: originX, y: bounds.height - placeholderLabel.frame.height,
                                        width: placeholderLabel.frame.size.width, height: placeholderLabel.frame.size.height)
    }
    
    // MARK: - 3D 变换辅助方法
    
    /// 重新设置视图的锚点（AnchorPoint），同时调整 position 以保证视图不发生位置跳动
    /// 解决因为直接修改 anchorPoint 导致的视图偏移问题
    private func setAnchorPoint(_ anchorPoint: CGPoint, forView view: UIView) {
        var newPoint = CGPoint(x: view.bounds.size.width * anchorPoint.x, y: view.bounds.size.height * anchorPoint.y)
        var oldPoint = CGPoint(x: view.bounds.size.width * view.layer.anchorPoint.x, y: view.bounds.size.height * view.layer.anchorPoint.y)
        
        newPoint = newPoint.applying(view.transform)
        oldPoint = oldPoint.applying(view.transform)
        
        var position = view.layer.position
        
        position.x -= oldPoint.x
        position.x += newPoint.x
        
        position.y -= oldPoint.y
        position.y += newPoint.y
        
        view.layer.position = position
        view.layer.anchorPoint = anchorPoint
    }
    
    /// 根据给定的亮度倍数调整颜色
    /// - Parameters:
    ///   - color: 原始颜色
    ///   - factor: 亮度系数 (如 0.8 表示亮度降为原来的 80%)
    private func colorWithBrightnessFactor(_ color: UIColor, factor: CGFloat) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        if color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return UIColor(hue: hue, saturation: saturation, brightness: brightness * factor, alpha: alpha)
        } else {
            return color
        }
    }
    
    /// 构建并返回一个带透视效果的向后翻折 90 度的 3D 矩阵
    private func rotationAndPerspectiveTransformForView(_ view: UIView) -> CATransform3D {
        // 设置锚点在底部中心，这样它就像从底部边缘向后倒下
        setAnchorPoint(CGPoint(x: 0.5, y: 1.0), forView: view)
        
        var rotationAndPerspectiveTransform = CATransform3DIdentity
        // m34 控制透视效果的深度
        rotationAndPerspectiveTransform.m34 = 1.0 / 800
        // 旋转角度为 -90 度 (向后倒)
        let radians = ((-90) / 180.0 * CGFloat.pi)
        // 沿 X 轴执行旋转
        rotationAndPerspectiveTransform = CATransform3DRotate(rotationAndPerspectiveTransform, radians, 1.0, 0.0, 0.0)
        return rotationAndPerspectiveTransform
    }
    
    // MARK: - UITextField 边界区域重写 (Overrides)
        
    /// 返回处于编辑状态时的文本绘制区域
    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        let newBounds = CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height - currentFont.lineHeight + textFieldInsets.y)
        return newBounds.insetBy(dx: textFieldInsets.x, dy: 0)
    }
    
    /// 返回正常的文本绘制区域
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        let newBounds = CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height - currentFont.lineHeight + textFieldInsets.y)
        return newBounds.insetBy(dx: textFieldInsets.x, dy: 0)
    }
}
