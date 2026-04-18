//
//  PTRouterServiceManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

public typealias PTServiceCreator = () -> Any

public final class PTRouterServiceManager {
    public static let shared = PTRouterServiceManager()
    
    private let serviceQueue = DispatchQueue(label: "scheme.PTRouterServiceManager.queue")
    // 使用 Any 存储闭包，但在存取时强制类型约束
    private var creatorsMap: [String: () -> Any] = [:]
    private var servicesCache: [String: Any] = [:]
    
    private init() {}
    
    // MARK: - 强类型注册与获取
    public func registerService<Service>(_ serviceType: Service.Type, creator: @escaping () -> Service) {
        let key = String(describing: serviceType)
        serviceQueue.async {
            self.creatorsMap[key] = creator
        }
    }
    
    public func getService<Service>(_ serviceType: Service.Type) -> Service? {
        let key = String(describing: serviceType)
        
        return serviceQueue.sync {
            // 1. 查缓存
            if let cached = servicesCache[key] as? Service {
                return cached
            }
            // 2. 查构造器并缓存
            if let creator = creatorsMap[key], let instance = creator() as? Service {
                servicesCache[key] = instance
                return instance
            }
            return nil
        }
    }
}

//MARK: - Service Register & Unregister
public extension PTRouterServiceManager {
    class func serviceName<T>(of value: T) -> String {
        return String(describing: value)
    }
    
    // MARK: - Register With Service Name
    /// 通过服务名称(named)注册LAServiceCreator
    /// - Parameters:
    ///   - named: 服务名称
    ///   - creator: 服务构造者
    func registerService(named: String, creator: @escaping PTServiceCreator) {
        serviceQueue.async {
            self.creatorsMap[named] = creator
        }
    }
    
    /// 通过服务名称(named)注册一个服务实例 (存在缓存中)
    /// - Parameters:
    ///   - named: 服务名称
    ///   - instance: 服务实例
    func registerService(named: String, instance: Any) {
        serviceQueue.async {
            self.servicesCache[named] = instance
        }
    }
    
    /// 通过服务名称(named)注册LAServiceCreator
    /// - Parameters:
    ///   - named: 服务名称
    ///   - lazyCreator: 延迟实例化构造者 (如：```registerService(named: "A", lazyCreator: A())```)
    func registerService(named: String, lazyCreator: @escaping @autoclosure PTServiceCreator) {
        registerService(named: named, creator: lazyCreator)
    }
        
    /// 通过服务接口注册LAServiceCreator
    /// - Parameters:
    ///   - service: 服务接口
    ///   - lazyCreator: 延迟实例化构造者 (如：```registerService(named: "A", lazyCreator: A())```)
    func registerService<Service>(_ service: Service.Type, lazyCreator: @escaping @autoclosure () -> Service) {
        registerService(named: PTRouterServiceManager.serviceName(of: service), creator: lazyCreator)
    }
    
    /// 通过服务接口注册一个服务实例 (存在缓存中)
    /// - Parameters:
    ///   - service: 服务接口
    ///   - instance: 服务实例
    func registerService<Service>(_ service: Service.Type, instance: Service) {
        registerService(named: PTRouterServiceManager.serviceName(of: service), instance: instance)
    }
    
    // MARK: - Unregister Service
    
    /// 通过服务名称取消注册服务
    /// - Parameter named: 服务名称
    @discardableResult
    func unregisterService(named: String) -> Any? {
        return serviceQueue.sync {
            self.creatorsMap.removeValue(forKey: named)
            return self.servicesCache.removeValue(forKey: named)
        }
    }
    
    /// 通过服务接口取消注册服务
    /// - Parameter service: 服务接口
    @discardableResult
    func unregisterService<Service>(_ service: Service) -> Service? {
        return unregisterService(named: PTRouterServiceManager.serviceName(of: service)) as? Service
    }
}

//MARK: - Register Batch Services
public extension PTRouterServiceManager {
    typealias BatchServiceMap = [String: PTServiceCreator]
    typealias ServiceEntry = BatchServiceMap.Element
    func registerService(_ services: BatchServiceMap) {
        serviceQueue.async {
            self.creatorsMap.merge(services, uniquingKeysWith: { _, v2 in v2 })
        }
    }
    
    func registerService(entryLiteral entries: ServiceEntry ...) {
        return registerService(BatchServiceMap(entries, uniquingKeysWith: {_, v2 in v2}))
    }
}

//MARK: - Service Create
public extension PTRouterServiceManager {
    /// 根据服务名称创建服务（如果缓存中已有服务实例，则不需要创建）
    /// - Parameters:
    ///   - named: 服务名称
    ///   - shouldCache: 是否需要缓存
    func createService(named: String, shouldCache: Bool = true) -> Any? {
        // 检查是否有缓存
        if let service = serviceQueue.sync(execute: { servicesCache[named] }) {
            return service
        }
        // 检查是否有构造者
        guard let creator = serviceQueue.sync(execute: { creatorsMap[named] }) else {
            return nil
        }
        
        let service = creator()
        if shouldCache {
            serviceQueue.async {
                self.servicesCache[named] = service
            }
        }
        return service
    }
    
    /// 根据服务接口创建服务（如果缓存中已有服务实例，则不需要创建）
    /// - Parameters:
    ///   - service: 服务接口
    ///   - shouldCache: 是否需要缓存
    func createService<Service>(_ service: Service.Type, shouldCache: Bool = true) -> Service? {
        createService(named: PTRouterServiceManager.serviceName(of: service), shouldCache: shouldCache) as? Service
    }
}

//MARK: - Service Fetch
public extension PTRouterServiceManager {
    /// 通过服务名称获取服务
    /// - Parameter named: 服务名称
    func getService(named: String) -> Any? {
        createService(named: named)
    }
}

//MARK: - Service Clean Cache
public extension PTRouterServiceManager {
    func cleanAllServiceCache() {
        serviceQueue.async {
            self.servicesCache.removeAll()
        }
    }
    
    @discardableResult
    func cleanServiceCache(named: String) -> Any? {
        serviceQueue.sync {
            servicesCache.removeValue(forKey: named)
        }
    }
    
    @discardableResult
    func cleanServiceCache<Service>(by service: Service.Type) -> Service? {
        cleanServiceCache(named: PTRouterServiceManager.serviceName(of: service)) as? Service
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
