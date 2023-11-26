//
//  SVGAPlayerEdition.m
//  PooTools_Example
//
//  Created by 邓杰豪 on 21/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

#import "SVGAPlayerEdition.h"
#import <SVGAPlayer/SVGAVideoSpriteEntity.h>
#import <SVGAPlayer/SVGAContentLayer.h>
#import <SVGAPlayer/SVGABitmapLayer.h>
#import <SVGAPlayer/SVGAAudioLayer.h>
#import <SVGAPlayer/SVGAAudioEntity.h>
#import <pthread.h>
#import "SVGAVideoEntity+PTEX.h"

#ifdef DEBUG
static NSString *globalStaticString = nil;
NSDateFormatter *getDateFormatter_(void) {
    static NSDateFormatter *dateFormatter_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter_ = [[NSDateFormatter alloc] init];
        [dateFormatter_ setDateFormat:@"hh:mm:ss:SS"];
    });
    return dateFormatter_;
}

#define PTNSLog(format, ...) do {fprintf(stderr, "[%s]-------------> %s:%d\t%s\n", [[getDateFormatter_() stringFromDate:[NSDate date]] UTF8String], [[[NSString stringWithUTF8String: __FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat: format, ## __VA_ARGS__] UTF8String]);fprintf(stderr, "我这里是打印,不要慌,我路过的😂😂😂😂😂😂😂😂😂😂😂😂\n");}while (0)
#else
#define PTNSLog(format, ...)
#endif

static inline void _jp_dispatch_sync_on_main_queue(void (^block)(void)) {
    if (pthread_main_np()) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

@interface _JPProxy : NSProxy
@property (nonatomic, weak, readonly) id target;
- (instancetype)initWithTarget:(id)target;
+ (instancetype)proxyWithTarget:(id)target;
@end

@implementation _JPProxy
- (instancetype)initWithTarget:(id)target {
    _target = target;
    return self;
}

+ (instancetype)proxyWithTarget:(id)target {
    return [[_JPProxy alloc] initWithTarget:target];
}

- (id)forwardingTargetForSelector:(SEL)selector {
    return _target;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    void *null = NULL;
    [invocation setReturnValue:&null];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    return [NSObject instanceMethodSignatureForSelector:@selector(init)];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [_target respondsToSelector:aSelector];
}

- (BOOL)isEqual:(id)object {
    return [_target isEqual:object];
}

- (NSUInteger)hash {
    return [_target hash];
}

- (Class)superclass {
    return [_target superclass];
}

- (Class)class {
    return [_target class];
}

- (BOOL)isKindOfClass:(Class)aClass {
    return [_target isKindOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass {
    return [_target isMemberOfClass:aClass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    return [_target conformsToProtocol:aProtocol];
}

- (BOOL)isProxy {
    return YES;
}

- (NSString *)description {
    return [_target description];
}

- (NSString *)debugDescription {
    return [_target debugDescription];
}
@end

@interface SVGAPlayerEdition ()
@property (nonatomic, strong) CALayer *drawLayer;
@property (nonatomic, copy) NSArray<SVGAContentLayer *> *contentLayers;
@property (nonatomic, copy) NSArray<SVGAAudioLayer *> *audioLayers;

@property (nonatomic, strong) NSMutableDictionary<NSString *, UIImage *> *dynamicObjects;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSAttributedString *> *dynamicTexts;
@property (nonatomic, strong) NSMutableDictionary<NSString *, SVGAPlayerEditionDrawingBlock> *dynamicDrawings;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *dynamicHiddens;

@property (nonatomic, strong) CADisplayLink *displayLink;
@end

@implementation SVGAPlayerEdition

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initPlayer];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initPlayer];
    }
    return self;
}

- (void)initPlayer {
#if POOTOOLS_DEBUG
    PTNSLog(@"[SVGAPlayerEdition_%p] alloc", self);
#endif
    self.contentMode = UIViewContentModeTop;
    _mainRunLoopMode = NSRunLoopCommonModes;
    _userStoppedScene = SVGAPlayerEditionStoppedScene_ClearLayers;
    _finishedAllScene = SVGAPlayerEditionStoppedScene_ClearLayers;
    _loops = 0;
    _loopCount = 0;
    _isReversing = NO;
    _isMute = NO;
    _startFrame = 0;
    _endFrame = 0;
    _currentFrame = 0;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (newSuperview == nil) {
        [self stopAnimation:SVGAPlayerEditionStoppedScene_ClearLayers];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.videoItem && self.drawLayer) {
        [self __resizeLayers];
    }
}

