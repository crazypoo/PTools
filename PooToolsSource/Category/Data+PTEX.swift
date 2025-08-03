//
//  Data+ImageTypeEX.swift
//  Diou
//
//  Created by ken lam on 2021/10/9.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import CommonCrypto
import CryptoKit

extension Data: PTProtocolCompatible {}

public extension Data {
    func formattedSize() -> String {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = [.useKB, .useMB, .useGB]

        return byteCountFormatter.string(fromByteCount: Int64(count))
    }
    
    func formattedString() -> String {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: self, options: [])
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
            if let formattedString = String(data: jsonData, encoding: .utf8) {
                return formattedString
            }
        } catch {
            PTNSLogConsole("Error formatting JSON: \(error)")
        }

        return ""
    }
    
    //MARK: 根據Data來獲取圖片的格式(底層方法)
    ///根據Data來獲取圖片的格式(底層方法)
    func detectImageType() -> PTAboutImageType {
        if self.count < 16 { return .UNKNOW }
        
        var value = [UInt8](repeating:0, count:1)
        
        self.copyBytes(to: &value, count: 1)
        
        switch value[0] {
        case 0x4D, 0x49:
            return .TIFF
        case 0x00:
            if self.count >= 12 {
                let heicHeader = self.subdata(in: Range(NSMakeRange(4, 8))!)
                if let heicString = String(data: heicHeader, encoding: .ascii) {
                    if heicString == "ftypheic" || heicString == "ftypheix" || heicString == "ftypmif1" || heicString == "ftypmsf1" {
                        return .HEIC
                    }
                }
            }
            return .ICO
        case 0x69:
            return .ICNS
        case 0x47:
            return .GIF
        case 0x89:
            return .PNG
        case 0xFF:
            return .JPEG
        case 0x42:
            return .BMP
        case 0x52:
            let subData = self.subdata(in: Range(NSMakeRange(0, 12))!)
            if let infoString = String(data: subData, encoding: .ascii) {
                if infoString.hasPrefix("RIFF") && infoString.hasSuffix("WEBP") {
                    return .WEBP
                }
            }
            break
        default:
            break
        }
        return .UNKNOW
    }
    
    //MARK: 根據Data來獲取圖片的格式
    ///根據Data來獲取圖片的格式
    static func detectImageType(with data: Data) -> PTAboutImageType {
        data.detectImageType()
    }
    
    //MARK: 根據圖片URL轉換成Data來獲取圖片的格式
    ///根據圖片URL轉換成Data來獲取圖片的格式
    static func detectImageType(with url: URL) -> PTAboutImageType {
        if let data = try? Data(contentsOf: url) {
            return data.detectImageType()
        } else {
            return .UNKNOW
        }
    }
    
    //MARK: 根據圖片FileUrl轉換成Data來獲取圖片的格式
    ///根據圖片FileUrl轉換成Data來獲取圖片的格式
    static func detectImageType(with filePath: String) -> PTAboutImageType {
        let pathUrl = URL(fileURLWithPath: filePath)
        if let data = try? Data(contentsOf: pathUrl) {
            return data.detectImageType()
        } else {
            return .UNKNOW
        }
    }
    
    //MARK: 根據圖片名字先獲取圖片然後轉換成Data來獲取圖片的格式
    ///根據圖片名字先獲取圖片然後轉換成Data來獲取圖片的格式
    static func detectImageType(with imageName: String,
                                bundle: Bundle = Bundle.main) -> PTAboutImageType {
        
        guard let path = bundle.path(forResource: imageName, ofType: "") else { return .UNKNOW }
        let pathUrl = URL(fileURLWithPath: path)
        if let data = try? Data(contentsOf: pathUrl) {
            return data.detectImageType()
        } else {
            return .UNKNOW
        }
    }
}

// MARK: - Methods
public extension Data {
    //MARK: Data轉String
    ///Data轉String
    func toString(encoding: String.Encoding) -> String? {
        String(data: self, encoding: encoding)
    }
    
