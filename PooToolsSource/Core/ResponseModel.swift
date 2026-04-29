//
//  ResponseModel.swift
//  MiniChatSwift
//
//  Created by 林勇彬 on 2022/5/20.
//  Copyright © 2022 九州所想. All rights reserved.
//

import UIKit

public struct PTIPInfoModel :PTModelProtocol {
    public var lon: CGFloat = 0.0
    public var zip: String = ""
    public var query: String = ""
    public var asBaseic: String = ""
    public var isp: String = ""
    public var countryCode: String = ""
    public var lat: CGFloat = 0.0
    public var city: String = ""
    public var region: String = ""
    public var timezone: String = ""
    public var org: String = ""
    public var country: String = ""
    public var status: String = ""
    public var regionName: String = ""
            
    public init() {}
    
    enum CodingKeys: String,CodingKey {
        case asBaseic = "as"
        // 其余字段名和后端完全一致，直接列出来即可
        case lon, zip, query, isp, countryCode, lat, city, region, timezone, org, country, status, regionName
    }
}

public struct PTBaseStructModel {
    public var originalString: String = ""
    public var customerModel: Any? = nil
    public var resultData:Data? = Data()
    
    init() {}
}
