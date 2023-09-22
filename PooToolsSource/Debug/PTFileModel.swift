//
//  PTFileModel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 23/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public enum PTFileType {
    case unknown
    case folder     //文件夹
    case image      //图片
    case video      //视频
    case audio      //音频
    case web        //链接
    case application    //应用和执行文件
    case zip        //压缩包
    case log        //日志
    case excel     //表格
    case word       //word文档
    case ppt        //ppt
    case pdf        //pdf
    case system     //系统文件
    case txt        //文本
    case db         //数据库
}

class PTFileModel: PTBaseModel {
    var name: String = ""
    var modificationDate: Date = Date()
    var size: Double = 0
    var fileType: PTFileType = .unknown    
}
