//
//  PTRouterServiceManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

public typealias PTServiceCreator = () -> Any

// 1. 服务生命周期定义
public enum PTServiceScope {
    case singleton  // 单例：全局唯一，强缓存
    case prototype  // 原型：每次获取都生成新实例，不占用缓存
}

// 2. 升级为 Actor：天生线程安全，抛弃 DispatchQueue
public actor PTRouterServiceManager {
    public static let shared = PTRouterServiceManager()
    
    // 存储结构优化：同时保存 Scope 和 Creator
    // ⚠️ 注意：再也没有 serviceQueue 了！
    private var creatorsMap: [String: (scope: PTServiceScope, creator: PTServiceCreator)] = [:]
    private var servicesCache: [String: Any] = [:]
    
    private init() {}
    
    // MARK: - 基础强类型注册与获取 (核心方法)
    public func registerService<Service>(_ serviceType: Service.Type, scope: PTServiceScope = .singleton, creator: @escaping () -> Service) {
        let key = PTRouterServiceManager.serviceName(of: serviceType)
        creatorsMap[key] = (scope, creator)
    }
    
    public func getService<Service>(_ serviceType: Service.Type) -> Service? {
        let key = PTRouterServiceManager.serviceName(of: serviceType)
        
        // 1. 查单例缓存
        if let cached = servicesCache[key] as? Service {
            return cached
        }
        // 2. 查构造器
        guard let config = creatorsMap[key], let instance = config.creator() as? Service else {
            return nil
        }
        // 3. 决定是否缓存
        if config.scope == .singleton {
            servicesCache[key] = instance
        }
        return instance
    }
}

// MARK: - 原有扩展平滑升级 (兼容旧 API)
public extension PTRouterServiceManager {
    
    // 静态方法不受 Actor 实例隔离限制，可以直接用
    static func serviceName<T>(of value: T) -> String {
        return String(describing: value)
    }
    
    // MARK: - Register With Service Name
    // ⚠️ 扩展里的方法在 Actor 内部默认是隔离的，直接赋值绝对安全！
    func registerService(named: String, scope: PTServiceScope = .singleton, creator: @escaping PTServiceCreator) {
        self.creatorsMap[named] = (scope, creator)
    }
    
    func registerService(named: String, instance: Any) {
        // 直接传实例的话，强制当做 singleton 存入缓存
        self.servicesCache[named] = instance
    }
    
    func registerService(named: String, scope: PTServiceScope = .singleton, lazyCreator: @escaping @autoclosure PTServiceCreator) {
        registerService(named: named, scope: scope, creator: lazyCreator)
    }
    
    func registerService<Service>(_ service: Service.Type, scope: PTServiceScope = .singleton, lazyCreator: @escaping @autoclosure () -> Service) {
        registerService(named: PTRouterServiceManager.serviceName(of: service), scope: scope, creator: lazyCreator)
    }
    
    func registerService<Service>(_ service: Service.Type, instance: Service) {
        registerService(named: PTRouterServiceManager.serviceName(of: service), instance: instance)
    }
    
    // MARK: - Unregister Service
    @discardableResult
    func unregisterService(named: String) -> Any? {
        self.creatorsMap.removeValue(forKey: named)
        return self.servicesCache.removeValue(forKey: named)
    }
    
    @discardableResult
    func unregisterService<Service>(_ service: Service.Type) -> Service? {
        return unregisterService(named: PTRouterServiceManager.serviceName(of: service)) as? Service
    }
}

// MARK: - Register Batch Services
public extension PTRouterServiceManager {
    typealias BatchServiceMap = [String: PTServiceCreator]
    typealias ServiceEntry = BatchServiceMap.Element
    
    func registerService(_ services: BatchServiceMap, scope: PTServiceScope = .singleton) {
        // 字典合并，自动装配上 scope
        let mappedServices = services.mapValues { (scope, $0) }
        self.creatorsMap.merge(mappedServices, uniquingKeysWith: { _, v2 in v2 })
    }
    
    func registerService(scope: PTServiceScope = .singleton, entryLiteral entries: ServiceEntry ...) {
        registerService(BatchServiceMap(entries, uniquingKeysWith: { _, v2 in v2 }), scope: scope)
    }
}

// MARK: - Service Create & Fetch (按字符串)
public extension PTRouterServiceManager {
    func createService(named: String) -> Any? {
        // 1. 检查是否有缓存
        if let service = servicesCache[named] {
            return service
        }
        
        // 2. 检查是否有对应的构造配置 (这里才是 Optional 的)
        guard let config = creatorsMap[named] else {
            return nil
        }
        
        // 3. 直接调用构造器生成实例 (creator 返回的是 Any，不需要 let 解包)
        let service = config.creator()
        
        // 4. 根据生命周期决定是否缓存
        if config.scope == .singleton {
            servicesCache[named] = service
        }
        
        return service
    }
    
    func getService(named: String) -> Any? {
        return createService(named: named)
    }
}

// MARK: - Service Clean Cache
public extension PTRouterServiceManager {
    func cleanAllServiceCache() {
        self.servicesCache.removeAll()
    }
    
    @discardableResult
    func cleanServiceCache(named: String) -> Any? {
        return servicesCache.removeValue(forKey: named)
    }
    
    @discardableResult
    func cleanServiceCache<Service>(by service: Service.Type) -> Service? {
        return cleanServiceCache(named: PTRouterServiceManager.serviceName(of: service)) as? Service
    }
}

public class PTServiceActionMapper {
    public static let shared = PTServiceActionMapper()
    
    // 存储映射关系：[ProtocolName_MethodName : 执行闭包]
    private var actionMap: [String: (Any?, Any?) -> Any?] = [:]
    
    // 注册动态服务闭包
    public func register(protocolName: String, methodName: String, action: @escaping (Any?, Any?) -> Any?) {
        let key = "\(protocolName)_\(methodName)"
        actionMap[key] = action
    }
    
    // 执行动态服务
    public func execute(protocolName: String, methodName: String, param: Any?, otherParam: Any?) -> Any? {
        let key = "\(protocolName)_\(methodName)"
        
        guard let action = actionMap[key] else {
            // ⚠️ 如果控制台打印了这句话，说明有人尝试通过 URL 调用服务，但你没注册！
            PTRouter.shareInstance.logcat?("Service", .logError, "未找到对应的动态服务闭包: \(key)")
            return nil
        }
        
        return action(param, otherParam)
    }
}
