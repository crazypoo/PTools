//
//  UIBarButtonItem+AMKLaunchTimeProfiler.m
//  AMKLaunchTimeProfiler
//
//  Created by mengxinxin on 2022/3/24.
//

#import "UIBarButtonItem+AMKLaunchTimeProfiler.h"

@implementation UIBarButtonItem (AMKLaunchTimeProfiler)

#pragma mark - Init Methods

- (instancetype _Nullable)amkltp_initWithImageType:(AMKLaunchTimeProfilerImageType)type target:(id _Nullable)target action:(SEL _Nullable)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:CGRectMake(0, 0, 30, 30)];
    [button setImage:[[UIImage amkltp_imageWithType:type] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButtonItem = [UIBarButtonItem.alloc initWithCustomView:button];
    return barButtonItem;
}

#pragma mark - Getters & Setters

#pragma mark - Data & Networking

#pragma mark - Public Methods

#pragma mark - Private Methods

#pragma mark - Notifications

#pragma mark - KVO

#pragma mark - Protocol

#pragma mark - Overrides

#pragma mark - Helper Methods

@end
