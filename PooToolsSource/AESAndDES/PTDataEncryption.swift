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

@objcMembers
public class PTDataEncryption {
    
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
}
