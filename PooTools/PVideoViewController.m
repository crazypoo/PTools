//
//  PVideoViewController.m
//  XMNaio_Client
//
//  Created by MYX on 2017/5/16.
//  Copyright © 2017年 E33QU5QCP3.com.xnmiao.customer.XMNiao-Customer. All rights reserved.
//

#import "PVideoViewController.h"
#import "PVideoListViewController.h"

#import "PVideoSupport.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import <Masonry/Masonry.h>
#import "UIView+LayoutSubviewsCallback.h"

@interface PVideoViewController()<PControllerBarDelegate,AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate> {
    
    AVCaptureDevice *_videoDevice;
    
    AVCaptureVideoDataOutput *_videoDataOut;
    AVCaptureAudioDataOutput *_audioDataOut;
    
    AVAssetWriterInputPixelBufferAdaptor *_assetWriterPixelBufferInput;
    AVAssetWriterInput *_assetWriterVideoInput;
    AVAssetWriterInput *_assetWriterAudioInput;
    CMTime _currentSampleTime;
    BOOL _recoding;
    
    dispatch_queue_t _recoding_queue;
    //      dispatch_queue_create("com.video.queue", DISPATCH_QUEUE_SERIAL)
    
    CGFloat customVideoWidthPX;
    
    
}
@property (nonatomic, assign) BOOL currentRecordIsCancel;
@property (nonatomic, assign) PVideoViewShowType showType;
@property (nonatomic, assign) CGFloat customVideo_W_H;
@property (nonatomic, assign) CGFloat customControViewHeight;
@property (nonatomic, strong) PVideoModel *currentRecord;
@property (nonatomic, strong) UIView *eyeView;
@property (nonatomic, strong) UIView *videoView;
@property (nonatomic, strong) UILabel *cancelInfo;
@property (nonatomic, strong) UILabel *statusInfo;
@property (nonatomic, strong) PFocusView *focusView;
@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreLayer;
@property (nonatomic, strong) PStatusBar *topSlideView;
@property (nonatomic, strong) PControllerBar *ctrlBar;
@property (nonatomic, assign) NSTimeInterval customRecordTime;
@property (nonatomic, strong) AVCaptureSession *videoSession;
@property (nonatomic, strong) UIWindow *keyWindow;
@end

static PVideoViewController *__currentVideoVC = nil;

@implementation PVideoViewController

-(instancetype)initWithRecordTime:(NSTimeInterval)recordTime video_W_H:(CGFloat)video_W_H withVideoWidthPX:(CGFloat)videoWidthPX withControViewHeight:(CGFloat)controViewHeight
{
    self = [super init];
    if (self) {
        self.customRecordTime = recordTime ? recordTime : 20;
        self.customVideo_W_H = video_W_H ? video_W_H : (4.0/3);
        customVideoWidthPX = videoWidthPX ? videoWidthPX :200;
        self.customControViewHeight = controViewHeight ? controViewHeight : 120;
    }
    return self;
}

- (void)startAnimationWithType:(PVideoViewShowType)showType
{
    self.showType = showType;
    __currentVideoVC = self;
    
    [self setupSubViews];
    self.view.hidden = YES;
    BOOL videoExist = [PVideoUtil existVideo];
    self.keyWindow = [UIApplication sharedApplication].delegate.window;
    [self.keyWindow addSubview:self.view];
    [self.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(self.keyWindow);
    }];
    if (self.showType == PVideoViewShowTypeSingle && videoExist) {
        
        [self ctrollVideoOpenVideoList:nil];
        kz_dispatch_after(0.4, ^{
            self.view.hidden = NO;
        });
        
    }
    else {
        self.view.hidden = NO;
        self.actionView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, CGRectGetHeight([PVideoConfig viewFrameWithType:showType video_W_H:self.customVideo_W_H withControViewHeight:self.customControViewHeight]));
        [UIView animateWithDuration:0.3 delay:0.1 options:UIViewAnimationOptionCurveLinear animations:^{
            self.actionView.transform = CGAffineTransformIdentity;
            self.view.backgroundColor = [UIColor colorWithRed: 0.0 green: 0.0 blue: 0.0 alpha: 0.4];
        } completion:^(BOOL finished) {
            [self viewDidAppear];
        }];
    }
    [self setupVideo];
}

