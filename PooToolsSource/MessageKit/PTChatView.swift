//
//  PTChatView.swift
//  LiXinCEO
//
//  Created by 邓杰豪 on 2024/3/31.
//

import UIKit
import SnapKit

public typealias PTChatHandler = (PTChatListModel,IndexPath) -> Void
public typealias PTChatCellHandler = (_ collectionView:UICollectionView,_ sectionModel:PTSection,_ indexPath:IndexPath) -> PTChatBaseCell?
public typealias PTChatCustomerCellHeightHandler = (_ dataModel:PTChatListModel,_ indexPath:Int) -> CGFloat
public typealias PTAttCellCallBack = (String,IndexPath,PTChatListModel) -> Void
public typealias PTCellMenuItemsHandler = (_ cellId:String) -> [String]?
public typealias PTCellMenuItemsTapCallBack = (_ indexPath:IndexPath,_ cellModel:PTChatListModel,_ itemName:String,_ itemIndex:Int) -> Void

@objcMembers
public class PTChatView: UIView {

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

    ///Cell的Menu
    public var cellMenuItemsHandler:PTCellMenuItemsHandler? = nil
    public var cellMenuItemsTapCallBack:PTCellMenuItemsTapCallBack? = nil

    ///消息列表
    public lazy var listCollection:PTCollectionView = {
        let collectionConfig = PTCollectionViewConfig()
        collectionConfig.viewType = .Custom
        collectionConfig.refreshWithoutAnimation = true
        collectionConfig.topRefresh = true

        let view = PTCollectionView(viewConfig: collectionConfig)
        view.registerClassCells(classs: [PTChatSystemMessageCell.ID:PTChatSystemMessageCell.self,PTChatTextCell.ID:PTChatTextCell.self,PTChatMediaCell.ID:PTChatMediaCell.self,PTChatMapCell.ID:PTChatMapCell.self,PTChatVoiceCell.ID:PTChatVoiceCell.self,PTChatTypingIndicatorCell.ID:PTChatTypingIndicatorCell.self,PTChatFileCell.ID:PTChatFileCell.self])
        view.customerLayout = { sectionIndex,sectionModel in
            var groupHeight:CGFloat = 0 + PTChatConfig.share.chatTopFixel
            var bannerGroupSize : NSCollectionLayoutSize
            var customers = [NSCollectionLayoutGroupCustomItem]()
            sectionModel.rows?.enumerated().forEach { (index,model) in
                if let cellModel = model.dataModel as? PTChatListModel {
                    var cellHeight:CGFloat = 0
                    
                    let timeHeight = (PTChatConfig.share.showTimeLabel ? (PTChatConfig.share.chatTimeFont.pointSize + 15) : 0)
                    let nameHeight = (PTChatConfig.share.showSenderName ? (PTChatConfig.share.senderNameFont.pointSize + 10) : 0)
                    let readStatusHeight = PTChatConfig.share.showReadStatus ? (PTChatConfig.share.readStatusFont.pointSize + 10) : 0
                    let spaceHeight = PTChatBaseCell.timeTopSpace * 2
                    
                    switch cellModel.messageType {
                    case .Text:
                        let msgContent = cellModel.msgContent as! String
                        
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
                        
                        cellHeight = nameContentTotal + timeHeight + spaceHeight
                    case .Map:
                        let mapHeight = PTChatConfig.share.mapMessageImageHeight
                        cellHeight = timeHeight + nameHeight + mapHeight + spaceHeight + readStatusHeight
                    case .Media:
                        let imageHeight = PTChatConfig.share.imageMessageImageHeight
                        cellHeight = timeHeight + nameHeight + imageHeight + spaceHeight + readStatusHeight
                    case .Voice:
                        let voiceHeight:CGFloat = 38
                        cellHeight = timeHeight + nameHeight + voiceHeight + spaceHeight + readStatusHeight
                    case .File:
                        var url:URL?
                        if cellModel.msgContent is String {
                            let contentString = cellModel.msgContent as! String
                            url = URL(string: contentString)
                        } else if cellModel.msgContent is URL {
                            url = (cellModel.msgContent as! URL)
                        }
                        
                        var contentHeight:CGFloat = PTChatFileCell.FileCellHeight
                        if url != nil {
                            let nameHeight = UIView.sizeFor(string: url!.lastPathComponent, font: PTChatConfig.share.fileNameFont,lineSpacing: PTChatConfig.share.fileContentSpace as NSNumber,width: PTChatFileCell.FileConentWidth - PTChatFileCell.FileCellImageHeight - PTChatFileCell.FileCellConentFixbel * 3).height
                            let fileSizeHeight = PTChatConfig.share.fileSizeFont.pointSize + 2 + PTChatFileCell.FileCellConentFixbel * 2
                            let total = nameHeight + fileSizeHeight
                            if total >= contentHeight {
                                contentHeight = total
                            }
                        }
                        cellHeight = timeHeight + contentHeight + nameHeight + PTChatBaseCell.timeTopSpace * 3 + readStatusHeight
                    case .SystemMessage:
                        let timeHeight = UIView.sizeFor(string: cellModel.messageTimeStamp.timeToDate().toFormat("yyyy-MM-dd HH:MM:ss"), font: PTChatConfig.share.chatTimeFont,lineSpacing: 2,width: CGFloat.kSCREEN_WIDTH).height
                        var contentHeight:CGFloat = 0
                        if cellModel.msgContent is String {
                            contentHeight = UIView.sizeFor(string: cellModel.msgContent as! String, font: PTChatConfig.share.chatSystemMessageFont,lineSpacing: 2,width: CGFloat.kSCREEN_WIDTH).height
                        }
                        cellHeight = timeHeight + contentHeight + 20
                    case .Typing:
                        cellHeight = 44
                    case .CustomerMessage:
                        cellHeight = self.customerCellHeightHandler?(cellModel,index) ?? 0
                    }
                    let customItem = NSCollectionLayoutGroupCustomItem.init(frame: CGRect.init(x: 0, y: groupHeight, width: CGFloat.kSCREEN_WIDTH, height: cellHeight), zIndex: 1000+index)
                    customers.append(customItem)
                    groupHeight += (cellHeight)
                    if ((sectionModel.rows?.count ?? 0) - 1) == index {
                        groupHeight += PTChatConfig.share.chatBottomFixel
                    }
                }
            }
            bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(CGFloat.kSCREEN_WIDTH), heightDimension: NSCollectionLayoutDimension.absolute(groupHeight))
            return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
                customers
            })
        }
        view.cellInCollection = { collectionView,sectionModel,indexPath in
            if let itemRow = sectionModel.rows?[indexPath.row],let cellModel = itemRow.dataModel as? PTChatListModel {
                if itemRow.ID == PTChatSystemMessageCell.ID,let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTChatSystemMessageCell {
                    cell.cellModel = cellModel
                    return cell
                } else if itemRow.ID == PTChatTypingIndicatorCell.ID,let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTChatTypingIndicatorCell {
                    return cell
                } else {
                    switch cellModel.messageType {
                    case .CustomerMessage:
                        return self.customerCellHandler?(collectionView,sectionModel,indexPath)
                    default:
                        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTChatBaseCell {
                            if itemRow.ID == PTChatTextCell.ID,let textCell = cell as? PTChatTextCell {
                                textCell.cellModel = cellModel
                                textCell.chinaPhoneCallback = { text in
                                    self.attCellChinaPhoneTapCallBack?(text,indexPath,cellModel)
                                }
                                textCell.mentionCallback = {  text in
                                    self.attCellMentionTapCallBack?(text,indexPath,cellModel)
                                }
                                textCell.urlCallback = { text in
                                    self.attCellUrlTapCallBack?(text,indexPath,cellModel)
                                }
                                textCell.hashtagCallback = { text in
                                    self.attCellHashtagTapCallBack?(text,indexPath,cellModel)
                                }
                                textCell.customCallback = { text in
                                    self.attCellCustomTapCallBack?(text,indexPath,cellModel)
                                }
                            } else if itemRow.ID == PTChatMediaCell.ID,let mediaCell = cell as? PTChatMediaCell {
                                mediaCell.cellModel = cellModel
                            } else if itemRow.ID == PTChatMapCell.ID,let mapCell = cell as? PTChatMapCell {
                                mapCell.cellModel = cellModel
                            } else if itemRow.ID == PTChatVoiceCell.ID,let voiceCell = cell as? PTChatVoiceCell {
                                voiceCell.cellModel = cellModel
                            } else if itemRow.ID == PTChatFileCell.ID,let fileCell = cell as? PTChatFileCell {
                                fileCell.cellModel = cellModel
                            }
                            cell.sendMessageError = { errorModel in
                                self.resendMessage(cellModel: errorModel, indexPath: indexPath)
                            }
                            
                            if itemRow.ID != PTChatTextCell.ID {
                                let longTap = self.cellLongTap(cell: cell, itemId: itemRow.ID, cellModel: cellModel, indexPath: indexPath)
                                let tap = UITapGestureRecognizer { sender in
                                    self.tapMessageHandler?(cellModel,indexPath)
                                }
                                cell.dataContent.addGestureRecognizers([tap,longTap])
                            } else {
                                let longTap = self.cellLongTap(cell: cell, itemId: itemRow.ID, cellModel: cellModel, indexPath: indexPath)
                                cell.contentView.isUserInteractionEnabled = true
                                cell.contentView.addGestureRecognizers([longTap])
                            }

                            cell.sendExp = { expModel in
                                self.chatDataArr[indexPath.row].messageStatus = .Error
                                if itemRow.ID == PTChatTextCell.ID,let textCell = cell as? PTChatTextCell {
                                    textCell.cellModel = self.chatDataArr[indexPath.row]
                                } else if itemRow.ID == PTChatMediaCell.ID,let mediaCell = cell as? PTChatMediaCell {
                                    mediaCell.cellModel = self.chatDataArr[indexPath.row]
                                } else if itemRow.ID == PTChatMapCell.ID,let mapCell = cell as? PTChatMapCell {
                                    mapCell.cellModel = self.chatDataArr[indexPath.row]
                                } else if itemRow.ID == PTChatVoiceCell.ID,let voiceCell = cell as? PTChatVoiceCell {
                                    voiceCell.cellModel = self.chatDataArr[indexPath.row]
                                } else if itemRow.ID == PTChatFileCell.ID,let fileCell = cell as? PTChatFileCell {
                                    fileCell.cellModel = self.chatDataArr[indexPath.row]
                                }
                            }
                            cell.userIcon.addActionHandlers { sender in
                                self.userIconTapHandler?(cellModel,indexPath)
                            }
                            return cell
                        }
                    }
                }
            }
            return nil
        }
        view.headerRefreshTask = { control in
            self.headerLoadReadyHandler?()
        }
