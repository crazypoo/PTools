//
//  URLSessionConfiguration+PTSwizzle.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

extension URLSessionConfiguration {

    @MainActor @objc
    static func swizzleMethods() {
        guard self == URLSessionConfiguration.self else {
            return
        }
        
        DispatchQueue.once(token: "pootools.urlsessionconfiguration.debug.swizzleMethods") {
            Swizzle(URLSessionConfiguration.self) {
                #selector(getter: URLSessionConfiguration.default) <-> #selector(URLSessionConfiguration.swizzledDefaultSessionConfiguration)
                #selector(getter: URLSessionConfiguration.ephemeral) <-> #selector(URLSessionConfiguration.swizzledEphemeralSessionConfiguration)
            }
        }
    }

    @MainActor private static func registerDebugProtocolIfNeeded() {
        DispatchQueue.once(token: "pootools.urlsessionconfiguration.debug.protocol") {
            URLProtocol.registerClass(PTCustomHTTPProtocol.self)
        }
    }

    @MainActor @objc
    private class func swizzledDefaultSessionConfiguration() -> URLSessionConfiguration {
        let configuration = swizzledDefaultSessionConfiguration()
        addDebugProtocol(to: configuration)
        return configuration
    }

    @MainActor @objc
    private class func swizzledEphemeralSessionConfiguration() -> URLSessionConfiguration {
        let configuration = swizzledEphemeralSessionConfiguration()
        addDebugProtocol(to: configuration)
        return configuration
    }

    @MainActor private static func addDebugProtocol(to configuration: URLSessionConfiguration) {
        var protocolClasses = configuration.protocolClasses ?? []
        if !protocolClasses.contains(where: { $0 == PTCustomHTTPProtocol.self }) {
            protocolClasses.insert(PTCustomHTTPProtocol.self, at: .zero)
            configuration.protocolClasses = protocolClasses
        }
        registerDebugProtocolIfNeeded()
    }
}