- (void)dealloc {
    [self stopAnimation:SVGAPlayerEditionStoppedScene_ClearLayers];
#if POOTOOLS_DEBUG
    PTNSLog(@"[SVGAPlayerEdition_%p] dealloc", self);
#endif
}

#pragma mark - Setter & Getter

- (void)setMainRunLoopMode:(NSRunLoopMode)mainRunLoopMode {
    if ([_mainRunLoopMode isEqual:mainRunLoopMode]) return;
    if (self.displayLink) {
        if (_mainRunLoopMode) {
            [self.displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:_mainRunLoopMode];
        }
        if (mainRunLoopMode.length) {
            [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:mainRunLoopMode];
        }
    }
    _mainRunLoopMode = mainRunLoopMode.copy;
}

- (void)setLoops:(NSInteger)loops {
    _loops = loops;
    _loopCount = 0;
}

- (void)setIsMute:(BOOL)isMute {
    if (_isMute == isMute) return;
    _isMute = isMute;
    
    float volume = isMute ? 0 : 1;
    for (SVGAAudioLayer *layer in self.audioLayers) {
        layer.audioPlayer.volume = volume;
    }
}

- (void)setIsReversing:(BOOL)isReversing {
    if (_isReversing == isReversing) return;
    _isReversing = isReversing;
    
    _jp_dispatch_sync_on_main_queue(^{
        if (self.isAnimating || self.drawLayer == nil) return;
        if (self->_isReversing && self->_currentFrame == self->_startFrame) {
            self->_currentFrame = self->_endFrame;
            [self __updateLayers];
        } else if (!self->_isReversing && self->_currentFrame == self->_endFrame) {
            self->_currentFrame = self->_startFrame;
            [self __updateLayers];
        }
    });
}

- (void)setVideoItem:(SVGAVideoEntity *)videoItem {
    [self setVideoItem:videoItem
            startFrame:0
              endFrame:(videoItem.frames > 1 ? (videoItem.frames - 1) : 0)];
}

- (NSInteger)leadingFrame {
    return _isReversing ? _endFrame : _startFrame;
}

- (NSInteger)trailingFrame {
    return _isReversing ? _startFrame : _endFrame;
}

- (float)progress {
    NSInteger playableFrames = _endFrame - _startFrame;
    if (playableFrames <= 0) return 0;
    
    // 都是正序
//    float progress = 0;
//    if (_isReversing) {
//        progress = (float)(_endFrame - _currentFrame) / (float)playableFrames;
//    } else {
//        progress = (float)(_currentFrame - _startFrame) / (float)playableFrames;
//    }
    
    // 包括正反序
    float progress = (float)(_currentFrame - _startFrame) / (float)playableFrames;
    
    return progress > 1 ? 1 : (progress < 0 ? 0 : progress);
}

- (BOOL)isAnimating {
    return self.displayLink != nil;
}

- (BOOL)isFinishedAll {
    return (_loops > 0) && (_loopCount >= _loops);
}

#pragma mark - 公开方法

#pragma mark 更换SVGA资源+设置播放区间
- (void)setVideoItem:(SVGAVideoEntity *)videoItem
        currentFrame:(NSInteger)currentFrame {
    [self setVideoItem:videoItem
            startFrame:0
              endFrame:(videoItem.frames > 1 ? (videoItem.frames - 1) : 0)
          currentFrame:currentFrame];
}

- (void)setVideoItem:(SVGAVideoEntity *)videoItem
          startFrame:(NSInteger)startFrame
            endFrame:(NSInteger)endFrame {
    [self setVideoItem:videoItem
            startFrame:startFrame
              endFrame:endFrame
          currentFrame:(_isReversing ? endFrame : startFrame)];
}

