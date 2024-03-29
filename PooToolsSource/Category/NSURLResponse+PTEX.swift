//
//  NSURLRepose+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 3/12/22.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

extension URLResponse {
    typealias MYURLResponseGetHTTPResponse = ((CFURL?) -> CFHTTPMessage?)?

    //MARK: 獲取Http的版本
    ///獲取Http的版本
    func getHTTPVersion() -> String? {
        let response = self
        var version: String?
        // 获取CFURLResponseGetHTTPResponse的函数实现
        let funName = "CFURLResponseGetHTTPResponse"
        let originURLResponseGetHTTPResponse = dlsym(UnsafeMutableRawPointer(bitPattern: Int(2)), funName.cString(using: .utf8))
        let theSelector = NSSelectorFromString("_CFURLResponse")
        if response.responds(to: theSelector) && nil != originURLResponseGetHTTPResponse {
            // 获取NSURLResponse的_CFURLResponse
            //#pragma clang diagnostic push
            //#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            let cfResponse = CFBridgingRetain(response.perform(theSelector))
            //#pragma clang diagnostic pop
            if nil != cfResponse {
                // 将CFURLResponseRef转化为CFHTTPMessageRef
                let message = originURLResponseGetHTTPResponse//originURLResponseGetHTTPResponse(cfResponse)
                // 获取http协议版本
                var cfVersion: CFString? = nil
                if let message {
                    cfVersion = (CFHTTPMessageCopyVersion(message as! CFHTTPMessage) as! CFString)
                }
                if nil != cfVersion {
                    version = cfVersion as? String
                }
            }
        }
        // 获取失败的话则设置一个默认值
        if nil == version || 0 == (version?.count ?? 0) {
            version = "HTTP/1.1"
        }
        return version
    }
}
