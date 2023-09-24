//
//  PTSendFeedBackAlert.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import UIKit
import SwifterSwift
import SnapKit

public class PTSendFeedBackAlert {
    public static let shared = PTSendFeedBackAlert()
    
    //MARK: 初始化創建Alert
    ///初始化創建Alert
    /// - Parameters:
    ///   - superView: 加載在?上
    ///   - alertTitle: 標題
    ///   - feedBackTitlePlaceholder: 反馈底字
    ///   - feedBackTitleFont: 反馈字体
    ///   - feedBackContentPlaceholder: 反馈内容底字
    ///   - feedBackContentFont: 反馈内容字体
    ///   - feedBackContentCount: 最大输入字数
    ///   - cancelString: 取消
    ///   - sendString: 完成
    ///   - canTapBackground: 是否支持點擊背景消失Alert
    ///   - titleFont: 标题字体
    ///   - done: 完成回調(标题,内容)
    ///   - dismiss: 界面離開後的回調
    public func alertSendFeedBack(superView:UIView,
                           alertTitle:String? = "反馈问题",
                           feedBackTitlePlaceholder:String? = "请输入反馈标题",
                           feedBackTitleFont:UIFont? = .appfont(size: 16),
                           feedBackContentPlaceholder:String? = "请输入反馈内容",
                           feedBackContentFont:UIFont? = .appfont(size: 16),
                           feedBackContentCount:NSNumber? = 100,
                           cancelString:String? = "取消",
                           sendString:String? = "确定",
                           titleFont:UIFont? = .appfont(size: 18),
                           canTapBackground:Bool? = false,
                           done:@escaping ((String,String) -> Void),
                           dismiss:PTActionTask? = nil) {
        let feedBackTitle = UITextField()
        feedBackTitle.placeholder = feedBackTitlePlaceholder!
        feedBackTitle.setPlaceHolderTextColor(.lightGray)
        feedBackTitle.clearButtonMode = .whileEditing
        feedBackTitle.font = feedBackTitleFont!
        feedBackTitle.addPaddingLeft(5)
        feedBackTitle.backgroundColor = .clear
        
        let feedBackContent = UITextView()
        feedBackContent.bk_placeholder = feedBackContentPlaceholder!
        feedBackContent.bk_placeholderLabel?.textColor = .lightGray
        feedBackContent.bk_placeholderLabel?.font = feedBackContentFont!
        feedBackContent.font = feedBackContentFont!
        feedBackContent.backgroundColor = .clear
        
        PTCustomAlertView.alertFunction(superView:superView,titleString: alertTitle!,titleFont: titleFont!,buttons: [cancelString!,sendString!], buttonColor: [],touchBackground: canTapBackground!,customAlertHeight: 250,alertLeftAndRightSpace: 60) { customerView in
            customerView.addSubviews([feedBackTitle,feedBackContent])
            feedBackTitle.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview()
                make.height.equalTo(44)
            }
            
            feedBackContent.bk_wordCountLabel?.backgroundColor = .clear
            feedBackContent.bk_wordCountLabel?.font = .appfont(size: 12)
            feedBackContent.pt_maxWordCount = feedBackContentCount!
            feedBackContent.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview()
                make.top.equalTo(feedBackTitle.snp.bottom)
            }
        } tapBlock: { index in
            if index == 1 {
                done(feedBackTitle.text ?? "",feedBackContent.text ?? "")
            }
        } alertDismissBlock: {
            if dismiss != nil {
                dismiss!()
            }
        }
    }
}
