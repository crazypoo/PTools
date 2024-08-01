//
//  HoshiTextField.swift
//  TextFieldEffects
//
//  Created by Raúl Riera on 24/01/2015.
//  Copyright (c) 2015 Raul Riera. All rights reserved.
//

import UIKit
import AttributedString

/**
 An HoshiTextField is a subclass of the TextFieldEffects object, is a control that displays an UITextField with a customizable visual effect around the lower edge of the control.
 */
@IBDesignable open class HoshiTextField: TextFieldEffects {
    /**
     The color of the border when it has no content.
     
     This property applies a color to the lower edge of the control. The default value for this property is a clear color.
     */
    @IBInspectable dynamic open var borderInactiveColor: UIColor? {
        didSet {
            updateBorder()
        }
    }
    
    /**
     The color of the border when it has content.
     
     This property applies a color to the lower edge of the control. The default value for this property is a clear color.
     */
    @IBInspectable dynamic open var borderActiveColor: UIColor? {
        didSet {
            updateBorder()
        }
    }
    
    /**
     The color of the placeholder text.

     This property applies a color to the complete placeholder string. The default value for this property is a black color.
     */
    @IBInspectable dynamic open var placeholderColor: UIColor = .black {
        didSet {
            updatePlaceholder()
        }
    }
    
    /**
     The scale of the placeholder font.
     
     This property determines the size of the placeholder label relative to the font size of the text field.
    */
    @IBInspectable dynamic open var placeholderFontScale: CGFloat = 0.65 {
        didSet {
            updatePlaceholder()
        }
    }
    
    dynamic open var placeholderAtt: ASAttributedString? {
        didSet {
            updatePlaceholder()
        }
    }

    override open var placeholder: String? {
        didSet {
            updatePlaceholder()
        }
    }
    
    override open var bounds: CGRect {
        didSet {
            updateBorder()
            updatePlaceholder()
        }
    }
    
    private let borderThickness: (active: CGFloat, inactive: CGFloat) = (active: 2, inactive: 0.5)
    private let placeholderInsets = CGPoint(x: 0, y: 6)
    private let textFieldInsets = CGPoint(x: 0, y: 12)
    private let inactiveBorderLayer = CALayer()
    private let activeBorderLayer = CALayer()
    private var activePlaceholderPoint: CGPoint = CGPoint.zero
    
    // MARK: - TextFieldEffects
    
    override open func drawViewsForRect(_ rect: CGRect) {
        let frame = CGRect(origin: CGPoint.zero, size: CGSize(width: rect.size.width, height: rect.size.height))
        
        placeholderLabel.frame = frame.insetBy(dx: placeholderInsets.x, dy: placeholderInsets.y)
        placeholderLabel.font = placeholderFontFromFont(font!)
        
        updateBorder()
        updatePlaceholder()
        
        layer.addSublayer(inactiveBorderLayer)
        layer.addSublayer(activeBorderLayer)
        addSubview(placeholderLabel)
    }
    
    override open func animateViewsForTextEntry() {
        if text!.isEmpty {
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: .beginFromCurrentState, animations: ({
                self.placeholderLabel.frame.origin = CGPoint(x: 10, y: self.placeholderLabel.frame.origin.y)
                self.placeholderLabel.alpha = 0
            }), completion: { _ in
                self.animationCompletionHandler?(.textEntry)
            })
        }
    
        layoutPlaceholderInTextRect()
        placeholderLabel.frame.origin = activePlaceholderPoint

        UIView.animate(withDuration: 0.4, animations: {
            self.placeholderLabel.alpha = 1.0
        })

