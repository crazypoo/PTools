//
//  PTRouter.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import UIKit

/*
 1.先AppDelegate注册服务
 /// 服务路由
 public let serivceHost = "scheme://services?"

 /// web跳转路由
 public let webRouterUrl = "scheme://webview/home"

 // 路由懒加载注册
 PTRouter.lazyRegisterRouterHandle { url, userInfo in
     PTRouterManager.injectRouterServiceConfig(webRouterUrl, serivceHost)
     return PTRouterManager.addGloableRouter([".XXXXX"], url, userInfo)
 }

 // 动态注册服务
 PTRouterManager.registerServices()

 // 日志回调，可以监控线上路由运行情况
 PTRouter.logcat { url, logType, errorMsg in
     PTNSLogConsole("PTRouter: logMsg- \(url) \(logType.rawValue) \(errorMsg)")
 }

 2.然后在VC绑定属性
 extension XXXXXXXXXXXController: PTRouterable {
     
     static var patternString: [String] {
         ["scheme://router/demo"]
     }
          
     static func registerAction(info: [String : Any]) -> Any {
         let vc =  XXXXXXXXXXXController()
         vc.resultLabel.text = info.description
         return vc
     }
 }
 */

// MARK: - Constants
// 跳转类型
public let PTJumpTypeKey = "jumpType"
// 第一个参数
public let PTRouterIvar1Key = "ivar1"
// 第二个参数
public let PTRouterIvar2Key = "ivar2"
// 返回值类型
public let PTRouterFunctionResultKey = "resultType"
// 路由Path常量Key
public let PTRouterPath = "path"
// 路由class常量Key
public let PTRouterClassName = "class"
//路由priority常量Key
public let PTRouterPriority = "priority"
// tabBar选中参数 tabBarSelecIndex
public let PTRouterTabBarSelecIndex = "tabBarSelecIndex"
//路由优先级默认值
public let PTRouterDefaultPriority: UInt = 1000

public typealias ComplateHandler = (([String: Any]?, Any?) -> Void)?

public enum PTRouterError: Error, LocalizedError {
    case notFound(url: String)
    case interceptorBlocked(reason: String)
    case invalidClass(className: String)
    case initializationFailed
    
    public var errorDescription: String? {
        switch self {
        case .notFound(let url): return "路由未匹配或未注册: \(url)"
        case .interceptorBlocked(let reason): return "路由被拦截器中断: \(reason)"
        case .invalidClass(let className): return "无法解析对应的目标类，请检查类名拼写: \(className)"
        case .initializationFailed: return "控制器初始化失败"
        }
    }
}

// 定义一个封装类来存储和执行接受参数的闭包
public class PTRouerParamsClosureWrapper: NSObject {
    public var closure: ((Any) -> Void)?

    public init(closure: @escaping (Any) -> Void) {
        self.closure = closure
    }

    public func executeClosure(params: Any) {
        closure?(params)
    }
}

public class PTRouter: PTRouterParser {
    
    // MARK: - Constants
    public typealias FailedHandleBlock = ([String: Any]) -> Void
    public typealias RouteResponse = (pattern: PTRouterPattern?, queries: [String: Any])
    public typealias MatchResult = (matched: Bool, queries: [String: Any])
    public typealias LazyRegisterHandleBlock = (_ url: String, _ userInfo: [String: Any]) -> Any?
    public typealias RouterLogHandleBlock = (_ url: String, _ logType: PTRouterLogType, _ errorMsg: String) -> Void
    
    // MARK: - 自定义跳转
    public typealias CustomJumpActionClouse = (PTJumpType, UIViewController) -> Void

    // MARK: - Private property
    // 存储新的异步拦截器
    private static var asyncInterceptors = [PTRouterAsyncInterceptor]()
    
    private var globalOpenFailedHandler: FailedHandleBlock?
    
    // MARK: - Public  property
    public static let shareInstance = PTRouter()
    
    // 映射要替换的路由信息
    public var reloadRouterMap: [PTRouterInfo] = []
    
    /// 懒加载注册
    public var lazyRegisterHandleBlock: LazyRegisterHandleBlock?
    
    // 路由是否加载完毕
    public var routerLoaded: Bool = false
    
    public var patterns = [PTRouterPattern]()
    
    public var webPath: String?
    
    public var serviceHost: String = "scheme://services?"
    
