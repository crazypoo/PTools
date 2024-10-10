//
//  UIAlertController+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 3/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

public extension UIAlertController {
    //MARK: 單按鈕Alert
    ///單按鈕Alert
    /// - Parameters:
    ///   - title: 標題
    ///   - msg: 內容
    ///   - cancel: 取消按鈕
    ///   - cancelBlock: 取消回調
    @objc class func alertVC(title:String? = "",
                             msg:String? = "",
                             cancel:String? = "PT Button cancel".localized(),
                             cancelBlock:PTActionTask?) {
        UIAlertController.base_alertVC(title: title,msg: msg,cancelBtn:cancel,cancel: cancelBlock)
    }
    
    //MARK: ActionSheet基類
    ///ActionSheet基類
    /// - Parameters:
    ///   - title: 標題
    ///   - subTitle: 子標題
    ///   - cancelButtonName: 取消按鈕
    ///   - destructiveButtons: 擴展按鈕(s)
    ///   - titles: 其他標題
    ///   - canTapBackground:
    ///   - destructiveBlock: 擴展回調
    ///   - cancelBlock: 取消回調
    ///   - otherBlock: 其他回調
    ///   - tapBackgroundBlock: 点击背景消失回调
    ///   - canTapBackground:
    @objc class func baseActionSheet(title:String,
                                     subTitle:String? = "",
                                     cancelButtonName:String = "PT Button cancel".localized(),
                                     destructiveButtons:[String] = [String](),
                                     titles:[String],
                                     canTapBackground:Bool = true,
                                     destructiveBlock:PTActionSheetIndexCallback? = nil,
                                     cancelBlock: PTActionSheetCallback? = nil,
                                     otherBlock: @escaping PTActionSheetIndexCallback,
                                     tapBackgroundBlock: PTActionSheetCallback? = nil) {
        
        let titleItem = PTActionSheetTitleItem(title: title,subTitle: subTitle!)
        let cancelItem = PTActionSheetItem(title: cancelButtonName)

        var destructiveItems = [PTActionSheetItem]()
        destructiveButtons.enumerated().forEach { index,value in
            let item = PTActionSheetItem(title: value)
            item.titleColor = .systemRed
            destructiveItems.append(item)
        }
        
        var contentItems = [PTActionSheetItem]()
        titles.enumerated().forEach { index,value in
            let item = PTActionSheetItem(title: value)
            contentItems.append(item)
        }
        
        let viewConfig = PTActionSheetViewConfig(dismissWithTapBG: canTapBackground)
                
        let actionSheet = PTActionSheetController(viewConfig:viewConfig,titleItem:titleItem,cancelItem:cancelItem,destructiveItems: destructiveItems,contentItems: contentItems,canTapBackground: canTapBackground)
        actionSheet.actionSheetDestructiveSelectBlock = destructiveBlock
        actionSheet.actionSheetCancelSelectBlock = cancelBlock
        actionSheet.actionSheetSelectBlock = otherBlock
        actionSheet.tapBackgroundBlock = tapBackgroundBlock
        PTAlertManager.show(actionSheet)

    }
    
    @objc class func baseCustomActionSheet(viewConfig:PTActionSheetViewConfig = PTActionSheetViewConfig(),titleItem:PTActionSheetTitleItem,
                                           cancelItem:PTActionSheetItem = PTActionSheetItem(title: "PT Button cancel".localized()),
                                           destructiveItems:[PTActionSheetItem] = [PTActionSheetItem](),
                                           contentItems:[PTActionSheetItem],
                                           destructiveBlock:PTActionSheetIndexCallback? = nil,
                                           cancelBlock: PTActionSheetCallback? = nil,
                                           otherBlock: @escaping PTActionSheetIndexCallback,
                                           canTapBackground:Bool = false,
                                           tapBackgroundBlock: PTActionSheetCallback? = nil) {
                                
        let actionSheet = PTActionSheetController(viewConfig:viewConfig,titleItem:titleItem,cancelItem:cancelItem,destructiveItems: destructiveItems,contentItems: contentItems,canTapBackground: canTapBackground)
        actionSheet.actionSheetDestructiveSelectBlock = destructiveBlock
        actionSheet.actionSheetCancelSelectBlock = cancelBlock
        actionSheet.actionSheetSelectBlock = otherBlock
        actionSheet.tapBackgroundBlock = tapBackgroundBlock
        PTAlertManager.show(actionSheet)
    }
    
