//
//  PTChatBaseCell.swift
//  LiXinCEO
//
//  Created by 邓杰豪 on 2024/4/1.
//

import UIKit
import SnapKit
#if canImport(PToolsConstraintLayout)
import PToolsConstraintLayout
#endif
#if SWIFT_PACKAGE
import ptools
#endif

public typealias PTChatBaseCellHandler = (_ dataModel: PTChatListModel) -> Void

@objcMembers
@MainActor
open class PTChatBaseCell: PTBaseNormalCell {
    
    // Constants
    public static let timeTopSpace: CGFloat = PTChatConfig.share.timeTopSpace
    public static let waitImageSize: CGFloat = 20
    public static let waitImageRightInset: CGFloat = 10
    public static let dataContentWaitImageInset: CGFloat = 5
    public static let dataContentUserIconInset: CGFloat = 5.5

    // English: Return the width available to message content in the consuming view's visible pane.
    // Español: Devuelve el ancho disponible para el contenido del mensaje en el panel visible de la vista consumidora.
    // 中文：返回消息内容在实际宿主可视面板中的可用宽度。
    public class func adaptiveContainerWidth(for view: UIView) -> CGFloat {
        let region = PTAdaptiveVisibleRegionResolver.region(for: view)
        return region.visibleRect.width > 0 ? region.visibleRect.width : max(1, view.bounds.width)
    }
    
    // Handlers
    public var sendExp: PTChatBaseCellHandler?
    public var sendMessageError: PTChatBaseCellHandler?
    
