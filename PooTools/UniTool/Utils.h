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

typedef NS_ENUM(NSInteger,FewMonthLaterType){
    FewMonthLaterTypeNormal = 0,
    FewMonthLaterTypeContract
};

typedef NS_ENUM(NSInteger,GetTimeType){
    GetTimeTypeYMD = 0,
    GetTimeTypeYM,
    GetTimeTypeY,
    GetTimeTypeM,
    GetTimeTypeMD,
    GetTimeTypeD,
    GetTimeTypeTimeStamp,
    GetTimeTypeYMDHHS,
    GetTimeTypeHHS,
    GetTimeTypeHH
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

#pragma mark ------> UIImageView
/*! @brief 图片简易生成
 */
+(UIImageView * _Nonnull)imageViewWithFrame:(CGRect)frame
                         withImage:(UIImage * _Nullable)image;
    
#pragma mark ------> UILabel
/*! @brief Label简易生成
 */
+(UILabel * _Nonnull)labelWithFrame:(CGRect)frame
                 withTitle:(NSString * _Nullable)title
             titleFontSize:(UIFont * _Nullable)font
                 textColor:(UIColor * _Nullable)color
           backgroundColor:(UIColor * _Nullable)bgColor
                 alignment:(NSTextAlignment)textAlignment;

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

/*! @brief AlertController Normal + Other Buttons + Can switch alert style
 */
+(void)alertVCWithTitle:(NSString * _Nullable)title
                message:(NSString * _Nullable)m
            cancelTitle:(NSString * _Nullable)cT
                okTitle:(NSString * _Nullable)okT
       destructiveTitle:(NSString * _Nullable)dT
       otherButtonArray:(NSArray * _Nonnull)titleArr
                 shouIn:(UIViewController * _Nonnull)vC
             alertStyle:(UIAlertControllerStyle)style
               okAction:(void (^ _Nullable)(void))okBlock
           cancelAction:(void (^ _Nullable)(void))cancelBlock
      destructiveAction:(void (^ _Nullable)(void))destructiveBlock
      otherButtonAction:(void (^_Nonnull) (NSInteger index))buttonIndexPath;

#pragma mark ------> 计算字符串高度或者宽度
/*! @brief Compute string heigh or width
 */
+(CGSize)sizeForString:(NSString  * _Nonnull)string
                  font:(UIFont * _Nonnull)stringFont
              andHeigh:(CGFloat)heigh
              andWidth:(CGFloat)width;

/*! @brief Compute string heigh or width(含有字行间距)
*/
+(CGSize)sizeForString:(NSString * _Nonnull)string
                  font:(UIFont * _Nonnull)stringFont
           lineSpacing:(CGFloat)lineSpacing
              andWidth:(CGFloat)width
              andHeigh:(CGFloat)height;

#pragma mark ------> UIButton
/*! @brief 按钮简易生成
 */
+(UIButton * _Nonnull)createBtnWithType:(UIButtonType)btnType
                         frame:(CGRect)btnFrame
               backgroundColor:(UIColor * _Nullable)bgColor;

/*! @brief 按钮倒计时
 */
+(void)timmerRunWithTime:(int)time
                  button:(UIButton * _Nonnull)btn
             originalStr:(NSString * _Nonnull)str
            setTapEnable:(BOOL)yesOrNo;
    
#pragma mark ------> 时间日期
/*! @brief 根据NSDate格式化时间
 */
+(NSString * _Nonnull)formateTime:(NSDate * _Nonnull)date WithType:(GetTimeType)type;

/*! @brief 获取当前时间
 */
+(NSString * _Nonnull)getTimeWithType:(GetTimeType)type;

/*! @brief 时间格式化
 */
+(NSString * _Nonnull)dateStringFormater:(NSString * _Nonnull)timeString withType:(GetTimeType)type;

/*! @brief 某个时间的某时间之后或者之前
 */
+(NSDate * _Nonnull)fewMonthLater:(NSInteger)month
                 fromNow:(NSDate * _Nonnull)thisTime
                timeType:(FewMonthLaterType)type;

/*! @brief 日期时间对比
 */
+ (int)compareOneDay:(NSDate * _Nonnull)oneDay
      withAnotherDay:(NSDate * _Nonnull)anotherDay
       dateFormatter:(NSString * _Nonnull)df;

/*! @brief 类似朋友圈的时间显示
 */
+(NSString * _Nonnull)theDayBeforeToday:(NSString * _Nonnull)dayStr;

#pragma mark ------> 获取手机语言
/*! @brief 获取手机App语言(根据定位)
 */
+(NSString * _Nonnull)getCurrentApplicationLocale;

/*! @brief 获取手机App语言(根据系统)
 */
+(NSString * _Nonnull)getCurrentDeviceLanguageInIOS;

/*! @brief 获取手机App语言(根据系统加强版)
 */
+(NSMutableDictionary * _Nonnull)getCurrentDeviceLanguageInIOSWithDic;

/*! @brief 用某个时间戳来判断当前时间与服务器获取的时间对比,是否快到期
 */
+(CheckNowTimeAndPastTimeRelationships)checkContractDateExpireContractDate:(NSString * _Nonnull)contractDate expTimeStamp:(int)timeStamp;

/*! @brief 用某个时间戳来判断当前时间与时间的对比,是否快到期
 */
+(CheckNowTimeAndPastTimeRelationships)checkStartDateExpireEndDataWithStartDate:(NSString * _Nonnull)sD withEndDate:(NSString * _Nonnull)eD expTimeStamp:(int)timeStamp;
#pragma mark ------> 图片
/*! @brief 获取视频第一帧
 */
+(UIImage * _Nonnull)thumbnailImageForVideo:(NSURL * _Nonnull)videoURL
                            atTime:(NSTimeInterval)time;
/*! @brief 用颜色生成图片
 */
+(UIImage * _Nonnull)createImageWithColor:(UIColor * _Nonnull)color;
/*! @brief 获取图片格式
 */
+ (ToolsAboutImageType)contentTypeForImageData:(NSData * _Nonnull)data;
/*! @brief 获取视频格式
 */
+ (ToolsUrlStringVideoType)contentTypeForUrlString:(NSString * _Nonnull)urlString;
/*! @brief iOS更换App图标
 * @attention 此方法必须在info.plist中添加Icon files (iOS 5)字段，k&vCFBundleAlternateIcons ={IconName={CFBundleIconFiles =(IconName);UIPrerenderedIcon = 0;};};CFBundlePrimaryIcon={CFBundleIconFiles=(AppIcon20x20,AppIcon29x29,AppIcon40x40,AppIcon60x60);};
 */
+(void)changeAPPIcon:(NSString * _Nullable)IconName;

/*! @brief 生成二维码
 */
+(UIImage * _Nonnull)createQRImageWithString:(NSString * _Nonnull)string
                           withSize:(CGFloat)size;

/*! @brief 图片按比例大小转换
 */
+(UIImage * _Nonnull)scaleImage:(UIImage * _Nonnull)image
               toScale:(float)scaleSize;

/*! @brief 添加文字水印
 * @param image 原来的图片
 * @param text 水印内容
 * @param point 水印位置
 * @param attributed 水印设置
 */
+ (UIImage * _Nonnull)jx_WaterImageWithImage:(UIImage * _Nonnull)image
                               text:(NSString * _Nonnull)text
                          textPoint:(CGPoint)point
                   attributedString:(NSDictionary * _Nonnull)attributed;


/*! @brief 添加文字水印(斜文字版)
 * @param originalImage 原来的图片
 * @param title 水印内容
 * @param markFont 水印字体
 * @param markColor 水印颜色
 */
+ (UIImage * _Nonnull)getWaterMarkImage:(UIImage * _Nonnull)originalImage
                      andTitle:(NSString * _Nonnull)title
                   andMarkFont:(UIFont * _Nonnull)markFont
                  andMarkColor:(UIColor * _Nonnull)markColor;

/*! @brief 添加图片水印
 * @param image 原来的图片
 * @param waterImage 水印图片
 * @param rect 水印位置大小
 */
+ (UIImage * _Nonnull)jx_WaterImageWithImage:(UIImage * _Nonnull)image
                         waterImage:(UIImage * _Nonnull)waterImage
                     waterImageRect:(CGRect)rect;

#pragma mark ------> JSON
/*! @brief Json字符串转字典
 */
+(NSDictionary * _Nonnull)dictionaryWithJsonString:(NSString * _Nonnull)jsonString;
/*! @brief Json字符串转数组
 */
+(NSArray * _Nonnull)stringToJSON:(NSString * _Nonnull)jsonStr;
/*! @brief 字典转字符串
 */
+(NSString * _Nonnull)convertToJsonData:(NSDictionary * _Nonnull)dictData;
/*! @brief 不规则Json字符串变换成规则字符串
 */
+(NSString * _Nonnull)changeJsonStringToTrueJsonString:(NSString * _Nonnull)json;

#pragma mark ------> 数组
/*! @brief 数组升序
 */
+(NSArray * _Nonnull)arraySortASC:(NSArray * _Nonnull)arr;
/*! @brief 数组倒序
 */
+(NSArray * _Nonnull)arraySortINV:(NSArray * _Nonnull)arr;

#pragma mark ------> 字符串
/*! @brief 中文转拼音
 */
+(NSString * _Nonnull)chineseTransform:(NSString * _Nonnull)chinese;

/*! @brief 银行卡号辨别银行
 */
+(NSString * _Nonnull)backbankenameWithBanknumber:(NSString * _Nonnull)banknumber;

/*! @brief iOS9++，暂时仅限英文换其他
 */
+(NSString * _Nonnull)stringToOtherLanguage:(NSString * _Nonnull)string
                     otherLanguage:(NSStringTransform _Nonnull)language;

/*! @brief 数字小写转大写
 */
+(NSString * _Nonnull)getUperDigit:(NSString * _Nonnull)inputStr;
+(NSString * _Nonnull)getIntPartUper:(int)digit;
+(NSString * _Nonnull)getPartAfterDot:(NSString * _Nonnull)digitStr;
+(NSString * _Nonnull)dealWithDigit:(int)digit
                     grade:(GradeType)grade;
+(NSString * _Nonnull)digitUppercase:(NSString * _Nonnull)numstr;

/*! @brief 隐藏手机号码某一段
 */
+(NSString * _Nonnull)shoujibaomi:(NSString * _Nonnull)phone;

/*! @brief 查找某字符在字符串的位置
 */
+ (NSArray * _Nonnull)rangeOfSubString:(NSString * _Nonnull)subStr
                     inString:(NSString * _Nonnull)string;

/*! @brief 华氏转摄氏/摄氏转华氏
 */
+ (CGFloat)temperatureUnitExchangeValue:(CGFloat)value
                               changeTo:(TemperatureUnit)unit;

/*! @brief 英文星期几转中文星期几
 */
+(NSString * _Nonnull)engDayCoverToZHCN:(NSString * _Nonnull)str;

/*! @brief 判断是否白天
 */
+(BOOL)isNowDayTime;

/*! @brief 判断是否存在Emoji
 */
+(BOOL)stringContainsEmoji:(NSString * _Nonnull)string;

/*! @brief 判断是否存在SIM卡
 */
+(BOOL)isSIMInstalled;

/*! @brief 此方法用来鉴定picker是否在滑动
 */
+(BOOL)isRolling:(UIView * _Nonnull)view;
@end
