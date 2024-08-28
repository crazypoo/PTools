//
//  PTInputBoxView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/30.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public enum PTInputBoxConfigurationType {
    case NumberAlphabet
    case Number
    case Alphabet
}

open class PTInputBoxConfiguration :NSObject {
        
    /// 输入框个数
    open var inputBoxNumber: Int = 0
    
    /// 单个输入框的宽度
    open var inputBoxWidth: CGFloat = 0.0
    
    /// 单个输入框的高度
    open var inputBoxHeight: CGFloat = 0.0
    
    /// 单个输入框的边框宽度, Default is 1 pixel
    open var inputBoxBorderWidth: CGFloat = 1.0 / UIScreen.main.scale
    
    /// 单个输入框的边框圆角
    open var inputBoxCornerRadius: CGFloat = 0.0
    
    /// 输入框间距, Default is 5
    open var inputBoxSpacing: CGFloat = 5.0
    
    /// 左边距
    open var leftMargin: CGFloat = 0.0
    
    /// 单个输入框的颜色, Default is lightGrayColor
    open var inputBoxColor: UIColor? = UIColor.lightGray
    
    /// 光标颜色, Default is blueColor
    open var tintColor: UIColor? = UIColor.blue
    
    /// 显示 或 隐藏
    open var secureTextEntry: Bool = false
    
    /// 字体, Default is UIFont.boldSystemFont(ofSize: 16.0)
    open var font: UIFont? = UIFont.boldSystemFont(ofSize: 16.0)
    
    /// 颜色, Default is blackColor
    open var textColor: UIColor? = UIColor.black
    
    /// 输入类型：数字+字母，数字，字母. Default is '.number_alphabet'
    open var inputType: PTInputBoxConfigurationType = PTInputBoxConfigurationType.NumberAlphabet
    
    /// 自动弹出键盘
    open var autoShowKeyboard: Bool = false
    
    /// 默认0.5
    open var autoShowKeyboardDelay: TimeInterval = 0.5
    
    /// 光标闪烁动画, Default is YES
    open var showFlickerAnimation: Bool = true
    
    /// 显示下划线
    open var showUnderLine: Bool = false
    
    /// 下划线尺寸
    open var underLineSize: CGSize = CGSize.zero
    
    /// 下划线颜色, Default is lightGrayColor
    open var underLineColor: UIColor = UIColor.lightGray
    
    ///自定义的输入占位字符，secureTextEntry = false，有效
    open var customInputHolder: String = ""
    
    /// 设置键盘类型
    open var keyboardType: UIKeyboardType = UIKeyboardType.default
    
    /// 使用系统的密码键盘
    open var useSystemPasswordKeyboard: Bool = false
    
    /// 单个输入框输入时的颜色
    open var inputBoxHighlightedColor: UIColor? = nil
    
    /// 下划线高亮颜色
    open var underLineHighlightedColor: UIColor? = nil
    
    /* 输入完成后，可能根据不同的状态，显示不同的颜色。  */
    
    /// 单个输入框输入完成时的颜色
    open var inputBoxFinishColors: [UIColor] = []
    
    /// 下划线高亮颜色
    open var underLineFinishColors: [UIColor] = []
    
    /// 输入完成时字体
    open var finishFonts: [UIFont] = []
    
    /// 输入完成时颜色
    open var finishTextColors: [UIColor] = []
}

public class PTInputBoxView: UIView {
    public var inputBlock: ((_ code: String) -> Void)? = nil
    public var finishBlock: ((_ codeView: PTInputBoxView, _ code: String) -> Void)? = nil
    
    private var config: PTInputBoxConfiguration!
    private var textField: UITextField = UITextField()
    private var inputFinish: Bool = false
    private var inputFinishIndex: Int = 0
    private var layerArray = [CAShapeLayer]()
        
