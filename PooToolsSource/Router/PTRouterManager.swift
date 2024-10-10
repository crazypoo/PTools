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
public let NSKVONotifyingPrefix = "KVONotifying_"

/// 神策动态类
public let kSADelegateClassSensorsSuffix = "_CN.SENSORSDATA"
/// 排除苹果系统类
public let kSAppleSuffix = "com.apple"

/// 排除cocoaPods相关库
public let kSCocoaPodsSuffix = "org.cocoapods"

public class PTRouterManager: NSObject {
    
    static public let shareInstance = PTRouterManager()
    
    // MARK: - 注册路由
    public static func addGloableRouter(_ excludeCocoapods: Bool = false,
                                        _ urlPath: String,
                                        _ userInfo: [String: Any],
                                        forceCheckEnable: Bool = false) -> Any? {
        
        PTRouter.globalOpenFailedHandler { (info) in
            guard let matchFailedKey = info[PTRouter.matchFailedKey] as? String else { return }
            PTNSLogConsole(matchFailedKey,levelType: PTLogMode,loggerType: .Router)
            PTRouter.shareInstance.logcat?("PTRouter: globalOpenFailedHandler", .logError, "\(matchFailedKey)")
        }
        
        return PTRouterManager.registerRouterMap(excludeCocoapods, urlPath, userInfo,forceCheckEnable: forceCheckEnable)
    }
    
    // MARK: -注册web与服务调用
    public static func injectRouterServiceConfig(_ webPath: String?, _ serviceHost: String) {
        PTRouter.injectRouterServiceConfig(webPath, serviceHost)
    }
}

extension PTRouterManager {
    
    /// 类名和枚举值的映射表
    static var apiArray = [String]()
    static var classMapArray = [String]()
    static var registerRouterList: Array = [[String: String]]()

    // MARK: - 自动注册路由
    public class func registerRouterMap(_ excludeCocoapods: Bool = false,
                                        _ urlPath: String,
                                        _ userInfo: [String: Any],
                                        forceCheckEnable: Bool = false) -> Any? {
        let beginRegisterTime = CFAbsoluteTimeGetCurrent()
        if registerRouterList.isEmpty {
            registerRouterList = fetchRouterRegisterClass(excludeCocoapods)
        }
        for item in registerRouterList {
            var priority: UInt32 = 0
            if let number = UInt32(item[PTRouterPriority] ?? "0") {
                priority = number
            }
            PTRouter.addRouterItem(item[PTRouterPath] ?? "", priority: priority, classString: item[PTRouterClassName] ?? "")
        }
        let endRegisterTime = CFAbsoluteTimeGetCurrent()
        PTRouter.shareInstance.logcat?("注册路由耗时：\(endRegisterTime - beginRegisterTime)", .logNormal, "")
        PTRouter.routerLoadStatus(true)
#if DEBUG
        routerForceRecheck(excludeCocoapods)
#endif
        return PTRouter.openURL(urlPath, userInfo: userInfo)
    }
    
    // MARK: - 客户端强制校验，是否匹配
    public static func routerForceRecheck(_ excludeCocoapods: Bool = false) {
        PTRouterManager.runtimeRouterList(excludeCocoapods)
        let paths = registerRouterList.compactMap { $0[PTRouterPath] }
        let patternArray = Set(paths)
        let apiPathArray = Set(apiArray)
        let diffArray = patternArray.symmetricDifference(apiPathArray)
        PTNSLogConsole("URL差集：\(diffArray)")
        PTNSLogConsole("registerRouterList：\(registerRouterList)")
        assert(diffArray.count == 0, "URL 拼写错误，请确认差集中的url是否匹配")
        
        let classNames = registerRouterList.compactMap { $0[PTRouterClassName] }
        let patternValueArray = Set(classNames)
        let classPathArray = Set(classMapArray)
        let diffClassesArray = patternValueArray.symmetricDifference(classPathArray)
        PTNSLogConsole("classes差集：\(diffClassesArray)")
        assert(diffClassesArray.count == 0, "classes 拼写错误，请确认差集中的class是否匹配")
    }
    
    class func runtimeRouterList(_ excludeCocoapods: Bool = false) {
        
