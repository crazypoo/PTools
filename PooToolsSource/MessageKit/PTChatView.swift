//
//  PTChatView.swift
//  LiXinCEO
//
//  Created by 邓杰豪 on 2024/3/31.
//

import UIKit
import SnapKit
import AVFoundation
import Photos

public typealias PTChatHandler = @MainActor (PTChatListModel,IndexPath) -> Void
public typealias PTChatCellHandler = (_ collectionView:UICollectionView,_ sectionModel:PTSection,_ indexPath:IndexPath,_ baseCell:UICollectionViewCell) -> PTChatBaseCell?
public typealias PTChatCustomerCellHeightHandler = (_ dataModel:PTChatListModel,_ indexPath:Int) -> CGFloat
public typealias PTAttCellCallBack = (String,IndexPath,PTChatListModel) -> Void
public typealias PTCellMenuItemsHandler = (_ cellId:String) -> [String]?
public typealias PTCellMenuItemsTapCallBack = (_ indexPath:IndexPath,_ cellModel:PTChatListModel,_ itemName:String,_ itemIndex:Int) -> Void

@objcMembers
@MainActor
public class PTChatView: UIView {

    private let chatSectionIdentifier = "PTChatView.messages"

    ///消息数组
    public var chatDataArr:[PTChatListModel] = [PTChatListModel]()
    ///重新发送消息回调
    public var resendMessageHandler:PTChatHandler? = nil
    ///头部刷新回调
    public var headerLoadReadyHandler:PTActionTask? = nil
//    ///点击空地方回调
//    public var listTapHandler:PTActionTask? = nil
    ///消息点击回调
    public var tapMessageHandler:PTChatHandler? = nil
    ///头像点击回调
    public var userIconTapHandler:PTChatHandler? = nil
    //MARK: 自定义消息下使用
    ///自定义Cell设置
    public var customerCellHandler:PTChatCellHandler? = nil
    ///自定义Cell高度设置
    public var customerCellHeightHandler:PTChatCustomerCellHeightHandler? = nil
    ///富文本Cell的内容点击
    public var attCellUrlTapCallBack:PTAttCellCallBack? = nil
    public var attCellChinaPhoneTapCallBack:PTAttCellCallBack? = nil
    public var attCellHashtagTapCallBack:PTAttCellCallBack? = nil
    public var attCellMentionTapCallBack:PTAttCellCallBack? = nil
    public var attCellCustomTapCallBack:PTAttCellCallBack? = nil
    public var messageDownloadedHandler:PTChatHandler? = nil

    ///Cell的Menu
    public var cellMenuItemsHandler:PTCellMenuItemsHandler? = nil
    public var cellMenuItemsTapCallBack:PTCellMenuItemsTapCallBack? = nil

    public var listTopOffset:CGFloat = 0 {
        didSet {
            listContentInset(bottomInset: listBottomOffset,topInset: listTopOffset)
        }
    }
    
    public var listBottomOffset:CGFloat = 0 {
        didSet {
            listContentInset(bottomInset: listBottomOffset,topInset: listTopOffset)
        }
    }
    
