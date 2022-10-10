//
//  MXRotationManager.m
//  Yunlu
//
//  Created by Michael on 2018/9/21.
//  Copyright © 2018 DCloud. All rights reserved.
//

#import "MXRotationManager.h"
#import <objc/message.h>

static MXRotationManager *INSTANCE = nil;

@interface MXRotationManager ()

@property (nonatomic, readwrite) UIInterfaceOrientationMask interfaceOrientationMask;

@end

@implementation MXRotationManager

#pragma mark - singleton
+ (instancetype)defaultManager {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        INSTANCE = [[super allocWithZone:nil] init];
        INSTANCE.interfaceOrientationMask = UIInterfaceOrientationMaskPortrait;
    });
    return INSTANCE;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self defaultManager];
}

#pragma mark - setter methods
- (void)setOrientation:(UIDeviceOrientation)orientation {
    if (_orientation == orientation) return;
    if ([UIDevice currentDevice].orientation == orientation) {
        //强制旋转成与之前不一样的
        [[UIDevice currentDevice] setValue:@(_orientation) forKey:@"orientation"];
    }
    _orientation = orientation;
    UIInterfaceOrientationMask interfaceOrientationMask = UIInterfaceOrientationMaskPortrait;
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            interfaceOrientationMask = UIInterfaceOrientationMaskPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            interfaceOrientationMask = UIInterfaceOrientationMaskPortraitUpsideDown;
            break;
        case UIDeviceOrientationLandscapeRight:
            interfaceOrientationMask = UIInterfaceOrientationMaskLandscapeLeft;
            break;
        case UIDeviceOrientationLandscapeLeft:
            interfaceOrientationMask = UIInterfaceOrientationMaskLandscapeRight;
            break;
        default:
            interfaceOrientationMask = UIInterfaceOrientationMaskPortrait;
            break;
    }
    [MXRotationManager defaultManager].interfaceOrientationMask = interfaceOrientationMask;
    //强制旋转成全屏
    [[UIDevice currentDevice] setValue:@(orientation) forKey:@"orientation"];
}

@end
