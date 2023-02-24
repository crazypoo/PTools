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
public typealias PTStepperValue = (_ string:String) -> Void
@objcMembers
public class PTStepper: UIView {

    //MARK: 輸入提示回調
    ///輸入提示回調yes:大於最大值,no小於最小值
    public var alertBlock:PTStepperErrorAlert?
    //MARK: 輸入回調
    ///輸入回調
    public var valueBlock:PTStepperValue?
    //MARK: 支持晃動(默認開)
    ///支持晃動(默認開)
    public var isShake:Bool = true
    //MARK: 數值增減基數(倍數增減)默認1的倍數增減
    ///數值增減基數(倍數增減)默認1的倍數增減
    public var multipleNum:Int = 1
    //MARK: 初始顯示值,默認0
    ///初始顯示值,默認0
    public var baseNum:String = "0"
    {
        didSet
        {
            self.numberText.text = self.baseNum
        }
    }
    //MARK: 最小值
    ///最小值
    public var minNum:Int = 0
    //MARK: 最大值
    ///最大值
    public var maxNum:Int = 99999
    //MARK: 數字框是否支持手動輸入(默認開)
    ///數字框是否支持手動輸入(默認開)
    public var canText:Bool = true
    {
        didSet
        {
            self.numberText.isUserInteractionEnabled = self.canText
        }
    }
    //MARK: 是否顯示邊框(默認開)
    ///是否顯示邊框(默認開)
    public var hideBorder:Bool = true
    {
        didSet
        {
            self.setupViews()
        }
    }
    //MARK: 邊框顏色
    ///邊框顏色
    public var stepperBorderColor:UIColor = .lightGray
    {
        didSet
        {
            self.setupViews()
        }
    }
    //MARK: 按鈕顏色
    ///按鈕顏色
    public var buttonBackgroundColor:UIColor = .clear
    {
        didSet
        {
            self.addButton.backgroundColor = self.buttonBackgroundColor
            self.reduceButton.backgroundColor = self.buttonBackgroundColor
        }
    }
    //MARK: 輸入框字體顏色
    ///輸入框字體顏色
    public var numberTextColor:UIColor = .black
    {
        didSet
        {
            self.numberText.textColor = self.numberTextColor
        }
    }
    //MARK: 輸入框字體
    ///輸入框字體
    public var numberTextFont:UIFont = .appfont(size: 13)
    {
        didSet
        {
            self.numberText.font = self.numberTextFont
        }
    }
    //MARK: 加號圖片
    ///加號圖片
    public var addImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44))
    {
        didSet
        {
            self.addButton.setImage(self.addImage, for: .normal)
        }
    }
    //MARK: 減號圖片
    ///減號圖片
    public var reduceImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44))
    {
        didSet
        {
            self.reduceButton.setImage(self.reduceImage, for: .normal)
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
            if self.numberText.text!.int! < self.maxNum
            {
                self.numberText.text = "\(self.numberText.text!.int! + self.multipleNum)"
            }
            else
            {
                self.shakeAnimation()
            }
            self.callBack(value: self.numberText.text!)
        })
        return view
    }()
    
    lazy var reduceButton : UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(self.reduceImage, for: .normal)
        view.addActionHandlers(handler: { sender in
            self.numberText.resignFirstResponder()
            if self.numberText.text!.int! <= self.minNum
            {
                self.shakeAnimation()
                return
            }
            self.numberText.text = "\(self.numberText.text!.int! - self.multipleNum)"
            self.callBack(value: self.numberText.text!)
        })
        return view
    }()
    
    lazy var numberText : UITextField = {
        let view = UITextField()
        if self.baseNum.stringIsEmpty()
        {
            view.text = "0"
        }
        else
        {
            view.text = self.baseNum
        }
        view.delegate = self
        view.isUserInteractionEnabled = self.canText
        view.textColor = self.numberTextColor
        view.font = self.numberTextFont
        view.keyboardType = .numberPad
        view.textAlignment = .center
        view.addTarget(self, action: #selector(self.textNumberChange(textField:)), for: .editingChanged)
        return view
    }()
        
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        self.addButton.snp.makeConstraints { make in
            make.height.equalToSuperview()
            make.width.equalTo(self.addButton.snp.height)
            make.left.equalToSuperview()
        }
        
        self.reduceButton.snp.makeConstraints { make in
            make.height.width.equalTo(self.addButton)
            make.right.equalToSuperview()
        }
        
        self.numberText.snp.makeConstraints { make in
            make.left.equalTo(self.addButton.snp.right).offset(CGFloat.ScaleW(w: 1))
            make.right.equalTo(self.reduceButton.snp.left).offset(-CGFloat.ScaleW(w: 1))
            make.top.bottom.equalToSuperview()
        }
    }
    
    func setupViews()
    {
        self.addButton.removeFromSuperview()
        self.reduceButton.removeFromSuperview()
        self.numberText.removeFromSuperview()
        
        self.addSubviews([self.addButton,self.reduceButton,self.numberText])
        
        if !self.hideBorder
        {
            self.reduceButton.layer.borderWidth = 0.5
            self.numberText.layer.borderWidth = 0.5
            self.addButton.layer.borderWidth = 0.5
            
            self.reduceButton.layer.borderColor = self.stepperBorderColor.cgColor
            self.numberText.layer.borderColor = self.stepperBorderColor.cgColor
            self.addButton.layer.borderColor = self.stepperBorderColor.cgColor
        }
        
        self.layoutSubviews()
    }
    
    func textNumberChange(textField:UITextField)
    {
        if textField.text!.int! < self.minNum
        {
            self.alertAction(max: false)
            textField.text = ""
        }
        
        if textField.text!.int! > self.maxNum
        {
            self.alertAction(max: true)
            textField.text = ""
            return
        }
    }
    
    func shakeAnimation()
    {
        if self.isShake
        {
            let animation = CAKeyframeAnimation(keyPath: "position.x")
            let positionX = self.layer.position.x
            animation.values = [(positionX - 4),positionX,(positionX + 4)]
            animation.repeatCount = 3
            animation.duration = 0.07
            animation.autoreverses = true
            self.layer.add(animation, forKey: nil)
        }
    }
    
    func callBack(value:String)
    {
        if self.valueBlock != nil
        {
            self.valueBlock!(value)
        }
    }
    
    func alertAction(max:Bool)
    {
        if self.alertBlock != nil
        {
            self.alertBlock!(max)
        }
    }
}

extension PTStepper:UITextFieldDelegate
{
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        self.recordNumber = textField.text ?? ""
        textField.text = ""
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text?.nsString.length == 0
        {
            textField.text = self.recordNumber
        }
        
        if (textField.text?.int ?? 0) / self.multipleNum == 0
        {
            textField.text = "\(self.multipleNum)"
        }
        else
        {
            textField.text = "\(((textField.text?.int ?? 0) / self.multipleNum) * self.multipleNum)"
        }
        self.callBack(value: textField.text ?? "")
    }
    
    func validateNumber(number:String) -> Bool
    {
        var res = true
        let tmpSet = NSCharacterSet(charactersIn: "0123456789")
        var i = 0
        while i < number.nsString.length {
            let string = number.nsString.substring(with: NSRange(location: i, length: 1))
            let range = string.nsString.rangeOfCharacter(from: tmpSet as CharacterSet)
            if range.length == 0
            {
                res = false
                break
            }
            i += 1
        }
        return res
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return self.validateNumber(number: string)
    }
}
