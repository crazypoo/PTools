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

static NSString *LANGUAGEENGLISH = @"LANGUAGEENGLISH";
static NSString *LANGUAGEANDCHINESE = @"LANGUAGEANDCHINESE";
static NSString *LANGUAGECHINESE = @"LANGUAGECHINESE";
@interface Utils : NSObject

+(UIImageView *)imageViewWithFrame:(CGRect)frame withImage:(UIImage *)image;
+(UILabel *)labelWithFrame:(CGRect)frame withTitle:(NSString *)title titleFontSize:(UIFont *)font textColor:(UIColor *)color backgroundColor:(UIColor *)bgColor alignment:(NSTextAlignment)textAlignment;
+(UIButton *)createBtnWithType:(UIButtonType)btnType frame:(CGRect)btnFrame backgroundColor:(UIColor*)bgColor;

+(CGSize)sizeForString:(NSString *)string fontToSize:(float)fontToSize andHeigh:(float)heigh andWidth:(float)width;

+(NSString *)chineseTransform:(NSString *)chinese;

+(UIAlertView *)alertTitle:(NSString *)title message:(NSString *)msg delegate:(id)aDeleagte cancelBtn:(NSString *)cancelName otherBtnName:(NSString *)otherbuttonName;
+(UIAlertView *)alertShowWithMessage:(NSString *)message;
+(void)alertVCWithTitle:(NSString *)title message:(NSString *)m cancelTitle:(NSString *)cT okTitle:(NSString *)okT shouIn:(UIViewController *)vC okAction:(void (^ _Nullable)(void))okBlock cancelAction:(void (^ _Nullable)(void))cancelBlock;

+(void)timmerRunWithTime:(int)time button:(UIButton *)btn originalStr:(NSString *)str setTapEnable:(BOOL)yesOrNo;
+(NSString *)formateTime:(NSDate*)date;
+(NSString *)getYMDHHS;

+(NSString *)getCurrentApplicationLocale;
+(NSString *)getCurrentDeviceLanguageInIOS;
+(NSMutableDictionary *)getCurrentDeviceLanguageInIOSWithDic;

+(UIImage*)createImageWithColor:(UIColor*)color;

+(void)changeAPPIcon:(NSString *)IconName;//此方法必须在info.plist中添加Icon files (iOS 5)字段，k&vCFBundleAlternateIcons ={IconName={CFBundleIconFiles =(IconName);UIPrerenderedIcon = 0;};};CFBundlePrimaryIcon={CFBundleIconFiles=(AppIcon20x20,AppIcon29x29,AppIcon40x40,AppIcon60x60);};

+(NSString *)stringToOtherLanguage:(NSString *)string otherLanguage:(NSStringTransform)language;//iOS9++，暂时仅限英文换其他
+(NSString *)backbankenameWithBanknumber:(NSString *)banknumber;//银行卡号辨别银行

+(NSString *)theDayBeforeToday:(NSString *)dayStr;//类似朋友圈的时间显示

+ (UIImage *)thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time;//获取视频第一帧

+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;
+ (NSArray *)stringToJSON:(NSString *)jsonStr;

+(NSString*)shoujibaomi:(NSString*)phone;

+(NSArray *)arraySortASC:(NSArray *)arr;//数组升序
+(NSArray *)arraySortINV:(NSArray *)arr;//数组倒序

+ (int)compareOneDay:(NSDate *)oneDay withAnotherDay:(NSDate *)anotherDay dateFormatter:(NSString *)df;//日期时间对比
@end
