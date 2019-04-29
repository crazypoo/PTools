//
//  PVideoConfig.h
//  XMNaio_Client
//
//  Created by MYX on 2017/5/16.
//  Copyright © 2017年 E33QU5QCP3.com.xnmiao.customer.XMNiao-Customer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PMacros.h"

#define kThemeBlackColor   [UIColor blackColor]
#define kThemeTineColor    [UIColor greenColor]

#define kThemeWaringColor  [UIColor redColor]
#define kThemeWhiteColor   [UIColor whiteColor]
#define kThemeGraryColor   [UIColor grayColor]

#define kVideoDicName      @"kLittleVideo"// 视频保存路径

extern void kz_dispatch_after(float time, dispatch_block_t block);

typedef NS_ENUM(NSUInteger, PVideoViewShowType) {
    PVideoViewShowTypeSmall,  // 小屏幕 ...聊天界面的
    PVideoViewShowTypeSingle, // 全屏 ... 朋友圈界面的
};

@interface PVideoConfig : NSObject

/*! @brief 录像的View大小
 */
+ (CGRect)viewFrameWithType:(PVideoViewShowType)type
                  video_W_H:(CGFloat)video_W_H
       withControViewHeight:(CGFloat)controViewHeight;
/*! @brief 视频View的尺寸
 */
+ (CGSize)videoViewDefaultSizeWithVideo_W_H:(CGFloat)video_W_H;
/*! @brief 默认视频分辨率
 */
+ (CGSize)defualtVideoSizeWithVideo_W_H:(CGFloat)video_W_H
                       withVideoWidthPX:(CGFloat)videoWidthPX;
/*! @brief 渐变色
 */
+ (NSArray *)gradualColors;
/*! @brief 模糊View
 */
+ (void)motionBlurView:(UIView *)superView;

+ (void)showHinInfo:(NSString *)text
             inView:(UIView *)superView
              frame:(CGRect)frame
           timeLong:(NSTimeInterval)time;

@end

/*!
 *  视频对象 Model类
 */
@interface PVideoModel : NSObject
/// 完整视频 本地路径
@property (nonatomic, copy) NSString *videoAbsolutePath;
/// 缩略图 路径
@property (nonatomic, copy) NSString *thumAbsolutePath;
// 录制时间
@property (nonatomic, strong) NSDate *recordTime;

@end

@interface PVideoUtil : NSObject

/*!
 *  有视频的存在
 */
+ (BOOL)existVideo;

/*!
 *  时间倒序 后的视频列表
 */
+ (NSArray *)getSortVideoList;

/*!
 *  保存缩略图
 *
 *  @param videoUrl 视频路径
 *  @param second   第几秒的缩略图
 */
+ (void)saveThumImageWithVideoURL:(NSURL *)videoUrl
                           second:(int64_t)second;

/*!
 *  产生新的对象
 */
+ (PVideoModel *)createNewVideo;

/*!
 *  删除视频
 */
+ (void)deleteVideo:(NSString *)videoPath;

@end
