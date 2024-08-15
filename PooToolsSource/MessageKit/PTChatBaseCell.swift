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
    public static let timeTopSpace: CGFloat = PTChatConfig.share.timeTopSpace
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
        createButton(cornerRadius: PTChatConfig.share.messageUserIconSize / 2, clipsToBounds: true)
    }()
    
    open lazy var messageTimeLabel: UILabel = {
        createLabel(font: PTChatConfig.share.chatTimeFont,
                    textColor: PTChatConfig.share.chatTimeColor,
                    backgroundColor: PTChatConfig.share.chatTimeBackgroundColor,
                    isHidden: !PTChatConfig.share.showTimeLabel)
    }()
    
    open lazy var senderNameLabel: UILabel = {
        createLabel(font: PTChatConfig.share.senderNameFont,
                    textColor: PTChatConfig.share.senderNameColor,
                    isHidden: !PTChatConfig.share.showSenderName)
    }()
    
    open lazy var waitImageView: UIButton = {
        createButton(image: PTChatConfig.share.chatWaitImage, userInteractionEnabled: false, isHidden: true)
    }()

    open lazy var readStatusLabel: UIButton = {
        let button = createButton(titleFont: PTChatConfig.share.readStatusFont,
                                  normalTitleColor: PTChatConfig.share.readStatusColor,
                                  selectedTitleColor: PTChatConfig.share.readStatusColor,
                                  normalTitle: PTChatConfig.share.unreadStatusName,
                                  selectedTitle: PTChatConfig.share.readStatusName)
        button.isHidden = !PTChatConfig.share.showReadStatus
        return button
    }()
    
    open lazy var dataContent: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        return view
    }()
    
    open lazy var dataContentStatusView: UIButton = {
        createButton(userInteractionEnabled: false)
    }()
    
    // Initializers
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - UI Setup Methods
    
    private func setupSubviews() {
        contentView.addSubviews([messageTimeLabel, userIcon, senderNameLabel, waitImageView, dataContent, readStatusLabel])
        setStatusView()
    }
    
    private func setStatusView() {
        dataContent.addSubview(dataContentStatusView)
        dataContentStatusView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    open func setBaseSubviews(cellModel: PTChatListModel) {
        outputModel = cellModel
        setupUIWithModel(cellModel: cellModel)
    }
    
    open func resetSubviewsFrame(cellModel: PTChatListModel) {
        outputModel = cellModel
        setupUIWithModel(cellModel: cellModel)
        waitImageView.addActionHandlers { [weak self] sender in
            self?.sendMessageError?(cellModel)
        }
        checkCellSendStatus(cellModel: cellModel)
    }
    
    // MARK: - Common UI Setup Method
    
    private func setupUIWithModel(cellModel: PTChatListModel) {
        // Configure UI elements based on the data model
        userIcon.loadImage(contentData: cellModel.senderCover)
        messageTimeLabel.text = cellModel.messageTimeStamp.conversationTimeSet()
        
        setupTimeLabelConstraints()
        setupUserIconConstraints(cellModel: cellModel)
        setupSenderNameConstraints(cellModel: cellModel)
        setupReadStatusLabelConstraints(cellModel: cellModel)
        setupWaitImageViewConstraints(cellModel: cellModel)
    }
    
    // MARK: - Layout Setup Methods

    private func setupTimeLabelConstraints() {
        let timeLabelHeight = PTChatConfig.share.showTimeLabel ? (PTChatConfig.share.chatTimeFont.pointSize + 15) : 0
        messageTimeLabel.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(self.messageTimeLabel.sizeFor(height: timeLabelHeight).width + PTChatConfig.share.chatTimeContentFixel * 2)
            make.top.equalToSuperview().inset(PTChatBaseCell.timeTopSpace)
            make.height.equalTo(timeLabelHeight)
        }
        PTGCDManager.gcdMain { [weak self] in
            self?.messageTimeLabel.viewCorner(radius: timeLabelHeight / 2)
        }
    }
    
    private func setupUserIconConstraints(cellModel: PTChatListModel) {
        userIcon.snp.remakeConstraints { make in
            make.size.equalTo(PTChatConfig.share.messageUserIconSize)
            make.top.equalTo(messageTimeLabel.snp.bottom)
            make.rightOrLeftEqualToSuperView(belongToMe: cellModel.belongToMe, inset: PTChatConfig.share.userIconFixelSpace)
        }
    }
    
    private func setupSenderNameConstraints(cellModel: PTChatListModel) {
        senderNameLabel.textAlignment = cellModel.belongToMe ? .right : .left
        senderNameLabel.text = cellModel.senderName
        senderNameLabel.snp.remakeConstraints { make in
            make.top.equalTo(userIcon)
            make.rightOrLeftEqualToSuperView(belongToMe: cellModel.belongToMe,equalView: userIcon, inset: PTChatBaseCell.dataContentUserIconInset)
            make.height.equalTo(PTChatConfig.share.showSenderName ? (PTChatConfig.share.senderNameFont.pointSize + 10) : 0)
        }
    }
    
    private func setupReadStatusLabelConstraints(cellModel: PTChatListModel) {
        readStatusLabel.isSelected = cellModel.isRead
        readStatusLabel.titleLabel?.textAlignment = cellModel.belongToMe ? .right : .left
        readStatusLabel.snp.remakeConstraints { make in
            make.top.equalTo(dataContent.snp.bottom)
            make.rightOrLeftEqualToSuperView(belongToMe: cellModel.belongToMe, inset: PTChatBaseCell.dataContentUserIconInset)
            make.height.equalTo(PTChatConfig.share.showReadStatus ? (PTChatConfig.share.readStatusFont.pointSize + 10) : 0)
        }
    }
    
    private func setupWaitImageViewConstraints(cellModel: PTChatListModel) {
        waitImageView.snp.remakeConstraints { make in
            make.size.equalTo(PTChatBaseCell.waitImageSize)
            make.rightOrLeftEqualToDataContent(belongToMe: cellModel.belongToMe,equalView: dataContent, inset: PTChatBaseCell.dataContentWaitImageInset)
            make.bottom.equalTo(dataContent)
        }
    }
    
    // MARK: - Status Check and Animation Methods

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
        waitImageView.layer.add(rotationAnimation(), forKey: "rotationAnimation")
    }
    
    open func stopWaitAnimation() {
        waitImageView.layer.removeAllAnimations()
        waitImageView.isHidden = true
        timer?.invalidate()
        timer = nil
    }
    
    private func rotationAnimation() -> CABasicAnimation {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.toValue = 2 * Double.pi
        rotationAnimation.duration = 1.5
        rotationAnimation.isRemovedOnCompletion = false
        rotationAnimation.repeatCount = .infinity
        return rotationAnimation
    }
    
    // MARK: - Timer and Countdown Methods
    
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
    
    // MARK: - Helper Methods

    private func createButton(cornerRadius: CGFloat = 0,
                              clipsToBounds: Bool = false,
                              image: UIImage? = nil,
                              titleFont: UIFont? = nil,
                              normalTitleColor: UIColor? = nil,
                              selectedTitleColor: UIColor? = nil,
                              normalTitle: String? = nil,
                              selectedTitle: String? = nil,
                              userInteractionEnabled: Bool = true,
                              isHidden: Bool = false) -> UIButton {
        let button = UIButton(type: .custom)
        button.clipsToBounds = clipsToBounds
        button.layer.cornerRadius = cornerRadius
        button.setImage(image, for: .normal)
        button.titleLabel?.font = titleFont
        button.setTitleColor(normalTitleColor, for: .normal)
        button.setTitleColor(selectedTitleColor, for: .selected)
        button.setTitle(normalTitle, for: .normal)
        button.setTitle(selectedTitle, for: .selected)
        button.isUserInteractionEnabled = userInteractionEnabled
        button.isHidden = isHidden
        return button
    }

    private func createLabel(font: UIFont, textColor: UIColor, backgroundColor: UIColor? = nil, isHidden: Bool = false) -> UILabel {
        let label = UILabel()
        label.font = font
        label.textColor = textColor
        label.backgroundColor = backgroundColor
        label.isHidden = isHidden
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }
}

// MARK: - Convenience Methods for Layout Constraints
extension ConstraintMaker {
    func rightOrLeftEqualToSuperView(belongToMe: Bool,equalView:UIView? = nil, inset: CGFloat) {
        if belongToMe {
            if let equalView = equalView {
                self.right.equalTo(equalView.snp.left).offset(-inset)
            } else {
                self.right.equalToSuperview().inset(inset)
            }
        } else {
            if let equalView = equalView {
                self.left.equalTo(equalView.snp.right).offset(inset)
            } else {
                self.left.equalToSuperview().inset(inset)
            }
        }
    }

    func rightOrLeftEqualToDataContent(belongToMe: Bool,equalView:UIView, inset: CGFloat) {
        if belongToMe {
            self.right.equalTo(equalView.snp.left).offset(-inset)
        } else {
            self.left.equalTo(equalView.snp.right).offset(inset)
        }
    }
}