- (void)setVideoItem:(SVGAVideoEntity *)videoItem
          startFrame:(NSInteger)startFrame
            endFrame:(NSInteger)endFrame
        currentFrame:(NSInteger)currentFrame {
    if (_videoItem == nil && videoItem == nil) return;
    
    [self stopAnimation:SVGAPlayerEditionStoppedScene_ClearLayers];
    
    if (videoItem && videoItem.entityError == SVGAVideoEntityError_None) {
        _videoItem = videoItem;
    } else {
        _videoItem = nil;
    }
    
    _loopCount = 0;
    
    [self setStartFrame:startFrame
               endFrame:endFrame
           currentFrame:currentFrame];
}

#pragma mark 设置播放区间
- (void)resetStartFrameAndEndFrame {
    [self setStartFrame:_videoItem.minFrame
               endFrame:_videoItem.maxFrame
           currentFrame:_currentFrame];
}

- (void)setStartFrameUntilTheEnd:(NSInteger)startFrame {
    [self setStartFrame:startFrame
               endFrame:_videoItem.maxFrame
           currentFrame:_currentFrame];
}

- (void)setEndFrameFromBeginning:(NSInteger)endFrame {
    [self setStartFrame:_videoItem.minFrame
               endFrame:endFrame
           currentFrame:_currentFrame];
}

- (void)setStartFrame:(NSInteger)startFrame endFrame:(NSInteger)endFrame {
    [self setStartFrame:startFrame
               endFrame:endFrame
           currentFrame:_currentFrame];
}

- (void)setStartFrame:(NSInteger)startFrame
             endFrame:(NSInteger)endFrame
         currentFrame:(NSInteger)currentFrame {
    NSInteger frames = _videoItem.frames;
    
    if (frames <= 1) {
        _startFrame = 0;
        _endFrame = 0;
        _currentFrame = 0;
        if (!self.isAnimating) {
            [self __drawLayersIfNeeded:YES];
        }
        return;
    }
    
    if (endFrame < 0) {
        endFrame = 0;
    } else if (endFrame >= frames) {
        endFrame = frames - 1;
    }
    
    if (startFrame < 0) {
        startFrame = 0;
    } else if (startFrame > endFrame) {
        startFrame = endFrame;
    }
    
    if (currentFrame < startFrame) {
        currentFrame = startFrame;
    } else if (currentFrame > endFrame) {
        currentFrame = endFrame;
    }
    
    _startFrame = startFrame;
    _endFrame = endFrame;
    _currentFrame = currentFrame;
    
    if (!self.isAnimating) {
        [self __drawLayersIfNeeded:YES];
    }
}

#pragma mark 重置loopCount
- (void)resetLoopCount {
    _loopCount = 0;
}

#pragma mark 开始播放
- (BOOL)startAnimation {
    [self pauseAnimation];
    
    NSInteger frame = _currentFrame;
    
    if (self.isFinishedAll) {
        _loopCount = 0;
        frame = self.leadingFrame;
    }
    
    if (_isReversing) {
        if (frame <= _startFrame) {
            frame = _endFrame;
        }
    } else {
        if (frame >= _endFrame) {
            frame = _startFrame;
        }
    }
    
    BOOL isNeedUpdate = _currentFrame != frame;
    _currentFrame = frame;
    
    [self __drawLayersIfNeeded:isNeedUpdate];
    if (![self __checkIsCanDraw]) return NO;
    
    [self __addLink];
    return YES;
}

#pragma mark 跳至指定帧
- (BOOL)stepToFrame:(NSInteger)frame {
    return [self stepToFrame:frame andPlay:NO];
}

- (BOOL)stepToFrame:(NSInteger)frame andPlay:(BOOL)andPlay {
    [self pauseAnimation];
    
    if (andPlay && self.isFinishedAll) {
        _loopCount = 0;
        frame = self.leadingFrame;
    }
    
    if (frame < _videoItem.minFrame) {
        PTNSLog(@"[SVGAPlayerEdition_%p] 给的frame超出了总frames的范围！这里给你修正！", self);
        frame = _videoItem.minFrame;
    } else if (frame > _videoItem.maxFrame) {
        PTNSLog(@"[SVGAPlayerEdition_%p] 给的frame超出了总frames的范围！这里给你修正！", self);
        frame = _videoItem.maxFrame;
    }
    
    BOOL isNeedUpdate = _currentFrame != frame;
    _currentFrame = frame;
    
    [self __drawLayersIfNeeded:isNeedUpdate];
    if (![self __checkIsCanDraw]) return NO;
    
    if (andPlay) {
        [self __addLink];
    } else {
        if (isNeedUpdate) PTNSLog(@"[SVGAPlayerEdition_%p] 已跳至第%zd帧，并且不播放", self, frame);
    }
    return YES;
}

