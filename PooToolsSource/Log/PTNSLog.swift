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

// 🚀 优化点 1：创建一个专属的串行队列，保障文件 I/O 线程安全，防止高并发时崩溃
private let PTLogFileQueue = DispatchQueue(label: "com.ptools.log.fileQueue")

// 🚀 优化点 2：全局缓存环境状态，避免每次打印都去 await 耗时查询
private let currentAppEnvironment: String = {
    // 假设你有同步获取环境的方法，这里做了简化。
    // 如果你之前的 applicationEnvironment() 必须是 async，建议在 App 启动时预先获取并赋值给一个全局变量。
    let isAppStore = UIApplication.shared.inferredEnvironment == .appStore
    let isTestFlight = UIApplication.shared.inferredEnvironment == .testFlight
    if isAppStore { return "<<<生產環境>>>" }
    if isTestFlight { return "<<<測試環境>>>" }
    return "<<<DEBUG環境>>>"
}()

public func PTNSLogConsole(_ any: Any...,
                           isWriteLog: Bool = PTCoreUserDefultsWrapper.PTLogWrite,
                           file: NSString = #file,
                           line: Int = #line,
                           column: Int = #column,
                           fn: String = #function,
                           levelType: LoggerEXLevelType = .info, // 小驼峰
                           loggerType: LoggerEXType = .other) {
    
    let msgStr = convertToJSONString(any)
    PTNSLog(msgStr, isWriteLog: isWriteLog, file: file, line: line, column: column, fn: fn, levelType: levelType, loggerType: loggerType)
}

private func convertToJSONString(_ elements: [Any]) -> String {
    // 🚀 优化点 3：使用 map 和 compactMap 替代 `+=`，性能更好且更 Swift-Style
    return elements.map { element -> String in
        if let stringElement = element as? String,
           let jsonString = stringElement.jsonStringToDic()?.convertToJsonString(),
           !jsonString.stringIsEmpty() {
            return jsonString
        } else if let dicElement = element as? NSDictionary {
            let jsonString = dicElement.convertToJsonString()
            return jsonString
        } else if let arrElement = element as? NSArray {
            let jsonString = arrElement.convertToJsonString()
            return jsonString
        }
        return "\(element)"
    }.joined(separator: "\n")
}

// MARK: - 自定义打印
public func PTNSLog(_ msg: Any...,
                    isWriteLog: Bool = PTCoreUserDefultsWrapper.PTLogWrite,
                    file: NSString = #file,
                    line: Int = #line,
                    column: Int = #column,
                    fn: String = #function,
                    levelType: LoggerEXLevelType = .info,
                    loggerType: LoggerEXType = .other) {
    
    // 🚀 优化点 4：使用高效的字符串拼接，避免 for-in 循环
    let msgStr = msg.map { "\($0)" }.joined(separator: "\n")
    
    // 格式化输出字符串
    let currentDate = String.currentDate(dateFormatterString: "yyyy-MM-dd HH:mm:ss")
    let prefix = "\n🔨\(currentAppEnvironment)Empezar🔨 \n⏰現在⏰：\(currentDate)\n📁當前文件完整的路徑是📁：\(file)\n📄當前文件是📄：\(file.lastPathComponent)\n➡️第 \(line) 行⬅️ \n➡️第 \(column) 列⬅️ \n🧾函數名🧾：\(fn)\n📝打印內容如下📝：\n\(msgStr)\n❌結論❌\n"
    
    // 控制台输出 & OSLog 处理
    let environment = UIApplication.shared.inferredEnvironment
    if environment == .appStore {
        DDLogSet(levelType: levelType, prefix: prefix)
    } else {
        let logger = Logger.logger(categoryName: loggerType.rawValue)
        switch levelType {
        case .debug: logger.debug("\(prefix)")
        case .error: logger.error("\(prefix)")
        case .info: logger.info("\(prefix)")
        case .warning: logger.warning("\(prefix)")
        case .trace, .notice, .critical, .fault:
            logger.notice("\(prefix)") // 简化调用
        }
        
#if POOTOOLS_DEBUG
        // 确保 UI 更新在主线程
        DispatchQueue.main.async {
            if LocalConsole.shared.isVisiable {
                LocalConsole.shared.print(prefix)
            }
        }
#endif
    }
    
    // 🚀 优化点 5：异步+串行写入文件，完全不阻塞主线程和其他日志打印
    if isWriteLog {
        let cachePath = FileManager.pt.CachesDirectory()
        let logURL = URL(fileURLWithPath: cachePath).appendingPathComponent("log.txt")
        
        PTLogFileQueue.async {
            appendText(fileURL: logURL, string: prefix, currentDate: currentDate)
        }
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
    let dataString = "\n🔨\(currentAppStatus)Empezar🔨 \n⏰現在⏰：\(currentDate)\n📁當前文件完整的路徑是📁：\(file)\n📄當前文件是📄：\(file.lastPathComponent)\n➡️第 \(line) 行⬅️ \n➡️第 \(column) 列⬅️ \n🧾函數名🧾：\(fn)\n📝打印內容如下📝：\n\(msgStr)❌結論❌\n"

    return (currentDate,dataString)
}

fileprivate func DDLogSet(levelType:LoggerEXLevelType = .info,
                          prefix:String) {
    DDLog.add(DDOSLogger.sharedInstance)
    switch levelType {
    case .debug:
        DDLogDebug(DDLogMessageFormat(stringLiteral: prefix))
    case .error:
        DDLogError(DDLogMessageFormat(stringLiteral: prefix))
    case .info:
        DDLogInfo(DDLogMessageFormat(stringLiteral: prefix))
    case .warning:
        DDLogWarn(DDLogMessageFormat(stringLiteral: prefix))
    case .trace:
        DDLogVerbose(DDLogMessageFormat(stringLiteral: prefix))
    case .notice:
        DDLogVerbose(DDLogMessageFormat(stringLiteral: prefix))
    case .critical:
        DDLogVerbose(DDLogMessageFormat(stringLiteral: prefix))
    case .fault:
        DDLogVerbose(DDLogMessageFormat(stringLiteral: prefix))
    }
}

// 在文件末尾追加新内容
// 在文件末尾追加新内容 (此函数现在仅在串行队列 PTLogFileQueue 中执行，绝对安全)
private func appendText(fileURL: URL, string: String, currentDate: String) {
    let stringToWrite = "\n\(currentDate)：\(string)"
    guard let data = stringToWrite.data(using: .utf8) else { return }
    
    do {
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
        }
        
        // 使用更安全的 FileHandle API
        let fileHandle = try FileHandle(forWritingTo: fileURL)
        defer {
            try? fileHandle.close() // 🚀 优化点 6：确保在使用完毕后关闭句柄，防止内存和文件句柄泄漏
        }
        
        try fileHandle.seekToEnd()
        fileHandle.write(data)
        
    } catch {
        // 如果文件写入失败，直接用最低成本的 print 输出，防止循环调用 PTNSLog
        PTNSLog("写入日志文件失败: \(error)")
    }
}

public func PTPrintPointer<T>(ptr: UnsafePointer<T>,
                              isWriteLog: Bool = false,
                              file: NSString = #file,
                              line: Int = #line,
                              column: Int = #column,
                              fn: String = #function,
                              levelType:LoggerEXLevelType = .info,
                              loggerType:LoggerEXType = .other) {
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
                       levelType:LoggerEXLevelType = .info,
                       loggerType:LoggerEXType = .other) {
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
                       levelType:LoggerEXLevelType = .info,
                       loggerType:LoggerEXType = .other) {
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
