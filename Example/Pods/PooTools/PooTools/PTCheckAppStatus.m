//
//  PTCheckAppStatus.m
//  CloudGateWorker
//
//  Created by 邓杰豪 on 2019/3/27.
//  Copyright © 2019年 邓杰豪. All rights reserved.
//

#import "PTCheckAppStatus.h"

#import "PooSystemInfo.h"
#import "RCDraggableButton.h"
#import <Masonry/Masonry.h>
#import "PMacros.h"

@interface PTCheckAppStatus ()
{
    CADisplayLink *displayLink;
    NSTimeInterval lastTime;
    NSUInteger count;
}
@property(nonatomic,copy) void (^fpsHandler)(NSInteger fpsValue);
@property (nonatomic,strong) RCDraggableButton *avatar;
@end

@implementation PTCheckAppStatus
@synthesize fpsLabel;

- (void)dealloc
{
    [displayLink setPaused:YES];
    [displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

+ (PTCheckAppStatus *)sharedInstance
{
    static PTCheckAppStatus *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PTCheckAppStatus alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationDidBecomeActiveNotification)
                                                     name: UIApplicationDidBecomeActiveNotification
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationWillResignActiveNotification)
                                                     name: UIApplicationWillResignActiveNotification
                                                   object: nil];
        [self createUI];
    }
    return self;
}

-(void)createUI
{
    if (!self.avatar)
    {
        self.avatar = [[RCDraggableButton alloc] initInView:kAppDelegateWindow WithFrame:CGRectMake(0, HEIGHT_STATUS, kSCREEN_WIDTH, 30)];
        self.avatar.adjustsImageWhenHighlighted = NO;
        self.avatar.tag = 9999;
        
        // Track FPS using display link
        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkTick:)];
        [displayLink setPaused:YES];
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        
        // fpsLabel
        fpsLabel = [UILabel new];
        fpsLabel.font = kDEFAULT_FONT(kDevLikeFont_Bold, 12);
        fpsLabel.numberOfLines = 0;
        fpsLabel.lineBreakMode = NSLineBreakByClipping;
        fpsLabel.textColor = [UIColor whiteColor];
        fpsLabel.backgroundColor = [UIColor blackColor];
        fpsLabel.textAlignment = NSTextAlignmentCenter;
        fpsLabel.tag = 101;
        [self.avatar addSubview:fpsLabel];
        [fpsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.bottom.equalTo(self.avatar);
        }];
    }
    self.closed = NO;
}

- (void)displayLinkTick:(CADisplayLink *)link
{
    if (lastTime == 0)
    {
        lastTime = link.timestamp;
        return;
    }
    
    count++;
    NSTimeInterval interval = link.timestamp - lastTime;
    if (interval < 1) return;
    lastTime = link.timestamp;
    float fps = count / interval;
    count = 0;
    
    NSString *text = [NSString stringWithFormat:@"CUP USED:%.3f FPS:%d\nMEMORY:U%.0f A%.0f W%.0f I%.0f F%.0f ",[PooSystemInfo cpuUsageForApp],(int)round(fps),[PooSystemInfo usedMemory],[PooSystemInfo activeMemory],[PooSystemInfo wiredMemory],[PooSystemInfo inactiveMemory],[PooSystemInfo freeMemory]];
    [fpsLabel setText: text];
    if (_fpsHandler)
    {
        _fpsHandler((int)round(fps));
    }
}

- (void)open
{
    [displayLink setPaused:NO];
    [self createUI];
}

- (void)openWithHandler:(void (^)(NSInteger fpsValue))handler
{
    [[PTCheckAppStatus sharedInstance] open];
    _fpsHandler=handler;
}

- (void)close
{
    [displayLink setPaused:YES];
    self.closed = YES;
    [self.avatar removeFromSuperview];
    self.avatar = nil;
}

- (void)applicationDidBecomeActiveNotification
{
    [displayLink setPaused:NO];
}

- (void)applicationWillResignActiveNotification
{
    [displayLink setPaused:YES];
}

@end