    public init(frame: CGRect, config: PTInputBoxConfiguration) {
        self.config = config
        super.init(frame: frame)
        setupView(frame)
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupView(_ frame: CGRect) {
        guard frame.width > 0, frame.height > 0, config.inputBoxNumber > 0, config.inputBoxWidth <= frame.width else {
            return
        }
        
        config.leftMargin = max(0, (frame.width - config.inputBoxWidth * CGFloat(config.inputBoxNumber) - config.inputBoxSpacing * CGFloat(config.inputBoxNumber - 1)) / 2)
        config.inputBoxWidth = max(0, (frame.width - config.inputBoxSpacing * CGFloat(config.inputBoxNumber - 1) - config.leftMargin * 2) / CGFloat(config.inputBoxNumber))
        config.inputBoxHeight = min(config.inputBoxHeight, frame.height)

        for i in 0..<config.inputBoxNumber {
            let x = config.leftMargin + (config.inputBoxWidth + config.inputBoxSpacing) * CGFloat(i)
            let y = (frame.height - config.inputBoxHeight) / 2
            let textField = createTextField(tag: i, frame: CGRect(x: x, y: y, width: config.inputBoxWidth, height: config.inputBoxHeight))
            addSubview(textField)
            let tap = UITapGestureRecognizer { sender in
                self.tapActioin()
            }
            addGestureRecognizer(tap)
        }

        setupMainTextField(frame)
        NotificationCenter.default.addObserver(self, selector: #selector(textChange), name: UITextField.textDidChangeNotification, object: textField)

        if config.autoShowKeyboard {
            DispatchQueue.main.asyncAfter(deadline: .now() + config.autoShowKeyboardDelay) {
                self.textField.becomeFirstResponder()
            }
        }
    }
    
    private func createTextField(tag: Int, frame: CGRect) -> UITextField {
        let textField = UITextField(frame: frame)
        textField.tag = tag
        textField.textAlignment = .center
        textField.isUserInteractionEnabled = false
        textField.isSecureTextEntry = config.secureTextEntry
        
        PTGCDManager.gcdMain {
            textField.layer.borderWidth = self.config.inputBoxBorderWidth
            textField.layer.cornerRadius = self.config.inputBoxCornerRadius
            textField.layer.borderColor = self.config.inputBoxColor?.cgColor
        }
        
        textField.font = config.font
        textField.textColor = config.textColor
        
        if config.showUnderLine {
            addUnderline(to: textField)
        }

        if config.tintColor != nil {
            addFlickerLayer(to: textField)
        }

        return textField
    }

    private func addUnderline(to textField: UITextField) {
        let underlineFrame = CGRect(x: (textField.frame.width - config.underLineSize.width) / 2,
                                    y: textField.frame.height - config.underLineSize.height,
                                    width: config.underLineSize.width,
                                    height: config.underLineSize.height)
        let underline = UIView(frame: underlineFrame)
        underline.tag = 100
        underline.backgroundColor = config.underLineColor
        textField.addSubview(underline)
    }

    private func addFlickerLayer(to textField: UITextField) {
        let flickerLayerFrame = CGRect(x: (textField.frame.width - 2) / 2,
                                       y: 4,
                                       width: 2,
                                       height: textField.frame.height - 8)
        let flickerLayer = CAShapeLayer()
        flickerLayer.path = UIBezierPath(rect: flickerLayerFrame).cgPath
        flickerLayer.fillColor = config.tintColor?.cgColor
        flickerLayer.add(alphaAnimation(), forKey: "kFlickerAnimation")
        flickerLayer.isHidden = textField.tag != 0

        layerArray.append(flickerLayer)
        textField.layer.addSublayer(flickerLayer)
    }

    private func setupMainTextField(_ frame: CGRect) {
        textField.isHidden = true
        textField.keyboardType = config.keyboardType
        textField.isSecureTextEntry = config.useSystemPasswordKeyboard
        textField.frame = CGRect(x: 0, y: frame.height, width: 0, height: 0)
        if #available(iOS 12.0, *) {
            textField.textContentType = .oneTimeCode
        }
        addSubview(textField)
    }
    
    @objc private func tapActioin() {
        textField.becomeFirstResponder()
    }
    
    @objc private func textChange() {
        setDefault()
        
        let text = textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let filteredText = filterText(text)

        textField.text = filteredText
        inputBlock?(filteredText)
        
        setValue(filteredText as NSString)
        flickerAnimation(filteredText as NSString)

        if inputFinish {
            finish()
        }
    }

    private func filterText(_ text: String) -> String {
        var filteredText = ""
        for character in text {
            switch config.inputType {
            case .NumberAlphabet where character.isNumber || character.isLetter,
                 .Number where character.isNumber,
                 .Alphabet where character.isLetter:
                filteredText.append(character)
            default:
                break
            }
        }
        return String(filteredText.prefix(config.inputBoxNumber))
    }

    private func setDefault() {
        for i in 0..<config.inputBoxNumber {
            let textField = subviews[i] as! UITextField
            textField.text = ""
            textField.layer.borderWidth = self.config.inputBoxBorderWidth
            textField.layer.cornerRadius = self.config.inputBoxCornerRadius
            textField.layer.borderColor = self.config.inputBoxColor?.cgColor
            textField.layoutIfNeeded()

            if config.showFlickerAnimation, layerArray.count > i {
                let layer = layerArray[i]
                layer.isHidden = true
                layer.removeAnimation(forKey: "kFlickerAnimation")
            }
            
            if config.showUnderLine {
                let underline = textField.viewWithTag(100)!
                underline.backgroundColor = config.underLineColor
            }
        }
    }
    
    private func flickerAnimation(_ text: NSString) {
        if config.showFlickerAnimation, text.length < layerArray.count {
            let layer = layerArray[text.length]
            layer.isHidden = false
            layer.add(alphaAnimation(), forKey: "kFlickerAnimation")
        }
    }
    
    private func alphaAnimation() -> CABasicAnimation {
        let alpha = CABasicAnimation(keyPath: "opacity")
        alpha.fromValue = 1.0
        alpha.toValue = 0.0
        alpha.duration = 1.0
        alpha.repeatCount = .greatestFiniteMagnitude
        alpha.isRemovedOnCompletion = false
        alpha.timingFunction = CAMediaTimingFunction(name: .easeOut)
        return alpha
    }
    
    private func setValue(_ text: NSString) {
        inputFinish = text.length == config.inputBoxNumber
        
        for i in 0..<text.length {
            PTGCDManager.gcdGobal {
                let char = text.character(at: i)
                
                var font = self.config.font ?? UIFont.boldSystemFont(ofSize: 16.0)
                var color = self.config.textColor ?? .black
                var inputBoxColor = self.config.inputBoxHighlightedColor
                var underlineColor = self.config.underLineHighlightedColor
                
                if self.inputFinish {
                    font = self.config.finishFonts[safe: self.inputFinishIndex] ?? font
                    color = self.config.finishTextColors[safe: self.inputFinishIndex] ?? color
                    inputBoxColor = self.config.inputBoxFinishColors[safe: self.inputFinishIndex] ?? inputBoxColor
                    underlineColor = self.config.underLineFinishColors[safe: self.inputFinishIndex] ?? underlineColor
                }
                PTGCDManager.gcdMain {
                    let textField = self.subviews[i] as! UITextField
                    textField.text = self.config.customInputHolder.isEmpty ? String(format: "%c", char) : self.config.customInputHolder
                    textField.font = font
                    textField.textColor = color
                    PTGCDManager.gcdAfter(time: 0.01) {
                        textField.layer.borderWidth = self.config.inputBoxBorderWidth
                        textField.layer.borderColor = inputBoxColor?.cgColor
                        if self.config.showUnderLine, let underline = textField.viewWithTag(100) {
                            underline.backgroundColor = underlineColor
                        }
                        textField.layoutIfNeeded()
                    }
                }
            }
        }
        
        let lessCount = self.config.inputBoxNumber - text.length
        if lessCount > 0 {
            for i in 0..<lessCount {
                let textField = self.subviews[text.length + i] as! UITextField
                let font = self.config.font ?? UIFont.boldSystemFont(ofSize: 16.0)
                let color = self.config.textColor ?? .black
                let inputBoxColor = self.config.inputBoxColor
                
                textField.font = font
                textField.textColor = color
                textField.layer.borderWidth = self.config.inputBoxBorderWidth
                textField.layer.borderColor = inputBoxColor?.cgColor
                textField.layoutIfNeeded()
            }
        }

        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    private func finish() {
        finishBlock?(self, textField.text!)
        textField.resignFirstResponder()
        
        for i in 0..<config.inputBoxNumber {
            PTGCDManager.gcdMain {
                let textField = self.subviews[i] as! UITextField
                let font = self.config.font ?? UIFont.boldSystemFont(ofSize: 16.0)
                let color = self.config.textColor ?? .black
                let inputBoxColor = self.config.inputBoxHighlightedColor
                
                textField.font = font
                textField.textColor = color
                textField.layer.borderWidth = self.config.inputBoxBorderWidth
                textField.layer.borderColor = inputBoxColor?.cgColor
                textField.layoutIfNeeded()
            }
        }
    }
    
    public func clear() {
        textField.text = ""
        setDefault()
        flickerAnimation("")
    }

    public func showInput() {
        textField.becomeFirstResponder()
    }
    
    public func hideInput() {
        textField.resignFirstResponder()
    }
    
    public func setCode(_ code: String) {
        let trimmedCode = String(code.prefix(config.inputBoxNumber))
        textField.text = trimmedCode
        setValue(trimmedCode as NSString)
        flickerAnimation(trimmedCode as NSString)
    }
    
    public func getCode() -> String? {
        return textField.text
    }
}
