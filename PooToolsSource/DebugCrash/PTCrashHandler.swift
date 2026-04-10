//
//  PTCrashHandler.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import MachO.dyld

// MARK: - 辅助工具

/**
 获取主执行文件的内存偏移量 (ASLR Slide)
 用于在符号化崩溃堆栈时计算真实的内存地址
 */
func calculate() -> Int {
    let imageCount = _dyld_image_count()
    for i in 0..<imageCount {
        // 找到第一个类型为可执行文件 (MH_EXECUTE) 的 image，通常就是我们的主 App
        if let header = _dyld_get_image_header(i), header.pointee.filetype == MH_EXECUTE {
            return _dyld_get_image_vmaddr_slide(i)
        }
    }
    return 0
}

// 定义需要捕获的严重 Unix 崩溃信号
private let fatalSignals: [Int32] = [
    SIGABRT, SIGBUS, SIGFPE, SIGILL, SIGPIPE, SIGSEGV, SIGSYS, SIGTRAP
]

// MARK: - NSException 异常捕获

// 保存系统原有的未捕获异常处理器
private var preUncaughtExceptionHandler: NSUncaughtExceptionHandler?

public class CrashUncaughtExceptionHandler {
    /// 接收异常的闭包回调
    public static var exceptionReceiveClosure: ((Int32?, NSException?, String, [String]) -> Void)?

    /// 准备并注册异常捕获
    public func prepare() {
        preUncaughtExceptionHandler = NSGetUncaughtExceptionHandler()
        NSSetUncaughtExceptionHandler(UncaughtExceptionHandler)
    }
}

// 实际处理 NSException 的 C 语言风格函数
private func UncaughtExceptionHandler(exception: NSException) {
    let arr = exception.callStackSymbols
    let reason = exception.reason ?? "未知原因"
    let name = exception.name.rawValue
    let crash = "\nName: \(name)\nReason: \(reason)"

    // 触发自定义的回调
    CrashUncaughtExceptionHandler.exceptionReceiveClosure?(nil, exception, crash, arr)
    
    // 如果系统之前有其他处理器（例如其他第三方 SDK 注册的），继续传递给它们
    preUncaughtExceptionHandler?(exception)
    
    // 强制杀掉进程，防止程序在异常状态下继续运行导致不可知的错误
    kill(getpid(), SIGKILL)
}


// MARK: - Unix 信号捕获 (Signal)

// 优化：使用字典保存每个信号对应的原有 sigaction 结构体，确保不会丢失
private var previousSignalHandlers: [Int32: sigaction] = [:]

public class CrashSignalExceptionHandler {
    /// 接收信号崩溃的闭包回调
    public static var exceptionReceiveClosure: ((Int32?, NSException?, String) -> Void)?

    /// 准备并注册信号捕获
    public func prepare() {
        backupOriginalHandler()
        signalNewRegister()
    }

    /// 备份系统或第三方原有的信号处理器
    private func backupOriginalHandler() {
        for signalType in fatalSignals {
            var oldAction = sigaction()
            // 传入 nil 获取当前的 action 并保存在 oldAction 中
            sigaction(signalType, nil, &oldAction)
            previousSignalHandlers[signalType] = oldAction
        }
    }

    /// 注册我们自己的信号处理器
    private func signalNewRegister() {
        for signalType in fatalSignals {
            var action = sigaction()
            action.__sigaction_u.__sa_sigaction = CrashSignalHandler
            action.sa_flags = SA_NODEFER | SA_SIGINFO
            sigemptyset(&action.sa_mask)
            
            // 注册新的 action
            sigaction(signalType, &action, nil)
        }
    }
}

// 实际处理 Unix 信号的 C 语言风格函数
private func CrashSignalHandler(signal: Int32, info: UnsafeMutablePointer<__siginfo>?, context: UnsafeMutableRawPointer?) {
    let exceptionInfo = "Signal \(SignalName(signal))"

    // 触发自定义回调
    CrashSignalExceptionHandler.exceptionReceiveClosure?(signal, nil, exceptionInfo)
    
    // 恢复系统默认的信号处理器，防止死循环
    ClearSignalRegister()

    // 尝试调用崩溃前备份的其他信号处理器（将崩溃信息传递给其他 SDK）
    if var oldAction = previousSignalHandlers[signal] {
        if oldAction.__sigaction_u.__sa_sigaction != nil {
            oldAction.__sigaction_u.__sa_sigaction(signal, info, context)
        } else if oldAction.__sigaction_u.__sa_handler != nil {
            oldAction.__sigaction_u.__sa_handler(signal)
        }
    }
    
    // 强制杀掉进程
    kill(getpid(), SIGKILL)
}

/// 将信号常量转换为可读的字符串
private func SignalName(_ signal: Int32) -> String {
    switch signal {
    case SIGABRT: return "SIGABRT"
    case SIGBUS: return "SIGBUS"
    case SIGFPE: return "SIGFPE"
    case SIGILL: return "SIGILL"
    case SIGPIPE: return "SIGPIPE"
    case SIGSEGV: return "SIGSEGV"
    case SIGSYS: return "SIGSYS"
    case SIGTRAP: return "SIGTRAP"
    default: return "None"
    }
}

/// 将所有严重信号重置为系统默认行为 (SIG_DFL)
private func ClearSignalRegister() {
    for signalType in fatalSignals {
        signal(signalType, SIG_DFL)
    }
}


// MARK: - 对外暴露的 Crash Handler 门面类

public class PTCrashHandler {
    /// 统一对外的异常回调
    public var exceptionReceiveClosure: ((Int32?, NSException?, String) -> Void)?

    @MainActor public static let shared = PTCrashHandler()

    private let uncaughtExceptionHandler: CrashUncaughtExceptionHandler
    private let signalExceptionHandler: CrashSignalExceptionHandler

    @MainActor private init() {
        self.uncaughtExceptionHandler = CrashUncaughtExceptionHandler()
        self.signalExceptionHandler = CrashSignalExceptionHandler()

        // 监听 NSException 崩溃
        CrashUncaughtExceptionHandler.exceptionReceiveClosure = { [weak self] signal, exception, info, arr in
            self?.exceptionReceiveClosure?(signal, exception, info)
            
            // 使用前面优化过的 Thread.simpleCallStackSymbols 来格式化堆栈
            let trace = PTCrashModel(type: .nsexception,
                                     details: .builder(name: info),
                                     traces: .builder(Thread.simpleCallStackSymbols(arr)))
            PTCrashManager.save(crash: trace)
        }

        // 监听 Signal 崩溃
        CrashSignalExceptionHandler.exceptionReceiveClosure = { [weak self] signal, exception, info in
            self?.exceptionReceiveClosure?(signal, exception, info)
            
            // 信号崩溃无法直接从 exception 中获取堆栈，因此获取当前线程的堆栈
            let trace = PTCrashModel(type: .signal,
                                     details: .builder(name: info),
                                     traces: .builder(Thread.simpleCallStackSymbols()))
            PTCrashManager.save(crash: trace)
        }
    }

    /// 启动崩溃捕获监听（建议在 App 启动的尽早阶段调用，如 AppDelegate）
    public func prepare() {
        uncaughtExceptionHandler.prepare()
        signalExceptionHandler.prepare()
    }
}
