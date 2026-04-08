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
import Photos
import ObjectiveC

public typealias TouchedBlock = (_ sender:UIButton) -> Void

public extension UIButton {
    
    // 优化：将 Int 替换为 UInt8 配合指针使用，防止内存异常
    private struct AssociatedKeys {
        static var UIButtonBlockKey: UInt8 = 0
        static var CountdownTimerKey: UInt8 = 0
    }
    
    // MARK: - Runtime
    private var countdownTimer: DispatchSourceTimer? {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.CountdownTimerKey) as? DispatchSourceTimer }
        set { objc_setAssociatedObject(self, &AssociatedKeys.CountdownTimerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    @objc func addActionHandlers(handler:@escaping TouchedBlock) {
        // 优化：使用 COPY_NONATOMIC 保证闭包内存安全
        objc_setAssociatedObject(self, &AssociatedKeys.UIButtonBlockKey, handler, .OBJC_ASSOCIATION_COPY)
        addTarget(self, action: #selector(actionTouched(sender:)), for: .touchUpInside)
    }
    
    @objc func actionTouched(sender:UIButton) {
        if let block:TouchedBlock = objc_getAssociatedObject(self, &AssociatedKeys.UIButtonBlockKey) as? TouchedBlock {
            block(sender)
        }
    }
    
    @objc func removeTargerAndAction() {
        removeTarget(nil, action: nil, for: .allEvents)
    }
    
    // 建议：底层其实使用的是 Kingfisher，建议后续更名为 pt_setWebImage
    @objc func pt_SDWebImage(imageString:String,
                             placeholder:UIImage = PTAppBaseConfig.share.defaultPlaceholderImage,
                             forState:UIControl.State = .normal,
                             loadedHandler:PTImageLoadHandler? = nil) {
        guard let url = URL(string: imageString) else {
            loadedHandler?(nil, nil, nil)
            return
        }
        kf.setImage(with: URL(string: imageString), for: forState,placeholder: placeholder,options: PTAppBaseConfig.share.gobalWebImageLoadOption(),completionHandler: { result in
            switch result {
            case .success(let result):
                loadedHandler?(nil,result.originalSource.url,result.image)
            case .failure(let error):
                loadedHandler?(error,nil,nil)
            }
        })
    }
    
    @available(iOS 15.0, *)
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
        // 优化：安全解包 font，避免 titleLabel 或 font 为 nil 时引发强制解包崩溃
        guard let titleLabel = titleLabel, let font = titleLabel.font else { return .zero }
        guard let text = titleLabel.text, !text.stringIsEmpty() else { return .zero }
        
        var dic: [NSAttributedString.Key: Any] = [.font: font]
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.lineSpacing = lineSpacing
        dic[.paragraphStyle] = paraStyle
        let size = text.boundingRect(with: CGSize(width: width, height: height),
                                     options: [.usesLineFragmentOrigin, .usesFontLeading],
                                     attributes: dic,
                                     context: nil).size
        return size
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
                       timingCallPack:((TimeInterval)->Void)? = nil) {
        buttonTimeRun_Base(timeInterval: timeInterval) { finish, time in
            if finish {
                self.setTitle(originalTitle, for: self.state)
                self.isUserInteractionEnabled = countdownFinishCanTap
                PTGCDManager.gcdMain {
                    timeFinish?()
                }
            } else {
                let buttonTime = String(format: "%02d%@", time, uni) // 优化：使用 %02d 替代 %.2d 更加规范
                self.setTitle(buttonTime, for: self.state)
                self.isUserInteractionEnabled = countdowningCanTap
                PTGCDManager.gcdMain {
                    timingCallPack?(TimeInterval(time))
                }
            }
        }
    }
    
    func loadImage(contentData:Any,
                   iCloudDocumentName:String = "",
                   borderWidth:CGFloat = PTAppBaseConfig.share.loadImageProgressBorderWidth,
                   borderColor:UIColor = PTAppBaseConfig.share.loadImageProgressBorderColor,
                   showValueLabel:Bool = PTAppBaseConfig.share.loadImageShowValueLabel,
                   valueLabelFont:UIFont = PTAppBaseConfig.share.loadImageShowValueFont,
                   valueLabelColor:UIColor = PTAppBaseConfig.share.loadImageShowValueColor,
                   uniCount:Int = PTAppBaseConfig.share.loadImageShowValueUniCount,
                   emptyImage:UIImage = PTAppBaseConfig.share.defaultEmptyImage,
                   controlState:UIControl.State = .normal,
                   progressHandle: ((_ receivedSize: Int64, _ totalSize: Int64) -> Void)? = nil,
                   loadFinish: ((PTLoadImageResult) -> Void)? = nil) {
        // 直接调用父类 UIView 封装好的核心逻辑
        pt_loadCoreImage(
            contentData: contentData,
            iCloudDocumentName: iCloudDocumentName,
            borderWidth: borderWidth,
            borderColor: borderColor,
            showValueLabel: showValueLabel,
            valueLabelFont: valueLabelFont,
            valueLabelColor: valueLabelColor,
            uniCount: uniCount,
            emptyImage: emptyImage,
            progressHandle: progressHandle,
            setImageBlock: { [weak self] image in
                self?.setImage(image, for: controlState) // UIButton 特有的渲染方式
            },
            loadFinish: loadFinish
        )
    }
        
    // 优化：UIButton.Configuration 是 iOS 15.0+ 引入的，必须打上 @available 标签防止低版本设备崩溃
    @available(iOS 15.0, *)
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
    
    @objc func getButtonSize(width:CGFloat = CGFloat.greatestFiniteMagnitude,
                             height:CGFloat = CGFloat.greatestFiniteMagnitude) -> CGSize {
        // 优化：安全解包处理
        guard let titleLabel = titleLabel, let font = titleLabel.font, let currentText = titleLabel.text, !currentText.stringIsEmpty() else { return .zero }
        return UIView.sizeFor(string: currentText, font: font, height: height, width: width)
    }
    
    @objc func getButtonWidth(height:CGFloat) -> CGFloat {
        getButtonSize(height: height).width
    }
    
    @objc func getButtonHeight(width:CGFloat) -> CGFloat {
        getButtonSize(width: width).height
    }
}

/// Custom button that pauses console window swizzling to allow the console menu's presenting view controller to remain the top view controller.
public class ConsoleMenuButton: UIButton { }

extension ConsoleMenuButton {
    public override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willDisplayMenuFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        super.contextMenuInteraction(interaction, willDisplayMenuFor: configuration, animator: animator)
        SwizzleTool.pauseDidAddSubviewSwizzledClosure = true
    }
    
    public override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        SwizzleTool.pauseDidAddSubviewSwizzledClosure = false
    }
}
