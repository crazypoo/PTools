//
//  PTPhoneNetWorkInfo.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 18/11/22.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

/*
 #define IOS_CELLULAR    @"pdp_ip0"
 #define IOS_WIFI        @"en0"
 #define IOS_VPN       @"utun0"
 #define IP_ADDR_IPv4    @"ipv4"
 #define IP_ADDR_IPv6    @"ipv6"
 */

@objcMembers
public class PTPhoneNetWorkInfo:NSObject {
    
    public struct NetworkInterfaceInfo {
        let name: String
        let ip: String
        let netmask: String
    }
    
    public class func ipv4String() -> String {
        for info in PTPhoneNetWorkInfo.enumerate() {
            if info.name == "en0" {
                return info.ip
            }
        }
        return "0.0.0.0"
    }
    
    public static func enumerate() -> [NetworkInterfaceInfo] {
        var interfaces = [NetworkInterfaceInfo]()
        
        // MARK: Get list of all interfaces on the local machine:
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            
            // MARK: For each interface ...
            var ptr = ifaddr
            while (ptr != nil) {
                
                let flags = Int32(ptr!.pointee.ifa_flags)
                var addr = ptr!.pointee.ifa_addr.pointee
                
                // MARK: Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
                if (flags & (IFF_UP | IFF_RUNNING | IFF_LOOPBACK)) == (IFF_UP | IFF_RUNNING) {
                    if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
                        
                        var mask = ptr!.pointee.ifa_netmask.pointee
                        
                        // MARK: Convert interface address to a human readable string:
                        let zero = CChar(0)
                        var hostname = [CChar](repeating: zero, count: Int(NI_MAXHOST))
                        var netmask = [CChar](repeating: zero, count: Int(NI_MAXHOST))
                        
                        // 获取 IP 地址
                        if (getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                                        nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                            
                            // 👉 修改点 1：截断 hostname 数组的空终止符，并安全解码为 UTF-8 字符串
                            let validHostname = hostname.prefix(while: { $0 != 0 }).map { UInt8(bitPattern: $0) }
                            let address = String(decoding: validHostname, as: UTF8.self)
                            
                            // 接口名称（ifa_name 是指针类型，可以直接使用 String(cString:)，无需修改）
                            let name = ptr!.pointee.ifa_name!
                            let ifname = String(cString: name)
                            
                            // 获取子网掩码
                            if (getnameinfo(&mask, socklen_t(mask.sa_len), &netmask, socklen_t(netmask.count),
                                            nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                                
                                // 👉 修改点 2：截断 netmask 数组的空终止符，并安全解码为 UTF-8 字符串
                                let validNetmask = netmask.prefix(while: { $0 != 0 }).map { UInt8(bitPattern: $0) }
                                let netmaskIP = String(decoding: validNetmask, as: UTF8.self)
                                
                                // 组装并添加到数组
                                let info = NetworkInterfaceInfo(name: ifname, ip: address, netmask: netmaskIP)
                                interfaces.append(info)
                            }
                        }
                    }
                }
                ptr = ptr!.pointee.ifa_next
            }
            freeifaddrs(ifaddr) // 释放 C 语言分配的内存，防止内存泄漏
        }
        return interfaces
    }
}
