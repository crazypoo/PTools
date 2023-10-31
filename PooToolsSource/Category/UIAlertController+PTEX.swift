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
                             cancel:String? = "取消",
                             cancelBlock:PTActionTask?) {
        UIAlertController.base_alertVC(title: title,msg: msg,cancelBtn:cancel,cancel: cancelBlock)
    }
    
    //MARK: ActionSheet基類
    ///ActionSheet基類
    /// - Parameters:
    ///   - title: 標題
    ///   - subTitle: 子標題
    ///   - cancelButtonName: 取消按鈕
    ///   - destructiveButtonName: 擴展按鈕
    ///   - titles: 其他標題
    ///   - destructiveBlock: 擴展回調
    ///   - cancelBlock: 取消回調
    ///   - otherBlock: 其他回調
    ///   - tapBackgroundBlock:
    ///   - tapBackgroundBlock:
    @objc class func baseActionSheet(title:String,
                                     subTitle:String? = "",
                                     cancelButtonName:String? = "取消",
                                     destructiveButtonName:String? = "",
                                     titles:[String],
                                     destructiveBlock: @escaping (_ sheet:PTActionSheetView)->Void,
                                     cancelBlock: @escaping (_ sheet:PTActionSheetView)->Void,
                                     otherBlock: @escaping (_ sheet:PTActionSheetView, _ index:Int)->Void,
                                     tapBackgroundBlock: @escaping (_ sheet:PTActionSheetView)->Void) {
        let actionSheet = PTActionSheetView(title: title,subTitle: subTitle,cancelButton: cancelButtonName,destructiveButton: destructiveButtonName!,otherButtonTitles: titles)
        actionSheet.actionSheetSelectBlock = { (sheet,index) in
            switch index {
            case PTActionSheetView.DestructiveButtonTag:
                destructiveBlock(sheet)
            case PTActionSheetView.CancelButtonTag:
                cancelBlock(sheet)
            default:
                otherBlock(sheet,index)
            }
        }
        actionSheet.show()
        actionSheet.actionSheetTapDismissBlock = { sheet in
            tapBackgroundBlock(sheet)
        }
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
    @objc class func base_alertVC(title:String? = "",
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
                            alertCornerRadius:NSNumber? = 15,
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
        alertContentView.layer.cornerRadius = CGFloat(alertCornerRadius!.floatValue)
        
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
                                      textFieldDelegate:UITextFieldDelegate,
                                      alertBGColor:UIColor? = .white,
                                      alertCornerRadius:CGFloat? = 15,
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
        alertContentView.layer.cornerRadius = alertCornerRadius!
        showIn!.present(alert, animated: true, completion: nil)
    }

    class func alert_Tips(tipsTitle:String? = "",
                          cancelTitle:String = "",
                          cancelBlock: PTActionTask? = nil,
                          doneTitle:String,
                          doneBlock: PTActionTask? = nil,
                          tipContentView:((_ contentView:UIView)->Void)?) {
        let tipsControl = PTUpdateTipsViewController(titleString: tipsTitle,cancelTitle: cancelTitle, doneTitle: doneTitle)
        tipsControl.modalPresentationStyle = .fullScreen
        if cancelBlock != nil {
            tipsControl.cancelTask = cancelBlock!
        }
        if doneBlock != nil {
            tipsControl.doneTask = doneBlock!
        }

        if tipContentView != nil {
            tipContentView!(tipsControl.contentView)
        }
        PTUtils.getCurrentVC().present(tipsControl, animated: true, completion: nil)
    }
    
    //MARK: 初始化UpdateTips
    ///初始化UpdateTips
    /// - Parameters:
    ///   - oV: 舊版本號
    ///   - nV: 新版本號
    ///   - descriptionString: 更新信息
    ///   - url: 下載URL
    ///   - test: 是否測試
    ///   - isShowError: 是否顯示錯誤
    ///   - isForcedUpgrade: 是否強制升級
    class func alert_updateTips(oldVersion oV: String,
                                newVersion nV: String,
                                description descriptionString: String,
                                downloadUrl url: URL,
                                isTest test:Bool = false,
                                showError isShowError:Bool = true,
                                forcedUpgrade isForcedUpgrade:Bool = false) {
        let cancelTitle:String = isForcedUpgrade ? "" : NSLocalizedString("取消升级", comment: "")
        UIAlertController.alert_Tips(tipsTitle: NSLocalizedString("发现新版本", comment: ""),cancelTitle: cancelTitle,cancelBlock: {
            if test {
                if isShowError {
                    UserDefaults.standard.set(1, forKey: uAppNoMoreShowUpdate)
                }
            }
        },doneTitle: NSLocalizedString("升级", comment: "")) {
            let realURL:URL = (url.scheme ?? "").stringIsEmpty() ? URL.init(string: "https://" + url.description)! : url
            UIApplication.shared.open(realURL, options: .init(), completionHandler: nil)
        } tipContentView: { contentView in
            
            let tipsContent = PTUpdateTipsContentView(oV: oV, nV: nV, descriptionString: descriptionString)
            contentView.addSubview(tipsContent)
            tipsContent.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
}
