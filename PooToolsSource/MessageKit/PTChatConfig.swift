//
//  PTChatConfig.swift
//  PooTools
//
//  Created by 邓杰豪 on 2024/3/31.
//

import UIKit
import MapKit
import SafeSFSymbols
import SwiftDate

public extension UIImage {
    @objc func resizeImage() -> UIImage {
        let w = self.size.width * 0.7
        let h = self.size.height * 0.7
        return self.resizableImage(withCapInsets: UIEdgeInsets(top: h, left: w, bottom: h, right: w))
    }
}

public class PTMessageTextCustomAttTagModel:PTBaseModel {
    ///Example: \\xxxxx\\b
    public var tag:String = ""
    public var tagColor:DynamicColor = .systemGray
    public var tagSelectedColor:DynamicColor = .systemGray
}

@objcMembers
public class PTChatConfig: NSObject {
    public static let share = PTChatConfig()
    
    //MARK: Base setting
    ///文本內容實際顯示最大的Width
    public static let ChatContentShowMaxWidth = CGFloat.kSCREEN_WIDTH - PTChatConfig.share.messageUserIconSize - PTChatConfig.share.userIconFixelSpace - PTChatBaseCell.dataContentWaitImageInset - PTChatBaseCell.waitImageRightInset - PTChatBaseCell.waitImageSize - PTChatBaseCell.dataContentUserIconInset
    ///設置持有人ID
    public var imOwnerId:String = ""
    @PTClampedProperyWrapper(range:10...120) public var messageExpTime: Int = 60

    class public func timeExp(expTime:Date) -> Bool {
        
        let newExpTime = expTime + PTChatConfig.share.messageExpTime.seconds
        let current = Date()
        if current >= newExpTime {
            return true
        } else {
            return false
        }
    }
    
    /// 顶部偏移
    public var chatTopFixel:CGFloat = 0
    /// 底部偏移
    public var chatBottomFixel:CGFloat = 0
    //MARK: System message
    ///系統時間字體大小
    public var chatTimeFont:UIFont = .appfont(size: 13)
    ///系統時間字體顏色
    public var chatTimeColor:UIColor = UIColor(hexString: "919191")!
    ///系統时间的左右间距
    @PTClampedProperyWrapper(range:5...20) public var chatTimeContentFixel:CGFloat = 5
    ///系統時間背景颜色
    public var chatTimeBackgroundColor:UIColor = UIColor(hexString: "cacaca")!
    ///系統內容字體大小
    public var chatSystemMessageFont:UIFont = .appfont(size: 13)
    ///系統內容字體顏色
    public var chatSystemMessageColor:UIColor = UIColor(hexString: "919191")!
    ///系統時間文字間隔
    public var chatSystemTimeLineSpace:NSNumber = 2
    ///系統內容文字間隔
    public var chatSystemContentLineSpace:NSNumber = 2


    //MARK: Message base
    ///消息頭像大小
    @PTClampedProperyWrapper(range:44...88) open var messageUserIconSize: CGFloat = 44
    ///是否顯示時間
    public var showTimeLabel:Bool = true
    ///是否顯示用戶名
    public var showSenderName:Bool = true
    ///用戶名字字體
    public var senderNameFont:UIFont = .appfont(size: 13)
    ///用戶名字顏色
    public var senderNameColor:UIColor = UIColor(hexString: "919191")!
    public var senderNameBackgroundColor:UIColor = .clear
    public var receiverNameColor:UIColor = UIColor(hexString: "919191")!
    public var receiverNameBackgroundColor:UIColor = .clear
    public var userIconTopSpacing:CGFloat = 0
    ///頭像到邊的距離
    public var userIconFixelSpace:CGFloat = 10
    ///自己消息的聊天氣泡
    public var chatMeBubbleImage:UIImage = UIColor.white.createImageWithColor().transformImage(size: CGSize(width: 55, height: 55))
    ///自己消息的聊天Hightlight氣泡
    public var chatMeHighlightedBubbleImage:UIImage = UIColor.white.lighter(amount: 0.8).createImageWithColor().transformImage(size: CGSize(width: 55, height: 55))
    ///別人消息的聊天氣泡
    public var chatOtherBubbleImage:UIImage = UIColor.systemBlue.createImageWithColor().transformImage(size: CGSize(width: 55, height: 55))
    ///別人消息的聊天Hightlight氣泡
    public var chatOtherHighlightedBubbleImage:UIImage = UIColor.systemBlue.lighter(amount: 0.8).createImageWithColor().transformImage(size: CGSize(width: 55, height: 55))
    ///等待消息的圖片
    public var chatWaitImage:UIImage = "📀".emojiToImage(emojiFont: .appfont(size: 20))
    ///異常消息的圖片
    public var chatWaitErrorImage:UIImage = "‼️".emojiToImage(emojiFont: .appfont(size: 20))
    ///已讀未讀開關
    public var showReadStatus:Bool = true
    ///已讀未讀字體
    public var readStatusFont:UIFont = .appfont(size: 13)
    ///已讀未讀顏色
    public var readStatusColor:UIColor = UIColor(hexString: "919191")!
    public var readStatusName:String = "Read"
    public var unreadStatusName:String = "unread"
    ///时间到顶的距离,默认5最大100
    @PTClampedProperyWrapper(range:5...100) open var timeTopSpace: CGFloat = 5

