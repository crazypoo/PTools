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
    
    public var hashtagCallback: PTAttLabelCallBack?
    public var mentionCallback: PTAttLabelCallBack?
    public var chinaPhoneCallback: PTAttLabelCallBack?
    public var urlCallback: PTAttLabelCallBack?
    public var customCallback: PTAttLabelCallBack?

    public var cellModel: PTChatListModel! {
        didSet {
            PTGCDManager.gcdMain {
                self.setBaseSubviews(cellModel: self.cellModel)
                self.dataContentSets(cellModel: self.cellModel)
            }
        }
    }
    
    fileprivate var activeLabel: PTActiveLabel = {
        let view = PTActiveLabel()
        view.urlMaximumLength = 20
        return view
    }()
            
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        dataContent.addSubview(activeLabel)
    }
    
    private func setupConstraints(for cellModel: PTChatListModel, contentHeight: CGFloat, contentWidth: CGFloat, contentNumberOfLines: Int) {
        dataContent.snp.remakeConstraints { make in
            make.top.equalTo(senderNameLabel.snp.bottom)
            make.height.equalTo(contentHeight)
            if cellModel.belongToMe {
                make.right.equalTo(userIcon.snp.left).offset(-PTChatBaseCell.dataContentUserIconInset)
            } else {
                make.left.equalTo(userIcon.snp.right).offset(PTChatBaseCell.dataContentUserIconInset)
            }
            if contentNumberOfLines <= 1 && contentWidth <= PTChatConfig.ChatContentShowMaxWidth {
                make.width.equalTo(contentWidth)
            } else {
                make.width.equalTo(PTChatConfig.ChatContentShowMaxWidth)
            }
        }

        activeLabel.snp.makeConstraints { make in
            make.edges.equalTo(dataContent).inset(UIEdgeInsets(
                top: 0,
                left: cellModel.belongToMe ? PTChatConfig.share.textOwnerContentEdges.left : PTChatConfig.share.textOtherContentEdges.left,
                bottom: 0,
                right: cellModel.belongToMe ? PTChatConfig.share.textOwnerContentEdges.right : PTChatConfig.share.textOtherContentEdges.right
            ))
        }
    }

    private func configureActiveLabel(_ label: PTActiveLabel, with cellModel: PTChatListModel, msgContent: String, font: UIFont, titleColor: UIColor) {
        label.customize { label in
            label.textAlignment = .left
            label.text = msgContent
            label.numberOfLines = 0
            label.lineSpacing = PTChatConfig.share.textLineSpace
            label.font = font
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
        }
    }

    private func handleCustomTags(for label: PTActiveLabel, with cellModel: PTChatListModel) {
        var customAttTypes = [PTActiveType]()
        if !PTChatConfig.share.customerTagModels.isEmpty {
            PTChatConfig.share.customerTagModels.forEach { tagModel in
                let type = PTActiveType.custom(pattern: tagModel.tag)
                customAttTypes.append(type)
                label.enabledTypes.append(type)
                label.customColor[type] = tagModel.tagColor
                label.customSelectedColor[type] = tagModel.tagSelectedColor
            }
        }
        
        if !customAttTypes.isEmpty {
            customAttTypes.forEach { type in
                label.handleCustomTap(for: type) { text in
                    self.customCallback?(text)
                }
            }
        }
    }

    func dataContentSets(cellModel: PTChatListModel) {
        guard let msgContent = cellModel.msgContent as? String else { return }
        
        let isOwner = cellModel.belongToMe
        let dataContentFont = isOwner ? PTChatConfig.share.textMeMessageFont : PTChatConfig.share.textOtherMessageFont
        let textEdges = isOwner ? PTChatConfig.share.textOwnerContentEdges.left + PTChatConfig.share.textOwnerContentEdges.right : PTChatConfig.share.textOtherContentEdges.left + PTChatConfig.share.textOtherContentEdges.right
        
        let contentNumberOfLines = msgContent.numberOfLines(font: dataContentFont, labelShowWidth: PTChatConfig.ChatContentShowMaxWidth, lineSpacing: PTChatConfig.share.textLineSpace)
        var contentHeight = UIView.sizeFor(string: msgContent, font: dataContentFont, lineSpacing: PTChatConfig.share.textLineSpace, width: PTChatConfig.ChatContentShowMaxWidth).height + 40
        if contentNumberOfLines <= 1 {
            contentHeight = PTChatConfig.share.contentBaseHeight
        }
        
        let contentWidth = UIView.sizeFor(string: msgContent, font: dataContentFont, lineSpacing: PTChatConfig.share.textLineSpace, height: PTChatConfig.share.contentBaseHeight).width + textEdges + 5
        
        let titleColor = isOwner ? PTChatConfig.share.textMeMessageColor : PTChatConfig.share.textOtherMessageColor
        dataContentStatusView.setBackgroundImage(isOwner ? PTChatConfig.share.chatMeBubbleImage.resizeImage() : PTChatConfig.share.chatOtherBubbleImage.resizeImage(), for: .normal)
        dataContentStatusView.setBackgroundImage(isOwner ? PTChatConfig.share.chatMeHighlightedBubbleImage.resizeImage() : PTChatConfig.share.chatOtherHighlightedBubbleImage.resizeImage(), for: .highlighted)
        dataContentStatusView.contentEdgeInsets = isOwner ? PTChatConfig.share.textOwnerContentEdges : PTChatConfig.share.textOtherContentEdges

        setupConstraints(for: cellModel, contentHeight: contentHeight, contentWidth: contentWidth, contentNumberOfLines: contentNumberOfLines)

        configureActiveLabel(activeLabel, with: cellModel, msgContent: msgContent, font: dataContentFont, titleColor: titleColor)
        handleCustomTags(for: activeLabel, with: cellModel)
        
        resetSubviewsFrame(cellModel: cellModel)
    }
}
