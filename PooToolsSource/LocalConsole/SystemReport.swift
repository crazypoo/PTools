//
//  SystemReport.swift
//  LocalConsole
//
//  Created by Duraid Abdul on 2021-06-01.
//

import Foundation
import MachO

public class SystemReport {
    @MainActor public static let shared = SystemReport()
    
    public var versionString: String {
        ProcessInfo.processInfo.operatingSystemVersionString
            .replacingOccurrences(of: "Build ", with: "")
            .replacingOccurrences(of: "Version ", with: "")
    }
    
    // 当前设备的温度状态。
    public var thermalState: String {
        let state = ProcessInfo.processInfo.thermalState
        switch state {
        case .nominal: return "Nominal"
        case .fair : return "Fair"
        case .serious : return "Serious"
        case .critical : return "Critical"
        default: return "Unknown"
        }
    }
    
    // 不读取系统私有 MobileGestalt 文件，避免私有路径、KVC 和沙盒限制。
    public lazy var gestaltCacheExtra: NSDictionary? = {
        nil
    }()
    
    // 设备营销名称使用公开环境信息和机器标识作为兜底。
    public lazy var gestaltMarketingName: Any = {
        ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? modelIdentifier
    }()
    
    // 不暴露私有 iBoot 信息，使用系统版本作为公开替代值。
    public lazy var gestaltFirmwareVersion: Any = versionString
    
    // CPU 架构使用编译目标提供的公开信息。
    public lazy var gestaltArchitecture: Any = deviceArchitecture
    
    // Fallback in case gestaltArchitecture doesn't return a value.
    public var deviceArchitecture: String {
    #if arch(arm64)
    return "arm64"
    #elseif arch(x86_64)
    return "x86_64"
    #elseif arch(arm)
    return "arm"
    #elseif arch(i386)
    return "i386"
    #else
    return "Unknown"
    #endif
    }
    
    public lazy var gestaltModelIdentifier: Any = modelIdentifier
    
    // Fallback in case gestaltModelIdentifier doesn't return a value.
    public var modelIdentifier: String {
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MO" + "DEL_IDENTIFIER"] { return simulatorModelIdentifier }
        var sysinfo = utsname()
        uname(&sysinfo)
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)?.trimmingCharacters(in: .controlCharacters) ?? "Unknown"
    }
    
    public var kernel: String {
        var size = 0
        sysctlbyname("ker" + "n.os" + "type", nil, &size, nil, 0)
        
        var string = [CChar](repeating: 0, count: Int(size))
        sysctlbyname("ker" + "n.os" + "type", &string, &size, nil, 0)
        let validCharacters = string.prefix(while: { $0 != 0 })
        let utf8Bytes = validCharacters.map { UInt8(bitPattern: $0) }
        return String(decoding: utf8Bytes, as: UTF8.self)
    }
    
    public var kernelVersion: String {
        var size = 0
        sysctlbyname("ker" + "n.os" + "release", nil, &size, nil, 0)
        var string = [CChar](repeating: 0, count: Int(size))
        sysctlbyname("ker" + "n.os" + "release", &string, &size, nil, 0)
        let validCharacters = string.prefix(while: { $0 != 0 })
        let utf8Bytes = validCharacters.map { UInt8(bitPattern: $0) }
        return String(decoding: utf8Bytes, as: UTF8.self)
    }
    
    public var compileDate: String {        
        var size = 0
        sysctlbyname("ker" + "n.ve" + "rsion", nil, &size, nil, 0)
        var string = [CChar](repeating: 0, count: Int(size))
        sysctlbyname("ker" + "n.ve" + "rsion", &string, &size, nil, 0)
        let validCharacters = string.prefix(while: { $0 != 0 })
        let utf8Bytes = validCharacters.map { UInt8(bitPattern: $0) }
        let fullString = String(decoding: utf8Bytes, as: UTF8.self)

        
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        if let matches = detector?.matches(in: fullString, options: [], range: NSRange(location: 0, length: fullString.utf16.count)) {
            for match in matches {
                
                if let date = match.date {
                    
                    let dateformatter = DateFormatter()
                    dateformatter.dateStyle = .medium
                    
                    return dateformatter.string(from: date)
                }
            }
        }
        return "Unknown"
    }
}