- (void)endAniamtion {
    [UIView animateWithDuration:0.3 animations:^{
        self.view.backgroundColor = [UIColor clearColor];
        self.actionView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, CGRectGetHeight([PVideoConfig viewFrameWithType:self.showType video_W_H:self.customVideo_W_H withControViewHeight:self.customControViewHeight]));
    } completion:^(BOOL finished) {
        [self closeView];
    }];
}

- (void)closeView {
    [self.videoSession stopRunning];
    [self.videoPreLayer removeFromSuperlayer];
    self.videoPreLayer = nil;
    [self.videoView removeFromSuperview];
    self.videoView = nil;
    
    _videoDevice = nil;
    _videoDataOut = nil;
    _assetWriter = nil;
    _assetWriterAudioInput = nil;
    _assetWriterVideoInput = nil;
    _assetWriterPixelBufferInput = nil;
    [self.view removeFromSuperview];
    __currentVideoVC = nil;
}

- (void)setupSubViews {
    _view = [UIView new];
    self.view.backgroundColor = [UIColor clearColor];
    
    UIPanGestureRecognizer *ges = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveTopBarAction:)];
    [self.view addGestureRecognizer:ges];
    
    CGRect actionRect = [PVideoConfig viewFrameWithType:self.showType video_W_H:self.customVideo_W_H withControViewHeight:self.customControViewHeight];
    
    _actionView = [UIView new];
    [self.view addSubview:_actionView];
    _actionView.backgroundColor = kThemeBlackColor;
    _actionView.clipsToBounds = YES;
    [_actionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(actionRect.origin.x);
        make.top.equalTo(self.view).offset(actionRect.origin.y);
        make.height.offset(actionRect.size.height);
        make.width.offset(actionRect.size.width);
    }];
    
    BOOL isSmallStyle = self.showType == PVideoViewShowTypeSmall;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CGSize videoViewSize = [PVideoConfig videoViewDefaultSizeWithVideo_W_H:self.customVideo_W_H];
        CGFloat topHeight = isSmallStyle ? 20.0 : 64.0;
        
        CGFloat allHeight = self.actionView.frame.size.height;
        
        CGFloat buttomHeight =  isSmallStyle ? self.customControViewHeight : allHeight - topHeight - videoViewSize.height;
        
        self.topSlideView = [[PStatusBar alloc] initWithFrame:CGRectZero style:self.showType];
        if (!isSmallStyle) {
            [self.topSlideView addCancelTarget:self selector:@selector(endAniamtion)];
        }
        [self.actionView addSubview:self.topSlideView];
        [self.topSlideView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(self.actionView);
            make.height.offset(topHeight);
        }];
        
        self.ctrlBar = [PControllerBar new];
        [self.ctrlBar setupSubViewsWithStyle:self.showType recordTime:self.customRecordTime];
        self.ctrlBar.delegate = self;
        [self.actionView addSubview:self.ctrlBar];
        [self.ctrlBar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.actionView);
            make.bottom.equalTo(self.actionView);
            make.height.offset(buttomHeight);
        }];
        
        self.videoView = [UIView new];
        [self.actionView addSubview:self.videoView];
        [self.videoView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.actionView);
            make.top.equalTo(self.topSlideView.mas_bottom);
            make.width.offset(videoViewSize.width);
            make.height.offset(videoViewSize.height);
            
        }];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusAction:)];
        tapGesture.delaysTouchesBegan = YES;
        [self.videoView addGestureRecognizer:tapGesture];
        
        UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(zoomVideo:)];
        doubleTapGesture.numberOfTapsRequired = 2;
        doubleTapGesture.numberOfTouchesRequired = 1;
        doubleTapGesture.delaysTouchesBegan = YES;
        [self.videoView addGestureRecognizer:doubleTapGesture];
        [tapGesture requireGestureRecognizerToFail:doubleTapGesture];
        
        
        self.focusView = [[PFocusView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        self.focusView.backgroundColor = [UIColor clearColor];
        
        self.statusInfo = [UILabel new];
        self.statusInfo.textAlignment = NSTextAlignmentCenter;
        self.statusInfo.font = [UIFont systemFontOfSize:14.0];
        self.statusInfo.textColor = [UIColor whiteColor];
        self.statusInfo.hidden = NO;
        [self.actionView addSubview:self.statusInfo];
        [self.statusInfo mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.videoView);
            make.height.offset(20);
            make.bottom.equalTo(self.videoView.mas_bottom).offset(-30);
        }];
        
        self.cancelInfo = [UILabel new];
        self.cancelInfo.textAlignment = NSTextAlignmentCenter;
        self.cancelInfo.textColor = kThemeWhiteColor;
        self.cancelInfo.backgroundColor = kThemeWaringColor;
        self.cancelInfo.hidden = YES;
        [self.actionView addSubview:self.cancelInfo];
        [self.cancelInfo mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.offset(120);
            make.height.offset(24);
            make.centerX.centerY.equalTo(self.videoView);
        }];
        
        [self.actionView sendSubviewToBack:self.videoView];

    });
}

