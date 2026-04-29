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

public class PTFloatingPlaseholderConfig: PTBaseModel {
    public var containerRadius: CGFloat = 0
    public var borderLayerColor: UIColor = .clear
    public var borderLayerFloatingColor: UIColor = .systemBlue
    public var borderLayerWidth: CGFloat = 1
    public var floatingPlaceholderColor: UIColor = .systemBlue
    public var normalPlaceholderColor: UIColor = .gray
    public var floatingPlaceholderFont: UIFont = .systemFont(ofSize: 12)
    public var normalPlaceholderFont: UIFont = .systemFont(ofSize: 16)
    public var textFont: UIFont = .systemFont(ofSize: 16)
    public var tinColor: UIColor = .systemBlue // 建议拼写修改为 tintColor
    public var clearMode: UITextField.ViewMode = .whileEditing
    public var textColor: UIColor = .black
    public var keyboardType: UIKeyboardType = .default
    public var isSecureTextEntry: Bool = false
    public var isMust: Bool = false
    
    public var insidePadding: CGFloat = 12
    public var placeholderPaddingOffset: CGFloat = 4
    public var placeholderWidthOffset: CGFloat = 8
    /// placeholder 上浮时距离 superview top 的偏移
    public var placeholderFloatingTopOffset: CGFloat = -8
    public var haveAction: Bool = false
    public var actionSize: CGSize = .zero
    public var actionNormal: Any?
    public var actionSelected: Any?
    public var actionSapcing: CGFloat = 8 // 建议拼写修改为 actionSpacing
    public var textAlignment: NSTextAlignment = .left
    
    public required init() { super.init() }
    
    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

public class PTFloatingPlaseholderTextField: UIView {

    // 【优化】避免使用 !，直接赋初始值，防止 init(coder:) 时崩溃
    private var viewConfig: PTFloatingPlaseholderConfig = PTFloatingPlaseholderConfig()
    private var placeholderString: String = ""
    
    // 【优化】记录上一次的 bounds，避免 layoutSubviews 中频繁且无效的重绘
    private var lastBounds: CGRect = .zero
    
    // 【优化】缓存富文本，避免每次动画都重新生成字符串（提升性能）
    private var cachedNormalAttString: ASAttributedString?
    private var cachedFloatingAttString: ASAttributedString?
    
    public var inputedCallback: ((String) -> Void)?
    public var inputBegainCallback: PTActionTask?
    public var inputingCallback: ((String) -> Void)?
    public var actionTouchBlock: TouchedBlock?

    public lazy var textField: UITextField = {
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
    
    public lazy var placeholderLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }()
    
    public lazy var actionButton: UIButton = {
        let view = UIButton(type: .custom)
        if let normal = viewConfig.actionNormal {
            view.loadImage(contentData: normal, controlState: .normal)
        }
        if let selected = viewConfig.actionSelected {
            view.loadImage(contentData: selected, controlState: .selected)
        }
        view.isHidden = !viewConfig.haveAction
        // 【重要修复】添加 [weak self] 防止闭包引起的强引用循环
        view.addActionHandlers(handler: { [weak self] sender in
            self?.actionTouchBlock?(sender)
        })
        return view
    }()
    
    private let borderLayer = CAShapeLayer()

    /// true = placeholder 上浮（左上角）
    private var isFloating = false
        
    public init(config: PTFloatingPlaseholderConfig = PTFloatingPlaseholderConfig()) {
        self.viewConfig = config
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        layer.cornerRadius = viewConfig.containerRadius
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = viewConfig.borderLayerWidth
        layer.addSublayer(borderLayer)
        
        addSubviews([actionButton, placeholderLabel, textField])

        actionButton.snp.makeConstraints { make in
            make.size.equalTo(self.viewConfig.actionSize)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(self.viewConfig.insidePadding)
        }
        
        placeholderLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(self.viewConfig.insidePadding + self.viewConfig.placeholderPaddingOffset)
            if self.viewConfig.haveAction {
                make.right.equalTo(self.actionButton.snp.left).offset(-self.viewConfig.actionSapcing)
            } else {
                make.right.equalToSuperview().inset(self.viewConfig.insidePadding)
            }
            make.centerY.equalToSuperview()
        }

