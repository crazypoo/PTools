//
//  PVideoSupport.m
//  XMNaio_Client
//
//  Created by MYX on 2017/5/16.
//  Copyright © 2017年 E33QU5QCP3.com.xnmiao.customer.XMNiao-Customer. All rights reserved.
//

#import "PVideoSupport.h"
#import <Masonry/Masonry.h>

#pragma mark ---------------> Custom View

@interface PStatusBar()
@property (nonatomic,strong)CALayer *recodingLayer;
@property (nonatomic,strong)CAShapeLayer *nomalLayer;
@property (nonatomic,assign)PVideoViewShowType style;
@end

@implementation PStatusBar
{
    BOOL _clear;
    
    UIButton *_cancelBtn;
}

- (instancetype)initWithFrame:(CGRect)frame style:(PVideoViewShowType)style
{
    if (self = [super initWithFrame:frame])
    {
        _style = style;
        [PVideoConfig motionBlurView:self];
        [self setupSubLayers];
    }
    return self;
}

- (void)addCancelTarget:(id)target selector:(SEL)selector
{
    [_cancelBtn removeFromSuperview];
    _cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    [_cancelBtn addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    [_cancelBtn setTitleColor:kThemeTineColor forState:UIControlStateNormal];
    _cancelBtn.alpha = 0.8;
    [self addSubview:_cancelBtn];
    [_cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(10);
        make.top.equalTo(self).offset(22);
        make.width.offset(50);
        make.height.offset(40);
    }];
}

- (void)setupSubLayers
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.style == PVideoViewShowTypeSingle)
        {
            return;
        }
        
        UIView *showView = [[UIView alloc] initWithFrame:self.bounds];
        showView.backgroundColor = [UIColor clearColor];
        [self addSubview:showView];
        
        CGAffineTransform transform = CGAffineTransformIdentity;
        
        CGFloat barW = 20.0;
        CGFloat barSpace = 4.0;
        CGFloat topEdge = 5.5;
        CGPoint selfCent = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        CGMutablePathRef nomalPath = CGPathCreateMutable();
        for (int i = 0; i < 3; i++)
        {
            CGPathMoveToPoint(nomalPath, &transform, selfCent.x-(barW/2), topEdge+(barSpace * i));
            CGPathAddLineToPoint(nomalPath, &transform, selfCent.x+(barW/2), topEdge+(barSpace * i));
        }
        self.nomalLayer = [CAShapeLayer layer];
        self.nomalLayer.frame = self.bounds;
        self.nomalLayer.strokeColor = [UIColor  colorWithRed: 0.5 green: 0.5 blue: 0.5 alpha: 0.7 ].CGColor;
        self.nomalLayer.lineCap = kCALineCapRound;
        self.nomalLayer.lineWidth = 2.0;
        self.nomalLayer.path = nomalPath;
        [showView.layer addSublayer:self.nomalLayer];
        CGPathRelease(nomalPath);
        
        CGFloat width = 10;
        CGFloat height = 8;
        self.recodingLayer = [CALayer layer];
        self.recodingLayer.frame = CGRectMake(selfCent.x - width/2, selfCent.y - height/2, width, height);
        self.recodingLayer.cornerRadius = height/2;
        self.recodingLayer.masksToBounds = YES;
        self.recodingLayer.backgroundColor = kThemeWaringColor.CGColor;
        [showView.layer addSublayer:self.recodingLayer];
        
        self.recodingLayer.hidden = YES;

    });
}

- (void)setIsRecoding:(BOOL)isRecoding
{
    _isRecoding = isRecoding;
    [self display];
}

- (void)display
{
    if (_style == PVideoViewShowTypeSingle)
    {
        return;
    }
    
    if (self.isRecoding)
    {
        self.recodingLayer.hidden = NO;
        self.nomalLayer.hidden = YES;
        kz_dispatch_after(0.5, ^{
            if (!self.isRecoding)  return;
            self.recodingLayer.hidden = YES;
            self.nomalLayer.hidden = YES;
        });
    }
    else
    {
        self.nomalLayer.hidden = NO;
        self.recodingLayer.hidden = YES;
    }
}

@end

@implementation PCloseBtn


