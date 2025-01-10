//
//  PTStepper.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 24/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift
import SnapKit

public typealias PTStepperErrorAlert = (_ type:Bool) -> Void
public typealias PTStepperValue = (_ string:String,_ valueChangeType:PTStepperVahleChangeType) -> Void

public enum PTStepperVahleChangeType:Int {
    case Add
    case Reduce
    case Input
}

public enum PTStepperShowType:Int {
    case LTR
    case RTL
}

@objcMembers
public class PTStepper: UIView {

    public var inputingCallback:((String)->Void)?
    
    /// 輸入框的背景顏色
    open var inputBackgroundColor:UIColor = .clear {
        didSet {
            numberText.backgroundColor = inputBackgroundColor
        }
    }
    
    /// 用來展示加減號的位置
    open var viewShowType:PTStepperShowType = .LTR {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// 輸入與按鈕的間隙
    open var contentSpace:CGFloat = 1
    
    // MARK: 輸入提示回調
    open var alertBlock:PTStepperErrorAlert?
    
    // MARK: 輸入回調
    open var valueBlock:PTStepperValue?
    
    // MARK: 支持晃動(默認開)
    open var isShake:Bool = true
    
    // MARK: 數值增減基數(倍數增減)默認1的倍數增減
    open var multipleNum:Int = 1
    
    // MARK: 初始顯示值,默認0
    open var baseNum:String = "0" {
        didSet {
            numberText.text = baseNum
        }
    }
    
    // MARK: 最小值
    open var minNum:Int = 0
    
    // MARK: 最大值
    open var maxNum:Int = 99999
    
    // MARK: 數字框是否支持手動輸入(默認開)
    open var canText:Bool = true {
        didSet {
            numberText.isUserInteractionEnabled = canText
        }
    }
    
    // MARK: 是否顯示邊框(默認開)
    open var hideBorder:Bool = true {
        didSet {
            updateBorders()
        }
    }
    
    // MARK: 邊框顏色
    open var stepperBorderColor:UIColor = .lightGray {
        didSet {
            updateBorders()
        }
    }
    
    // MARK: 按鈕顏色
    open var buttonBackgroundColor:UIColor = .clear {
        didSet {
            addButton.backgroundColor = buttonBackgroundColor
            reduceButton.backgroundColor = buttonBackgroundColor
        }
    }
    
    // MARK: 輸入框字體顏色
    open var numberTextColor:UIColor = .black {
        didSet {
            numberText.textColor = numberTextColor
        }
    }
    
    // MARK: 輸入框字體
    open var numberTextFont:UIFont = .appfont(size: 13) {
        didSet {
            numberText.font = numberTextFont
        }
    }
    
    // MARK: 加號圖片
    open var addImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44)) {
        didSet {
            addButton.setImage(addImage, for: .normal)
        }
    }
    
    // MARK: 減號圖片
    open var reduceImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44)) {
        didSet {
            reduceButton.setImage(reduceImage, for: .normal)
        }
    }
    
    // MARK: 記錄數值
    private var recordNumber:String = ""

    private lazy var addButton : UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(self.addImage, for: .normal)
        view.addActionHandlers(handler: self.handleAddButtonTap)
        return view
    }()
    
    private lazy var reduceButton : UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(self.reduceImage, for: .normal)
        view.addActionHandlers(handler: self.handleReduceButtonTap)
        return view
    }()
    
    private lazy var numberText : UITextField = {
        let view = UITextField()
        view.text = self.baseNum.isEmpty ? "0" : self.baseNum
        view.delegate = self
        view.isUserInteractionEnabled = self.canText
        view.textColor = self.numberTextColor
        view.font = self.numberTextFont
        view.keyboardType = .numberPad
        view.textAlignment = .center
        view.addTarget(self, action: #selector(self.textNumberChange(textField:)), for: .editingChanged)
        view.backgroundColor = self.inputBackgroundColor
        return view
    }()
        
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        addButton.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.width.equalTo(self.addButton.snp.height)
            switch self.viewShowType {
            case .LTR:
                make.left.equalToSuperview()
            case .RTL:
                make.right.equalToSuperview()
            }
        }
        
        reduceButton.snp.remakeConstraints { make in
            make.height.width.equalTo(self.addButton)
            switch self.viewShowType {
            case .LTR:
                make.right.equalToSuperview()
            case .RTL:
                make.left.equalToSuperview()
            }
        }
        
        numberText.snp.remakeConstraints { make in
            switch self.viewShowType {
            case .LTR:
                make.left.equalTo(self.addButton.snp.right).offset(self.contentSpace)
                make.right.equalTo(self.reduceButton.snp.left).offset(-self.contentSpace)
            case .RTL:
                make.right.equalTo(self.addButton.snp.left).offset(-self.contentSpace)
                make.left.equalTo(self.reduceButton.snp.right).offset(self.contentSpace)
            }
            make.top.bottom.equalToSuperview()
        }
    }
    
    private func setupViews() {
        addSubviews([addButton, reduceButton, numberText])
        updateBorders()
    }
    
    private func updateBorders() {
        let borderWidth: CGFloat = hideBorder ? 0.0 : 0.5
        let borderColor = hideBorder ? UIColor.clear.cgColor : stepperBorderColor.cgColor
        
        [reduceButton, numberText, addButton].forEach { button in
            button.layer.borderWidth = borderWidth
            button.layer.borderColor = borderColor
        }
    }
    
    @objc private func textNumberChange(textField: UITextField) {
        guard let text = textField.text, let value = Int(text) else {
            alertAction(max: false)
            textField.text = ""
            return
        }

        if value < minNum {
            alertAction(max: false)
            textField.text = "\(minNum)"
        } else if value > maxNum {
            alertAction(max: true)
            textField.text = "\(maxNum)"
        }
    }
    
    private func handleAddButtonTap(sender: UIButton) {
        self.numberText.resignFirstResponder()
        if let currentValue = Int(self.numberText.text ?? ""), currentValue < self.maxNum {
            self.numberText.text = "\(currentValue + self.multipleNum)"
        } else {
            self.shakeAnimation()
        }
        self.callBack(value: self.numberText.text ?? "", type: .Add)
    }
    
    private func handleReduceButtonTap(sender: UIButton) {
        self.numberText.resignFirstResponder()
        if let currentValue = Int(self.numberText.text ?? ""), currentValue > self.minNum {
            self.numberText.text = "\(currentValue - self.multipleNum)"
        } else {
            self.shakeAnimation()
        }
        self.callBack(value: self.numberText.text ?? "", type: .Reduce)
    }
    
    private func shakeAnimation() {
        if isShake {
            let animation = CAKeyframeAnimation(keyPath: "position.x")
            let positionX = layer.position.x
            animation.values = [positionX - 4, positionX, positionX + 4]
            animation.repeatCount = 3
            animation.duration = 0.07
            animation.autoreverses = true
            layer.add(animation, forKey: nil)
        }
    }
    
    private func callBack(value:String, type:PTStepperVahleChangeType) {
        valueBlock?(value, type)
    }
    
    private func alertAction(max:Bool) {
        alertBlock?(max)
    }
}

extension PTStepper: UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        recordNumber = textField.text ?? ""
        textField.text = ""
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text?.isEmpty ?? true {
            textField.text = recordNumber
        }

        if let text = textField.text, let intValue = Int(text), intValue / multipleNum == 0 {
            textField.text = "\(multipleNum)"
        } else if let text = textField.text {
            textField.text = "\((Int(text) ?? 0) / multipleNum * multipleNum)"
        }
        self.callBack(value: textField.text ?? "", type: .Input)
     }
     
     public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
         // 限制輸入框只允許數字
         self.inputingCallback?(textField.text ?? "")
         return string.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
     }
 }
