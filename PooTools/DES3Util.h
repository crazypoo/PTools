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

/*! @brief 加密(DES)
 */
+ (NSString*)encrypt:(NSString*)plainText withKey:(NSString *)key;

/*! @brief 解密(DES)
 */
+ (NSString*)decrypt:(NSString*)encryptText withKey:(NSString *)key;

@end

