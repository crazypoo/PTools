//
//  PTRouterManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import UIKit

/// 对于KVO监听，动态创建子类，需要特殊处理
public let NSKVONotifyingPrefix = "NSKVONotifying_"

public class PTRouterManager: NSObject {
    
    static public let shareInstance = PTRouterManager()
    
    // MARK: - 注册路由
    public static func addGloableRouter(_ registerClassPrifxArray: [String], _ urlPath: String, _ userInfo: [String: Any]) -> Any? {
        
        PTRouter.globalOpenFailedHandler { (info) in
            guard let matchFailedKey = info[PTRouter.matchFailedKey] as? String else { return }
            PTNSLogConsole(matchFailedKey)
            PTRouter.shareInstance.logcat?("PTRouter: globalOpenFailedHandler", .logError, "\(matchFailedKey)")
        }
        
        return PTRouterManager.registerRouterMap(registerClassPrifxArray, urlPath, userInfo)
    }
    
    // MARK: -注册web与服务调用
    public static func injectRouterServiceConfig(_ webPath: String?, _ serviceHost: String) {
        PTRouter.injectRouterServiceConfig(webPath, serviceHost)
    }
}

extension PTRouterManager {
    
    /// 类名和枚举值的映射表
    static var pagePathMap: Dictionary = [String: String]()
    static var apiArray = [String]()
    static var classMapArray = [String]()
    static var mapJOSN: Array = [[String: String]]()
    
    // MARK: - 自动注册路由
    public class func registerRouterMap(_ registerClassPrifxArray: [String], _ urlPath: String, _ userInfo: [String: Any]) -> Any? {
        
        let beginRegisterTime = CFAbsoluteTimeGetCurrent()
        
        let expectedClassCount = objc_getClassList(nil, 0)
        let allClasses = UnsafeMutablePointer<AnyClass>.allocate(capacity: Int(expectedClassCount))
        let autoreleasingAllClasses = AutoreleasingUnsafeMutablePointer<AnyClass>(allClasses)
        let actualClassCount: Int32 = objc_getClassList(autoreleasingAllClasses, expectedClassCount)
        
        var resultXLClass = [AnyClass]()
        for i in 0 ..< actualClassCount {
            
            let currentClass: AnyClass = allClasses[Int(i)]
            let fullClassName: String = NSStringFromClass(currentClass.self)
            
            for value in registerClassPrifxArray {
                if (fullClassName.containsSubString(substring: value))  {
                    if (class_getInstanceMethod(currentClass, NSSelectorFromString("methodSignatureForSelector:")) != nil),
                       (class_getInstanceMethod(currentClass, NSSelectorFromString("doesNotRecognizeSelector:")) != nil), let cls =  currentClass as? UIViewController.Type {
                        resultXLClass.append(cls)
                    }
                    
#if DEBUG
                    if let clss = currentClass as? CustomRouterInfo.Type {
                        apiArray.append(clss.patternString)
                        classMapArray.append(clss.routerClass)
                    }
#endif
                }
            }
        }
        
        for i in 0 ..< resultXLClass.count {
            let currentClass: AnyClass = resultXLClass[i]
            if let cls = currentClass as? PTRouterable.Type {
                let fullName: String = NSStringFromClass(currentClass.self)
                
                for s in 0 ..< cls.patternString.count {
                    
                    if fullName.hasPrefix(NSKVONotifyingPrefix) {
                        let range = fullName.index(fullName.startIndex, offsetBy: NSKVONotifyingPrefix.count)..<fullName.endIndex
                        let subString = fullName[range]
                        pagePathMap[cls.patternString[s]] = "\(subString)"
                        PTRouter.addRouterItem(cls.patternString[s], classString: "\(subString)")
                        mapJOSN.append(["path": cls.patternString[s], "class": "\(subString)"])
                    } else {
                        pagePathMap[cls.patternString[s]] = fullName
                        PTRouter.addRouterItem(cls.patternString[s], classString: fullName)
                        mapJOSN.append(["path": cls.patternString[s], "class": fullName])
                    }
                }
            }
        }
        
        let endRegisterTime = CFAbsoluteTimeGetCurrent()
        PTRouter.shareInstance.logcat?("注册路由耗时：\(endRegisterTime - beginRegisterTime)", .logNormal, "")
        PTRouter.routerLoadStatus(true)
#if DEBUG
        PTNSLogConsole(mapJOSN)
        writeRouterMapToFile(mapArray: mapJOSN)
        routerForceRecheck()
#endif
        return PTRouter.openURL(urlPath, userInfo: userInfo)
    }
    
    // MARK: - 自动注册服务
    public class func registerServices() {
        
        let expectedClassCount = objc_getClassList(nil, 0)
        let allClasses = UnsafeMutablePointer<AnyClass>.allocate(capacity: Int(expectedClassCount))
        let autoreleasingAllClasses = AutoreleasingUnsafeMutablePointer<AnyClass>(allClasses)
        let actualClassCount: Int32 = objc_getClassList(autoreleasingAllClasses, expectedClassCount)
        var resultXLClass = [AnyClass]()
        for i in 0 ..< actualClassCount {
            
            let currentClass: AnyClass = allClasses[Int(i)]
            if (class_getInstanceMethod(currentClass, NSSelectorFromString("methodSignatureForSelector:")) != nil),
               (class_getInstanceMethod(currentClass, NSSelectorFromString("doesNotRecognizeSelector:")) != nil),
               let cls = currentClass as? PTRouterServiceProtocol.Type {
                PTNSLogConsole(currentClass)
                resultXLClass.append(cls)
                
                PTRouterServiceManager.default.registerService(named: cls.seriverName, lazyCreator: (cls as! NSObject.Type).init())
            }
        }
    }
    