- (void)setGradientColors:(NSArray *)gradientColors
{
    self.backgroundColor = [UIColor clearColor];
    _gradientColors = gradientColors;
    
    CAShapeLayer *trackLayer = [CAShapeLayer layer];
    trackLayer.frame = self.bounds;
    trackLayer.strokeColor = kThemeTineColor.CGColor;
    trackLayer.fillColor = [UIColor clearColor].CGColor;
    trackLayer.lineCap = kCALineCapRound;
    trackLayer.lineWidth = 3.0;
    
//    CGMutablePathRef path = [self getDrawPath];
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGFloat centX = self.bounds.size.width/2;
    CGFloat centY = self.bounds.size.height/2;
    CGFloat drawWidth = 22;
    CGFloat drawHeight = 10;
    CGPathMoveToPoint(path, NULL, (centX - drawWidth/2), (centY - drawHeight/2));
    CGPathAddLineToPoint(path, NULL, centX, centY + drawHeight/2);
    CGPathAddLineToPoint(path, NULL, centX + drawWidth/2, centY - drawHeight/2);

    trackLayer.path = path;
    [self.layer addSublayer:trackLayer];
    CGPathRelease(path);
    
    CAGradientLayer *maskLayer = [CAGradientLayer layer];
    maskLayer.frame = self.bounds;
    maskLayer.colors = _gradientColors;
    [self.layer addSublayer:maskLayer];
    maskLayer.mask = trackLayer;
    [self setNeedsDisplay];
}


- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    if (_gradientColors != nil)
    {
        return;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetAllowsAntialiasing(context, YES);
    
    CGContextSetStrokeColorWithColor(context, kThemeGraryColor.CGColor);
    CGContextSetLineWidth(context, 3.0);
    CGContextSetLineCap(context, kCGLineCapRound);
//    CGMutablePathRef path = [self getDrawPath];
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGFloat centX = self.bounds.size.width/2;
    CGFloat centY = self.bounds.size.height/2;
    CGFloat drawWidth = 22;
    CGFloat drawHeight = 10;
    CGPathMoveToPoint(path, NULL, (centX - drawWidth/2), (centY - drawHeight/2));
    CGPathAddLineToPoint(path, NULL, centX, centY + drawHeight/2);
    CGPathAddLineToPoint(path, NULL, centX + drawWidth/2, centY - drawHeight/2);

    CGContextAddPath(context, path);
    CGContextDrawPath(context, kCGPathStroke);
    CGPathRelease(path);
}

//FIX:没有释放
//- (CGMutablePathRef)getDrawPath
//{
//    CGMutablePathRef path = CGPathCreateMutable();
//    CGFloat centX = self.bounds.size.width/2;
//    CGFloat centY = self.bounds.size.height/2;
//    CGFloat drawWidth = 22;
//    CGFloat drawHeight = 10;
//    CGPathMoveToPoint(path, NULL, (centX - drawWidth/2), (centY - drawHeight/2));
//    CGPathAddLineToPoint(path, NULL, centX, centY + drawHeight/2);
//    CGPathAddLineToPoint(path, NULL, centX + drawWidth/2, centY - drawHeight/2);
//
//    CGMutablePathRef newPath = path;
//    //FIX:释放
//    CGPathRelease(path);
//    return newPath;
//}

@end

@implementation PRecordBtn
{
    UITapGestureRecognizer *_tapGesture;
    PVideoViewShowType _style;
}