        activeBorderLayer.frame = rectForBorder(borderThickness.active, isFilled: true)
    }
    
    override open func animateViewsForTextDisplay() {
        if let text = text, text.isEmpty {
            UIView.animate(withDuration: 0.35, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 2.0, options: .beginFromCurrentState, animations: ({
                self.layoutPlaceholderInTextRect()
                self.placeholderLabel.alpha = 1
            }), completion: { _ in
                self.animationCompletionHandler?(.textDisplay)
            })
            
            activeBorderLayer.frame = self.rectForBorder(self.borderThickness.active, isFilled: false)
            inactiveBorderLayer.frame = self.rectForBorder(self.borderThickness.inactive, isFilled: true)

        }
    }
    
    // MARK: - Private
    
    private func updateBorder() {
        inactiveBorderLayer.frame = rectForBorder(borderThickness.inactive, isFilled: !isFirstResponder)
        inactiveBorderLayer.backgroundColor = borderInactiveColor?.cgColor
        
        activeBorderLayer.frame = rectForBorder(borderThickness.active, isFilled: isFirstResponder)
        activeBorderLayer.backgroundColor = borderActiveColor?.cgColor
    }
    
    private func updatePlaceholder() {
        if let placeholderAtt = placeholderAtt {
            placeholderLabel.attributed.text = placeholderAtt
        } else {
            placeholderLabel.text = placeholder
            placeholderLabel.textColor = placeholderColor
        }
        placeholderLabel.sizeToFit()
        layoutPlaceholderInTextRect()
        
        if isFirstResponder || text!.isNotEmpty {
            animateViewsForTextEntry()
        }
    }
    
    private func placeholderFontFromFont(_ font: UIFont) -> UIFont! {
        let smallerFont = UIFont(descriptor: font.fontDescriptor, size: font.pointSize * placeholderFontScale)
        return smallerFont
    }
    
    private func rectForBorder(_ thickness: CGFloat, isFilled: Bool) -> CGRect {
        if isFilled {
            return CGRect(origin: CGPoint(x: 0, y: frame.height-thickness), size: CGSize(width: frame.width, height: thickness))
        } else {
            return CGRect(origin: CGPoint(x: 0, y: frame.height-thickness), size: CGSize(width: 0, height: thickness))
        }
    }
    
    private func layoutPlaceholderInTextRect() {
        let textRect = self.textRect(forBounds: bounds)
        var originX = textRect.origin.x
        switch self.textAlignment {
        case .center:
            originX += textRect.size.width/2 - placeholderLabel.bounds.width/2
        case .right:
            originX += textRect.size.width - placeholderLabel.bounds.width
        default:
            break
        }
        placeholderLabel.frame = CGRect(x: originX, y: textRect.height/2,
            width: placeholderLabel.bounds.width, height: placeholderLabel.bounds.height)
        activePlaceholderPoint = CGPoint(x: placeholderLabel.frame.origin.x, y: placeholderLabel.frame.origin.y - placeholderLabel.frame.size.height - placeholderInsets.y)

    }
    
    // MARK: - Overrides
    
    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.offsetBy(dx: textFieldInsets.x, dy: textFieldInsets.y)
    }
    
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.offsetBy(dx: textFieldInsets.x, dy: textFieldInsets.y)
    }
}

open class PTHoshiTextField:UITextField {
    private let floatingLabel: UILabel = UILabel()
    
    override open var placeholder: String? {
        didSet {
            updatePlaceholder()
        }
    }
    
    dynamic open var placeholderAtt: ASAttributedString? {
        didSet {
            updatePlaceholder()
        }
    }
    
    dynamic open var placeholderColor: UIColor = .black {
        didSet {
            updatePlaceholder()
        }
    }
    
    dynamic open var placeholderFont: UIFont = .appfont(size: 12) {
        didSet {
            updatePlaceholder()
        }
    }
    
    open var textAndPlceholderSpace:CGFloat = 0 {
        didSet {
            layoutSubviews()
        }
    }
    
    open var leftSpace:CGFloat? {
        didSet {
            layoutSubviews()
        }
    }
    
