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
    private var interceptors = [PTRouterInterceptor]()
    
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
        let pattern = PTRouterPattern.init(patternString.trimmingCharacters(in: CharacterSet.whitespaces), classString, priority: priority)
        patterns.append(pattern)
        patterns.sort { $0.priority > $1.priority }
    }

    func addRouterInterceptor(_ whiteList: [String] = [String](),
                              priority: uint = 0,
                              handle: @escaping PTRouterInterceptor.InterceptorHandleBlock) {
        let interceptor = PTRouterInterceptor.init(whiteList, priority: priority, handle: handle)
        interceptors.append(interceptor)
        interceptors.sort { $0.priority > $1.priority }
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
    
    func canOpenURL(_ urlString: String) -> Bool {
        if urlString.isEmpty {
            return false
        }
        return matchURL(urlString.trimmingCharacters(in: CharacterSet.whitespaces)).pattern != nil
    }
    
    func requestURL(_ urlString: String, userInfo: [String: Any] = [String: Any]()) -> RouteResponse {
        matchURL(urlString.trimmingCharacters(in: CharacterSet.whitespaces), userInfo: userInfo)
    }
    
    // MARK: - Private method
    private func matchURL(_ urlString: String, userInfo: [String: Any] = [String: Any]()) -> RouteResponse {
        
        let request = PTRouterRequest.init(urlString)
        var queries = request.queries
        var matched: PTRouterPattern?
        var matchUserInfo: [String: Any] = userInfo
        let relocationMap = reloadRouterMap(PTRouter.shareInstance.reloadRouterMap, url: urlString)
        if let relocationMap = relocationMap,
           let url = relocationMap[PTRouter.urlKey] as? String,
           let firstMatched = patterns.filter({ $0.patternString == url }).first {
            //relocation
            matched = firstMatched
            if let relocationUserInfo =  relocationMap[PTRouter.userInfoKey] as? [String: Any] {
                matchUserInfo = relocationUserInfo
            }
        } else {
            var matchedPatterns = [PTRouterPattern]()
            
            if routerWebUrlCheck(urlString) {
                matchedPatterns = patterns.filter{ ($0.patternString == PTRouter.shareInstance.webPath)}
                assert(PTRouter.shareInstance.webPath != nil, "h5 jump path cannot be empty")
            } else {
                //filter the scheme and the count of paths not matched
                matchedPatterns = patterns.filter{ $0.sheme == request.sheme && $0.patternPaths.count == request.paths.count }
            }
            
            for pattern in matchedPatterns {
                let result = matchPattern(request, pattern: pattern)
                if result.matched || routerWebUrlCheck(urlString) {
                    matched = pattern
                    queries.routerCombine(result.queries)
                    break
                }
            }
        }
        
        guard let currentPattern = matched else {
            //not matched
            var info = [PTRouter.matchFailedKey  : urlString as Any]
            info.routerCombine(matchUserInfo)
            globalOpenFailedHandler?(info)
            logcat?(urlString, .logError, "not matched, please check the router register is all readly")
            assert(matched != nil, "not matched, please check the router register is all readly")
            return (nil, [String: Any]())
        }
        
        guard routerIntercept(currentPattern.patternString, queries: queries) else {
            return (nil, [String: Any]())
        }
        
        if routerWebUrlCheck(urlString) {
            queries.routerCombine(["url" : urlString as Any])
            queries.routerCombine([PTJumpTypeKey: "\(PTJumpType.push.rawValue)" as Any])
            queries.routerCombine(matchUserInfo)
        } else {
            queries.routerCombine([PTRouter.requestURLKey  : currentPattern.matchString as Any])
            queries.routerCombine(matchUserInfo)
        }
        
        return (currentPattern, queries)
    }
    
    private func matchPattern(_ request: PTRouterRequest, pattern: PTRouterPattern) -> MatchResult {
        
        var requestPaths = request.paths
        var pathQuery = [String: Any]()
        // replace params
        pattern.paramsMatchDict.forEach({ (name, index) in
            let requestPathQueryValue = requestPaths[index] as Any
            pathQuery[name] = requestPathQueryValue
            requestPaths[index] = PTRouterPattern.PatternPlaceHolder
        })
        
        let matchString = requestPaths.joined(separator: "/")
        if matchString == pattern.matchString {
            return (true, pathQuery)
        } else {
            return (false, [String: Any]())
        }
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
    
    // Intercep the request and return whether should continue
    private func routerIntercept(_ matchedPatternString: String, queries: [String: Any]) -> Bool {
        
        for interceptor in interceptors where !interceptor.whiteList.contains(matchedPatternString) {
            if !interceptor.handle(queries) {
                // interceptor handle return true will continue interceptor
                return false
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

    /// addRouterItem
    ///
    /// - Parameters:
    ///   - whiteList: whiteList for intercept
    ///   - priority: match priority, sort by inverse order
    ///   - handle: block of interception
    class func addRouterInterceptor(_ whiteList: [String] = [String](), priority: uint = 0, handle: @escaping PTRouterInterceptor.InterceptorHandleBlock) {
        shareInstance.addRouterInterceptor(whiteList, priority: priority, handle: handle)
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
    class func canOpenURL(_ urlString: String) -> Bool {
        shareInstance.canOpenURL(urlString.trimmingCharacters(in: CharacterSet.whitespaces))
    }
    
    /// request for url
    ///
    /// - Parameters:
    ///   - urlString: real request urlstring
    ///   - userInfo: custom userInfo, could contain Object
    /// - Returns: response for request, contain pattern and queries
    class func requestURL(_ urlString: String, userInfo: [String: Any] = [String: Any]()) -> RouteResponse {
        shareInstance.requestURL(urlString.trimmingCharacters(in: CharacterSet.whitespaces), userInfo: userInfo)
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

public struct PTRouterInfo: Decodable {
    public init() {}
    
    public var targetPath: String?
    public var orginPath: String?
    public var routerType: Int = 0 // 1: 表示替换或者修复客户端代码path错误 2: 新增路由path 3:删除路由 4: 重置路由
    public var path: String? // 新的路由地址
    public var className: String? // 路由地址对应的界面
    public var params: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case targetPath
        case orginPath
        case path
        case className
        case routerType
        case params
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        targetPath = try container.decodeIfPresent(String.self, forKey: CodingKeys.targetPath)
        orginPath = try container.decodeIfPresent(String.self, forKey: CodingKeys.orginPath)
        routerType = try container.decode(Int.self, forKey: CodingKeys.routerType)
        path = try container.decodeIfPresent(String.self, forKey: CodingKeys.path)
        className = try container.decodeIfPresent(String.self, forKey: CodingKeys.className)
        params = try container.decodeIfPresent(Dictionary<String, Any>.self, forKey: CodingKeys.params)
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
    public class func openURL(_ urlString: String, userInfo: [String: Any] = [String: Any](), complateHandler: ComplateHandler = nil) -> Any? {
        if urlString.isEmpty {
            return nil
        }
        if !shareInstance.routerLoaded {
            return shareInstance.lazyRegisterHandleBlock?(urlString, userInfo)
        } else {
            return openCacheRouter((urlString, userInfo), complateHandler: complateHandler)
        }
    }
    
    @discardableResult
    public class func openURL(_ uriTuple: (String, [String: Any]), complateHandler: ComplateHandler = nil) -> Any? {
        if !shareInstance.routerLoaded {
            return shareInstance.lazyRegisterHandleBlock?(uriTuple.0, uriTuple.1)
        } else {
            return openCacheRouter(uriTuple, complateHandler: complateHandler)
        }
    }
    
    @discardableResult
    public class func openWebURL(_ uriTuple: (String, [String: Any])) -> Any? {
        PTRouter.openURL(uriTuple)
    }
    
    @discardableResult
    public class func openWebURL(_ urlString: String,
                                 userInfo: [String: Any] = [String: Any]()) -> Any? {
        PTRouter.openURL((urlString, userInfo))
    }
    
    
    public class func openCacheRouter(_ uriTuple: (String, [String: Any]), complateHandler: ComplateHandler = nil) -> Any? {
        
        if uriTuple.0.isEmpty {
            return nil
        }
        
        if uriTuple.0.contains(shareInstance.serviceHost) {
            return routerService(uriTuple)
        } else {
            return routerJump(uriTuple, complateHandler: complateHandler)
        }
    }

    // 路由跳转
    public class func routerJump(_ uriTuple: (String, [String: Any]), complateHandler: ComplateHandler = nil) -> Any? {
        
        let response = PTRouter.requestURL(uriTuple.0, userInfo: uriTuple.1)
        let queries = response.queries
        var resultJumpType: PTJumpType = .push
        
        if let typeString = queries[PTJumpTypeKey] as? String,
           let jumpType = PTJumpType.init(rawValue: Int(typeString) ?? 1) {
            resultJumpType = jumpType
        } else {
            resultJumpType = .push
        }
        
        let instanceVC = PTRouterDynamicParamsMapping.shared.routerGetInstance(with: response.pattern?.classString ?? "").instanceObject as? NSObject
        _ = instanceVC?.setPropertyParameter(queries)

        var resultVC: UIViewController?
        
        if let vc = instanceVC as? UIViewController {
            resultVC = vc
        }

        if let jumpVC = resultVC {
            jump(jumpType: resultJumpType, vc: jumpVC,queries:queries)
            let className = NSStringFromClass(type(of: jumpVC))
            shareInstance.logcat?(uriTuple.0, .logNormal, "resultVC: \(className)")
        } else {
            shareInstance.logcat?(uriTuple.0 , .logError, "resultVC: nil")
        }
        
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
                    PTUtils.popToTargetVC(vcClass: type(of: vc))
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
    
    // 服务调用
    public class func routerService(_ uriTuple: (String, [String: Any])) -> Any? {
        let request = PTRouterRequest.init(uriTuple.0)
        let queries = request.queries
        guard let protocols = queries["protocol"] as? String,
              let methods = queries["method"] as? String else {
            assert(queries["protocol"] != nil, "The protocol name is empty")
            assert(queries["method"] != nil, "The method name is empty")
            shareInstance.logcat?(uriTuple.0, .logError, "protocol or method is empty，Unable to initiate service")
            return nil
        }
        
        //为了使用方便，针对1个参数或2个参数，依旧可以按照ivar1，ivar2进行传递，自动匹配。对于没有ivar1参数的,但是方法中必须有参数的，将queries赋值作为ivar1。
        shareInstance.logcat?(uriTuple.0, .logNormal, "")
        
        if let functionResultType = uriTuple.1[PTRouterFunctionResultKey] as? Int {
            if functionResultType == PTRouterFunctionResultType.voidType.rawValue {
                performTargetVoidType(protocolName: protocols, actionName: methods, param: uriTuple.1[PTRouterIvar1Key], otherParam: uriTuple.1[PTRouterIvar2Key])
                return nil
            } else if functionResultType == PTRouterFunctionResultType.valueType.rawValue {
                let exectueResult = performTarget(protocolName: protocols, actionName: methods, param: uriTuple.1[PTRouterIvar1Key], otherParam: uriTuple.1[PTRouterIvar2Key])
                return exectueResult?.takeUnretainedValue()
            } else if functionResultType == PTRouterFunctionResultType.referenceType.rawValue {
                let exectueResult = performTarget(protocolName: protocols, actionName: methods, param: uriTuple.1[PTRouterIvar1Key], otherParam: uriTuple.1[PTRouterIvar2Key])
                return exectueResult?.takeRetainedValue()
            }
        }
        return nil
    }
    
    //实现路由转发协议-值类型与引用类型
    public class func performTarget(protocolName: String,
                                    actionName: String,
                                    param: Any? = nil,
                                    otherParam: Any? = nil,
                                    classMethod: Bool = false) -> Unmanaged<AnyObject>? {
        if classMethod {
            let serviceClass = PTRouterServiceManager.default.servicesCache[protocolName] as? AnyObject ?? NSObject()
            assert(PTRouterServiceManager.default.servicesCache[protocolName] != nil, "No corresponding service found")
            let selector  = NSSelectorFromString(actionName)
            guard let _ = class_getClassMethod(serviceClass as? AnyClass, selector) else {
                assert(class_getClassMethod(serviceClass as? AnyClass, selector) != nil, "No corresponding class method found")
                shareInstance.logcat?("\(protocolName)->\(actionName)", .logError, "No corresponding class method found")
                return nil
            }
            return serviceClass.perform(selector, with: param, with: otherParam)
        } else {
            let serviceClass = PTRouterServiceManager.default.servicesCache[protocolName] as? AnyObject ?? NSObject()
            let selector = NSSelectorFromString(actionName)
            guard let _ = class_getInstanceMethod(type(of: serviceClass), selector) else {
                assert(class_getInstanceMethod(serviceClass as? AnyClass, selector) != nil, "No corresponding instance method found")
                shareInstance.logcat?("\(protocolName)->\(actionName)", .logError, "No corresponding instance method found")
                return nil
            }
            return serviceClass.perform(selector, with: param, with: otherParam)
        }
    }
    
    //实现路由转发协议-无返回值类型
    public class func performTargetVoidType(protocolName: String,
                                            actionName: String,
                                            param: Any? = nil,
                                            otherParam: Any? = nil,
                                            classMethod: Bool = false) {
        if classMethod {
            let serviceClass = PTRouterServiceManager.default.servicesCache[protocolName] as? AnyObject ?? NSObject()
            assert(PTRouterServiceManager.default.servicesCache[protocolName] != nil, "No corresponding service found")
            let selector  = NSSelectorFromString(actionName)
            guard let _ = class_getClassMethod(serviceClass as? AnyClass, selector) else {
                assert(class_getClassMethod(serviceClass as? AnyClass, selector) != nil, "No corresponding class method found")
                shareInstance.logcat?("\(protocolName)->\(actionName)", .logError, "No corresponding class method found")
                return
            }
            _ = serviceClass.perform(selector, with: param, with: otherParam)
        } else {
            let serviceClass = PTRouterServiceManager.default.servicesCache[protocolName] as? AnyObject ?? NSObject()
            let selector = NSSelectorFromString(actionName)
            guard let _ = class_getInstanceMethod(type(of: serviceClass), selector) else {
                assert(class_getInstanceMethod(serviceClass as? AnyClass, selector) != nil, "No corresponding instance method found")
                shareInstance.logcat?("\(protocolName)->\(actionName)", .logError, "No corresponding instance method found")
                return
            }
            _ = serviceClass.perform(selector, with: param, with: otherParam)
        }
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
        PTRouterServiceManager.default.registerService(named: named, creator: creator)
    }
    
    /// 通过服务名称(named)注册一个服务实例 (存在缓存中)
    /// - Parameters:
    ///   - named: 服务名称
    ///   - instance: 服务实例
    class func registerService(named: String, instance: Any) {
        PTRouterServiceManager.default.registerService(named: named, instance: instance)
    }
    
    /// 通过服务名称(named)注册LAServiceCreator
    /// - Parameters:
    ///   - named: 服务名称
    ///   - lazyCreator: 延迟实例化构造者 (如：```registerService(named: "A", lazyCreator: A())```)
    class func registerService(named: String, lazyCreator: @escaping @autoclosure PTServiceCreator) {
        PTRouterServiceManager.default.registerService(named: named, lazyCreator: lazyCreator)
    }
    
    // MARK: - Register With Service Type
    /// 通过服务接口注册LAServiceCreator
    /// - Parameters:
    ///   - service: 服务接口
    ///   - creator: 服务构造者
    class func registerService<Service>(_ service: Service.Type, creator: @escaping () -> Service) {
        PTRouterServiceManager.default.registerService(service, creator: creator)
    }
    
    /// 通过服务接口注册LAServiceCreator
    /// - Parameters:
    ///   - service: 服务接口
    ///   - lazyCreator: 延迟实例化构造者 (如：```registerService(named: "A", lazyCreator: A())```)
    class func registerService<Service>(_ service: Service.Type, lazyCreator: @escaping @autoclosure () -> Service) {
        PTRouterServiceManager.default.registerService(service, lazyCreator: lazyCreator())
    }
    
    /// 通过服务接口注册一个服务实例 (存在缓存中)
    /// - Parameters:
    ///   - service: 服务接口
    ///   - instance: 服务实例
    class func registerService<Service>(_ service: Service.Type, instance: Service) {
        PTRouterServiceManager.default.registerService(service, instance: instance)
    }
}

public extension PTRouter {
    
    /// 根据服务名称创建服务（如果缓存中已有服务实例，则不需要创建）
    /// - Parameters:
    ///   - named: 服务名称
    ///   - shouldCache: 是否需要缓存
    @discardableResult
    class func createService(named: String, shouldCache: Bool = true) -> Any? {
        PTRouterServiceManager.default.createService(named: named)
    }
    
    /// 根据服务接口创建服务（如果缓存中已有服务实例，则不需要创建）
    /// - Parameters:
    ///   - service: 服务接口
    ///   - shouldCache: 是否需要缓存
    @discardableResult
    class func createService<Service>(_ service: Service.Type, shouldCache: Bool = true) -> Service? {
        PTRouterServiceManager.default.createService(service)
    }
    
    /// 通过服务名称获取服务
    /// - Parameter named: 服务名称
    @discardableResult
    class func getService(named: String) -> Any? {
        PTRouterServiceManager.default.getService(named: named)
    }
    
    /// 通过服务接口获取服务
    /// - Parameter service: 服务接口
    @discardableResult
    class func getService<Service>(_ service: Service.Type) -> Service? {
        PTRouterServiceManager.default.getService(named: PTRouterServiceManager.serviceName(of: service)) as? Service
    }
}

public extension PTRouter {
    class func routeJump(vcName:String,scheme:String) {
        let relocationMap: NSDictionary = ["routerType": 2 ,"className": vcName, "path": scheme]
        let data = try! JSONSerialization.data(withJSONObject: relocationMap, options: [])
        let routeReMapInfo = try! JSONDecoder().decode(PTRouterInfo.self, from: data)
        PTRouterManager.addRelocationHandle(routerMapList: [routeReMapInfo])
        PTRouter.openURL(scheme)
    }
}
