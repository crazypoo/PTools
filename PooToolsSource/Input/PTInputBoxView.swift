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
    /// 存放光标 --- 2024-05-11 15:14:14
    private var layerArray = [CAShapeLayer]()
        
    override init(frame: CGRect) {
        fatalError("Use init(frame:config:) instead")
    }
    
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
    
    // MARK: --- view layout
    func setupView(_ frame: CGRect){
        if frame.size.width <= 0 || frame.size.height <= 0 || config.inputBoxNumber == 0 || config.inputBoxWidth > frame.size.width {
            return
        }
        
        let spacing = config.inputBoxSpacing
        var width: CGFloat = 0.0
        
        if config.inputBoxWidth > 0 {
            width = config.inputBoxWidth
        }
        
        if width > 0 {
            config.leftMargin = (frame.width - width * CGFloat(config.inputBoxNumber) - spacing * CGFloat(config.inputBoxNumber - 1)) * 0.5
        } else {
            let totalSpacing = spacing * CGFloat(config.inputBoxNumber - 1)
            config.inputBoxWidth = (frame.width - totalSpacing - config.leftMargin * 2.0) / CGFloat(config.inputBoxNumber);
            
            width = config.inputBoxWidth
        }
        
        if config.leftMargin < 0 {
            config.leftMargin = 0
            
            let totalSpacing = spacing * CGFloat(config.inputBoxNumber - 1)
            config.inputBoxWidth = (frame.width - totalSpacing - config.leftMargin * 2.0) / CGFloat(config.inputBoxNumber);
            
            width = config.inputBoxWidth
        }
        
        var height: CGFloat = 0.0
        if config.inputBoxHeight > frame.height {
            config.inputBoxHeight = frame.height
        }
        height = config.inputBoxHeight
        
        if config.showUnderLine {
            if config.underLineSize.width <= 0 {
                config.underLineSize.width = width
            }
            
            if config.underLineSize.height <= 0 {
                config.underLineSize.height = 1
            }
        }
        
        for i in 0..<config.inputBoxNumber {
            
            let x = config.leftMargin + (width + spacing) * CGFloat(i)
            let y = (frame.height - height) * 0.5
            
            let textField = UITextField()
            textField.tag = i
            textField.textAlignment = .center
            textField.isUserInteractionEnabled = false
            textField.isSecureTextEntry = config.secureTextEntry
            textField.frame = CGRect(x: x, y: y, width: width, height: height)
            
            if config.inputBoxBorderWidth > 0 {
                PTGCDManager.gcdMain {
                    textField.layer.borderWidth = self.config.inputBoxBorderWidth
                }
            }
            
            if config.inputBoxCornerRadius > 0 {
                PTGCDManager.gcdMain {
                    textField.layer.cornerRadius = self.config.inputBoxCornerRadius
                }
            }
            
            if config.inputBoxColor != nil {
                PTGCDManager.gcdMain {
                    textField.layer.borderColor = self.config.inputBoxColor?.cgColor
                }
            }
            
            if config.tintColor != nil {
                if width > 2 && height > 8 {
                    let w: CGFloat = 2
                    let y: CGFloat = 4
                    let x: CGFloat = (width - w) * 0.5
                    let h: CGFloat = height - 2 * y
                    
                    let path: UIBezierPath = UIBezierPath(rect: CGRect(x: x, y: y, width: w, height: h))
                    let layer: CAShapeLayer = CAShapeLayer()
                    layer.path = path.cgPath
                    layer.fillColor = config.tintColor?.cgColor
                    layer.add(alphaAnimation(), forKey: "kFlickerAnimation")
                    if i != 0 {
                        layer.isHidden = true
                    }
                    
                    layerArray.append(layer)
                    textField.layer.addSublayer(layer)
                }
            }
            
            if config.font != nil {
                textField.font = config.font
            }
            
            if config.textColor != nil {
                textField.textColor = config.textColor
            }
            
            if config.showUnderLine {
                let x: CGFloat = (width - config.underLineSize.width) * 0.5
                let y: CGFloat = (height - config.underLineSize.height)
                let frame: CGRect = CGRect(x: x, y: y, width: config.underLineSize.width, height: config.underLineSize.height)
                
                let underLine: UIView = UIView()
                underLine.tag = 100
                underLine.frame = frame
                underLine.backgroundColor = config.underLineColor
                textField.addSubview(underLine)
            }
            
            self.addSubview(textField)
        }
        
        self.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(tapActioin)))
        
        textField.isHidden = true
        textField.keyboardType = config.keyboardType
        textField.isSecureTextEntry = config.useSystemPasswordKeyboard
        textField.frame = CGRect(x: 0, y: frame.height, width: 0, height: 0)
        if #available(iOS 12.0, *) {
            textField.textContentType = .oneTimeCode
        }
        self.addSubview(textField)
        
        NotificationCenter.default.addObserver(self, selector: #selector(textChange), name: UITextField.textDidChangeNotification, object: textField)
        
        
        if config.autoShowKeyboard {
            let time: TimeInterval = config.autoShowKeyboardDelay
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + time) {
                self.textField.becomeFirstResponder()
            }
        }
    }
    
    // MARK: --- event
    @objc func tapActioin() {
        textField.becomeFirstResponder()
    }
    
    @objc func textChange() {
        setDefault()
        
        let text: NSString = (textField.text?.trimmingCharacters(in: CharacterSet(charactersIn: " ")) ?? "") as NSString
        
        var filterText: NSString = ""
        for i in 0 ..< text.length {
            let c: unichar = text.character(at: i)
            if config.inputType == PTInputBoxConfigurationType.NumberAlphabet {
                if (c >= 48 && c <= 57) || (c >= 65 && c <= 90) || (c >= 97 && c <= 122) {
                    filterText = filterText.appendingFormat("%c", c)
                }
            } else if config.inputType == PTInputBoxConfigurationType.Number {
                if (c >= 48 && c <= 57) {
                    filterText = filterText.appendingFormat("%c", c)
                }
            } else if config.inputType == PTInputBoxConfigurationType.Alphabet {
                if (c >= 65 && c <= 90) || (c >= 97 && c <= 122) {
                    filterText = filterText.appendingFormat("%c", c)
                }
            }
        }
        
        let count: Int = config.inputBoxNumber
        if filterText.length > count {
            filterText = filterText.substring(to: count) as NSString
        }
        
        textField.text = filterText as String
        if inputBlock != nil {
            inputBlock!(filterText as String)
        }
        
        setValue(filterText)
        
        flickerAnimation(filterText)
        
        if inputFinish {
            finish()
        }
    }
    
    func setDefault() {
        for i in 0..<config.inputBoxNumber {
            let subviews: NSArray = self.subviews as NSArray
            
            let textField = subviews[i] as! UITextField
            textField.text = ""
            
            if config.inputBoxColor != nil {
                textField.layer.borderColor = config.inputBoxColor?.cgColor
            }
            
            if config.showFlickerAnimation && layerArray.count > i {
                let layer = layerArray[i]
                layer.isHidden = true
                layer.removeAnimation(forKey: "kFlickerAnimation")
            }
            
            if config.showUnderLine {
                let underLine: UIView = textField.viewWithTag(100)!
                underLine.backgroundColor = config.underLineColor
            }
        }
    }
    
    func flickerAnimation(_ text: NSString) {
        if config.showFlickerAnimation && text.length < layerArray.count {
            let layer = layerArray[text.length]
            layer.isHidden = false
            layer.add(alphaAnimation(), forKey: "kFlickerAnimation")
        }
    }
    
    func alphaAnimation() -> CABasicAnimation {
        let alpha = CABasicAnimation(keyPath: "opacity")
        alpha.fromValue = NSNumber(1.0)
        alpha.toValue = NSNumber(0.0)
        alpha.duration = Double(1.0)
        alpha.repeatCount = MAXFLOAT
        alpha.isRemovedOnCompletion = false
        alpha.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        return alpha
    }
    
    func setValue(_ text: NSString) {
        inputFinish = text.length == config.inputBoxNumber
        
        for i in 0..<text.length {
            let c: unichar = text.character(at: i)
            let subviews: NSArray = self.subviews as NSArray
            let textField = subviews[i] as! UITextField
            
            textField.text = String.init(format: "%c", c)
            
            if textField.isSecureTextEntry == false && config.customInputHolder.count > 0 {
                textField.text = config.customInputHolder
            }
            
            // Input Status
            var font: UIFont = config.font ?? UIFont.boldSystemFont(ofSize: 16.0)
            var color: UIColor = config.textColor ?? UIColor.black
            var inputBoxColor: UIColor? = config.inputBoxHighlightedColor
            var underLineColor: UIColor? = config.underLineHighlightedColor
            
            // Finish Status
            if inputFinish {
                if inputFinishIndex < config.finishFonts.count {
                    let fonts: NSArray = config.finishFonts as NSArray
                    font = fonts[inputFinishIndex] as! UIFont
                }
                if inputFinishIndex < config.finishTextColors.count {
                    let colors: NSArray = config.finishTextColors as NSArray
                    color = colors[inputFinishIndex] as! UIColor
                }
                if inputFinishIndex < config.inputBoxFinishColors.count {
                    let colors: NSArray = config.inputBoxFinishColors as NSArray
                    inputBoxColor = colors[inputFinishIndex] as? UIColor
                }
                if inputFinishIndex < config.underLineFinishColors.count {
                    let colors: NSArray = config.underLineFinishColors as NSArray
                    underLineColor = colors[inputFinishIndex] as? UIColor
                }
            }
            
            textField.font = font
            textField.textColor = color
            
            if inputBoxColor != nil {
                textField.layer.borderColor = inputBoxColor!.cgColor
            }
            
            if config.showUnderLine && underLineColor != nil {
                let underLine: UIView? = textField.viewWithTag(100) ?? nil
                underLine?.backgroundColor = underLineColor
            }
        }
    }
    
    func finish() {
        if finishBlock != nil {
            finishBlock!(self, textField.text!)
        }
        
        PTGCDManager.gcdAfter(time: 0.1) {
            self.textField.resignFirstResponder()
        }
    }
    
    public func clear() {
        textField.text = "";
        
        setDefault()
        flickerAnimation("")
    }
    
    public func showInputFinishColorWithIndex(_ index: Int) {
        inputFinishIndex = index
        
        guard let text = textField.text else { return }
        setValue(text as NSString)
    }
}