- (void)setupVideo {
    NSString *unUseInfo = nil;
    if (TARGET_IPHONE_SIMULATOR) {
        unUseInfo = @"模拟器不可以的..";
    }
    
    __block NSString *bUnUseInfo = unUseInfo;
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (!granted) {
            bUnUseInfo = @"相机访问受限...";
        }
    }];
    
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
        if (!granted) {
            bUnUseInfo = @"录音访问受限...";
        }
    }];
    
    unUseInfo = bUnUseInfo;
    
    if (unUseInfo != nil) {
        self.statusInfo.text = unUseInfo;
        self.statusInfo.hidden = NO;
        self.eyeView = [PEyeView new];
        [self.videoView addSubview:self.eyeView];
        [self.eyeView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.bottom.equalTo(self.videoView);
        }];
        return;
    }
    
    _recoding_queue = dispatch_queue_create("com.littlevideo.queue", DISPATCH_QUEUE_SERIAL);
    
    NSArray *devicesVideo = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    NSArray *devicesAudio = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:devicesVideo[0] error:nil];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:devicesAudio[0] error:nil];
    
    _videoDevice = devicesVideo[0];
    
    _videoDataOut = [[AVCaptureVideoDataOutput alloc] init];
    _videoDataOut.videoSettings = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
    _videoDataOut.alwaysDiscardsLateVideoFrames = YES;
    [_videoDataOut setSampleBufferDelegate:self queue:_recoding_queue];
    
    _audioDataOut = [[AVCaptureAudioDataOutput alloc] init];
    [_audioDataOut setSampleBufferDelegate:self queue:_recoding_queue];
    
    self.videoSession = [[AVCaptureSession alloc] init];
    if ([self.videoSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        self.videoSession.sessionPreset = AVCaptureSessionPreset640x480;
    }
    if ([self.videoSession canAddInput:videoInput]) {
        [self.videoSession addInput:videoInput];
    }
    if ([self.videoSession canAddInput:audioInput]) {
        [self.videoSession addInput:audioInput];
    }
    if ([self.videoSession canAddOutput:_videoDataOut]) {
        [self.videoSession addOutput:_videoDataOut];
    }
    if ([self.videoSession canAddOutput:_audioDataOut]) {
        [self.videoSession addOutput:_audioDataOut];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CGFloat viewWidth = CGRectGetWidth(self.actionView.frame);
        self.videoPreLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.videoSession];
        self.videoPreLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [self.videoView.layer addSublayer:self.videoPreLayer];
        kWeakSelf(self);
        self.videoView.layoutSubviewsCallback = ^(UIView *view) {
            weakself.videoPreLayer.frame = CGRectMake(0, -CGRectGetMinY(weakself.videoView.frame), viewWidth, viewWidth*weakself.customVideo_W_H);
            weakself.videoPreLayer.position = CGPointMake(viewWidth/2, CGRectGetHeight(weakself.videoView.frame)/2);
        };

    });
    
    [self.videoSession startRunning];
    
    [self viewWillAppear];
}

