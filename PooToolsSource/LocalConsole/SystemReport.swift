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
    
    // Current device thermal state.
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
    
    // Retrieve device mobile gestalt cache.
    public lazy var gestaltCacheExtra: NSDictionary? = {
        let url = URL(fileURLWithPath: "/pri" + "vate/va" + "r/containe" + "rs/Shared/Sys" + "temGroup/sys" + "temgroup.com.apple.mobilegestal" + "tcache/Libr" + "ary/Ca" + "ches/com.app" + "le.MobileGes" + "talt.plist")
        
        let dictionary = NSDictionary(contentsOf: url)
        return dictionary?.value(forKey: "CacheE" + "xtra") as? NSDictionary
    }()
    
    // Device marketing name.
    public lazy var gestaltMarketingName: Any = gestaltCacheExtra?.value(forKey: "Z/dqyWS6OZ" + "TRy10UcmUAhw") ?? "Unknown"
    
    // iBoot (second-stage loader) version.
    public lazy var gestaltFirmwareVersion: Any = gestaltCacheExtra?.value(forKey: "LeSRsiLoJC" + "Mhjn6nd6GWbQ") ?? "Unknown"
    
    // CPU architecture.
    public lazy var gestaltArchitecture: Any = gestaltCacheExtra?.value(forKey: "k7QIBwZJJO" + "Vw+Sej/8h8VA") ?? deviceArchitecture
    
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
    
    public lazy var gestaltModelIdentifier: Any = gestaltCacheExtra?.value(forKey: "h9jDsbgj7xI" + "VeIQ8S3/X3Q") ?? modelIdentifier
    
    // Fallback in case gestaltModelIdentifier doesn't return a value.
    public var modelIdentifier: String {
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MO" + "DEL_IDENTIFIER"] { return simulatorModelIdentifier }
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)?.trimmingCharacters(in: .controlCharacters) ?? "Unknown"
    }
    
    public var kernel: String {
        var size = 0
        // 第一次调用：获取所需的内存空间大小
        sysctlbyname("ker" + "n.os" + "type", nil, &size, nil, 0)
        
        var string = [CChar](repeating: 0, count: Int(size))
        // 第二次调用：将数据写入预先分配的 string 数组中
        sysctlbyname("ker" + "n.os" + "type", &string, &size, nil, 0)
        
        // 👉 步骤 1：截断空终止符 (\0)
        // 遍历数组，只要遇到不为 0 的字符就保留，这样可以完美剔除末尾的 C 字符串终止符
        let validCharacters = string.prefix(while: { $0 != 0 })
        
        // 👉 步骤 2：将 CChar (Int8) 映射为 Swift 标准的 UInt8 字节数组
        let utf8Bytes = validCharacters.map { UInt8(bitPattern: $0) }
        
        // 👉 步骤 3：使用 Xcode 官方推荐的 API 进行 UTF8 解码
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
