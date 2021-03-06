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
#import <Masonry/Masonry.h>

NSString *PLaunchAdDetailDisplayNotification = @"PShowLaunchAdDetailNotification";

static PLaunchAdMonitor *monitor = nil;

@interface PLaunchAdMonitor()

@property (nonatomic, assign) BOOL imgLoaded;
@property (nonatomic, strong) NSMutableData *imgData;
@property (nonatomic, strong) NSMutableDictionary *detailParam;
@property (nonatomic, copy) void(^callback)(void);
@property (nonatomic, assign) ToolsAboutImageType imageType;
@property (nonatomic, assign) BOOL playMovie;
@property (nonatomic, strong) NSURL *videoUrl;
@property (nonatomic, strong)AVPlayerViewController *player;
@end


@implementation PLaunchAdMonitor

+ (void)showAdAtPath:(nonnull NSArray *)path
              onView:(nonnull id)container
        timeInterval:(NSTimeInterval)interval
    detailParameters:(nullable NSDictionary *)param
               years:(nullable NSString *)year
      skipButtonFont:(nullable UIFont *)sbFont
             comName:(nullable NSString * )comname
         comNameFont:(nullable UIFont *)cFont
            callback:(void(^_Nullable)(void))callback
{
    [[self defaultMonitor] loadImageAtPath:path];
    while (!monitor.imgLoaded)
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    monitor.detailParam = [[NSMutableDictionary alloc] init];
    [monitor.detailParam removeAllObjects];
    [monitor.detailParam addEntriesFromDictionary:param];
    
    BOOL dic = (param == nil) ? NO : YES;
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
    @synchronized (self)
    {
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

+ (void)showImageOnView:(id)container forTime:(NSTimeInterval)time years:(NSString *)year comName:(NSString *)comname dic:(BOOL)yesOrNo comLabel:(BOOL)hide skipButtonFont:(UIFont *)sbFont comNameFont:(UIFont *)cFont
{
    CGRect f = [UIScreen mainScreen].bounds;
    UIView *v = [UIView new];
    v.backgroundColor = [UIColor lightGrayColor];
    
    if ([container isKindOfClass:[UIView class]])
    {
        
        [(UIView *)container addSubview:v];
        [(UIView *)container bringSubviewToFront:v];
        [v mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.bottom.equalTo((UIView *)container);
        }];
    }
    else if ([container isKindOfClass:[UIWindow class]])
    {
        [(UIWindow *)container addSubview:v];
        [(UIWindow *)container bringSubviewToFront:v];
        [v mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.bottom.equalTo((UIWindow *)container);
        }];
    }
    
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
    
    UIFont *newFont;

    if (IS_IPAD)
    {
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        switch (orientation) {
            case UIInterfaceOrientationLandscapeLeft:
            {
                newFont = sbFont ? kDEFAULT_FONT(sbFont.familyName, sbFont.pointSize/2.5) : kDEFAULT_FONT(kDevLikeFont, 16);
            }
                break;
            case UIInterfaceOrientationLandscapeRight:
            {
                newFont = sbFont ? kDEFAULT_FONT(sbFont.familyName, sbFont.pointSize/2.5) : kDEFAULT_FONT(kDevLikeFont, 16);
            }
                break;
            default:
            {
                newFont = sbFont ? sbFont : kDEFAULT_FONT(kDevLikeFont, 16);
            }
                break;
        }
    }
    else
    {
        switch (device.orientation) {
            case UIDeviceOrientationLandscapeLeft:
            {
                newFont = sbFont ? kDEFAULT_FONT(sbFont.familyName, sbFont.pointSize/2) : kDEFAULT_FONT(kDevLikeFont, 16);
            }
                break;
            case UIDeviceOrientationLandscapeRight:
            {
                newFont = sbFont ? kDEFAULT_FONT(sbFont.familyName, sbFont.pointSize/2) : kDEFAULT_FONT(kDevLikeFont, 16);
            }
                break;
            default:
            {
                newFont = sbFont ? sbFont : kDEFAULT_FONT(kDevLikeFont, 16);
            }
                break;
        }

    }
    
    if (monitor.playMovie)
    {
//        [kNotificationCenter addObserver:self selector:@selector(playerItemDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:v];

        monitor.player = [[AVPlayerViewController alloc] init];
        monitor.player.player = [AVPlayer playerWithURL:monitor.videoUrl];
        monitor.player.showsPlaybackControls = NO;
        if (@available(iOS 11.0, *)) {
            monitor.player.entersFullScreenWhenPlaybackBegins = YES;
        } else {
            // Fallback on earlier versions
        }
        [v addSubview:monitor.player.view];
        [monitor.player.view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(v);
            make.bottom.equalTo(v).offset(-bottomViewHeight);
        }];
        [monitor.player.player play];

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
        exit.titleLabel.font = newFont;
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
                [imageBtn setImage:[UIImage imageWithData:monitor.imgData] forState:UIControlStateNormal];
                [imageBtn addTarget:self action:@selector(showAdDetail:) forControlEvents:UIControlEventTouchUpInside];
                [monitor.imgData setLength:0];
                imageBtn.userInteractionEnabled = yesOrNo;
                [v addSubview:imageBtn];
                [imageBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.top.left.right.equalTo(v);
                    make.bottom.equalTo(v).offset(-bottomViewHeight);
                }];
                imageBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
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
        exit.titleLabel.font = newFont;
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
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByCharWrapping;
        label.font = cFont ? cFont : kDEFAULT_FONT(kDevLikeFont, 12);
        label.textColor = [UIColor blackColor];
        label.text = [NSString stringWithFormat:@"Copyright (c) %@年 %@.\n All rights reserved.",year,comname];
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
                         [monitor.player.player pause];
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
                         [monitor.player.player pause];
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
            self.videoUrl = ([imageStr rangeOfString:@"/var"].length>0) ? [NSURL fileURLWithPath:imageStr] : [NSURL URLWithString:[imageStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
        }
        else
        {
            self.playMovie = NO;

            if ([imageStr isKindOfClass:[NSString class]])
            {
                [self loadImage:imageStr];
            }
            else if([imageStr isKindOfClass:[NSURL class]])
            {
                [self loadImage:[(NSURL *)imageStr description]];
            }
            else if([imageStr isKindOfClass:[UIImage class]]){
                self.imgData = [NSMutableData data];
                [self.imgData appendData:UIImagePNGRepresentation((UIImage*)imageStr)];
                self.imgLoaded = YES;
            }
        }
    }
}

-(void)loadImage:(NSString *)imageStr
{
    NSURL *URL = [NSURL URLWithString:imageStr];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
        if (resp.statusCode != 200) {
            self.imgLoaded = YES;
            return ;
        }
        self.imgData = [NSMutableData data];
        self.imageType = [Utils contentTypeForImageData:data];
        [self.imgData appendData:data];
        self.imgLoaded = YES;
    }];
    [dataTask resume];
}

//- (void)playerItemDidPlayToEnd:(NSNotification *)notification
//{
//
//}
@end