    ///消息列表
    public lazy var listCollection:PTCollectionView = {
        let collectionConfig = PTCollectionViewConfig()
        collectionConfig.viewType = .Custom
        collectionConfig.refreshWithoutAnimation = true
        collectionConfig.topRefresh = true

        let view = PTCollectionView(viewConfig: collectionConfig)
        view.registerClassCells(classs: [PTChatSystemMessageCell.ID:PTChatSystemMessageCell.self,PTChatTextCell.ID:PTChatTextCell.self,PTChatMediaCell.ID:PTChatMediaCell.self,PTChatMapCell.ID:PTChatMapCell.self,PTChatVoiceCell.ID:PTChatVoiceCell.self,PTChatTypingIndicatorCell.ID:PTChatTypingIndicatorCell.self,PTChatFileCell.ID:PTChatFileCell.self])
        view.customerLayout = { [weak self] sectionIndex, sectionModel in
            let customerCellHeightHandler = self?.customerCellHeightHandler
            return UICollectionView.waterFallLayout(data: sectionModel.rows,rowCount:1,itemOriginalX: 0,topContentSpace:PTChatConfig.share.chatTopFixel, bottomContentSpace: PTChatConfig.share.chatBottomFixel,itemSpace: 0) { index, model in
                guard let rowModel = model as? PTRows,
                      let cellModel = rowModel.dataModel as? PTChatListModel else {
                    return 44
                }
                var cellHeight:CGFloat = 0
                
                let timeHeight = (PTChatConfig.share.showTimeLabel ? (PTChatConfig.share.chatTimeFont.pointSize + 15) : 0)
                let nameHeight = (PTChatConfig.share.showSenderName ? (PTChatConfig.share.senderNameFont.pointSize + 10) : 0)
                let readStatusHeight = PTChatConfig.share.showReadStatus ? (PTChatConfig.share.readStatusFont.pointSize + 10) : 0
                let spaceHeight = PTChatBaseCell.timeTopSpace * 2
                
                switch cellModel.messageType {
                case .Text:
                    if let msgContent = cellModel.msgContent as? String {
                        
                        var dataContentFont:UIFont!
                        if cellModel.belongToMe {
                            dataContentFont = PTChatConfig.share.textMeMessageFont
                        } else {
                            dataContentFont = PTChatConfig.share.textOtherMessageFont
                        }
                        
                        var contentHeight = UIView.sizeFor(string: msgContent, font: dataContentFont,lineSpacing: PTChatConfig.share.textLineSpace,width: PTChatConfig.ChatContentShowMaxWidth).height + 40
                        
                        let contentNumberOfLines = msgContent.numberOfLines(font: dataContentFont, labelShowWidth: PTChatConfig.ChatContentShowMaxWidth,lineSpacing: PTChatConfig.share.textLineSpace)
                        if contentNumberOfLines <= 1 {
                            contentHeight = PTChatConfig.share.contentBaseHeight
                        }
                    
                        var nameContentTotal = nameHeight + contentHeight + readStatusHeight
                        if nameContentTotal < PTChatConfig.share.messageUserIconSize {
                            nameContentTotal = PTChatConfig.share.messageUserIconSize
                        }
                        
                        cellHeight = nameContentTotal + timeHeight + spaceHeight + PTChatConfig.share.userIconTopSpacing
                    }
                case .Map:
                    let mapHeight = PTChatConfig.share.mapMessageImageHeight
                    cellHeight = timeHeight + nameHeight + mapHeight + spaceHeight + readStatusHeight + PTChatConfig.share.userIconTopSpacing
                case .Media:
                    var imageHeight = PTChatConfig.share.imageMessageImageHeight
                    if let mediaString = cellModel.msgContent as? String {
                        switch mediaString.nsString.contentTypeForUrl() {
                        case .MOV, .MP4, .ThreeGP:
                            imageHeight = PTChatConfig.share.mediaMessageVideoHeight
                        default:
                            imageHeight = PTChatConfig.share.imageMessageImageHeight
                        }
                    } else if let mediaURL = cellModel.msgContent as? URL {
                        switch mediaURL.absoluteString.nsString.contentTypeForUrl() {
                        case .MOV, .MP4, .ThreeGP:
                            imageHeight = PTChatConfig.share.mediaMessageVideoHeight
                        default:
                            imageHeight = PTChatConfig.share.imageMessageImageHeight
                        }
                    } else if let avItem = cellModel.msgContent as? AVPlayerItem {
                        imageHeight = PTChatConfig.share.mediaMessageVideoHeight
                    } else if let avAsset = cellModel.msgContent as? AVAsset {
                        imageHeight = PTChatConfig.share.mediaMessageVideoHeight
                    } else if let asset = cellModel.msgContent as? PHAsset {
                        switch asset.mediaType {
                        case .image:
                            imageHeight = PTChatConfig.share.imageMessageImageHeight
                        case .video:
                            imageHeight = PTChatConfig.share.mediaMessageVideoHeight
                        default:
                            imageHeight = PTChatConfig.share.imageMessageImageHeight
                        }
                    }
                    cellHeight = timeHeight + nameHeight + imageHeight + spaceHeight + readStatusHeight + PTChatConfig.share.userIconTopSpacing
                case .Voice:
                    let voiceHeight:CGFloat = 38
                    cellHeight = timeHeight + nameHeight + voiceHeight + spaceHeight + readStatusHeight + PTChatConfig.share.userIconTopSpacing
                case .File:
                    var url:URL?
                    if let contentString = cellModel.msgContent as? String {
                        url = URL(string: contentString)
                    } else if let contentURL = cellModel.msgContent as? URL {
                        url = contentURL
                    }
                    
                    var contentHeight:CGFloat = PTChatFileCell.FileCellHeight
                    if let findURL = url {
                        let nameHeight = UIView.sizeFor(string: findURL.lastPathComponent, font: PTChatConfig.share.fileNameFont,lineSpacing: PTChatConfig.share.fileContentSpace,width: PTChatFileCell.FileConentWidth - PTChatFileCell.FileCellImageHeight - PTChatFileCell.FileCellConentFixbel * 3).height
                        let fileSizeHeight = PTChatConfig.share.fileSizeFont.pointSize + 2 + PTChatFileCell.FileCellConentFixbel * 2
                        let total = nameHeight + fileSizeHeight
                        if total >= contentHeight {
                            contentHeight = total
                        }
                    }
                    cellHeight = timeHeight + contentHeight + nameHeight + PTChatBaseCell.timeTopSpace * 3 + readStatusHeight + PTChatConfig.share.userIconTopSpacing
                case .SystemMessage:
                    let timeHeight = UIView.sizeFor(string: cellModel.messageTimeStamp.timeToDate().toFormat("yyyy-MM-dd HH:MM:ss"), font: PTChatConfig.share.chatTimeFont,lineSpacing: 2,width: CGFloat.kSCREEN_WIDTH).height
                    var contentHeight:CGFloat = 0
                    if let contentString = cellModel.msgContent as? String {
                        contentHeight = UIView.sizeFor(string: contentString, font: PTChatConfig.share.chatSystemMessageFont,lineSpacing: 2,width: CGFloat.kSCREEN_WIDTH).height
                    }
                    cellHeight = timeHeight + contentHeight + 20
                case .Typing:
                    cellHeight = 44
                case .CustomerMessage:
                    cellHeight = customerCellHeightHandler?(cellModel,index) ?? 44
                }
                return cellHeight
            }
        }
        view.cellInCollection = { [weak self] collectionView, sectionModel, indexPath in
            guard let self,
                  let rows = sectionModel.rows,
                  rows.indices.contains(indexPath.item) else {
                return nil
            }

            let itemRow = rows[indexPath.item]
            guard let cellModel = itemRow.dataModel as? PTChatListModel else {
                return nil
            }

            let baseCell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath)
            if itemRow.ID == PTChatSystemMessageCell.ID, let cell = baseCell as? PTChatSystemMessageCell {
                cell.cellModel = cellModel
                return cell
            }
            if itemRow.ID == PTChatTypingIndicatorCell.ID, let cell = baseCell as? PTChatTypingIndicatorCell {
                return cell
            }

            if cellModel.messageType == .CustomerMessage {
                guard let cell = self.customerCellHandler?(collectionView, sectionModel, indexPath, baseCell) else {
                    return nil
                }
                cell.dataContent.gestureRecognizers?.forEach { cell.dataContent.removeGestureRecognizer($0) }
                let longTap = self.cellLongTap(cell: cell, itemId: itemRow.ID, cellModel: cellModel, indexPath: indexPath)
                cell.dataContent.addGestureRecognizers([longTap])
                return cell
            }

            guard let cell = baseCell as? PTChatBaseCell else {
                return nil
            }

            if itemRow.ID == PTChatTextCell.ID, let textCell = cell as? PTChatTextCell {
                textCell.cellModel = cellModel
                textCell.chinaPhoneCallback = { [weak self] text in
                    self?.attCellChinaPhoneTapCallBack?(text, indexPath, cellModel)
                }
                textCell.mentionCallback = { [weak self] text in
                    self?.attCellMentionTapCallBack?(text, indexPath, cellModel)
                }
                textCell.urlCallback = { [weak self] text in
                    self?.attCellUrlTapCallBack?(text, indexPath, cellModel)
                }
                textCell.hashtagCallback = { [weak self] text in
                    self?.attCellHashtagTapCallBack?(text, indexPath, cellModel)
                }
                textCell.customCallback = { [weak self] text in
                    self?.attCellCustomTapCallBack?(text, indexPath, cellModel)
                }
            } else if itemRow.ID == PTChatMediaCell.ID, let mediaCell = cell as? PTChatMediaCell {
                mediaCell.cellModel = cellModel
                mediaCell.mediaPlayButtonTapCallback = { [weak self] in
                    PTMainActorBridge.perform { [weak self] in
                        self?.tapMessageHandler?(cellModel, indexPath)
                    }
                }
                mediaCell.mediaDownloadFinishCallback = { [weak self] in
                    PTMainActorBridge.perform { [weak self] in
                        self?.messageDownloadedHandler?(cellModel, indexPath)
                    }
                }
            } else if itemRow.ID == PTChatMapCell.ID, let mapCell = cell as? PTChatMapCell {
                mapCell.cellModel = cellModel
            } else if itemRow.ID == PTChatVoiceCell.ID, let voiceCell = cell as? PTChatVoiceCell {
                voiceCell.cellModel = cellModel
            } else if itemRow.ID == PTChatFileCell.ID, let fileCell = cell as? PTChatFileCell {
                fileCell.cellModel = cellModel
            }

            cell.sendMessageError = { [weak self] errorModel in
                self?.resendMessage(cellModel: errorModel, indexPath: indexPath)
            }
            cell.sendExp = { [weak cell] expModel in
                expModel.messageStatus = .Error
                cell?.checkCellSendStatus(cellModel: expModel)
            }

            // English: Remove interactions from the previous model before installing the current model's gestures.
            // Español: Elimina las interacciones del modelo anterior antes de instalar los gestos del modelo actual.
            // 中文：先移除上一个模型的交互，再安装当前模型的手势。
            cell.dataContent.gestureRecognizers?.forEach { cell.dataContent.removeGestureRecognizer($0) }
            var gestures: [UIGestureRecognizer] = []
            let longTap = self.cellLongTap(cell: cell, itemId: itemRow.ID, cellModel: cellModel, indexPath: indexPath)
            if itemRow.ID != PTChatTextCell.ID {
                let tap = UITapGestureRecognizer { [weak self, weak cell] _ in
                    guard let self, let cell else { return }
                    if itemRow.ID == PTChatMediaCell.ID, let mediaCell = cell as? PTChatMediaCell {
                        if mediaCell.isImage || mediaCell.videoCacheURL != nil {
                            self.tapMessageHandler?(cellModel, indexPath)
                        } else if mediaCell.needLoadVideo, let needLoadURL = mediaCell.loadMediaURL {
                            mediaCell.mediaDownloadFunction(urlReal: needLoadURL)
                        } else {
                            self.tapMessageHandler?(cellModel, indexPath)
                        }
                    } else {
                        self.tapMessageHandler?(cellModel, indexPath)
                    }
                }
                gestures = [tap, longTap]
            } else {
                gestures = [longTap]
            }
            cell.dataContent.addGestureRecognizers(gestures)

            cell.userIcon.removeTargerAndAction()
            cell.userIcon.addActionHandlers { [weak self] _ in
                self?.userIconTapHandler?(cellModel, indexPath)
            }
            return cell
        }
        view.headerRefreshTask = { [weak self] in
            PTMainActorBridge.perform { [weak self] in
                self?.headerLoadReadyHandler?()
            }
        }
        return view
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        listContentInset()
        addSubviews([listCollection])
        listCollection.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        listContentInset()
        addSubviews([listCollection])
        listCollection.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    public func chatRegisterClass(classs:[String:PTChatBaseCell.Type]) {
        self.listCollection.contentCollectionView.registerClassCells(classs: classs)
    }
    
