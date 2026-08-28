//
//  String+PTEX+Crypto.swift
//  PooTools
//
//  English: String encryption, hashing, and scalar conversion helpers.
//  Español: Ayudantes de cifrado, hash y conversión escalar para String.
//  中文：String 加密、哈希和标量转换辅助方法。
//

import Foundation
import CommonCrypto

private extension PTPOP where Base: ExpressibleByStringLiteral {
    // English: Keep the compatibility value local so the split file does not widen private API visibility.
    // Español: Mantén local el valor de compatibilidad para no ampliar la visibilidad de la API privada.
    // 中文：将兼容值保留在本文件内，避免拆分时扩大私有 API 的可见性。
    var cryptoStringValue: String {
        String(describing: base)
    }
}

// MARK: AES, AES128, DES, DES3, CAST, RC2, RC4, Blowfish 多种加密
/**
 iOS中填充规则PKCS7,加解密模式ECB(无补码,CCCrypt函数中对应的nil),字符集UTF8,输出base64(可以自己改hex)
 */
//MARK: 加密模式
public enum DDYSCAType {
    case AES, AES128, DES, DES3, CAST, RC2, RC4, Blowfish
    var infoTuple: (algorithm: CCAlgorithm, digLength: Int, keyLength: Int) {
        switch self {
        case .AES:
            return (CCAlgorithm(kCCAlgorithmAES), Int(kCCKeySizeAES128), Int(kCCKeySizeAES128))
        case .AES128:
            return (CCAlgorithm(kCCAlgorithmAES128), Int(kCCBlockSizeAES128), Int(kCCKeySizeAES256))
        case .DES:
            return (CCAlgorithm(kCCAlgorithmDES), Int(kCCBlockSizeDES), Int(kCCKeySizeDES))
        case .DES3:
            return (CCAlgorithm(kCCAlgorithm3DES), Int(kCCBlockSize3DES), Int(kCCKeySize3DES))
        case .CAST:
            return (CCAlgorithm(kCCAlgorithmCAST), Int(kCCBlockSizeCAST), Int(kCCKeySizeMaxCAST))
        case .RC2:
            return (CCAlgorithm(kCCAlgorithmRC2), Int(kCCBlockSizeRC2), Int(kCCKeySizeMaxRC2))
        case .RC4:
            return (CCAlgorithm(kCCAlgorithmRC4), Int(kCCBlockSizeRC2), Int(kCCKeySizeMaxRC4))
        case .Blowfish:return (CCAlgorithm(kCCAlgorithmBlowfish), Int(kCCBlockSizeBlowfish), Int(kCCKeySizeMaxBlowfish))
        }
    }
}

public extension PTPOP where Base: ExpressibleByStringLiteral {
    
