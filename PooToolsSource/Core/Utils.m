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

#define HORIZONTAL_SPACE 30//水平间距
#define VERTICAL_SPACE 50//竖直间距
#define CG_TRANSFORM_ROTATION (M_PI_2 / 3)//旋转角度(正旋45度 || 反旋45度)

@implementation Utils
+(BOOL)isIPhoneXSeries
{
    return [PTUtils oc_isiPhoneSeries];
}
@end
