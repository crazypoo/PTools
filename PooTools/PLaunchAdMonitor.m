//
//  PLaunchAdMonitor.m
//  adasdasdadadasdasdadadadad
//
//  Created by MYX on 2017/4/6.
//  Copyright © 2017年 邓杰豪. All rights reserved.
//

#import "PLaunchAdMonitor.h"
#import <ImageIO/ImageIO.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVKit/AVKit.h>
#import "PMacros.h"
#import "Utils.h"

NSString *PLaunchAdDetailDisplayNotification = @"PShowLaunchAdDetailNotification";

static PLaunchAdMonitor *monitor = nil;

@interface PLaunchAdMonitor()<NSURLConnectionDataDelegate, NSURLConnectionDelegate>

@property (nonatomic, assign) BOOL imgLoaded;
@property (nonatomic, strong) NSMutableData *imgData;
@property (nonatomic, strong) NSURLConnection *conn;
@property (nonatomic, strong) NSMutableDictionary *detailParam;
@property (nonatomic, copy) void(^callback)(void);
@property (nonatomic, strong) NSString *imageType;
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
    UIView *v = [[UIView alloc] initWithFrame:f];
    v.backgroundColor = [UIColor lightGrayColor];
    
    f.size.height -= 50;
    
    CGFloat bottomViewHeight = 0;
    
    if (hide) {
        bottomViewHeight = 0;
    }
    else
    {
        bottomViewHeight = 100;
    }
    
    if (monitor.playMovie) {
        [container addSubview:v];
        [container bringSubviewToFront:v];

        monitor.player = [[MPMoviePlayerController alloc] initWithContentURL:monitor.videoUrl];
        monitor.player.controlStyle = MPMovieControlStyleNone;
        monitor.player.shouldAutoplay = YES;
        monitor.player.repeatMode = MPMovieRepeatModeOne;
        [monitor.player setFullscreen:YES animated:YES];
        monitor.player.scalingMode = MPMovieScalingModeAspectFit;
        [monitor.player prepareToPlay];
        [monitor.player.view setFrame:CGRectMake(0, 0, f.size.width, [UIScreen mainScreen].bounds.size.height-bottomViewHeight)];
        [v addSubview: monitor.player.view];
        [monitor.player play];

        UIButton *imageBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        imageBtn.frame = CGRectMake(0, 0, f.size.width, [UIScreen mainScreen].bounds.size.height-bottomViewHeight);
        [imageBtn addTarget:self action:@selector(showAdDetail:) forControlEvents:UIControlEventTouchUpInside];
        imageBtn.userInteractionEnabled = yesOrNo;
        [v addSubview:imageBtn];

        UIButton *exit = [UIButton buttonWithType:UIButtonTypeCustom];
        exit.frame = CGRectMake(f.size.width-55, kScreenStatusBottom, 45, 35);
        exit.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2];
        [exit setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        exit.titleLabel.font = sbFont;
        [exit setTitle:@"跳过" forState:UIControlStateNormal];
        [exit addTarget:self action:@selector(hideView:) forControlEvents:UIControlEventTouchUpInside];
        kViewBorderRadius(exit, 5, 0, [UIColor clearColor]);
        [v addSubview:exit];
    }
    else
    {
        if ([monitor.imageType isEqualToString:@"gif"]) {
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
            
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, f.size.width, [UIScreen mainScreen].bounds.size.height-bottomViewHeight)];
            imageView.animationImages = frames;
            imageView.animationDuration = 1;
            [imageView startAnimating];
            [v addSubview:imageView];
            
            UIGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showAdDetail:)];
            [imageView addGestureRecognizer:tapGesture];
        }
        else
        {
            UIButton *imageBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            imageBtn.frame = CGRectMake(0, 0, f.size.width, [UIScreen mainScreen].bounds.size.height-bottomViewHeight);
            [imageBtn setBackgroundImage:[UIImage imageWithData:monitor.imgData] forState:UIControlStateNormal];
            imageBtn.imageView.contentMode = UIViewContentModeScaleToFill;
            [imageBtn setAdjustsImageWhenHighlighted:NO];
            [imageBtn addTarget:self action:@selector(showAdDetail:) forControlEvents:UIControlEventTouchUpInside];
            monitor.conn = nil;
            [monitor.imgData setLength:0];
            imageBtn.userInteractionEnabled = yesOrNo;
            [v addSubview:imageBtn];
        }
        
        UIButton *exit = [UIButton buttonWithType:UIButtonTypeCustom];
        exit.frame = CGRectMake(f.size.width-65, 24, 55, 55);
        exit.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2];
        [exit setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [exit addTarget:self action:@selector(hideView:) forControlEvents:UIControlEventTouchUpInside];
        exit.layer.cornerRadius = exit.frame.size.width/2;
        exit.layer.masksToBounds = YES;
        exit.titleLabel.textAlignment = NSTextAlignmentCenter;
        exit.titleLabel.numberOfLines = 0;
        exit.titleLabel.lineBreakMode = NSLineBreakByCharWrapping;
        exit.titleLabel.font = sbFont;
        [v addSubview:exit];
        
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
        [container addSubview:v];
        [container bringSubviewToFront:v];
    }
    
    
    if (!hide) {
        
        UIFont *cfont;
        if (cFont == nil) {
            cfont = [UIFont systemFontOfSize:12];
        }
        else
        {
            cfont = cFont;
        }
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height-bottomViewHeight, f.size.width, bottomViewHeight)];
        label.backgroundColor = [UIColor whiteColor];
        label.font = cfont;
        label.text = [NSString stringWithFormat:@"Copyright (c) %@年 %@. All rights reserved.",year,comname];
        label.textAlignment = NSTextAlignmentCenter;
        [v addSubview:label];
        label = nil;
    }
}

+(void)hideView:(id)sender
{
    UIView *sup = [(UIButton *)sender superview];
    sup.userInteractionEnabled = NO;
    if (monitor.callback) {
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
    if ([monitor.imageType isEqualToString:@"gif"]) {
        sup = [(UIImageView *)sender superview];
    }
    else
    {
        sup = [(UIButton *)sender superview];
    }
    
    sup.userInteractionEnabled = NO;
    if (monitor.callback) {
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
        NSString* pathExtention = [imageStr pathExtension];
        if([pathExtention isEqualToString:@"mp4"]) {
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
    self.imageType = [self contentTypeForImageData:data];
    [self.imgData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.imgLoaded = YES;
}

#pragma mark ---------------> SwitchImageType
- (NSString *)contentTypeForImageData:(NSData *)data {
    
    uint8_t c;
    
    [data getBytes:&c length:1];
    
    switch (c) {
            
        case 0xFF:
        {
            return @"jpeg";
        }
        case 0x89:
        {
            return @"png";
        }
        case 0x47:
        {
            return @"gif";
        }
        case 0x49:
        case 0x4D:
        {
            return @"tiff";
        }
        case 0x52:
        {
            if ([data length] < 12) {
                return nil;
            }
            
            NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
            
            if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"])
            {
                return @"webp";
            }
            return nil;
        }
    }
    return nil;
}

@end

