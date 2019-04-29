//
//  PCarrie.m
//  test
//
//  Created by crazypoo on 15/5/12.
//  Copyright (c) 2015年 P. All rights reserved.
//

#import "PCarrie.h"

@implementation PCarrie

+(NSString *)currentRadioAccessTechnology
{
    CTTelephonyNetworkInfo *current = [[CTTelephonyNetworkInfo alloc] init];
    return current.currentRadioAccessTechnology;
}

+(NSMutableDictionary *)subscriberCellularProvider
{
    NSMutableDictionary *arr = [[NSMutableDictionary alloc]init];
    CTTelephonyNetworkInfo *current = [[CTTelephonyNetworkInfo alloc] init];
    [arr setObject:current.subscriberCellularProvider.carrierName forKey:@"carrierName"];
    [arr setObject:current.subscriberCellularProvider.mobileCountryCode forKey:@"mobileCountryCode"];
    [arr setObject:current.subscriberCellularProvider.mobileNetworkCode forKey:@"mobileNetworkCode"];
    [arr setObject:current.subscriberCellularProvider.isoCountryCode forKey:@"isoCountryCode"];
    [arr setObject:[NSNumber numberWithBool:current.subscriberCellularProvider.allowsVOIP] forKey:@"allowsVOIP"];
    return arr;
}

@end
