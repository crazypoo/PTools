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

        let defaultSessionConfiguration = class_getClassMethod(
            URLSessionConfiguration.self,
            #selector(getter: URLSessionConfiguration.default)
        )
        let swizzledDefaultSessionConfiguration = class_getClassMethod(
            URLSessionConfiguration.self,
            #selector(URLSessionConfiguration.swizzledDefaultSessionConfiguration)
        )

        method_exchangeImplementations(defaultSessionConfiguration!, swizzledDefaultSessionConfiguration!)

        let ephemeralSessionConfiguration = class_getClassMethod(
            URLSessionConfiguration.self,
            #selector(getter: URLSessionConfiguration.ephemeral)
        )
        let swizzledEphemeralSessionConfiguration = class_getClassMethod(
            URLSessionConfiguration.self,
            #selector(URLSessionConfiguration.swizzledEphemeralSessionConfiguration)
        )

        method_exchangeImplementations(ephemeralSessionConfiguration!, swizzledEphemeralSessionConfiguration!)
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