#pragma mark 暂停播放
- (void)pauseAnimation {
    [self __removeLink];
    [self __stopAudios];
}

#pragma mark 停止播放
- (void)stopAnimation {
    [self stopAnimation:_userStoppedScene];
}

- (void)stopAnimation:(SVGAPlayerEditionStoppedScene)scene {
    switch (scene) {
        case SVGAPlayerEditionStoppedScene_StepToTrailing:
            [self stepToFrame:self.trailingFrame];
            break;
            
        case SVGAPlayerEditionStoppedScene_StepToLeading:
            [self stepToFrame:self.leadingFrame];
            break;
            
        default:
            [self pauseAnimation];
            [self __clearLayers];
            _currentFrame = 0;
            break;
    }
}

#pragma mark - 私有方法

/// 停止音频播放
- (void)__stopAudios {
    for (SVGAAudioLayer *layer in self.audioLayers) {
        if (layer.audioPlaying) {
            [layer.audioPlayer stop];
            layer.audioPlaying = NO;
        }
    }
}

/// 清空图层
- (void)__clearLayers {
#if POOTOOLS_DEBUG
    PTNSLog(@"[SVGAPlayerEdition_%p] __clearLayers", self);
#endif
    self.audioLayers = nil;
    self.contentLayers = nil;
    [self.drawLayer removeFromSuperlayer];
    self.drawLayer = nil;
}

/// 绘制图层（如需）
- (void)__drawLayersIfNeeded:(BOOL)isNeedUpdate {
    _jp_dispatch_sync_on_main_queue(^{
        if (self.videoItem == nil || self.superview == nil) {
            [self __clearLayers];
            return;
        }
        
        if (self.drawLayer == nil) {
            [self __clearLayers];
            [self __drawLayers];
        } else if (isNeedUpdate) {
            [self __updateLayers];
        }
    });
}

