//
//  PTChatTextCell.swift
//  LiXinCEO
//
//  Created by 邓杰豪 on 2024/3/31.
//

import UIKit
import AttributedString
import SnapKit

public class PTChatTextCell: PTChatBaseCell {
    public static let ID = "PTChatTextCell"
            
    public var cellModel:PTChatListModel! {
        didSet {
            PTGCDManager.gcdMain {
                self.setBaseSubsViews(cellModel: self.cellModel)
                self.dataContentSets(cellModel: self.cellModel)
            }
        }
    }
            
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func dataContentSets(cellModel:PTChatListModel) {
        
        userIcon.snp.remakeConstraints { make in
            make.size.equalTo(PTChatConfig.share.messageUserIconSize)
            if cellModel.belongToMe {
                make.right.equalToSuperview().inset(PTChatConfig.share.userIconFixelSpace)
            } else {
                make.left.equalToSuperview().inset(PTChatConfig.share.userIconFixelSpace)
            }
            make.top.equalTo(self.messageTimeLabel.snp.bottom).offset(PTChatBaseCell.TimeTopSpace)
        }
        
        senderNameLabel.snp.remakeConstraints { make in
            make.top.equalTo(self.userIcon)
            if cellModel.belongToMe {
                make.right.equalTo(self.userIcon.snp.left).offset(-PTChatBaseCell.DataContentUserIconFixel)
            } else {
                make.left.equalTo(self.userIcon.snp.right).offset(PTChatBaseCell.DataContentUserIconFixel)
            }
            
            make.height.equalTo(PTChatConfig.share.showSenderName ? PTChatBaseCell.NameHeight : 0)
        }
        
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
        var contentHeight = UIView.sizeFor(string: msgContent, font: dataContentFont,lineSpacing: PTChatConfig.share.textLineSpace,width: PTChatConfig.ChatContentShowMaxWidth).height
        if contentHeight < PTChatConfig.share.contentBaseHeight {
            contentHeight = PTChatConfig.share.contentBaseHeight
        }
        
        let contentWidth:CGFloat = UIView.sizeFor(string: msgContent, font: dataContentFont,lineSpacing: PTChatConfig.share.textLineSpace,height: PTChatConfig.share.contentBaseHeight).width + textEdges + 5
        
        dataContent.titleLabel?.numberOfLines = 0
        var titleColor:UIColor!
        if cellModel.belongToMe {
            titleColor = PTChatConfig.share.textMeMessageColor
            dataContent.setBackgroundImage(PTChatConfig.share.chatMeBubbleImage.resizeImage(), for: .normal)
            dataContent.setBackgroundImage(PTChatConfig.share.chatMeHighlightedBubbleImage.resizeImage(), for: .highlighted)
            dataContent.contentEdgeInsets = PTChatConfig.share.textOwnerContentEdges
        } else {
            titleColor = PTChatConfig.share.textOtherMessageColor
            dataContent.setBackgroundImage(PTChatConfig.share.chatOtherBubbleImage.resizeImage(), for: .normal)
            dataContent.setBackgroundImage(PTChatConfig.share.chatOtherHighlightedBubbleImage.resizeImage(), for: .highlighted)
            dataContent.contentEdgeInsets = PTChatConfig.share.textOtherContentEdges
        }
        
        let msgContentAtt:ASAttributedString = """
                \(wrap: .embedding("""
                \(msgContent,.foreground(titleColor),.font(dataContentFont),.paragraph(.alignment(.left),.lineSpacing(CGFloat(truncating: PTChatConfig.share.textLineSpace))))
                """))
                """
        dataContent.setAttributedTitle(msgContentAtt.value, for: .normal)
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
        
        waitImageView.snp.remakeConstraints { make in
            make.size.equalTo(PTChatBaseCell.WaitImageSize)
            if cellModel.belongToMe {
                make.right.equalTo(self.dataContent.snp.left).offset(-PTChatBaseCell.DataContentWaitImageFixel)
            } else {
                make.left.equalTo(self.dataContent.snp.right).offset(PTChatBaseCell.DataContentWaitImageFixel)
            }
            make.centerY.equalToSuperview()
        }
        waitImageView.addActionHandlers { sender in
            self.sendMesageError?(cellModel)
        }
        checkCellSendStatus(cellModel: cellModel)
    }
}