    //MARK: Data轉Bytes
    ///Data轉Bytes
    func toBytes() -> [UInt8]{
        [UInt8](self)
    }
    
    //MARK: Data轉字典
    ///Data轉字典
    func toDict() -> Dictionary<String, Any>? {
        do{
            return try JSONSerialization.jsonObject(with: self, options: .allowFragments) as? [String: Any]
        } catch {
            PTNSLogConsole(error.localizedDescription,levelType: .Error,loggerType: .Data)
            return nil
        }
    }
    
    //MARK: 从给定的JSON数据返回一个基础对象。
    ///从给定的JSON数据返回一个基础对象。
    func toObject(options: JSONSerialization.ReadingOptions = []) throws -> Any {
        try JSONSerialization.jsonObject(with: self, options: options)
    }
    
    //MARK: 指定Model类型
    /// 指定Model类型
    func toModel<T>(_ type:T.Type) -> T? where T:Decodable {
        do {
            return try JSONDecoder().decode(type, from: self)
        } catch  {
            PTNSLogConsole("data to model error",levelType: .Error,loggerType: .Data)
            return nil
        }
    }
}

public extension PTPOP where Base == Data {
    ///hash计算
    func hashString(hashType: PTHashType,
                    lowercase: Bool = true) -> String {
        var output = NSMutableString()
        switch hashType {
            case .md5:
                output = NSMutableString(capacity: Int(CC_MD5_DIGEST_LENGTH))                
                let digestData = Insecure.MD5.hash(data: base)
                output.append(String(digestData.map { String(format: "%02hhx", $0)}.joined().prefix(32)))
            case .sha1:
                var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
                _ = base.withUnsafeBytes { (messageBytes) -> Bool in
                    CC_SHA1(messageBytes.baseAddress, CC_LONG(base.count), &digest)
                    return true
                }
                output = NSMutableString(capacity: Int(CC_SHA1_DIGEST_LENGTH))
                for byte in digest{
                    output.appendFormat("%02x", byte)
                }
            case .sha224:
                var digest = [UInt8](repeating: 0, count: Int(CC_SHA224_DIGEST_LENGTH))
                _ = base.withUnsafeBytes { (messageBytes) -> Bool in
                    CC_SHA224(messageBytes.baseAddress, CC_LONG(base.count), &digest)
                    return true
                }

                output = NSMutableString(capacity: Int(CC_SHA224_DIGEST_LENGTH))
                for byte in digest{
                    output.appendFormat("%02x", byte)
                }
            case .sha256:
                var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
                _ = base.withUnsafeBytes { (messageBytes) -> Bool in
                    CC_SHA256(messageBytes.baseAddress, CC_LONG(base.count), &digest)
                    return true
                }

                output = NSMutableString(capacity: Int(CC_SHA256_DIGEST_LENGTH))
                for byte in digest{
                    output.appendFormat("%02x", byte)
                }
            case .sha384:
                var digest = [UInt8](repeating: 0, count: Int(CC_SHA384_DIGEST_LENGTH))
                _ = base.withUnsafeBytes { (messageBytes) -> Bool in
                    CC_SHA384(messageBytes.baseAddress, CC_LONG(base.count), &digest)
                    return true
                }

                output = NSMutableString(capacity: Int(CC_SHA384_DIGEST_LENGTH))
                for byte in digest{
                    output.appendFormat("%02x", byte)
                }
            case .sha512:
                var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
                _ = base.withUnsafeBytes { (messageBytes) -> Bool in
                    CC_SHA512(messageBytes.baseAddress, CC_LONG(base.count), &digest)
                    return true
                }

                output = NSMutableString(capacity: Int(CC_SHA512_DIGEST_LENGTH))
                for byte in digest{
                    output.appendFormat("%02x", byte)
                }
        }

        if !lowercase {
            return String(output).uppercased()
        }
        return String(output)
    }
}
