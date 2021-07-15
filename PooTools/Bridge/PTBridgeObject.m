//
//  PTBridgeObject.m
//  PTBridgeObject
//
//  Created by ken lam on 2021/7/15.
//  Copyright © 2021 crazypoo. All rights reserved.
//

#import "PTBridgeObject.h"
#import "PMacros.h"

@implementation PTBridgeObject
+(BOOL)kStringIsEmpty:(NSString *)str
{
    return kStringIsEmpty(str);
}

+(void)gcdAfter:(double)times handle:(void(^)(void))block
{
    GCDAfter(times, ^{
        block();
    });
}

+(void)viewBorderRadius:(UIView *)someViews withRadius:(CGFloat)radius withWidth:(CGFloat)width withColor:(UIColor *)color
{
    kViewBorderRadius(someViews, radius, width, color);
}
@end