- (instancetype)initWithFrame:(CGRect)frame style:(PVideoViewShowType)style
{
    if (self = [super initWithFrame:frame])
    {
        _style = style;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self setupRoundButton];
            self.layer.cornerRadius = self.bounds.size.width/2;
        });
        self.layer.masksToBounds = YES;
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (void)setupRoundButton
{
    self.backgroundColor = [UIColor clearColor];
    
    CGFloat width = self.frame.size.width;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:width/2];
    
    CAShapeLayer *trackLayer = [CAShapeLayer layer];
    trackLayer.frame = self.bounds;
    trackLayer.strokeColor = kThemeTineColor.CGColor;
    trackLayer.fillColor = [UIColor clearColor].CGColor;
    trackLayer.opacity = 1.0;
    trackLayer.lineCap = kCALineCapRound;
    trackLayer.lineWidth = 2.0;
    trackLayer.path = path.CGPath;
    [self.layer addSublayer:trackLayer];
    
    if (_style == PVideoViewShowTypeSingle)
    {
        CATextLayer *textLayer = [CATextLayer layer];
        textLayer.string = @"按住拍";
        textLayer.frame = CGRectMake(0, 0, 120, 30);
        textLayer.position = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        UIFont *font = [UIFont boldSystemFontOfSize:22];
        CFStringRef fontName = (__bridge CFStringRef)font.fontName;
        CGFontRef fontRef = CGFontCreateWithFontName(fontName);
        textLayer.font = fontRef;
        textLayer.fontSize = font.pointSize;
        CGFontRelease(fontRef);
        textLayer.contentsScale = [UIScreen mainScreen].scale;
        textLayer.foregroundColor = kThemeTineColor.CGColor;
        textLayer.alignmentMode = kCAAlignmentCenter;
        textLayer.wrapped = YES;
        [trackLayer addSublayer:textLayer];
    }
    
    CAGradientLayer *gradLayer = [CAGradientLayer layer];
    gradLayer.frame = self.bounds;
    gradLayer.colors = [PVideoConfig gradualColors];
    [self.layer addSublayer:gradLayer];
    
    gradLayer.mask = trackLayer;
}
@end


@implementation PFocusView
{
    CGFloat _width;
    CGFloat _height;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _width = CGRectGetWidth(frame);
        _height = _width;
    }
    return self;
    
}

- (void)focusing
{
    [UIView animateWithDuration:0.5 animations:^{
        
        self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.8, 0.8);
    } completion:^(BOOL finished) {
        self.transform = CGAffineTransformIdentity;
    }];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, kThemeTineColor.CGColor);
    CGContextSetLineWidth(context, 1.0);
    
    CGFloat len = 4;
    
    CGContextMoveToPoint(context, 0.0, 0.0);
    CGContextAddRect(context, self.bounds);
    
    CGContextMoveToPoint(context, 0, _height/2);
    CGContextAddLineToPoint(context, len, _height/2);
    
    CGContextMoveToPoint(context, _width/2, _height);
    CGContextAddLineToPoint(context, _width/2, _height - len);
    
    CGContextMoveToPoint(context, _width, _height/2);
    CGContextAddLineToPoint(context, _width - len, _height/2);
    
    CGContextMoveToPoint(context, _width/2, 0);
    CGContextAddLineToPoint(context, _width/2, len);
    
    CGContextDrawPath(context, kCGPathStroke);
}

@end


@implementation PEyeView


- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [PVideoConfig motionBlurView:self];
        
        [self setupView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self layoutIfNeeded];
        [PVideoConfig motionBlurView:self];
        [self setupView];
    }
    return self;
}

- (void)setupView
{
    UIView *view = [[UIView alloc] initWithFrame:self.bounds];
    view.backgroundColor = [UIColor clearColor];
    [self addSubview:view];
    
    PEyePath path = createEyePath(self.bounds);
    UIColor *color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.9];
    
    CAShapeLayer *shapelayer1 = [CAShapeLayer layer];
    shapelayer1.frame = self.bounds;
    shapelayer1.strokeColor = color.CGColor;
    shapelayer1.fillColor = [UIColor clearColor].CGColor;
    shapelayer1.opacity = 1.0;
    shapelayer1.lineCap = kCALineCapRound;
    shapelayer1.lineWidth = 1.0;
    shapelayer1.path = path.strokePath;
    [view.layer addSublayer:shapelayer1];
    
    CAShapeLayer *shapelayer2 = [CAShapeLayer layer];
    shapelayer2.frame = self.bounds;
    shapelayer2.strokeColor = color.CGColor;
    shapelayer2.fillColor = color.CGColor;
    shapelayer2.opacity = 1.0;
    shapelayer2.lineCap = kCALineCapRound;
    shapelayer2.lineWidth = 1.0;
    shapelayer2.path = path.fillPath;
    [view.layer addSublayer:shapelayer2];
    
    KZEyePathRelease(path);
}

