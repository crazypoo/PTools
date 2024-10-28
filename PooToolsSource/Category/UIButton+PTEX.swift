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
        removeTarget(nil, action: nil, for: .allEvents)
    }
    
    @objc func pt_SDWebImage(imageString:String,
                             placeholder:UIImage = PTAppBaseConfig.share.defaultPlaceholderImage,
                             forState:UIControl.State = .normal,
                             loadedHandler:PTImageLoadHandler? = nil) {
        kf.setImage(with: URL.init(string: imageString), for: forState,placeholder: placeholder,options: PTAppBaseConfig.share.gobalWebImageLoadOption(),completionHandler: { result in
            switch result {
            case .success(let result):
                if loadedHandler != nil {
                    loadedHandler!(nil,result.originalSource.url,result.image)
                }
            case .failure(let error):
                if loadedHandler != nil {
                    loadedHandler!(error,nil,nil)
                }
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
        guard let imageView = self.imageView,
              let titleLabel = self.titleLabel else {
            return
        }
        
        let imageWidth = imageView.frame.size.width
        let imageHeight = imageView.frame.size.height
        let labelWidth = titleLabel.frame.size.width
        let labelHeight = titleLabel.frame.size.height
        
        var imageEdgeInsets = UIEdgeInsets.zero
        var labelEdgeInsets = UIEdgeInsets.zero
        
        switch style {
        case .Top:
            imageEdgeInsets = UIEdgeInsets(top: -labelHeight - imageTitleSpace / 2, left: 0, bottom: 0, right: -labelWidth)
            labelEdgeInsets = UIEdgeInsets(top: 0, left: -imageWidth, bottom: -imageHeight - imageTitleSpace / 2, right: 0)
            
        case .Left:
            imageEdgeInsets = UIEdgeInsets(top: 0, left: -imageTitleSpace / 2, bottom: 0, right: imageTitleSpace / 2)
            labelEdgeInsets = UIEdgeInsets(top: 0, left: imageTitleSpace / 2, bottom: 0, right: -imageTitleSpace / 2)
            
        case .Bottom:
            imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: -labelHeight - imageTitleSpace / 2, right: -labelWidth)
            labelEdgeInsets = UIEdgeInsets(top: -imageHeight - imageTitleSpace / 2, left: -imageWidth, bottom: 0, right: 0)
            
        case .Right:
            imageEdgeInsets = UIEdgeInsets(top: 0, left: labelWidth + imageTitleSpace / 2, bottom: 0, right: -labelWidth - imageTitleSpace / 2)
            labelEdgeInsets = UIEdgeInsets(top: 0, left: -imageWidth - imageTitleSpace / 2, bottom: 0, right: imageWidth + imageTitleSpace / 2)
        }
        
        self.titleEdgeInsets = labelEdgeInsets
        self.imageEdgeInsets = imageEdgeInsets
    }
    
    //MARK: 計算文字的Size
    ///計算文字的Size
    /// - Parameters:
    ///   - lineSpacing: 行距
    ///   - height:
    ///   - width:
    ///   - height:
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
        let size = titleLabel!.text!.boundingRect(with: CGSize.init(width: width, height: height), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: dic, context: nil).size
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
        if let image = contentData as? UIImage {
            setImage(image, for: controlState)
        } else if let dataUrlString = contentData as? String {
            Task {
                let result = await PTLoadImageFunction.handleStringContent(dataUrlString, iCloudDocumentName) { receivedSize, totalSize in
                    PTGCDManager.gcdMain {
                        self.layerProgress(value: CGFloat((receivedSize / totalSize)),borderWidth: borderWidth,borderColor: borderColor,showValueLabel: showValueLabel,valueLabelFont:valueLabelFont,valueLabelColor:valueLabelColor,uniCount:uniCount)
                    }
                }
                if result.0?.count ?? 0 > 1 {
                    self.setImage(UIImage.animatedImage(with: result.0!, duration: 2), for: controlState)
                } else if result.0?.count ?? 0 == 1 {
                    self.setImage(result.1, for: controlState)
                } else {
                    self.setImage(emptyImage, for: controlState)
                }
            }
        } else if let contentDatas = contentData as? Data {
            let dataImage = UIImage(data: contentDatas)
            setImage(dataImage, for: controlState)
        } else {
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