//        let tap = UITapGestureRecognizer { sender in
//            self.listTapHandler?()
//        }
//        view.addGestureRecognizer(tap)
        return view
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews([listCollection])
        listCollection.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func chatRegisterClass(classs:[String:PTChatBaseCell.Type]) {
        self.listCollection.contentCollectionView.registerClassCells(classs: classs)
    }
    
    func cellLongTap(cell:PTChatBaseCell,itemId:String,cellModel:PTChatListModel,indexPath:IndexPath) ->UILongPressGestureRecognizer {
        let longTap = UILongPressGestureRecognizer { sender in
            let longGes = sender as! UILongPressGestureRecognizer
            switch longGes.state {
            case .possible:break
            case .began:
                cell.dataContentStatusView.isHighlighted = true
            case .changed:break
            case .ended:
                cell.dataContentStatusView.isHighlighted = false
            case .cancelled:break
            case .failed:break
            case .recognized:break
            @unknown default:break
            }
            
            if let menuTitles = self.cellMenuItemsHandler?(itemId), !menuTitles.isEmpty {
                let items = menuTitles.enumerated().map { index, title in
                    PTEditMenuItem(title: title) {
                        self.cellMenuItemsTapCallBack?(indexPath, cellModel, title, index)
                    }
                }

                PTEditMenuItemsInteraction.share.showMenu(items, targetRect: cell.dataContentStatusView.frame, for: cell.dataContentStatusView)
            }
        }
        longTap.minimumPressDuration = 0.5
        return longTap
    }
    
    ///刷新数据
    public func viewReloadData(loadFinish:((UICollectionView)->Void)? = nil) {
        var sections = [PTSection]()
        if chatDataArr.count > 0 {
            let rows: [PTRows] = chatDataArr.compactMap { value in
                switch value.messageType {
                case .SystemMessage:
                    return PTRows(ID: PTChatSystemMessageCell.ID, dataModel: value)
                case .Text:
                    return PTRows(ID: PTChatTextCell.ID, dataModel: value)
                case .Media:
                    return PTRows(ID: PTChatMediaCell.ID, dataModel: value)
                case .Map:
                    return PTRows(ID: PTChatMapCell.ID, dataModel: value)
                case .Voice:
                    return PTRows(ID: PTChatVoiceCell.ID, dataModel: value)
                case .Typing:
                    return PTRows(ID: PTChatTypingIndicatorCell.ID, dataModel: value)
                case .File:
                    return PTRows(ID: PTChatFileCell.ID, dataModel: value)
                case .CustomerMessage:
                    guard !value.customerCellId.stringIsEmpty() else { return nil }
                    return PTRows(ID: value.customerCellId, dataModel: value)
                }
            }
            let section = PTSection(rows: rows)
            sections.append(section)
            listCollection.showCollectionDetail(collectionData: sections,finishTask: loadFinish)
        }
    }
    
    fileprivate func resendMessage(cellModel:PTChatListModel,indexPath:IndexPath) {
        let timeStamp = Date().timeIntervalSince1970
        let currentModel = cellModel
        currentModel.messageStatus = .Sending
        currentModel.messageTimeStamp = timeStamp
        self.chatDataArr.remove(at: indexPath.row)
        self.chatDataArr.append(currentModel)
        self.viewReloadData { cView in
            self.listCollection.contentCollectionView.scrollToBottom()
            self.resendMessageHandler?(cellModel,indexPath)
        }
    }
}