    public var logcat: RouterLogHandleBlock?
    
    public var customJumpAction: CustomJumpActionClouse?

    // MARK: - Public method
    func addRouterItem(_ patternString: String,
                       classString: String,
                       priority: uint = 0) {
        let pattern = PTRouterPattern(patternString.trimmingCharacters(in: CharacterSet.whitespaces), classString: classString, priority: UInt(priority))
        patterns.append(pattern)
        patterns.sort { $0.priority > $1.priority }
    }
    
    public class func addAsyncInterceptor(_ interceptor: PTRouterAsyncInterceptor) {
        asyncInterceptors.append(interceptor)
        asyncInterceptors.sort { $0.priority > $1.priority }
    }
    
    func globalOpenFailedHandler(_ handle: @escaping FailedHandleBlock) {
        globalOpenFailedHandler = handle
    }
    
    func lazyRegisterRouterHandle(_ handle: @escaping LazyRegisterHandleBlock) {
        lazyRegisterHandleBlock = handle
    }
    
    func logcat(_ handle: @escaping RouterLogHandleBlock) {
        logcat = handle
    }
    
    func customJumpAction(_ handle: @escaping CustomJumpActionClouse) {
        customJumpAction = handle
    }

    func removeRouter(_ patternString: String) {
        patterns = patterns.filter { $0.patternString != patternString }
    }
    
    func canOpenURL(_ urlString: String) async -> Bool {
        if urlString.isEmpty {
            return false
        }
        return await PTRouter.matchURL(urlString.trimmingCharacters(in: CharacterSet.whitespaces)).pattern != nil
    }
    
    func requestURL(_ urlString: String, userInfo: [String: Any] = [String: Any]()) async -> RouteResponse {
        await PTRouter.matchURL(urlString.trimmingCharacters(in: CharacterSet.whitespaces), userInfo: userInfo)
    }
    
    // MARK: - Private method
    private class func matchURL(_ urlString: String, userInfo: [String: Any] = [String: Any]()) async -> RouteResponse {
        
        let request = PTRouterRequest(urlString)
        // queries 包含了 ? 后面跟随的基础参数 (比如 scheme://user/123?from=home 里的 from=home)
        var queries = request.queries
        var matched: PTRouterPattern?
        var matchUserInfo: [String: Any] = userInfo
        
        // 1. 处理动态重定向 (Relocation)
        let relocationMap = shareInstance.reloadRouterMap(PTRouter.shareInstance.reloadRouterMap, url: urlString)
        if let relocationMap = relocationMap,
           let url = relocationMap[PTRouter.urlKey] as? String,
           let firstMatched = shareInstance.patterns.first(where: { $0.patternString == url }) {
            // 命中重定向
            matched = firstMatched
            if let relocationUserInfo = relocationMap[PTRouter.userInfoKey] as? [String: Any] {
                matchUserInfo = relocationUserInfo
            }
        } else {
            // 2. 正则引擎核心匹配逻辑
            let isWebURL = shareInstance.routerWebUrlCheck(urlString)
            var candidatePatterns = [PTRouterPattern]()
            
            if isWebURL {
                candidatePatterns = shareInstance.patterns.filter { $0.patternString == PTRouter.shareInstance.webPath }
                assert(PTRouter.shareInstance.webPath != nil, "h5 jump path cannot be empty")
            } else {
                // 粗略过滤：只保留 scheme 一致的模式，提升后续正则匹配的性能
                candidatePatterns = shareInstance.patterns.filter { $0.patternString.hasPrefix("\(request.sheme)://") }
            }
            
            // 遍历尝试正则匹配
            for pattern in candidatePatterns {
                if isWebURL {
                    matched = pattern
                    break
                } else {
                    // 🌟 调用我们在升级方向三中新写的正则匹配方法
                    let result = pattern.matchResult(for: urlString)
                    if result.matched {
                        matched = pattern
                        // 将正则提取出的路径参数（如 :id=123 提取出的 ["id": "123"]）合并到 queries 中
                        queries.merge(result.queries) { current, _ in current }
                        break
                    }
                }
            }
        }
        
        // 3. 匹配失败处理
        guard let currentPattern = matched else {
            var info: [String: Any] = [PTRouter.matchFailedKey: urlString]
            info.merge(matchUserInfo) { current, _ in current }
            shareInstance.globalOpenFailedHandler?(info)
            shareInstance.logcat?(urlString, .logError, "not matched, please check the router register is all ready")
            return (nil, [:])
        }
        