/// 绘制图层
- (void)__drawLayers {
#if POOTOOLS_DEBUG
    PTNSLog(@"[SVGAPlayerEdition_%p] __drawLayers", self);
#endif
    self.drawLayer = [[CALayer alloc] init];
    self.drawLayer.frame = CGRectMake(0, 0, self.videoItem.videoSize.width, self.videoItem.videoSize.height);
    self.drawLayer.masksToBounds = true;
    
    NSMutableDictionary *tempHostLayers = [NSMutableDictionary dictionary];
    NSMutableArray *tempContentLayers = [NSMutableArray array];
    [self.videoItem.sprites enumerateObjectsUsingBlock:^(SVGAVideoSpriteEntity * _Nonnull sprite, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *imageKey = sprite.imageKey;
        
        UIImage *bitmap;
        if (imageKey != nil) {
            NSString *bitmapKey = [imageKey stringByDeletingPathExtension];
            if (_dynamicObjects[bitmapKey] != nil) {
                bitmap = self.dynamicObjects[bitmapKey];
            } else {
                bitmap = self.videoItem.images[bitmapKey];
            }
        }
        SVGAContentLayer *contentLayer = [sprite requestLayerWithBitmap:bitmap];
        contentLayer.imageKey = imageKey;
        [tempContentLayers addObject:contentLayer];
        
        if ([imageKey hasSuffix:@".matte"]) {
            CALayer *hostLayer = [[CALayer alloc] init];
            hostLayer.mask = contentLayer;
            tempHostLayers[imageKey] = hostLayer;
        } else {
            if (sprite.matteKey && sprite.matteKey.length > 0) {
                CALayer *hostLayer = tempHostLayers[sprite.matteKey];
                [hostLayer addSublayer:contentLayer];
                if (![sprite.matteKey isEqualToString:self.videoItem.sprites[idx - 1].matteKey]) {
                    [self.drawLayer addSublayer:hostLayer];
                }
            } else {
                [self.drawLayer addSublayer:contentLayer];
            }
        }
        
        if (imageKey != nil) {
            if (_dynamicTexts[imageKey] != nil) {
                NSAttributedString *text = self.dynamicTexts[imageKey];
                UIImage *kBitmap = self.videoItem.images[imageKey];
                CGSize bitmapSize = CGSizeMake(kBitmap.size.width * kBitmap.scale, kBitmap.size.height * kBitmap.scale);
                CGSize size = [text boundingRectWithSize:bitmapSize options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
                CATextLayer *textLayer = [CATextLayer layer];
                textLayer.contentsScale = UIScreen.mainScreen.scale;
                textLayer.frame = CGRectMake(0, 0, size.width, size.height);
                textLayer.string = text;
                [contentLayer addSublayer:textLayer];
                contentLayer.textLayer = textLayer;
                [contentLayer resetTextLayerProperties:text];
            }
            
            if (_dynamicDrawings[imageKey] != nil) {
                contentLayer.dynamicDrawingBlock = self.dynamicDrawings[imageKey];
            }
            
            if (_dynamicHiddens[imageKey] != nil) {
                contentLayer.dynamicHidden = [self.dynamicHiddens[imageKey] boolValue];
            }
        }
    }];
    self.contentLayers = tempContentLayers.copy;
    
    NSMutableArray *audioLayers = [NSMutableArray array];
    [self.videoItem.audios enumerateObjectsUsingBlock:^(SVGAAudioEntity * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SVGAAudioLayer *audioLayer = [[SVGAAudioLayer alloc] initWithAudioItem:obj videoItem:self.videoItem];
        [audioLayers addObject:audioLayer];
    }];
    self.audioLayers = audioLayers.copy;
    
    [self.layer addSublayer:self.drawLayer];
    [self __updateLayers];
    [self __resizeLayers];
}

/// 更新图层+音频
- (void)__updateLayers {
    [CATransaction setDisableActions:YES];
    for (SVGAContentLayer *layer in self.contentLayers) {
        if ([layer isKindOfClass:[SVGAContentLayer class]]) {
            [layer stepToFrame:self.currentFrame];
        }
    }
    [CATransaction setDisableActions:NO];
    
    // 反转、停止时，不播放音频
    if (!self.isReversing && self.isAnimating && self.audioLayers.count > 0) {
        for (SVGAAudioLayer *layer in self.audioLayers) {
            if (!layer.audioPlaying && layer.audioItem.startFrame <= self.currentFrame && self.currentFrame <= layer.audioItem.endFrame) {
                layer.audioPlayer.volume = self.isMute ? 0 : 1; // JP修改_设置是否静音
                [layer.audioPlayer setCurrentTime:(NSTimeInterval)(layer.audioItem.startTime / 1000)];
                [layer.audioPlayer play];
                layer.audioPlaying = YES;
            }
            if (layer.audioPlaying && layer.audioItem.endFrame <= self.currentFrame) {
                [layer.audioPlayer stop];
                layer.audioPlaying = NO;
            }
        }
    }
}

/// 调整图层
- (void)__resizeLayers {
    CGSize videoSize = self.videoItem.videoSize;
    switch (self.contentMode) {
        case UIViewContentModeScaleAspectFit:
        {
            CGSize viewSize = self.bounds.size;
            CGFloat videoRatio = videoSize.width / videoSize.height;
            CGFloat layerRatio = viewSize.width / viewSize.height;
            
            CGFloat ratio;
            CGFloat offsetX;
            CGFloat offsetY;
            if (videoRatio > layerRatio) { // 跟AspectFill不一样的地方
                ratio = viewSize.width / videoSize.width;
                offsetX = (1.0 - ratio) / 2.0 * videoSize.width;
                offsetY = (1.0 - ratio) / 2.0 * videoSize.height - (viewSize.height - videoSize.height * ratio) / 2.0;
            } else {
                ratio = viewSize.height / videoSize.height;
                offsetX = (1.0 - ratio) / 2.0 * videoSize.width - (viewSize.width - videoSize.width * ratio) / 2.0;
                offsetY = (1.0 - ratio) / 2.0 * videoSize.height;
            }
            
            self.drawLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransformMake(ratio, 0, 0, ratio, -offsetX, -offsetY));
            break;
        }
            
        case UIViewContentModeScaleAspectFill:
        {
            CGSize viewSize = self.bounds.size;
            CGFloat videoRatio = videoSize.width / videoSize.height;
            CGFloat layerRatio = viewSize.width / viewSize.height;
            
            CGFloat ratio;
            CGFloat offsetX;
            CGFloat offsetY;
            if (videoRatio < layerRatio) { // 跟AspectFit不一样的地方
                ratio = viewSize.width / videoSize.width;
                offsetX = (1.0 - ratio) / 2.0 * videoSize.width;
                offsetY = (1.0 - ratio) / 2.0 * videoSize.height - (viewSize.height - videoSize.height * ratio) / 2.0;
            } else {
                ratio = viewSize.height / videoSize.height;
                offsetX = (1.0 - ratio) / 2.0 * videoSize.width - (viewSize.width - videoSize.width * ratio) / 2.0;
                offsetY = (1.0 - ratio) / 2.0 * videoSize.height;
            }
            
            self.drawLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransformMake(ratio, 0, 0, ratio, -offsetX, -offsetY));
            break;
        }
            
        case UIViewContentModeTop:
        {
            CGFloat scaleX = self.frame.size.width / videoSize.width;
            CGFloat offsetX = (1.0 - scaleX) / 2.0 * videoSize.width;
            CGFloat offsetY = (1.0 - scaleX) / 2.0 * videoSize.height;
            self.drawLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransformMake(scaleX, 0, 0, scaleX, -offsetX, -offsetY));
            break;
        }
            
        case UIViewContentModeBottom:
        {
            CGFloat scaleX = self.frame.size.width / videoSize.width;
            CGFloat offsetX = (1.0 - scaleX) / 2.0 * videoSize.width;
            CGFloat offsetY = (1.0 - scaleX) / 2.0 * videoSize.height;
            CGFloat diffY = self.frame.size.height - videoSize.height * scaleX;
            self.drawLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransformMake(scaleX, 0, 0, scaleX, -offsetX, -offsetY + diffY));
            break;
        }
            
        case UIViewContentModeLeft:
        {
            CGFloat scaleY = self.frame.size.height / videoSize.height;
            CGFloat offsetX = (1.0 - scaleY) / 2.0 * videoSize.width;
            CGFloat offsetY = (1.0 - scaleY) / 2.0 * videoSize.height;
            self.drawLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransformMake(scaleY, 0, 0, scaleY, -offsetX, -offsetY));
            break;
        }
            
        case UIViewContentModeRight:
        {
            CGFloat scaleY = self.frame.size.height / videoSize.height;
            CGFloat offsetX = (1.0 - scaleY) / 2.0 * videoSize.width;
            CGFloat offsetY = (1.0 - scaleY) / 2.0 * videoSize.height;
            CGFloat diffX = self.frame.size.width - videoSize.width * scaleY;
            self.drawLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransformMake(scaleY, 0, 0, scaleY, -offsetX + diffX, -offsetY));
            break;
        }
            
        default:
        {
            CGFloat scaleX = self.frame.size.width / videoSize.width;
            CGFloat scaleY = self.frame.size.height / videoSize.height;
            CGFloat offsetX = (1.0 - scaleX) / 2.0 * videoSize.width;
            CGFloat offsetY = (1.0 - scaleY) / 2.0 * videoSize.height;
            self.drawLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransformMake(scaleX, 0, 0, scaleY, -offsetX, -offsetY));
            break;
        }
    }
}

