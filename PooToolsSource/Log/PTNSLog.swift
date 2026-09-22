//
//  PNSLog.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/15.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import Foundation
import SwifterSwift
import os.lock

#if !canImport(PToolsLogging) && !POOTOOLS_LOGGING
import os
#endif

#if canImport(PToolsLogging)
import PToolsLogging
#endif

// English: Use the Foundation-only logging contracts supplied by the required PToolsCore target.
// Español: Usa los contratos de logging basados solo en Foundation proporcionados por el target obligatorio PToolsCore.
// 中文：使用必需的 PToolsCore target 提供的 Foundation-only 日志契约。
#if canImport(PToolsCore)
import PToolsCore
#endif

#if !canImport(PToolsCore) && !POOTOOLS_SPLIT_CORE
// English: Keep the direct Example target compatible with the Foundation logging protocol without a second logging backend.
// Español: Mantiene compatible el target Example directo con el protocolo de logging de Foundation sin un segundo backend.
// 中文：在不引入第二套日志后端的前提下，保持 Example 直接 target 兼容 Foundation 日志协议。
public enum PTLogSeverity: String, Sendable {
    case debug
    case info
    case warning
    case error
}

public struct PTLogEvent: Sendable {
    public let message: String
    public let severity: PTLogSeverity
    public let category: String

    public init(message: String,
                severity: PTLogSeverity = .info,
                category: String = "general") {
        self.message = message
        self.severity = severity
        self.category = category
    }
}

public protocol PTLogging: Sendable {
    func log(_ event: PTLogEvent)
}
#endif

// English: Core owns only an atomic logging preference and does not know which optional Debug UI consumes it.
// Español: Core solo posee una preferencia atómica de logging y no conoce qué UI de Debug opcional la consume.
// 中文：Core 只维护原子化的日志偏好，不感知由哪个可选 Debug UI 消费该配置。
public enum PTLogRuntimeConfiguration {
    private static let lock = OSAllocatedUnfairLock(initialState: false)

    public static var defaultWritesToFile: Bool {
        get { lock.withLock { $0 } }
        set { lock.withLock { $0 = newValue } }
    }
}

public struct PTOSLogger: PTLogging {
#if canImport(PToolsLogging) || POOTOOLS_LOGGING
    private let subsystem: String
    private let category: PTLogCategory
#else
    private let logger: Logger
#endif

    public init(subsystem: String = Bundle.main.bundleIdentifier ?? "PooTools",
                category: String = "PooTools") {
#if canImport(PToolsLogging) || POOTOOLS_LOGGING
        self.subsystem = subsystem
        self.category = PTLogCategory(rawValue: category)
#else
        self.logger = Logger(subsystem: subsystem, category: category)
#endif
    }

    public func log(_ event: PTLogEvent) {
#if canImport(PToolsLogging) || POOTOOLS_LOGGING
        let level: PTLogLevel
        switch event.severity {
        case .debug:
            level = .debug
        case .info:
            level = .info
        case .warning:
            level = .warning
        case .error:
            level = .error
        }
        PTLogger.log(event.message,
                     level: level,
                     category: category,
                     metadata: ["subsystem": subsystem])
#else
        switch event.severity {
        case .debug:
            logger.debug("\(event.message, privacy: .public)")
        case .info:
            logger.info("\(event.message, privacy: .public)")
        case .warning:
            logger.warning("\(event.message, privacy: .public)")
        case .error:
            logger.error("\(event.message, privacy: .public)")
        }
#endif
    }
}

// 🚀 优化点 2：使用 Bundle 底层状态判断环境，彻底摆脱对 UIApplication 的 @MainActor 依赖。
// 这样一来，这段代码在任何线程初始化都不会触发 Swift 6 的严格并发警告。
private let currentAppEnvironment: String = {
    #if DEBUG
    // 只要是 Debug 编译环境，就直接返回，且编译器不会去检查 #else 里面的代码逻辑是否可达
    return "DEBUG 環境"
    #else
    // 只有在 Release（发布）环境下，才会编译并执行下方代码来判断是 TestFlight 还是 App Store
    let isTestFlight = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    if isTestFlight {
        return "測試環境 (TestFlight)"
    }
    
    return "生產環境 (App Store)"
    #endif
}()