        textField.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(self.viewConfig.insidePadding)
            if self.viewConfig.haveAction {
                make.right.equalTo(self.actionButton.snp.left).offset(-self.viewConfig.actionSapcing)
            } else {
                make.right.equalToSuperview().inset(self.viewConfig.insidePadding)
            }
            make.top.bottom.equalToSuperview().inset(self.viewConfig.floatingPlaceholderFont.pointSize / 2)
        }

        textField.addTarget(self, action: #selector(beginEdit), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(endEdit), for: .editingDidEnd)
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        
        // 初始调用一次绘制
        updateBorderPath()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        // 【优化】只在尺寸真正改变时才重新计算边框路径，降低 CPU 消耗
        if bounds != lastBounds {
            lastBounds = bounds
            updateBorderPath()
        }
    }
    
    // 【优化】支持系统的暗黑/浅色模式切换
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateBorderPath() // 因为 CGColor 不会自动随系统模式刷新，需要手动重绘
        }
    }

    private func getPlaceholderAtt(mainString: String, isNormal: Bool) -> ASAttributedString {
        let plaseHolderFont = isNormal ? viewConfig.normalPlaceholderFont : viewConfig.floatingPlaceholderFont
        let plaseHolderColor = isNormal ? viewConfig.normalPlaceholderColor : viewConfig.floatingPlaceholderColor
        var placeholderAtt: ASAttributedString = """
                    \(wrap: .embedding("""
                    \(mainString,.foreground(plaseHolderColor),.font(plaseHolderFont),.paragraph(.alignment(viewConfig.textAlignment)))
                    """))
                    """
        if viewConfig.isMust {
            let placeholderLastAtt: ASAttributedString = """
                        \(wrap: .embedding("""
                        \(" *",.foreground(.systemRed),.font(plaseHolderFont),.paragraph(.alignment(viewConfig.textAlignment)))
                        """))
                        """
            placeholderAtt += placeholderLastAtt
        }
        return placeholderAtt
    }
    
    public func configure(placeholder: String, text: String? = nil) {
        self.placeholderString = placeholder
        
        // 生成并缓存两种状态下的富文本
        self.cachedNormalAttString = getPlaceholderAtt(mainString: placeholder, isNormal: true)
        self.cachedFloatingAttString = getPlaceholderAtt(mainString: placeholder, isNormal: false)
        
        placeholderLabel.attributed.text = cachedNormalAttString
        textField.text = text

        let textIsNotEmpty = !(text ?? "").stringIsEmpty()
        setFloating(textIsNotEmpty, animated: false)
    }

    // MARK: - Events
    @objc private func beginEdit() {
        setFloating(true, animated: true)
    }

    @objc private func endEdit() {
        let textIsNotEmpty = !(textField.text ?? "").stringIsEmpty()
        setFloating(textIsNotEmpty, animated: true)
    }

    @objc private func textChanged() {
        let textIsNotEmpty = !(textField.text ?? "").stringIsEmpty()
        setFloating(textIsNotEmpty, animated: true)
    }

    // MARK: - Floating
    private func setFloating(_ float: Bool, animated: Bool) {
        // 如果状态没有变化，直接返回，避免多余动画
        if isFloating == float && placeholderLabel.attributed.text != nil { return }
        isFloating = float

        placeholderLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(self.viewConfig.insidePadding + self.viewConfig.placeholderPaddingOffset)
            if float {
                make.top.equalToSuperview().offset(self.viewConfig.placeholderFloatingTopOffset)
            } else {
                make.centerY.equalToSuperview()
                if self.viewConfig.haveAction {
                    make.right.equalTo(self.actionButton.snp.left).offset(-self.viewConfig.actionSapcing)
                } else {
                    make.right.equalToSuperview().inset(self.viewConfig.insidePadding)
                }
            }
        }

        let animations = {
            // 【优化】直接使用预先缓存的字符串，不用重复计算
            self.placeholderLabel.attributed.text = float ? self.cachedFloatingAttString : self.cachedNormalAttString
            self.layoutIfNeeded()
            self.updateBorderPath()
        }

        if animated {
            UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut], animations: animations, completion: nil)
        } else {
            animations()
        }
    }

    // MARK: - Border Path
    private func updateBorderPath() {
        let rect = bounds
        guard rect.width > 0 && rect.height > 0 else { return }

        let radius: CGFloat = viewConfig.containerRadius
        let labelWidth = placeholderLabel.intrinsicContentSize.width + viewConfig.placeholderWidthOffset
        let gapStartX = viewConfig.insidePadding
        let gapEndX = viewConfig.insidePadding + labelWidth

        let path = UIBezierPath()
        path.move(to: CGPoint(x: radius, y: 0))

        if isFloating {
            borderLayer.strokeColor = viewConfig.borderLayerFloatingColor.cgColor
            path.addLine(to: CGPoint(x: gapStartX, y: 0))
            path.move(to: CGPoint(x: gapEndX, y: 0))
            path.addLine(to: CGPoint(x: rect.width - radius, y: 0))
        } else {
            borderLayer.strokeColor = viewConfig.borderLayerColor.cgColor
            path.addLine(to: CGPoint(x: rect.width - radius, y: 0))
        }

        path.addArc(withCenter: CGPoint(x: rect.width - radius, y: radius), radius: radius, startAngle: CGFloat(-Double.pi/2), endAngle: 0, clockwise: true)
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - radius))
        path.addArc(withCenter: CGPoint(x: rect.width - radius, y: rect.height - radius), radius: radius, startAngle: 0, endAngle: CGFloat(Double.pi/2), clockwise: true)
        path.addLine(to: CGPoint(x: radius, y: rect.height))
        path.addArc(withCenter: CGPoint(x: radius, y: rect.height - radius), radius: radius, startAngle: CGFloat(Double.pi/2), endAngle: CGFloat(Double.pi), clockwise: true)
        path.addLine(to: CGPoint(x: 0, y: radius))
        path.addArc(withCenter: CGPoint(x: radius, y: radius), radius: radius, startAngle: CGFloat.pi, endAngle: CGFloat(3 * Double.pi / 2), clockwise: true)

        borderLayer.path = path.cgPath
    }
}

extension PTFloatingPlaseholderTextField: UITextFieldDelegate {
    
    // 【重要修复】修正了获取 UITextField 即将改变后的文本逻辑
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text,
           let textRange = Range(range, in: text) {
            // 正确替换范围内的字符，能够正确处理插入光标或删除(Backspace)字符的场景
            let newText = text.replacingCharacters(in: textRange, with: string)
            inputingCallback?(newText)
        }
        return true
    }

    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        inputBegainCallback?()
        return true
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        inputedCallback?(textField.text ?? "")
    }
    
    // MARK: - Responder Chain & Message Forwarding
        
    /// 1. 确保将外层视图的 第一响应者 状态，同步委托给内部真正的 textField
    public override var isFirstResponder: Bool {
        return textField.isFirstResponder
    }
    
    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
    
    @discardableResult
    public override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
    
    /// 2. 核心修复：消息转发机制
    /// 当系统尝试在当前视图调用不支持的方法（例如 select:, copy:, paste: 等）时触发。
    /// 我们判断内部的 textField 是否支持该方法，如果支持，就把这个动作安全地“转发”给 textField 执行。
    public override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if textField.responds(to: aSelector) {
            return textField
        }
        return super.forwardingTarget(for: aSelector)
    }
}
