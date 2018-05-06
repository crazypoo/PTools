//
//  UIColor+Random.m
//
//  Created by Gavin He on 13-9-5.
//  Copyright (c) 2013年 Gavin He. All rights reserved.
//

#import "UIColor+Random.h"

@implementation UIColor (Random)

+(UIColor*)randomColor{
    return [UIColor randomColorWithAlpha:1.0];
}

+(UIColor*)randomColorWithAlpha:(float)alpha{
    static BOOL seed = NO;
    if (!seed) {
        seed = YES;
        int a = (int)time(NULL);
        srandom(a);
    }
    CGFloat red = (CGFloat)random()/(CGFloat)RAND_MAX;
    CGFloat green = (CGFloat)random()/(CGFloat)RAND_MAX;
    CGFloat blue = (CGFloat)random()/(CGFloat)RAND_MAX;
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

@end
