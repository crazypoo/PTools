//
//  PTDataEncryption.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 22/11/22.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import CryptoSwift
import CommonCrypto
import Security

@objcMembers
public class PTDataEncryption {
    //MARK: RSA key生成
    public static func rsaPrivateAndPublicKey(groupIdentifier: String = "com.pt.rsa.private",
                                              saveToKeychain: Bool = true) -> (Bool, Data?, Data?) {
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
            PTNSLogConsole("生成私钥失败: \(error?.takeRetainedValue().localizedDescription ?? "未知错误")")
            return (false, nil, nil)
        }
        
        let publicKey = SecKeyCopyPublicKey(privateKey)!
        
        guard let privateKeyData = SecKeyCopyExternalRepresentation(privateKey, &error) as Data? else {
            PTNSLogConsole("导出私钥失败: \(error?.takeRetainedValue().localizedDescription ?? "未知错误")")
            return (false, nil, nil)
        }
        
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            PTNSLogConsole("导出公钥失败: \(error?.takeRetainedValue().localizedDescription ?? "未知错误")")
            return (false, nil, nil)
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
                PTNSLogConsole("存储私钥到钥匙串失败: \(status)")
                return (false, nil, nil)
            }
        }
        
        return (true, privateKeyData, publicKeyData)
    }
    
    //MARK: AES加密
    public static func aesEncryption(data: Data, key: String, iv: String) async throws -> String {
        guard let aes = try? AES(key: key, iv: iv).encrypt(data.bytes) else {
            throw createError("AES encryption failed")
        }
        return Data(aes).base64EncodedString()
    }
    
    //MARK: AES解密
    public static func aesDecrypt(data: Data, key: String, iv: String) async throws -> Data {
        guard let aes = try? AES(key: key, iv: iv).decrypt(data.bytes) else {
            throw createError("AES decryption failed")
        }
        return Data(aes)
    }
    
    //MARK: AES加密(ECB)
    public static func aesECBEncryption(data: Data, key: String) async throws -> String {
        guard let aes = try? AES(key: key.bytes, blockMode: ECB(), padding: .pkcs7).encrypt(data.bytes) else {
            throw createError("AES ECB encryption failed")
        }
        return Data(aes).base64EncodedString()
    }
    
    //MARK: AES解密(ECB)
    public static func aesECBDecrypt(data: Data, key: String) async throws -> Data {
        guard let aes = try? AES(key: key.bytes, blockMode: ECB(), padding: .pkcs7).decrypt(data.bytes) else {
            throw createError("AES ECB decryption failed")
        }
        return Data(aes)
    }
    
    //MARK: Des加密
    public static func desCrypt(operation: CCOperation, key: String, dataString: String) async throws -> String {
        return try await withUnsafeThrowingContinuation { continuation in
            do {
                let result = try performDESCrypt(operation: operation, key: key, dataString: dataString)
                continuation.resume(returning: result)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private static func performDESCrypt(operation: CCOperation, key: String, dataString: String) throws -> String {
        guard let keyData = key.data(using: .utf8),
              let cryptData = operation == kCCEncrypt ? dataString.data(using: .utf8) : Data(base64Encoded: dataString)
        else {
            throw createError("Invalid key or data")
        }

        let keyBytes = [UInt8](keyData)
        let dataIn = [UInt8](cryptData)
        let dataOutSize = cryptData.count + kCCBlockSizeDES
        let dataOut = UnsafeMutablePointer<UInt8>.allocate(capacity: dataOutSize)
        defer { dataOut.deallocate() }

        var dataOutMoved = 0
        let cryptStatus = CCCrypt(operation, CCAlgorithm(kCCAlgorithmDES), CCOptions(kCCOptionPKCS7Padding), keyBytes, kCCKeySizeDES, keyBytes, dataIn, cryptData.count, dataOut, dataOutSize, &dataOutMoved)

        guard cryptStatus == kCCSuccess else {
            throw createError("DES crypt failed with status: \(cryptStatus)")
        }

        let resultData = Data(bytes: dataOut, count: dataOutMoved)
        return operation == kCCEncrypt ? resultData.base64EncodedString() : String(data: resultData, encoding: .utf8) ?? ""
    }

    private static func createError(_ message: String) -> NSError {
        return NSError(domain: message, code: 1, userInfo: nil)
    }
    
    //MARK: RSA加密
    static func stripPEMHeaders(pemString: String) -> String {
        return pemString
            .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
    }
    
    static func publicKeyFromString(_ publicKeyString: String) -> SecKey? {
        // 去掉 PEM 公钥头尾标识
        let keyString = stripPEMHeaders(pemString: publicKeyString)
        
        // 将 Base64 字符串解码为 Data
        guard let keyData = Data(base64Encoded: keyString) else {
            PTNSLogConsole("Failed to decode Base64 public key string")
            return nil
        }
        
        // RSA 公钥标头 (如果需要的话，可以尝试添加)
        let keySize = 2048
        let keyDict: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: keySize,
            kSecReturnPersistentRef as String: true
        ]
        
        // 使用 Security 框架将 Data 转换为 SecKey
        guard let publicKey = SecKeyCreateWithData(keyData as CFData, keyDict as CFDictionary, nil) else {
            PTNSLogConsole("Failed to create public key from data")
            return nil
        }
        
        return publicKey
    }
    
    static func encryptWithRSA(plainText: String, publicKey: SecKey) -> Data? {
        let buffer = [UInt8](plainText.utf8)
        let keySize = SecKeyGetBlockSize(publicKey)
        var cipherText = [UInt8](repeating: 0, count: keySize)
        var cipherTextLen = keySize
        
        let status = SecKeyEncrypt(publicKey, SecPadding.PKCS1, buffer, buffer.count, &cipherText, &cipherTextLen)
        
        if status == errSecSuccess {
            return Data(cipherText)
        } else {
            PTNSLogConsole("Error encrypting: \(status)")
            return nil
        }
    }
    
    static func decryptWithRSA(encryptedData: Data, privateKey: SecKey) -> String? {
        let keySize = SecKeyGetBlockSize(privateKey)
        var plainText = [UInt8](repeating: 0, count: keySize)
        var plainTextLen = keySize
        
        let status = SecKeyDecrypt(privateKey, SecPadding.PKCS1, [UInt8](encryptedData), encryptedData.count, &plainText, &plainTextLen)
        
        if status == errSecSuccess {
            return String(bytes: plainText, encoding: .utf8)
        } else {
            PTNSLogConsole("Error decrypting: \(status)")
            return nil
        }
    }
}
