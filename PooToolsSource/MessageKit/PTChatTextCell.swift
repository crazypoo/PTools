//
//  PTChatTextCell.swift
//  LiXinCEO
//
//  Created by 邓杰豪 on 2024/3/31.
//

import UIKit
import AttributedString
import SnapKit

public typealias PTAttLabelCallBack = (String) -> Void

public class PTChatTextCell: PTChatBaseCell {
    public static let ID = "PTChatTextCell"
    
    public var hashtagCallback:PTAttLabelCallBack?
    public var mentionCallback:PTAttLabelCallBack?
    public var chinaPhoneCallback:PTAttLabelCallBack?
    public var urlCallback:PTAttLabelCallBack?
    public var customCallback:PTAttLabelCallBack?

    public var cellModel:PTChatListModel! {
        didSet {
            PTGCDManager.gcdMain {
                self.setBaseSubsViews(cellModel: self.cellModel)
                self.dataContentSets(cellModel: self.cellModel)
            }
        }
    }
    
    fileprivate var activeLabel:PTActiveLabel = {
        let view = PTActiveLabel()
        view.urlMaximumLength = 20
        return view
    }()
            
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func dataContentSets(cellModel:PTChatListModel) {
                
        let msgContent = cellModel.msgContent as! String
        
        var dataContentFont:UIFont!
        
        var textEdges:CGFloat = 0
        if cellModel.belongToMe {
            dataContentFont = PTChatConfig.share.textMeMessageFont
            textEdges = PTChatConfig.share.textOwnerContentEdges.left + PTChatConfig.share.textOwnerContentEdges.right
        } else {
            dataContentFont = PTChatConfig.share.textOtherMessageFont
            textEdges = PTChatConfig.share.textOtherContentEdges.left + PTChatConfig.share.textOtherContentEdges.right
        }
        
        let contentNumberOfLines = msgContent.numberOfLines(font: dataContentFont, labelShowWidth: PTChatConfig.ChatContentShowMaxWidth,lineSpacing: PTChatConfig.share.textLineSpace)
        var contentHeight = UIView.sizeFor(string: msgContent, font: dataContentFont,lineSpacing: PTChatConfig.share.textLineSpace,width: PTChatConfig.ChatContentShowMaxWidth).height + 40
        if contentNumberOfLines <= 1 {
            contentHeight = PTChatConfig.share.contentBaseHeight
        }
        
        let contentWidth:CGFloat = UIView.sizeFor(string: msgContent, font: dataContentFont,lineSpacing: PTChatConfig.share.textLineSpace,height: PTChatConfig.share.contentBaseHeight).width + textEdges + 5
        
        var titleColor:UIColor!
        if cellModel.belongToMe {
            titleColor = PTChatConfig.share.textMeMessageColor
            dataContentStatusView.setBackgroundImage(PTChatConfig.share.chatMeBubbleImage.resizeImage(), for: .normal)
            dataContentStatusView.setBackgroundImage(PTChatConfig.share.chatMeHighlightedBubbleImage.resizeImage(), for: .highlighted)
            dataContentStatusView.contentEdgeInsets = PTChatConfig.share.textOwnerContentEdges
        } else {
            titleColor = PTChatConfig.share.textOtherMessageColor
            dataContentStatusView.setBackgroundImage(PTChatConfig.share.chatOtherBubbleImage.resizeImage(), for: .normal)
            dataContentStatusView.setBackgroundImage(PTChatConfig.share.chatOtherHighlightedBubbleImage.resizeImage(), for: .highlighted)
            dataContentStatusView.contentEdgeInsets = PTChatConfig.share.textOtherContentEdges
        }
        
        dataContent.snp.remakeConstraints { make in
            if cellModel.belongToMe {
                make.right.equalTo(self.userIcon.snp.left).offset(-PTChatBaseCell.DataContentUserIconFixel)
            } else {
                make.left.equalTo(self.userIcon.snp.right).offset(PTChatBaseCell.DataContentUserIconFixel)
            }
            make.top.equalTo(self.senderNameLabel.snp.bottom)
            make.height.equalTo(contentHeight)
            if contentNumberOfLines <= 1 && contentWidth <= PTChatConfig.ChatContentShowMaxWidth {
                make.width.equalTo(contentWidth)
            } else {
                make.width.equalTo(PTChatConfig.ChatContentShowMaxWidth)
            }
        }
        
        dataContent.addSubviews([activeLabel])
        activeLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().inset(cellModel.belongToMe ? PTChatConfig.share.textOwnerContentEdges.left : PTChatConfig.share.textOtherContentEdges.left)
            make.right.equalToSuperview().inset(cellModel.belongToMe ? PTChatConfig.share.textOwnerContentEdges.right : PTChatConfig.share.textOtherContentEdges.right)
        }

        var customAttTypes = [PTActiveType]()
        if PTChatConfig.share.customerTagModels.count > 0 {
            PTChatConfig.share.customerTagModels.enumerated().forEach { index,value in
                let type = PTActiveType.custom(pattern: value.tag)
                customAttTypes.append(type)
                activeLabel.enabledTypes.append(type)
            }
        }
               
        activeLabel.customize { label in
            label.textAlignment = .left
            label.text = msgContent
            label.numberOfLines = 0
            label.lineSpacing = CGFloat(truncating: PTChatConfig.share.textLineSpace)
            label.font = dataContentFont
            label.textColor = titleColor
            label.hashtagColor = PTChatConfig.share.hashtagColor
            label.hashtagSelectedColor = PTChatConfig.share.hashtagSelectedColor
            label.mentionColor = PTChatConfig.share.mentionColor
            label.mentionSelectedColor = PTChatConfig.share.mentionSelectedColor
            label.URLColor = PTChatConfig.share.urlColor
            label.URLSelectedColor = PTChatConfig.share.urlSelectedColor
            label.chinaCellPhoneColor = PTChatConfig.share.chinaCellPhoneColor
            label.chinaCellPhoneSelectedColor = PTChatConfig.share.chinaCellPhoneSelectedColor

            label.handleMentionTap { text in
                self.mentionCallback?(text)
            }
            label.handleHashtagTap { text in
                self.hashtagCallback?(text)
            }
            label.handleURLTap { url in
                self.urlCallback?(url.absoluteString)
            }
            label.handleChinaCellPhoneTap { phone in
                self.chinaPhoneCallback?(phone)
            }
            
            if customAttTypes.count > 0 {
                customAttTypes.enumerated().forEach { index,value in
                    label.customColor[value] = PTChatConfig.share.customerTagModels[index].tagColor
                    label.customSelectedColor[value] = PTChatConfig.share.customerTagModels[index].tagSelectedColor
                    label.handleCustomTap(for: value) { text in
                        self.customCallback?(text)
                    }
                }
            }
        }
        
        resetSubsFrame(cellModel: cellModel)
    }
}