/*
 - (void)drawRect:(CGRect)rect {
 [super drawRect:rect];
 return;
 
 KZEyePath path = createEyePath(self.bounds);
 
 CGContextRef context = UIGraphicsGetCurrentContext();
 UIColor *color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.9];
 [color setStroke];
 [color setFill];
 CGContextSetLineWidth(context, 1.0);
 CGContextSetLineCap(context, kCGLineCapRound);
 CGContextAddPath(context, path.strokePath);
 CGContextDrawPath(context, kCGPathStroke);
 
 CGContextAddPath(context, path.fillPath);
 CGContextDrawPath(context, kCGPathFillStroke);
 
 KZEyePathRelease(path);
 }
 */
typedef struct eyePath
{
    CGMutablePathRef strokePath;
    CGMutablePathRef fillPath;
} PEyePath;

void KZEyePathRelease(PEyePath path)
{
    CGPathRelease(path.fillPath);
    CGPathRelease(path.strokePath);
}

PEyePath createEyePath(CGRect rect)
{
    CGPoint selfCent = CGPointMake(CGRectGetWidth(rect)/2, CGRectGetHeight(rect)/2);
    CGFloat eyeWidth = 64.0;
    CGFloat eyeHeight = 40.0;
    CGFloat curveCtrlH = 44;
    
    CGAffineTransform transform = CGAffineTransformMakeScale(1.0, 1.0);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, &transform, selfCent.x - eyeWidth/2, selfCent.y);
    CGPathAddQuadCurveToPoint(path, &transform, selfCent.x, selfCent.y - curveCtrlH, selfCent.x + eyeWidth/2, selfCent.y);
    CGPathAddQuadCurveToPoint(path, &transform, selfCent.x, selfCent.y + curveCtrlH, selfCent.x - eyeWidth/2, selfCent.y);
    CGFloat arcRadius = eyeHeight/2 - 1;
    CGPathMoveToPoint(path, &transform, selfCent.x + arcRadius, selfCent.y);
    CGPathAddArc(path, &transform, selfCent.x, selfCent.y, arcRadius, 0, M_PI * 2, false);
    
    CGFloat startAngle = 110;
    CGFloat angle1 = startAngle + 30;
    CGFloat angle2 = angle1 + 20;
    CGFloat angle3 = angle2 + 10;
    CGFloat arcRadius2 = arcRadius - 4;
    CGFloat arcRadius3 = arcRadius2 - 7;
    
    CGMutablePathRef path2 = createDonutPath(selfCent, angleToRadian(startAngle), angleToRadian(angle1), arcRadius2, arcRadius3, &transform);
    CGMutablePathRef path3 = createDonutPath(selfCent, angleToRadian(angle2), angleToRadian(angle3), arcRadius2, arcRadius3, &transform);
    CGPathAddPath(path2, NULL, path3);
    
    CGPathRelease(path3);
    return (PEyePath){path, path2};
}

// angle 逆时针角度
CGMutablePathRef createDonutPath(CGPoint center, CGFloat startAngle, CGFloat endAngle, CGFloat bigRadius, CGFloat smallRadius, CGAffineTransform * transform) {
    CGFloat arcStart = M_PI*2 - startAngle;
    CGFloat arcEnd = M_PI*2 - endAngle;
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, transform, center.x + bigRadius * cos(startAngle), center.y - bigRadius * sin(startAngle));
    CGPathAddArc(path, transform, center.x, center.y, bigRadius, arcStart, arcEnd, true);
    CGPathAddLineToPoint(path, transform, center.x + smallRadius * cos(endAngle), center.y - smallRadius * sin(endAngle));
    CGPathAddArc(path, transform, center.x, center.y, smallRadius, arcEnd, arcStart, false);
    CGPathAddLineToPoint(path, transform, center.x + bigRadius * cos(startAngle), center.y - bigRadius * sin(startAngle));
    return path;
}

double kz_sin(double angle)
{
    return sin(angleToRadian(angle));
}

double kz_cos(double angle)
{
    return cos(angleToRadian(angle));
}

CGFloat angleToRadian(CGFloat angle)
{
    return angle/180.0*M_PI;
}

@end

