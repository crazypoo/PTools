//
//  PTTestChatViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/4/3.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import MapKit

class PTTestChatViewController: PTBaseViewController {

    fileprivate var pageNumber:Int = 0
    fileprivate var olderChatTimeSteam:String = ""

    lazy var chatContent:PTChatView = {
        let view = PTChatView()
        view.listBottomOffset = CGFloat.kTabbarSaveAreaHeight
        view.headerLoadReadyHandler = {
            self.testModel().enumerated().forEach { index,value in
                self.chatContent.chatDataArr.insert(value, at: 0)
            }
            self.chatContent.listCollection.endRefresh()
            self.chatContent.viewReloadData()
        }
        view.resendMessageHandler = { cellModel,indexPath in
            PTNSLogConsole("\(cellModel)\(indexPath)")
        }
//        view.listTapHandler = {
//            PTNSLogConsole("123123123123")
//        }
        view.cellMenuItemsHandler = { id in
            return ["1111","222222","3333333"]
        }
        view.cellMenuItemsTapCallBack = { indexPath,cellModel,itemName,itemIndex in
            PTNSLogConsole("\(indexPath),\(cellModel),\(itemName),\(itemIndex)")
        }
        view.attCellUrlTapCallBack = { text,indexPath,cellModel in
            PTNSLogConsole("\(text)")
        }
        view.attCellHashtagTapCallBack = { text,indexPath,cellModel in
            PTNSLogConsole("\(text)")
        }
        view.attCellMentionTapCallBack = { text,indexPath,cellModel in
            PTNSLogConsole("\(text)")
        }
        view.attCellChinaPhoneTapCallBack = { text,indexPath,cellModel in
            PTNSLogConsole("\(text)")
        }
        view.attCellCustomTapCallBack = { text,indexPath,cellModel in
            PTNSLogConsole("\(text)")
        }
        view.tapMessageHandler = { cellModel,indexPath in
            PTNSLogConsole("\(cellModel)\(indexPath)")
            switch cellModel.messageType {
            case .Media:
                let mediaModel = PTMediaBrowserModel()
                mediaModel.imageURL = cellModel.msgContent
                
                let mediaBroswer = PTMediaBrowserConfig()
                mediaBroswer.mediaData = [mediaModel]
                mediaBroswer.actionType = .Save
                mediaBroswer.dynamicBackground = true
                
                let vc = PTMediaBrowserController(viewConfig: mediaBroswer)
                vc.viewSaveImageBlock = { finish in
                    if finish {
                        PTAlertTipControl.present(title:"",subtitle: "ok",icon:.Done,style: .Normal)
                    } else {
                        PTAlertTipControl.present(title:"",subtitle: "error",icon:.Error,style: .Normal)
                    }
                }
                vc.viewDismissBlock = {
                    self.changeStatusBar(type: .Dark)
                }
                vc.modalPresentationStyle = .fullScreen
                self.navigationController?.present(vc, animated: true)
            default:
                break
            }
        }
        view.userIconTapHandler = { cellModel,indexPath in
            PTNSLogConsole("\(cellModel)\(indexPath)")
        }
        return view
    }()
    
