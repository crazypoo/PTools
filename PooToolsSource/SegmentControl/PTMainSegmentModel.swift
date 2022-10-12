//
//  MSMainSegmentModel.swift
//  MinaTicket
//
//  Created by jax on 2022/6/18.
//  Copyright © 2022 Hola. All rights reserved.
//

import UIKit
import JXSegmentedView

public enum PTSegmentControlModelType
{
    case OnlyTitle(type:PTSegmentControlModelSubType)
    case ImageTitle(type:PTSegmentControlModelSubType)
    case OnlyImage
    
    public enum PTSegmentControlModelSubType {
    case Normal
    case OnlyTitle
    }
}

public class PTMainSegmentModel: JXSegmentedTitleItemModel {
    open var subTitle: String? = ""
    open var subTitleNormalColor: UIColor = .black
    open var subTitleCurrentColor: UIColor = .black
    open var subTitleSelectedColor: UIColor = .white
    open var subTitleCurrentBGColor: UIColor = .clear
    open var subTitleNormalBGColor: UIColor = .clear
    open var subTitleSelectedBGColor: UIColor = .clear
    open var itemWidthIncrement : CGFloat = 0
    open var onlyShowTitle:PTSegmentControlModelType? = .OnlyTitle(type: .Normal)
    open var subTitleNormalFont: UIFont = .appfont(size: 12)
    open var subTitleSelectedFont: UIFont = .appfont(size: 12,bold: true)
    open var modelIndex:Int = 0
    open var itemSpace:CGFloat = 0
    open var imageURL:String? = ""
}
