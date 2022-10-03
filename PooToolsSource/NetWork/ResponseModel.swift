//
//  ResponseModel.swift
//  MiniChatSwift
//
//  Created by 林勇彬 on 2022/5/20.
//  Copyright © 2022 九州所想. All rights reserved.
//

import UIKit
import KakaJSON

public class ResponseModel:PTBaseModel {
    public var status: Int = 0
    public var data: Any? = nil
    public var datas: [Any]? = nil
    public let msg: String = ""
    public let totalCount: Int = 0
    public var originalString: String = ""

    public var isSuccess:Bool {
        get {
            return status == 200
        }
    }
}
