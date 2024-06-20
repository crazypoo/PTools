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
    
//    fileprivate var activeLabel:PTActiveLabel = {
//        let view = PTActiveLabel()
//        view.urlMaximumLength = 20
//
//        return view
//    }()
            
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
        
//        dataContent.addSubviews([activeLabel])
//        activeLabel.snp.makeConstraints { make in
//            make.top.bottom.equalToSuperview()
//            make.left.equalToSuperview().inset(cellModel.belongToMe ? PTChatConfig.share.textOwnerContentEdges.left : PTChatConfig.share.textOtherContentEdges.left)
//            make.right.equalToSuperview().inset(cellModel.belongToMe ? PTChatConfig.share.textOwnerContentEdges.right : PTChatConfig.share.textOtherContentEdges.right)
//        }
//
//        activeLabel.customize { label in
//            label.textAlignment = .left
//            label.text = msgContent
//            label.numberOfLines = 0
//            label.lineSpacing = CGFloat(truncating: PTChatConfig.share.textLineSpace)
//            label.font = dataContentFont
//            label.textColor = titleColor
//            label.hashtagColor = UIColor(red: 85.0/255, green: 172.0/255, blue: 238.0/255, alpha: 1)
//            label.hashtagSelectedColor = UIColor(red: 85.0/255, green: 172.0/255, blue: 238.0/255, alpha: 1)
//            label.mentionColor = UIColor(red: 238.0/255, green: 85.0/255, blue: 96.0/255, alpha: 1)
//            label.mentionSelectedColor = UIColor(red: 238.0/255, green: 85.0/255, blue: 96.0/255, alpha: 1)
//            label.URLColor = UIColor(red: 85.0/255, green: 238.0/255, blue: 151.0/255, alpha: 1)
//            label.URLSelectedColor = UIColor(red: 82.0/255, green: 190.0/255, blue: 41.0/255, alpha: 1)
//            label.chinaCellPhoneColor = .random
//            label.chinaCellPhoneSelectedColor = .random
//
//            label.handleMentionTap { text in
////                self.alert(title:"Mention", message: text)
//                PTNSLogConsole("123")
//            }
//            label.handleHashtagTap { text in
////                self.alert(title:"Hashtag", message: text)
//                PTNSLogConsole("2222222")
//            }
//            label.handleURLTap { url in
////                self.alert(title:"URL", message: url.absoluteString)
//                PTNSLogConsole("aaaaaaaaaa")
//            }
//            label.handleChinaCellPhoneTap { phone in
//                PTNSLogConsole("11111111111")
////                self.alert(title:"CellPhone", message: phone)
//            }
//
//            //Custom types
//
////            label.customColor[customType] = UIColor.purple
////            label.customSelectedColor[customType] = UIColor.green
////            label.customColor[customType2] = UIColor.magenta
////            label.customSelectedColor[customType2] = UIColor.green
////
////            label.configureLinkAttribute = { (type, attributes, isSelected) in
////                var atts = attributes
////                switch type {
////                case PTActiveType.hashtag:
////                    atts[NSAttributedString.Key.font] = isSelected ? UIFont.boldSystemFont(ofSize: 16) : UIFont.boldSystemFont(ofSize: 16)
////                case customType3:
////                    atts[NSAttributedString.Key.font] = isSelected ? UIFont.boldSystemFont(ofSize: 16) : UIFont.boldSystemFont(ofSize: 14)
////                default: ()
////                }
////
////                return atts
////            }
//
////            label.handleCustomTap(for: customType) { text in
////                self.alert(title:"Custom type", message: text)
////            }
////            label.handleCustomTap(for: customType2) { text in
////                self.alert(title:"Custom type", message: text)
////            }
////            label.handleCustomTap(for: customType3) { text in
////                self.alert(title:"Custom type", message: text)
////            }
//        }
        
        resetSubsFrame(cellModel: cellModel)
    }
}
