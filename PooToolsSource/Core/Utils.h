//
//  Utils.h
//  login
//
//  Created by crazypoo on 14/7/10.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <MediaPlayer/MediaPlayer.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>

@interface Utils : NSObject
+(BOOL)isIPhoneXSeries;
/*! @brief 是否是空对象
 */
+(BOOL)checkObject:(NSObject *)obj;
/*! @brief 字典是否为空
 */
+(BOOL)checkDic:(NSDictionary *)dic;
/*! @brief 字符串是否为空
 */
+(BOOL)checkStringFunc:(NSString *)str;
@end