    //MARK: 字符串 AES, AES128, DES, DES3, CAST, RC2, RC4, Blowfish 多种加密
    ///字符串 AES, AES128, DES, DES3, CAST, RC2, RC4, Blowfish 多种加密
    /// - Parameters:
    ///   - cryptType: 加密类型
    ///   - key: 加密的key
    ///   - encode: 编码还是解码
    ///   - encryptIV: 偏移量
    /// - Returns: 编码或者解码后的字符串
    func scaCrypt(cryptType: DDYSCAType,
                  key: String?,
                  encode: Bool,
                  encryptIV: String = "1") -> String? {
        let strData = encode ? cryptoStringValue.data(using: .utf8) : Data(base64Encoded: cryptoStringValue)
        guard let strData,
              let keyData = key?.data(using: .utf8),
              let encryptIVData = encryptIV.data(using: .utf8),
              let cryptData = NSMutableData(length: strData.count + cryptType.infoTuple.digLength) else {
            return nil
        }
        // 创建数据编码后的指针
        let dataPointer = UnsafeRawPointer((strData as NSData).bytes)
        // 获取转码后数据的长度
        let dataLength = size_t(strData.count)
        
        // 2、后台对应的加密key
        // 将加密或解密的密钥转化为Data数据
        // 创建密钥的指针
        let keyPointer = UnsafeRawPointer((keyData as NSData).bytes)
        // 设置密钥的长度
        let keyLength = cryptType.infoTuple.keyLength
        /// 3、后台对应的加密 IV，这个是跟后台商量的iv偏移量
        let encryptIVDataBytes = UnsafeRawPointer((encryptIVData as NSData).bytes)
        // 获取返回数据(cryptData)的指针
        let cryptPointer = UnsafeMutableRawPointer(mutating: cryptData.mutableBytes)
        // 获取接收数据的长度
        let cryptDataLength = size_t(cryptData.length)
        // 加密或则解密后的数据长度
        var cryptBytesLength:size_t = 0
        // 是解密或者加密操作(CCOperation 是32位的)
        let operation = encode ? CCOperation(kCCEncrypt) : CCOperation(kCCDecrypt)
        // 算法类型
        let algoritm: CCAlgorithm = CCAlgorithm(cryptType.infoTuple.algorithm)
        // 设置密码的填充规则（ PKCS7 & ECB 两种填充规则）
        let options: CCOptions = UInt32(kCCOptionPKCS7Padding) | UInt32(kCCOptionECBMode)
        // 执行算法处理
        let cryptStatus = CCCrypt(operation, algoritm, options, keyPointer, keyLength, encryptIVDataBytes, dataPointer, dataLength, cryptPointer, cryptDataLength, &cryptBytesLength)
        // 结果字符串初始化
        var resultString: String?
        // 通过返回状态判断加密或者解密是否成功
        if CCStatus(cryptStatus) == CCStatus(kCCSuccess) {
            cryptData.length = cryptBytesLength
            if encode {
                resultString = cryptData.base64EncodedString(options: .lineLength64Characters)
            } else {
                resultString = NSString(data: cryptData as Data, encoding: String.Encoding.utf8.rawValue) as String?
            }
        }
        return resultString
    }
}

//MARK: SHA1, SHA224, SHA256, SHA384, SHA512
/**
 - 安全哈希算法（Secure Hash Algorithm）主要适用于数字签名标准（Digital Signature Standard DSS）里面定义的数字签名算法（Digital Signature Algorithm DSA）。对于长度小于2^64位的消息，SHA1会产生一个160位的消息摘要。当接收到消息的时候，这个消息摘要可以用来验证数据的完整性。在传输的过程中，数据很可能会发生变化，那么这时候就会产生不同的消息摘要。当让除了SHA1还有SHA256以及SHA512等。
 - SHA1有如下特性：不可以从消息摘要中复原信息；两个不同的消息不会产生同样的消息摘要
 - SHA1 SHA256 SHA512 这4种本质都是摘要函数，不通在于长度 SHA1是160位，SHA256是256位，SHA512是512位
 */
//MARK: 加密类型
public enum DDYSHAType {
    case SHA1, SHA224, SHA256, SHA384, SHA512
    var infoTuple: (algorithm: CCHmacAlgorithm,
                    length: Int) {
        switch self {
        case .SHA1:
            return (algorithm: CCHmacAlgorithm(kCCHmacAlgSHA1), length: Int(CC_SHA1_DIGEST_LENGTH))
        case .SHA224:
            return (algorithm: CCHmacAlgorithm(kCCHmacAlgSHA224), length: Int(CC_SHA224_DIGEST_LENGTH))
        case .SHA256:
            return (algorithm: CCHmacAlgorithm(kCCHmacAlgSHA256), length: Int(CC_SHA256_DIGEST_LENGTH))
        case .SHA384:
            return (algorithm: CCHmacAlgorithm(kCCHmacAlgSHA384), length: Int(CC_SHA384_DIGEST_LENGTH))
        case .SHA512:
            return (algorithm: CCHmacAlgorithm(kCCHmacAlgSHA512), length: Int(CC_SHA512_DIGEST_LENGTH))
        }
    }
}

public extension PTPOP where Base: ExpressibleByStringLiteral {
    
