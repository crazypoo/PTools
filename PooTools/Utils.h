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

typedef NS_ENUM(NSInteger, GradeType) {
    GradeTypeGe = 0,
    GradeTypeWan,
    GradeTypeYi
};

typedef NS_ENUM(NSInteger,TemperatureUnit){
    Fahrenheit = 0,
    CentigradeDegree
};

typedef NS_ENUM(NSInteger,ToolsAboutImageType){
    ToolsAboutImageTypeJPEG = 0,
    ToolsAboutImageTypePNG,
    ToolsAboutImageTypeGIF,
    ToolsAboutImageTypeTIFF,
    ToolsAboutImageTypeWEBP,
    ToolsAboutImageTypeUNKNOW
};

typedef NS_ENUM(NSInteger,ToolsUrlStringVideoType){
    ToolsUrlStringVideoTypeMP4 = 0,
    ToolsUrlStringVideoTypeMOV,
    ToolsUrlStringVideoType3GP,
    ToolsUrlStringVideoTypeUNKNOW
};

typedef NS_ENUM(NSInteger,CheckNowTimeAndPastTimeRelationships){
    CheckNowTimeAndPastTimeRelationshipsExpire = 0,
    CheckNowTimeAndPastTimeRelationshipsNormal,
    CheckNowTimeAndPastTimeRelationshipsError
};

static NSString *LANGUAGEENGLISH = @"LANGUAGEENGLISH";
static NSString *LANGUAGEANDCHINESE = @"LANGUAGEANDCHINESE";
static NSString *LANGUAGECHINESE = @"LANGUAGECHINESE";

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

#pragma mark ------> UIImageView
/*! @brief 图片简易生成
 */
+(UIImageView *)imageViewWithFrame:(CGRect)frame
                         withImage:(UIImage *)image;
    
#pragma mark ------> UILabel
/*! @brief Label简易生成
 */
+(UILabel *)labelWithFrame:(CGRect)frame
                 withTitle:(NSString *)title
             titleFontSize:(UIFont *)font
                 textColor:(UIColor *)color
           backgroundColor:(UIColor *)bgColor
                 alignment:(NSTextAlignment)textAlignment;

#pragma mark ------> UIAlertView/UIViewController
/*! @brief AlertView Normal
 */
+(UIAlertView *)alertTitle:(NSString *)title
                   message:(NSString *)msg
                  delegate:(id)aDeleagte
                 cancelBtn:(NSString *)cancelName
              otherBtnName:(NSString *)otherbuttonName;

/*! @brief AlertView + Only cancel
 */
+(UIAlertView *)alertShowWithMessage:(NSString *)message;

/*! @brief AlertController Normal
 */
+(void)alertVCWithTitle:(NSString *)title
                message:(NSString *)m
            cancelTitle:(NSString *)cT
                okTitle:(NSString *)okT
                 shouIn:(UIViewController *)vC
               okAction:(void (^ _Nullable)(void))okBlock
           cancelAction:(void (^ _Nullable)(void))cancelBlock;

/*! @brief AlertController Only Cancel
 */
+(void)alertVCWithTitle:(NSString *)title
                message:(NSString *)m
            cancelTitle:(NSString *)cT
                 shouIn:(UIViewController *)vC
           cancelAction:(void (^ _Nullable)(void))cancelBlock;

/*! @brief AlertController Normal + Other Buttons + Can switch alert style
 */
+(void)alertVCWithTitle:(NSString *)title
                message:(NSString *)m
            cancelTitle:(NSString *)cT
                okTitle:(NSString *)okT
       otherButtonArrow:(NSArray *)titleArr
                 shouIn:(UIViewController *)vC
             alertStyle:(UIAlertControllerStyle)style
               okAction:(void (^ _Nullable)(void))okBlock
           cancelAction:(void (^ _Nullable)(void))cancelBlock
      otherButtonAction:(void (^) (NSInteger))buttonIndexPath;

#pragma mark ------> 计算字符串高度或者宽度
/*! @brief Compute string heigh or width
 */
+(CGSize)sizeForString:(NSString *)string
            fontToSize:(float)fontToSize
              andHeigh:(float)heigh
              andWidth:(float)width;

#pragma mark ------> UIButton
/*! @brief 按钮简易生成
 */
+(UIButton *)createBtnWithType:(UIButtonType)btnType
                         frame:(CGRect)btnFrame
               backgroundColor:(UIColor*)bgColor;

/*! @brief 按钮倒计时
 */
+(void)timmerRunWithTime:(int)time
                  button:(UIButton *)btn
             originalStr:(NSString *)str
            setTapEnable:(BOOL)yesOrNo;
    
#pragma mark ------> 时间日期
/*! @brief 获取时间年月日时分秒(一般方法)
 */
+(NSString *)formateTime:(NSDate*)date;

/*! @brief 获取时间年月日时分秒
 */
+(NSString *)getYMDHHS;

/*! @brief 获取时间年月日
 */
+(NSString *)getYMD;

/*! @brief 时间戳
 */
+(NSString *)getTimeStamp;

/*! @brief 某个时间的某时间之后或者之前
 */