        // 4. 同步拦截器检查 (如果你保留了原有的拦截器逻辑)
        guard await PTRouter.executeAsyncIntercept(currentPattern.patternString, queries: queries) else {
            return (nil, [:])
        }
        
        // 5. 组装最终返回的参数
        if shareInstance.routerWebUrlCheck(urlString) {
            queries["url"] = urlString
            queries[PTJumpTypeKey] = "\(PTJumpType.push.rawValue)"
        } else {
            queries[PTRouter.requestURLKey] = currentPattern.patternString
        }
        queries.merge(matchUserInfo) { current, _ in current }
        
        return (currentPattern, queries)
    }
    
    func routerWebUrlCheck(_ urlString: String) -> Bool {
        if let url = PTRouter.canOpenURLString(urlString) {
            if url.scheme == "https" || url.scheme == "http" {
                return true
            } else {
                return false
            }
        }
        return false
    }
        
    /// 执行异步拦截检查
    private class func executeAsyncIntercept(_ path: String, queries: [String: Any]) async -> Bool {
        for interceptor in asyncInterceptors {
            // 如果不在白名单内，执行拦截
            if !interceptor.whiteList.contains(path) {
                do {
                    let shouldContinue = try await interceptor.handle(queries: queries)
                    if !shouldContinue { return false }
                } catch {
                    shareInstance.logcat?(path, .logError, "拦截器异常中断: \(error)")
                    return false
                }
            }
        }
        return true
    }

    func routerLoadStatus(_ loadStatus: Bool) {
        routerLoaded = loadStatus
    }
    
    func injectRouterServiceConfig(_ webPath: String?, _ serviceHost: String) {
        self.webPath = webPath
        self.serviceHost = serviceHost
    }
    
