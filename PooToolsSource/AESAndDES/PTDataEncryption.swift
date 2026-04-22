//
//  PTDataEncryption.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 22/11/22.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import Foundation
import CryptoSwift
import CommonCrypto
import Security
import CryptoKit // 补充：Apple 原生的现代加密框架

// MARK: - 错误定义
public enum PTEncryptionError: LocalizedError {
    case keyGenerationFailed(String)
    case keychainOperationFailed(OSStatus)
    case encryptionFailed(String)
    case decryptionFailed(String)
    case invalidKeyOrData
    case unsupportedAlgorithm
    
    public var errorDescription: String? {
        switch self {
        case .keyGenerationFailed(let msg): return "密钥生成失败: \(msg)"
        case .keychainOperationFailed(let status): return "钥匙串操作失败，状态码: \(status)"
        case .encryptionFailed(let msg): return "加密失败: \(msg)"
        case .decryptionFailed(let msg): return "解密失败: \(msg)"
        case .invalidKeyOrData: return "无效的密钥或数据"
        case .unsupportedAlgorithm: return "不支持的加密算法"
        }
    }
}

@objcMembers
public class PTDataEncryption {
    
    // MARK: - RSA key 生成
    /// 生成 RSA 公私钥对
    /// - Parameters:
    ///   - groupIdentifier: 钥匙串的 Application Tag
    ///   - saveToKeychain: 是否保存到钥匙串
    /// - Returns: 包含私钥和公钥的 Data 元组
    public static func rsaPrivateAndPublicKey(groupIdentifier: String = "com.pt.rsa.private",
                                              saveToKeychain: Bool = true) throws -> (privateKey: Data, publicKey: Data) {
        let keyAttributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: saveToKeychain,
                kSecAttrApplicationTag as String: groupIdentifier
            ]
        ]
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(keyAttributes as CFDictionary, &error) else {
            let errorMsg = error?.takeRetainedValue().localizedDescription ?? "未知错误"
            PTNSLogConsole("生成私钥失败: \(errorMsg)")
            throw PTEncryptionError.keyGenerationFailed(errorMsg)
        }
        
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw PTEncryptionError.keyGenerationFailed("无法从私钥提取公钥")
        }
        
        guard let privateKeyData = SecKeyCopyExternalRepresentation(privateKey, &error) as Data? else {
            throw PTEncryptionError.keyGenerationFailed("导出私钥数据失败")
        }
        
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            throw PTEncryptionError.keyGenerationFailed("导出公钥数据失败")
        }
        
        if saveToKeychain {
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassKey,
                kSecAttrApplicationTag as String: groupIdentifier
            ]
            SecItemDelete(deleteQuery as CFDictionary)
            
            let saveQuery: [String: Any] = [
                kSecClass as String: kSecClassKey,
                kSecAttrApplicationTag as String: groupIdentifier,
                kSecValueRef as String: privateKey
            ]
            
            let status = SecItemAdd(saveQuery as CFDictionary, nil)
            if status != errSecSuccess {
                throw PTEncryptionError.keychainOperationFailed(status)
            }
        }
        
        return (privateKeyData, publicKeyData)
    }
    
    // MARK: - AES 加密 (CBC - CryptoSwift)
    public static func aesEncryption(data: Data, key: String, iv: String) throws -> String {
        guard let aes = try? AES(key: key, iv: iv).encrypt(data.bytes) else {
            throw PTEncryptionError.encryptionFailed("AES CBC encryption failed")
        }
        return Data(aes).base64EncodedString()
    }
    
    // MARK: - AES 解密 (CBC - CryptoSwift)
    public static func aesDecrypt(data: Data, key: String, iv: String) throws -> Data {
        guard let aes = try? AES(key: key, iv: iv).decrypt(data.bytes) else {
            throw PTEncryptionError.decryptionFailed("AES CBC decryption failed")
        }
        return Data(aes)
    }
    
    // MARK: - AES 加密 (ECB - CryptoSwift)
    public static func aesECBEncryption(data: Data, key: String) throws -> String {
        guard let aes = try? AES(key: key.bytes, blockMode: ECB(), padding: .pkcs7).encrypt(data.bytes) else {
            throw PTEncryptionError.encryptionFailed("AES ECB encryption failed")
        }
        return Data(aes).base64EncodedString()
    }
    
    // MARK: - AES 解密 (ECB - CryptoSwift)
    public static func aesECBDecrypt(data: Data, key: String) throws -> Data {
        guard let aes = try? AES(key: key.bytes, blockMode: ECB(), padding: .pkcs7).decrypt(data.bytes) else {
            throw PTEncryptionError.decryptionFailed("AES ECB decryption failed")
        }
        return Data(aes)
    }
    
    // MARK: - 【补充】AES-GCM 加解密 (原生 CryptoKit，推荐！)
    /// 使用 Apple 原生的 CryptoKit 进行 AES-GCM 加密，安全性远高于 ECB/CBC
    public static func aesGCMEncrypt(data: Data, keyString: String) throws -> String {
        let symmetricKey = SymmetricKey(data: SHA256.hash(data: Data(keyString.utf8)))
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
        guard let combinedData = sealedBox.combined else {
            throw PTEncryptionError.encryptionFailed("AES-GCM combined data nil")
        }
        return combinedData.base64EncodedString()
    }
    
    public static func aesGCMDecrypt(base64String: String, keyString: String) throws -> Data {
        guard let data = Data(base64Encoded: base64String) else {
            throw PTEncryptionError.invalidKeyOrData
        }
        let symmetricKey = SymmetricKey(data: SHA256.hash(data: Data(keyString.utf8)))
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: symmetricKey)
    }
    
    // MARK: - Des 加解密 (⚠️ 提示：DES 已不安全，仅建议为兼容老系统使用)
    public static func desCrypt(operation: CCOperation, key: String, dataString: String) throws -> String {
        guard let keyData = key.data(using: .utf8),
              let cryptData = operation == kCCEncrypt ? dataString.data(using: .utf8) : Data(base64Encoded: dataString)
        else {
            throw PTEncryptionError.invalidKeyOrData
        }

        let keyBytes = [UInt8](keyData)
        let dataIn = [UInt8](cryptData)
        let dataOutSize = cryptData.count + kCCBlockSizeDES
        let dataOut = UnsafeMutablePointer<UInt8>.allocate(capacity: dataOutSize)
        defer { dataOut.deallocate() }

        var dataOutMoved = 0
        let cryptStatus = CCCrypt(operation, CCAlgorithm(kCCAlgorithmDES), CCOptions(kCCOptionPKCS7Padding), keyBytes, kCCKeySizeDES, nil, dataIn, cryptData.count, dataOut, dataOutSize, &dataOutMoved)

        guard cryptStatus == kCCSuccess else {
            throw PTEncryptionError.encryptionFailed("DES crypt failed with status: \(cryptStatus)")
        }

        let resultData = Data(bytes: dataOut, count: dataOutMoved)
        return operation == kCCEncrypt ? resultData.base64EncodedString() : String(data: resultData, encoding: .utf8) ?? ""
    }
    
    // MARK: - RSA 公私钥转换与加解密
    public static func stripPEMHeaders(pemString: String) -> String {
        return pemString
            .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
    }
    
    public static func publicKeyFromString(_ publicKeyString: String) -> SecKey? {
        let keyString = stripPEMHeaders(pemString: publicKeyString)
        guard let keyData = Data(base64Encoded: keyString) else {
            PTNSLogConsole("Failed to decode Base64 public key string")
            return nil
        }
        
        let keyDict: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: 2048,
            kSecReturnPersistentRef as String: true
        ]
        
        return SecKeyCreateWithData(keyData as CFData, keyDict as CFDictionary, nil)
    }
    
    public static func encryptWithRSA(plainText: String, publicKey: SecKey) throws -> Data {
        let data = Data(plainText.utf8)
        let algorithm: SecKeyAlgorithm = .rsaEncryptionPKCS1

        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, algorithm) else {
            throw PTEncryptionError.unsupportedAlgorithm
        }

        var error: Unmanaged<CFError>?
        guard let cfEncryptedData = SecKeyCreateEncryptedData(publicKey, algorithm, data as CFData, &error) else {
            let errorMsg = error?.takeRetainedValue().localizedDescription ?? "未知错误"
            throw PTEncryptionError.encryptionFailed(errorMsg)
        }

        return cfEncryptedData as Data
    }
    
    public static func decryptWithRSA(encryptedData: Data, privateKey: SecKey) throws -> String {
        let algorithm: SecKeyAlgorithm = .rsaEncryptionPKCS1

        guard SecKeyIsAlgorithmSupported(privateKey, .decrypt, algorithm) else {
            throw PTEncryptionError.unsupportedAlgorithm
        }

        var error: Unmanaged<CFError>?
        guard let decryptedCFData = SecKeyCreateDecryptedData(privateKey, algorithm, encryptedData as CFData, &error) else {
            let errorMsg = error?.takeRetainedValue().localizedDescription ?? "未知错误"
            throw PTEncryptionError.decryptionFailed(errorMsg)
        }

        let decryptedData = decryptedCFData as Data
        guard let resultString = String(data: decryptedData, encoding: .utf8) else {
            throw PTEncryptionError.decryptionFailed("无法将解密后的 Data 转换为 String")
        }
        return resultString
    }
}

