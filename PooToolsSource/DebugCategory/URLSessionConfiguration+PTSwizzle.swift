//
//  URLSessionConfiguration+PTSwizzle.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

extension URLSessionConfiguration {

    @objc
    static func swizzleMethods() {
        guard self == URLSessionConfiguration.self else {
            return
        }
        
        Swizzle(URLSessionConfiguration.self) {
            #selector(getter: URLSessionConfiguration.default) <-> #selector(URLSessionConfiguration.swizzledDefaultSessionConfiguration)
            #selector(getter: URLSessionConfiguration.ephemeral) <-> #selector(URLSessionConfiguration.swizzledEphemeralSessionConfiguration)
        }
    }

    @objc
    private class func swizzledDefaultSessionConfiguration() -> URLSessionConfiguration {
        let configuration = swizzledDefaultSessionConfiguration()
        configuration.protocolClasses?.insert(PTCustomHTTPProtocol.self, at: .zero)
        URLProtocol.registerClass(PTCustomHTTPProtocol.self)
        return configuration
    }

    @objc
    private class func swizzledEphemeralSessionConfiguration() -> URLSessionConfiguration {
        let configuration = swizzledEphemeralSessionConfiguration()
        configuration.protocolClasses?.insert(PTCustomHTTPProtocol.self, at: .zero)
        URLProtocol.registerClass(PTCustomHTTPProtocol.self)
        return configuration
    }
}

