//
//  NSDictionary+PTEX.swift
//  Diou
//
//  Created by ken lam on 2021/10/21.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit

public extension NSDictionary {
    //MARK: Json類型數據轉字符串
    ///Json類型數據轉字符串
    @objc func jsonDataToString() -> String {
        let stringDict = self.reduce(into: [String: String]()) { result, element in
            let key = "\(element.key)"
            let value = "\(element.value)"
            result[key] = value
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: stringDict, options: [])
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
    
    //MARK: 檢測Dic是否為空
    ///檢測Dic是否為空
    class func checkDic(_ dic:NSDictionary?) -> Bool {
        if dic == nil {
            return true
        }
        if let dict = dic as? [AnyHashable:Any],dict.isEmpty {
            return true
        }
        if (dic?.allKeys ?? []).isEmpty {
            return true
        }
        return false
    }
}
