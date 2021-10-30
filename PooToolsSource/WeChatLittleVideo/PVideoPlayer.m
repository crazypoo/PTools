//
//  PVideoPlayer.m
//  XMNaio_Client
//
//  Created by MYX on 2017/5/16.
//  Copyright © 2017年 E33QU5QCP3.com.xnmiao.customer.XMNiao-Customer. All rights reserved.
//

#import "PVideoPlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface PVideoPlayer()
@property (nonatomic ,strong) AVPlayer *player;
@end

@implementation PVideoPlayer
{
    UIView *_ctrlView;
    CALayer *_playStatus;
    
    BOOL _isPlaying;
}

- (instancetype)initWithFrame:(CGRect)frame videoUrl:(NSURL *)videoUrl
{
    if (self = [super initWithFrame:frame])
    {
        _autoReplay = YES;
        _videoUrl = videoUrl;
        [self setupSubViews];
    }
    return self;
}

- (void)play
{
    if (_isPlaying)
    {
        return;
    }
    [self tapAction];
}

- (void)stop
{
    if (_isPlaying)
    {
        [self tapAction];
    }
}


- (void)setupSubViews
{
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:_videoUrl];
    self.player = [AVPlayer playerWithPlayerItem:playerItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    playerLayer.frame = self.bounds;
    playerLayer.videoGravity = AVLayerVideoGravityResize;
    [self.layer addSublayer:playerLayer];
    
    _ctrlView = [[UIView alloc] initWithFrame:self.bounds];
    _ctrlView.backgroundColor = [UIColor clearColor];
    [self addSubview:_ctrlView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
    [_ctrlView addGestureRecognizer:tap];
    [self setupStatusView];
    [self tapAction];
}

- (void)setupStatusView
{
    CGPoint selfCent = CGPointMake(self.bounds.size.width/2+10, self.bounds.size.height/2);
    CGFloat width = 40;
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, nil, selfCent.x - width/2, selfCent.y - width/2);
    CGPathAddLineToPoint(path, nil, selfCent.x - width/2, selfCent.y + width/2);
    CGPathAddLineToPoint(path, nil, selfCent.x + width/2 - 4, selfCent.y);
    CGPathAddLineToPoint(path, nil, selfCent.x - width/2, selfCent.y - width/2);
    
    CGColorRef color = [UIColor colorWithRed: 1.0 green: 1.0 blue: 1.0 alpha: 0.5].CGColor;
    
    CAShapeLayer *trackLayer = [CAShapeLayer layer];
    trackLayer.frame = self.bounds;
    trackLayer.strokeColor = [UIColor clearColor].CGColor;
    trackLayer.fillColor = color;
    trackLayer.opacity = 1.0;
    trackLayer.lineCap = kCALineCapRound;
    trackLayer.lineWidth = 1.0;
    trackLayer.path = path;
    [_ctrlView.layer addSublayer:trackLayer];
    _playStatus = trackLayer;
    
    CGPathRelease(path);
}

- (void)tapAction
{
    if (_isPlaying)
    {
        [self.player pause];
    }
    else
    {
        [self.player play];
    }
    _isPlaying = !_isPlaying;
    _playStatus.hidden = !_playStatus.hidden;
}

- (void)playEnd
{
    
    if (!_autoReplay)
    {
        return;
    }
    [self.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        [self.player play];
    }];
}

- (void)removeFromSuperview
{
    [self.player.currentItem cancelPendingSeeks];
    [self.player.currentItem.asset cancelLoading];
    [[NSNotificationCenter defaultCenter] removeObserver:self ];
    [super removeFromSuperview];
}

@end

