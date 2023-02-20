//
//  Utils.m
//  login
//
//  Created by crazypoo on 14/7/10.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import "Utils.h"
#import "PMacros.h"

#import <PooTools/PooTools-Swift.h>

@implementation Utils
+(BOOL)isIPhoneXSeries
{
    return [PTUtils oc_isiPhoneSeries];
}

+(BOOL)checkObject:(NSObject *)obj
{
    return (obj == nil || [obj isKindOfClass:[NSNull class]] || ([obj respondsToSelector:@selector(length)] && [(NSData *)obj length] == 0) || ([obj respondsToSelector:@selector(count)] && [(NSArray *)obj count] == 0));
}

+(BOOL)checkDic:(NSDictionary *)dic
{
    return (dic == nil || [dic isKindOfClass:[NSNull class]] || dic.allKeys == 0);
}

+(BOOL)checkStringFunc:(NSString *)str
{
    return ([str isKindOfClass:[NSNull class]] || str == nil || [str length] < 1 ? YES : NO );
}

@end
