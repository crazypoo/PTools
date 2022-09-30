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
    CheckNowTimeAndPastTimeRelationshipsReadyExpire,
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
    GetTimeTypeTimeStampFull,
    GetTimeTypeTimeStampYMDHM,
    GetTimeTypeTimeStampYMD,
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
+(void)alertVCWithTitle:(NSString *_Nullable)title
                message:(NSString *_Nullable)m
            cancelTitle:(NSString *_Nullable)cT
                okTitle:(NSString *_Nullable)okT
       destructiveTitle:(NSString *_Nullable)dT
       otherButtonArray:(NSArray *_Nullable)titleArr
                 shouIn:(UIViewController *_Nonnull)vC
      sourceViewForiPad:(UIView *_Nullable)sView
             alertStyle:(UIAlertControllerStyle)style
               okAction:(void (^ _Nullable)(void))okBlock
           cancelAction:(void (^ _Nullable)(void))cancelBlock
      destructiveAction:(void (^ _Nullable)(void))destructiveBlock
      otherButtonAction:(void (^_Nullable)(NSInteger index))buttonIndexPath;

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

#pragma mark ------> JSON
/*! @brief Json字符串转字典
 */
+(NSDictionary * _Nonnull)dictionaryWithJsonString:(NSString * _Nonnull)jsonString;

#pragma mark ------> 数组
/*! @brief 数组升序
 */
+(NSArray * _Nonnull)arraySortASC:(NSArray * _Nonnull)arr;
/*! @brief 数组倒序
 */
+(NSArray * _Nonnull)arraySortINV:(NSArray * _Nonnull)arr;

#pragma mark ------> 字符串
/*! @brief 银行卡号辨别银行
 */
+(NSString * _Nonnull)backbankenameWithBanknumber:(NSString * _Nonnull)banknumber;

/*! @brief 数字小写转大写
 */
+(NSString * _Nonnull)getUperDigit:(NSString * _Nonnull)inputStr;
+(NSString * _Nonnull)getIntPartUper:(int)digit;
+(NSString * _Nonnull)getPartAfterDot:(NSString * _Nonnull)digitStr;
+(NSString * _Nonnull)dealWithDigit:(int)digit
                     grade:(GradeType)grade;
+(NSString * _Nonnull)digitUppercase:(NSString * _Nonnull)numstr;

/*! @brief 查找某字符在字符串的位置
 */
+ (NSArray * _Nonnull)rangeOfSubString:(NSString * _Nonnull)subStr
                     inString:(NSString * _Nonnull)string;

/*! @brief 英文星期几转中文星期几
 */
+(NSString * _Nonnull)engDayCoverToZHCN:(NSString * _Nonnull)str;

/*! @brief 判断是否存在SIM卡
 */
+(BOOL)isRolling:(UIView * _Nonnull)view;

/*! @brief 获取当前ViewController
*/
+(UIViewController *_Nonnull)getCurrentVC;
@end
