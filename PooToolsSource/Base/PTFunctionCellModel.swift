//
//  PTFunctionCellModel.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

open class PTFunctionCellModel: NSObject {
    ///图片名
    open var imageName:String = ""
    ///图片上下间隔默认CGFloat.ScaleW(w: 5)
    open var imageTopOffset:CGFloat = CGFloat.ScaleW(w: 5)
    open var imageBottomOffset:CGFloat = CGFloat.ScaleW(w: 5)
    ///名
    open var name:String = ""
    ///名字颜色
    open var nameColor:UIColor = UIColor.black
    ///主标题下的描述
    open var desc:String = ""
    ///主标题下文字颜色
    open var descColor:UIColor = UIColor.lightGray
    ///描述
    open var content:String = ""
    ///描述文字颜色
    open var contentTextColor:UIColor = UIColor.black
    ///Content的富文本
    open var contentAttr:NSAttributedString?
    ///是否带有switch
    open var haveSwitch:Bool = false
    ///是否带有可点击标识
    open var haveDisclosureIndicator:Bool = false
    ///是否有线
    open var haveLine:Bool = false
    ///字体
    open var cellFont:UIFont = .appfont(size: 16)
    ///ID
    open var cellID:String? = ""
    ///是否已经选择了
    open var cellSelect:Bool? = false
    ///当前选择的Indexpath
    open var cellIndexPath:IndexPath?
    ///Cell的AccessViewImage
    open var disclosureIndicatorImageName :String = ""
    
    open var conrner:UIRectCorner = []
    
    open var showContentIcon:Bool = false
    open var contentIcon:String = ""
    
    open var rightSpace:CGFloat = 10
    open var leftSpace:CGFloat = 10
    open var cellCorner:CGFloat = 10
    open var switchTinColor:UIColor = .systemGreen
}