    func reloadRouterMap(_ reloadRouterMap: [PTRouterInfo], url: String) -> [String: Any]?  {
        if reloadRouterMap.count > 0 {
            
            var orignRouterUrl = ""
            var replacedRouterUrl = ""
            var replaceParam: [String: Any] = [:]
            
            for rouerInfo in reloadRouterMap {
                
                if (rouerInfo.routerType == PTRouterReloadMapEnum.replace.rawValue) {
                    if (patterns.first(where: { $0.patternString == rouerInfo.orginPath }) != nil) {
                        orignRouterUrl = rouerInfo.orginPath ?? ""
                        replacedRouterUrl = rouerInfo.targetPath ?? ""
                        replaceParam = rouerInfo.params ?? [:]
                    }
                }
            }
            
            if url.hasPrefix(orignRouterUrl) {
                let dict = replaceParam as [String: AnyObject]
                return [PTRouter.urlKey: replacedRouterUrl, PTRouter.userInfoKey: dict] as [String: Any]
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}

//MARK: Convenience
public extension PTRouter {
    
    /// addRouterItem with parasing the dictionary, the class which match the className need inherit the protocol of PTRouterable
    ///
    class func addRouterItem(_ routerItem: RouteItem) {
        addRouterItem(routerItem.path, classString: routerItem.className)
    }
    
    /// addRouterItem with parasing the dictionary, the class which match the className need inherit the protocol of PTRouterable
    ///
    /// - Parameter dictionary: [patternString: className]
    class func addRouterItem(_ dictionary: [String: String]) {
        dictionary.forEach { (key: String, value: String) in
            addRouterItem(key, classString: value)
        }
    }
    
    /// convienience addRouterItem with className
    ///
    /// - Parameters:
    ///   - patternString: register urlstring
    ///   - priority:
    ///   - classString: the class which match the className need inherit the protocol of PTRouterable
    class func addRouterItem(patternString: String, priority: uint = 0, classString: String) {
        let clz: AnyClass? = classString.trimmingCharacters(in: CharacterSet.whitespaces).matchClass()
        if let _ = clz as? PTRouterable.Type {
            self.addRouterItem(patternString.trimmingCharacters(in: CharacterSet.whitespaces), classString: classString, priority: priority)
        } else {
            if let currentCls = clz, currentCls is PTRouterableProxy.Type {
                self.addRouterItem(patternString.trimmingCharacters(in: CharacterSet.whitespaces), classString: classString, priority: priority)
            } else {
                shareInstance.logcat?(patternString, .logError, "\(classString) register router error， please implementation the PTRouterable Protocol")
                assert(clz as? PTRouterable.Type != nil, "register router error， please implementation the PTRouterable Protocol")
            }
        }
    }

    /// addRouterItem
    ///
    /// - Parameters:
    ///   - patternString: register urlstring
    ///   - priority: match priority, sort by inverse order
    ///   - handle: block of refister URL
    class func addRouterItem(_ patternString: String, classString: String, priority: uint = 0) {
        shareInstance.addRouterItem(patternString.trimmingCharacters(in: CharacterSet.whitespaces), classString: classString, priority: priority)
    }
    
    /// addFailedHandel
    class func globalOpenFailedHandler(_ handel: @escaping FailedHandleBlock) {
        shareInstance.globalOpenFailedHandler(handel)
    }
    
    /// LazyRegister
    class func lazyRegisterRouterHandle(_ handel: @escaping LazyRegisterHandleBlock) {
        shareInstance.lazyRegisterRouterHandle(handel)
    }
    
    /// addRouterItemLogHandle
    class func logcat(_ handle: @escaping RouterLogHandleBlock) {
        shareInstance.logcat(handle)
    }
    
    /// addRouterItemLogHandle
    class func customJumpAction(_ handle: @escaping CustomJumpActionClouse) {
        shareInstance.customJumpAction(handle)
    }

    /// removeRouter by register urlstring
    ///
    /// - Parameter patternString: register urlstring
    class func removeRouter(_ patternString: String) {
        shareInstance.removeRouter(patternString.trimmingCharacters(in: CharacterSet.whitespaces))
    }
    
    /// Check whether register for url
    ///
    /// - Parameter urlString: real request urlstring
    /// - Returns: whether register
    class func canOpenURL(_ urlString: String) async -> Bool {
        await shareInstance.canOpenURL(urlString.trimmingCharacters(in: CharacterSet.whitespaces))
    }
    
    /// request for url
    ///
    /// - Parameters:
    ///   - urlString: real request urlstring
    ///   - userInfo: custom userInfo, could contain Object
    /// - Returns: response for request, contain pattern and queries
    class func requestURL(_ urlString: String, userInfo: [String: Any] = [String: Any]()) async -> RouteResponse {
        await shareInstance.requestURL(urlString.trimmingCharacters(in: CharacterSet.whitespaces), userInfo: userInfo)
    }
    
    // injectRouterServiceConfig
    class func injectRouterServiceConfig(_ webPath: String?, _ serviceHost: String) {
        return shareInstance.injectRouterServiceConfig(webPath, serviceHost)
    }
    
    /// Is the route loaded
    /// - Parameter loadStatus:  router paths loadStatus
    class func routerLoadStatus(_ loadStatus: Bool) {
        return shareInstance.routerLoadStatus(loadStatus)
    }
}

//MARK: Generate
// constants
public extension PTRouter {
    static let patternKey = "patternKey"
    static let requestURLKey = "requestURLKey"
    static let matchFailedKey = "matchFailedKey"
    static let urlKey = "url"
    static let userInfoKey = "userInfo"
}

// 跳转方式
@objc public enum PTJumpType: Int {
    case modal
    case push
    case popToTaget
    case windowNavRoot
    case modalDismissBeforePush
    case showTab
}

// 动态路由调用方法返回类型
@objc public enum PTRouterFunctionResultType: Int {
    case voidType   // 无返回值类型
    case valueType  // 值类型
    case referenceType // 引用类型
}

/// 远端下发路由数据
@objc public enum PTRouterReloadMapEnum: Int {
    case none
    case replace
    case add
    case delete
    case reset
}

// 日志类型
@objc public enum PTRouterLogType: Int {
    case logNormal
    case logError
}

public struct RouteItem {
    
    public var path: String = ""
    public var className: String = ""
    public var action: String = ""
    public var descriptions: String = ""
    public var params: [String: Any] = [:]
    
    public init(path: String, className: String, action: String = "", descriptions: String = "", params: [String: Any] = [:]) {
        self.path = path
        self.className = className
        self.action = action
        self.descriptions = descriptions
        self.params = params
    }
}

extension PTRouter {
    
    // MARK: - Convenience method
    public class func generate(_ patternString: String, params: [String: Any] = [String: Any](), jumpType: PTJumpType) -> (String, [String: Any]) {
        
        if let url = URL(string: patternString) {
            let orginParams = url.urlParameters ?? [String: Any]()
            var queries = params
            queries[PTJumpTypeKey] = "\(jumpType.rawValue)"
            
            for (key, value) in orginParams.reversed() {
                queries[key] = value
            }
            return (patternString, queries)
        }
        
        return ("", [String: Any]())
    }
    
}

public protocol CustomRouterInfo {
    static var patternString: String { get }
    static var routerClass: String { get }
    var params: [String: Any] { get }
    var jumpType: PTJumpType { get }
}

extension CustomRouterInfo {
    public var requiredURL: (String, [String: Any]) {
        PTRouter.generate(Self.patternString, params: params, jumpType: jumpType)
    }
}

// MARK: - 解决 Swift 原生不支持解析 Any 的神器
/// 这是一个递归的类型擦除解析器，专门用来处理下发 JSON 中不可预知的 [String: Any]
public struct PTAnyDecodable: Decodable {
    public let value: Any

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // 按照从精确到宽泛的顺序尝试解析
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([PTAnyDecodable].self) {
            // 如果是数组，递归解包
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: PTAnyDecodable].self) {
            // 如果是字典，递归解包
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "PTAnyDecodable 遇到无法解析的类型")
        }
    }
}

