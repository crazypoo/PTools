//
//  URLSessionConfiguration+PTSwizzle.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import os.lock

// English: Keep protocol registration thread-safe because URLSession configuration getters are not main-thread APIs.
// Español: Mantén el registro del protocolo seguro entre hilos porque los getters de URLSession no son APIs del hilo principal.
// 中文：URLSession 配置 getter 不属于主线程 API，因此协议注册必须保证线程安全。
private enum PTURLSessionDebugProtocolRegistry {
    static let lock = OSAllocatedUnfairLock(initialState: false)
}

extension URLSessionConfiguration {

    @MainActor @objc
    static func swizzleMethods() {
        guard self == URLSessionConfiguration.self else {
            return
        }
        
        DispatchQueue.once(token: "pootools.urlsessionconfiguration.debug.swizzleMethods") {
            // English: These are class methods, so swizzle the metaclass rather than the instance method table.
            // Español: Son métodos de clase, por lo que se intercambia la metaclase y no la tabla de métodos de instancia.
            // 中文：这里交换的是类方法，必须操作元类，不能使用实例方法表。
            Swizzle(URLSessionConfiguration.self, isClassMethod: true, owner: "debug.network") {
                #selector(getter: URLSessionConfiguration.default) <-> #selector(URLSessionConfiguration.swizzledDefaultSessionConfiguration)
                #selector(getter: URLSessionConfiguration.ephemeral) <-> #selector(URLSessionConfiguration.swizzledEphemeralSessionConfiguration)
            }
        }
    }

    private static func registerDebugProtocolIfNeeded() {
        let shouldRegister = PTURLSessionDebugProtocolRegistry.lock.withLock { isRegistered in
            guard !isRegistered else { return false }
            isRegistered = true
            return true
        }
        guard shouldRegister else { return }
        URLProtocol.registerClass(PTCustomHTTPProtocol.self)
    }

    @objc
    private class func swizzledDefaultSessionConfiguration() -> URLSessionConfiguration {
        let configuration = swizzledDefaultSessionConfiguration()
        addDebugProtocol(to: configuration)
        return configuration
    }

    @objc
    private class func swizzledEphemeralSessionConfiguration() -> URLSessionConfiguration {
        let configuration = swizzledEphemeralSessionConfiguration()
        addDebugProtocol(to: configuration)
        return configuration
    }

    private static func addDebugProtocol(to configuration: URLSessionConfiguration) {
        var protocolClasses = configuration.protocolClasses ?? []
        if !protocolClasses.contains(where: { $0 == PTCustomHTTPProtocol.self }) {
            protocolClasses.insert(PTCustomHTTPProtocol.self, at: .zero)
            configuration.protocolClasses = protocolClasses
        }
        registerDebugProtocolIfNeeded()
    }
}
