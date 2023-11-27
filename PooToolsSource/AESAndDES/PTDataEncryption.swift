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
    
    //        /* Generate a key from a `password`. Optional if you already have a key */
    //        var key : Array<UInt8> = []
    //        do{
    //            key = try PKCS5.PBKDF2(
    //                password: password,
    //                salt: salt,
    //                iterations: 4096,
    //                keyLength: 32, /* AES-256 */
    //                variant: .sha2(.sha256)
    //            ).calculate()
    //        }
    //        catch{}
    //
    //        /* Generate random IV value. IV is public value. Either need to generate, or get it from elsewhere */
    //        let iv = AES.randomIV(AES.blockSize)
    
    //MARK: AES加密
    ///AES加密
    /// - Parameters:
    ///   - data: 加密內容
    ///   - key: key
    ///   - iv: iv(16位)
    ///   - handle: 輸出
    public static func aesEncryption(data:Data,
                                     key:String,
                                     iv:String) async throws -> String {
        /* Encrypt Data */
        let aes = try AES(key: key,iv: iv).encrypt(data.bytes)
        let encryptedData = Data(aes)
        return encryptedData.base64EncodedString()
    }
    
    //MARK: AES解密
    ///AES解密
    /// - Parameters:
    ///   - data: 加密內容
    ///   - key: key
    ///   - iv: iv(16位)
    ///   - handle: 輸出
    public static func aesDecrypt(data:Data,
                                  key:String,
                                  iv:String) async throws -> Data {
        /* Decrypt Data */
        let aes = try AES(key: key,iv: iv).decrypt(data.bytes)
        return Data(aes)
    }
    
    //MARK: AES加密(ECB)
    ///AES加密(ECB)
    /// - Parameters:
    ///   - data: 加密內容
    ///   - key: key
    ///   - handle: 輸出
    public static func aesECBEncryption(data:Data,
                                        key:String) async throws -> String {
        /* Encrypt Data */
        let aes = try AES(key: key.bytes, blockMode: ECB(),padding: .pkcs7).encrypt(data.bytes)
        let encryptedData = Data(aes)
        return encryptedData.base64EncodedString()
    }
    
    //MARK: AES解密(ECB)
    ///AES解密(ECB)
    /// - Parameters:
    ///   - data: 加密內容
    ///   - key: key
    ///   - handle: 輸出
    public static func aesECBDecrypt(data:Data,
                                     key:String) async throws -> Data {
        /* Decrypt Data */
        let aes = try AES(key: key.bytes, blockMode: ECB(),padding: .pkcs7).decrypt(data.bytes)
        return Data(aes)
    }
    
    //MARK: Des加密
    ///Des加密
    /// - Parameters:
    ///   - operation: 加密/解密
    ///   - key: key
    ///   - dataString: 被加密內容
    ///   - handle: 輸出
    public static func desCrypt(operation:CCOperation, 
                                key: String,
                                dataString:String!) async throws -> String {
        try await withUnsafeThrowingContinuation { continuation in
            guard let keyData = key.data(using: .utf8) else {
                continuation.resume(throwing: NSError(domain: "PT Crypt change error".localized(), code: 1, userInfo: nil) as Error)
                return
            }

            var cryptData: Data?

            if operation == kCCEncrypt {
                cryptData = dataString.data(using: .utf8)
            } else {
                cryptData = Data(base64Encoded: dataString, options: Data.Base64DecodingOptions(rawValue: 0))
            }

            guard cryptData != nil else {
                continuation.resume(throwing: NSError(domain: "PT Crypt had encode".localized(), code: 2, userInfo: nil) as Error)
                return
            }

            let algoritm: CCAlgorithm = CCAlgorithm(kCCAlgorithmDES)
            let option: CCOptions = CCOptions(kCCOptionPKCS7Padding)

            let keyBytes = [UInt8](keyData)
            let keyLength = kCCKeySizeDES

            let dataIn = [UInt8](cryptData!)
            let dataInlength = cryptData!.count

            let dataOutAvailable = Int(dataInlength + kCCBlockSizeDES)
            let dataOut = UnsafeMutablePointer<UInt8>.allocate(capacity: dataOutAvailable)
            let dataOutMoved = UnsafeMutablePointer<Int>.allocate(capacity: 1)

            dataOutMoved.initialize(to: 0)

            let cryptStatus = CCCrypt(operation, algoritm, option, keyBytes, keyLength, keyBytes, dataIn, dataInlength, dataOut, dataOutAvailable, dataOutMoved)

            guard CCStatus(cryptStatus) == CCStatus(kCCSuccess) else {
                continuation.resume(throwing: NSError(domain: "PT Crypt had encode".localized(), code: 2, userInfo: nil) as Error)
                return
            }

            var data: Data?
            data = Data(bytes: dataOut, count: dataOutMoved.pointee)

            dataOutMoved.deallocate()
            dataOut.deallocate()

            if operation == kCCEncrypt {
                data = data!.base64EncodedData()
            }
            continuation.resume(returning: String(data: data!, encoding: .utf8)!)
        }
    }
}
