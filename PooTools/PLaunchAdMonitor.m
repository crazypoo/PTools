//
//  PLaunchAdMonitor.m
//  adasdasdadadasdasdadadadad
//
//  Created by MYX on 2017/4/6.
//  Copyright © 2017年 邓杰豪. All rights reserved.
//

#import "PLaunchAdMonitor.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVKit/AVKit.h>
#import "PMacros.h"
#import "Utils.h"
#import <Masonry/Masonry.h>

NSString *PLaunchAdDetailDisplayNotification = @"PShowLaunchAdDetailNotification";

static PLaunchAdMonitor *monitor = nil;

@interface PLaunchAdMonitor()<NSURLConnectionDataDelegate, NSURLConnectionDelegate>

@property (nonatomic, assign) BOOL imgLoaded;
@property (nonatomic, strong) NSMutableData *imgData;
@property (nonatomic, strong) NSURLConnection *conn;
@property (nonatomic, strong) NSMutableDictionary *detailParam;
@property (nonatomic, copy) void(^callback)(void);
@property (nonatomic, assign) ToolsAboutImageType imageType;
@property (nonatomic, assign) BOOL playMovie;
@property (nonatomic, strong) NSURL *videoUrl;
@property (nonatomic, strong) MPMoviePlayerController *player;
@end


@implementation PLaunchAdMonitor

+ (void)showAdAtPath:(NSArray *)path onView:(UIView *)container timeInterval:(NSTimeInterval)interval detailParameters:(NSDictionary *)param years:(NSString *)year skipButtonFont:(UIFont *)sbFont comName:(nullable NSString *)comname comNameFont:(UIFont *)cFont callback:(void (^ _Nullable)(void))callback
{
    [[self defaultMonitor] loadImageAtPath:path];
    while (!monitor.imgLoaded)
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    monitor.detailParam = [[NSMutableDictionary alloc] init];
    [monitor.detailParam removeAllObjects];
    [monitor.detailParam addEntriesFromDictionary:param];
    
    BOOL dic;
    if (param == nil) {
        dic = NO;
    }
    else
    {
        dic = YES;
    }
    monitor.callback = callback;
    
    BOOL comLabel;
    if (year == nil || comname == nil) {
        comLabel = YES;
    }
    else
    {
        comLabel = NO;
    }
    
    [self showImageOnView:container forTime:interval years:year comName:comname dic:dic comLabel:comLabel skipButtonFont:sbFont comNameFont:cFont];
}

+ (instancetype)defaultMonitor
{
    @synchronized (self) {
        if (!monitor) {
            monitor = [[PLaunchAdMonitor alloc] init];
        }
        return monitor;
    }
}

+ (BOOL)validatePath:(NSString *)path
{
    NSURL *url = [NSURL URLWithString:path];
    return url != nil;
}

