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
        static var CountdownTimerKey = 997
    }
    
    private var countdownTimer: DispatchSourceTimer? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.CountdownTimerKey) as? DispatchSourceTimer
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.CountdownTimerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
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
        removeTarget(nil, action: nil, for: .allEvents)
    }
    
    @objc func pt_SDWebImage(imageString:String,
                             placeholder:UIImage = PTAppBaseConfig.share.defaultPlaceholderImage,
                             forState:UIControl.State = .normal,
                             loadedHandler:PTImageLoadHandler? = nil) {
        kf.setImage(with: URL(string: imageString), for: forState,placeholder: placeholder,options: PTAppBaseConfig.share.gobalWebImageLoadOption(),completionHandler: { result in
            switch result {
            case .success(let result):
                loadedHandler?(nil,result.originalSource.url,result.image)
            case .failure(let error):
                loadedHandler?(error,nil,nil)
            }
        })
    }
    
    func layoutButtonWithEdgeInsets(style:PTButtonEdgeInsetsStyle,
                                    imageTitleSpace:CGFloat) {
        /**
         * 知识点：titleEdgeInsets是title相对于其上下左右的inset，跟tableView的contentInset是类似的，
         * 如果只有title，那它上下左右都是相对于button的，image也是一样；
         * 如果同时有image和label，那这时候image的上左下是相对于button，右边是相对于label的；title的上右下是相对于button，左边是相对于image的。
         */
        guard let imageView = self.imageView, let titleLabel = self.titleLabel else { return }

        let imageSize = imageView.frame.size
        let titleSize = titleLabel.frame.size
        let halfSpace = imageTitleSpace / 2

        let imageW = imageSize.width
        let imageH = imageSize.height
        let titleW = titleSize.width
        let titleH = titleSize.height

        let imageInsets: UIEdgeInsets
        let titleInsets: UIEdgeInsets

        switch style {
        case .Top:
            imageInsets = UIEdgeInsets(top: -titleH - halfSpace, left: 0, bottom: 0, right: -titleW)
            titleInsets = UIEdgeInsets(top: 0, left: -imageW, bottom: -imageH - halfSpace, right: 0)

        case .Left:
            imageInsets = UIEdgeInsets(top: 0, left: -halfSpace, bottom: 0, right: halfSpace)
            titleInsets = UIEdgeInsets(top: 0, left: halfSpace, bottom: 0, right: -halfSpace)

        case .Bottom:
            imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: -titleH - halfSpace, right: -titleW)
            titleInsets = UIEdgeInsets(top: -imageH - halfSpace, left: -imageW, bottom: 0, right: 0)

        case .Right:
            imageInsets = UIEdgeInsets(top: 0, left: titleW + halfSpace, bottom: 0, right: -titleW - halfSpace)
            titleInsets = UIEdgeInsets(top: 0, left: -imageW - halfSpace, bottom: 0, right: imageW + halfSpace)
        }

        self.imageEdgeInsets = imageInsets
        self.titleEdgeInsets = titleInsets
    }
    
    //MARK: 計算文字的Size
    ///計算文字的Size
    /// - Parameters:
    ///   - lineSpacing: 行距
    ///   - height:
    ///   - width:
    ///   - height:
    /// - Returns: Size
    @objc func sizeFor(lineSpacing:CGFloat = 2.5,
                       height:CGFloat = CGFloat.greatestFiniteMagnitude,
                       width:CGFloat = CGFloat.greatestFiniteMagnitude)->CGSize {
        var dic = [NSAttributedString.Key.font: titleLabel!.font] as! [NSAttributedString.Key:Any]
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.lineSpacing = lineSpacing
        dic[NSAttributedString.Key.paragraphStyle] = paraStyle
        if let text = titleLabel?.text,!text.stringIsEmpty() {
            let size = text.boundingRect(with: CGSize(width: width, height: height), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: dic, context: nil).size
            return size
        }
        return .zero
    }

    //MARK: 按鈕倒計時基礎方法
    ///按鈕倒計時基礎方法
    /// - Parameters:
    ///   - timeInterval: 時間
    ///   - finishBlock:回調
    func buttonTimeRun_Base(timeInterval:TimeInterval,
                            finishBlock: @Sendable @escaping (_ finish:Bool, _ time:Int)->Void) {
        countdownTimer = PTGCDManager.timeRun(timeInterval: timeInterval, finishBlock: finishBlock)
    }
    
    /// 中斷倒數
    func cancelCountdown() {
        countdownTimer?.cancel()
        countdownTimer = nil
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
                       uni:String = "",
                       timeFinish:PTActionTask? = nil,
                       timingCallPack:PTActionTask? = nil) {
        buttonTimeRun_Base(timeInterval: timeInterval) { finish, time in
            if finish {
                self.setTitle(originalTitle, for: self.state)
                self.isUserInteractionEnabled = countdownFinishCanTap
                PTGCDManager.gcdMain {
                    timeFinish?()
                }
            } else {
                let strTime = String(format: "%.2d%@", time,uni)
                let buttonTime = String(format: "%@", strTime)
                self.setTitle(buttonTime, for: self.state)
                self.isUserInteractionEnabled = countdowningCanTap
                PTGCDManager.gcdMain {
                    timingCallPack?()
                }
            }
        }
    }
    
    func loadImage(contentData:Any,
                   iCloudDocumentName:String = "",
                   borderWidth:CGFloat = 1.5,
                   borderColor:UIColor = UIColor.purple,
                   showValueLabel:Bool = false,
                   valueLabelFont:UIFont = .appfont(size: 16,bold: true),
                   valueLabelColor:UIColor = .white,
                   uniCount:Int = 0,
                   emptyImage:UIImage = PTAppBaseConfig.share.defaultEmptyImage,
                   controlState:UIControl.State = .normal) {
        setImage(emptyImage, for: controlState)
        switch contentData {
        case let contentData as UIImage:
            setImage(contentData, for: controlState)
        case let contentData as String:
            Task {
                let result = await PTLoadImageFunction.handleStringContent(contentData, iCloudDocumentName) { receivedSize, totalSize in
                    PTGCDManager.gcdMain {
                        self.layerProgress(value: CGFloat((receivedSize / totalSize)),borderWidth: borderWidth,borderColor: borderColor,showValueLabel: showValueLabel,valueLabelFont:valueLabelFont,valueLabelColor:valueLabelColor,uniCount:uniCount)
                    }
                }
                if result.allImages?.count ?? 0 > 1 {
                    self.setImage(UIImage.animatedImage(with: result.allImages!, duration: result.loadTime), for: controlState)
                } else if result.allImages?.count ?? 0 == 1 {
                    self.setImage(result.firstImage, for: controlState)
                } else {
                    self.setImage(emptyImage, for: controlState)
                }
            }
        case let contentData as Data:
            let dataImage = UIImage(data: contentData)
            setImage(dataImage, for: controlState)
        case let color as UIColor:
            setImage(color.createImageWithColor(), for: controlState)
        default:
            setImage(emptyImage, for: controlState)
        }
    }
}

/// Custom button that pauses console window swizzling to allow the console menu's presenting view controller to remain the top view controller.
public class ConsoleMenuButton: UIButton {
}

extension ConsoleMenuButton {
    public override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willDisplayMenuFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        super.contextMenuInteraction(interaction, willDisplayMenuFor: configuration, animator: animator)
        SwizzleTool.pauseDidAddSubviewSwizzledClosure = true
    }
    
    public override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        SwizzleTool.pauseDidAddSubviewSwizzledClosure = false
    }
}