public struct PTRouterInfo: Decodable {
    public var targetPath: String?
    public var orginPath: String?
    public var routerType: Int = 0
    public var path: String?
    public var className: String?
    
    // ⚠️ 外部依然保持 [String: Any] 的便利性，不需要让业务方知道 PTAnyDecodable 的存在
    public var params: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case targetPath
        case orginPath
        case routerType
        case path
        case className
        case params
    }
    
    public init() {}
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        targetPath = try container.decodeIfPresent(String.self, forKey: .targetPath)
        orginPath = try container.decodeIfPresent(String.self, forKey: .orginPath)
        routerType = try container.decode(Int.self, forKey: .routerType)
        path = try container.decodeIfPresent(String.self, forKey: .path)
        className = try container.decodeIfPresent(String.self, forKey: .className)
        
        // 核心改造点：通过 PTAnyDecodable 作为跳板，安全地将 JSON 解析为 [String: Any]
        if let anyDict = try container.decodeIfPresent([String: PTAnyDecodable].self, forKey: .params) {
            // 剥去包装，还原本质数据
            self.params = anyDict.mapValues { $0.value }
        }
    }
}

//MARK: Jump
//MARK: extension of viewcontroller jump for PTRouter
extension PTRouter {
    
    class func processParameter(_ parameter: Any) -> Int? {
        if let intValue = parameter as? Int {
            return intValue
        } else if let stringValue = parameter as? String, let intValue = Int(stringValue) {
            return intValue
        } else {
            return 0
        }
    }
    
    @discardableResult
    @MainActor
    public class func openURLVC(_ urlString: String, userInfo: [String: Any] = [:]) async throws -> UIViewController {
        
        // 1. 拦截器检查
        let canContinue = await executeAsyncIntercept(urlString, queries: userInfo)
        guard canContinue else {
            // 被拦截器截断，抛出具体异常
            throw PTRouterError.interceptorBlocked(reason: "匹配到拦截白名单外的规则")
        }
        
        // 2. 匹配 URL
        let response = await PTRouter.matchURL(urlString, userInfo: userInfo)
        guard let pattern = response.pattern else {
            throw PTRouterError.notFound(url: urlString)
        }
        
        let queries = response.queries
        
        // 解析 JumpType
        var resultJumpType: PTJumpType = .push
        if let typeString = queries[PTJumpTypeKey] as? String,
           let jumpType = PTJumpType(rawValue: Int(typeString) ?? 1) {
            resultJumpType = jumpType
        }
        
        // 3. 解析类名
        guard let vcClass = NSClassFromString(pattern.classString) as? UIViewController.Type else {
            shareInstance.logcat?(urlString, .logError, "解析类名失败: \(pattern.classString)")
            throw PTRouterError.invalidClass(className: pattern.classString)
        }
        
