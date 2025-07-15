//
//  PTFunctionCellModel.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import AttributedString

@objc public enum PTFusionShowAccessoryType:Int {
    case Switch
    case DisclosureIndicator
    case More
    case NoneAccessoryView
}

@objc public enum PTFusionLineType:Int {
    case Normal
    case Imaginary
    case NO
}

@objcMembers
open class PTFusionCellModel: NSObject {
    ///图片名
    public var leftImage:Any?
    ///图片上下间隔默认CGFloat.ScaleW(w: 5)
    public var imageTopOffset:CGFloat = 5
    public var imageBottomOffset:CGFloat = 5
    public var labelLineSpace:CGFloat = 2
    ///icon是否圆形
    public var iconRound:Bool = false
    ///名
    public var name:String = ""
    ///名字颜色
    public var nameColor:UIColor = PTAppBaseConfig.share.viewDefaultTextColor
    ///主标题下的描述
    public var desc:String = ""
    ///主标题下文字颜色
    public var descColor:UIColor = UIColor.lightGray
    ///主标题的富文本
    public var nameAttr:ASAttributedString?
    ///描述
    public var content:String = ""
    ///描述文字颜色
    public var contentTextColor:UIColor = PTAppBaseConfig.share.viewDefaultTextColor
    ///Content的富文本
    public var contentAttr:ASAttributedString?
    ///content字体
    public var contentFont:UIFont = .appfont(size: 16)
    ///content行數
    public var contentNumberOfLines:Int = 0
    ///content換行
    public var contentLineBreakMode:NSLineBreakMode = .byCharWrapping
    ///AccessoryView类型
    public var accessoryType:PTFusionShowAccessoryType = .NoneAccessoryView
    ///是否有线
    public var haveLine:PTFusionLineType = .NO
    ///顶部线
    public var haveTopLine:PTFusionLineType = .NO
    ///字体
    public var cellFont:UIFont = .appfont(size: 16)
    ///Desc字体
    public var cellDescFont:UIFont = .appfont(size: 14)
    ///ID
    public var cellID:String? = ""
    ///ClassName
    public var cellClass: AnyClass? = nil
    
    ///是否已经选择了
    public var cellSelect:Bool? = false
    ///当前选择的Indexpath
    public var cellIndexPath:IndexPath?
    ///Cell的AccessViewImage
    public var disclosureIndicatorImage :Any?
    ///Cell的圓角處理
    public var conrner:UIRectCorner = []
    ///Cell的是否顯示Icon
    public var contentIcon:Any?
    ///Cell的右間隔
    public var rightSpace:CGFloat = 10
    ///右內容的間距
    public var contentRightSpace:CGFloat = 10
    ///Cell的左間隔
    public var leftSpace:CGFloat = 10
    ///左內容的間距(有圖片的時候用)
    public var contentLeftSpace:CGFloat = 10
    ///Cell的圓角度數
    public var cellCorner:CGFloat = 10
    ///Cell的Switch的开顏色
    public var switchOnTinColor:UIColor = .systemGreen
    ///Cell的Switch的按钮顏色
    public var switchThumbTintColor:UIColor = .white
    ///Cell的Switch的边框顏色
    public var switchTintColor:UIColor = .clear
    ///Cell的Switch的背景顏色
    public var switchBackgroundColor:UIColor = .clear
    ///Section的更多文字
    public var moreString:String = "PT More".localized()
    ///Section的更多文字颜色
    public var moreColor:UIColor = .lightGray
    ///更多的字体
    public var moreFont:UIFont = .appfont(size: 13)
    ///更多与箭头的间隙
    public var moreDisclosureIndicatorSpace:CGFloat = 5
    ///更多箭头的大小
    public var moreDisclosureIndicatorSize:CGSize = CGSizeMake(14, 14)
    ///更多展示方式
    public var moreLayoutStyle: PTLayoutButtonStyle = .leftTitleRightImage
    ///Section的更多箭头图片
    public var moreDisclosureIndicator :Any? = "▶️".emojiToImage(emojiFont: .appfont(size: 14))
    ///iCloudDocument地址
    public var iCloudDocument:String = ""
    ///TopLineHeight
    public var topLineHeight:CGFloat = 1
    ///BottomLineHeight
    public var bottomLineHeight:CGFloat = 1
    ///TopLineColor
    public var topLineColor:UIColor = DynamicColor(hexString: "E8E8E8") ?? .lightGray
    ///BottomLineColor
    public var bottomLineColor:UIColor = DynamicColor(hexString: "E8E8E8") ?? .lightGray
        
    @PTClampedProperyWrapper(range:20...51) public var switchControlWidth: CGFloat = 51

}

@objcMembers
open class PTTagLayoutModel:NSObject {
    public var name:String = ""
    public var haveImage:Bool = false
    public var imageWidth:CGFloat = 16
    public var contentSpace:CGFloat = 4
    public var contentFont:UIFont = .appfont(size: 14)
    public var contentTextColor:UIColor = .black
}
