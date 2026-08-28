//
//  PTChatListModel.swift
//  LiXinCEO
//
//  Created by 邓杰豪 on 2024/3/31.
//

import UIKit
import SmartCodable

public enum PTChatMessageType:Int,SmartCaseDefaultable {
    case Text
    case Map
    case Media
    case Voice
    case File
    case SystemMessage
    case CustomerMessage
    case Typing
}

public enum PTChatMessageStatus:Int,SmartCaseDefaultable {
    case Sending
    case Arrived
    case Error
}

@MainActor
// SmartCodable's requirements are nonisolated in the legacy decoder; this UI model is only decoded and consumed on MainActor.
// Los requisitos de SmartCodable no están aislados en el decodificador heredado; este modelo de UI solo se decodifica y consume en MainActor.
// SmartCodable 的协议要求在旧解码器中是非隔离的；这个 UI 模型只在 MainActor 上解码和使用。
open class PTChatListModel: @preconcurrency PTCodableModelProtocol {
    ///消息时间戳
    public var messageTimeStamp:TimeInterval = 0
    ///消息ID
    public var msgId:String = ""
    public var messageType:PTChatMessageType = .Text
    ///创建者ID
    public var creatorId:String = ""
    ///内容
    @SmartAny public var msgContent:Any?
    ///消息人头像
    public var senderCover:String = ""
    ///消息状态
    public var messageStatus:PTChatMessageStatus = .Arrived
    ///发送者名字
    public var senderName:String = ""
    ///是否属于我
    public var belongToMe: Bool {
        return creatorId == PTChatConfig.share.imOwnerId
    }

    //MARK: 这个是需要自定义cell时用
    ///自定义CELL的ID
    public var customerCellId:String = ""
    ///是否已讀
    public var isRead:Bool = false
    ///额外扩展字段
    @SmartAny public var msgExten:Any?
    
    public required init() {}
}