- (BOOL)__checkIsCanDraw {
    if (self.videoItem == nil) {
#if POOTOOLS_DEBUG
        PTNSLog(@"[SVGAPlayerEdition_%p] videoItem是空的，无法播放", self);
#endif
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(svgaPlayerEdition:animationPlayFailed:)]) {
            [self.delegate svgaPlayerEdition:self animationPlayFailed:SVGAPlayerPlayEditionError_NullEntity];
        }
        return NO;
    }
    
    if (self.superview == nil) {
#if POOTOOLS_DEBUG
        PTNSLog(@"[SVGAPlayerEdition_%p] superview是空的，无法播放", self);
#endif
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(svgaPlayerEdition:animationPlayFailed:)]) {
            [self.delegate svgaPlayerEdition:self animationPlayFailed:SVGAPlayerPlayEditionError_NullSuperview];
        }
        return NO;
    }
    
    return YES;
}

#pragma mark - Display Link

- (void)__addLink {
    [self __removeLink];
#if POOTOOLS_DEBUG
    PTNSLog(@"[SVGAPlayerEdition_%p] 开启定时器，此时startFrame: %zd, endFrame: %zd, currentFrame: %zd, loopCount: %zd", self, self.startFrame, self.endFrame, self.currentFrame, self.loopCount);
#endif
    self.displayLink = [CADisplayLink displayLinkWithTarget:[_JPProxy proxyWithTarget:self] selector:@selector(__linkHandle)];
    self.displayLink.preferredFramesPerSecond = self.videoItem.FPS;
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:self.mainRunLoopMode];
}

