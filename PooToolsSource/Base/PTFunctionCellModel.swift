//
//  PTFunctionCellModel.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public class PTFunctionCellModel: NSObject {
    ///图片名
    var imageName:String = ""
    ///图片上下间隔默认CGFloat.ScaleW(w: 5)
    var imageTopOffset:CGFloat = CGFloat.ScaleW(w: 5)
    var imageBottomOffset:CGFloat = CGFloat.ScaleW(w: 5)
    ///名
    var name:String = ""
    ///名字颜色
    var nameColor:UIColor = UIColor.black
    ///主标题下的描述
    var desc:String = ""
    ///主标题下文字颜色
    var descColor:UIColor = UIColor.lightGray
    ///描述
    var content:String = ""
    ///描述文字颜色
    var contentTextColor:UIColor = UIColor.black
    ///Content的富文本
    var contentAttr:NSAttributedString?
    ///是否带有switch
    var haveSwitch:Bool = false
    ///是否带有可点击标识
    var haveDisclosureIndicator:Bool = false
    ///是否有线
    var haveLine:Bool = false
    ///字体
    var cellFont:UIFont = .appfont(size: 16)
    ///ID
    var cellID:String? = ""
    ///是否已经选择了
    var cellSelect:Bool? = false
    ///当前选择的Indexpath
    var cellIndexPath:IndexPath?
    ///Cell的AccessViewImage
    var disclosureIndicatorImageName :String = ""
    
    var conrner:UIRectCorner = []
    
    var showContentIcon:Bool = false
    var contentIcon:String = ""
    
    var rightSpace:CGFloat = 10
    var leftSpace:CGFloat = 10
    var cellCorner:CGFloat = 10
    var switchTinColor:UIColor = .systemGreen
}