- (void)viewWillAppear {
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CGSize videoViewSize = [PVideoConfig videoViewDefaultSizeWithVideo_W_H:self.customVideo_W_H];
        
        self.eyeView = [[PEyeView alloc] initWithFrame:CGRectMake(0, 0, videoViewSize.width, videoViewSize.height)];
        [self.videoView addSubview:self.eyeView];

    });
}

- (void)viewDidAppear {
    
    if (TARGET_IPHONE_SIMULATOR)  return;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIView *sysSnapshot = [self.eyeView snapshotViewAfterScreenUpdates:NO];
        CGFloat videoViewHeight = CGRectGetHeight(self.videoView.frame);
        CGFloat viewViewWidth = CGRectGetWidth(self.videoView.frame);
        self.eyeView.alpha = 0;
        UIView *topView = [sysSnapshot resizableSnapshotViewFromRect:CGRectMake(0, 0, viewViewWidth, videoViewHeight/2) afterScreenUpdates:NO withCapInsets:UIEdgeInsetsZero];
        CGRect btmFrame = CGRectMake(0, videoViewHeight/2, viewViewWidth, videoViewHeight/2);
        UIView *btmView = [sysSnapshot resizableSnapshotViewFromRect:btmFrame afterScreenUpdates:NO withCapInsets:UIEdgeInsetsZero];
        btmView.frame = btmFrame;
        [self.videoView addSubview:topView];
        [self.videoView addSubview:btmView];
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            topView.transform = CGAffineTransformMakeTranslation(0,-videoViewHeight/2);
            btmView.transform = CGAffineTransformMakeTranslation(0, videoViewHeight);
            topView.alpha = 0.3;
            btmView.alpha = 0.3;
        } completion:^(BOOL finished) {
            [topView removeFromSuperview];
            [btmView removeFromSuperview];
            [self.eyeView removeFromSuperview];
            self.eyeView = nil;
            [self focusInPointAtVideoView:CGPointMake(self.videoView.bounds.size.width/2, self.videoView.bounds.size.height/2)];
        }];
        
        __block UILabel *zoomLab = [UILabel new];
        zoomLab.font = [UIFont boldSystemFontOfSize:14];
        zoomLab.text = @"双击放大";
        zoomLab.textColor = [UIColor whiteColor];
        zoomLab.textAlignment = NSTextAlignmentCenter;
        [self.videoView addSubview:zoomLab];
        [self.videoView bringSubviewToFront:zoomLab];
        [zoomLab mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.offset(200);
            make.height.offset(20);
            make.centerX.equalTo(self.videoView);
            make.bottom.equalTo(self.videoView).offset(-50);
        }];
        
        kz_dispatch_after(1.6, ^{
            [zoomLab removeFromSuperview];
        });
    });
}

