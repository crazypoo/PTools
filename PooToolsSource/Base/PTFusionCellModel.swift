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
    open var leftImage:Any?
    ///图片上下间隔默认CGFloat.ScaleW(w: 5)
    open var imageTopOffset:CGFloat = 5
    open var imageBottomOffset:CGFloat = 5
    open var labelLineSpace:CGFloat = 2
    ///icon是否圆形
    open var iconRound:Bool = false
    ///名
    open var name:String = ""
    ///名字颜色
    open var nameColor:UIColor = PTAppBaseConfig.share.viewDefaultTextColor
    ///主标题下的描述
    open var desc:String = ""
    ///主标题下文字颜色
    open var descColor:UIColor = UIColor.lightGray
    ///主标题的富文本
    open var nameAttr:ASAttributedString?
    ///描述
    open var content:String = ""
    ///描述文字颜色
    open var contentTextColor:UIColor = PTAppBaseConfig.share.viewDefaultTextColor
    ///Content的富文本
    open var contentAttr:ASAttributedString?
    ///content字体
    open var contentFont:UIFont = .appfont(size: 16)
    ///AccessoryView类型
    open var accessoryType:PTFusionShowAccessoryType = .NoneAccessoryView
    ///是否有线
    open var haveLine:PTFusionLineType = .NO
    ///顶部线
    open var haveTopLine:PTFusionLineType = .NO
    ///字体
    open var cellFont:UIFont = .appfont(size: 16)
    ///Desc字体
    open var cellDescFont:UIFont = .appfont(size: 14)
    ///ID
    open var cellID:String? = ""
    ///ClassName
    open var cellClass: AnyClass? = nil
    
    ///是否已经选择了
    open var cellSelect:Bool? = false
    ///当前选择的Indexpath
    open var cellIndexPath:IndexPath?
    ///Cell的AccessViewImage
    open var disclosureIndicatorImage :Any?
    ///Cell的圓角處理
    open var conrner:UIRectCorner = []
    ///Cell的是否顯示Icon
    open var contentIcon:Any?
    ///Cell的右間隔
    open var rightSpace:CGFloat = 10
    ///右內容的間距
    open var contentRightSpace:CGFloat = 10
    ///Cell的左間隔
    open var leftSpace:CGFloat = 10
    ///左內容的間距(有圖片的時候用)
    open var contentLeftSpace:CGFloat = 10
    ///Cell的圓角度數
    open var cellCorner:CGFloat = 10
    ///Cell的Switch的开顏色
    open var switchOnTinColor:UIColor = .systemGreen
    ///Cell的Switch的按钮顏色
    open var switchThumbTintColor:UIColor = .white
    ///Cell的Switch的边框顏色
    open var switchTintColor:UIColor = .clear
    ///Cell的Switch的背景顏色
    open var switchBackgroundColor:UIColor = .clear
    ///Section的更多文字
    open var moreString:String = "PT More".localized()
    ///Section的更多文字颜色
    open var moreColor:UIColor = .lightGray
    ///更多的字体
    open var moreFont:UIFont = .appfont(size: 13)
    ///更多与箭头的间隙
    open var moreDisclosureIndicatorSpace:CGFloat = 5
    ///更多箭头的大小
    open var moreDisclosureIndicatorSize:CGSize = CGSizeMake(14, 14)
    ///更多展示方式
    open var moreLayoutStyle: PTLayoutButtonStyle = .leftTitleRightImage
    ///Section的更多箭头图片
    open var moreDisclosureIndicator :Any? = "▶️".emojiToImage(emojiFont: .appfont(size: 14))
    ///iCloudDocument地址
    open var iCloudDocument:String = ""
    ///TopLineHeight
    open var topLineHeight:CGFloat = 1
    ///BottomLineHeight
    open var bottomLineHeight:CGFloat = 1
    ///TopLineColor
    open var topLineColor:UIColor = DynamicColor(hexString: "E8E8E8") ?? .lightGray
    ///BottomLineColor
    open var bottomLineColor:UIColor = DynamicColor(hexString: "E8E8E8") ?? .lightGray
        
    @PTClampedProperyWrapper(range:20...51) open var switchControlWidth: CGFloat = 51

}

@objcMembers
open class PTTagLayoutModel:NSObject {
    open var name:String = ""
    open var haveImage:Bool = false
    open var imageWidth:CGFloat = 16
    open var contentSpace:CGFloat = 4
    open var contentFont:UIFont = .appfont(size: 14)
    open var contentTextColor:UIColor = .black
}
