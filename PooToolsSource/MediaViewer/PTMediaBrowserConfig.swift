//
//  PTMediaBrowserConfig.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 25/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public typealias PTViewerSaveBlock = (_ finish:Bool) -> Void
public typealias PTViewerIndexBlock = (_ dataIndex:Int) -> Void
public typealias PTViewerEXIndexBlock = (_ dataIndex:Int,_ image:UIImage?) -> Void

@objc public enum PTViewerDataType:Int {
    case Normal
    case GIF
    case Video
    case FullView
    case ThreeD
    case LivePhoto
    case None
}

@objc public enum PTViewerActionType:Int {
    case All
    case Save
    case Delete
    case DIY
    case Empty
}

@objcMembers
public class PTMediaBrowserConfig: NSObject {
    public static let share = PTMediaBrowserConfig()
    ///内容的文字颜色
    public var titleColor:UIColor = UIColor.white
    ///标题字体
    public var titleFont:UIFont = UIFont.systemFont(ofSize: 24)
    ///内容字体
    public var viewerFont:UIFont = UIFont.systemFont(ofSize: 13)
    ///内容的容器背景颜色
    public var viewerContentBackgroundColor:UIColor = .clear
    ///操作方式
    public var actionType:PTViewerActionType = .All
    ///关闭页面按钮图片连接/名字
    public var closeViewerImage:UIImage = "❌".emojiToImage(emojiFont: .appfont(size: 20))
    ///更多操作按钮图片连接/名字
    public var moreActionImage:UIImage = "🗃️".emojiToImage(emojiFont: .appfont(size: 20))
    ///播放按钮
    public var playButtonImage:UIImage = "▶️".emojiToImage(emojiFont: .appfont(size: 44))
    public var playButtonImageSize:CGSize = .init(width: 44, height: 44)

    ///更多功能扩展,如果选择全部,则默认保存0删除1........
    public var moreActionEX:[String] = []
    ///iCloudDocumentName
    public var iCloudDocumentName:String = ""
    ///背景模糊
    public var dynamicBackground:Bool = false
    ///更多文字设置
    public var showMore:String = "...\("PT More".localized())"
    ///保存
    public var saveDesc:String = "PT Media save".localized()
    ///删除
    public var deleteDesc:String = "PT Media delete".localized()
    ///ActionSheet Title
    public var actionTitle:String = "PT Media option".localized()
    ///ActionSheet Cancel
    public var actionCancel:String = "PT Button cancel".localized()
    ///Image reload
    public var imageReloadButton:String = "PT Image load fail".localized()

    public var pageControlOption:PTMediaPageControlOption = .scrolling
    
    public var pageControlShow:Bool = false
    
    public var imageLongTapAction:Bool = true

    public enum PTMediaPageControlOption:Int {
        case system
        case fill
        case pill
        case snake
        case image
        case scrolling
    }
    
    @PTClampedPropertyWrapper(range: 50...200) public var dismissY:CGFloat = 200
}