        let bundles = CFBundleGetAllBundles() as? [CFBundle]
        for bundle in bundles ?? [] {
            let identifier = CFBundleGetIdentifier(bundle);
            
            if let id = identifier as? String {
                if excludeCocoapods {
                    if  id.hasPrefix(kSAppleSuffix) || id.hasPrefix(kSCocoaPodsSuffix) {
                        continue
                    }
                } else {
                    if  id.hasPrefix(kSAppleSuffix) {
                        continue
                    }
                }
            }
            
            guard let execURL = CFBundleCopyExecutableURL(bundle) as NSURL? else { continue }
            let imageURL = execURL.fileSystemRepresentation
            let classCount = UnsafeMutablePointer<UInt32>.allocate(capacity: MemoryLayout<UInt32>.stride)
            guard let classNames = objc_copyClassNamesForImage(imageURL, classCount) else {
                continue
            }
            
            for idx in 0..<classCount.pointee {
                let currentClassName = String(cString: classNames[Int(idx)])
                guard let currentClass = NSClassFromString(currentClassName) else {
                    continue
                }
                
                if class_getInstanceMethod(currentClass, NSSelectorFromString("methodSignatureForSelector:")) != nil,
                   class_getInstanceMethod(currentClass, NSSelectorFromString("doesNotRecognizeSelector:")) != nil  {
                    if let clss = currentClass as? CustomRouterInfo.Type {
                        apiArray.append(clss.patternString)
                        classMapArray.append(clss.routerClass)
                    }
                }
            }
        }
    }

    public class func loadRouterClass(excludeCocoapods: Bool = false,
                                      useCache: Bool = false) {
        
        if PTRouterDebugTool.checkTracing() || !useCache {
            registerRouterList = fetchRouterRegisterClass(excludeCocoapods)
        } else {
            let cachePath = fetchCurrentVersionRouterCachePath()
            let fileExists = FileManager.pt.judgeFileOrFolderExists(filePath: cachePath)
            var cacheData: Array = [[String: String]]()
            if fileExists {
                cacheData = loadArrayDictFromJSON(path: cachePath)
            }
            
            if useCache && fileExists && !cacheData.isEmpty {
                registerRouterList = cacheData
            } else {
                registerRouterList = fetchRouterRegisterClass(excludeCocoapods)
            }
        }
    }

    public static func fetchCurrentVersionRouterCachePath() -> String {
        let appVersion = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? ""
        // 获得沙盒的根路径
        let home = NSHomeDirectory() as NSString
        // 获得Documents路径，使用NSString对象的appendingPathComponent()方法拼接路径
        let plistPath = home.appendingPathComponent("Documents") as NSString
        // 输出plist文件到指定的路径
        let resultJSONPath = "\(plistPath)/\(appVersion)_routerMap.json"
        PTRouter.shareInstance.logcat?("路由缓存文件地址：\(resultJSONPath)", .logNormal, "")
        return resultJSONPath
    }
    
