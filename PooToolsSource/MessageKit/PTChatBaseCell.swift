//
//  PTChatBaseCell.swift
//  LiXinCEO
//
//  Created by 邓杰豪 on 2024/4/1.
//

import UIKit
import SnapKit

public typealias PTChatBaseCellHandler = (_ dataModel:PTChatListModel) -> Void

@objcMembers
open class PTChatBaseCell: PTBaseNormalCell {
    
    ///Cell时间到顶部的高度
    public static let TimeTopSpace:CGFloat = 5
    ///等待图片大小
    public static let WaitImageSize:CGFloat = 20
    ///等待图片到边的距离
    public static let WaitImageRightFixel:CGFloat = 10
    ///等待图片到内容距离
    public static let DataContentWaitImageFixel:CGFloat = 5
    ///内容到头像距离
    public static let DataContentUserIconFixel:CGFloat = 5.5
    ///消息过期回调
    public var sendExp:PTChatBaseCellHandler? = nil
    ///错误点击回调
    public var sendMesageError:PTChatBaseCellHandler? = nil

    fileprivate var timer:Timer?
    public var outputModel:PTChatListModel!
    
    open lazy var userIcon:UIButton = {
        let view = UIButton(type: .custom)
        view.clipsToBounds = true
        view.viewCorner(radius: PTChatConfig.share.messageUserIconSize / 2)
        return view
    }()
    