        // 4. 实例化 VC
        let resultVC: UIViewController
        if let routableClass = vcClass as? PTRoutableController.Type {
            resultVC = routableClass.init(routerParams: queries) as! UIViewController
        } else {
            resultVC = vcClass.init()
            _ = resultVC.setPropertyParameter(queries)
        }
        
        // 5. 执行跳转
        jump(jumpType: resultJumpType, vc: resultVC, queries: queries)
        
        return resultVC
    }

    @discardableResult
    @MainActor // 确保 UI 跳转在主线程
    public class func openURL(_ urlString: String, userInfo: [String: Any] = [:]) async throws -> Any? {
        // 1. 执行异步拦截检查
        let canContinue = await executeAsyncIntercept(urlString, queries: userInfo)
        guard canContinue else {
            throw PTRouterError.interceptorBlocked(reason: "匹配到拦截白名单外的规则")
        }
        
        // 2. 原有的逻辑（调用我们之前重构过的底层逻辑）
        return await self.openCacheRouter((urlString, userInfo))
    }

    @discardableResult
    public class func openURL(_ urlString: String, userInfo: [String: Any] = [String: Any](), complateHandler: ComplateHandler = nil) async throws -> Any? {
        if urlString.isEmpty {
            throw PTRouterError.notFound(url: urlString)
        }
        if !shareInstance.routerLoaded {
            return shareInstance.lazyRegisterHandleBlock?(urlString, userInfo)
        } else {
            return await openCacheRouter((urlString, userInfo), complateHandler: complateHandler)
        }
    }
    
    @discardableResult
    public class func openURL(_ uriTuple: (String, [String: Any]), complateHandler: ComplateHandler = nil) async -> Any? {
        if !shareInstance.routerLoaded {
            return shareInstance.lazyRegisterHandleBlock?(uriTuple.0, uriTuple.1)
        } else {
            return await openCacheRouter(uriTuple, complateHandler: complateHandler)
        }
    }
    
    @discardableResult
    public class func openWebURL(_ uriTuple: (String, [String: Any])) async -> Any? {
        await PTRouter.openURL(uriTuple)
    }
    
    @discardableResult
    public class func openWebURL(_ urlString: String,
                                 userInfo: [String: Any] = [String: Any]()) async -> Any? {
        await PTRouter.openURL((urlString, userInfo))
    }
    
    
    public class func openCacheRouter(_ uriTuple: (String, [String: Any]), complateHandler: ComplateHandler = nil) async -> Any? {
        
        if uriTuple.0.isEmpty {
            return nil
        }
        
        if uriTuple.0.contains(shareInstance.serviceHost) {
            return routerService(uriTuple)
        } else {
            return await routerJump(uriTuple, complateHandler: complateHandler)
        }
    }
    
    // 重构你的 routerJump 方法
    public class func routerJump(_ uriTuple: (String, [String: Any]), complateHandler: ComplateHandler = nil) async -> Any? {
        
        let response = await PTRouter.requestURL(uriTuple.0, userInfo: uriTuple.1)
        let queries = response.queries
        
        // 解析 JumpType
        var resultJumpType: PTJumpType = .push
        if let typeString = queries[PTJumpTypeKey] as? String,
           let jumpType = PTJumpType(rawValue: Int(typeString) ?? 1) {
            resultJumpType = jumpType
        }
        
        guard let className = response.pattern?.classString,
              let vcClass = NSClassFromString(className) as? UIViewController.Type else {
            shareInstance.logcat?(uriTuple.0 , .logError, "解析类名失败或类不存在")
            return nil
        }
        
        let resultVC: UIViewController
        
        // 【核心优化点】：判断是否实现了安全的传参协议
        if let routableClass = vcClass as? PTRoutableController.Type {
            // 走现代 Swift 安全初始化方案
            resultVC = routableClass.init(routerParams: queries) as! UIViewController
            shareInstance.logcat?(uriTuple.0, .logNormal, "使用 PTRoutableController 协议安全初始化")
        } else {
            // 降级兜底方案：走原有的旧逻辑 (init() + KVC)
            resultVC = await vcClass.init()
            _ = resultVC.setPropertyParameter(queries)
            shareInstance.logcat?(uriTuple.0, .logNormal, "降级使用 KVC 赋值初始化")
        }
        
        // 执行跳转
        jump(jumpType: resultJumpType, vc: resultVC, queries: queries)
        
