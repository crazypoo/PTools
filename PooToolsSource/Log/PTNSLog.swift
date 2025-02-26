//
//  PNSLog.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/15.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import Foundation
import CocoaLumberjack
import SwifterSwift
import OSLog

//PTNSLog(_ msg: Any...,
public func PTNSLogConsole(_ any:Any...,
                           isWriteLog: Bool = PTCoreUserDefultsWrapper.PTLogWrite,
                           file: NSString = #file,
                           line: Int = #line,
                           column: Int = #column,
                           fn: String = #function,
                           levelType:LoggerEXLevelType = .Info,
                           loggerType:LoggerEXType = .Other) {
    
    let msgStr = convertToJSONString(any)
    PTNSLog(msgStr,isWriteLog: isWriteLog,file: file,line: line,column:column,fn:fn,levelType: levelType,loggerType: loggerType)
}

private func convertToJSONString(_ elements: [Any]) -> String {
    var msgStr = ""
    for element in elements {
        var newString = "\(element)"
        if let stringElement = element as? String, let jsonString = stringElement.jsonStringToDic()?.convertToJsonString(), !jsonString.stringIsEmpty() {
            newString = jsonString
        } else if let dicElement = element as? NSDictionary {
            let jsonString = dicElement.convertToJsonString()
            if !jsonString.stringIsEmpty() {
                newString = jsonString
            }
        } else if let arrElement = element as? NSArray {
            let jsonString = arrElement.convertToJsonString()
            if !jsonString.stringIsEmpty() {
                newString = jsonString
            }
        }
        msgStr += "\(newString)\n"
    }
    return msgStr
}

//MARK: - 自定义打印
/// 自定义打印
/// - Parameter msg: 打印的内容
/// - Parameter isWriteLog:
/// - Parameter file: 文件路径
/// - Parameter line: 打印内容所在的 行
/// - Parameter column: 打印内容所在的 列
/// - Parameter fn: 打印内容的函数名
public func PTNSLog(_ msg: Any...,
                    isWriteLog: Bool = PTCoreUserDefultsWrapper.PTLogWrite,
                    file: NSString = #file,
                    line: Int = #line,
                    column: Int = #column,
                    fn: String = #function,
                    levelType:LoggerEXLevelType = .Info,
                    loggerType:LoggerEXType = .Other) {
    Task {
        var msgStr = ""
        for element in msg {
            msgStr += "\(element)\n"
        }
        let formatResult = await formatLogMessage(file: file, line: line, column: column, fn: fn, msgStr: msgStr)
        let prefix = formatResult.1
        let currentDate = formatResult.0

        let environment = await UIApplication.applicationEnvironment()
        switch environment {
        case .appStore:
            DDLogSet(levelType: levelType,prefix: prefix)
        default:
            let logger = Logger.loger(categoryName: loggerType.rawValue)
            switch levelType {
            case .Debug:
                logger.debug("\(prefix)")
            case .Error:
                logger.error("\(prefix)")
            case .Info:
                logger.info("\(prefix)")
            case .Warning:
                logger.warning("\(prefix)")
            case .Trace:
                logger.trace("\(prefix)")
            case .Notice:
                logger.notice("\(prefix)")
            case .Critical:
                logger.critical("\(prefix)")
            case .Fault:
                logger.fault("\(prefix)")
            }
    #if POOTOOLS_DEBUG
            PTGCDManager.gcdMain {
                if LocalConsole.shared.isVisiable {
                    LocalConsole.shared.print(prefix)
                }
            }
    #endif
        }
        
        guard isWriteLog else {
            return
        }
        // 将内容同步写到文件中去（Caches文件夹下）
        let cachePath = FileManager.pt.CachesDirectory()
        let logURL = cachePath + "/log.txt"
        appendText(fileURL: URL(string: logURL)!, string: "\(prefix)", currentDate: currentDate,isWriteLog: isWriteLog,file: file,line: line,column: column,fn: fn)

    }
}

private func formatLogMessage(file: NSString, line: Int, column: Int, fn: String, msgStr: String) async -> (String,String) {
    let currentAppStatus: String
    let environment = await UIApplication.applicationEnvironment()
    switch environment {
    case .appStore:
        currentAppStatus = "<<<生產環境>>>"
    case .testFlight:
        currentAppStatus = "<<<測試環境>>>"
    default:
        currentAppStatus = "<<<DEBUG環境>>>"
    }
    
    let currentDate = String.currentDate(dateFormatterString: "yyyy-MM-dd HH:mm:ss")
//    let dataString = "\n🔨\(currentAppStatus)Empezar🔨\n🌏RootViewController:\(String(describing: PTUtils.getRootViewController())) \n🌑CurrentViewController:\(PTUtils.getCurrentVC()) \n⭐️ActivityViewController:\(String(describing: PTUtils.getActivityViewController())) \n⏰現在⏰：\(currentDate)\n📁當前文件完整的路徑是📁：\(file)\n📄當前文件是📄：\(file.lastPathComponent)\n➡️第 \(line) 行⬅️ \n➡️第 \(column) 列⬅️ \n🧾函數名🧾：\(fn)\n📝打印內容如下📝：\n\(msgStr)❌結論❌\n"
    let dataString = "\n🔨\(currentAppStatus)Empezar🔨 \n⏰現在⏰：\(currentDate)\n📁當前文件完整的路徑是📁：\(file)\n📄當前文件是📄：\(file.lastPathComponent)\n➡️第 \(line) 行⬅️ \n➡️第 \(column) 列⬅️ \n🧾函數名🧾：\(fn)\n📝打印內容如下📝：\n\(msgStr)❌結論❌\n"

    return (currentDate,dataString)
}