+ (void)showImageOnView:(UIView *)container forTime:(NSTimeInterval)time years:(NSString *)year comName:(NSString *)comname dic:(BOOL)yesOrNo comLabel:(BOOL)hide skipButtonFont:(UIFont *)sbFont comNameFont:(UIFont *)cFont
{
    CGRect f = [UIScreen mainScreen].bounds;
    UIView *v = [UIView new];
    v.backgroundColor = [UIColor lightGrayColor];
    [container addSubview:v];
    [container bringSubviewToFront:v];
    [v mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(container);
    }];
    
    f.size.height -= 50;
    
    UIDevice *device = [UIDevice currentDevice];
    
    CGFloat bottomViewHeight = 0;
    if (hide)
    {
        bottomViewHeight = 0;
    }
    else
    {
        switch (device.orientation)
        {
            case UIDeviceOrientationLandscapeLeft:
            {
                bottomViewHeight = 50;
            }
                break;
            case UIDeviceOrientationLandscapeRight:
            {
                bottomViewHeight = 50;
            }
                break;
            default:
            {
                bottomViewHeight = 100;
            }
                break;
        }
    }
    
    if (monitor.playMovie)
    {
        monitor.player = [[MPMoviePlayerController alloc] initWithContentURL:monitor.videoUrl];
        monitor.player.controlStyle = MPMovieControlStyleNone;
        monitor.player.shouldAutoplay = YES;
        monitor.player.repeatMode = MPMovieRepeatModeOne;
        [monitor.player setFullscreen:YES animated:YES];
        monitor.player.scalingMode = MPMovieScalingModeAspectFit;
        [monitor.player prepareToPlay];
        [v addSubview: monitor.player.view];
        [monitor.player.view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(v);
            make.height.offset(bottomViewHeight);
        }];
        [monitor.player play];

        UIButton *imageBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [imageBtn addTarget:self action:@selector(showAdDetail:) forControlEvents:UIControlEventTouchUpInside];
        imageBtn.userInteractionEnabled = yesOrNo;
        [v addSubview:imageBtn];
        [imageBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.bottom.equalTo(monitor.player.view);
        }];

        UIButton *exit = [UIButton buttonWithType:UIButtonTypeCustom];
        exit.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2];
        [exit setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        exit.titleLabel.font = sbFont;
        [exit setTitle:@"跳过" forState:UIControlStateNormal];
        [exit addTarget:self action:@selector(hideView:) forControlEvents:UIControlEventTouchUpInside];
        kViewBorderRadius(exit, 5, 0, [UIColor clearColor]);
        [v addSubview:exit];
        [exit mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(v).offset(-10);
            make.top.equalTo(v).offset(kScreenStatusBottom);
            make.width.offset(sbFont.pointSize*exit.titleLabel.text.length+10*2);
            make.height.offset(sbFont.pointSize*exit.titleLabel.text.length+5*2);
        }];
    }
    else
    {
        switch (monitor.imageType)
        {
            case ToolsAboutImageTypeGIF:
            {
                CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)monitor.imgData, NULL);
                size_t frameCout = CGImageSourceGetCount(source);
                NSMutableArray* frames = [[NSMutableArray alloc] init];
                for (size_t i=0; i<frameCout; i++)
                {
                    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, i, NULL);
                    UIImage* imageName = [UIImage imageWithCGImage:imageRef];
                    [frames addObject:imageName];
                    CGImageRelease(imageRef);
                }
                
                UIImageView *imageView = [UIImageView new];
                imageView.animationImages = frames;
                imageView.animationDuration = 1;
                [imageView startAnimating];
                [v addSubview:imageView];
                [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.top.left.right.equalTo(v);
                    make.height.offset(bottomViewHeight);
                }];
                
                UIGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showAdDetail:)];
                [imageView addGestureRecognizer:tapGesture];
                //FIX:没有释放
                CFRelease(source);
            }
                break;
            default:
            {
                UIButton *imageBtn = [UIButton buttonWithType:UIButtonTypeCustom];
                [imageBtn setBackgroundImage:[UIImage imageWithData:monitor.imgData] forState:UIControlStateNormal];
                [imageBtn addTarget:self action:@selector(showAdDetail:) forControlEvents:UIControlEventTouchUpInside];
                monitor.conn = nil;
                [monitor.imgData setLength:0];
                imageBtn.userInteractionEnabled = yesOrNo;
                [v addSubview:imageBtn];
                [imageBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.top.left.right.equalTo(v);
                    make.bottom.equalTo(v).offset(-bottomViewHeight);
                }];
                imageBtn.imageView.contentMode = UIViewContentModeScaleToFill;
                [imageBtn setAdjustsImageWhenHighlighted:NO];
            }
                break;
        }
        
        UIButton *exit = [UIButton buttonWithType:UIButtonTypeCustom];
        exit.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2];
        [exit setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [exit addTarget:self action:@selector(hideView:) forControlEvents:UIControlEventTouchUpInside];
        exit.titleLabel.textAlignment = NSTextAlignmentCenter;
        exit.titleLabel.numberOfLines = 0;
        exit.titleLabel.lineBreakMode = NSLineBreakByCharWrapping;
        exit.titleLabel.font = sbFont;
        [v addSubview:exit];
        [exit mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(v).offset(-10);
            make.top.equalTo(v).offset(kScreenStatusBottom);
            make.width.height.offset(55);
        }];
        kViewBorderRadius(exit, 55/2, 0, kClearColor);
        
        __block int timeout = time;
        dispatch_queue_t queue   = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_source_t _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
        dispatch_source_set_timer(_timer,dispatch_walltime(NULL, 0),1.0*NSEC_PER_SEC, 0);
        dispatch_source_set_event_handler(_timer, ^{
            if(timeout <= 0){
                dispatch_source_cancel(_timer);
                dispatch_async(dispatch_get_main_queue(), ^{
                });
            }
            else
            {
                NSString *strTime = [NSString stringWithFormat:@"%.2d",timeout];
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *buttonTime          = [NSString stringWithFormat:@"跳过\n%@s",strTime];
                    [exit setTitle:buttonTime forState:UIControlStateNormal];
                });
                timeout--;
            }
        });
        dispatch_resume(_timer);

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            v.userInteractionEnabled = NO;
            if (monitor.callback) {
                monitor.callback();
                monitor.callback = nil;
            }
            [UIView animateWithDuration:.25
                             animations:^{
                                 v.alpha = 0.0f;
                             }
                             completion:^(BOOL finished) {
                                 [v removeFromSuperview];
                             }];
        });
    }
    
    if (!hide)
    {
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor whiteColor];
        label.font = cFont ? cFont : [UIFont fontWithName:@"HelveticaNeue-Light" size:12];
        label.text = [NSString stringWithFormat:@"Copyright (c) %@年 %@. All rights reserved.",year,comname];
        label.textAlignment = NSTextAlignmentCenter;
        [v addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(v);
            make.height.offset(bottomViewHeight);
            make.bottom.equalTo(v);
        }];
        label = nil;
    }
}

