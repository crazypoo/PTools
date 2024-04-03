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
    @objc func resizeImage() ->UIImage {
        let w = self.size.width * 0.7
        let h = self.size.height * 0.7
        return self.resizableImage(withCapInsets: UIEdgeInsets(top: h, left: w, bottom: h, right: w))
    }
}

@objcMembers
public class PTChatConfig: NSObject {
    public static let share = PTChatConfig()
    
    //MARK: Base setting
    ///文本內容實際顯示最大的Width
    public static let ChatContentShowMaxWidth = CGFloat.kSCREEN_WIDTH - PTChatConfig.share.messageUserIconSize - PTChatConfig.share.userIconFixelSpace - PTChatBaseCell.DataContentWaitImageFixel - PTChatBaseCell.WaitImageRightFixel - PTChatBaseCell.WaitImageSize - PTChatBaseCell.DataContentUserIconFixel
    ///設置持有人ID
    open var imOwnerId:String = ""
    @PTClampedProperyWrapper(range:10...120) public var messageExpTime: Int = 60

    class public func timeExp(expTime:Date) ->Bool {
        
        let newExpTime = expTime + PTChatConfig.share.messageExpTime.seconds
        let current = Date()
        if current >= newExpTime {
            return true
        } else {
            return false
        }
    }
    
    //MARK: System message
    ///系統時間字體大小
    open var chatTimeFont:UIFont = .appfont(size: 13)
    ///系統時間字體顏色
    open var chatTimeColor:UIColor = UIColor(hexString: "919191")!
    ///系統內容字體大小
    open var chatSystemMessageFont:UIFont = .appfont(size: 13)
    ///系統內容字體顏色
    open var chatSystemMessageColor:UIColor = UIColor(hexString: "919191")!
    ///系統時間文字間隔
    open var chatSystemTimeLineSpace:NSNumber = 2
    ///系統內容文字間隔
    open var chatSystemContentLineSpace:NSNumber = 2

    //MARK: Message base
    ///消息頭像大小
    @PTClampedProperyWrapper(range:44...88) open var messageUserIconSize: CGFloat = 44
    ///是否顯示時間
    open var showTimeLabel:Bool = true
    ///是否顯示用戶名
    open var showSenderName:Bool = true
    ///用戶名字字體
    open var senderNameFont:UIFont = .appfont(size: 13)
    ///用戶名字顏色
    open var senderNameColor:UIColor = UIColor(hexString: "919191")!
    ///頭像到邊的距離
    open var userIconFixelSpace:CGFloat = 10
    ///自己消息的聊天氣泡
    open var chatMeBubbleImage:UIImage = UIColor.white.createImageWithColor().transformImage(size: CGSize(width: 55, height: 55))
    ///自己消息的聊天Hightlight氣泡
    open var chatMeHighlightedBubbleImage:UIImage = UIColor.white.lighter(amount: 0.8).createImageWithColor().transformImage(size: CGSize(width: 55, height: 55))
    ///別人消息的聊天氣泡
    open var chatOtherBubbleImage:UIImage = UIColor.systemBlue.createImageWithColor().transformImage(size: CGSize(width: 55, height: 55))
    ///別人消息的聊天Hightlight氣泡
    open var chatOtherHighlightedBubbleImage:UIImage = UIColor.systemBlue.lighter(amount: 0.8).createImageWithColor().transformImage(size: CGSize(width: 55, height: 55))
    ///等待消息的圖片
    open var chatWaitImage:UIImage = "📀".emojiToImage(emojiFont: .appfont(size: 20))
    ///異常消息的圖片
    open var chatWaitErrorImage:UIImage = "‼️".emojiToImage(emojiFont: .appfont(size: 20))
    ///已讀未讀開關
    open var showReadStatus:Bool = true
    ///已讀未讀字體
    open var readStatusFont:UIFont = .appfont(size: 13)
    ///已讀未讀顏色
    open var readStatusColor:UIColor = UIColor(hexString: "919191")!
    open var readStatusName:String = "Read"
    open var unreadStatusName:String = "unread"

    //MARK: Text message
    ///自己文本顏色
    open var textMeMessageColor:UIColor = .black
    ///自己文本字體
    open var textMeMessageFont:UIFont = .appfont(size: 15)
    ///別人文本顏色
    open var textOtherMessageColor:UIColor = .black
    ///別人文本字體
    open var textOtherMessageFont:UIFont = .appfont(size: 15)
    ///自己文本偏移設置
    open var textOwnerContentEdges:UIEdgeInsets = UIEdgeInsets(top: 20, left: 10, bottom: 20, right: 15)
    ///別人文本偏移設置
    open var textOtherContentEdges:UIEdgeInsets = UIEdgeInsets(top: 20, left: 15, bottom: 20, right: 15)
    ///文本字體間隔
    open var textLineSpace:NSNumber = 2
    ///設置聊天內容框最小Height
    @PTClampedProperyWrapper(range:38...88) open var contentBaseHeight: CGFloat = 38

    //MARK: Media message
    ///Media的Width大小
    @PTClampedProperyWrapper(range:88...200) open var imageMessageImageWidth: CGFloat = 200
    ///Media的Height大小
    @PTClampedProperyWrapper(range:88...200) open var imageMessageImageHeight: CGFloat = 200
    ///Media的Coner大小
    @PTClampedProperyWrapper(range:0...100) open var imageMessageImageCorner: CGFloat = 5
    open var mediaPlayButton:UIImage = "▶️".emojiToImage(emojiFont: .appfont(size: 40))
    
    //MARK: Map message
    ///地圖Width大小
    @PTClampedProperyWrapper(range:88...200) open var mapMessageImageWidth: CGFloat = 200
    ///地圖Height大小
    @PTClampedProperyWrapper(range:88...200) open var mapMessageImageHeight: CGFloat = 200
    ///地圖Coner大小
    @PTClampedProperyWrapper(range:0...100) open var mapMessageImageCorner: CGFloat = 5
    ///是否顯示建築
    open var showBuilding:Bool = true
    ///地圖的圖片縮放
    open var span:MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0)
    ///是否顯示POI
    open var showsPointsOfInterest: Bool = false
    ///地圖Pin
    open var mapCellPinImage:UIImage = "🧭".emojiToImage(emojiFont: .appfont(size: 40))
    
    //MARK: Voice message
    ///音頻Width大小
    @PTClampedProperyWrapper(range:150...250) open var audioMessageImageWidth: CGFloat = 250
    ///播放按鈕
    open var playButtonImage:UIImage = UIImage(.play).withTintColor(.systemBlue)
    ///暫停按鈕
    open var pauseButtonImage:UIImage = UIImage(.pause).withTintColor(.systemBlue)
    ///時間字體
    open var durationFont:UIFont = .appfont(size: 14)
    ///時間字體顏色
    open var durationColor:UIColor = .systemBlue
    ///Progress顏色
    open var progressColor:UIColor = .systemBlue
    
    //MARK: Typing message
    open var dotColor:UIColor = .lightGray
    
    //MARK: File message
    open var fileNameFont:UIFont = .appfont(size: 18,bold: true)
    open var fileNameColor:UIColor = .black
    open var fileSizeFont:UIFont = .appfont(size: 13)
    open var fileSizeColor:UIColor = .lightGray
    @PTClampedProperyWrapper(range:0...15) open var fileContentSpace: CGFloat = 2
    open var fileImage:UIImage = "📁".emojiToImage(emojiFont: .appfont(size: 40))
}