    // MARK: - 重定向、剔除、新增、重置路由
    public static func addRelocationHandle(routerMapList: [PTRouterInfo] = []) {
        // 数组为空 return
        if routerMapList.count == 0 {
            return
        }
        // 新增的重定向信息转模型
        var currentRouterInfo = [PTRouterInfo]()
        for routerInfoInstance in routerMapList {
            
            if routerInfoInstance.routerType == PTRouterReloadMapEnum.add.rawValue {
                PTRouter.addRouterItem(routerInfoInstance.path ?? "", classString: routerInfoInstance.className ?? "")
            } else if routerInfoInstance.routerType == PTRouterReloadMapEnum.delete.rawValue {
                PTRouter.removeRouter(routerInfoInstance.path ?? "")
            } else if routerInfoInstance.routerType == PTRouterReloadMapEnum.replace.rawValue ||
                        routerInfoInstance.routerType == PTRouterReloadMapEnum.reset.rawValue {
                currentRouterInfo.append(routerInfoInstance)
            }
        }
        // 模型转化后的数组为空 return
        if currentRouterInfo.count == 0 {
            return
        }
        // 老的重定向数据map
        let routerInfoList: [PTRouterInfo] = PTRouter.shareInstance.reloadRouterMap
        var routerInfoMap: [String: PTRouterInfo] = [String: PTRouterInfo]()
        for list in routerInfoList {
            routerInfoMap[list.orginPath ?? ""] = list
        }
        // 数据对比
        // routerType为delete时
        // orginPath与targetPath一致时，删除所有orginPath的重定向数据
        // orginPath与targetPath不一致时，删除原有orginPath的重定向数据，存储新的orginPath数据并把routerType改为add
        for info in currentRouterInfo {
            if info.routerType == PTRouterReloadMapEnum.reset.rawValue {
                // 如果已经存在相同orginPath的数据 需要先remove
                if routerInfoMap[info.orginPath ?? ""] != nil {
                    routerInfoMap.removeValue(forKey: info.orginPath ?? "")
                }
                if info.orginPath != info.targetPath {
                    var routerInfo = info
                    routerInfo.routerType = PTRouterReloadMapEnum.replace.rawValue
                    routerInfoMap[routerInfo.orginPath ?? ""] = routerInfo
                }
            } else if info.routerType == PTRouterReloadMapEnum.replace.rawValue {
                routerInfoMap[info.orginPath ?? ""] = info
            }
        }
        // [String: PTRouterInfo] 转 [PTRouterInfo]
        var resultInfo = [PTRouterInfo]()
        for (_, routerInfo) in routerInfoMap {
            resultInfo.append(routerInfo)
        }
        PTRouter.shareInstance.reloadRouterMap = resultInfo
    }
    
    // MARK: - 客户端强制校验，是否匹配
    public static func routerForceRecheck() {
        let patternArray = Set(pagePathMap.keys)
        let apiPathArray = Set(apiArray)
        let diffArray = patternArray.symmetricDifference(apiPathArray)
        PTNSLogConsole("URL差集：\(diffArray)", error: true)
        PTNSLogConsole("pagePathMap：\(pagePathMap)", error: true)
        assert(diffArray.count == 0, "URL 拼写错误，请确认差集中的url是否匹配")
        
        let patternValueArray = Set(pagePathMap.values)
        let classPathArray = Set(classMapArray)
        let diffClassesArray = patternValueArray.symmetricDifference(classPathArray)
        PTNSLogConsole("classes差集：\(diffClassesArray)", error: true)
        assert(diffClassesArray.count == 0, "classes 拼写错误，请确认差集中的class是否匹配")
    }
    
    // MARK: - 路由映射文件导出
    public static func writeRouterMapToFile(mapArray: [[String: String]]) {
        PTNSLogConsole(mapJOSN)
        let array: NSArray = mapJOSN as NSArray
        
        // 获得沙盒的根路径
        let home = NSHomeDirectory() as NSString
        // 获得Documents路径，使用NSString对象的appendingPathComponent()方法拼接路径
        let plistPath = home.appendingPathComponent("Documents") as NSString
        // 输出plist文件到指定的路径
        let resultPath = "\(plistPath)/routerMap.plist"
        let resultJSONPath = "\(plistPath)/routerMap.json"
        
        PTNSLogConsole("routerMapPlist文件地址：\(resultPath)", error: true)
        PTNSLogConsole("routerMapJSON文件地址：\(resultJSONPath)", error: true)
        array.write(toFile: resultPath, atomically: true)
        
        let data = try! JSONSerialization.data(withJSONObject: mapJOSN,
                                               options: JSONSerialization.WritingOptions.prettyPrinted)
        let url = URL(fileURLWithPath: resultJSONPath)
        try! data.write(to: url, options: .atomic)
    }
}