#pragma mark ---------------> 分割线
@interface PControllerBar()
@property (nonatomic,strong)PRecordBtn *startBtn;
@property (nonatomic,strong)UIView *progressLine;
@property (nonatomic,assign)NSTimeInterval surplusTime;
@property (nonatomic,assign)BOOL recording;
@property (nonatomic,assign)int customRecordTime;
@property (nonatomic,strong)UILongPressGestureRecognizer *longPress;
@property (nonatomic,strong)UIButton *videoListBtn;
@property (nonatomic,strong)PCloseBtn *closeVideoBtn;
@end

@implementation PControllerBar
{
    BOOL _touchIsInside;
    
    NSTimer *_timer;

    BOOL _videoDidEnd;
}

- (void)setupSubViewsWithStyle:(PVideoViewShowType)style recordTime:(NSTimeInterval)recordTime
{
    [self layoutIfNeeded];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [PVideoConfig motionBlurView:self];
        self.customRecordTime = recordTime;
        
        CGFloat selfHeight = self.bounds.size.height;
        CGFloat selfWidth = self.bounds.size.width;
        CGFloat edge = 20.0;
        CGFloat startBtnWidth = style == PVideoViewShowTypeSmall ? selfHeight - (edge * 2) : selfHeight/2;
        
        self.startBtn = [[PRecordBtn alloc] initWithFrame:CGRectZero style:style];
        [self addSubview:self.startBtn];
        [self.startBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.offset(startBtnWidth);
            make.centerX.centerY.equalTo(self);
        }];
        
        self.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
        self.longPress.minimumPressDuration = 0.01;
        self.longPress.delegate = self;
        [self addGestureRecognizer:self.longPress];
        
        self.progressLine = [UIView new];
        self.progressLine.backgroundColor = kThemeTineColor;
        self.progressLine.hidden = YES;
        [self addSubview:self.progressLine];
        [self.progressLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.equalTo(self);
            make.width.offset(selfWidth);
            make.height.offset(4);
        }];
        
        self.surplusTime = self.customRecordTime;
        
        if (style == PVideoViewShowTypeSingle)
        {
            return;
        }
        
        self.videoListBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.videoListBtn.layer.cornerRadius = 8;
        self.videoListBtn.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.videoListBtn.layer.masksToBounds = YES;
        [self.videoListBtn addTarget:self action:@selector(videoListAction) forControlEvents:UIControlEventTouchUpInside];
        //        self.videoListBtn.backgroundColor = kzThemeTineColor
        [self addSubview:self.videoListBtn];
        [self.videoListBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(edge);
            make.top.equalTo(self).offset(edge+startBtnWidth/6);
            make.width.offset(startBtnWidth/4*3);
            make.height.offset(startBtnWidth/3*2);
        }];
        
        NSArray<PVideoModel *> *videoList = [PVideoUtil getSortVideoList];
        if (videoList.count == 0)
        {
            self.videoListBtn.hidden = YES;
        }
        else
        {
            [self.videoListBtn setBackgroundImage:[UIImage imageWithContentsOfFile:videoList[0].thumAbsolutePath] forState: UIControlStateNormal];
        }
        
        CGFloat closeBtnWidth = startBtnWidth/3*2;
        self.closeVideoBtn = [PCloseBtn buttonWithType:UIButtonTypeCustom];
        //    self.closeVideoBtn.frame = CGRectMake(self.bounds.size.width - closeBtnWidth - edge, edge+startBtnWidth/6, closeBtnWidth, closeBtnWidth);
        [self.closeVideoBtn addTarget:self action:@selector(videoCloseAction) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.closeVideoBtn];
        [self.closeVideoBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(- edge);
            make.top.equalTo(self).offset(edge+startBtnWidth/6);
            make.width.height.offset(closeBtnWidth);
        }];
    });
}

- (void)startRecordSet
{
    self.startBtn.alpha = 1.0;
    
    self.progressLine.frame = CGRectMake(0, 0, self.bounds.size.width, 2);
    self.progressLine.backgroundColor = kThemeTineColor;
    self.progressLine.hidden = NO;
    
    self.surplusTime = self.customRecordTime;
    self.recording = YES;
    
    _videoDidEnd = NO;
    
    if (_timer == nil)
    {
        _timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(recordTimerAction) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
    }
    [_timer fire];
    
    [UIView animateWithDuration:0.4 animations:^{
        self.startBtn.alpha = 0.0;
        self.startBtn.transform = CGAffineTransformScale(CGAffineTransformIdentity, 2.0, 2.0);
    } completion:^(BOOL finished) {
        if (finished)
        {
            self.startBtn.transform = CGAffineTransformIdentity;
        }
    }];
}

