//
//  PopSignatureView.m
//  EsayHandwritingSignature
//
//  Created by Liangk on 2017/11/9.
//  Copyright © 2017年 liang. All rights reserved.
//

#import "PopSignatureView.h"
#import "EasySignatureView.h"
#import <Masonry/Masonry.h>
#import <PooTools/NSString+WPAttributedMarkup.h>
#import <PooTools/PMacros.h>

#define SignatureViewHeight ((kSCREEN_WIDTH*(350))/(375))

@interface PopSignatureView () <SignatureViewDelegate> {
    UIView* _mainView;
    UILabel *navTitle;
    UIButton *clearBtn;;
}

@property (nonatomic,strong) UIView *backGroundView;
@property (nonatomic,strong) UIView *navView;
@property (nonatomic,strong) UIColor *navColor;
@property (nonatomic,strong) NSString *maskString;
@property (nonatomic,strong) NSString *fontName;
@property (nonatomic,strong) NSString *navFontName;
@property (nonatomic,strong) UIButton *maskView;
@property (nonatomic,strong) UIButton *btn3;
@property (nonatomic,strong) EasySignatureView *signatureView;

@end

@implementation PopSignatureView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        self.frame =CGRectMake(0, 0, kSCREEN_WIDTH, kSCREEN_HEIGHT);
        self.backgroundColor = kRGBAColor(0, 0, 0, 0.4);
        self.userInteractionEnabled = YES;
    }
    return self;
}
- (id)initWithMainView:(UIView*)mainView
{
    self = [super init];
    if(self)
    {
        self.frame = CGRectMake(0, 0, kSCREEN_WIDTH, kSCREEN_HEIGHT);
        self.userInteractionEnabled = YES;
        _mainView = mainView;
    }
    return self;
}

-(instancetype)initWithNavColor:(UIColor *)navC maskString:(NSString *)mString withViewFontName:(NSString *)fName withNavFontName:(NSString *)nfName
{
    self = [super init];
    if (self)
    {
        self.navColor = navC;
        self.maskString = mString;
        self.fontName = fName;
        self.navFontName = nfName;
    }
    return self;
}

- (void)showInView:(UIView *)view
{
    [view addSubview:self];
}

- (void)setupView
{
    self.maskView = [UIButton buttonWithType:UIButtonTypeCustom];
    self.maskView.frame = CGRectMake(0, 0, kSCREEN_WIDTH, kSCREEN_HEIGHT);
    self.maskView.backgroundColor = kRGBAColor(0, 0, 0, 0.4);
    self.maskView.userInteractionEnabled = YES;
    [self addSubview:self.maskView];
    [self.maskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(self);
    }];
    
    self.backGroundView = [UIView new];
    self.backGroundView.userInteractionEnabled = YES;
    [self.maskView addSubview:self.backGroundView];

    self.signatureView = [EasySignatureView new];
    self.signatureView.backgroundColor = UIColor.whiteColor;
    self.signatureView.delegate = self;
    self.signatureView.showMessage = self.maskString ? self.maskString : @"";
    self.signatureView.placeholderFont = self.fontName ? self.fontName : kDevLikeFont;
    [self.backGroundView addSubview:self.signatureView];

    self.navView = [UIView new];
    self.navView.backgroundColor = self.navColor ? self.navColor : kRandomColor;
    [self.backGroundView addSubview:self.navView];
    
    UIFont *viewBtnFont = kDEFAULT_FONT(self.fontName ? self.fontName : kDevLikeFont, 16);
    
    CGFloat navSpace = 10;
    NSString *cleanString = @"清除";
    clearBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    clearBtn.titleLabel.font = viewBtnFont;
    [clearBtn setTitle:cleanString forState:UIControlStateNormal];
    [clearBtn addTarget:self action:@selector(onClear) forControlEvents:UIControlEventTouchUpInside];
    [clearBtn setTitleColor:kRGBAColor(255, 255, 255, 0.5) forState:UIControlStateNormal];
    [self.navView addSubview:clearBtn];

    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.titleLabel.font = viewBtnFont;
    [cancelBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.navView addSubview:cancelBtn];
    
    self.btn3 = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btn3 setTitle:@"提交" forState:UIControlStateNormal];
    [self.btn3 setTitleColor:kRGBAColor(255, 255, 255, 0.5) forState:UIControlStateNormal];
    self.btn3.titleLabel.font = viewBtnFont;
    self.btn3.backgroundColor = self.navColor ? self.navColor : kRandomColor;
    [self.btn3 addTarget:self action:@selector(okAction) forControlEvents:UIControlEventTouchUpInside];
    [self.backGroundView addSubview:self.btn3];
    
    UIDevice *device = [UIDevice currentDevice];
    if (device.orientation == UIDeviceOrientationLandscapeLeft || device.orientation ==  UIDeviceOrientationLandscapeRight)
    {
        [self.backGroundView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.bottom.equalTo(self.maskView);
        }];
        
        [self.signatureView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.backGroundView);
            make.height.offset(kSCREEN_HEIGHT - HEIGHT_BUTTON*2);
            make.top.offset(HEIGHT_BUTTON);
        }];
        
        [self.navView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.equalTo(self.backGroundView);
            make.height.offset(HEIGHT_BUTTON);
        }];
        
        NSDictionary *style = @{
                                @"big":@[kDEFAULT_FONT(self.navFontName ? self.navFontName : kDevLikeFont_Bold, 12),UIColor.whiteColor],
                                @"small":@[kDEFAULT_FONT(self.navFontName ? self.navFontName : kDevLikeFont_Bold, 10),UIColor.whiteColor]
                                };
        
        navTitle = [UILabel new];
        navTitle.textAlignment = NSTextAlignmentCenter;
        navTitle.lineBreakMode = NSLineBreakByCharWrapping;
        navTitle.numberOfLines = 0;
        navTitle.attributedText = [@"<big>请在白色区域手写签名</big>\n<small>并以正楷, 工整书写</small>" attributedStringWithStyleBook:style];
        [self.navView addSubview:navTitle];
        [navTitle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self.navView);
            make.centerX.equalTo(self.navView.mas_centerX);
        }];
        navTitle.hidden = YES;
        
        [clearBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.navView).offset(-navSpace);
            make.top.bottom.equalTo(self.navView);
            make.width.offset(cleanString.length*viewBtnFont.pointSize+10);
        }];
        
        [cancelBtn setTitle:@"返回" forState:UIControlStateNormal];
        [cancelBtn addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        [cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.navView).offset(navSpace);
            make.top.bottom.equalTo(self.navView);
            make.width.offset(cleanString.length*viewBtnFont.pointSize+10);
        }];
        
        [self.btn3 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.backGroundView);
            make.bottom.equalTo(self.backGroundView);
            make.height.offset(HEIGHT_BUTTON);
        }];
    }
    else
    {
        [self.backGroundView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.bottom.equalTo(self.maskView);
        }];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapMaskView:)];
        [self.backGroundView addGestureRecognizer:tap];
        
        [self.btn3 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.backGroundView);
            make.bottom.equalTo(self.backGroundView);
            make.height.offset(HEIGHT_BUTTON);
        }];
        
        [self.signatureView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.backGroundView);
            make.height.offset(SignatureViewHeight - HEIGHT_BUTTON*2);
            make.bottom.equalTo(self.btn3.mas_top);
        }];
        
        [self.navView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.backGroundView);
            make.height.offset(HEIGHT_BUTTON);
            make.bottom.equalTo(self.signatureView.mas_top);
        }];
        
        [clearBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.navView).offset(-navSpace);
            make.top.bottom.equalTo(self.navView);
            make.width.offset(cleanString.length*viewBtnFont.pointSize+10);
        }];
        
        [cancelBtn setTitle:@"签名" forState:UIControlStateNormal];
        [cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.navView).offset(navSpace);
            make.top.bottom.equalTo(self.navView);
            make.width.offset(cleanString.length*viewBtnFont.pointSize+10);
        }];
    }
}

