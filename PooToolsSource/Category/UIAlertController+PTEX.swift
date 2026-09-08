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
    @objc class func alertVC(title:String = "",
                             msg:String = "",
                             cancel:String? = nil,
                             cancelBlock:PTActionTask?) {
        let cancelString = cancel ?? "PT Button cancel".localized()
        UIAlertController.base_alertVC(title: title,msg: msg,cancelBtn:cancelString,cancel: cancelBlock)
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
                                     subTitle:String = "",
                                     cancelButtonName:String? = nil,
                                     destructiveButtons:[String] = [String](),
                                     titles:[String],
                                     canTapBackground:Bool = true,
                                     destructiveBlock:PTActionSheetIndexCallback? = nil,
                                     cancelBlock: PTActionSheetCallback? = nil,
                                     otherBlock: @escaping PTActionSheetIndexCallback,
                                     tapBackgroundBlock: PTActionSheetCallback? = nil) {
        let cancelString = cancelButtonName ?? "PT Button cancel".localized()

        let titleItem: PTActionSheetTitleItem? = title.stringIsEmpty() && subTitle.stringIsEmpty()
            ? nil
            : PTActionSheetTitleItem(title: title, subTitle: subTitle)
        let cancelItem = PTActionSheetItem(title: cancelString)

        let destructiveItems = destructiveButtons.map { value in
            let item = PTActionSheetItem(title: value)
            item.titleColor = .systemRed
            return item
        }
        
        let contentItems = titles.map { value in
            let item = PTActionSheetItem(title: value)
            return item
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
                                           cancelItem:PTActionSheetItem? = nil,
                                           destructiveItems:[PTActionSheetItem] = [PTActionSheetItem](),
                                           contentItems:[PTActionSheetItem],
                                           destructiveBlock:PTActionSheetIndexCallback? = nil,
                                           cancelBlock: PTActionSheetCallback? = nil,
                                           otherBlock: @escaping PTActionSheetIndexCallback,
                                           canTapBackground:Bool = false,
                                           tapBackgroundBlock: PTActionSheetCallback? = nil) {
        let cancelItems = cancelItem ?? PTActionSheetItem(title: "PT Button cancel".localized())
                            
        let actionSheet = PTActionSheetController(viewConfig:viewConfig,titleItem:titleItem,cancelItem:cancelItems,destructiveItems: destructiveItems,contentItems: contentItems,canTapBackground: canTapBackground)
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
    class func base_alertVC(title:String = "",
                            titleColor:UIColor? = nil,
                            titleFont:UIFont = UIFont.systemFont(ofSize: 15),
                            msg:String = "",
                            msgColor:UIColor? = nil,
                            msgFont:UIFont = UIFont.systemFont(ofSize: 15),
                            okBtns:[String] = [String](),
                            buttonsFont:UIFont = .appfont(size: 15),
                            cancelBtn:String = "",
                            showIn:UIViewController? = nil,
                            cancelBtnColor:UIColor = .systemBlue,
                            doneBtnColors:[UIColor] = [UIColor](),
                            alertBGColor:UIColor = .white,
    @PTClampedPropertyWrapper(range:0...15) alertCornerRadius:CGFloat = 15,
                            cancel:PTActionTask? = nil,
                            moreBtn: ((_ index:Int,_ title:String)->Void)? = nil) {
        let titleColorN = titleColor ?? .label
        let msgColorN = msgColor ?? .secondaryLabel
        let hasCancel = !cancelBtn.stringIsEmpty()
        // English: Keep the cancel action last, matching the native alert hierarchy.
        // Español: Mantén la acción de cancelar al final, como en la jerarquía nativa de las alertas.
        // 中文：取消操作放在最后，符合系统 Alert 的按钮层级和视觉顺序。
        let actionTitles = okBtns + (hasCancel ? [cancelBtn] : [])
        let actionColors = okBtns.indices.map { index in
            index < doneBtnColors.count ? doneBtnColors[index] : .systemBlue
        } + (hasCancel ? [cancelBtnColor] : [])
        let titles = actionTitles.isEmpty ? ["PT Button cancel".localized()] : actionTitles
        let colors = actionColors.isEmpty ? [.systemBlue] : actionColors
        
        let contentSpacing:CGFloat = 25

        // English: Measure the message with the same capped width used by the customer alert surface.
        // Español: Mide el mensaje con el mismo ancho máximo que usa la superficie de la alerta personalizada.
        // 中文：正文测量使用与自定义弹窗表面相同的宽度上限。
        let contentWidth = resolvedCustomerAlertContentWidth(for: showIn, contentSpace: contentSpacing)
        
        let messageHeight = msg.isEmpty ? 0 : max(44, msg.boundingSize(font: msgFont,width: contentWidth).height + 20)

        let alert = PTCustomerAlertController(
            title: title,
            titleFont: titleFont,
            titleColor: titleColorN,
            customerViewHeight: messageHeight,
            customerViewCallback: { customerView in
                guard messageHeight > 0 else { return }
                let messageLabel = UILabel()
                messageLabel.text = msg
                messageLabel.textColor = msgColorN
                messageLabel.font = msgFont
                messageLabel.numberOfLines = 0
                messageLabel.textAlignment = .center
                messageLabel.adjustsFontForContentSizeCategory = true
                customerView.addSubview(messageLabel)
                messageLabel.snp.makeConstraints { make in
                    make.edges.equalToSuperview().inset(10)
                }
            },
            buttons: titles,
            buttonsColors: colors,
            buttonsFont: buttonsFont,
            cornerSize: alertCornerRadius,
            contentSpace: contentSpacing,
            canTapBackground: false
        )
        alert.contentBackgroundColor = alertBGColor == .white ? nil : alertBGColor
        alert.bottomButtonTapCallback = { _, index in
            if hasCancel && index == titles.count - 1 {
                cancel?()
                return
            }
            guard !okBtns.isEmpty else {
                cancel?()
                return
            }
            guard okBtns.indices.contains(index) else { return }
            moreBtn?(index, okBtns[index])
        }
        presentCustomerAlert(alert, from: showIn)
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
    class func base_textfield_alertVC(title:String = "",
                                      titleColor:UIColor? = nil,
                                      titleFont:UIFont = UIFont.systemFont(ofSize: 15),
                                      okBtn:String,
                                      buttonsFont:UIFont = .appfont(size: 15),
                                      cancelBtn:String,
                                      showIn:UIViewController? = nil,
                                      cancelBtnColor:UIColor? = nil,
                                      doneBtnColor:UIColor = .systemBlue,
                                      placeHolders:[String],
                                      textFieldTexts:[String],
                                      textTintColor:UIColor = .systemBlue,
                                      keyboardType:[UIKeyboardType]?,
                                      textFieldDelegate:UITextFieldDelegate,
                                      alertBGColor:UIColor = .white,
    @PTClampedPropertyWrapper(range:0...15) alertCornerRadius:CGFloat = 15,
                                      cancel:PTActionTask? = nil,
                                      doneBtn:((_ result:[String:String]) -> Void)?) {
        let titleColorN = titleColor ?? .label
        let cancelBtnColorN = cancelBtnColor ?? .label
        let fields = placeHolders.enumerated().map { index, placeholder in
            let textField = UITextField()
            textField.placeholder = placeholder
            textField.delegate = textFieldDelegate
            textField.tag = index
            textField.text = textFieldTexts.indices.contains(index) ? textFieldTexts[index] : ""
            textField.tintColor = textTintColor
            textField.keyboardType = keyboardType?.indices.contains(index) == true
                ? keyboardType?[index] ?? .default
                : .default
            textField.clearButtonMode = .whileEditing
            textField.borderStyle = .roundedRect
            return textField
        }
        let fieldHeight = fields.isEmpty ? 0 : CGFloat(fields.count) * 50 + 10
        let alert = PTCustomerAlertController(
            title: title,
            titleFont: titleFont,
            titleColor: titleColorN,
            customerViewHeight: fieldHeight,
            customerViewCallback: { customerView in
                guard !fields.isEmpty else { return }
                let stackView = UIStackView(arrangedSubviews: fields)
                stackView.axis = .vertical
                stackView.spacing = 6
                customerView.addSubview(stackView)
                stackView.snp.makeConstraints { make in
                    make.edges.equalToSuperview().inset(10)
                }
                fields.forEach { field in
                    field.snp.makeConstraints { make in
                        make.height.equalTo(44)
                    }
                }
            },
            // English: Keep cancel as the trailing action so vertical layouts place it at the bottom.
            // Español: Mantén cancelar como la acción final para que los diseños verticales lo sitúen abajo.
            // 中文：取消按钮作为最后一个操作，使纵向布局时自然位于底部。
            buttons: [okBtn, cancelBtn],
            buttonsColors: [doneBtnColor, cancelBtnColorN],
            buttonsFont: buttonsFont,
            cornerSize: alertCornerRadius,
            contentSpace: 25,
            canTapBackground: false
        )
        alert.contentBackgroundColor = alertBGColor == .white ? nil : alertBGColor
        alert.bottomButtonTapCallback = { _, index in
            if index == 1 {
                cancel?()
                return
            }
            guard index == 0 else { return }
            var result = [String: String]()
            fields.forEach { field in
                let key = field.placeholder ?? "field_\(field.tag)"
                result[key] = field.text ?? ""
            }
            doneBtn?(result)
        }
        presentCustomerAlert(alert, from: showIn)
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
    class func alertSendFeedBack(alertTitle:String? = nil,
                                 feedBackTitlePlaceholder:String? = nil,
                                 feedBackTitleFont:UIFont = .appfont(size: 16),
                                 feedBackTitleHeight:CGFloat = 44,
                                 feedBackContentPlaceholder:String? = nil,
                                 feedBackContentFont:UIFont = .appfont(size: 16),
                                 feedBackContentCount:NSNumber = 100,
                                 feedBackWordCountFont:UIFont = .appfont(size: 12),
                                 feedBackContentIsSecureTextEntry:Bool = false,
                                 cancelString:String? = nil,
                                 sendString:String? = nil,
                                 buttonsFont:UIFont = .appfont(size: 15),
                                 titleFont:UIFont = .appfont(size: 18),
                                 textInset:UIEdgeInsets? = .zero,
                                 titleTintColor:UIColor = .systemBlue,
                                 textTintColor:UIColor = .systemBlue,
                                 alertBGColor:UIColor = .white,
                                 done: @escaping (String, String) -> Void,
                                 dismiss:PTActionTask? = nil) {
        let titleItem = alertTitle ?? "PT Screen feedback".localized()
        let cancelItem = cancelString ?? "PT Button cancel".localized()
        let sendItem = sendString ?? "PT Button comfirm".localized()
        let feedBackTitlePlaceholderItem = feedBackTitlePlaceholder ?? "PT Feedback input title".localized()
        let feedBackContentPlaceholderItem = feedBackContentPlaceholder ?? "PT Feedback input content".localized()

        let feedBackTitleText:UITextField
        let leftSpacing = textInset?.left ?? 10
        #if POOTOOLS_INPUT
        let feedBackTitle = PTTextField()
        feedBackTitle.placeholder = feedBackTitlePlaceholderItem
        feedBackTitle.setPlaceHolderTextColor(.lightGray)
        feedBackTitle.clearButtonMode = .whileEditing
        feedBackTitle.font = feedBackTitleFont
        feedBackTitle.backgroundColor = .clear
        feedBackTitle.leftSpace = leftSpacing
        feedBackTitleText = feedBackTitle
        feedBackTitleText.tintColor = titleTintColor
        #else
        feedBackTitleText = UITextField()
        feedBackTitleText.placeholder = feedBackTitlePlaceholderItem
        feedBackTitleText.setPlaceHolderTextColor(.lightGray)
        feedBackTitleText.clearButtonMode = .whileEditing
        feedBackTitleText.font = feedBackTitleFont
        feedBackTitleText.backgroundColor = .clear
        feedBackTitleText.addPaddingLeft(leftSpacing + 5)
        feedBackTitleText.tintColor = titleTintColor
        #endif
        
        let feedBackContent = UITextView()
        if let textInsets = textInset {
            feedBackContent.textContainerInset = textInsets
        }
        feedBackContent.pt_placeholder = feedBackContentPlaceholderItem
        feedBackContent.pt_placeholderLabel?.textColor = .lightGray
        feedBackContent.pt_placeholderLabel?.font = feedBackContentFont
        feedBackContent.font = feedBackContentFont
        feedBackContent.backgroundColor = .clear
        feedBackContent.isSecureTextEntry = feedBackContentIsSecureTextEntry
        feedBackContent.tintColor = textTintColor
        
        let customerAlert = PTCustomerAlertController(title: titleItem,
                                                      customerViewHeight:250,
                                                      customerViewCallback: { customerView in
            customerView.addSubviews([feedBackTitleText,feedBackContent])
            feedBackTitleText.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview()
                make.height.equalTo(feedBackTitleHeight)
            }
            
            feedBackContent.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview()
                make.top.equalTo(feedBackTitleText.snp.bottom)
            }
            
            feedBackContent.pt_wordCountLabel?.backgroundColor = .clear
            feedBackContent.pt_wordCountLabel?.font = feedBackWordCountFont
            feedBackContent.pt_maxWordCount = feedBackContentCount
        },
                                                      // English: Submit first and cancel last for native action ordering.
                                                      // Español: Coloca enviar primero y cancelar al final para respetar el orden nativo.
                                                      // 中文：发送按钮放在前面，取消按钮放在最后，符合系统操作顺序。
                                                      buttons: [sendItem,cancelItem],
                                                      buttonsColors: [],
                                                      buttonsFont: buttonsFont,
                                                      contentSpace:60)
        customerAlert.bottomButtonTapCallback = { _, index in
            if index == 0 {
                done(feedBackTitleText.text ?? "",feedBackContent.text ?? "")
            } else if index == 1 {
                dismiss?()
            }
        }
        customerAlert.contentBackgroundColor = alertBGColor == .white ? nil : alertBGColor
        presentCustomerAlert(customerAlert, from: nil)
    }
}

// English: Keep legacy alert wrappers on the same sizing and scene-presentation path.
// Español: Mantén los wrappers heredados de alerta en la misma ruta de tamaño y presentación por escena.
// 中文：让旧版 Alert 包装器统一使用同一套尺寸计算和场景展示路径。
private extension UIAlertController {
    static func resolvedCustomerAlertContentWidth(for presenter: UIViewController?, contentSpace: CGFloat) -> CGFloat {
        let availableWidths = [
            presenter?.viewIfLoaded?.bounds.width,
            presenter?.viewIfLoaded?.window?.bounds.width,
            PTSceneContext.activeWindow()?.bounds.width,
            CGFloat.kSCREEN_WIDTH
        ].compactMap { $0 }.filter { $0.isFinite && $0 > 0 }
        return PTCustomerAlertController.resolvedContentWidth(
            containerWidth: availableWidths.first ?? CGFloat.kSCREEN_WIDTH,
            contentSpace: contentSpace
        )
    }

    static func presentCustomerAlert(_ alert: PTCustomerAlertController, from presenter: UIViewController?) {
        alert.preferredWindowScene = presenter?.viewIfLoaded?.window?.windowScene
        PTAlertManager.show(alert)
    }
}
