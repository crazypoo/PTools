//
//  PTAPIFunctionCheck.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/9.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import Alamofire
import KakaJSON

class PTAPIFunctionCheck: NSObject {
    class func checkCode(code:String) ->Bool {
        if code == "000000" {
            return true
        } else {
            return false
        }
    }
    
    class func getUserLanguage() ->String {
        //zh,kh,en,tw
        let lauguage = "zh"
        return lauguage
    }

    class func apiHeaderSet(parmas:[String:String]?) ->HTTPHeaders {
        
        let currentSteamTime = NSDate().timeIntervalSinceNow
        
        let token = "test"
        
        let version = kAppVersion!
        
        let keysArr = parmas?.keys.sorted { (obj1,obj2) ->Bool in
            return obj1.compare(obj2,options: .numeric) == .orderedAscending
        }
        
        var clear = ""
        
        keysArr?.enumerated().forEach { index,value in
            clear = clear.appendingFormat("%@=%@&",value,(parmas![value]!))
        }
        clear = clear.appendingFormat("%@=%@","salt","tinhtinh")
        
        let headerDic = ["ts":"\(currentSteamTime)","token":token,"version":version,"sign":clear.md5,"language":PTAPIFunctionCheck.getUserLanguage()] as [String : String]
        
        return HTTPHeaders.init(headerDic)
    }

    class func swiftApiRequest(apiUrl:String,method:HTTPMethod = .post,parameters:[String:String]? = nil,modelType: Convertible.Type,success:@escaping ((Any?) -> Void),fail:@escaping ((String)->Void)) {
        Task.init {
            do {
                let header = PTAPIFunctionCheck.apiHeaderSet(parmas: parameters)

                let model = try await Network.requestApi(needGobal:false,urlStr: apiUrl,method: method,header: header,parameters: parameters,modelType: modelType)
                success(model.customerModel)
            } catch {
                PTNSLogConsole("\(error.localizedDescription)",levelType: .Notice,loggerType: .Network)
                fail(error.localizedDescription)
            }
        }
    }
}