        complateHandler?(queries, resultVC)
        return resultVC
    }
    
    public class func jump(jumpType: PTJumpType, vc: UIViewController, queries: [String: Any]) {
        DispatchQueue.main.async {
            if let action = shareInstance.customJumpAction {
                action(jumpType, vc)
            } else {
                switch jumpType {
                case .modal:
                    PTUtils.modal(vc)
                case .push:
                    PTUtils.push(vc)
                case .popToTaget:
                    PTUtils.popToVC(ofType: type(of: vc))
                case .windowNavRoot:
                    PTUtils.pusbWindowNavRoot(vc)
                case .modalDismissBeforePush:
                    PTUtils.modalDismissBeforePush(vc)
                case .showTab:
                    showTabBar(queries: queries)
                }
            }
        }
    }
    
    private class func showTabBar(queries: [String: Any]) {
        let selectIndex: Int = processParameter(queries[PTRouterTabBarSelecIndex] ?? 0) ?? 0
        let tabVC = UIApplication.shared.delegate?.window??.rootViewController
        if let tabVC = tabVC as? UITabBarController {
            let navVC: UINavigationController? = PTUtils.getTopViewController(nil)?.navigationController
            if let navigationController = navVC {
                navigationController.popToRootViewController(animated: false)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    tabVC.selectedIndex = selectIndex
                    if let topViewController = PTUtils.getTopViewController(nil), let navController = topViewController.navigationController {
                        navController.popToRootViewController(animated: false)
                    }
                }
            }
        }
    }
    
    // 修改 PTRouter.routerService 方法：
    // 服务调用 (重构版)
    public class func routerService(_ uriTuple: (String, [String: Any])) -> Any? {
        let request = PTRouterRequest(uriTuple.0)
        let queries = request.queries
        
        // 1. 校验 protocol 和 method
        guard let protocols = queries["protocol"] as? String,
              let methods = queries["method"] as? String else {
            assert(queries["protocol"] != nil, "The protocol name is empty")
            assert(queries["method"] != nil, "The method name is empty")
            shareInstance.logcat?(uriTuple.0, .logError, "protocol or method is empty，Unable to initiate service")
            return nil
        }
        
        shareInstance.logcat?(uriTuple.0, .logNormal, "通过 ActionMapper 动态派发服务: \(protocols) -> \(methods)")
        
        // 2. 核心改造：直接把活儿丢给 Mapper 即可！
        // 不再需要判断 PTRouterFunctionResultType
        // 不再需要 takeUnretainedValue / takeRetainedValue
        return PTServiceActionMapper.shared.execute(
            protocolName: protocols,
            methodName: methods,
            param: uriTuple.1[PTRouterIvar1Key],
            otherParam: uriTuple.1[PTRouterIvar2Key]
        )
    }
    
    /// ⚠️ 改造点 1：返回值从 Unmanaged<AnyObject>? 强制改为了 Any?
    /// 这个修改极其重要！Swift 的闭包会自动管理内存，不再需要手动处理引用计数。
    @available(*, deprecated, message: "请优先使用 PTRouterServiceManager 直接调用协议。如果必须通过 URL 动态调用，请确保已在 PTServiceActionMapper 中注册")
    public class func performTarget(protocolName: String,
                                    actionName: String,
                                    param: Any? = nil,
                                    otherParam: Any? = nil,
                                    classMethod: Bool = false) -> Any? {
        
        // 核心改造：不再使用 class_getInstanceMethod 和 performSelector
        // 而是直接把调用请求转发给我们的 ActionMapper
        return PTServiceActionMapper.shared.execute(
            protocolName: protocolName,
            methodName: actionName,
            param: param,
            otherParam: otherParam
        )
    }
    
    /// ⚠️ 改造点 2：无返回值的调用
    @available(*, deprecated, message: "请优先使用 PTRouterServiceManager 直接调用协议。")
    public class func performTargetVoidType(protocolName: String,
                                            actionName: String,
                                            param: Any? = nil,
                                            otherParam: Any? = nil,
                                            classMethod: Bool = false) {
        
        // 同样转发给 ActionMapper，并丢弃可能的返回值
        _ = PTServiceActionMapper.shared.execute(
            protocolName: protocolName,
            methodName: actionName,
            param: param,
            otherParam: otherParam
        )
    }
}

