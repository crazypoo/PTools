//
//  PTFloatingPlaseholderTextField.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 30/11/2025.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import Foundation
import SwifterSwift
import AttributedString

public class PTFloatingPlaseholderConfig:PTBaseModel {
    public var containerRadius:CGFloat = 0
    public var borderLayerColor:UIColor = .clear
    public var borderLayerFloatingColor:UIColor = .systemBlue
    public var borderLayerWidth:CGFloat = 1
    public var floatingPlaceholderColor:UIColor = .systemBlue
    public var normalPlaceholderColor:UIColor = .gray
    public var floatingPlaceholderFont:UIFont = .systemFont(ofSize: 12)
    public var normalPlaceholderFont:UIFont = .systemFont(ofSize: 16)
    public var textFont:UIFont = .systemFont(ofSize: 16)
    public var tinColor:UIColor = .systemBlue
    public var clearMode:UITextField.ViewMode = .whileEditing
    public var textColor:UIColor = .black
    public var keyboardType:UIKeyboardType = UIKeyboardType.default
    public var isSecureTextEntry:Bool = false
    public var isMust:Bool = true
    
    public var insidePadding:CGFloat = 12
    public var placeholderPaddingOffset:CGFloat = 4
    public var placeholderWidthOffset:CGFloat = 8
    ///placeholder 上浮时距离 superview top 的偏移
    public var placeholderFloatingTopOffset:CGFloat = -8
}

public class PTFloatingPlaseholderTextField: UIView {

    fileprivate var viewConfig:PTFloatingPlaseholderConfig!
    fileprivate var placeholderString:String = ""
    
    public var inputedCallback:((String)->Void)?
    public var inputBegainCallback:PTActionTask?
    public var inputingCallback:((String)->Void)?

    lazy var  textField:UITextField = {
        let view = UITextField()
        view.borderStyle = .none
        view.tintColor = self.viewConfig.tinColor
        view.font = self.viewConfig.textFont
        view.clearButtonMode = self.viewConfig.clearMode
        view.textColor = self.viewConfig.textColor
        view.keyboardType = self.viewConfig.keyboardType
        view.isSecureTextEntry = self.viewConfig.isSecureTextEntry
        view.delegate = self
        return view
    }()
    lazy var  placeholderLabel:UILabel = {
        let view = UILabel()
        return view
    }()
    private let borderLayer = CAShapeLayer()

    /// true = placeholder 上浮（左上角）
    private var isFloating = false
        
    public init(config:PTFloatingPlaseholderConfig = PTFloatingPlaseholderConfig()) {
        viewConfig = config
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        // 基础样式
        layer.cornerRadius = viewConfig.containerRadius

        borderLayer.strokeColor = viewConfig.borderLayerColor.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = viewConfig.borderLayerWidth
        layer.addSublayer(borderLayer)

        addSubviews([placeholderLabel,textField])

        // 初始约束（placeholder 使用 centerY，未浮起时居中在边框线上）
        placeholderLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(self.viewConfig.insidePadding + self.viewConfig.placeholderPaddingOffset)
            make.centerY.equalToSuperview()
        }