fileprivate func DDLogSet(levelType:LoggerEXLevelType = .Info,
                          prefix:String) {
    DDLog.add(DDOSLogger.sharedInstance)
    switch levelType {
    case .Debug:
        DDLogDebug(DDLogMessageFormat(stringLiteral: prefix))
    case .Error:
        DDLogError(DDLogMessageFormat(stringLiteral: prefix))
    case .Info:
        DDLogInfo(DDLogMessageFormat(stringLiteral: prefix))
    case .Warning:
        DDLogWarn(DDLogMessageFormat(stringLiteral: prefix))
    case .Trace:
        DDLogVerbose(DDLogMessageFormat(stringLiteral: prefix))
    case .Notice:
        DDLogVerbose(DDLogMessageFormat(stringLiteral: prefix))
    case .Critical:
        DDLogVerbose(DDLogMessageFormat(stringLiteral: prefix))
    case .Fault:
        DDLogVerbose(DDLogMessageFormat(stringLiteral: prefix))
    }
}

// 在文件末尾追加新内容
private func appendText(fileURL: URL,
                        string: String,
                        currentDate: String,
                        isWriteLog: Bool = false,
                        file: NSString = #file,
                        line: Int = #line,
                        column: Int = #column,
                        fn: String = #function) {
    do {
        // 如果文件不存在则新建一个
        FileManager.pt.createFile(filePath: fileURL.path)
        let fileHandle = try FileHandle(forWritingTo: fileURL)
        let stringToWrite = "\n" + "\(currentDate)：" + string
        // 找到末尾位置并添加
        fileHandle.seekToEndOfFile()
        fileHandle.write(stringToWrite.data(using: String.Encoding.utf8)!)
    } catch let error as NSError {
        let logString = "failed to append: \(error)"
        PTNSLog(logString,isWriteLog: isWriteLog,file: file,line: line,column:column,fn:fn,levelType: .Error,loggerType: .Other)
    }
}

public func PTPrintPointer<T>(ptr: UnsafePointer<T>,
                              isWriteLog: Bool = false,
                              file: NSString = #file,
                              line: Int = #line,
                              column: Int = #column,
                              fn: String = #function,
                              levelType:LoggerEXLevelType = .Info,
                              loggerType:LoggerEXType = .Other) {
    let logString = "内存地址：\(ptr)) --------------"
    PTNSLog(logString,isWriteLog: isWriteLog,file: file,line: line,column:column,fn:fn,levelType: levelType,loggerType: loggerType)
}

// MARK: - 以下内容是：MJ的Mems演变过来
// MARK: mark 变量的：地址、内存、大小 的打印
public func PTPrint<T>(val: inout T,
                       isWriteLog: Bool = false,
                       file: NSString = #file,
                       line: Int = #line,
                       column: Int = #column,
                       fn: String = #function,
                       levelType:LoggerEXLevelType = .Info,
                       loggerType:LoggerEXType = .Other) {
    let logString = "-------------- \(type(of: val)) --------------\n变量的地址:\(PTMems.ptr(ofVal: &val))\n变量的内存:\(PTMems.memStr(ofVal: &val))\n变量的大小:\(PTMems.size(ofVal: &val))\n"
    PTNSLog(logString,isWriteLog: isWriteLog,file: file,line: line,column:column,fn:fn,levelType: levelType,loggerType: loggerType)
}

// MARK: 对象的：地址、内存、大小 的打印
public func PTPrint<T>(ref: T,
                       isWriteLog: Bool = false,
                       file: NSString = #file,
                       line: Int = #line,
                       column: Int = #column,
                       fn: String = #function,
                       levelType:LoggerEXLevelType = .Info,
                       loggerType:LoggerEXType = .Other) {
    let logString = "-------------- \(type(of: ref)) --------------\n对象的地址:\(PTMems.ptr(ofRef: ref))\n对象的内存:\(PTMems.memStr(ofRef: ref))\n对象的大小:\(PTMems.size(ofRef: ref))\n"
    PTNSLog(logString,isWriteLog: isWriteLog,file: file,line: line,column:column,fn:fn,levelType: levelType,loggerType: loggerType)
}

public enum PTMemAlign : Int {
    case one = 1, two = 2, four = 4, eight = 8
}

private let _EMPTY_PTR = UnsafeRawPointer(bitPattern: 0x1)!

