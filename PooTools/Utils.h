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

typedef NS_ENUM(NSInteger, GradeType) {
    GradeTypeGe = 0,
    GradeTypeWan,
    GradeTypeYi
};

static NSString *LANGUAGEENGLISH = @"LANGUAGEENGLISH";
static NSString *LANGUAGEANDCHINESE = @"LANGUAGEANDCHINESE";
static NSString *LANGUAGECHINESE = @"LANGUAGECHINESE";
@interface Utils : NSObject

#pragma mark ------> UIImageView
+(UIImageView *)imageViewWithFrame:(CGRect)frame withImage:(UIImage *)image;
    
#pragma mark ------> UILabel
+(UILabel *)labelWithFrame:(CGRect)frame withTitle:(NSString *)title titleFontSize:(UIFont *)font textColor:(UIColor *)color backgroundColor:(UIColor *)bgColor alignment:(NSTextAlignment)textAlignment;

#pragma mark ------> UIAlertView/UIViewController
+(UIAlertView *)alertTitle:(NSString *)title message:(NSString *)msg delegate:(id)aDeleagte cancelBtn:(NSString *)cancelName otherBtnName:(NSString *)otherbuttonName;
+(UIAlertView *)alertShowWithMessage:(NSString *)message;
+(void)alertVCWithTitle:(NSString *)title message:(NSString *)m cancelTitle:(NSString *)cT okTitle:(NSString *)okT shouIn:(UIViewController *)vC okAction:(void (^ _Nullable)(void))okBlock cancelAction:(void (^ _Nullable)(void))cancelBlock;
+(void)alertVCWithTitle:(NSString *)title message:(NSString *)m cancelTitle:(NSString *)cT shouIn:(UIViewController *)vC cancelAction:(void (^ _Nullable)(void))cancelBlock;

#pragma mark ------> 计算字符串高度或者宽度
+(CGSize)sizeForString:(NSString *)string fontToSize:(float)fontToSize andHeigh:(float)heigh andWidth:(float)width;

#pragma mark ------> UIButton
+(UIButton *)createBtnWithType:(UIButtonType)btnType frame:(CGRect)btnFrame backgroundColor:(UIColor*)bgColor;
+(void)timmerRunWithTime:(int)time button:(UIButton *)btn originalStr:(NSString *)str setTapEnable:(BOOL)yesOrNo;
    
#pragma mark ------> 时间日期
+(NSString *)formateTime:(NSDate*)date;
+(NSString *)getYMDHHS;
+(NSString *)getYMD;
+(NSDate *)fewMonthLater:(NSInteger)month fromNow:(NSDate *)thisTime;
+ (int)compareOneDay:(NSDate *)oneDay withAnotherDay:(NSDate *)anotherDay dateFormatter:(NSString *)df;//日期时间对比
+(NSString *)theDayBeforeToday:(NSString *)dayStr;//类似朋友圈的时间显示

#pragma mark ------> 获取手机语言
+(NSString *)getCurrentApplicationLocale;
+(NSString *)getCurrentDeviceLanguageInIOS;
+(NSMutableDictionary *)getCurrentDeviceLanguageInIOSWithDic;

#pragma mark ------> 图片
+(UIImage *)thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time;//获取视频第一帧
+(UIImage*)createImageWithColor:(UIColor*)color;//用颜色生成图片
+(void)changeAPPIcon:(NSString *)IconName;//此方法必须在info.plist中添加Icon files (iOS 5)字段，k&vCFBundleAlternateIcons ={IconName={CFBundleIconFiles =(IconName);UIPrerenderedIcon = 0;};};CFBundlePrimaryIcon={CFBundleIconFiles=(AppIcon20x20,AppIcon29x29,AppIcon40x40,AppIcon60x60);};
+(UIImage *)createQRImageWithString:(NSString *)string withSize:(CGFloat)size;//生成二维码

#pragma mark ------> JSON
+(NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;
+(NSArray *)stringToJSON:(NSString *)jsonStr;
+(NSString *)convertToJsonData:(NSDictionary *)dictData;

#pragma mark ------> 数组
+(NSArray *)arraySortASC:(NSArray *)arr;//数组升序
+(NSArray *)arraySortINV:(NSArray *)arr;//数组倒序

#pragma mark ------> 字符串
+(NSString *)chineseTransform:(NSString *)chinese;//中文转拼音

+(NSString *)backbankenameWithBanknumber:(NSString *)banknumber;//银行卡号辨别银行
    
+(NSString *)stringToOtherLanguage:(NSString *)string otherLanguage:(NSStringTransform)language;//iOS9++，暂时仅限英文换其他

// 数字小写转大写
+(NSString *)getUperDigit:(NSString *)inputStr;
+(NSString *)getIntPartUper:(int)digit;
+(NSString *)getPartAfterDot:(NSString *)digitStr;
+(NSString *)dealWithDigit:(int)digit grade:(GradeType)grade;

//隐藏手机号码某一段
+(NSString*)shoujibaomi:(NSString*)phone;

// 查找某字符在字符串的位置
+ (NSArray *)rangeOfSubString:(NSString *)subStr inString:(NSString *)string;
@end