    open var textEditingEdges:UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    private lazy var leftSpaceView:UIView = {
        let view = UIView()
        view.frame = CGRectMake(0, 0, self.leftSpace!, self.frame.size.height)
        return view
    }()
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    private func setup() {
        addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        addTarget(self, action: #selector(textFieldDidBeginEditing), for: .editingDidBegin)
        addTarget(self, action: #selector(textFieldDidEndEditing), for: .editingDidEnd)
        floatingLabel.textColor = self.placeholderColor
        floatingLabel.font = self.placeholderFont
        floatingLabel.alpha = 0
        let labelHeight = floatingLabel.font.pointSize + 5
        addSubview(floatingLabel)
        floatingLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset((self.bounds.height - labelHeight) / 2)
            make.height.equalTo(labelHeight)
        }
    }

    @objc private func textFieldDidChange() {
        updateFloatingLabel(animated: true)
    }

    @objc private func textFieldDidBeginEditing() {
        updateFloatingLabel(animated: true)
    }

    @objc private func textFieldDidEndEditing() {
        updateFloatingLabel(animated: true)
    }

    private func updateFloatingLabel(animated: Bool) {
        let isTextEmpty = text?.isEmpty ?? true
        let shouldFloat = !isTextEmpty || isFirstResponder

        let animations = {
            let labelHeight = self.floatingLabel.font.pointSize + 5
            self.floatingLabel.alpha = shouldFloat ? 1 : 0
            self.floatingLabel.snp.updateConstraints { make in
                make.top.equalToSuperview().inset(shouldFloat ? self.setTextAndPlaceHolderTop() : (self.bounds.height - labelHeight) / 2)
            }
        }

        if animated {
            UIView.animate(withDuration: 0.3, animations: animations)
        } else {
            animations()
        }
        
        let _ = self.textRect(forBounds: self.bounds)
        let _ = self.editingRect(forBounds: self.bounds)
        let _ = self.placeholderRect(forBounds: self.bounds)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        if (leftSpace ?? 0) > 0 {
            leftView = leftSpaceView
            leftViewMode = .always
        }
        
        let labelHeight = self.floatingLabel.font.pointSize + 5

        let isTextEmpty = text?.isEmpty ?? true
        if !isTextEmpty || isFirstResponder {
            
            floatingLabel.snp.updateConstraints { make in
                make.top.equalToSuperview().inset(self.setTextAndPlaceHolderTop())
            }
            if !isTextEmpty {
                floatingLabel.alpha = 1
            } else {
                floatingLabel.alpha = 0
            }
        } else {
            floatingLabel.snp.updateConstraints { make in
                make.top.equalToSuperview().inset((self.bounds.height - labelHeight) / 2)
            }
            floatingLabel.alpha = 0
        }
    }
    
    private func updatePlaceholder() {
        if let placeholderAtt = placeholderAtt {
            floatingLabel.attributed.text = placeholderAtt
            attributedPlaceholder = placeholderAtt.value
        } else {
            floatingLabel.text = placeholder
            floatingLabel.font = placeholderFont
            floatingLabel.textColor = placeholderColor
        }
        floatingLabel.sizeToFit()
    }
    
    private func setTextAndPlaceHolderTop()->CGFloat {
        let fontToTopHeight = (self.bounds.height - (self.font ?? UIFont.systemFont(ofSize: 14)).pointSize) / 2
        var lessSapce:CGFloat = 0

        if let placeholderAtt = placeholderAtt {
            lessSapce = fontToTopHeight - (placeholderAtt.value.largestFontSize() + 5)
        } else {
            lessSapce = fontToTopHeight - (self.floatingLabel.font.pointSize + 5)
        }
        if lessSapce < 0 {
            lessSapce = 0
        } else {
            if (lessSapce - textAndPlceholderSpace) < 0 {
                lessSapce = 0
            } else {
                lessSapce -= textAndPlceholderSpace
            }
        }
        return lessSapce
    }
    
    open override func textRect(forBounds bounds: CGRect) -> CGRect {
        let isTextEmpty = text?.isEmpty ?? true
        if !isTextEmpty || isFirstResponder {
            if !isTextEmpty {
                return bounds.inset(by: textEditingEdges)
            } else {
                return bounds.inset(by: .zero)
            }
        } else {
            return bounds.inset(by: .zero)
        }
    }

    open override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let isTextEmpty = text?.isEmpty ?? true
        if !isTextEmpty || isFirstResponder {
            if !isTextEmpty {
                return bounds.inset(by: textEditingEdges)
            } else {
                return bounds.inset(by: .zero)
            }
        } else {
            return bounds.inset(by: .zero)
        }
    }

    open override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        let isTextEmpty = text?.isEmpty ?? true
        if !isTextEmpty || isFirstResponder {
            if !isTextEmpty {
                return bounds.inset(by: textEditingEdges)
            } else {
                return bounds.inset(by: .zero)
            }
        } else {
            return bounds.inset(by: .zero)
        }
    }
}