/// 辅助查看内存的小工具类
public struct PTMems<T> {
    private static func _memStr(_ ptr: UnsafeRawPointer,
                                _ size: Int,
                                _ aligment: Int) ->String {
        if ptr == _EMPTY_PTR { return "" }
        
        var rawPtr = ptr
        var string = ""
        let fmt = "0x%0\(aligment << 1)lx"
        let count = size / aligment
        for i in 0..<count {
            if i > 0 {
                string.append(" ")
                rawPtr += aligment
            }
            let value: CVarArg
            switch aligment {
            case PTMemAlign.eight.rawValue:
                value = rawPtr.load(as: UInt64.self)
            case PTMemAlign.four.rawValue:
                value = rawPtr.load(as: UInt32.self)
            case PTMemAlign.two.rawValue:
                value = rawPtr.load(as: UInt16.self)
            default:
                value = rawPtr.load(as: UInt8.self)
            }
            string.append(String(format: fmt, value))
        }
        return string
    }
    
    private static func _memBytes(_ ptr: UnsafeRawPointer,
                                  _ size: Int) -> [UInt8] {
        guard ptr != _EMPTY_PTR else { return [] }
        return (0..<size).map { (ptr + $0).load(as: UInt8.self) }
    }
    
    /// 获得变量的内存数据（字节数组格式）
    public static func memBytes(ofVal v: inout T) -> [UInt8] {
        _memBytes(ptr(ofVal: &v), MemoryLayout.stride(ofValue: v))
    }
    
    /// 获得引用所指向的内存数据（字节数组格式）
    public static func memBytes(ofRef v: T) -> [UInt8] {
        let p = ptr(ofRef: v)
        return _memBytes(p, malloc_size(p))
    }
    
    /// 获得变量的内存数据（字符串格式）
    ///
    /// - Parameter v:
    /// - Parameter alignment: 决定了多少个字节为一组
    public static func memStr(ofVal v: inout T,
                              alignment: PTMemAlign? = nil) -> String {
        let p = ptr(ofVal: &v)
        return _memStr(p, MemoryLayout.stride(ofValue: v),
                       alignment != nil ? alignment!.rawValue : MemoryLayout.alignment(ofValue: v))
    }
    
    /// 获得引用所指向的内存数据（字符串格式）
    ///
    /// - Parameter v:
    /// - Parameter alignment: 决定了多少个字节为一组
    public static func memStr(ofRef v: T,
                              alignment: PTMemAlign? = nil) -> String {
        let p = ptr(ofRef: v)
        return _memStr(p, malloc_size(p),
                       alignment != nil ? alignment!.rawValue : MemoryLayout.alignment(ofValue: v))
    }
    
    /// 获得变量的内存地址
    public static func ptr(ofVal v: inout T) -> UnsafeRawPointer {
        MemoryLayout.size(ofValue: v) == 0 ? _EMPTY_PTR : withUnsafePointer(to: &v) {
            UnsafeRawPointer($0)
        }
    }
    
    /// 获得引用所指向内存的地址
    public static func ptr(ofRef v: T) -> UnsafeRawPointer {
        if v is Array<Any>
            || Swift.type(of: v) is AnyClass
            || v is AnyClass {
            return UnsafeRawPointer(bitPattern: unsafeBitCast(v, to: UInt.self))!
        } else if v is String {
            var mstr = v as! String
            if mstr.mems.type() != .heap {
                return _EMPTY_PTR
            }
            return UnsafeRawPointer(bitPattern: unsafeBitCast(v, to: (UInt, UInt).self).1)!
        } else {
            return _EMPTY_PTR
        }
    }
    
    /// 获得变量所占用的内存大小
    public static func size(ofVal v: inout T) -> Int {
        MemoryLayout.size(ofValue: v) > 0 ? MemoryLayout.stride(ofValue: v) : 0
    }
    
    /// 获得引用所指向内存的大小
    public static func size(ofRef v: T) -> Int {
        malloc_size(ptr(ofRef: v))
    }
}

public enum PTStringMemType : UInt8 {
    /// TEXT段（常量区）
    case text = 0xd0
    /// taggerPointer
    case tagPtr = 0xe0
    /// 堆空间
    case heap = 0xf0
    /// 未知
    case unknow = 0xff
}

public struct PTMemsWrapper<Base> {
    public private(set) var base: Base
    public init(_ base: Base) {
        self.base = base
    }
}

public protocol PTMemsCompatible {}
public extension PTMemsCompatible {
    static var mems: PTMemsWrapper<Self>.Type {
        get {
            PTMemsWrapper<Self>.self
        }
        set {}
    }
    var mems: PTMemsWrapper<Self> {
        get {
            PTMemsWrapper(self)
        }
        set {}
    }
}

extension String: PTMemsCompatible {}
public extension PTMemsWrapper where Base == String {
    mutating func type() -> PTStringMemType {
        let ptr = PTMems.ptr(ofVal: &base)
        return PTStringMemType(rawValue: (ptr + 15).load(as: UInt8.self) & 0xf0)
        ?? PTStringMemType(rawValue: (ptr + 7).load(as: UInt8.self) & 0xf0)
        ?? .unknow
    }
}