    //MARK: Text message
    ///自己文本顏色
    public var textMeMessageColor:UIColor = .black
    ///自己文本字體
    public var textMeMessageFont:UIFont = .appfont(size: 15)
    ///別人文本顏色
    public var textOtherMessageColor:UIColor = .black
    ///別人文本字體
    public var textOtherMessageFont:UIFont = .appfont(size: 15)
    ///自己文本偏移設置
    public var textOwnerContentEdges:UIEdgeInsets = UIEdgeInsets(top: 20, left: 10, bottom: 20, right: 15)
    ///別人文本偏移設置
    public var textOtherContentEdges:UIEdgeInsets = UIEdgeInsets(top: 20, left: 15, bottom: 20, right: 15)
    ///文本字體間隔
    public var textLineSpace:CGFloat = 2
    ///設置聊天內容框最小Height
    @PTClampedProperyWrapper(range:38...88) public var contentBaseHeight: CGFloat = 38
    ///#井号话题颜色
    public var hashtagColor:DynamicColor = .systemBlue
    public var hashtagSelectedColor:DynamicColor = .systemBlue
    ///China phone颜色
    public var chinaCellPhoneColor:DynamicColor = .BurntOrangeColor
    public var chinaCellPhoneSelectedColor:DynamicColor = .BurntOrangeColor
    ///URL颜色
    public var urlColor:DynamicColor = .SteelBlueColor
    public var urlSelectedColor:DynamicColor = .SteelBlueColor
    ///@颜色
    public var mentionColor:DynamicColor = .systemRed
    public var mentionSelectedColor:DynamicColor = .systemRed
    ///自定义标签文字内容
    public var customerTagModels:[PTMessageTextCustomAttTagModel] = []
    
    //MARK: Media message
    ///Media的Width大小
    @PTClampedProperyWrapper(range:88...200) public var imageMessageImageWidth: CGFloat = 200
    ///Media的Height大小
    @PTClampedProperyWrapper(range:88...200) public var imageMessageImageHeight: CGFloat = 200
    ///Media的Coner大小
    @PTClampedProperyWrapper(range:0...100) public var imageMessageImageCorner: CGFloat = 5
    ///Media的Width大小
    @PTClampedProperyWrapper(range:88...200) public var mediaMessageVideoWidth: CGFloat = 200
    ///Media的Height大小
    @PTClampedProperyWrapper(range:88...200) public var mediaMessageVideoHeight: CGFloat = 200
    public var mediaPlayButton:UIImage = "▶️".emojiToImage(emojiFont: .appfont(size: 40))
    public var mediaPlayButtonSize:CGSize = .init(width: 34, height: 34)

    //MARK: Map message
    ///地圖Width大小
    @PTClampedProperyWrapper(range:88...200) public var mapMessageImageWidth: CGFloat = 200
    ///地圖Height大小
    @PTClampedProperyWrapper(range:88...200) public var mapMessageImageHeight: CGFloat = 200
    ///地圖Coner大小
    @PTClampedProperyWrapper(range:0...100) public var mapMessageImageCorner: CGFloat = 5
    ///是否顯示建築
    public var showBuilding:Bool = true
    ///地圖的圖片縮放
    public var span:MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0)
    ///是否顯示POI
    public var showsPointsOfInterest: Bool = false
    ///地圖Pin
    public var mapCellPinImage:UIImage = "🧭".emojiToImage(emojiFont: .appfont(size: 40))
    
    //MARK: Voice message
    ///音頻Width大小
    @PTClampedProperyWrapper(range:150...250) public var audioMessageImageWidth: CGFloat = 250
    ///播放按鈕
    public var playButtonImage:UIImage = UIImage(.play).withTintColor(.systemBlue)
    ///暫停按鈕
    public var pauseButtonImage:UIImage = UIImage(.pause).withTintColor(.systemBlue)
    ///時間字體
    public var durationFont:UIFont = .appfont(size: 14)
    ///時間字體顏色
    public var durationColor:UIColor = .systemBlue
    ///Progress顏色
    public var progressColor:UIColor = .systemBlue
    
    //MARK: Typing message
    public var dotColor:UIColor = .lightGray
    
    //MARK: File message
    public var fileNameFont:UIFont = .appfont(size: 18,bold: true)
    public var fileNameColor:UIColor = .black
    public var fileSizeFont:UIFont = .appfont(size: 13)
    public var fileSizeColor:UIColor = .lightGray
    @PTClampedProperyWrapper(range:0...15) public var fileContentSpace: CGFloat = 2
    public var fileImage:UIImage = "📁".emojiToImage(emojiFont: .appfont(size: 40))
}
