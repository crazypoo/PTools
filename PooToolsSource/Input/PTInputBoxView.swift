//
//  PTInputBoxView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/30.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

public enum PTInputBoxConfigurationType {
    case NumberAlphabet
    case Number
    case Alphabet
}

// MARK: - Configuration
open class PTInputBoxConfiguration {
    /// 输入框个数
    open var inputBoxNumber: Int = 4
    /// 单个输入框的宽度
    open var inputBoxWidth: CGFloat = 45.0
    /// 单个输入框的高度
    open var inputBoxHeight: CGFloat = 45.0
    /// 单个输入框的边框宽度
    open var inputBoxBorderWidth: CGFloat = 1.0 / UIScreen.main.scale
    /// 单个输入框的边框圆角
    open var inputBoxCornerRadius: CGFloat = 6.0
    /// 输入框间距
    open var inputBoxSpacing: CGFloat = 10.0
    
    /// 单个输入框的默认边框颜色
    open var inputBoxColor: UIColor = .lightGray
    /// 单个输入框输入时的边框高亮颜色
    open var inputBoxHighlightedColor: UIColor = .systemBlue
    /// 单个输入框输入完成时的边框颜色 (可选)
    open var inputBoxFinishColor: UIColor?
    
    /// 光标颜色
    open var tintColor: UIColor = .systemBlue
    /// 是否显示为密文
    open var secureTextEntry: Bool = false
    /// 字体
    open var font: UIFont = UIFont.boldSystemFont(ofSize: 20.0)
    /// 文字颜色
    open var textColor: UIColor = .black
    /// 输入类型
    open var inputType: PTInputBoxConfigurationType = .NumberAlphabet
    
    /// 自动弹出键盘
    open var autoShowKeyboard: Bool = true
    /// 光标闪烁动画
    open var showFlickerAnimation: Bool = true
    
    /// 显示下划线
    open var showUnderLine: Bool = false
    /// 下划线高度
    open var underLineHeight: CGFloat = 2.0
    /// 下划线默认颜色
    open var underLineColor: UIColor = .lightGray
    /// 下划线高亮颜色
    open var underLineHighlightedColor: UIColor = .systemBlue
    
    /// 自定义的输入占位字符 (当 secureTextEntry = false 时有效，比如填入 "●")
    open var customInputHolder: String = ""
    /// 键盘类型
    open var keyboardType: UIKeyboardType = .numberPad
    /// 是否开启触觉震动反馈 (新功能)
    open var enableHapticFeedback: Bool = true
    
    public init() {}
}

// MARK: - Main View
public class PTInputBoxView: UIView {
    
    // 回调闭包
    public var inputBlock: ((_ code: String) -> Void)?
    public var finishBlock: ((_ codeView: PTInputBoxView, _ code: String) -> Void)?
    
    private var config: PTInputBoxConfiguration
    
    // 隐藏的实际输入框，用于拉起键盘和接收字符
    private lazy var hiddenTextField: UITextField = {
        let tf = UITextField()
        tf.isHidden = true
        tf.keyboardType = config.keyboardType
        tf.isSecureTextEntry = config.secureTextEntry
        tf.textContentType = .oneTimeCode // 支持自动填充验证码
        tf.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        return tf
    }()
    