// MARK: - 【Java 兼容专用】AES-GCM 加解密
extension PTDataEncryption {
    
    /// 与 Java 对接的 AES-GCM 加密
    /// - Parameters:
    ///   - data: 要加密的明文数据
    ///   - keyString: 密钥
    ///   - ivString: 向量 (Java 通常要求 12 字节的 nonce)
    /// - Returns: 返回 [密文 + Tag] 拼接后的 Base64 字符串 (这是 Java 最喜欢的格式)
    public static func aesGCMEncryptForJava(data: Data, keyString: String, ivString: String) throws -> String {
        let symmetricKey = SymmetricKey(data: Data(keyString.utf8))
        
        // 1. 指定 Nonce (IV)
        guard let nonceData = ivString.data(using: .utf8),
              let nonce = try? AES.GCM.Nonce(data: nonceData) else {
            throw PTEncryptionError.invalidKeyOrData
        }
        
        // 2. 加密
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey, nonce: nonce)
        
        // 3. 按照 Java 的习惯拼接: 密文 + Tag
        var javaFormatData = Data()
        javaFormatData.append(sealedBox.ciphertext)
        javaFormatData.append(sealedBox.tag)
        
        return javaFormatData.base64EncodedString()
    }
    
    /// 与 Java 对接的 AES-GCM 解密
    /// - Parameters:
    ///   - base64String: Java 传过来的 Base64 字符串 (格式通常为：密文 + Tag)
    ///   - keyString: 密钥
    ///   - ivString: 向量 (Java 加密时使用的 nonce)
    public static func aesGCMDecryptFromJava(base64String: String, keyString: String, ivString: String) throws -> Data {
        guard let encryptedData = Data(base64Encoded: base64String),
              let nonceData = ivString.data(using: .utf8) else {
            throw PTEncryptionError.invalidKeyOrData
        }
        
        let symmetricKey = SymmetricKey(data: Data(keyString.utf8))
        guard let nonce = try? AES.GCM.Nonce(data: nonceData) else {
            throw PTEncryptionError.invalidKeyOrData
        }
        
        // Java 传过来的数据包含了密文和 16 字节的 Tag，需要拆分开给 CryptoKit
        let tagLength = 16
        guard encryptedData.count > tagLength else {
            throw PTEncryptionError.decryptionFailed("数据长度异常，无法提取 Tag")
        }
        
        let ciphertext = encryptedData.prefix(encryptedData.count - tagLength)
        let tag = encryptedData.suffix(tagLength)
        
        // 组装成 Apple 的 SealedBox 再解密
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
        return try AES.GCM.open(sealedBox, using: symmetricKey)
    }
}