    open lazy var messageTimeLabel:UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.font = PTChatConfig.share.chatTimeFont
        view.textColor = PTChatConfig.share.chatTimeColor
        view.numberOfLines = 0
        view.isHidden = !PTChatConfig.share.showTimeLabel
        return view
    }()
    
    open lazy var senderNameLabel:UILabel = {
        let view = UILabel()
        view.font = PTChatConfig.share.senderNameFont
        view.textColor = PTChatConfig.share.senderNameColor
        view.numberOfLines = 0
        view.isHidden = !PTChatConfig.share.showSenderName
        return view
    }()
    
    open lazy var waitImageView:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(PTChatConfig.share.chatWaitImage, for: .normal)
        view.isUserInteractionEnabled = false
        view.isHidden = true
        return view
    }()
    
    open lazy var readStatusLabel:UIButton = {
        let view = UIButton(type: .custom)
        view.titleLabel?.font = PTChatConfig.share.readStatusFont
        view.setTitleColor(PTChatConfig.share.readStatusColor, for: .normal)
        view.setTitleColor(PTChatConfig.share.readStatusColor, for: .selected)
        view.setTitle(PTChatConfig.share.unreadStatusName, for: .normal)
        view.setTitle(PTChatConfig.share.readStatusName, for: .selected)
        view.isHidden = !PTChatConfig.share.showReadStatus
        return view
    }()
    
    open lazy var dataContent:UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        return view
    }()
    
    open lazy var dataContentStatusView:UIButton = {
        let view = UIButton(type: .custom)
        view.isUserInteractionEnabled = false
        return view
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubviews([messageTimeLabel,userIcon,senderNameLabel,waitImageView,dataContent,readStatusLabel])
        setStatusView()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    func setStatusView() {
        dataContent.addSubview(dataContentStatusView)
        dataContentStatusView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    ///配置初始界面,如果继承这个view需要在新的view中remakeConstraints
    open func setBaseSubsViews(cellModel:PTChatListModel) {
        outputModel = cellModel
        userIcon.pt_SDWebImage(imageString: cellModel.senderCover)
        messageTimeLabel.text = cellModel.messageTimeStamp.conversationTimeSet()
        messageTimeLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(PTChatBaseCell.TimeTopSpace)
            make.height.equalTo(PTChatConfig.share.showTimeLabel ? (PTChatConfig.share.chatTimeFont.pointSize + 15) : 0)
        }
        
        userIcon.snp.makeConstraints { make in
            make.size.equalTo(PTChatConfig.share.messageUserIconSize)
            if cellModel.belongToMe {
                make.right.equalToSuperview().inset(PTChatConfig.share.userIconFixelSpace)
            } else {
                make.left.equalToSuperview().inset(PTChatConfig.share.userIconFixelSpace)
            }
            make.top.equalTo(self.messageTimeLabel.snp.bottom)
        }
        
        if cellModel.belongToMe {
            senderNameLabel.textAlignment = .right
        } else {
            senderNameLabel.textAlignment = .left
        }
        senderNameLabel.text = cellModel.senderName
        senderNameLabel.snp.makeConstraints { make in
            make.top.equalTo(self.userIcon)
            if cellModel.belongToMe {
                make.right.equalTo(self.userIcon.snp.left).offset(-PTChatBaseCell.DataContentUserIconFixel)
            } else {
                make.left.equalTo(self.userIcon.snp.right).offset(PTChatBaseCell.DataContentUserIconFixel)
            }
            
            make.height.equalTo(PTChatConfig.share.showSenderName ? (PTChatConfig.share.senderNameFont.pointSize + 10) : 0)
        }
        
        waitImageView.snp.makeConstraints { make in
            make.size.equalTo(PTChatBaseCell.WaitImageSize)
            if cellModel.belongToMe {
                make.left.lessThanOrEqualToSuperview().inset(PTChatBaseCell.WaitImageRightFixel)
            } else {
                make.right.lessThanOrEqualToSuperview().inset(PTChatBaseCell.WaitImageRightFixel)
            }
            make.bottom.equalTo(self.dataContent)
        }
    }
    
    open func resetSubsFrame(cellModel:PTChatListModel) {
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
            
            make.height.equalTo(PTChatConfig.share.showSenderName ? (PTChatConfig.share.senderNameFont.pointSize + 10) : 0)
        }

        if PTChatConfig.share.showReadStatus {
            if cellModel.belongToMe {
                readStatusLabel.titleLabel?.textAlignment = .right
            } else {
                readStatusLabel.titleLabel?.textAlignment = .left
            }
            
            readStatusLabel.isSelected = cellModel.isRead
        }
        readStatusLabel.snp.remakeConstraints { make in
            make.top.equalTo(self.dataContent.snp.bottom)
            if cellModel.belongToMe {
                make.right.equalTo(self.userIcon.snp.left).offset(-PTChatBaseCell.DataContentUserIconFixel)
            } else {
                make.left.equalTo(self.userIcon.snp.right).offset(PTChatBaseCell.DataContentUserIconFixel)
            }
            
            make.height.equalTo(PTChatConfig.share.showReadStatus ? (PTChatConfig.share.readStatusFont.pointSize + 10) : 0)
        }
        
        waitImageView.snp.remakeConstraints { make in
            make.size.equalTo(PTChatBaseCell.WaitImageSize)
            if cellModel.belongToMe {
                make.right.equalTo(self.dataContent.snp.left).offset(-PTChatBaseCell.DataContentWaitImageFixel)
            } else {
                make.left.equalTo(self.dataContent.snp.right).offset(PTChatBaseCell.DataContentWaitImageFixel)
            }
            make.bottom.equalTo(self.dataContent)
        }
        waitImageView.addActionHandlers { sender in
            self.sendMesageError?(cellModel)
        }
        checkCellSendStatus(cellModel: cellModel)
    }
    
    ///检测Cell是否过期
    open func checkCellSendStatus(cellModel:PTChatListModel) {
        
        switch cellModel.messageStatus {
        case .Sending:
            waitImageView.setImage(PTChatConfig.share.chatWaitImage, for: .normal)
            startWaitAnimation()
            startCountDown(date: cellModel.messageTimeStamp.timeToDate())
        case .Arrived:
            stopWaitAnimation()
            waitImageView.isHidden = true
            waitImageView.isUserInteractionEnabled = false
            waitImageView.setImage(PTChatConfig.share.chatWaitImage, for: .normal)
        case .Error:
            stopWaitAnimation()
            waitImageView.isHidden = false
            waitImageView.isUserInteractionEnabled = true
            waitImageView.setImage(PTChatConfig.share.chatWaitErrorImage, for: .normal)
        }
    }
    
    ///等待View动画开启
    open func startWaitAnimation() {
        waitImageView.isHidden = false
        waitImageView.isUserInteractionEnabled = false
        let layerAnimation = CABasicAnimation(keyPath: "transform.rotation")
        layerAnimation.toValue = 2 * Double.pi
        layerAnimation.duration = 1.5
        layerAnimation.isRemovedOnCompletion = false
        layerAnimation.repeatCount = Float(MAXFLOAT)
        waitImageView.layer.add(layerAnimation, forKey: nil)
    }
    
    ///等待View动画关闭
    open func stopWaitAnimation() {
        waitImageView.layer.removeAllAnimations()
        waitImageView.isHidden = true
        waitImageView.isUserInteractionEnabled = false
        timer?.invalidate()
        timer = nil
    }
    
    fileprivate func startCountDown(date:Date) {
        self.updateCountDown(date: date)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { timer in
            self.updateCountDown(date: date)
        })
    }
    
    fileprivate func updateCountDown(date:Date) {
        if PTChatConfig.timeExp(expTime: date) {
            self.timer?.invalidate()
            self.timer = nil
            self.sendExp?(self.outputModel)
        }
    }
}