- (void)focusInPointAtVideoView:(CGPoint)point {
    CGPoint cameraPoint= [self.videoPreLayer captureDevicePointOfInterestForPoint:point];
    self.focusView.center = point;
    [self.videoView addSubview:self.focusView];
    [self.videoView bringSubviewToFront:self.focusView];
    [self.focusView focusing];
    
    NSError *error = nil;
    if ([_videoDevice lockForConfiguration:&error]) {
        if ([_videoDevice isFocusPointOfInterestSupported]) {
            _videoDevice.focusPointOfInterest = cameraPoint;
        }
        if ([_videoDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            _videoDevice.focusMode = AVCaptureFocusModeAutoFocus;
        }
        if ([_videoDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
            _videoDevice.exposureMode = AVCaptureExposureModeAutoExpose;
        }
        if ([_videoDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
            _videoDevice.whiteBalanceMode = AVCaptureWhiteBalanceModeAutoWhiteBalance;
        }
        [_videoDevice unlockForConfiguration];
    }
    if (error) {
        NSLog(@"聚焦失败:%@",error);
    }
    kz_dispatch_after(1.0, ^{
        [self.focusView removeFromSuperview];
    });
}

#pragma mark ---------------> Actions
- (void)focusAction:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self.videoView];
    [self focusInPointAtVideoView:point];
}

- (void)zoomVideo:(UITapGestureRecognizer *)gesture {
    NSError *error = nil;
    if ([_videoDevice lockForConfiguration:&error]) {
        CGFloat zoom = _videoDevice.videoZoomFactor == 2.0?1.0:2.0;
        _videoDevice.videoZoomFactor = zoom;
        [_videoDevice unlockForConfiguration];
    }
}

- (void)moveTopBarAction:(UIPanGestureRecognizer *)gesture {
    CGPoint pointAtView = [gesture locationInView:self.view];
    CGRect dafultFrame = [PVideoConfig viewFrameWithType:self.showType video_W_H:self.customVideo_W_H withControViewHeight:self.customControViewHeight];
    
    if (pointAtView.y < dafultFrame.origin.y) {
        return;
    }
    
    CGPoint pointAtTop = [gesture locationInView:self.topSlideView];
    if (pointAtTop.y > -10 && pointAtTop.y < 30) {
        CGRect actionFrame = _actionView.frame;
        actionFrame.origin.y = pointAtView.y;
        _actionView.frame = actionFrame;
        
        CGFloat alpha = 0.4*(kSCREEN_HEIGHT - pointAtView.y)/CGRectGetHeight(_actionView.frame);
        self.view.backgroundColor = [UIColor colorWithRed: 0.0 green: 0.0 blue: 0.0 alpha: alpha];
    }
    if (gesture.state == UIGestureRecognizerStateEnded) {
        if (pointAtView.y >= CGRectGetMidY(dafultFrame)) {
            [self endAniamtion];
        }
        else {
            [UIView animateWithDuration:0.3 animations:^{
                self.actionView.frame = dafultFrame;
                self.view.backgroundColor = [UIColor colorWithRed: 0.0 green: 0.0 blue: 0.0 alpha: 0.4];
            }];
        }
    }
}

#pragma mark ---------------> controllerBarDelegate
- (void)ctrollVideoDidStart:(PControllerBar *)controllerBar {
    self.currentRecord = [PVideoUtil createNewVideo];
    self.currentRecordIsCancel = NO;
    NSURL *outURL = [NSURL fileURLWithPath:self.currentRecord.videoAbsolutePath];
    [self createWriter:outURL];
    
    self.topSlideView.isRecoding = YES;
    
    self.statusInfo.textColor = kThemeTineColor;
    self.statusInfo.text = @"↑上移取消";
    self.statusInfo.hidden = NO;
    kz_dispatch_after(0.5, ^{
        self.statusInfo.hidden = YES;
    });
    
    _recoding = YES;
    //    NSLog(@"视频开始录制");
}

- (void)ctrollVideoDidEnd:(PControllerBar *)controllerBar {
    self.topSlideView.isRecoding = NO;
    _recoding = NO;
    [self saveVideo:^(NSURL *outFileURL) {
        if (self.delegate) {
            [self.delegate videoViewController:self didRecordVideo:self.currentRecord];
            [self endAniamtion];
        }
    }];
    
    //    NSLog(@"视频录制结束");
}

- (void)ctrollVideoDidCancel:(PControllerBar *)controllerBar reason:(PRecordCancelReason)reason{
    self.currentRecordIsCancel = YES;
    self.topSlideView.isRecoding = NO;
    _recoding = NO;
    if (reason == PRecordCancelReasonTimeShort) {
        [PVideoConfig showHinInfo:@"录制时间过短" inView:self.videoView frame:CGRectMake(0,CGRectGetHeight(self.videoView.frame)/3*2,CGRectGetWidth(self.videoView.frame),20) timeLong:1.0];
    }
    //    NSLog(@"当前视频录制取消");
}

- (void)ctrollVideoWillCancel:(PControllerBar *)controllerBar {
    if (!self.cancelInfo.hidden) {
        return;
    }
    self.cancelInfo.text = @"松手取消";
    self.cancelInfo.hidden = NO;
    kz_dispatch_after(0.5, ^{
        self.cancelInfo.hidden = YES;
    });
}

- (void)ctrollVideoDidRecordSEC:(PControllerBar *)controllerBar {
    self.topSlideView.isRecoding = YES;
    //    NSLog(@"视频录又过了 1 秒");
}

- (void)ctrollVideoDidClose:(PControllerBar *)controllerBar {
    //    NSLog(@"录制界面关闭");
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoViewControllerDidCancel:)]) {
        [self.delegate videoViewControllerDidCancel:self];
    }
    [self endAniamtion];
}