    //MARK: SHA1, SHA224, SHA256, SHA384, SHA512 加密
    ///SHA1, SHA224, SHA256, SHA384, SHA512 加密
    /// - Parameters:
    ///   - cryptType: 加密类型，默认是 SHA1 加密
    ///   - key: 加密的key
    ///   - lower: 大写还是小写，默认小写
    /// - Returns: 加密以后的字符串
    func shaCrypt(cryptType: DDYSHAType = .SHA1,
                  key: String?,
                  lower: Bool = true) -> String? {
        guard let cStr = cryptoStringValue.cString(using: String.Encoding.utf8) else {
            return nil
        }
        let strLen  = strlen(cStr)
        let digLen = cryptType.infoTuple.length
        let buffer = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digLen)
        let hash = NSMutableString()
        
        if let key, !key.isEmpty, let cKey = key.cString(using: String.Encoding.utf8) {
            let keyLen = key.lengthOfBytes(using: String.Encoding.utf8)
            CCHmac(cryptType.infoTuple.algorithm, cKey, keyLen, cStr, strLen, buffer)
        } else {
            switch cryptType {
            case .SHA1:     CC_SHA1(cStr,   (CC_LONG)(strlen(cStr)), buffer)
            case .SHA224:   CC_SHA224(cStr, (CC_LONG)(strlen(cStr)), buffer)
            case .SHA256:   CC_SHA256(cStr, (CC_LONG)(strlen(cStr)), buffer)
            case .SHA384:   CC_SHA384(cStr, (CC_LONG)(strlen(cStr)), buffer)
            case .SHA512:   CC_SHA512(cStr, (CC_LONG)(strlen(cStr)), buffer)
            }
        }
        for i in 0..<digLen {
            if lower {
                hash.appendFormat("%02x", buffer[i])
            } else {
                hash.appendFormat("%02X", buffer[i])
            }
        }
        buffer.deallocate()
        return hash as String
    }
}

// MARK: 字符串的转换
public extension PTPOP where Base: ExpressibleByStringLiteral {
    
    // MARK: 字符串 转 CGFloat
    /// 字符串 转 Float
    /// - Returns: CGFloat
    func toCGFloat() -> CGFloat? {
        if let doubleValue = Double(cryptoStringValue) {
            return CGFloat(doubleValue)
        }
        return nil
    }
    
    // MARK: 字符串转 Bool
    /// 字符串转 Bool
    /// - Returns: Bool
    func toBool() -> Bool? {
        switch cryptoStringValue.lowercased() {
        case "true", "t", "yes", "y", "1":
            return true
        case "false", "f", "no", "n", "0":
            return false
        default:
            return nil
        }
    }
    
    // MARK: 字符串转 Int
    /// 字符串转 Int
    /// - Returns: Int
    func toInt() -> Int? {
        if let num = NumberFormatter().number(from: cryptoStringValue) {
            return num.intValue
        } else {
            return nil
        }
    }
    
    // MARK: 字符串转 Double
    /// 字符串转 Double
    /// - Returns: Double
    func toDouble() -> Double? {
        if let num = NumberFormatter().number(from: cryptoStringValue) {
            return num.doubleValue
        } else {
            return nil
        }
    }
    
    // MARK: 字符串转 Float
    /// 字符串转 Float
    /// - Returns: Float
    func toFloat() -> Float? {
        if let num = NumberFormatter().number(from: cryptoStringValue) {
            return num.floatValue
        } else {
            return nil
        }
    }
    
    // MARK: 字符串转 NSString
    /// 字符串转 NSString
    var toNSString: NSString {
        cryptoStringValue as NSString
    }
    
    // MARK: 字符串转 Int64
    /// 字符串转 Int64
    var toInt64Value: Int64? {
        Int64(cryptoStringValue)
    }
    
    // MARK: 字符串转 NSNumber
    /// 字符串转 NSNumber
    var toNumber: NSNumber? {
        self.toDouble()?.pt.number
    }
}
