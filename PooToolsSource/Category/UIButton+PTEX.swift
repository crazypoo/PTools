//
//  UIButton+BlockEX.swift
//  Diou
//
//  Created by ken lam on 2021/10/9.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import Kingfisher

public typealias TouchedBlock = (_ sender:UIButton) -> Void

public enum PTButtonEdgeInsetsStyle:Int {
    /// image在上，label在下
    case Top
    /// image在左，label在右
    case Left
    /// image在下，label在上
    case Bottom
    /// image在右，label在左
    case Right
}

public extension UIButton {
    private struct AssociatedKeys {
        static var UIButtonBlockKey = 998
    }
    
    @objc func addActionHandlers(handler:@escaping TouchedBlock) {
        objc_setAssociatedObject(self, &AssociatedKeys.UIButtonBlockKey, handler, .OBJC_ASSOCIATION_COPY)
        addTarget(self, action: #selector(actionTouched(sender:)), for: .touchUpInside)
    }
    
    @objc func actionTouched(sender:UIButton) {
        let block:TouchedBlock = objc_getAssociatedObject(self, &AssociatedKeys.UIButtonBlockKey) as! TouchedBlock
        block(sender)
    }
    
    @objc func removeTargerAndAction() {
        self.removeTarget(nil, action: nil, for: .allEvents)
    }
    
    @objc func pt_SDWebImage(imageString:String) {
        self.kf.setImage(with: URL.init(string: imageString), for: .normal,placeholder: PTAppBaseConfig.share.defaultPlaceholderImage,options: PTAppBaseConfig.share.gobalWebImageLoadOption())
    }
    
    func layoutButtonWithEdgeInsets(style:PTButtonEdgeInsetsStyle,
                                    imageTitleSpace:CGFloat) {
        /**
         * 知识点：titleEdgeInsets是title相对于其上下左右的inset，跟tableView的contentInset是类似的，
         * 如果只有title，那它上下左右都是相对于button的，image也是一样；
         * 如果同时有image和label，那这时候image的上左下是相对于button，右边是相对于label的；title的上右下是相对于button，左边是相对于image的。
         */

        let imageWith = imageView?.frame.size.width
        let imageHeight = imageView?.frame.size.height
        
        let labelWidth:CGFloat = (titleLabel?.frame.size.width)!
        let labelHeight:CGFloat = (titleLabel?.frame.size.height)!
        
        var imageEdgeInsets = UIEdgeInsets.zero
        var labelEdgeInsets = UIEdgeInsets.zero
        
        switch style {
        case .Top:
            imageEdgeInsets = UIEdgeInsets(top: -labelHeight-imageTitleSpace / 2, left: 0, bottom: 0, right: -labelWidth)
            labelEdgeInsets = UIEdgeInsets(top: 0, left: -imageWith!, bottom: -imageHeight!-imageTitleSpace/2, right: 0)
        case .Left:
            imageEdgeInsets = UIEdgeInsets(top: 0, left: -imageTitleSpace/2, bottom: 0, right: imageTitleSpace/2.0)
            labelEdgeInsets = UIEdgeInsets(top: 0, left: imageTitleSpace/2, bottom: 0, right: -imageTitleSpace/2.0)
        case .Bottom:
            imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: -labelHeight-imageTitleSpace/2, right: -labelWidth)
            labelEdgeInsets = UIEdgeInsets(top: -imageHeight!-imageTitleSpace/2, left: -imageWith!, bottom: 0, right: 0)
        case .Right:
            imageEdgeInsets = UIEdgeInsets(top: 0, left: labelWidth+imageTitleSpace/2, bottom: 0, right: -labelWidth-imageTitleSpace/2)
            labelEdgeInsets = UIEdgeInsets(top: 0, left: -imageWith!-imageTitleSpace/2, bottom: 0, right: imageWith!+imageTitleSpace/2)
        }
        
        titleEdgeInsets = labelEdgeInsets
        self.imageEdgeInsets = imageEdgeInsets
    }
    
    //MARK: 計算文字的Size
    ///計算文字的Size
    /// - Parameters:
    ///   - lineSpacing: 行距
    ///   - size: size
    /// - Returns: Size
    @objc func sizeFor(lineSpacing:NSNumber? = nil,
                       height:CGFloat = CGFloat.greatestFiniteMagnitude,
                       width:CGFloat = CGFloat.greatestFiniteMagnitude)->CGSize {
        var dic = [NSAttributedString.Key.font: titleLabel!.font] as! [NSAttributedString.Key:Any]
        if lineSpacing != nil {
            let paraStyle = NSMutableParagraphStyle()
            paraStyle.lineSpacing = CGFloat(lineSpacing!.floatValue)
            dic[NSAttributedString.Key.paragraphStyle] = paraStyle
        }
        let size = titleLabel!.text!.boundingRect(with: CGSize.init(width: width, height: height), options: [.usesLineFragmentOrigin], attributes: dic, context: nil).size
        return size
    }

    //MARK: 按鈕倒計時基礎方法
    ///按鈕倒計時基礎方法
    /// - Parameters:
    ///   - timeInterval: 時間
    ///   - finishBlock:回調
    func buttonTimeRun_Base(timeInterval:TimeInterval,
                            finishBlock: @escaping (_ finish:Bool, _ time:Int)->Void) {
        PTGCDManager.timeRunWithTime_base(timeInterval: timeInterval, finishBlock: finishBlock)
    }
    
    //MARK: 按鈕倒計時方法
    ///按鈕倒計時方法
    /// - Parameters:
    ///   - timeInterval: 時間
    ///   - originalTitle: 原始標題
    ///   - countdowningCanTap:
    ///   - countdownFinishCanTap:
    ///   - timeFinish:
    ///   - canTap: 倒計時後是否可以點擊
    ///   - finishBlock: 回調
    func buttonTimeRun(timeInterval:TimeInterval,
                       originalTitle:String,
                       countdowningCanTap:Bool = true,
                       countdownFinishCanTap:Bool = true,
                       timeFinish:PTActionTask?) {
        buttonTimeRun_Base(timeInterval: timeInterval) { finish, time in
            if finish {
                self.setTitle(originalTitle, for: self.state)
                self.isUserInteractionEnabled = countdownFinishCanTap
                if timeFinish != nil {
                    timeFinish!()
                }
            } else {
                let strTime = String.init(format: "%.2d", time)
                let buttonTime = String.init(format: "%@", strTime)
                self.setTitle(buttonTime, for: self.state)
                self.isUserInteractionEnabled = countdowningCanTap
            }
        }
    }
}