- (void)ctrollVideoOpenVideoList:(PControllerBar *)controllerBar {
    //    NSLog(@"查看视频列表");
    PVideoListViewController *listVC = [[PVideoListViewController alloc] initWithVideo_H_W:self.customVideo_W_H withControViewHeight:self.customControViewHeight];
    __weak typeof(self) blockSelf = self;
    listVC.selectBlock = ^(PVideoModel *selectModel) {
        self.currentRecord = selectModel;
        if (self.delegate) {
            [self.delegate videoViewController:blockSelf didRecordVideo:self.currentRecord];
        }
        [blockSelf closeView];
    };
    
    listVC.didCloseBlock = ^{
        if (self.showType == PVideoViewShowTypeSingle) {
            [blockSelf viewDidAppear];
        }
    };
    [listVC showAnimationWithType:self.showType];
}

#pragma mark ---------------> AVCaptureVideoDataOutputSampleBufferDelegate&&AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if (!_recoding) return;
    
    @autoreleasepool {
        _currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
        if (_assetWriter.status != AVAssetWriterStatusWriting) {
            [_assetWriter startWriting];
            [_assetWriter startSessionAtSourceTime:_currentSampleTime];
        }
        if (captureOutput == _videoDataOut) {
            if (_assetWriterPixelBufferInput.assetWriterInput.isReadyForMoreMediaData) {
                CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
                BOOL success = [_assetWriterPixelBufferInput appendPixelBuffer:pixelBuffer withPresentationTime:_currentSampleTime];
                if (!success) {
                    NSLog(@"Pixel Buffer没有append成功");
                }
            }
        }
        if (captureOutput == _audioDataOut) {
            [_assetWriterAudioInput appendSampleBuffer:sampleBuffer];
        }
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
}

