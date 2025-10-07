//
//  UIButton+BlockEX.swift
//  Diou
//
//  Created by ken lam on 2021/10/9.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import Kingfisher
import AttributedString

public typealias TouchedBlock = (_ sender:UIButton) -> Void

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
    
    func layoutButtonWithEdgeInsets(style:PTLayoutButtonStyle,
                                    imageTitleSpace:CGFloat) {
        self.applyConfiguration(layout:style,imagePadding: imageTitleSpace)
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
                       width:CGFloat = CGFloat.greatestFiniteMagnitude) -> CGSize {
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
                            finishBlock: @Sendable @escaping (_ finish:Bool, _ time:Int) -> Void) {
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
    
    /// 高度封装的配置方法，支持图片尺寸、subtitle、全方向布局
    func applyConfiguration(image: UIImage? = nil,
                            highlightedImage: UIImage? = nil,
                            attributedTitle: ASAttributedString? = nil,
                            highlightedAttributedTitle: ASAttributedString? = nil,
                            attributedSubtitle: ASAttributedString? = nil,
                            layout: PTLayoutButtonStyle = .leftImageRightTitle,
                            imagePadding: CGFloat = 6,
                            contentInsets: UIEdgeInsets = .zero,
                            imageSize: CGSize? = nil,
                            imageContentMode: UIView.ContentMode = .scaleAspectFit,
                            titleAlignment: NSTextAlignment = .center,
                            baseForegroundColor: UIColor? = nil,
                            backgroundColor: UIColor? = nil,
                            cornerRadius: CGFloat = 0,
                            updateHandler: ((UIButton) -> Void)? = nil) {
        var config = UIButton.Configuration.plain()
        
        // MARK: - 基础属性
        config.image = image
        config.baseForegroundColor = baseForegroundColor
        config.background.backgroundColor = backgroundColor
        config.background.cornerRadius = cornerRadius
        
        // MARK: - 布局方向
        switch layout {
        case .leftImageRightTitle: config.imagePlacement = .leading
        case .leftTitleRightImage: config.imagePlacement = .trailing
        case .upImageDownTitle: config.imagePlacement = .top
        case .upTitleDownImage: config.imagePlacement = .bottom
        default:break
        }
        config.imagePadding = imagePadding
        
        // MARK: - 内边距
        config.contentInsets = NSDirectionalEdgeInsets(
            top: contentInsets.top,
            leading: contentInsets.left,
            bottom: contentInsets.bottom,
            trailing: contentInsets.right
        )
        
        // MARK: - 标题 & 副标题
        if let attributedTitle = attributedTitle {
            config.attributedTitle = AttributedString(attributedTitle.value)
        }
        if let attributedSubtitle = attributedSubtitle {
            config.attributedSubtitle = AttributedString(attributedSubtitle.value)
            config.titleAlignment = .center
        } else {
            config.titleAlignment = .center
        }
        
        // MARK: - 居中
        self.contentHorizontalAlignment = .center
        self.contentVerticalAlignment = .center
        
        // MARK: - 固定图片尺寸
        if let imageSize = imageSize {
            var imageConfig = UIImage.SymbolConfiguration(pointSize: imageSize.height)
            if image?.renderingMode != .alwaysTemplate {
                imageConfig = UIImage.SymbolConfiguration(scale: .default)
            }
            self.setPreferredSymbolConfiguration(imageConfig, forImageIn: .normal)
            self.configuration?.imagePadding = imagePadding
        }
        
        // 应用配置
        self.configuration = config
        
        // MARK: - 状态支持（高亮）
        self.setImage(highlightedImage, for: .highlighted)
        self.setAttributedTitle(highlightedAttributedTitle?.value, for: .highlighted)
        
        // 额外属性
        self.imageView?.contentMode = imageContentMode
        self.titleLabel?.textAlignment = titleAlignment
        
        // MARK: - 动态样式更新
        if let updateHandler = updateHandler {
            self.configurationUpdateHandler = { button in
                updateHandler(button)
            }
        }
        
        // 更新布局
        self.layoutIfNeeded()
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