- (void)endRecordSet
{
    self.progressLine.hidden = YES;
    [_timer invalidate];
    _timer = nil;
    self.recording = NO;
    self.startBtn.alpha = 1;
}

#pragma mark ---------------> UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.longPress)
    {
        if (self.surplusTime <= 0) return NO;
        
        CGPoint point = [gestureRecognizer locationInView:self];
        CGPoint startBtnCent = self.startBtn.center;
        
        CGFloat dx = point.x - startBtnCent.x;
        CGFloat dy = point.y - startBtnCent.y;
        
        CGFloat startWidth = self.startBtn.bounds.size.width;
        if ((dx * dx) + (dy * dy) < (startWidth * startWidth))
        {
            return YES;
        }
        return NO;
    }
    return YES;
}

#pragma mark ---------------> Actions
- (void)longpressAction:(UILongPressGestureRecognizer *)gesture
{
    CGPoint point = [gesture locationInView:self];
    _touchIsInside = point.y >= 0;
    switch (gesture.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            [self videoStartAction];
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            if (!_touchIsInside)
            {
                self.progressLine.backgroundColor = kThemeWaringColor;
                if (_delegate && [_delegate respondsToSelector:@selector(ctrollVideoWillCancel:)])
                {
                    [_delegate ctrollVideoWillCancel:self];
                }
            }
            else
            {
                self.progressLine.backgroundColor = kThemeTineColor;
            }
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            [self endRecordSet];
            if (!_touchIsInside || self.customRecordTime - self.surplusTime <= 1) {
                PRecordCancelReason reason = PRecordCancelReasonTimeShort;
                if (!_touchIsInside)
                {
                    reason = PRecordCancelReasonDefault;
                }
                [self videoCancelAction:reason];
            }
            else
            {
                [self videoEndAction];
            }
        }
            break;
        case UIGestureRecognizerStateCancelled:
            break;
        default:
            break;
    }
}

- (void)videoStartAction
{
    [self startRecordSet];
    if (_delegate && [_delegate respondsToSelector:@selector(ctrollVideoDidStart:)])
    {
        [_delegate ctrollVideoDidStart:self];
    }
}

- (void)videoCancelAction:(PRecordCancelReason)reason
{
    if (_delegate && [_delegate respondsToSelector:@selector(ctrollVideoDidCancel:reason:)])
    {
        [_delegate ctrollVideoDidCancel:self reason:reason];
    }
}

- (void)videoEndAction
{
    
    if (_videoDidEnd) return;
    
    _videoDidEnd = YES;
    if (_delegate && [_delegate respondsToSelector:@selector(ctrollVideoDidEnd:)])
    {
        [_delegate ctrollVideoDidEnd:self];
    }
}

- (void)videoListAction
{
    if (_delegate && [_delegate respondsToSelector:@selector(ctrollVideoOpenVideoList:)])
    {
        [_delegate ctrollVideoOpenVideoList:self];
    }
}

- (void)videoCloseAction {
    if (_delegate && [_delegate respondsToSelector:@selector(ctrollVideoDidClose:)])
    {
        [_delegate ctrollVideoDidClose:self];
    }
}

- (void)recordTimerAction
{
    CGFloat reduceLen = self.bounds.size.width/self.customRecordTime;
    CGFloat oldLineLen = self.progressLine.frame.size.width;
    CGRect oldFrame = self.progressLine.frame;
    
    [UIView animateWithDuration:1.0 delay: 0.0 options: UIViewAnimationOptionCurveLinear animations:^{
        self.progressLine.frame = CGRectMake(oldFrame.origin.x, oldFrame.origin.y, oldLineLen - reduceLen, oldFrame.size.height);
        self.progressLine.center = CGPointMake(self.bounds.size.width/2, self.progressLine.bounds.size.height/2);
    } completion:^(BOOL finished) {
        self.surplusTime --;
        if (self.recording) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(ctrollVideoDidRecordSEC:)])
            {
                [self.delegate ctrollVideoDidRecordSEC:self];
            }
        }
        if (self.surplusTime <= 0.0)
        {
            [self endRecordSet];
            [self videoEndAction];
        }
    }];
}

