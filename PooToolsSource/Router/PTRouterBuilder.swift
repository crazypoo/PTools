//
//  PTRouterBuilder.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

public class PTRouterBuilder {
    
    public var buildResult: (String, [String: Any]) = ("", [:])
    
    public init () {}
}

extension PTRouterBuilder {
    
    @discardableResult
    public class func build(_ path: String) -> PTRouterBuilder {
        let builder = PTRouterBuilder.init()
        builder.buildPaths(path: path)
        return builder
    }
    
    @discardableResult
    public func withInt(key: String, value: Int) -> Self {
        buildResult.1[key] = value
        return self
    }
    
    @discardableResult
    public func withString(key: String, value: String) -> Self {
        buildResult.1[key] = value
        return self
    }
    
    @discardableResult
    public func withBool(key: String, value: Bool) -> Self {
        buildResult.1[key] = value
        return self
    }
    
    @discardableResult
    public func withDouble(key: String, value: Double) -> Self {
        buildResult.1[key] = value
        return self
    }
    
    @discardableResult
    public func withFloat(key: String, value: Float) -> Self {
        buildResult.1[key] = value
        return self
    }
    
    @discardableResult
    public func withAny(key: String, value: Any) -> Self {
        buildResult.1[key] = value
        return self
    }
    
    func buildPaths(path: String) {
        buildResult.0 = path
    }
    
    @discardableResult
    public func buildService<PTRouterServiceProtocol>(_ protocolInstance: PTRouterServiceProtocol.Type, methodName: String) -> Self {
        let protocolName = String(describing: protocolInstance)
        buildResult.0 = "\(PTRouter.shareInstance.serviceHost)protocol=\(protocolName)&method=\(methodName)"
        return self
    }
    
    @discardableResult
    public func buildServicePath<PTRouterServiceProtocol>(_ protocolInstance: PTRouterServiceProtocol.Type, methodName: String) -> String {
        let protocolName = String(describing: protocolInstance)
        return "\(PTRouter.shareInstance.serviceHost)protocol=\(protocolName)&method=\(methodName)"
    }
    
    @discardableResult
    func buildService(path: String) -> Self  {
        buildResult.0 = path
        return self
    }
    
    @discardableResult
    public func buildDictionary(param: [String: Any]) -> Self {
        buildResult.1.merge(dic: param)
        return self
    }
    
    @discardableResult
    public func fetchService() async -> Any? {
        let result = PTRouter.generate(buildResult.0, params: buildResult.1, jumpType: .push)
        PTRouter.shareInstance.logcat?(buildResult.0, .logNormal, "")
        return await PTRouter.openURL(result)
    }
    
    public func navigation(_ handler: ComplateHandler = nil) async {
        await PTRouter.openURL(buildResult, complateHandler: handler)
    }
}

public struct PTTypedBuilder<T: PTRoutableStaticController> {
    private let path: String
    private var params: T.Params?

    public init(path: String) {
        self.path = path
    }

    // 这里是精髓：value 必须是该 VC 预定义的 Params 类型
    public func with(params: T.Params) -> Self {
        var copy = self
        copy.params = params
        return copy
    }

    @discardableResult
    // 1. 加上 throws，且返回值从 T? 变成了绝对安全的 T
    public func navigation() async throws -> T {
        let dict = params?.toDictionary() ?? [:]
        
        // 2. 加上 try，调用底层的核心引擎
        let vc = try await PTRouter.openURLVC(path, userInfo: dict)
        
        // 3. 强类型校验：确保底层创建出来的 VC 真的是我们期望的泛型 T
        guard let targetVC = vc as? T else {
            // 如果类型不对，主动抛出一个类型异常
            throw PTRouterError.invalidClass(className: String(describing: T.self))
        }
        
        return targetVC
    }
}
