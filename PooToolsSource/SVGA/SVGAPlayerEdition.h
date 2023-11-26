//
//  SVGAPlayerEdition.h
//  PooTools_Example
//
//  Created by 邓杰豪 on 21/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SVGAPlayer/SVGAVideoEntity.h>

NS_ASSUME_NONNULL_BEGIN

@class SVGAPlayerEdition;

typedef void(^SVGAPlayerEditionDrawingBlock)(CALayer *contentLayer, NSInteger frameIndex);

typedef NS_ENUM(NSUInteger, SVGAPlayerPlayEditionError) {
    /// 没有SVGA资源
    SVGAPlayerPlayEditionError_NullEntity = 1,
    /// 没有父视图
    SVGAPlayerPlayEditionError_NullSuperview = 2,
    /// 只有一帧可播放帧（无法形成动画）
    SVGAPlayerPlayEditionError_OnlyOnePlayableFrame = 3,
};

typedef NS_ENUM(NSUInteger, SVGAPlayerEditionStoppedScene) {
    /// 停止后清空图层
    SVGAPlayerEditionStoppedScene_ClearLayers = 0,
    /// 停止后留在最后
    SVGAPlayerEditionStoppedScene_StepToTrailing = 1,
    /// 停止后回到开头
    SVGAPlayerEditionStoppedScene_StepToLeading = 2,
};

@protocol SVGAPlayerEditionDelegate <NSObject>
@optional
/// 正在播放的回调
- (void)svgaPlayerEdition:(SVGAPlayerEdition *)player animationPlaying:(NSInteger)currentFrame;
/// 完成一次播放的回调
- (void)svgaPlayerEdition:(SVGAPlayerEdition *)player animationDidFinishedOnce:(NSInteger)loopCount;
/// 完成所有播放的回调（前提条件：`loops > 0`）
- (void)svgaPlayerEdition:(SVGAPlayerEdition *)player animationDidFinishedAll:(NSInteger)loopCount;
/// 播放失败的回调
- (void)svgaPlayerEdition:(SVGAPlayerEdition *)player animationPlayFailed:(SVGAPlayerPlayEditionError)error;
@end

@interface SVGAPlayerEdition: UIView
/// 代理
@property (nonatomic, weak) id<SVGAPlayerEditionDelegate> delegate;

/// 播放所在RunLoop模式（默认为CommonMode）
@property (nonatomic, copy) NSRunLoopMode mainRunLoopMode;

/// 主动调用`stopAnimation`后的情景
@property (nonatomic, assign) SVGAPlayerEditionStoppedScene userStoppedScene;
/// 完成所有播放后（需要设置`loops > 0`）的情景
@property (nonatomic, assign) SVGAPlayerEditionStoppedScene finishedAllScene;

/// 播放次数（大于0才会触发回调`svgaPlayerDidFinishedAllAnimation`）
@property (nonatomic, assign) NSInteger loops;
/// 当前播放次数
@property (nonatomic, assign, readonly) NSInteger loopCount;

/// 是否静音
@property (nonatomic, assign) BOOL isMute;

/// 是否反转播放
@property (nonatomic, assign) BOOL isReversing;

/// SVGA资源
@property (nonatomic, strong, nullable) SVGAVideoEntity *videoItem;
/// 起始帧数
@property (nonatomic, assign, readonly) NSInteger startFrame;
/// 结束帧数
@property (nonatomic, assign, readonly) NSInteger endFrame;
/// 头部帧数
@property (readonly) NSInteger leadingFrame;
/// 尾部帧数
@property (readonly) NSInteger trailingFrame;

/// 当前帧数
@property (nonatomic, assign, readonly) NSInteger currentFrame;

/// 当前进度
@property (readonly) float progress;

/// 是否播放中
@property (readonly) BOOL isAnimating;

/// 是否完成所有播放（前提条件：`loops > 0`）
@property (readonly) BOOL isFinishedAll;

#pragma mark - 更换SVGA资源+设置播放区间
- (void)setVideoItem:(nullable SVGAVideoEntity *)videoItem
        currentFrame:(NSInteger)currentFrame;

- (void)setVideoItem:(nullable SVGAVideoEntity *)videoItem
          startFrame:(NSInteger)startFrame
            endFrame:(NSInteger)endFrame;

- (void)setVideoItem:(nullable SVGAVideoEntity *)videoItem
          startFrame:(NSInteger)startFrame
            endFrame:(NSInteger)endFrame
        currentFrame:(NSInteger)currentFrame;

#pragma mark - 设置播放区间
/// 重置起始帧数为最小帧数（0），结束帧数为最大帧数（videoItem.frames）
- (void)resetStartFrameAndEndFrame;

/// 设置起始帧数，结束帧数为最大帧数（videoItem.frames）
- (void)setStartFrameUntilTheEnd:(NSInteger)startFrame;

/// 设置结束帧数，起始帧数为最小帧数（0）
- (void)setEndFrameFromBeginning:(NSInteger)endFrame;

- (void)setStartFrame:(NSInteger)startFrame
             endFrame:(NSInteger)endFrame;

- (void)setStartFrame:(NSInteger)startFrame
             endFrame:(NSInteger)endFrame
         currentFrame:(NSInteger)currentFrame;

#pragma mark - 重置loopCount
- (void)resetLoopCount;

#pragma mark - 开始播放（如果已经完成所有播放，则重置loopCount；返回YES代表播放成功）
- (BOOL)startAnimation;

#pragma mark - 跳至指定帧（如果已经完成所有播放，则重置loopCount；返回YES代表播放/跳转成功）
- (BOOL)stepToFrame:(NSInteger)frame;
- (BOOL)stepToFrame:(NSInteger)frame andPlay:(BOOL)andPlay;

#pragma mark - 暂停播放
- (void)pauseAnimation;

#pragma mark - 停止播放
- (void)stopAnimation; // ==> [self stopAnimation:self.userStoppedScene];
- (void)stopAnimation:(SVGAPlayerEditionStoppedScene)scene;

#pragma mark - Dynamic Object
- (void)setImage:(nullable UIImage *)image forKey:(NSString *)aKey;
- (void)setAttributedText:(nullable NSAttributedString *)attributedText forKey:(NSString *)aKey;
- (void)setDrawingBlock:(nullable SVGAPlayerEditionDrawingBlock)drawingBlock forKey:(NSString *)aKey;
- (void)setHidden:(BOOL)hidden forKey:(NSString *)aKey;
- (void)clearDynamicObjects;
@end

NS_ASSUME_NONNULL_END