@end

#pragma mark ---------------> Video List控件
@implementation PCircleCloseBtn

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    self.layer.backgroundColor = [UIColor whiteColor].CGColor;
    self.layer.cornerRadius = self.bounds.size.width/2;
    self.layer.masksToBounds = YES;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetAllowsAntialiasing(context, YES);
    CGContextSetStrokeColorWithColor(context, kThemeBlackColor.CGColor);
    CGContextSetLineWidth(context, 1.0);
    CGContextSetLineCap(context, kCGLineCapRound);
    
    CGPoint selfCent = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    CGFloat closeWidth = 8.0;
    
    CGContextMoveToPoint(context, selfCent.x-closeWidth/2, selfCent.y - closeWidth/2);
    CGContextAddLineToPoint(context, selfCent.x + closeWidth/2, selfCent.y + closeWidth/2);
    
    CGContextMoveToPoint(context, selfCent.x-closeWidth/2, selfCent.y + closeWidth/2);
    CGContextAddLineToPoint(context, selfCent.x + closeWidth/2, selfCent.y - closeWidth/2);
    
    CGContextDrawPath(context, kCGPathStroke);
}

@end


@implementation PVideoListCell
{
    UIImageView *_thumImage;
    PCircleCloseBtn *_closeBtn;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _thumImage = [[UIImageView alloc] initWithFrame:CGRectMake(4, 4, self.bounds.size.width - 8, self.bounds.size.height - 8)];
        _thumImage.layer.cornerRadius = 6.0;
        _thumImage.layer.masksToBounds = YES;
        _thumImage.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:_thumImage];
        
        _closeBtn = [[PCircleCloseBtn alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
        [_closeBtn addTarget:self action:@selector(deleteAction) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_closeBtn];
        _closeBtn.hidden = YES;
        
    }
    return self;
}

- (void)setVideoModel:(PVideoModel *)videoModel
{
    _videoModel = videoModel;
    _thumImage.image = [UIImage imageNamed:videoModel.thumAbsolutePath];
    //    [UIImage imageWithContentsOfFile:videoModel.totalThumPath];
}

- (void)setEdit:(BOOL)canEdit
{
    _closeBtn.hidden = !canEdit;
}

- (void)deleteAction
{
    if (self.deleteVideoBlock)
    {
        self.deleteVideoBlock(self.videoModel);
    }
}
@end

@implementation PAddNewVideoCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self setupView];
    }
    return self;
}

- (void)setupView
{
    CALayer *bgLayer = [CALayer layer];
    bgLayer.frame = CGRectMake(4, 4, self.bounds.size.width - 8, self.bounds.size.height - 8);
    bgLayer.backgroundColor = [UIColor colorWithRed: 0.5 green: 0.5 blue: 0.5 alpha: 0.3].CGColor;
    bgLayer.cornerRadius = 8.0;
    bgLayer.masksToBounds = YES;
    [self.contentView.layer addSublayer:bgLayer];
    
    CGPoint selfCent = CGPointMake(bgLayer.bounds.size.width/2, bgLayer.bounds.size.height/2);
    CGFloat len = 20;
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, nil, selfCent.x, selfCent.y - len);
    CGPathAddLineToPoint(path, nil, selfCent.x, selfCent.y + len);
    
    CGPathMoveToPoint(path, nil, selfCent.x - len, selfCent.y);
    CGPathAddLineToPoint(path, nil, selfCent.x + len, selfCent.y);
    
    CAShapeLayer *crossLayer = [CAShapeLayer layer];
    crossLayer.fillColor = [UIColor clearColor].CGColor;
    crossLayer.strokeColor = kThemeGraryColor.CGColor;
    crossLayer.lineWidth = 4.0;
    crossLayer.path = path;
    crossLayer.opacity = 1.0;
    [bgLayer addSublayer:crossLayer];
    CGPathRelease(path);
}
@end
