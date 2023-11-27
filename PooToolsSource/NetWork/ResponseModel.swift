//
//  ResponseModel.swift
//  MiniChatSwift
//
//  Created by 林勇彬 on 2022/5/20.
//  Copyright © 2022 九州所想. All rights reserved.
//

import UIKit
import KakaJSON
import HandyJSON

public class ResponseModel:PTBaseModel {
    public var status: Int = 0
    public var data: Any? = nil
    public var datas: [Any]? = nil
    public let msg: String = ""
    public let totalCount: Int = 0
    public var originalString: String = ""
    public var customerModel: Any? = nil

    public var isSuccess:Bool {
        get {
            status == 200
        }
    }
}

public class PTIPInfoModel :PTBaseModel {
    var lon: CGFloat = 0.0
    var zip: String!
    var query: String!
    var asBaseic: String!
    var isp: String!
    var countryCode: String!
    var lat: CGFloat = 0.0
    var city: String!
    var region: String!
    var timezone: String!
    var org: String!
    var country: String!
    var status: String!
    var regionName: String!
    
    required public init() {}

    public override func mapping(mapper: HelpingMapper) {
        mapper <<<
            asBaseic <-- "as"
    }
}