+(NSDate *)fewMonthLater:(NSInteger)month
                 fromNow:(NSDate *)thisTime;

/*! @brief 日期时间对比
 */
+ (int)compareOneDay:(NSDate *)oneDay
      withAnotherDay:(NSDate *)anotherDay
       dateFormatter:(NSString *)df;

/*! @brief 类似朋友圈的时间显示
 */
+(NSString *)theDayBeforeToday:(NSString *)dayStr;

#pragma mark ------> 获取手机语言
/*! @brief 获取手机App语言(根据定位)
 */
+(NSString *)getCurrentApplicationLocale;

/*! @brief 获取手机App语言(根据系统)
 */
+(NSString *)getCurrentDeviceLanguageInIOS;

/*! @brief 获取手机App语言(根据系统加强版)
 */
+(NSMutableDictionary *)getCurrentDeviceLanguageInIOSWithDic;

/*! @brief 用某个时间戳来判断当前时间与服务器获取的时间对比,是否快到期
 */
+(CheckNowTimeAndPastTimeRelationships)checkContractDateExpireContractDate:(NSString *)contractDate expTimeStamp:(int)timeStamp;

/*! @brief 用某个时间戳来判断当前时间与时间的对比,是否快到期
 */
+(CheckNowTimeAndPastTimeRelationships)checkStartDateExpireEndDataWithStartDate:(NSString *)sD withEndDate:(NSString *)eD expTimeStamp:(int)timeStamp;
#pragma mark ------> 图片
/*! @brief 获取视频第一帧
 */
+(UIImage *)thumbnailImageForVideo:(NSURL *)videoURL
                            atTime:(NSTimeInterval)time;
/*! @brief 用颜色生成图片
 */
+(UIImage*)createImageWithColor:(UIColor*)color;
/*! @brief 获取图片格式
 */
+ (ToolsAboutImageType)contentTypeForImageData:(NSData *)data;
/*! @brief 获取视频格式
 */
+ (ToolsUrlStringVideoType)contentTypeForUrlString:(NSString *)urlString;
/*! @brief iOS更换App图标
 * @attention 此方法必须在info.plist中添加Icon files (iOS 5)字段，k&vCFBundleAlternateIcons ={IconName={CFBundleIconFiles =(IconName);UIPrerenderedIcon = 0;};};CFBundlePrimaryIcon={CFBundleIconFiles=(AppIcon20x20,AppIcon29x29,AppIcon40x40,AppIcon60x60);};
 */
+(void)changeAPPIcon:(NSString *)IconName;

/*! @brief 生成二维码
 */
+(UIImage *)createQRImageWithString:(NSString *)string
                           withSize:(CGFloat)size;

/*! @brief 图片按比例大小转换
 */
+(UIImage *)scaleImage:(UIImage *)image
               toScale:(float)scaleSize;

#pragma mark ------> JSON
/*! @brief Json字符串转字典
 */
+(NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;
/*! @brief Json字符串转数组
 */
+(NSArray *)stringToJSON:(NSString *)jsonStr;
/*! @brief 字典转字符串
 */
+(NSString *)convertToJsonData:(NSDictionary *)dictData;
/*! @brief 不规则Json字符串变换成规则字符串
 */
+(NSString *)changeJsonStringToTrueJsonString:(NSString *)json;

#pragma mark ------> 数组
/*! @brief 数组升序
 */
+(NSArray *)arraySortASC:(NSArray *)arr;
/*! @brief 数组倒序
 */
+(NSArray *)arraySortINV:(NSArray *)arr;

#pragma mark ------> 字符串
/*! @brief 中文转拼音
 */
+(NSString *)chineseTransform:(NSString *)chinese;

/*! @brief 银行卡号辨别银行
 */
+(NSString *)backbankenameWithBanknumber:(NSString *)banknumber;

/*! @brief iOS9++，暂时仅限英文换其他
 */
+(NSString *)stringToOtherLanguage:(NSString *)string
                     otherLanguage:(NSStringTransform)language;

/*! @brief 数字小写转大写
 */
+(NSString *)getUperDigit:(NSString *)inputStr;
+(NSString *)getIntPartUper:(int)digit;
+(NSString *)getPartAfterDot:(NSString *)digitStr;
+(NSString *)dealWithDigit:(int)digit
                     grade:(GradeType)grade;

/*! @brief 隐藏手机号码某一段
 */
+(NSString*)shoujibaomi:(NSString*)phone;

/*! @brief 查找某字符在字符串的位置
 */
+ (NSArray *)rangeOfSubString:(NSString *)subStr
                     inString:(NSString *)string;

/*! @brief 华氏转摄氏/摄氏转华氏
 */
+ (CGFloat)temperatureUnitExchangeValue:(CGFloat)value
                               changeTo:(TemperatureUnit)unit;

/*! @brief 英文星期几转中文星期几
 */
+(NSString *)engDayCoverToZHCN:(NSString *)str;

/*! @brief 判断是否白天
 */
+(BOOL)isNowDayTime;

/*! @brief 判断是否存在Emoji
 */
+(BOOL)stringContainsEmoji:(NSString *)string;

@end
