//
//  Utils.h
//  login
//
//  Created by crazypoo on 14/7/10.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <MediaPlayer/MediaPlayer.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>

typedef NS_ENUM(NSInteger,FewMonthLaterType){
    FewMonthLaterTypeNormal = 0,
    FewMonthLaterTypeContract
};

static NSString * _Nonnull LANGUAGEENGLISH = @"LANGUAGEENGLISH";
static NSString * _Nonnull LANGUAGEANDCHINESE = @"LANGUAGEANDCHINESE";
static NSString * _Nonnull LANGUAGECHINESE = @"LANGUAGECHINESE";

/*! @brief 判断iPhone X / XS / XS MAX / XR
 */
static inline BOOL isIPhoneXSeries() {
    BOOL iPhoneXSeries = NO;
    if (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPhone) {
        return iPhoneXSeries;
    }
    
    if (@available(iOS 11.0, *)) {
        UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
        if (mainWindow.safeAreaInsets.bottom > 0.0) {
            iPhoneXSeries = YES;
        }
    }
    
    return iPhoneXSeries;
}

@interface Utils : NSObject
    
#pragma mark ------> UIAlertView/UIViewController
/*! @brief AlertController + Only Show
 */
+(void)alertVCOnlyShowWithTitle:(NSString *_Nullable)title
                     andMessage:(NSString *_Nullable)message;

/*! @brief AlertController Normal
 */
+(void)alertVCWithTitle:(NSString * _Nullable)title
                message:(NSString * _Nullable)m
            cancelTitle:(NSString * _Nullable)cT
                okTitle:(NSString * _Nullable)okT
                 shouIn:(UIViewController * _Nonnull)vC
               okAction:(void (^ _Nullable)(void))okBlock
           cancelAction:(void (^ _Nullable)(void))cancelBlock;

/*! @brief AlertController Only Cancel
 */
+(void)alertVCWithTitle:(NSString * _Nullable)title
                message:(NSString * _Nullable)m
            cancelTitle:(NSString * _Nullable)cT
                 shouIn:(UIViewController * _Nonnull)vC
           cancelAction:(void (^ _Nullable)(void))cancelBlock;

#pragma mark ------> UIButton
/*! @brief 按钮倒计时
 */
+(void)timmerRunWithTime:(int)time
                  button:(UIButton * _Nonnull)btn
             originalStr:(NSString * _Nonnull)str
            setTapEnable:(BOOL)yesOrNo;
    
#pragma mark ------> 字符串
/*! @brief 英文星期几转中文星期几
 */
+(NSString * _Nonnull)engDayCoverToZHCN:(NSString * _Nonnull)str;
@end