- (void)__removeLink {
    if (self.displayLink) {
#if POOTOOLS_DEBUG
        PTNSLog(@"[SVGAPlayerEdition_%p] 关闭定时器，此时startFrame: %zd, endFrame: %zd, currentFrame: %zd, loopCount: %zd", self, self.startFrame, self.endFrame, self.currentFrame, self.loopCount);
#endif
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

- (void)__linkHandle {
    id delegate = self.delegate;
    
    BOOL isFinish = NO;
    if (_isReversing) {
        _currentFrame -= 1;
        if (_currentFrame < _startFrame) {
            _currentFrame = _startFrame;
            _loopCount += 1;
            isFinish = YES;
        }
    } else {
        _currentFrame += 1;
        if (_currentFrame > _endFrame) {
            _currentFrame = _endFrame;
            _loopCount += 1;
            isFinish = YES;
        }
    }
    
    if (self.isFinishedAll) { // 全部完成
        _loopCount = _loops;
        [self stopAnimation:_finishedAllScene];
#if POOTOOLS_DEBUG
        PTNSLog(@"[SVGAPlayerEdition_%p] 全部播完了 %zd", self, _loops);
#endif
        if (delegate != nil && [delegate respondsToSelector:@selector(svgaPlayerEdition:animationDidFinishedAll:)]) {
            [delegate svgaPlayerEdition:self animationDidFinishedAll:_loopCount];
        }
        return;
    }
    
    if (isFinish) { // 完成一次
        [self __stopAudios];
        if (delegate != nil && [delegate respondsToSelector:@selector(svgaPlayerEdition:animationDidFinishedOnce:)]) {
            [delegate svgaPlayerEdition:self animationDidFinishedOnce:_loopCount];
        }
        
        NSInteger leadingFrame = self.leadingFrame;
        NSInteger trailingFrame = self.trailingFrame;
        // 有可能在回调时修改了新的startFrame和endFrame，得判断一下是否继续运行定时器
        if (leadingFrame == trailingFrame) {
            // 头部帧数与尾部帧数相同，说明只有一帧可播放帧，没必要运行定时器了
            [self stepToFrame:trailingFrame];
#if POOTOOLS_DEBUG
            PTNSLog(@"[SVGAPlayerEdition_%p] 只有一帧可播放帧，无法形成动画", self);
#endif
            if (delegate != nil && [delegate respondsToSelector:@selector(svgaPlayerEdition:animationPlayFailed:)]) {
                [delegate svgaPlayerEdition:self animationPlayFailed:SVGAPlayerPlayEditionError_OnlyOnePlayableFrame];
            }
            return;
        }
        
        // 回到开头
        // 有可能在回调时进行了【反转】，导致当前帧数与头部帧数相等，因此现在应该是跳去下一帧
        if (_currentFrame == leadingFrame) {
            // 能来到这里，证明至少有两帧，放心跳
            if (_isReversing) {
                leadingFrame -= 1;
            } else {
                leadingFrame += 1;
            }
        }
        _currentFrame = leadingFrame;
    } // 开始下一次
    
    // 刷新最新帧
#if POOTOOLS_DEBUG
    PTNSLog(@"[SVGAPlayerEdition_%p] animating %zd", self, _currentFrame);
#endif
    [self __updateLayers];
    if (delegate != nil && [delegate respondsToSelector:@selector(svgaPlayerEdition:animationPlaying:)]) {
        [delegate svgaPlayerEdition:self animationPlaying:_currentFrame];
    }
}

#pragma mark - Dynamic Object

- (NSMutableDictionary *)dynamicObjects {
    if (_dynamicObjects == nil) {
        _dynamicObjects = [NSMutableDictionary dictionary];
    }
    return _dynamicObjects;
}

- (NSMutableDictionary *)dynamicTexts {
    if (_dynamicTexts == nil) {
        _dynamicTexts = [NSMutableDictionary dictionary];
    }
    return _dynamicTexts;
}

- (NSMutableDictionary *)dynamicDrawings {
    if (_dynamicDrawings == nil) {
        _dynamicDrawings = [NSMutableDictionary dictionary];
    }
    return _dynamicDrawings;
}

- (NSMutableDictionary *)dynamicHiddens {
    if (_dynamicHiddens == nil) {
        _dynamicHiddens = [NSMutableDictionary dictionary];
    }
    return _dynamicHiddens;
}

- (void)setImage:(UIImage *)image forKey:(NSString *)aKey {
    if (aKey == nil) return;
    self.dynamicObjects[aKey] = image;
    
    if (self.contentLayers.count == 0) return;
    
    if (!image) image = self.videoItem.images[aKey];
    for (SVGAContentLayer *layer in self.contentLayers) {
        if ([layer isKindOfClass:[SVGAContentLayer class]] && [layer.imageKey isEqualToString:aKey]) {
            layer.bitmapLayer.contents = (__bridge id _Nullable)([image CGImage]);
            break;
        }
    }
}

- (void)setAttributedText:(NSAttributedString *)attributedText forKey:(NSString *)aKey {
    if (aKey == nil) return;
    self.dynamicTexts[aKey] = attributedText;
    
    if (self.contentLayers.count == 0) return;
    for (SVGAContentLayer *layer in self.contentLayers) {
        if ([layer isKindOfClass:[SVGAContentLayer class]] && [layer.imageKey isEqualToString:aKey]) {
            if (attributedText) {
                CATextLayer *textLayer = layer.textLayer;
                if (textLayer == nil) {
                    UIImage *bitmap = self.videoItem.images[aKey];
                    CGSize bitmapSize = CGSizeMake(bitmap.size.width * bitmap.scale, bitmap.size.height * bitmap.scale);
                    CGSize size = [attributedText boundingRectWithSize:bitmapSize options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
                    textLayer = [CATextLayer layer];
                    textLayer.contentsScale = UIScreen.mainScreen.scale;
                    textLayer.frame = CGRectMake(0, 0, size.width, size.height);
                    [layer addSublayer:textLayer];
                    layer.textLayer = textLayer;
                    [layer resetTextLayerProperties:attributedText];
                }
                textLayer.string = attributedText;
            } else {
                [layer.textLayer removeFromSuperlayer];
                layer.textLayer = nil;
            }
            break;
        }
    }
}

- (void)setDrawingBlock:(SVGAPlayerEditionDrawingBlock)drawingBlock forKey:(NSString *)aKey {
    if (aKey == nil) return;
    self.dynamicDrawings[aKey] = drawingBlock;
    
    if (self.contentLayers.count == 0) return;
    for (SVGAContentLayer *layer in self.contentLayers) {
        if ([layer isKindOfClass:[SVGAContentLayer class]] && [layer.imageKey isEqualToString:aKey]) {
            layer.dynamicDrawingBlock = drawingBlock;
            break;
        }
    }
}

- (void)setHidden:(BOOL)hidden forKey:(NSString *)aKey {
    if (aKey == nil) return;
    self.dynamicHiddens[aKey] = @(hidden);
    
    if (self.contentLayers.count == 0) return;
    for (SVGAContentLayer *layer in self.contentLayers) {
        if ([layer isKindOfClass:[SVGAContentLayer class]] && [layer.imageKey isEqualToString:aKey]) {
            layer.dynamicHidden = hidden;
            break;
        }
    }
}

- (void)clearDynamicObjects {
    [_dynamicObjects removeAllObjects];
    [_dynamicTexts removeAllObjects];
    [_dynamicDrawings removeAllObjects];
    [_dynamicHiddens removeAllObjects];
}

@end
