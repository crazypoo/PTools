//
//  UIView+ViewShaking.m
//  PooTools_Example
//
//  Created by 邓杰豪 on 2018/9/26.
//  Copyright © 2018年 crazypoo. All rights reserved.
//

#import "UIView+ViewShaking.h"

@implementation UIView (ViewShaking)

- (void)ViewUI_viewShaking
{
    CAKeyframeAnimation *keyFrame = [CAKeyframeAnimation animationWithKeyPath:@"position.x"];
    keyFrame.duration = 0.3;
    CGFloat x = self.layer.position.x;
    keyFrame.values = @[@(x - 30), @(x - 30), @(x + 20), @(x - 20), @(x + 10), @(x - 10), @(x + 5), @(x - 5)];
    [self.layer addAnimation:keyFrame forKey:@"shake"];
}

@end
