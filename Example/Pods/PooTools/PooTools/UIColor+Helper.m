//
//  UIColor+Helpers.m
//  T-All
//
//  Created by 何桂强 on 14-9-28.
//  Copyright (c) 2014年 Pactera. All rights reserved.
//

#import "UIColor+Helper.h"

@implementation UIColor (Helper)
-(UIColor *)inverseColor
{
    const CGFloat *componentColors = CGColorGetComponents(self.CGColor);
    UIColor *newColor = [[UIColor alloc] initWithRed:(1.0 - componentColors[0])
                                               green:(1.0 - componentColors[1])
                                                blue:(1.0 - componentColors[2])
                                               alpha:componentColors[3]];
    return newColor;
}
@end
