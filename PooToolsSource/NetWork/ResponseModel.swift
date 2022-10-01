//
//  ResponseModel.swift
//  MiniChatSwift
//
//  Created by 林勇彬 on 2022/5/20.
//  Copyright © 2022 九州所想. All rights reserved.
//

import UIKit

class ResponseModel:PTBaseModel {
    private(set) var status: Int = 0
    var data: Any? = nil
    var datas: [Any]? = nil
    let msg: String = ""
    let totalCount: Int = 0
    
    var isSuccess:Bool {
        get {
            return status == 200
        }
    }
}
