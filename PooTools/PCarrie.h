//
//  PCarrie.h
//  test
//
//  Created by crazypoo on 15/5/12.
//  Copyright (c) 2015年 P. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

@interface PCarrie : NSObject

/*! @brief 获取手机当前运营商
 */
+(NSString *)currentRadioAccessTechnology;

/*! @brief 获取手机当前运营商其他信息
 */
+(NSMutableDictionary *)subscriberCellularProvider;
@end