    //MARK: ALERT真正基类
    ///ALERT真正基类
    /// - Parameters:
    ///   - title: 標題
    ///   - titleColor: 標題顏色
    ///   - titleFont: 標題字體
    ///   - msg: 內容
    ///   - msgColor: 內容顏色
    ///   - msgFont:
    ///   - okBtns: 更多按鈕(數組)
    ///   - cancelBtn: 取消按鈕
    ///   - showIn: 在哪裏顯示
    ///   - cancelBtnColor: 取消按鈕顏色
    ///   - doneBtnColors: 更多按鈕顏色(數組)
    ///   - alertBGColor: 背景顏色
    ///   - alertCornerRadius: 圓角
    ///   - cancel: 取消回調
    ///   - moreBtn: 更多按鈕點擊回調
    ///   - msgFont:
    class func base_alertVC(title:String? = "",
                            titleColor:UIColor? = PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white),
                            titleFont:UIFont? = UIFont.systemFont(ofSize: 15),
                            msg:String? = "",
                            msgColor:UIColor? = PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white),
                            msgFont:UIFont? = UIFont.systemFont(ofSize: 15),
                            okBtns:[String]? = [String](),
                            cancelBtn:String? = "",
                            showIn:UIViewController? = PTUtils.getCurrentVC(),
                            cancelBtnColor:UIColor? = .systemBlue,
                            doneBtnColors:[UIColor]? = [UIColor](),
                            alertBGColor:UIColor? = .white,
    @PTClampedProperyWrapper(range:0...15) alertCornerRadius:CGFloat = 15,
                            cancel:PTActionTask? = nil,
                            moreBtn: ((_ index:Int,_ title:String)->Void)? = nil) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        
        if !(cancelBtn!).stringIsEmpty() {
            let cancelAction = UIAlertAction(title: cancelBtn, style: .cancel) { (action) in
                if cancel != nil {
                    cancel!()
                }
            }
            cancelAction.setValue(cancelBtnColor, forKey: "titleTextColor")
            alert.addAction(cancelAction)
        }
        
        if (okBtns?.count ?? 0) > 0 {
            var dontArrColor = [UIColor]()
            if doneBtnColors!.count == 0 || okBtns?.count != doneBtnColors?.count || okBtns!.count > (doneBtnColors?.count ?? 0) {
                if doneBtnColors!.count == 0 {
                    okBtns?.enumerated().forEach({ (index,value) in
                        dontArrColor.append(.systemBlue)
                    })
                } else if okBtns!.count > (doneBtnColors?.count ?? 0) {
                    let count = okBtns!.count - (doneBtnColors?.count ?? 0)
                    dontArrColor = doneBtnColors!
                    for _ in 0..<(count) {
                        dontArrColor.append(.systemBlue)
                    }
                } else if okBtns!.count < (doneBtnColors?.count ?? 0) {
                    let count = (doneBtnColors?.count ?? 0) - okBtns!.count
                    dontArrColor = doneBtnColors!
                    for _ in 0..<(count) {
                        dontArrColor.removeLast()
                    }
                }
            } else {
                dontArrColor = doneBtnColors!
            }
            okBtns?.enumerated().forEach({ (index,value) in
                let callAction = UIAlertAction(title: value, style: .default) { (action) in
                    if moreBtn != nil {
                        moreBtn!(index,value)
                    }
                }
                callAction.setValue(dontArrColor[index], forKey: "titleTextColor")
                alert.addAction(callAction)
            })
        }
        
        // KVC修改系统弹框文字颜色字号
        if !(title ?? "").stringIsEmpty() {
            let alertStr = NSMutableAttributedString(string: title!)
            let alertStrAttr = [NSAttributedString.Key.foregroundColor: titleColor!, NSAttributedString.Key.font: titleFont!]
            alertStr.addAttributes(alertStrAttr, range: NSMakeRange(0, title!.count))
            alert.setValue(alertStr, forKey: "attributedTitle")
        }
        
        if !(msg ?? "").stringIsEmpty() {
            let alertMsgStr = NSMutableAttributedString(string: msg!)
            let alertMsgStrAttr = [NSAttributedString.Key.foregroundColor: msgColor!, NSAttributedString.Key.font: msgFont!]
            alertMsgStr.addAttributes(alertMsgStrAttr, range: NSMakeRange(0, msg!.count))
            alert.setValue(alertMsgStr, forKey: "attributedMessage")
        }

        let subview = alert.view.subviews.first! as UIView
        let alertContentView = subview.subviews.first! as UIView
        if alertBGColor != .white {
            alertContentView.backgroundColor = alertBGColor
        }
                                alertContentView.layer.cornerRadius = alertCornerRadius
        
        showIn!.present(alert, animated: true, completion: nil)
    }
    
    //MARK: ALERT輸入框基類
    ///ALERT輸入框基類
    /// - Parameters:
    ///   - title: 標題
    ///   - titleColor: 標題顏色
    ///   - titleFont: 標題字體
    ///   - okBtn: 更多按鈕(數組)
    ///   - cancelBtn: 取消按鈕
    ///   - showIn: 在哪裏顯示
    ///   - cancelBtnColor: 取消按鈕顏色
    ///   - doneBtnColor: 更多按鈕顏色(數組)
    ///   - placeHolders: 輸入框底字(數組)
    ///   - textFieldTexts:輸入框文字(數組)
    ///   - keyboardType: 輸入框鍵盤類型(數組)
    ///   - textFieldDelegate:輸入框代理
    ///   - alertBGColor: 背景顏色
    ///   - alertCornerRadius: 圓角
    ///   - cancel: 取消回調
    ///   - doneBtn: 更多按鈕點擊回調
    class func base_textfield_alertVC(title:String? = "",
                                      titleColor:UIColor? = PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white),
                                      titleFont:UIFont? = UIFont.systemFont(ofSize: 15),
                                      okBtn:String,
                                      cancelBtn:String,
                                      showIn:UIViewController? = PTUtils.getCurrentVC(),
                                      cancelBtnColor:UIColor? = PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white),
                                      doneBtnColor:UIColor? = .systemBlue,
                                      placeHolders:[String],
                                      textFieldTexts:[String],
                                      keyboardType:[UIKeyboardType]?,
                                      textFieldDelegate:UITextFieldDelegate,
                                      alertBGColor:UIColor? = .white,
    @PTClampedProperyWrapper(range:0...15) alertCornerRadius:CGFloat = 15,
                                      cancel:PTActionTask? = nil,
                                      doneBtn:((_ result:[String:String])->Void)?) {
        let alert = UIAlertController(title: title, message: "", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: cancelBtn, style: .cancel) { (action) in
            if cancel != nil {
                cancel!()
            }
        }
        cancelAction.setValue(cancelBtnColor, forKey: "titleTextColor")
        alert.addAction(cancelAction)

        if placeHolders.count == textFieldTexts.count {
            placeHolders.enumerated().forEach({ (index,value) in
                alert.addTextField { (textField : UITextField) -> Void in
                    textField.placeholder = value
                    textField.delegate = textFieldDelegate
                    textField.tag = index
                    textField.text = textFieldTexts[index]
                    if keyboardType?.count == placeHolders.count {
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
            if doneBtn != nil {
                doneBtn!(resultDic)
            }
        }
        doneAction.setValue(doneBtnColor, forKey: "titleTextColor")
        alert.addAction(doneAction)

        // KVC修改系统弹框文字颜色字号
        if !(title ?? "").stringIsEmpty() {
            let alertStr = NSMutableAttributedString(string: title!)
            let alertStrAttr = [NSAttributedString.Key.foregroundColor: titleColor!, NSAttributedString.Key.font: titleFont!]
            alertStr.addAttributes(alertStrAttr, range: NSMakeRange(0, title!.count))
            alert.setValue(alertStr, forKey: "attributedTitle")
        }

        let subview = alert.view.subviews.first! as UIView
        let alertContentView = subview.subviews.first! as UIView
        if alertBGColor != .white {
            alertContentView.backgroundColor = alertBGColor
        }
        alertContentView.layer.cornerRadius = alertCornerRadius
        showIn!.present(alert, animated: true, completion: nil)
    }
    
    //MARK: 初始化創建Alert
    ///初始化創建Alert
    /// - Parameters:
    ///   - alertTitle: 標題
    ///   - feedBackTitlePlaceholder: 反馈底字
    ///   - feedBackTitleFont: 反馈字体
    ///   - feedBackContentPlaceholder: 反馈内容底字
    ///   - feedBackContentFont: 反馈内容字体
    ///   - feedBackContentCount: 最大输入字数
    ///   - feedBackContentIsSecureTextEntry: 是否密码格式输入
    ///   - cancelString: 取消
    ///   - sendString: 完成
    ///   - titleFont: 标题字体
    ///   - done: 完成回調(标题,内容)
    ///   - dismiss: 界面離開後的回調
    class func alertSendFeedBack(alertTitle:String? = "PT Screen feedback".localized(),
                                 feedBackTitlePlaceholder:String? = "PT Feedback input title".localized(),
                                 feedBackTitleFont:UIFont? = .appfont(size: 16),
                                 feedBackContentPlaceholder:String? = "PT Feedback input content".localized(),
                                 feedBackContentFont:UIFont? = .appfont(size: 16),
                                 feedBackContentCount:NSNumber? = 100,
                                 feedBackContentIsSecureTextEntry:Bool? = false,
                                 cancelString:String? = "PT Button cancel".localized(),
                                 sendString:String? = "PT Button comfirm".localized(),
                                 titleFont:UIFont? = .appfont(size: 18),
                                 textInset:UIEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0),
                                 done: @escaping (String, String) -> Void,
                                 dismiss:PTActionTask? = nil) {
        let feedBackTitleText:UITextField
        #if POOTOOLS_INPUT
        let feedBackTitle = PTTextField()
        feedBackTitle.placeholder = feedBackTitlePlaceholder!
        feedBackTitle.setPlaceHolderTextColor(.lightGray)
        feedBackTitle.clearButtonMode = .whileEditing
        feedBackTitle.font = feedBackTitleFont!
        feedBackTitle.addPaddingLeft(5)
        feedBackTitle.backgroundColor = .clear
        feedBackTitle.leftSpace = textInset.left
        
        feedBackTitleText = feedBackTitle
        #else
        feedBackTitleText = UITextField()
        feedBackTitleText.placeholder = feedBackTitlePlaceholder!
        feedBackTitleText.setPlaceHolderTextColor(.lightGray)
        feedBackTitleText.clearButtonMode = .whileEditing
        feedBackTitleText.font = feedBackTitleFont!
        feedBackTitleText.addPaddingLeft(5)
        feedBackTitleText.backgroundColor = .clear
        let lView = UIView(frame: CGRectMake(0, 0, textInset.left, 44))
        feedBackTitleText.leftView = lView
        #endif
        
        let feedBackContent = UITextView()
        feedBackContent.textContainerInset = textInset
        feedBackContent.pt_placeholder = feedBackContentPlaceholder!
        feedBackContent.pt_placeholderLabel?.textColor = .lightGray
        feedBackContent.pt_placeholderLabel?.font = feedBackContentFont!
        feedBackContent.font = feedBackContentFont!
        feedBackContent.backgroundColor = .clear
        feedBackContent.isSecureTextEntry = feedBackContentIsSecureTextEntry!
        feedBackContent.tintColor = .red
        
        let customerAlert = PTCustomerAlertController(title: alertTitle!,customerViewHeight:250,customerViewCallback: { customerView in
            customerView.addSubviews([feedBackTitleText,feedBackContent])
            feedBackTitleText.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview()
                make.height.equalTo(44)
            }
            
            feedBackContent.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview()
                make.top.equalTo(feedBackTitleText.snp.bottom)
            }
            
            feedBackContent.pt_wordCountLabel?.backgroundColor = .clear
            feedBackContent.pt_wordCountLabel?.font = .appfont(size: 12)
            feedBackContent.pt_maxWordCount = feedBackContentCount!
        },buttons: [cancelString!,sendString!], buttonsColors: [],contentSpace:60)
        customerAlert.bottomButtonTapCallback = { title,index in
            if index == 1 {
                done(feedBackTitleText.text ?? "",feedBackContent.text ?? "")
            } else {
                dismiss?()
            }
        }
        PTAlertManager.show(customerAlert)
    }
}
