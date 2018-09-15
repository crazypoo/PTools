//
//  SecurityUtil.h
//  Smile
//
//  Created by apple on 15/8/25.
//  Copyright (c) 2015年 Weconex. All rights reserved.
//

#import "SecurityUtil.h"
#import <CommonCrypto/CommonCryptor.h>
#import "NSData+AES.h"

#define gDESIv             @"01234567"

@implementation SecurityUtil

#pragma mark - base64
+ (NSString*)encodeBase64String:(NSString * )input
{
    NSData *data = [input dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]; 
    data = [LGTMBase64 encodeData:data];
    NSString *base64String = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	return base64String;
}

+ (NSString*)decodeBase64String:(NSString * )input
{
    NSData *data = [input dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]; 
    data = [LGTMBase64 decodeData:data];
    NSString *base64String = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	return base64String;
} 

+ (NSString*)encodeBase64Data:(NSData *)data
{
	data = [LGTMBase64 encodeData:data];
    NSString *base64String = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	return base64String;
}

+ (NSString*)decodeBase64Data:(NSData *)data
{
	data = [LGTMBase64 decodeData:data];
    NSString *base64String = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	return base64String;
}

#pragma mark - AES加密
//将string转成带密码的data
+(NSString*)encryptAESData:(NSString*)string enterKey:(NSString *)key enterIv:(NSString *)iv
{
    //将nsstring转化为nsdata
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    //使用密码对nsdata进行加密
    NSData *encryptedData = [data AES128EncryptWithKey:key gIv:iv];
    //返回进行base64进行转码的加密字符串
    return [self encodeBase64Data:encryptedData];
}

#pragma mark - AES解密
//将带密码的data转成string
+(NSString*)decryptAESData:(NSString *)string enterKey:(NSString *)key enterIv:(NSString *)iv
{
    //base64解密
    NSData *decodeBase64Data = [LGTMBase64 decodeString:string];
    //使用密码对data进行解密
    NSData *decryData = [decodeBase64Data AES128DecryptWithKey:key gIv:iv];
    //将解了密码的nsdata转化为nsstring
    NSString *str = [[NSString alloc] initWithData:decryData encoding:NSUTF8StringEncoding];
    return str;
}

+ (NSString*)encrypt:(NSString*)plainText withKey:(NSString *)key
{
    NSData* data = [plainText dataUsingEncoding:NSUTF8StringEncoding];
    size_t plainTextBufferSize = [data length];
    const void *vplainText = (const void *)[data bytes];
    
    CCCryptorStatus ccStatus;
    uint8_t *bufferPtr = NULL;
    size_t bufferPtrSize = 0;
    size_t movedBytes = 0;
    
    bufferPtrSize = (plainTextBufferSize + kCCBlockSize3DES) & ~(kCCBlockSize3DES - 1);
    bufferPtr = malloc( bufferPtrSize * sizeof(uint8_t));
    memset((void *)bufferPtr, 0x0, bufferPtrSize);
    
    const void *vkey = (const void *) [key UTF8String];
    const void *vinitVec = (const void *) [gDESIv UTF8String];
    
    ccStatus = CCCrypt(
                       kCCEncrypt,
                       kCCAlgorithm3DES,
                       kCCOptionPKCS7Padding,
                       vkey,
                       kCCKeySize3DES,
                       vinitVec,
                       vplainText,
                       plainTextBufferSize,
                       (void *)bufferPtr,
                       bufferPtrSize,
                       &movedBytes
                       );
    
    NSData *myData = [NSData dataWithBytes:(const void *)bufferPtr length:(NSUInteger)movedBytes];
    NSString *result = [LGTMBase64 stringByEncodingData:myData];
    return result;
}

#pragma mark - DES
+ (NSString*)decrypt:(NSString*)encryptText withKey:(NSString *)key
{
    NSData *encryptData = [LGTMBase64 decodeData:[encryptText dataUsingEncoding:NSUTF8StringEncoding]];
    size_t plainTextBufferSize = [encryptData length];
    const void *vplainText = [encryptData bytes];
    
    CCCryptorStatus ccStatus;
    uint8_t *bufferPtr = NULL;
    size_t bufferPtrSize = 0;
    size_t movedBytes = 0;
    
    bufferPtrSize = (plainTextBufferSize + kCCBlockSize3DES) & ~(kCCBlockSize3DES - 1);
    bufferPtr = malloc( bufferPtrSize * sizeof(uint8_t));
    memset((void *)bufferPtr, 0x0, bufferPtrSize);
    
    const void *vkey = (const void *) [key UTF8String];
    const void *vinitVec = (const void *) [gDESIv UTF8String];
    
    ccStatus = CCCrypt(
                       kCCDecrypt,
                       kCCAlgorithm3DES,
                       kCCOptionPKCS7Padding,
                       vkey,
                       kCCKeySize3DES,
                       vinitVec,
                       vplainText,
                       plainTextBufferSize,
                       (void *)bufferPtr,
                       bufferPtrSize,
                       &movedBytes
                       );
    
    NSString *result = [[NSString alloc] initWithData:[NSData dataWithBytes:(const void *)bufferPtr
                                                                     length:(NSUInteger)movedBytes] encoding:NSUTF8StringEncoding];
    return result;
}
@end
