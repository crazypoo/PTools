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

// 🚀 优化点 1：现代化并发。使用 Swift Actor 处理文件写入，天生线程安全，完全取代传统的 DispatchQueue。
public actor PTLogFileManager {
    public static let shared = PTLogFileManager()
    private let fileManager = FileManager.default
    
    private init() {}
    
    /// 异步安全地将日志追加到文件
    public func append(logText: String) {
        let cachePath = FileManager.pt.CachesDirectory()
        let logURL = URL(fileURLWithPath: cachePath).appendingPathComponent("log.txt")
        
        guard let data = logText.data(using: .utf8) else { return }
        
        do {
            if !fileManager.fileExists(atPath: logURL.path) {
                fileManager.createFile(atPath: logURL.path, contents: nil, attributes: nil)
            }
            // 使用现代 API 处理文件句柄
            let fileHandle = try FileHandle(forWritingTo: logURL)
            defer { try? fileHandle.close() }
            
            try fileHandle.seekToEnd()
            fileHandle.write(data)
        } catch {
            PTNSLogConsole("❌ [PTLogFileManager] 写入日志文件失败: \(error)")
        }
    }
}

// 🚀 优化点 2：全局环境状态缓存保持不变，但命名和格式稍微调整，使其更适配新排版。
private let currentAppEnvironment: String = {
    let isAppStore = UIApplication.shared.inferredEnvironment_PT == .appStore
    let isTestFlight = UIApplication.shared.inferredEnvironment_PT == .testFlight
    if isAppStore { return "生產環境 (App Store)" }
    if isTestFlight { return "測試環境 (TestFlight)" }
    return "DEBUG 環境"
}()

// MARK: - 核心解析工具
// MARK: - 核心解析工具
private func convertToJSONString(_ elements: [Any]) -> String {
    return elements.compactMap { element -> String? in
        // 1. 如果是字符串，尝试判断它是不是一个 JSON 格式的字符串
        if let stringElement = element as? String {
            if let data = stringElement.data(using: .utf8),
               let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
               let prettyStr = prettyJSONString(from: jsonObject) {
                return prettyStr // 是 JSON 字符串，美化后输出
            }
            return stringElement // 只是普通字符串，原样返回
        }
        // 2. 如果是字典、数组或其他可以被 JSON 序列化的对象
        else if let prettyStr = prettyJSONString(from: element) {
            return prettyStr
        }
        
        // 3. 其他不支持 JSON 格式化的类型，直接走默认打印
        return "\(element)"
    }.joined(separator: "\n")
}

// 🚀 新增：原生 JSON 美化工具
public func prettyJSONString(from object: Any) -> String? {
    // 确保对象可以被转换为 JSON
    guard JSONSerialization.isValidJSONObject(object) else { return nil }
    
    do {
        // 使用 .prettyPrinted 选项来实现多行缩进的美化效果
        // .withoutEscapingSlashes 可以防止网址中的斜杠 "/" 被转义为 "\/" (iOS 13+ 支持)
        var options: JSONSerialization.WritingOptions = [.prettyPrinted]
        if #available(iOS 13.0, *) {
            options.insert(.withoutEscapingSlashes)
        }
        
        let data = try JSONSerialization.data(withJSONObject: object, options: options)
        return String(data: data, encoding: .utf8)
    } catch {
        return nil
    }
}

// MARK: - 快捷控制台打印
public func PTNSLogConsole(_ any: Any...,
                           isWriteLog: Bool = PTCoreUserDefultsWrapper.PTLogWrite,
                           file: NSString = #file,
                           line: Int = #line,
                           column: Int = #column,
                           fn: String = #function,
                           levelType: LoggerEXLevelType = .info,
                           loggerType: LoggerEXType = .other) {
    let msgStr = convertToJSONString(any)
    PTNSLog(msgStr, isWriteLog: isWriteLog, file: file, line: line, column: column, fn: fn, levelType: levelType, loggerType: loggerType)
}