    // 用于管理多个视觉框的 StackView
    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = config.inputBoxSpacing
        stack.isUserInteractionEnabled = false
        return stack
    }()
    
    // 存储视觉表现的 Label 数组
    private var visualLabels: [UILabel] = []
    // 存储光标 Layer 的数组
    private var cursorLayers: [CAShapeLayer] = []
    // 存储下划线的数组
    private var underLineViews: [UIView] = []
    
    // MARK: - Init
    public init(config: PTInputBoxConfiguration) {
        self.config = config
        super.init(frame: .zero)
        setupView()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupView() {
        addSubview(hiddenTextField)
        addSubview(stackView)
        
        // 使用 SnapKit 布局 StackView，让其居中并自适应内容
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(config.inputBoxHeight)
        }
        
        for _ in 0..<config.inputBoxNumber {
            let containerView = UIView()
            
            // 设置容器的宽高约束
            containerView.snp.makeConstraints { make in
                make.width.equalTo(config.inputBoxWidth)
            }
            
            // 创建显示的 Label
            let label = UILabel()
            label.textAlignment = .center
            label.font = config.font
            label.textColor = config.textColor
            label.layer.borderWidth = config.inputBoxBorderWidth
            label.layer.cornerRadius = config.inputBoxCornerRadius
            label.layer.borderColor = config.inputBoxColor.cgColor
            label.clipsToBounds = true
            
            containerView.addSubview(label)
            label.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            visualLabels.append(label)
            
            // 创建下划线 (如果需要)
            if config.showUnderLine {
                let underLine = UIView()
                underLine.backgroundColor = config.underLineColor
                containerView.addSubview(underLine)
                underLine.snp.makeConstraints { make in
                    make.leading.trailing.bottom.equalToSuperview()
                    make.height.equalTo(config.underLineHeight)
                }
                underLineViews.append(underLine)
            }
            
            // 创建光标
            if config.showFlickerAnimation {
                let cursorPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 2, height: config.inputBoxHeight * 0.6))
                let cursorLayer = CAShapeLayer()
                cursorLayer.path = cursorPath.cgPath
                cursorLayer.fillColor = config.tintColor.cgColor
                cursorLayer.isHidden = true // 默认隐藏
                containerView.layer.addSublayer(cursorLayer)
                cursorLayers.append(cursorLayer)
                
                // 让光标居中 (利用 layer 的 position)
                DispatchQueue.main.async {
                    cursorLayer.position = CGPoint(x: self.config.inputBoxWidth / 2 - 1,
                                                   y: self.config.inputBoxHeight * 0.2)
                }
            }
            
            stackView.addArrangedSubview(containerView)
        }
        
        // 添加点击手势，点击任意区域都拉起键盘
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        self.addGestureRecognizer(tap)
        
        // 初始状态更新
        updateUIState()
        
        if config.autoShowKeyboard {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.hiddenTextField.becomeFirstResponder()
            }
        }
    }
    
    // MARK: - Actions
    @objc private func viewTapped() {
        hiddenTextField.becomeFirstResponder()
    }
    
    @objc private func textDidChange(_ textField: UITextField) {
        var text = textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        text = filterText(text)
        
        textField.text = text
        inputBlock?(text)
        
        updateUIState()
        
        if text.count == config.inputBoxNumber {
            handleInputFinish(text: text)
        }
    }
    
    // MARK: - Logic & UI Update
    private func filterText(_ text: String) -> String {
        let filtered = text.filter { character in
            switch config.inputType {
            case .NumberAlphabet: return character.isNumber || character.isLetter
            case .Number: return character.isNumber
            case .Alphabet: return character.isLetter
            }
        }
        return String(filtered.prefix(config.inputBoxNumber))
    }
    
    private func updateUIState() {
        let text = hiddenTextField.text ?? ""
        let textArray = Array(text)
        
        for i in 0..<config.inputBoxNumber {
            let label = visualLabels[i]
            
            // 1. 设置文字内容
            if i < textArray.count {
                let char = textArray[i]
                if config.secureTextEntry {
                    label.text = "●"
                } else {
                    label.text = config.customInputHolder.isEmpty ? String(char) : config.customInputHolder
                }
            } else {
                label.text = ""
            }
            
            // 2. 设置高亮/默认颜色样式
            let isCurrentOrFilled = (i <= text.count && text.count != config.inputBoxNumber) || (i < text.count)
            let isHighlight = i == text.count // 当前正要输入的框
            
            UIView.animate(withDuration: 0.2) {
                // 边框颜色
                label.layer.borderColor = isCurrentOrFilled ? self.config.inputBoxHighlightedColor.cgColor : self.config.inputBoxColor.cgColor
                
                // 下划线颜色
                if self.config.showUnderLine {
                    let underLine = self.underLineViews[i]
                    underLine.backgroundColor = isCurrentOrFilled ? self.config.underLineHighlightedColor : self.config.underLineColor
                }
            }
            
            // 3. 处理光标动画
            if config.showFlickerAnimation {
                let cursor = cursorLayers[i]
                if isHighlight && hiddenTextField.isFirstResponder {
                    cursor.isHidden = false
                    startFlickerAnimation(for: cursor)
                } else {
                    cursor.isHidden = true
                    cursor.removeAnimation(forKey: "flicker")
                }
            }
        }
    }
    
    private func handleInputFinish(text: String) {
        hiddenTextField.resignFirstResponder()
        
        // 输入完成时的颜色处理
        if let finishColor = config.inputBoxFinishColor {
            for label in visualLabels {
                label.layer.borderColor = finishColor.cgColor
            }
        }
        
        // 触觉震动反馈
        if config.enableHapticFeedback {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
        
        finishBlock?(self, text)
    }
    
    private func startFlickerAnimation(for layer: CAShapeLayer) {
        guard layer.animation(forKey: "flicker") == nil else { return }
        let alphaAnimation = CABasicAnimation(keyPath: "opacity")
        alphaAnimation.fromValue = 1.0
        alphaAnimation.toValue = 0.0
        alphaAnimation.duration = 0.8
        alphaAnimation.repeatCount = .greatestFiniteMagnitude
        alphaAnimation.isRemovedOnCompletion = false
        alphaAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(alphaAnimation, forKey: "flicker")
    }
    
    // MARK: - Public APIs
    public func clear() {
        hiddenTextField.text = ""
        updateUIState()
        if config.autoShowKeyboard {
            hiddenTextField.becomeFirstResponder()
        }
    }
    
    public func showInput() {
        hiddenTextField.becomeFirstResponder()
        updateUIState() // 刷新光标状态
    }
    
    public func hideInput() {
        hiddenTextField.resignFirstResponder()
        updateUIState() // 刷新光标状态
    }
    
    public func setCode(_ code: String) {
        hiddenTextField.text = code
        textDidChange(hiddenTextField)
    }
    
    public func getCode() -> String? {
        return hiddenTextField.text
    }
}