- (void)cancelAction {
    [self hide];
}

- (void)show {
    [UIView animateWithDuration:0.5 animations:^{
        UIWindow* window = [UIApplication sharedApplication].keyWindow;
        [window addSubview:self];
        [self setupView];
    }];
}

- (void)onSignatureWriteAction {
    [self.btn3 setTitleColor:kRGBAColor(255, 255, 255, 1) forState:UIControlStateNormal];
    switch ([UIApplication sharedApplication].statusBarOrientation) {
        case UIInterfaceOrientationLandscapeRight:
        {
            [clearBtn setTitleColor:kRGBAColor(255, 255, 255, 1) forState:UIControlStateNormal];
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:
        {
            [clearBtn setTitleColor:kRGBAColor(255, 255, 255, 1) forState:UIControlStateNormal];
        }
            break;
        default:
        {
            [clearBtn setTitleColor:kRGBAColor(155, 155, 155, 1) forState:UIControlStateNormal];
        }
            break;
    }
    navTitle.hidden = NO;
}

- (void)hide
{
    if ([self.delegate respondsToSelector:@selector(cancelSign)]) {
        [self.delegate cancelSign];
    }
    [UIView animateWithDuration:0.3 animations:^{
        [self.backGroundView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.bottom.equalTo(self.maskView);
        }];
        self.alpha = 0;
    } completion:^(BOOL finished){
        
        [self removeFromSuperview];
    }];
}


- (void)onTapMaskView:(id)sender {
    [self hide];
}


//清除
- (void)onClear {
    [self.signatureView clear];
    [self.btn3 setTitleColor:kRGBAColor(255, 255, 255, 0.5) forState:UIControlStateNormal];
    [clearBtn setTitleColor:kRGBAColor(255, 255, 255, 0.5) forState:UIControlStateNormal];
    navTitle.hidden = YES;
}

- (void)okAction
{
     [self.signatureView sure];
    if(self.signatureView.SignatureImg)
    {
        self.hidden = YES;
        [self hide];
        if (self.delegate != nil &&[self.delegate respondsToSelector:@selector(onSubmitBtn:)]) {
            [self.delegate onSubmitBtn:self.signatureView.SignatureImg];
        }
    }
    else
    {
        PNSLog(@"NoImage");
    }
}


@end
