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
    public var lon: CGFloat = 0.0
    public var zip: String!
    public var query: String!
    public var asBaseic: String!
    public var isp: String!
    public var countryCode: String!
    public var lat: CGFloat = 0.0
    public var city: String!
    public var region: String!
    public var timezone: String!
    public var org: String!
    public var country: String!
    public var status: String!
    public var regionName: String!
    
    required public init() {}

    public override func mapping(mapper: HelpingMapper) {
        mapper <<<
            asBaseic <-- "as"
    }
}