- (void)createWriter:(NSURL *)assetUrl {
    _assetWriter = [AVAssetWriter assetWriterWithURL:assetUrl fileType:AVFileTypeQuickTimeMovie error:nil];
    int videoWidth = [PVideoConfig defualtVideoSizeWithVideo_W_H:self.customVideo_W_H withVideoWidthPX:customVideoWidthPX].width;
    int videoHeight = [PVideoConfig defualtVideoSizeWithVideo_W_H:self.customVideo_W_H withVideoWidthPX:customVideoWidthPX].height;
    /*
     NSDictionary *videoCleanApertureSettings = @{
     AVVideoCleanApertureWidthKey:@(videoHeight),
     AVVideoCleanApertureHeightKey:@(videoWidth),
     AVVideoCleanApertureHorizontalOffsetKey:@(200),
     AVVideoCleanApertureVerticalOffsetKey:@(0)
     };
     NSDictionary *videoAspectRatioSettings = @{
     AVVideoPixelAspectRatioHorizontalSpacingKey:@(3),
     AVVideoPixelAspectRatioVerticalSpacingKey:@(3)
     };
     NSDictionary *codecSettings = @{
     AVVideoAverageBitRateKey:@(960000),
     AVVideoMaxKeyFrameIntervalKey:@(1),
     AVVideoProfileLevelKey:AVVideoProfileLevelH264Main30,
     AVVideoCleanApertureKey: videoCleanApertureSettings,
     AVVideoPixelAspectRatioKey:videoAspectRatioSettings
     };
     */
    NSDictionary *outputSettings = @{
                                     AVVideoCodecKey : AVVideoCodecH264,
                                     AVVideoWidthKey : @(videoHeight),
                                     AVVideoHeightKey : @(videoWidth),
                                     AVVideoScalingModeKey:AVVideoScalingModeResizeAspectFill,
                                     //                          AVVideoCompressionPropertiesKey:codecSettings
                                     };
    _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:outputSettings];
    _assetWriterVideoInput.expectsMediaDataInRealTime = YES;
    _assetWriterVideoInput.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
    
    
    NSDictionary *audioOutputSettings = @{
                                          AVFormatIDKey:@(kAudioFormatMPEG4AAC),
                                          AVEncoderBitRateKey:@(64000),
                                          AVSampleRateKey:@(44100),
                                          AVNumberOfChannelsKey:@(1),
                                          };
    
    _assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings];
    _assetWriterAudioInput.expectsMediaDataInRealTime = YES;
    
    
    NSDictionary *SPBADictionary = @{
                                     (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
                                     (__bridge NSString *)kCVPixelBufferWidthKey : @(videoWidth),
                                     (__bridge NSString *)kCVPixelBufferHeightKey  : @(videoHeight),
                                     (__bridge NSString *)kCVPixelFormatOpenGLESCompatibility : ((__bridge NSNumber *)kCFBooleanTrue)
                                     };
    _assetWriterPixelBufferInput = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_assetWriterVideoInput sourcePixelBufferAttributes:SPBADictionary];
    if ([_assetWriter canAddInput:_assetWriterVideoInput]) {
        [_assetWriter addInput:_assetWriterVideoInput];
    }else {
        NSLog(@"不能添加视频writer的input \(assetWriterVideoInput)");
    }
    if ([_assetWriter canAddInput:_assetWriterAudioInput]) {
        [_assetWriter addInput:_assetWriterAudioInput];
    }else {
        NSLog(@"不能添加视频writer的input \(assetWriterVideoInput)");
    }
    
}

- (void)saveVideo:(void(^)(NSURL *outFileURL))complier {
    
    if (_recoding) return;
    
    if (!_recoding_queue){
        complier(nil);
        return;
    };
    
    dispatch_async(_recoding_queue, ^{
        NSURL *outputFileURL = [NSURL fileURLWithPath:self.currentRecord.videoAbsolutePath];
        [self.assetWriter finishWritingWithCompletionHandler:^{
            
            if (self.currentRecordIsCancel) return ;
            
            [PVideoUtil saveThumImageWithVideoURL:outputFileURL second:1];
            
            if (complier) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    complier(outputFileURL);
                });
            }
            if (self.savePhotoAlbum) {
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:outputFileURL];
                } completionHandler:^(BOOL success, NSError * _Nullable error) {
                    if (!error && success) {
                        NSLog(@"保存相册成功!");
                    }
                    else {
                        NSLog(@"保存相册失败! :%@",error);
                    }
                }];
            }
        }];
    });
}

@end

