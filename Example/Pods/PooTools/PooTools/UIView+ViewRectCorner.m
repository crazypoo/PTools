//
//  UIView+ViewRectCorner.m
//  PooTools_Example
//
//  Created by 邓杰豪 on 2018/9/25.
//  Copyright © 2018年 crazypoo. All rights reserved.
//

#import "UIView+ViewRectCorner.h"
#import <objc/runtime.h>

static NSString * const kcornerRadii = @"viewUI_rectCornerRadii";
static NSString * const krectCorner = @"viewUI_rectCorner";

@implementation UIView (ViewRectCorner)
- (void)setViewUI_rectCornerRadii:(CGFloat)viewUI_rectCornerRadii
{
    CGFloat Radii = [objc_getAssociatedObject(self, &kcornerRadii) floatValue];
    if (Radii != viewUI_rectCornerRadii)
    {
        [self willChangeValueForKey:kcornerRadii];
        objc_setAssociatedObject(self, &kcornerRadii,
                                 @(viewUI_rectCornerRadii),
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self didChangeValueForKey:kcornerRadii];
        [self ViewUI_rectCornerWithCornerRadii:viewUI_rectCornerRadii Corner:self.viewUI_rectCorner];
    }
}

- (CGFloat)viewUI_rectCornerRadii
{
    if (!objc_getAssociatedObject(self, &kcornerRadii))
    {
        [self setViewUI_rectCornerRadii:5];
    }
    return [objc_getAssociatedObject(self, &kcornerRadii) floatValue];
}

- (void)setViewUI_rectCorner:(UIRectCorner)viewUI_rectCorner
{
    [self willChangeValueForKey:krectCorner];
    objc_setAssociatedObject(self, &krectCorner,
                             @(viewUI_rectCorner),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:krectCorner];
    
    [self ViewUI_rectCornerWithCornerRadii:self.viewUI_rectCornerRadii Corner:viewUI_rectCorner];
}

- (UIRectCorner)viewUI_rectCorner
{
    return [objc_getAssociatedObject(self, &krectCorner) intValue];
}

- (void)ViewUI_rectCornerWithCornerRadii:(CGFloat )cornerRadii
                                  Corner:(UIRectCorner)corner
{
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                                   byRoundingCorners:corner
                                                         cornerRadii:CGSizeMake(cornerRadii,
                                                                                cornerRadii)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;
    self.layer.mask = maskLayer;
}

@end