//MARK: Service
public extension PTRouter {
    // MARK: - Register With Service Name
    /// 通过服务名称(named)注册LAServiceCreator
    /// - Parameters:
    ///   - named: 服务名称
    ///   - creator: 服务构造者
    class func registerService(named: String, creator: @escaping PTServiceCreator) {
        Task {
            await PTRouterServiceManager.shared.registerService(named: named, creator: creator)
        }
    }
    
    /// 通过服务名称(named)注册一个服务实例 (存在缓存中)
    /// - Parameters:
    ///   - named: 服务名称
    ///   - instance: 服务实例
    class func registerService(named: String, instance: Any) {
        Task {
            await PTRouterServiceManager.shared.registerService(named: named, instance: instance)
        }
    }
    
    /// 通过服务名称(named)注册LAServiceCreator
    /// - Parameters:
    ///   - named: 服务名称
    ///   - lazyCreator: 延迟实例化构造者 (如：```registerService(named: "A", lazyCreator: A())```)
    class func registerService(named: String, lazyCreator: @escaping @autoclosure PTServiceCreator) {
        Task {
            await PTRouterServiceManager.shared.registerService(named: named, lazyCreator: lazyCreator)
        }
    }
    
    // MARK: - Register With Service Type
    /// 通过服务接口注册LAServiceCreator
    /// - Parameters:
    ///   - service: 服务接口
    ///   - creator: 服务构造者
    class func registerService<Service>(_ service: Service.Type, creator: @escaping () -> Service) {
        Task {
            await PTRouterServiceManager.shared.registerService(service, creator: creator)
        }
    }
    
    /// 通过服务接口注册LAServiceCreator
    /// - Parameters:
    ///   - service: 服务接口
    ///   - lazyCreator: 延迟实例化构造者 (如：```registerService(named: "A", lazyCreator: A())```)
    class func registerService<Service>(_ service: Service.Type, lazyCreator: @escaping @autoclosure () -> Service) {
        Task {
            await PTRouterServiceManager.shared.registerService(service, lazyCreator: lazyCreator())
        }
    }
    
    /// 通过服务接口注册一个服务实例 (存在缓存中)
    /// - Parameters:
    ///   - service: 服务接口
    ///   - instance: 服务实例
    class func registerService<Service>(_ service: Service.Type, instance: Service) {
        Task {
            await PTRouterServiceManager.shared.registerService(service, instance: instance)
        }
    }
}

public extension PTRouter {
    
    /// 根据服务名称创建服务（如果缓存中已有服务实例，则不需要创建）
    /// - Parameters:
    ///   - named: 服务名称
    ///   - shouldCache: 是否需要缓存
    @discardableResult
    class func createService(named: String, shouldCache: Bool = true) -> Any? {
        Task {
            await PTRouterServiceManager.shared.createService(named: named)
        }
    }
    
    /// 根据服务接口创建服务（如果缓存中已有服务实例，则不需要创建）
    /// - Parameters:
    ///   - service: 服务接口
    ///   - shouldCache: 是否需要缓存
    @discardableResult
    class func createService<Service>(_ service: Service.Type) async -> Service? {
        // 直接调用底层 actor 极其安全的强类型泛型方法
        return await PTRouterServiceManager.shared.getService(service)
    }

    /// 通过服务名称获取服务
    /// - Parameter named: 服务名称
    @discardableResult
    class func getService(named: String) -> Any? {
        Task {
            await PTRouterServiceManager.shared.getService(named: named)
        }
    }
    
    /// 通过服务接口获取服务
    /// - Parameter service: 服务接口
    @discardableResult
    class func getService<Service>(_ service: Service.Type) async -> Service? {
        return await PTRouterServiceManager.shared.getService(service)
    }
}

public extension PTRouter {
    class func routeJump(vcName:String,scheme:String) async {
        let relocationMap: NSDictionary = ["routerType": 2 ,"className": vcName, "path": scheme]
        let data = try! JSONSerialization.data(withJSONObject: relocationMap, options: [])
        let routeReMapInfo = try! JSONDecoder().decode(PTRouterInfo.self, from: data)
        PTRouterManager.addRelocationHandle(routerMapList: [routeReMapInfo])
        Task  {
            do {
                let _ = try await PTRouter.openURL(scheme)
            } catch {
                PTNSLogConsole("\(error)")
            }
        }
    }
}
