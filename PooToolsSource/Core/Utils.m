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

+(void)alertVCOnlyShowWithTitle:(NSString *)title
                     andMessage:(NSString *)message
{
    [PTUtils oc_alert_baseWithTitle:title msg:message okBtns:@[] cancelBtn:@"确定" showIn:kAppDelegateWindow.rootViewController cancel:^{
        
    } moreBtn:^(NSInteger selectIndex, NSString * selectTitle) {
        
    }];
}

+(void)alertVCWithTitle:(NSString *)title message:(NSString *)m cancelTitle:(NSString *)cT okTitle:(NSString *)okT shouIn:(UIViewController *)vC okAction:(void (^ _Nullable)(void))okBlock cancelAction:(void (^ _Nullable)(void))cancelBlock
{
    [PTUtils oc_alert_baseWithTitle:title msg:m okBtns:@[okT] cancelBtn:cT showIn:vC cancel:^{
        cancelBlock();
    } moreBtn:^(NSInteger index, NSString * value) {
        okBlock();
    }];
}

+(void)alertVCWithTitle:(NSString *)title message:(NSString *)m cancelTitle:(NSString *)cT shouIn:(UIViewController *)vC cancelAction:(void (^ _Nullable)(void))cancelBlock
{
    [PTUtils oc_alert_baseWithTitle:title msg:m okBtns:@[] cancelBtn:cT showIn:vC cancel:^{
        cancelBlock();
    } moreBtn:^(NSInteger index, NSString * value) {
    }];
}

+(void)timmerRunWithTime:(int)time button:(UIButton *)btn originalStr:(NSString *)str setTapEnable:(BOOL)yesOrNo
{
    __block int timeout = time;
    dispatch_queue_t queue   = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
    dispatch_source_set_timer(_timer,dispatch_walltime(NULL, 0),1.0*NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(_timer, ^{
        if(timeout <= 0){
            dispatch_source_cancel(_timer);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (yesOrNo) {
                    btn.userInteractionEnabled = YES;
                    [btn setTitle:str forState:UIControlStateNormal];
                }
            });
        }
        else
        {
            NSString *strTime = [NSString stringWithFormat:@"%.2d",timeout];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *buttonTime          = [NSString stringWithFormat:@"%@",strTime];
                [btn setTitle:buttonTime forState:UIControlStateNormal];
                btn.userInteractionEnabled = NO;
            });
            timeout--;
        }
    });
    dispatch_resume(_timer);
}

#pragma mark ------>英文星期几转中文星期几
+(NSString *)engDayCoverToZHCN:(NSString *)str
{
    NSString *realStr;
    if ([str isEqualToString:@"Mon"]) {
        realStr = @"周一";
    }
    else if ([str isEqualToString:@"Tue"]) {
        realStr = @"周二";
    }
    else if ([str isEqualToString:@"Wed"]) {
        realStr = @"周三";
    }
    else if ([str isEqualToString:@"Thu"]) {
        realStr = @"周四";
    }
    else if ([str isEqualToString:@"Fri"]) {
        realStr = @"周五";
    }
    else if ([str isEqualToString:@"Sat"]) {
        realStr = @"周六";
    }
    else if ([str isEqualToString:@"Sun"]) {
        realStr = @"周日";
    }
    return realStr;
}
@end