        textField.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(self.viewConfig.insidePadding)
            make.right.equalToSuperview().offset(-self.viewConfig.insidePadding)
            make.top.bottom.equalToSuperview().inset(self.viewConfig.floatingPlaceholderFont.pointSize / 2)
        }

        // 事件（聚焦上浮；失焦根据是否有文本恢复）
        textField.addTarget(self, action: #selector(beginEdit), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(endEdit), for: .editingDidEnd)
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        // 确保边框和 label 宽度同步
        updateBorderPath()
    }

    private func placeholderAtt(mainString:String,isNormal:Bool) ->ASAttributedString {
        let plaseHolderFont = isNormal ? viewConfig.normalPlaceholderFont : viewConfig.floatingPlaceholderFont
        let plaseHolderColor = isNormal ? viewConfig.normalPlaceholderColor : viewConfig.floatingPlaceholderColor
        var placeholderAtt:ASAttributedString = """
                    \(wrap: .embedding("""
                    \(mainString,.foreground(plaseHolderColor),.font(plaseHolderFont),.paragraph(.alignment(.center)))
                    """))
                    """
        if viewConfig.isMust {
            let placeholderLastAtt:ASAttributedString = """
                        \(wrap: .embedding("""
                        \(" *",.foreground(.systemRed),.font(plaseHolderFont),.paragraph(.alignment(.center)))
                        """))
                        """
            placeholderAtt += placeholderLastAtt
        }
        return placeholderAtt
    }
    
    public func configure(placeholder: String, text: String? = nil) {
        self.placeholderString = placeholder
        let placeholderAtt = placeholderAtt(mainString: placeholder, isNormal: true)
        placeholderLabel.attributed.text = placeholderAtt
        textField.text = text

        // 根据是否已有文本设置初始状态，避免反转
        let textIsEmpty = (text ?? "").stringIsEmpty()
        // 强制直接设置，不触发 guard short-circuit
        isFloating = !textIsEmpty
        setFloating(!textIsEmpty, animated: false)
    }

    // MARK: - Events
    @objc private func beginEdit() {
        // 聚焦时上浮（和 Material 风格一致）
        setFloating(true, animated: true)
    }

    @objc private func endEdit() {
        let textIsEmpty = (textField.text ?? "").stringIsEmpty()
        setFloating(!textIsEmpty, animated: true)
    }

    @objc private func textChanged() {
        let textIsEmpty = (textField.text ?? "").stringIsEmpty()
        setFloating(!textIsEmpty, animated: true)
    }

    // MARK: - Floating
    private func setFloating(_ float: Bool, animated: Bool) {
        // 如果状态没有变化，不做任何操作
        guard float != isFloating else { return }

        // 先更新状态标志（后续绘制用到）
        isFloating = float

        // 先移除旧约束并根据状态重建 placeholder 约束
        placeholderLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(self.viewConfig.insidePadding + self.viewConfig.placeholderPaddingOffset)
            if float {
                // 上浮到左上角
                make.top.equalToSuperview().offset(self.viewConfig.placeholderFloatingTopOffset)
            } else {
                // 居中于边框线上
                make.centerY.equalToSuperview()
            }
        }

        let animations = {
            let placeholderAtt = self.placeholderAtt(mainString: self.placeholderString, isNormal: !float)
            self.placeholderLabel.attributed.text = placeholderAtt

            // 先 layout，使 placeholder 的 frame/intrinsicSize 更新
            self.layoutIfNeeded()
            // 再更新 border path（gap 位置依赖 placeholder 的宽度/位置）
            self.updateBorderPath()
        }

        if animated {
            UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut], animations: animations, completion: nil)
        } else {
            animations()
        }
    }

    // MARK: - Border: draw outline with gap when placeholder 在 border 上
    private func updateBorderPath() {
        let rect = bounds
        guard rect.width > 0 && rect.height > 0 else { return }

        let radius: CGFloat = viewConfig.containerRadius
        // label 宽度用于计算 gap 宽度（加一点 padding）
        let labelWidth = placeholderLabel.intrinsicContentSize.width + viewConfig.placeholderWidthOffset

        // gap 在上边的起始 x (相对左边 padding)
        // 当 placeholder 在 border 上（isFloating == false）时，我们需要留空
        let gapStartX = viewConfig.insidePadding
        let gapEndX = viewConfig.insidePadding + labelWidth

        let path = UIBezierPath()

        // 从上边左侧圆角起点开始画（跳过 gap 区域）
        path.move(to: CGPoint(x: radius, y: 0))

        if isFloating {
            borderLayer.strokeColor = viewConfig.borderLayerFloatingColor.cgColor
            // 未浮起：上边分为左段 -> gap -> 右段
            // 左段
            path.addLine(to: CGPoint(x: gapStartX, y: 0))
            // 跳过 gap（不画）
            path.move(to: CGPoint(x: gapEndX, y: 0))
            // 继续到右侧圆角起点
            path.addLine(to: CGPoint(x: rect.width - radius, y: 0))
        } else {
            borderLayer.strokeColor = viewConfig.borderLayerColor.cgColor
            // 已浮起：完整上边（无 gap）
            path.addLine(to: CGPoint(x: rect.width - radius, y: 0))
        }

        // 右上角弧
        path.addArc(withCenter: CGPoint(x: rect.width - radius, y: radius),
                    radius: radius,
                    startAngle: CGFloat(-Double.pi/2),
                    endAngle: 0,
                    clockwise: true)

        // 右边
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - radius))

        // 右下角
        path.addArc(withCenter: CGPoint(x: rect.width - radius, y: rect.height - radius),
                    radius: radius,
                    startAngle: 0,
                    endAngle: CGFloat(Double.pi/2),
                    clockwise: true)

        // 底边
        path.addLine(to: CGPoint(x: radius, y: rect.height))

        // 左下角
        path.addArc(withCenter: CGPoint(x: radius, y: rect.height - radius),
                    radius: radius,
                    startAngle: CGFloat(Double.pi/2),
                    endAngle: CGFloat(Double.pi),
                    clockwise: true)

        // 左边
        path.addLine(to: CGPoint(x: 0, y: radius))

        // 左上角弧
        path.addArc(withCenter: CGPoint(x: radius, y: radius),
                    radius: radius,
                    startAngle: CGFloat.pi,
                    endAngle: CGFloat(3 * Double.pi / 2),
                    clockwise: true)

        borderLayer.path = path.cgPath
    }
}

extension PTFloatingPlaseholderTextField:UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text ?? "") + string
        inputingCallback?(newString)
        return true
    }

    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        inputBegainCallback?()
        return true
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        inputedCallback?(textField.text ?? "")
    }
}
