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

@objcMembers
public class PTChatView: UIView {

    ///消息数组
    public var chatDataArr:[PTChatListModel] = [PTChatListModel]()
    ///重新发送消息回调
    public var resendMessageHandler:PTChatHandler? = nil
    ///头部刷新回调
    public var headerLoadReadyHandler:PTActionTask? = nil
    ///点击空地方回调
    public var listTapHandler:PTActionTask? = nil
    ///消息点击回调
    public var tapMessageHandler:PTChatHandler? = nil
    ///头像点击回调
    public var userIconTapHandler:PTChatHandler? = nil
    //MARK: 自定义消息下使用
    ///自定义Cell设置
    public var customerCellHandler:PTChatCellHandler? = nil
    ///自定义Cell高度设置
    public var customerCellHeightHandler:PTChatCustomerCellHeightHandler? = nil
    
    ///消息列表
    public lazy var listCollection:PTCollectionView = {
        let collectionConfig = PTCollectionViewConfig()
        collectionConfig.viewType = .Custom
        collectionConfig.refreshWithoutAnimation = true
        collectionConfig.topRefresh = true

        let view = PTCollectionView(viewConfig: collectionConfig)
        view.customerLayout = { sectionModel in
            var groupHeight:CGFloat = 0
            var bannerGroupSize : NSCollectionLayoutSize
            var customers = [NSCollectionLayoutGroupCustomItem]()
            sectionModel.rows.enumerated().forEach { (index,model) in
                let cellModel = model.dataModel as! PTChatListModel
                var cellHeight:CGFloat = 0
                switch cellModel.messageType {
                case .Text:
                    let msgContent = cellModel.msgContent as! String
                    
                    var dataContentFont:UIFont!
                    if cellModel.belongToMe {
                        dataContentFont = PTChatConfig.share.textMeMessageFont
                    } else {
                        dataContentFont = PTChatConfig.share.textOtherMessageFont
                    }
                    
                    var contentHeight = UIView.sizeFor(string: msgContent, font: dataContentFont,lineSpacing: 2,width: PTChatConfig.ChatContentShowMaxWidth).height
                    
                    if contentHeight < PTChatConfig.share.contentBaseHeight {
                        contentHeight = PTChatConfig.share.contentBaseHeight
                    }
                    
                    let timeHeight = (PTChatConfig.share.showTimeLabel ? PTChatBaseCell.TimeHeight : 0)
                    let nameHeight = (PTChatConfig.share.showSenderName ? PTChatBaseCell.NameHeight : 0)
                    var nameContentTotal = nameHeight + contentHeight
                    if nameContentTotal < PTChatConfig.share.messageUserIconSize {
                        nameContentTotal = PTChatConfig.share.messageUserIconSize
                    }
                    
                    cellHeight = nameContentTotal + timeHeight + PTChatBaseCell.TimeTopSpace * 3
                case .Map:
                    let timeHeight = (PTChatConfig.share.showTimeLabel ? PTChatBaseCell.TimeHeight : 0)
                    let nameHeight = (PTChatConfig.share.showSenderName ? PTChatBaseCell.NameHeight : 0)
                    let mapHeight = PTChatConfig.share.mapMessageImageHeight
                    cellHeight = timeHeight + nameHeight + mapHeight + PTChatBaseCell.TimeTopSpace * 3
                case .Media:
                    let timeHeight = (PTChatConfig.share.showTimeLabel ? PTChatBaseCell.TimeHeight : 0)
                    let nameHeight = (PTChatConfig.share.showSenderName ? PTChatBaseCell.NameHeight : 0)
                    let imageHeight = PTChatConfig.share.imageMessageImageHeight
                    cellHeight = timeHeight + nameHeight + imageHeight + PTChatBaseCell.TimeTopSpace * 3
                case .Voice:
                    let timeHeight = (PTChatConfig.share.showTimeLabel ? PTChatBaseCell.TimeHeight : 0)
                    let nameHeight = (PTChatConfig.share.showSenderName ? PTChatBaseCell.NameHeight : 0)
                    let voiceHeight:CGFloat = 38
                    cellHeight = timeHeight + nameHeight + voiceHeight + PTChatBaseCell.TimeTopSpace * 3
                case .File:
                    let timeHeight = (PTChatConfig.share.showTimeLabel ? PTChatBaseCell.TimeHeight : 0)
                    let nameHeight = (PTChatConfig.share.showSenderName ? PTChatBaseCell.NameHeight : 0)
                    
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
                    cellHeight = timeHeight + contentHeight + nameHeight + PTChatBaseCell.TimeTopSpace * 3
                case .SystemMessage:
                    let timeHeight = UIView.sizeFor(string: cellModel.messageTimeStamp.timeToDate().toFormat("yyyy-MM-dd HH:MM:ss"), font: PTChatConfig.share.chatTimeFont,lineSpacing: 2,width: CGFloat.kSCREEN_WIDTH).height
                    var contentHeight:CGFloat = 0
                    if cellModel.msgContent is String {
                        contentHeight = UIView.sizeFor(string: cellModel.msgContent as! String, font: PTChatConfig.share.chatSystemMessageFont,lineSpacing: 2,width: CGFloat.kSCREEN_WIDTH).height
                    }
                    let total = timeHeight + contentHeight
                    if total >= PTChatConfig.share.contentBaseHeight {
                        cellHeight = total
                    } else {
                        cellHeight = PTChatConfig.share.contentBaseHeight
                    }
                case .Typing:
                    cellHeight = 44
                case .CustomerMessage:
                    cellHeight = self.customerCellHeightHandler?(cellModel,index) ?? 0
                }
                let customItem = NSCollectionLayoutGroupCustomItem.init(frame: CGRect.init(x: 0, y: groupHeight, width: CGFloat.kSCREEN_WIDTH, height: cellHeight), zIndex: 1000+index)
                customers.append(customItem)
                groupHeight += (cellHeight)
            }
            bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(CGFloat.kSCREEN_WIDTH), heightDimension: NSCollectionLayoutDimension.absolute(groupHeight))
            return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
                customers
            })
        }
        view.cellInCollection = { collectionView,sectionModel,indexPath in
            let itemRow = sectionModel.rows[indexPath.row]
            let cellModel = itemRow.dataModel as! PTChatListModel
            if itemRow.ID == PTChatSystemMessageCell.ID {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTChatSystemMessageCell
                cell.cellModel = cellModel
                return cell
            } else if itemRow.ID == PTChatTypingIndicatorCell.ID {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTChatTypingIndicatorCell
                return cell
            } else {
                switch cellModel.messageType {
                case .CustomerMessage:
                    return self.customerCellHandler?(collectionView,sectionModel,indexPath)
                default:
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTChatBaseCell
                    if itemRow.ID == PTChatTextCell.ID {
                        (cell as! PTChatTextCell).cellModel = cellModel
                    } else if itemRow.ID == PTChatMediaCell.ID {
                        (cell as! PTChatMediaCell).cellModel = cellModel
                    } else if itemRow.ID == PTChatMapCell.ID {
                        (cell as! PTChatMapCell).cellModel = cellModel
                    } else if itemRow.ID == PTChatVoiceCell.ID {
                        (cell as! PTChatVoiceCell).cellModel = cellModel
                    } else if itemRow.ID == PTChatFileCell.ID {
                        (cell as! PTChatFileCell).cellModel = cellModel
                    }
                    cell!.sendMesageError = { errorModel in
                        self.resendMessage(cellModel: errorModel, indexPath: indexPath)
                    }
                    cell!.dataContent.addActionHandlers { sender in
                        self.tapMessageHandler?(cellModel,indexPath)
                    }
                    cell!.sendExp = { expModel in
                        self.chatDataArr[indexPath.row].messageStatus = .Error
                        if itemRow.ID == PTChatTextCell.ID {
                            (cell as! PTChatTextCell).cellModel = self.chatDataArr[indexPath.row]
                        } else if itemRow.ID == PTChatMediaCell.ID {
                            (cell as! PTChatMediaCell).cellModel = self.chatDataArr[indexPath.row]
                        } else if itemRow.ID == PTChatMapCell.ID {
                            (cell as! PTChatMapCell).cellModel = self.chatDataArr[indexPath.row]
                        } else if itemRow.ID == PTChatVoiceCell.ID {
                            (cell as! PTChatVoiceCell).cellModel = self.chatDataArr[indexPath.row]
                        } else if itemRow.ID == PTChatFileCell.ID {
                            (cell as! PTChatFileCell).cellModel = self.chatDataArr[indexPath.row]
                        }
                    }
                    cell!.userIcon.addActionHandlers { sender in
                        self.userIconTapHandler?(cellModel,indexPath)
                    }
                    return cell
                }
            }
        }
        view.headerRefreshTask = { control in
            self.headerLoadReadyHandler?()
        }
        let tap = UITapGestureRecognizer { sender in
            self.listTapHandler?()
        }
        view.addGestureRecognizer(tap)
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
    
    ///刷新数据
    public func viewReloadData(loadFinish:((UICollectionView)->Void)? = nil) {
        var sections = [PTSection]()
        if chatDataArr.count > 0 {
            var rows = [PTRows]()
            chatDataArr.enumerated().forEach { index,value in
                switch value.messageType {
                case .SystemMessage:
                    let row = PTRows(cls: PTChatSystemMessageCell.self,ID: PTChatSystemMessageCell.ID,dataModel: value)
                    rows.append(row)
                case .Text:
                    let row = PTRows(cls: PTChatTextCell.self,ID: PTChatTextCell.ID,dataModel: value)
                    rows.append(row)
                case .Media:
                    let row = PTRows(cls: PTChatMediaCell.self,ID: PTChatMediaCell.ID,dataModel: value)
                    rows.append(row)
                case .Map:
                    let row = PTRows(cls: PTChatMapCell.self,ID: PTChatMapCell.ID,dataModel: value)
                    rows.append(row)
                case .Voice:
                    let row = PTRows(cls: PTChatVoiceCell.self,ID: PTChatVoiceCell.ID,dataModel: value)
                    rows.append(row)
                case .Typing:
                    let row = PTRows(cls: PTChatTypingIndicatorCell.self,ID: PTChatTypingIndicatorCell.ID,dataModel: value)
                    rows.append(row)
                case .File:
                    let row = PTRows(cls: PTChatFileCell.self,ID: PTChatFileCell.ID,dataModel: value)
                    rows.append(row)
                case .CustomerMessage:
                    if value.customerCellClass != nil && !value.customerCellId.stringIsEmpty() {
                        let row = PTRows(cls: value.customerCellClass.self,ID: value.customerCellId,dataModel: value)
                        rows.append(row)
                    }
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
