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
    ///   - iv: iv
    ///   - handle: 輸出
    public static func aesEncryption(data:Data,key:String,iv:String,handle:(_ encryptionString:String)->Void)
    {
        /* Encrypt Data */
        do{
            let aes = try AES(key: key,iv: iv).encrypt(data.bytes)
            let encryptedData = Data(aes)
            handle(encryptedData.base64EncodedString())
        }
        catch{
            PTLocalConsoleFunction.share.pNSLog(error.localizedDescription)
        }
    }
    
    //MARK: AES解密
    ///AES解密
    /// - Parameters:
    ///   - data: 加密內容
    ///   - key: key
    ///   - iv: iv
    ///   - handle: 輸出
    public static func aseDecrypt(data:Data,key:String,iv:String,handle:(_ decryptData:Data)->Void)
    {
        /* Decrypt Data */
        do{
            let aes = try AES(key: key,iv: iv).decrypt(data.bytes)
            let decryptData = Data(aes)
            handle(decryptData)
        }
        catch{
            PTLocalConsoleFunction.share.pNSLog(error.localizedDescription)
        }
    }
    
    //MARK: Des加密
    ///Des加密
    /// - Parameters:
    ///   - operation: 加密/解密
    ///   - key: key
    ///   - dataString: 被加密內容
    ///   - handle: 輸出
    public static func desCrypt(operation:CCOperation, key: String,dataString:String!,handle:(_ outputString:String)->Void)
    {
        
        guard let keyData = key.data(using: .utf8) else {
            handle("")
            return
        }
        
        var cryptData: Data?
        
        if operation == kCCEncrypt
        {
            cryptData = dataString.data(using: .utf8)
        }
        else
        {
            cryptData = Data(base64Encoded: dataString, options: Data.Base64DecodingOptions(rawValue: 0))
        }
        
        guard cryptData != nil else {
            handle("")
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
            handle("")
            return
        }
        
        var data: Data?
        data = Data(bytes: dataOut, count: dataOutMoved.pointee)

        dataOutMoved.deallocate()
        dataOut.deallocate()
                
        if operation == kCCEncrypt
        {
            data = data!.base64EncodedData()
        }
        handle(String(data: data!, encoding: .utf8) ?? "")
    }
}