    private var expirationTask: Task<Void, Never>?
    private var lastAdaptiveLayoutSignature: String?
    
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
        super.init(coder: coder)
        setupSubviews()
    }
    
    deinit {
        expirationTask?.cancel()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        guard let model = outputModel, !contentView.bounds.isEmpty else { return }
        let region = PTAdaptiveVisibleRegionResolver.region(for: contentView)
        let signature = "\(region.signature)|\(contentView.bounds.integral)"
        guard signature != lastAdaptiveLayoutSignature else { return }
        lastAdaptiveLayoutSignature = signature
        setupUserIconConstraints(cellModel: model)
        setupSenderNameConstraints(cellModel: model)
        setupReadStatusLabelConstraints(cellModel: model)
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        expirationTask?.cancel()
        expirationTask = nil
        waitImageView.removeTargerAndAction()
        waitImageView.layer.removeAllAnimations()
        waitImageView.isHidden = true
        waitImageView.isUserInteractionEnabled = false
        outputModel = nil
        sendExp = nil
        sendMessageError = nil
    }
    
    // MARK: - UI Setup Methods
    
    private func setupSubviews() {
        contentView.addSubviews([messageTimeLabel, userIcon, senderNameLabel, waitImageView, dataContent, readStatusLabel])
        setStatusView()
    }
    
    private func setStatusView() {
        dataContent.addSubview(dataContentStatusView)
        dataContentStatusView.ptLayout.makeConstraints { make in
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
        waitImageView.removeTargerAndAction()
        waitImageView.addActionHandlers { [weak self] sender in
            self?.sendMessageError?(cellModel)
        }
        checkCellSendStatus(cellModel: cellModel)
    }
    
    // MARK: - Common UI Setup Method
    
    private func setupUIWithModel(cellModel: PTChatListModel) {
        // Configure UI elements based on the data model
        lastAdaptiveLayoutSignature = nil
        userIcon.loadImage(contentData: cellModel.senderCover)
        messageTimeLabel.text = cellModel.messageTimeStamp.conversationTimeSet(yesterdayString: PTChatConfig.share.yesterDayName)
        
        setupTimeLabelConstraints()
        setupUserIconConstraints(cellModel: cellModel)
        setupSenderNameConstraints(cellModel: cellModel)
        setupReadStatusLabelConstraints(cellModel: cellModel)
        setupWaitImageViewConstraints(cellModel: cellModel)
    }
    
    // MARK: - Layout Setup Methods

    private func setupTimeLabelConstraints() {
        let timeLabelHeight = PTChatConfig.share.showTimeLabel ? (PTChatConfig.share.chatTimeFont.pointSize + 15) : 0
        messageTimeLabel.ptLayout.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(self.messageTimeLabel.sizeFor(height: timeLabelHeight).width + PTChatConfig.share.chatTimeContentFixel * 2)
            make.top.equalToSuperview().inset(PTChatBaseCell.timeTopSpace)
            make.height.equalTo(timeLabelHeight)
        }
        messageTimeLabel.viewCorner(radius: timeLabelHeight / 2)
    }
    
    private func setupUserIconConstraints(cellModel: PTChatListModel) {
        let visibleRect = adaptiveVisibleRect()
        let leadingInset = visibleRect.minX + PTChatConfig.share.userIconFixelSpace
        let trailingInset = max(0, contentView.bounds.width - visibleRect.maxX) + PTChatConfig.share.userIconFixelSpace
        userIcon.ptLayout.remakeConstraints { make in
            make.size.equalTo(PTChatConfig.share.messageUserIconSize)
            make.top.equalTo(messageTimeLabel.ptLayout.bottom).offset(PTChatConfig.share.userIconTopSpacing)
            if cellModel.belongToMe {
                make.right.equalToSuperview().inset(trailingInset)
            } else {
                make.left.equalToSuperview().offset(leadingInset)
            }
        }
    }
    
    private func setupSenderNameConstraints(cellModel: PTChatListModel) {
        senderNameLabel.textAlignment = cellModel.belongToMe ? .right : .left
        senderNameLabel.text = cellModel.senderName
        senderNameLabel.textColor = cellModel.belongToMe ? PTChatConfig.share.senderNameColor : PTChatConfig.share.receiverNameColor
        senderNameLabel.backgroundColor = cellModel.belongToMe ? PTChatConfig.share.senderNameBackgroundColor : PTChatConfig.share.receiverNameBackgroundColor
        senderNameLabel.ptLayout.remakeConstraints { make in
            make.top.equalTo(userIcon)
            if cellModel.belongToMe {
                make.right.equalTo(userIcon.ptLayout.left).offset(-PTChatBaseCell.dataContentUserIconInset)
            } else {
                make.left.equalTo(userIcon.ptLayout.right).offset(PTChatBaseCell.dataContentUserIconInset)
            }
            make.height.equalTo(PTChatConfig.share.showSenderName ? (PTChatConfig.share.senderNameFont.pointSize + 10) : 0)
        }
    }
    
    private func setupReadStatusLabelConstraints(cellModel: PTChatListModel) {
        let visibleRect = adaptiveVisibleRect()
        let leadingInset = visibleRect.minX + PTChatBaseCell.dataContentUserIconInset
        let trailingInset = max(0, contentView.bounds.width - visibleRect.maxX) + PTChatBaseCell.dataContentUserIconInset
        readStatusLabel.isSelected = cellModel.isRead
        readStatusLabel.titleLabel?.textAlignment = cellModel.belongToMe ? .right : .left
        readStatusLabel.ptLayout.remakeConstraints { make in
            make.top.equalTo(dataContent.ptLayout.bottom)
            if cellModel.belongToMe {
                make.right.equalToSuperview().inset(trailingInset)
            } else {
                make.left.equalToSuperview().offset(leadingInset)
            }
            make.height.equalTo(PTChatConfig.share.showReadStatus ? (PTChatConfig.share.readStatusFont.pointSize + 10) : 0)
        }
    }

    // English: Resolve the cell-local visible pane and keep normal devices unchanged.
    // Español: Resuelve el panel visible local de la celda y mantiene sin cambios los dispositivos normales.
    // 中文：解析 Cell 的局部可视面板，普通设备仍保持原有布局。
    private func adaptiveVisibleRect() -> CGRect {
        guard !contentView.bounds.isEmpty else { return contentView.bounds }
        let region = PTAdaptiveVisibleRegionResolver.region(for: contentView)
        let visible = region.visibleRect.intersection(contentView.bounds)
        return visible.isEmpty ? contentView.bounds : visible
    }
    
    private func setupWaitImageViewConstraints(cellModel: PTChatListModel) {
        waitImageView.ptLayout.remakeConstraints { make in
            make.size.equalTo(PTChatBaseCell.waitImageSize)
            if cellModel.belongToMe {
                make.right.equalTo(dataContent.ptLayout.left).offset(-PTChatBaseCell.dataContentWaitImageInset)
            } else {
                make.left.equalTo(dataContent.ptLayout.right).offset(PTChatBaseCell.dataContentWaitImageInset)
            }
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
            waitImageView.isUserInteractionEnabled = false
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
        waitImageView.layer.removeAnimation(forKey: "rotationAnimation")
        waitImageView.layer.add(rotationAnimation(), forKey: "rotationAnimation")
    }
    
    open func stopWaitAnimation() {
        waitImageView.layer.removeAllAnimations()
        waitImageView.isHidden = true
        expirationTask?.cancel()
        expirationTask = nil
    }
    
    private func rotationAnimation() -> CABasicAnimation {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.toValue = 2 * Double.pi
        rotationAnimation.duration = 1.5
        rotationAnimation.isRemovedOnCompletion = false
        rotationAnimation.repeatCount = .infinity
        return rotationAnimation
    }
    
    // English: Use one cancellable task for message expiration instead of a repeating run-loop timer.
    // Español: Usa una tarea cancelable para la caducidad del mensaje en lugar de un temporizador repetitivo del run loop.
    // 中文：使用一个可取消任务处理消息过期，避免重复 RunLoop 定时器。
    
    private func startCountDown(from date: Date) {
        expirationTask?.cancel()
        expirationTask = nil
        updateCountDown(to: date)
        guard !PTChatConfig.timeExp(expTime: date) else { return }

        let expirationDate = date.addingTimeInterval(TimeInterval(PTChatConfig.share.messageExpTime))
        expirationTask = PTMainActorBridge.after(max(0, expirationDate.timeIntervalSinceNow)) { [weak self] in
            self?.updateCountDown(to: date)
        }
    }

    private func updateCountDown(to date: Date) {
        if PTChatConfig.timeExp(expTime: date) {
            expirationTask = nil
            if let outputModel {
                sendExp?(outputModel)
            }
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

// English: MainActor isolation makes the shared chat-cell base safe to capture in UI tasks.
// Español: La aislación MainActor hace segura la captura de la base común de celdas de chat en tareas de UI.
// 中文：共享聊天 Cell 基类由 MainActor 隔离，因此可以安全地被界面任务捕获。
@MainActor
extension PTChatBaseCell: Sendable {}

// MARK: - Convenience Methods for Layout Constraints
extension ConstraintMaker {
    @MainActor func rightOrLeftEqualToSuperView(belongToMe: Bool,equalView:UIView? = nil, inset: CGFloat) {
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

    @MainActor func rightOrLeftEqualToDataContent(belongToMe: Bool,equalView:UIView, inset: CGFloat) {
        if belongToMe {
            self.right.equalTo(equalView.snp.left).offset(-inset)
        } else {
            self.left.equalTo(equalView.snp.right).offset(inset)
        }
    }
}