+(void)hideView:(id)sender
{
    UIView *sup = [(UIButton *)sender superview];
    sup.userInteractionEnabled = NO;
    if (monitor.callback)
    {
        monitor.callback();
        monitor.callback = nil;
    }
    [UIView animateWithDuration:.25
                     animations:^{
                         sup.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         [sup removeFromSuperview];
                     }];
}

+ (void)showAdDetail:(id)sender
{
    UIView *sup = nil;
    switch (monitor.imageType)
    {
        case ToolsAboutImageTypeGIF:
        {
            sup = [(UIImageView *)sender superview];
        }
            break;
        default:
        {
            sup = [(UIButton *)sender superview];
        }
            break;
    }
    
    sup.userInteractionEnabled = NO;
    if (monitor.callback)
    {
        monitor.callback();
        monitor.callback = nil;
    }
    [UIView animateWithDuration:.25
                     animations:^{
                         sup.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         [sup removeFromSuperview];
                         [[NSNotificationCenter defaultCenter] postNotificationName:PLaunchAdDetailDisplayNotification object:monitor.detailParam];
                         [monitor.detailParam removeAllObjects];
                     }];
}

- (void)loadImageAtPath:(NSArray *)path
{
    NSString *imageStr = [path objectAtIndex:0];
    if (imageStr) {
        if([Utils contentTypeForUrlString:imageStr] == ToolsUrlStringVideoTypeMP4)
        {
            self.playMovie = YES;
            self.imgLoaded = YES;
            if ([imageStr rangeOfString:@"/var"].length>0)
            {
                self.videoUrl = [NSURL fileURLWithPath:imageStr];
            }
            else
            {
                self.videoUrl = [NSURL URLWithString:[imageStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            }
        }
        else
        {
            self.playMovie = NO;

            if ([imageStr isKindOfClass:[NSString class]]) {
                NSURL *URL = [NSURL URLWithString:imageStr];
                NSURLRequest *request = [NSURLRequest requestWithURL:URL];
                self.conn = [NSURLConnection connectionWithRequest:request delegate:self];
                if (self.conn) {
                    [self.conn start];
                }
            }else if([imageStr isKindOfClass:[NSURL class]]){
                NSURL *URL = [NSURL URLWithString:imageStr];
                NSURLRequest *request = [NSURLRequest requestWithURL:URL];
                self.conn = [NSURLConnection connectionWithRequest:request delegate:self];
                if (self.conn) {
                    [self.conn start];
                }
            }
            else if([imageStr isKindOfClass:[UIImage class]]){
                self.imgData = [NSMutableData data];
                [self.imgData appendData:UIImagePNGRepresentation((UIImage*)imageStr)];
                self.imgLoaded = YES;
            }
        }
    }
    
}

#pragma mark - NSURLConnectionDataDelegate method
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
    if (resp.statusCode != 200) {
        self.imgLoaded = YES;
        return ;
    }
    self.imgData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    self.imageType = [Utils contentTypeForImageData:data];
    [self.imgData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.imgLoaded = YES;
}
@end

