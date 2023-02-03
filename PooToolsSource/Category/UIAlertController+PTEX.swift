//
//  UIAlertController+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 3/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public extension UIAlertController
{
    //MARK: ALERT真正基类
    ///ALERT真正基类
    class func base_alertVC(title:String? = "",
                                   titleColor:UIColor? = UIColor.black,
                                   titleFont:UIFont? = UIFont.systemFont(ofSize: 15),
                                   msg:String? = "",
                                   msgColor:UIColor? = UIColor.black,
                                   msgFont:UIFont? = UIFont.systemFont(ofSize: 15),
                                   okBtns:[String]? = [String](),
                                   cancelBtn:String? = "",
                                   showIn:UIViewController? = PTUtils.getCurrentVC(),
                                   cancelBtnColor:UIColor? = .systemBlue,
                                   doneBtnColors:[UIColor]? = [UIColor](),
                                   alertBGColor:UIColor? = .white,
                                   alertCornerRadius:CGFloat? = 15,
                                   cancel:(()->Void)? = nil,
                                   moreBtn:((_ index:Int,_ title:String)->Void)?)
    {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        
        if !(cancelBtn!).stringIsEmpty()
        {
            let cancelAction = UIAlertAction(title: cancelBtn, style: .cancel) { (action) in
                if cancel != nil
                {
                    cancel!()
                }
            }
            alert.addAction(cancelAction)
            cancelAction.setValue(cancelBtnColor, forKey: "titleTextColor")
        }
        
        if (okBtns?.count ?? 0) > 0
        {
            var dontArrColor = [UIColor]()
            if doneBtnColors!.count == 0 || okBtns?.count != doneBtnColors?.count || okBtns!.count > (doneBtnColors?.count ?? 0)
            {
                if doneBtnColors!.count == 0
                {
                    okBtns?.enumerated().forEach({ (index,value) in
                        dontArrColor.append(.systemBlue)
                    })
                }
                else if okBtns!.count > (doneBtnColors?.count ?? 0)
                {
                    let count = okBtns!.count - (doneBtnColors?.count ?? 0)
                    dontArrColor = doneBtnColors!
                    for _ in 0..<(count)
                    {
                        dontArrColor.append(.systemBlue)
                    }
                }
                else if okBtns!.count < (doneBtnColors?.count ?? 0)
                {
                    let count = (doneBtnColors?.count ?? 0) - okBtns!.count
                    dontArrColor = doneBtnColors!
                    for _ in 0..<(count)
                    {
                        dontArrColor.removeLast()
                    }
                }
            }
            else
            {
                dontArrColor = doneBtnColors!
            }
            okBtns?.enumerated().forEach({ (index,value) in
                let callAction = UIAlertAction(title: value, style: .default) { (action) in
                    if moreBtn != nil
                    {
                        moreBtn!(index,value)
                    }
                }
                alert.addAction(callAction)
                callAction.setValue(dontArrColor[index], forKey: "titleTextColor")
            })
        }
        
        // KVC修改系统弹框文字颜色字号
        if !(title ?? "").stringIsEmpty()
        {
            let alertStr = NSMutableAttributedString(string: title!)
            let alertStrAttr = [NSAttributedString.Key.foregroundColor: titleColor!, NSAttributedString.Key.font: titleFont!]
            alertStr.addAttributes(alertStrAttr, range: NSMakeRange(0, title!.count))
            alert.setValue(alertStr, forKey: "attributedTitle")
        }
        
        if !(msg ?? "").stringIsEmpty()
        {
            let alertMsgStr = NSMutableAttributedString(string: msg!)
            let alertMsgStrAttr = [NSAttributedString.Key.foregroundColor: msgColor!, NSAttributedString.Key.font: msgFont!]
            alertMsgStr.addAttributes(alertMsgStrAttr, range: NSMakeRange(0, msg!.count))
            alert.setValue(alertMsgStr, forKey: "attributedMessage")
        }

        let subview = alert.view.subviews.first! as UIView
        let alertContentView = subview.subviews.first! as UIView
        if alertBGColor != .white
        {
            alertContentView.backgroundColor = alertBGColor
        }
        alertContentView.layer.cornerRadius = alertCornerRadius!
        
        showIn!.present(alert, animated: true, completion: nil)
    }
    
    class func base_textfiele_alertVC(title:String? = "",
                                             titleColor:UIColor? = UIColor.black,
                                             titleFont:UIFont? = UIFont.systemFont(ofSize: 15),
                                             okBtn:String,
                                             cancelBtn:String,
                                             showIn:UIViewController? = PTUtils.getCurrentVC(),
                                             cancelBtnColor:UIColor? = .black,
                                             doneBtnColor:UIColor? = .systemBlue,
                                             placeHolders:[String],
                                             textFieldTexts:[String],
                                             keyboardType:[UIKeyboardType]?,
                                             textFieldDelegate:Any? = nil,
                                             alertBGColor:UIColor? = .white,
                                             alertCornerRadius:CGFloat? = 15,
                                             cancel:(()->Void)? = nil,
                                             doneBtn:((_ result:[String:String])->Void)?)
    {
        let alert = UIAlertController(title: title, message: "", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: cancelBtn, style: .cancel) { (action) in
            if cancel != nil
            {
                cancel!()
            }
        }
        alert.addAction(cancelAction)
        cancelAction.setValue(cancelBtnColor, forKey: "titleTextColor")

        if placeHolders.count == textFieldTexts.count
        {
            placeHolders.enumerated().forEach({ (index,value) in
                alert.addTextField { (textField : UITextField) -> Void in
                    textField.placeholder = value
                    textField.delegate = (textFieldDelegate as! UITextFieldDelegate)
                    textField.tag = index
                    textField.text = textFieldTexts[index]
                    if keyboardType?.count == placeHolders.count
                    {
                        textField.keyboardType = keyboardType![index]
                    }
                }
            })
        }
        
        let doneAction = UIAlertAction(title: okBtn, style: .default) { (action) in
            var resultDic = [String:String]()
            alert.textFields?.enumerated().forEach({ (index,value) in
                resultDic[value.placeholder!] = value.text
            })
            if doneBtn != nil
            {
                doneBtn!(resultDic)
            }
        }
        alert.addAction(doneAction)
        doneAction.setValue(doneBtnColor, forKey: "titleTextColor")

        // KVC修改系统弹框文字颜色字号
        if !(title ?? "").stringIsEmpty()
        {
            let alertStr = NSMutableAttributedString(string: title!)
            let alertStrAttr = [NSAttributedString.Key.foregroundColor: titleColor!, NSAttributedString.Key.font: titleFont!]
            alertStr.addAttributes(alertStrAttr, range: NSMakeRange(0, title!.count))
            alert.setValue(alertStr, forKey: "attributedTitle")
        }

        let subview = alert.view.subviews.first! as UIView
        let alertContentView = subview.subviews.first! as UIView
        if alertBGColor != .white
        {
            alertContentView.backgroundColor = alertBGColor
        }
        alertContentView.layer.cornerRadius = alertCornerRadius!
        showIn!.present(alert, animated: true, completion: nil)
    }

}
