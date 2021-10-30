//
//  SecurityUtil.h
//  Smile
//
//  Created by apple on 15/8/25.
//  Copyright (c) 2015年 Weconex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LGTMBase64.h"

@interface SecurityUtil : NSObject 

#pragma mark - base64
/*! @brief 字符串加密(Base64)
 */
+ (NSString*)encodeBase64String:(NSString *)input;

/*! @brief 字符串解密(Base64)
 */
+ (NSString*)decodeBase64String:(NSString *)input;

/*! @brief NSData加密(Base64)
 */
+ (NSString*)encodeBase64Data:(NSData *)data;

/*! @brief NSData解密(Base64)
 */
+ (NSString*)decodeBase64Data:(NSData *)data;

#pragma mark - AES加密
/*! @brief 将string转成带密码的数据(RSA)
 */
+(NSString*)encryptAESData:(NSString*)string
                  enterKey:(NSString *)key
                   enterIv:(NSString *)iv;

/*! @brief 将带密码的数据转成string(RSA)
 */
+(NSString*)decryptAESData:(NSString*)string
                  enterKey:(NSString *)key
                   enterIv:(NSString *)iv;

#pragma mark - DES加密
/*! @brief 加密(DES)
 */
+ (NSString*)encrypt:(NSString*)plainText
             withKey:(NSString *)key;

/*! @brief 解密(DES)
 */
+ (NSString*)decrypt:(NSString*)encryptText
             withKey:(NSString *)key;
@end
