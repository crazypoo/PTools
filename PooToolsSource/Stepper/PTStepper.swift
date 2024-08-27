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

    ///輸入框的背景顏色
    open var inputBackgroundColor:UIColor = .clear {
        didSet {
            numberText.backgroundColor = inputBackgroundColor
        }
    }
    ///用來展示加減號的位置
    open var viewShowType:PTStepperShowType = .LTR {
        didSet {
            layoutSubviews()
        }
    }
    ///輸入與按鈕的間隙
    open var contentSpace:CGFloat = 1
    //MARK: 輸入提示回調
    ///輸入提示回調yes:大於最大值,no小於最小值
    open var alertBlock:PTStepperErrorAlert?
    //MARK: 輸入回調
    ///輸入回調
    open var valueBlock:PTStepperValue?
    //MARK: 支持晃動(默認開)
    ///支持晃動(默認開)
    open var isShake:Bool = true
    //MARK: 數值增減基數(倍數增減)默認1的倍數增減
    ///數值增減基數(倍數增減)默認1的倍數增減
    open var multipleNum:Int = 1
    //MARK: 初始顯示值,默認0
    ///初始顯示值,默認0
    open var baseNum:String = "0" {
        didSet {
            numberText.text = baseNum
        }
    }
    //MARK: 最小值
    ///最小值
    open var minNum:Int = 0
    //MARK: 最大值
    ///最大值
    open var maxNum:Int = 99999
    //MARK: 數字框是否支持手動輸入(默認開)
    ///數字框是否支持手動輸入(默認開)
    open var canText:Bool = true {
        didSet {
            numberText.isUserInteractionEnabled = canText
        }
    }
    //MARK: 是否顯示邊框(默認開)
    ///是否顯示邊框(默認開)
    open var hideBorder:Bool = true {
        didSet {
            setupViews()
        }
    }
    //MARK: 邊框顏色
    ///邊框顏色
    open var stepperBorderColor:UIColor = .lightGray {
        didSet {
            setupViews()
        }
    }
    //MARK: 按鈕顏色
    ///按鈕顏色
    open var buttonBackgroundColor:UIColor = .clear {
        didSet {
            addButton.backgroundColor = buttonBackgroundColor
            reduceButton.backgroundColor = buttonBackgroundColor
        }
    }
    //MARK: 輸入框字體顏色
    ///輸入框字體顏色
    open var numberTextColor:UIColor = .black {
        didSet {
            numberText.textColor = numberTextColor
        }
    }
    //MARK: 輸入框字體
    ///輸入框字體
    open var numberTextFont:UIFont = .appfont(size: 13) {
        didSet {
            numberText.font = numberTextFont
        }
    }
    //MARK: 加號圖片
    ///加號圖片
    open var addImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44)) {
        didSet {
            addButton.setImage(addImage, for: .normal)
        }
    }
    //MARK: 減號圖片
    ///減號圖片
    open var reduceImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44)) {
        didSet {
            reduceButton.setImage(reduceImage, for: .normal)
        }
    }
    //MARK: 記錄數值
    ///記錄數值
    private var recordNumber:String = ""
    
    lazy var addButton : UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(self.addImage, for: .normal)
        view.addActionHandlers(handler: { sender in
            self.numberText.resignFirstResponder()
            if self.numberText.text!.int! < self.maxNum {
                self.numberText.text = "\(self.numberText.text!.int! + self.multipleNum)"
            } else {
                self.shakeAnimation()
            }
            self.callBack(value: self.numberText.text!,type: .Add)
        })
        return view
    }()
    
    lazy var reduceButton : UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(self.reduceImage, for: .normal)
        view.addActionHandlers(handler: { sender in
            self.numberText.resignFirstResponder()
            if self.numberText.text!.int! <= self.minNum {
                self.shakeAnimation()
                return
            }
            self.numberText.text = "\(self.numberText.text!.int! - self.multipleNum)"
            self.callBack(value: self.numberText.text!,type: .Reduce)
        })
        return view
    }()
    
    lazy var numberText : UITextField = {
        let view = UITextField()
        if self.baseNum.stringIsEmpty() {
            view.text = "0"
        } else {
            view.text = self.baseNum
        }
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
    
    func setupViews() {
        addButton.removeFromSuperview()
        reduceButton.removeFromSuperview()
        numberText.removeFromSuperview()
        
        addSubviews([addButton, reduceButton, numberText])
        
        if !hideBorder {
            reduceButton.layer.borderWidth = 0.5
            numberText.layer.borderWidth = 0.5
            addButton.layer.borderWidth = 0.5
            
            reduceButton.layer.borderColor = stepperBorderColor.cgColor
            numberText.layer.borderColor = stepperBorderColor.cgColor
            addButton.layer.borderColor = stepperBorderColor.cgColor
        }
        
        layoutSubviews()
    }
    
    func textNumberChange(textField:UITextField) {
        if (textField.text ?? "").stringIsEmpty() {
            alertAction(max: false)
            textField.text = ""
        } else {
            if textField.text!.int! < minNum {
                alertAction(max: false)
                textField.text = ""
            }
            
            if textField.text!.int! > maxNum {
                alertAction(max: true)
                textField.text = ""
                return
            }
        }
    }
    
    func shakeAnimation() {
        if isShake {
            let animation = CAKeyframeAnimation(keyPath: "position.x")
            let positionX = layer.position.x
            animation.values = [(positionX - 4),positionX,(positionX + 4)]
            animation.repeatCount = 3
            animation.duration = 0.07
            animation.autoreverses = true
            layer.add(animation, forKey: nil)
        }
    }
    
    func callBack(value:String,type:PTStepperVahleChangeType) {
        if valueBlock != nil {
            valueBlock!(value,type)
        }
    }
    
    func alertAction(max:Bool) {
        if alertBlock != nil {
            alertBlock!(max)
        }
    }
}

extension PTStepper:UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        recordNumber = textField.text ?? ""
        textField.text = ""
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text?.nsString.length == 0 {
            textField.text = recordNumber
        }
        
        if (textField.text?.int ?? 0) / multipleNum == 0 {
            textField.text = "\(multipleNum)"
        } else {
            textField.text = "\(((textField.text?.int ?? 0) / multipleNum) * multipleNum)"
        }
        callBack(value: textField.text ?? "",type: .Input)
    }
    
    func validateNumber(number:String) -> Bool {
        var res = true
        let tmpSet = NSCharacterSet(charactersIn: "0123456789")
        var i = 0
        while i < number.nsString.length {
            let string = number.nsString.substring(with: NSRange(location: i, length: 1))
            let range = string.nsString.rangeOfCharacter(from: tmpSet as CharacterSet)
            if range.length == 0 {
                res = false
                break
            }
            i += 1
        }
        return res
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        validateNumber(number: string)
    }
}