    func cellLongTap(cell:PTChatBaseCell,itemId:String,cellModel:PTChatListModel,indexPath:IndexPath) ->UILongPressGestureRecognizer {
        let longTap = UILongPressGestureRecognizer { [weak self, weak cell] sender in
            if let longGes = sender as? UILongPressGestureRecognizer,
               let self,
               let cell {
                switch longGes.state {
                case .possible:break
                case .began:
                    cell.dataContentStatusView.isHighlighted = true
                case .changed:break
                case .ended:
                    cell.dataContentStatusView.isHighlighted = false
                    if let menuTitles = self.cellMenuItemsHandler?(itemId), !menuTitles.isEmpty {
                        let items = menuTitles.enumerated().map { index, title in
                            
                            let menuItem = PTEditMenuAction(title: title) { [weak self] in
                                Task { @MainActor [weak self] in
                                    self?.cellMenuItemsTapCallBack?(indexPath, cellModel, title, index)
                                }
                            }
                            return menuItem
                        }

                        cell.dataContent.pt_bindEditMenu(actions: items)
                    }
                case .cancelled:break
                case .failed:break
                case .recognized:break
                @unknown default:break
                }
            }
        }
        longTap.minimumPressDuration = 0.5
        return longTap
    }
    
    ///刷新数据
    public func viewReloadData(loadFinish:PTCollectionCallback? = nil) {
        if !chatDataArr.isEmpty {
            var sections = [PTSection]()
            let rows:[PTRows] = chatDataArr.compactMap { value in
                let diffIdentifier = value.diffId
                switch value.messageType {
                case .SystemMessage:
                    return PTRows(ID: PTChatSystemMessageCell.ID, diffId: diffIdentifier, dataModel: value)
                case .Text:
                    return PTRows(ID: PTChatTextCell.ID, diffId: diffIdentifier, dataModel: value)
                case .Media:
                    return PTRows(ID: PTChatMediaCell.ID, diffId: diffIdentifier, dataModel: value)
                case .Map:
                    return PTRows(ID: PTChatMapCell.ID, diffId: diffIdentifier, dataModel: value)
                case .Voice:
                    return PTRows(ID: PTChatVoiceCell.ID, diffId: diffIdentifier, dataModel: value)
                case .Typing:
                    return PTRows(ID: PTChatTypingIndicatorCell.ID, diffId: diffIdentifier, dataModel: value)
                case .File:
                    return PTRows(ID: PTChatFileCell.ID, diffId: diffIdentifier, dataModel: value)
                case .CustomerMessage:
                    guard !value.customerCellId.stringIsEmpty() else { return nil }
                    return PTRows(ID: value.customerCellId, diffId: diffIdentifier, dataModel: value)
                }
            }
            let section = PTSection(identifier: chatSectionIdentifier, rows: rows)
            sections.append(section)
            listCollection.showCollectionDetail(collectionData: sections,finishTask: loadFinish)
        } else {
            listCollection.clearAllData(finishTask: loadFinish)
        }
    }
    
    fileprivate func resendMessage(cellModel:PTChatListModel,indexPath:IndexPath) {
        guard let currentIndex = chatDataArr.firstIndex(where: { $0 === cellModel || $0.diffId == cellModel.diffId }) else {
            return
        }

        let timeStamp = Date().timeIntervalSince1970
        let currentModel = chatDataArr.remove(at: currentIndex)
        currentModel.messageStatus = .Sending
        currentModel.messageTimeStamp = timeStamp
        self.chatDataArr.append(currentModel)
        let newIndexPath = IndexPath(item: chatDataArr.count - 1, section: 0)
        self.viewReloadData { cView in
            self.listCollection.contentCollectionView.scrollToBottom()
            self.resendMessageHandler?(currentModel, newIndexPath)
        }
    }
    
    func listContentInset(bottomInset:CGFloat = 0,topInset:CGFloat = 0) {
        listCollection.contentCollectionView.contentInsetAdjustmentBehavior = .never
        listCollection.contentCollectionView.contentInset.top = topInset
        listCollection.contentCollectionView.contentInset.bottom = bottomInset
    }
}
