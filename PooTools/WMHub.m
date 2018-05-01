//
//  WMHub.m
//  Dagongzai
//
//  Created by crazypoo on 14/11/5.
//  Copyright (c) 2014年 Pactera. All rights reserved.
//

#import "WMHub.h"
#import <objc/runtime.h>

#import "WMHubWindow.h"
#import "WMHubViewController.h"
#import "UIColor+Helper.h"

@implementation WMHub

#pragma mark - class method

+ (void)show {
    WMHubViewController *inboxViewController = [WMHubViewController new];
    inboxViewController.hudColors = [self hudColors];
    inboxViewController.hudBackgroundColor = [self hudBackgroundColor];
    inboxViewController.hudLineWidth = [self hudLineWidth];
    [self hudWindow].rootViewController = inboxViewController;
    [[self hudWindow] makeKeyAndVisible];
}

+ (void)hide {
    [[self hudWindow].rootViewController performSelector:@selector(hide:) withObject: ^{
        [self hudWindow].hidden = YES;
        [self setHudWindow:nil];
        [[UIApplication sharedApplication].keyWindow makeKeyWindow];
    }];
}

+ (void)resetDefaultSetting{
    [WMHub setColors:@[[UIColor colorFromHexString:@"0xf05783"],
                       [UIColor colorFromHexString:@"0xfcb644"],
                       [UIColor colorFromHexString:@"0x88bd33"],
                       [UIColor colorFromHexString:@"0xe5512d"],
                       [UIColor colorFromHexString:@"0x3abcab"]]];
    [WMHub setBackgroundColor:[UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.75]];
    [WMHub setLineWidth:2.0f];
}

+ (void)setColors:(NSArray *)colors {
    
    //檢查每一個填入的元素是否都為 uicolor
    BOOL isLegal = YES;
    for (id objects in colors) {
        if (![objects isKindOfClass:[UIColor class]]) {
            isLegal = NO;
            break;
        }
    }
    
    //合法就讓他設定, 不合法則跳錯誤訊息
    if ([colors count] > 1 && isLegal) {
        [self setHudColors:colors];
    }
    else {
        NSLog(@"填入的顏色不被採用, 建議要填入兩個以上的顏色, 或是元素不合法.");
    }
}

+ (void)setBackgroundColor:(UIColor *)backgroundColor {
    [self setHudBackgroundColor:backgroundColor];
}

+ (void)setLineWidth:(CGFloat)lineWidth {
    [self setHudLineWidth:lineWidth];
}

#pragma mark - objects

#pragma mark hud 視窗

+ (WMHubWindow *)hudWindow {
    if (!objc_getAssociatedObject(self, _cmd)) {
        [self setHudWindow:[[WMHubWindow alloc] initWithFrame:[UIScreen mainScreen].bounds]];
    }
    return objc_getAssociatedObject(self, _cmd);
}

+ (void)setHudWindow:(WMHubWindow *)hudWindow {
    objc_setAssociatedObject(self, @selector(hudWindow), hudWindow, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark 客製化變數

+ (void)setHudColors:(NSArray *)hudColors {
    objc_setAssociatedObject(self, @selector(hudColors), hudColors, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSArray *)hudColors {
    if (!objc_getAssociatedObject(self, _cmd)) {
        [self setHudColors:@[[UIColor redColor], [UIColor greenColor], [UIColor yellowColor], [UIColor blueColor]]];
    }
    return objc_getAssociatedObject(self, _cmd);
}

+ (void)setHudBackgroundColor:(UIColor *)hudBackgroundColor {
    objc_setAssociatedObject(self, @selector(hudBackgroundColor), hudBackgroundColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (UIColor *)hudBackgroundColor {
    if (!objc_getAssociatedObject(self, _cmd)) {
        [self setHudBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.65f]];
    }
    return objc_getAssociatedObject(self, _cmd);
}

+ (void)setHudLineWidth:(CGFloat)hudLineWidth {
    objc_setAssociatedObject(self, @selector(hudLineWidth), @(hudLineWidth), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (CGFloat)hudLineWidth {
    if (!objc_getAssociatedObject(self, _cmd)) {
        [self setHudLineWidth:2.0f];
    }
    NSNumber *hudLineWidth = objc_getAssociatedObject(self, _cmd);
    return [hudLineWidth floatValue];
}

@end
