//
//  Data+ImageTypeEX.swift
//  Diou
//
//  Created by ken lam on 2021/10/9.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit

public extension Data
{
    func detectImageType() -> PTAboutImageType {
        if self.count < 16 { return .UNKNOW }
        
        var value = [UInt8](repeating:0, count:1)
        
        self.copyBytes(to: &value, count: 1)
        
        switch value[0] {
        case 0x4D, 0x49:
            return .TIFF
        case 0x00:
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
    
    static func detectImageType(with data: Data) -> PTAboutImageType {
        return data.detectImageType()
    }
    
    static func detectImageType(with url: URL) -> PTAboutImageType {
        if let data = try? Data(contentsOf: url) {
            return data.detectImageType()
        } else {
            return .UNKNOW
        }
    }
    
    static func detectImageType(with filePath: String) -> PTAboutImageType {
        let pathUrl = URL(fileURLWithPath: filePath)
        if let data = try? Data(contentsOf: pathUrl) {
            return data.detectImageType()
        } else {
            return .UNKNOW
        }
    }
    
    static func detectImageType(with imageName: String, bundle: Bundle = Bundle.main) -> PTAboutImageType? {
        
        guard let path = bundle.path(forResource: imageName, ofType: "") else { return nil }
        let pathUrl = URL(fileURLWithPath: path)
        if let data = try? Data(contentsOf: pathUrl) {
            return data.detectImageType()
        } else {
            return nil
        }
    }
}

// MARK: - Methods
public extension Data {
    /// 转 string
    func toString(encoding: String.Encoding) -> String? {
        return String(data: self, encoding: encoding)
    }
    
    func toBytes()->[UInt8]{
        return [UInt8](self)
    }
    
    func toDict()->Dictionary<String, Any>? {
        do{
            return try JSONSerialization.jsonObject(with: self, options: .allowFragments) as? [String: Any]
        }catch{
            print(error.localizedDescription)
            return nil
        }
    }
    /// 从给定的JSON数据返回一个基础对象。
    func toObject(options: JSONSerialization.ReadingOptions = []) throws -> Any {
        return try JSONSerialization.jsonObject(with: self, options: options)
    }
    /// 指定Model类型
    func toModel<T>(_ type:T.Type) -> T? where T:Decodable {
        do {
            return try JSONDecoder().decode(type, from: self)
        } catch  {
            print("data to model error")
            return nil
        }
    }
}
