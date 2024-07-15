//
//  PTChatBaseCell.swift
//  LiXinCEO
//
//  Created by 邓杰豪 on 2024/4/1.
//

import UIKit
import SnapKit

public typealias PTChatBaseCellHandler = (_ dataModel: PTChatListModel) -> Void

@objcMembers
open class PTChatBaseCell: PTBaseNormalCell {
    
    // Constants
    public static let timeTopSpace: CGFloat = 5
    public static let waitImageSize: CGFloat = 20
    public static let waitImageRightInset: CGFloat = 10
    public static let dataContentWaitImageInset: CGFloat = 5
    public static let dataContentUserIconInset: CGFloat = 5.5
    
    // Handlers
    public var sendExp: PTChatBaseCellHandler?
    public var sendMessageError: PTChatBaseCellHandler?
    
    // Timer for message expiration
    private var timer: Timer?
    
    // Data model
    public var outputModel: PTChatListModel!
    
    // UI Components
    open lazy var userIcon: UIButton = {
        let button = UIButton(type: .custom)
        button.clipsToBounds = true
        button.layer.cornerRadius = PTChatConfig.share.messageUserIconSize / 2
        return button
    }()
    
    open lazy var messageTimeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = PTChatConfig.share.chatTimeFont
        label.textColor = PTChatConfig.share.chatTimeColor
        label.numberOfLines = 0
        label.isHidden = !PTChatConfig.share.showTimeLabel
        label.backgroundColor = PTChatConfig.share.chatTimeBackgroundColor
        return label
    }()
    
    open lazy var senderNameLabel: UILabel = {
        let label = UILabel()
        label.font = PTChatConfig.share.senderNameFont
        label.textColor = PTChatConfig.share.senderNameColor
        label.numberOfLines = 0
        label.isHidden = !PTChatConfig.share.showSenderName
        return label
    }()
    
    open lazy var waitImageView: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(PTChatConfig.share.chatWaitImage, for: .normal)
        button.isUserInteractionEnabled = false
        button.isHidden = true
        return button
    }()

    open lazy var readStatusLabel: UIButton = {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = PTChatConfig.share.readStatusFont
        button.setTitleColor(PTChatConfig.share.readStatusColor, for: .normal)
        button.setTitleColor(PTChatConfig.share.readStatusColor, for: .selected)
        button.setTitle(PTChatConfig.share.unreadStatusName, for: .normal)
        button.setTitle(PTChatConfig.share.readStatusName, for: .selected)
        button.isHidden = !PTChatConfig.share.showReadStatus
        return button
    }()
    
    open lazy var dataContent: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        return view
    }()
    
    open lazy var dataContentStatusView: UIButton = {
        let button = UIButton(type: .custom)
        button.isUserInteractionEnabled = false
        return button
    }()
    
    // Initializers
    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubviews([messageTimeLabel, userIcon, senderNameLabel, waitImageView, dataContent, readStatusLabel])
        setStatusView()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // Methods
    private func setStatusView() {
        dataContent.addSubview(dataContentStatusView)
        dataContentStatusView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    open func setBaseSubsViews(cellModel: PTChatListModel) {
        outputModel = cellModel
        userIcon.loadImage(contentData: cellModel.senderCover)
        messageTimeLabel.text = cellModel.messageTimeStamp.conversationTimeSet()
        let timeLabelHeight = PTChatConfig.share.showTimeLabel ? (PTChatConfig.share.chatTimeFont.pointSize + 15) : 0
        messageTimeLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo((self.messageTimeLabel.sizeFor(height: timeLabelHeight).width + PTChatConfig.share.chatTimeContentFixel * 2))
            make.top.equalToSuperview().inset(PTChatBaseCell.timeTopSpace)
            make.height.equalTo(timeLabelHeight)
        }
        
        PTGCDManager.gcdMain {
            self.messageTimeLabel.viewCorner(radius: timeLabelHeight / 2)
        }
        
        userIcon.snp.makeConstraints { make in
            make.size.equalTo(PTChatConfig.share.messageUserIconSize)
            if cellModel.belongToMe {
                make.right.equalToSuperview().inset(PTChatConfig.share.userIconFixelSpace)
            } else {
                make.left.equalToSuperview().inset(PTChatConfig.share.userIconFixelSpace)
            }
            make.top.equalTo(messageTimeLabel.snp.bottom)
        }
        
        senderNameLabel.textAlignment = cellModel.belongToMe ? .right : .left
        senderNameLabel.text = cellModel.senderName
        senderNameLabel.snp.makeConstraints { make in
            make.top.equalTo(userIcon)
            if cellModel.belongToMe {
                make.right.equalTo(userIcon.snp.left).offset(-PTChatBaseCell.dataContentUserIconInset)
            } else {
                make.left.equalTo(userIcon.snp.right).offset(PTChatBaseCell.dataContentUserIconInset)
            }
            make.height.equalTo(PTChatConfig.share.showSenderName ? (PTChatConfig.share.senderNameFont.pointSize + 10) : 0)
        }
        
        waitImageView.snp.makeConstraints { make in
            make.size.equalTo(PTChatBaseCell.waitImageSize)
            if cellModel.belongToMe {
                make.left.lessThanOrEqualToSuperview().inset(PTChatBaseCell.waitImageRightInset)
            } else {
                make.right.lessThanOrEqualToSuperview().inset(PTChatBaseCell.waitImageRightInset)
            }
            make.bottom.equalTo(dataContent)
        }
    }
    
    open func resetSubsFrame(cellModel: PTChatListModel) {
        userIcon.snp.remakeConstraints { make in
            make.size.equalTo(PTChatConfig.share.messageUserIconSize)
            if cellModel.belongToMe {
                make.right.equalToSuperview().inset(PTChatConfig.share.userIconFixelSpace)
            } else {
                make.left.equalToSuperview().inset(PTChatConfig.share.userIconFixelSpace)
            }
            make.top.equalTo(messageTimeLabel.snp.bottom).offset(PTChatBaseCell.timeTopSpace)
        }
        
        senderNameLabel.snp.remakeConstraints { make in
            make.top.equalTo(userIcon)
            if cellModel.belongToMe {
                make.right.equalTo(userIcon.snp.left).offset(-PTChatBaseCell.dataContentUserIconInset)
            } else {
                make.left.equalTo(userIcon.snp.right).offset(PTChatBaseCell.dataContentUserIconInset)
            }
            make.height.equalTo(PTChatConfig.share.showSenderName ? (PTChatConfig.share.senderNameFont.pointSize + 10) : 0)
        }
        
        if PTChatConfig.share.showReadStatus {
            readStatusLabel.titleLabel?.textAlignment = cellModel.belongToMe ? .right : .left
            readStatusLabel.isSelected = cellModel.isRead
        }
        
        readStatusLabel.snp.remakeConstraints { make in
            make.top.equalTo(dataContent.snp.bottom)
            if cellModel.belongToMe {
                make.right.equalTo(userIcon.snp.left).offset(-PTChatBaseCell.dataContentUserIconInset)
            } else {
                make.left.equalTo(userIcon.snp.right).offset(PTChatBaseCell.dataContentUserIconInset)
            }
            make.height.equalTo(PTChatConfig.share.showReadStatus ? (PTChatConfig.share.readStatusFont.pointSize + 10) : 0)
        }
        
        waitImageView.snp.remakeConstraints { make in
            make.size.equalTo(PTChatBaseCell.waitImageSize)
            if cellModel.belongToMe {
                make.right.equalTo(dataContent.snp.left).offset(-PTChatBaseCell.dataContentWaitImageInset)
            } else {
                make.left.equalTo(dataContent.snp.right).offset(PTChatBaseCell.dataContentWaitImageInset)
            }
            make.bottom.equalTo(dataContent)
        }
        
        waitImageView.addActionHandlers { [weak self] sender in
            self?.sendMessageError?(cellModel)
        }
        
        checkCellSendStatus(cellModel: cellModel)
    }
    
    open func checkCellSendStatus(cellModel: PTChatListModel) {
        switch cellModel.messageStatus {
        case .Sending:
            waitImageView.setImage(PTChatConfig.share.chatWaitImage, for: .normal)
            startWaitAnimation()
            startCountDown(from: cellModel.messageTimeStamp.timeToDate())
        case .Arrived:
            stopWaitAnimation()
            waitImageView.isHidden = true
        case .Error:
            stopWaitAnimation()
            waitImageView.isHidden = false
            waitImageView.isUserInteractionEnabled = true
            waitImageView.setImage(PTChatConfig.share.chatWaitErrorImage, for: .normal)
        }
    }
    
    open func startWaitAnimation() {
        waitImageView.isHidden = false
        waitImageView.isUserInteractionEnabled = false
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.toValue = 2 * Double.pi
        rotationAnimation.duration = 1.5
        rotationAnimation.isRemovedOnCompletion = false
        rotationAnimation.repeatCount = .infinity
        waitImageView.layer.add(rotationAnimation, forKey: nil)
    }
    
    open func stopWaitAnimation() {
        waitImageView.layer.removeAllAnimations()
        waitImageView.isHidden = true
        timer?.invalidate()
        timer = nil
    }
    
    private func startCountDown(from date: Date) {
        updateCountDown(to: date)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateCountDown(to: date)
        }
    }
    
    private func updateCountDown(to date: Date) {
        if PTChatConfig.timeExp(expTime: date) {
            timer?.invalidate()
            sendExp?(outputModel)
        }
    }
}
