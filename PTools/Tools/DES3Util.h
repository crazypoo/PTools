//
//  DES3Util.h
//  DES
//
//  Created by crazypoo on 14/9/9.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DES3Util : NSObject {
    
}

// 加密方法
+ (NSString*)encrypt:(NSString*)plainText withKey:(NSString *)key;

// 解密方法
+ (NSString*)decrypt:(NSString*)encryptText withKey:(NSString *)key;

@end

