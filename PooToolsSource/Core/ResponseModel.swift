//
//  ResponseModel.swift
//  MiniChatSwift
//
//  Created by 林勇彬 on 2022/5/20.
//  Copyright © 2022 九州所想. All rights reserved.
//

import UIKit
import KakaJSON
//import MetaCodable
//import HelperCoders

public class PTIPInfoModel :PTBaseModel {
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
    
    public override func kj_modelKey(from property: Property) -> ModelPropertyKey {
        switch property.name {
        case "asBaseic":
            return "as"
        default:
            return property.name
        }
    }
}

public struct PTBaseStructModel {
    public var originalString: String = ""
    public var customerModel: Any? = nil
    public var resultData:Data? = Data()
    
    init() {}
}