// MARK: - 核心解析工具
private func convertToJSONString(_ elements: [Any]) -> String {
    return elements.compactMap { element -> String? in
        if let stringElement = element as? String {
            if let data = stringElement.data(using: .utf8),
               let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
               let prettyStr = prettyJSONString(from: jsonObject) {
                return prettyStr
            }
            return stringElement
        } else if let prettyStr = prettyJSONString(from: element) {
            return prettyStr
        }
        return "\(element)"
    }.joined(separator: "\n")
}

public func prettyJSONString(from object: Any) -> String? {
    guard JSONSerialization.isValidJSONObject(object) else { return nil }
    do {
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
                           isWriteLog: Bool = PTLogRuntimeConfiguration.defaultWritesToFile,
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
// 🚀 优化点 3：这是一个全局无隔离（nonisolated）函数，你可以在任何 Actor 或线程中直接调用，再也不需要包在主线程里！
public func PTNSLog(_ msg: Any...,
                    isWriteLog: Bool = PTLogRuntimeConfiguration.defaultWritesToFile,
                    file: NSString = #file,
                    line: Int = #line,
                    column: Int = #column,
                    fn: String = #function,
                    levelType: LoggerEXLevelType = .info,
                    loggerType: LoggerEXType = .other) {
    // 同步处理字符串转化，因为 msg 数组中可能包含非 Sendable 的类型（Any）
    let msgStr = convertToJSONString(msg)
    let currentDate = String.currentDate(dateFormatterString: "yyyy-MM-dd HH:mm:ss")
    let fileName = file.lastPathComponent
    
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
    
    // English: Forward calls to PTLogger when the logging target is present; direct Example builds use native OSLog.
    // Español: Reenvía las llamadas a PTLogger cuando existe el target de logging; las compilaciones directas de Example usan OSLog nativo.
    // 中文：日志 target 存在时转发到 PTLogger；Example 直接构建使用系统 OSLog。
#if canImport(PToolsLogging) || POOTOOLS_LOGGING
    let logLevel: PTLogLevel
    switch levelType {
    case .debug:
        logLevel = .debug
    case .error:
        logLevel = .error
    case .warning:
        logLevel = .warning
    case .trace:
        logLevel = .trace
    case .notice:
        logLevel = .notice
    case .critical, .fault:
        logLevel = .fault
    case .info:
        logLevel = .info
    }

    PTLogger.log(logOutput,
                 level: logLevel,
                 category: PTLogCategory(rawValue: loggerType.rawValue),
                 metadata: [
                    "environment": currentAppEnvironment,
                    "column": String(column)
                 ],
                 source: PTLogSource(file: fileName, function: fn, line: UInt(max(0, line))))
#else
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.ptools.example",
                        category: loggerType.rawValue)
    switch levelType {
    case .debug:
        logger.debug("\(logOutput, privacy: .public)")
    case .error, .critical, .fault:
        logger.error("\(logOutput, privacy: .public)")
    case .warning:
        logger.warning("\(logOutput, privacy: .public)")
    default:
        logger.info("\(logOutput, privacy: .public)")
    }
#endif

    // English: Install the canonical bounded file destination only when the legacy call requests file output.
    // Español: Instala el destino de archivos acotado y canónico solo cuando la llamada heredada solicita salida a disco.
    // 中文：只有旧入口明确要求写文件时，才安装统一的有界文件日志目标。
    if isWriteLog {
#if canImport(PToolsLogging) || POOTOOLS_LOGGING
        PTLogger.installFileDestinationIfNeeded()
#else
        Task {
            await PTLogFileManager.shared.append(logText: logOutput)
        }
#endif
    }
}

// MARK: - 内存查看工具
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

private var _EMPTY_PTR: UnsafeRawPointer {
    return UnsafeRawPointer(bitPattern: 0x1)!
}

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
                       alignment?.rawValue ?? MemoryLayout.alignment(ofValue: v))
    }
    
    /// 获得引用所指向的内存数据（字符串格式）
    ///
    /// - Parameter v:
    /// - Parameter alignment: 决定了多少个字节为一组
    public static func memStr(ofRef v: T,
                              alignment: PTMemAlign? = nil) -> String {
        let p = ptr(ofRef: v)
        return _memStr(p, malloc_size(p),
                       alignment?.rawValue ?? MemoryLayout.alignment(ofValue: v))
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
            guard var mstr = v as? String else { return _EMPTY_PTR }
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
