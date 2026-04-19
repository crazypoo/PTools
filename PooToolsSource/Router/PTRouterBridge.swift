//
//  PTRouterBridge.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2/11/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import Foundation

@objcMembers
public class PTRouterBridge: NSObject {
    
    public class func canOpenUrl(_ urlString: String) async -> Bool {
        return await PTRouter.canOpenURL(urlString)
    }
    
    // 方法1：根据URL字符串打开
    @discardableResult
    public class func openURL(_ urlString: String, userInfo: [String: Any] = [String: Any](), complateHandler: ComplateHandler = nil) async throws -> Any? {
        Task {
            do {
                let anys = try await PTRouter.openURL(urlString, userInfo: userInfo, complateHandler: complateHandler)
                return anys
            } catch {
                PTNSLogConsole("\(error)")
                return nil
            }
        }
    }
    
    
    // 方法2：根据URL元组打开
    @discardableResult
    public class func openURL(_ uriTuple: (String, [String: Any]), complateHandler: ComplateHandler = nil) async -> Any? {
        return await PTRouter.openURL(uriTuple, complateHandler: complateHandler)
    }

    // 方法3：根据URL元组打开WebURL
    @discardableResult
    public class func openWebURL(_ uriTuple: (String, [String: Any])) async -> Any? {
        return await PTRouter.openURL(uriTuple)
    }

     // 方法4：根据URL字符串打开WebURL
    @discardableResult
    public class func openWebURL(_ urlString: String, userInfo: [String: Any] = [String: Any]()) async -> Any? {
        return await PTRouter.openURL((urlString, userInfo))
    }
}