// MARK: - 自定义打印 (主入口)
public func PTNSLog(_ msg: Any...,
                    isWriteLog: Bool = PTCoreUserDefultsWrapper.PTLogWrite,
                    file: NSString = #file,
                    line: Int = #line,
                    column: Int = #column,
                    fn: String = #function,
                    levelType: LoggerEXLevelType = .info,
                    loggerType: LoggerEXType = .other) {
    
    // 将所有输入转化为格式化良好的字符串
    let msgStr = convertToJSONString(msg)
    
    let currentDate = String.currentDate(dateFormatterString: "yyyy-MM-dd HH:mm:ss")
    let fileName = file.lastPathComponent
    
    // 🚀 优化点 4：重新设计排版！使用分隔符和对齐的方式，极大地提升可读性。
    let logOutput = """
    
    ====================== 🔨 \(currentAppEnvironment) 🔨 ======================
    ⏰ 時間 : \(currentDate)
    📁 文件 : \(fileName)
    📍 位置 : 第 \(line) 行，第 \(column) 列
    🧾 函數 : \(fn)
    📝 內容 :
    \(msgStr)
    =============================================================================
    
    """
    
    // 控制台输出 & OSLog 处理
    let environment = UIApplication.shared.inferredEnvironment_PT
    if environment == .appStore {
        DDLogSet(levelType: levelType, prefix: logOutput)
    } else {
        let logger = Logger.logger(categoryName: loggerType.rawValue)
        switch levelType {
        case .debug: logger.debug("\(logOutput)")
        case .error: logger.error("\(logOutput)")
        case .info: logger.info("\(logOutput)")
        case .warning: logger.warning("\(logOutput)")
        case .trace, .notice, .critical, .fault:
            logger.notice("\(logOutput)")
        }
        
#if POOTOOLS_DEBUG
        // 确保 UI 更新在主线程
        Task { @MainActor in
            if LocalConsole.shared.isVisiable {
                LocalConsole.shared.print(logOutput)
            }
        }
#endif
    }
    
    // 🚀 优化点 5：使用 Task 结合 Actor，优雅地异步写入文件，绝对不阻塞主线程
    if isWriteLog {
        Task {
            await PTLogFileManager.shared.append(logText: logOutput)
        }
    }
}

// MARK: - 辅助组件
fileprivate func DDLogSet(levelType: LoggerEXLevelType = .info, prefix: String) {
    DDLog.add(DDOSLogger.sharedInstance)
    switch levelType {
    case .debug: DDLogDebug(DDLogMessageFormat(stringLiteral: prefix))
    case .error: DDLogError(DDLogMessageFormat(stringLiteral: prefix))
    case .info: DDLogInfo(DDLogMessageFormat(stringLiteral: prefix))
    case .warning: DDLogWarn(DDLogMessageFormat(stringLiteral: prefix))
    default: DDLogVerbose(DDLogMessageFormat(stringLiteral: prefix))
    }
}

// MARK: - 内存查看工具 (也进行了排版美化)
public func PTPrintPointer<T>(ptr: UnsafePointer<T>,
                              isWriteLog: Bool = false,
                              file: NSString = #file,
                              line: Int = #line,
                              column: Int = #column,
                              fn: String = #function,
                              levelType: LoggerEXLevelType = .info,
                              loggerType: LoggerEXType = .other) {
    let logString = "【内存地址】: \(ptr)"
    PTNSLog(logString, isWriteLog: isWriteLog, file: file, line: line, column: column, fn: fn, levelType: levelType, loggerType: loggerType)
}

public func PTPrint<T>(val: inout T,
                       isWriteLog: Bool = false,
                       file: NSString = #file,
                       line: Int = #line,
                       column: Int = #column,
                       fn: String = #function,
                       levelType: LoggerEXLevelType = .info,
                       loggerType: LoggerEXType = .other) {
    let logString = """
    【变量类型】: \(type(of: val))
     ├─ 地址 : \(PTMems.ptr(ofVal: &val))
     ├─ 内存 : \(PTMems.memStr(ofVal: &val))
     └─ 大小 : \(PTMems.size(ofVal: &val)) bytes
    """
    PTNSLog(logString, isWriteLog: isWriteLog, file: file, line: line, column: column, fn: fn, levelType: levelType, loggerType: loggerType)
}

public func PTPrint<T>(ref: T,
                       isWriteLog: Bool = false,
                       file: NSString = #file,
                       line: Int = #line,
                       column: Int = #column,
                       fn: String = #function,
                       levelType: LoggerEXLevelType = .info,
                       loggerType: LoggerEXType = .other) {
    let logString = """
    【对象类型】: \(type(of: ref))
     ├─ 地址 : \(PTMems.ptr(ofRef: ref))
     ├─ 内存 : \(PTMems.memStr(ofRef: ref))
     └─ 大小 : \(PTMems.size(ofRef: ref)) bytes
    """
    PTNSLog(logString, isWriteLog: isWriteLog, file: file, line: line, column: column, fn: fn, levelType: levelType, loggerType: loggerType)
}

// （注意：原有的 PTMems 及后续结构体保持不变，直接接在下方即可，因为那部分是底层内存解析逻辑，非常完美）
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