    func testModel() ->[PTChatListModel] {
        let systemModel = PTChatListModel()
        systemModel.messageTimeStamp = 1711986851
        systemModel.messageType = .SystemMessage
        systemModel.msgContent = "1231231231231231312312"
        
        let meSendTextModel = PTChatListModel()
        meSendTextModel.messageTimeStamp = 1710947453
        meSendTextModel.messageType = .Text
        meSendTextModel.creatorId = "46709394"
        meSendTextModel.msgContent = "1231231231231231312312"
        meSendTextModel.senderCover = "https://tinhtinhimg.zxkjcn.cn/171143117700603E0FFC28AFB45B1BD21E0BA664E7C4C_image_0.png"
        meSendTextModel.senderName = "自己"
        meSendTextModel.messageStatus = .Error
        
        let othetSendTextModel = PTChatListModel()
        othetSendTextModel.messageTimeStamp = 1710947454
        othetSendTextModel.messageType = .Text
        othetSendTextModel.creatorId = "9999999999999"
        othetSendTextModel.msgContent = "1231231231231231312312"
        othetSendTextModel.senderCover = "https://tinhtinhimg.zxkjcn.cn/171143117700603E0FFC28AFB45B1BD21E0BA664E7C4C_image_0.png"
        othetSendTextModel.senderName = "Test"
        othetSendTextModel.messageStatus = .Arrived

        let othetSendTextErrorModel = PTChatListModel()
        othetSendTextErrorModel.messageTimeStamp = 1710947455
        othetSendTextErrorModel.messageType = .Text
        othetSendTextErrorModel.creatorId = "9999999999999"
        othetSendTextErrorModel.msgContent = "1231231231231231312312"
        othetSendTextErrorModel.senderCover = "https://tinhtinhimg.zxkjcn.cn/171143117700603E0FFC28AFB45B1BD21E0BA664E7C4C_image_0.png"
        othetSendTextErrorModel.senderName = "Test"
        othetSendTextErrorModel.messageStatus = .Sending
        
        let meSendImageModel = PTChatListModel()
        meSendImageModel.messageTimeStamp = 1710947456
        meSendImageModel.messageType = .Media
        meSendImageModel.creatorId = "46709394"
        meSendImageModel.msgContent = "https://tinhtinhimg.zxkjcn.cn/171143117700603E0FFC28AFB45B1BD21E0BA664E7C4C_image_0.png"
        meSendImageModel.senderCover = "https://tinhtinhimg.zxkjcn.cn/171143117700603E0FFC28AFB45B1BD21E0BA664E7C4C_image_0.png"
        meSendImageModel.senderName = "自己"
        meSendImageModel.messageStatus = .Sending

        let otherSendImageModel = PTChatListModel()
        otherSendImageModel.messageTimeStamp = 1710947456
        otherSendImageModel.messageType = .Media
        otherSendImageModel.creatorId = "9999999999999"
        otherSendImageModel.msgContent = "https://tinhtinhimg.zxkjcn.cn/171143117700603E0FFC28AFB45B1BD21E0BA664E7C4C_image_0.png"
        otherSendImageModel.senderCover = "https://tinhtinhimg.zxkjcn.cn/171143117700603E0FFC28AFB45B1BD21E0BA664E7C4C_image_0.png"
        otherSendImageModel.senderName = "Test"
        otherSendImageModel.messageStatus = .Sending

        let meSendMapModel = PTChatListModel()
        meSendMapModel.messageTimeStamp = 1710947457
        meSendMapModel.messageType = .Map
        meSendMapModel.creatorId = "46709394"
        meSendMapModel.msgContent = "{\"lng\":\"112.77437690645458\",\"lat\":\"22.67277058992048\"}"
        meSendMapModel.senderCover = "https://tinhtinhimg.zxkjcn.cn/171143117700603E0FFC28AFB45B1BD21E0BA664E7C4C_image_0.png"
        meSendMapModel.senderName = "自己"
        meSendMapModel.messageStatus = .Error
        
        let meSendAppleMapModel = PTChatListModel()
        meSendAppleMapModel.messageTimeStamp = 1710947457
        meSendAppleMapModel.messageType = .Map
        meSendAppleMapModel.creatorId = "46709394"
        meSendAppleMapModel.msgContent = "{\"lng\":\"112.77437690645458\",\"lat\":\"22.67277058992048\"}"
        meSendAppleMapModel.senderCover = "https://tinhtinhimg.zxkjcn.cn/171143117700603E0FFC28AFB45B1BD21E0BA664E7C4C_image_0.png"
        meSendAppleMapModel.senderName = "自己"
        meSendAppleMapModel.messageStatus = .Error

        let meSendVoiceModel = PTChatListModel()
        meSendVoiceModel.messageTimeStamp = 1711986851
        meSendVoiceModel.messageType = .Voice
        meSendVoiceModel.creatorId = "46709394"
        meSendVoiceModel.msgContent = Bundle.main.url(forResource: "sound1", withExtension: "m4a")!
        meSendVoiceModel.senderCover = "https://tinhtinhimg.zxkjcn.cn/171143117700603E0FFC28AFB45B1BD21E0BA664E7C4C_image_0.png"
        meSendVoiceModel.senderName = "自己"
        meSendVoiceModel.messageStatus = .Sending
        
        let meSendVideoModel = PTChatListModel()
        meSendVideoModel.messageTimeStamp = 1711986851
        meSendVideoModel.messageType = .Media
        meSendVideoModel.creatorId = "46709394"
        meSendVideoModel.msgContent = "https://stream7.iqilu.com/10339/upload_transcode/202002/18/20200218114723HDu3hhxqIT.mp4"
        meSendVideoModel.senderCover = "https://tinhtinhimg.zxkjcn.cn/171143117700603E0FFC28AFB45B1BD21E0BA664E7C4C_image_0.png"
        meSendVideoModel.senderName = "自己"
        meSendVideoModel.messageStatus = .Arrived
    
        let meSendFileModel = PTChatListModel()
        meSendFileModel.messageTimeStamp = 1711986851
        meSendFileModel.messageType = .File
        meSendFileModel.creatorId = "46709394"
        meSendFileModel.msgContent = "https://stream7.iqilu.com/10339/upload_transcode/202002/18/20200218114723HDu3hhxqIT.mp4"
        meSendFileModel.senderCover = "https://tinhtinhimg.zxkjcn.cn/171143117700603E0FFC28AFB45B1BD21E0BA664E7C4C_image_0.png"
        meSendFileModel.senderName = "自己"
        meSendFileModel.messageStatus = .Arrived
        
        let meSendAttModel = PTChatListModel()
        meSendAttModel.messageTimeStamp = 1711986851
        meSendAttModel.messageType = .Text
        meSendAttModel.creatorId = "46709394"
        meSendAttModel.msgContent = "13800138000 http://www.qq.com #QQQQQQQQQQQQQ"
        meSendAttModel.senderCover = "https://tinhtinhimg.zxkjcn.cn/171143117700603E0FFC28AFB45B1BD21E0BA664E7C4C_image_0.png"
        meSendAttModel.senderName = "自己"
        meSendAttModel.messageStatus = .Arrived

        let customAttTag = PTChatListModel()
        customAttTag.messageTimeStamp = 1711986852
        customAttTag.messageType = .Text
        customAttTag.creatorId = "46709394"
        customAttTag.msgContent = "标签 aaaaaaaaaB 支持 克狗扑"
        customAttTag.senderCover = "https://tinhtinhimg.zxkjcn.cn/171143117700603E0FFC28AFB45B1BD21E0BA664E7C4C_image_0.png"
        customAttTag.senderName = "自己"
        customAttTag.messageStatus = .Arrived

        let typingModel = PTChatListModel()
        typingModel.messageType = .Typing
        return [systemModel,meSendTextModel,othetSendTextModel,othetSendTextErrorModel,meSendImageModel,otherSendImageModel,meSendMapModel,meSendAppleMapModel,meSendVoiceModel,meSendVideoModel,meSendFileModel,meSendAttModel,customAttTag,typingModel]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let customerTag = PTMessageTextCustomAttTagModel()
        customerTag.tag = "\\标签\\b"
        
        PTChatConfig.share.customerTagModels = [customerTag]
        PTChatConfig.share.imOwnerId = "46709394"
        PTChatConfig.share.span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)

        view.addSubviews([chatContent])
        chatContent.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
        }
        
        chatContent.chatDataArr = testModel()
        chatContent.viewReloadData { cView in
            PTGCDManager.gcdAfter(time: 0.35) {
                cView.scrollToBottom(animated: true)
            }
        }
        
        PTGCDManager.gcdAfter(time: 5) {
            self.chatContent.chatDataArr.removeAll(where: { $0.messageType == .Typing })
            self.chatContent.viewReloadData()
        }
    }
}