    static func loadArrayDictFromJSON(path: String) -> [[String: String]] {
        let url = URL(fileURLWithPath: path)

        do {
            let jsonData = try Data(contentsOf: url)
            if let arrayDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: String]] {
                return arrayDict
            }
        } catch {
            return [[String: String]]()
        }
        return [[String: String]]()
    }


    // MARK: - 提前获取工程中符合路由注册条件的类
    public class func fetchRouterRegisterClass(_ excludeCocoapods: Bool = false,
                                               _ localCache: Bool = false) -> [[String: String]] {
        let beginRegisterTime = CFAbsoluteTimeGetCurrent()
        
        var resultXLClass = [AnyClass]()
        
        let bundles = CFBundleGetAllBundles() as? [CFBundle]
        for bundle in bundles ?? [] {
            let identifier = CFBundleGetIdentifier(bundle);
            
            if let id = identifier as? String {
                if excludeCocoapods {
                    if  id.hasPrefix(kSAppleSuffix) || id.hasPrefix(kSCocoaPodsSuffix) {
                        continue
                    }
                } else {
                    if  id.hasPrefix(kSAppleSuffix) {
                        continue
                    }
                }
            }
            
            guard let execURL = CFBundleCopyExecutableURL(bundle) as NSURL? else { continue }
            let imageURL = execURL.fileSystemRepresentation
            let classCount = UnsafeMutablePointer<UInt32>.allocate(capacity: MemoryLayout<UInt32>.stride)
            guard let classNames = objc_copyClassNamesForImage(imageURL, classCount) else {
                continue
            }
            
            
            for idx in 0..<classCount.pointee {
                let currentClassName = String(cString: classNames[Int(idx)])
                guard let currentClass = NSClassFromString(currentClassName) else {
                    continue
                }
                
                if class_getInstanceMethod(currentClass, NSSelectorFromString("methodSignatureForSelector:")) != nil,
                   class_getInstanceMethod(currentClass, NSSelectorFromString("doesNotRecognizeSelector:")) != nil {
                    if let cls =  currentClass as? UIViewController.Type {
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
                if fullName.contains(kSADelegateClassSensorsSuffix)  {
                    break
                }
                
                for s in 0 ..< cls.patternString.count {
                    
                    if fullName.contains(NSKVONotifyingPrefix) {
                        let range = fullName.index(fullName.startIndex, offsetBy: NSKVONotifyingPrefix.count)..<fullName.endIndex
                        let subString = fullName[range]
                        registerRouterList.append([PTRouterPath: cls.patternString[s], PTRouterClassName: "\(subString)", PTRouterPriority: "\(cls.priority)"])
                    } else {
                        registerRouterList.append([PTRouterPath: cls.patternString[s], PTRouterClassName: fullName, PTRouterPriority: "\(cls.priority)"])
                    }
                }
            }
        }
        let endRegisterTime = CFAbsoluteTimeGetCurrent()
        PTRouter.shareInstance.logcat?("提前获取工程中符合路由注册条件的类耗时：\(endRegisterTime - beginRegisterTime)", .logNormal, "")
        writeRouterMapToFile(mapArray: registerRouterList)
        return registerRouterList

    }

    
    // MARK: - 自动注册服务
    public class func registerServices(excludeCocoapods: Bool = false) {
        
//        let expectedClassCount = objc_getClassList(nil, 0)
//        let allClasses = UnsafeMutablePointer<AnyClass>.allocate(capacity: Int(expectedClassCount))
//        let autoreleasingAllClasses = AutoreleasingUnsafeMutablePointer<AnyClass>(allClasses)
//        let actualClassCount: Int32 = objc_getClassList(autoreleasingAllClasses, expectedClassCount)
//        var resultXLClass = [AnyClass]()
//        for i in 0 ..< actualClassCount {
//            
//            let currentClass: AnyClass = allClasses[Int(i)]
//            if (class_getInstanceMethod(currentClass, NSSelectorFromString("methodSignatureForSelector:")) != nil),
//               (class_getInstanceMethod(currentClass, NSSelectorFromString("doesNotRecognizeSelector:")) != nil),
//               let cls = currentClass as? PTRouterServiceProtocol.Type {
//                PTNSLogConsole(currentClass)
//                resultXLClass.append(cls)
//                
//                PTRouterServiceManager.default.registerService(named: cls.seriverName, lazyCreator: (cls as! NSObject.Type).init())
//            }
//        }
        let beginRegisterTime = CFAbsoluteTimeGetCurrent()
        let bundles = CFBundleGetAllBundles() as? [CFBundle]
        for bundle in bundles ?? [] {
            let identifier = CFBundleGetIdentifier(bundle);
            
            if let id = identifier as? String {
                if excludeCocoapods {
                    if  id.hasPrefix(kSAppleSuffix) || id.hasPrefix(kSCocoaPodsSuffix) {
                        continue
                    }
                } else {
                    if  id.hasPrefix(kSAppleSuffix) {
                        continue
                    }
                }
            }
            
            guard let execURL = CFBundleCopyExecutableURL(bundle) as NSURL? else { continue }
            let imageURL = execURL.fileSystemRepresentation
            let classCount = UnsafeMutablePointer<UInt32>.allocate(capacity: MemoryLayout<UInt32>.stride)
            guard let classNames = objc_copyClassNamesForImage(imageURL, classCount) else {
                continue
            }
            
            for idx in 0..<classCount.pointee {
                let currentClassName = String(cString: classNames[Int(idx)])
                guard let currentClass = NSClassFromString(currentClassName) else {
                    continue
                }
                if class_getInstanceMethod(currentClass, NSSelectorFromString("methodSignatureForSelector:")) != nil,
                   class_getInstanceMethod(currentClass, NSSelectorFromString("doesNotRecognizeSelector:")) != nil,
                   let cls = currentClass as? PTRouterServiceProtocol.Type {
                    PTRouterServiceManager.default.registerService(named: cls.seriverName, lazyCreator: (cls as! NSObject.Type).init())
                }
            }
        }
        
        let endRegisterTime = CFAbsoluteTimeGetCurrent()
        PTNSLogConsole("服务注册耗时：\(endRegisterTime - beginRegisterTime)",levelType: PTLogMode,loggerType: .Router)
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
        
    // MARK: - 路由映射文件导出
    public static func writeRouterMapToFile(mapArray: [[String: String]]) {
        // 输出plist文件到指定的路径
        let resultJSONPath = fetchCurrentVersionRouterCachePath()
        var jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: mapArray, options: [])
        } catch {
            print("Error converting array to JSON: \(error)")
            return
        }
        
        let url = URL(fileURLWithPath: resultJSONPath)
        try! jsonData.write(to: url, options: .atomic)
    }
}
