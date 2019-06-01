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
#import "NSString+WPAttributedMarkup.h"
#import "PMacros.h"

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
@property (nonatomic,strong) UIButton *cancelBtn;
@property (nonatomic,strong) EasySignatureView *signatureView;
@property (nonatomic,copy) PooSignDoneBlock doneBlock;
@property (nonatomic,copy) PooSignCancelBlock cancelBlock;

@end

@implementation PopSignatureView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        self.frame =CGRectMake(0, 0, kSCREEN_WIDTH, kSCREEN_HEIGHT);
        self.backgroundColor = kDevMaskBackgroundColor;
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

-(instancetype)initWithNavColor:(UIColor *)navC maskString:(NSString *)mString withViewFontName:(NSString *)fName withNavFontName:(NSString *)nfName handleDone:(PooSignDoneBlock)doneBlock handleCancle:(PooSignCancelBlock)cancelBlock
{
    self = [super init];
    if (self)
    {
        self.navColor = navC;
        self.maskString = mString;
        self.fontName = fName;
        self.navFontName = nfName;
        self.doneBlock = doneBlock;
        self.cancelBlock = cancelBlock;
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
    self.maskView.backgroundColor = kDevMaskBackgroundColor;
    self.maskView.userInteractionEnabled = YES;
    [self addSubview:self.maskView];
    
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
    
    NSString *cleanString = @"清除";
    clearBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    clearBtn.titleLabel.font = viewBtnFont;
    [clearBtn setTitle:cleanString forState:UIControlStateNormal];
    [clearBtn addTarget:self action:@selector(onClear) forControlEvents:UIControlEventTouchUpInside];
    [clearBtn setTitleColor:kRGBAColor(255, 255, 255, 0.5) forState:UIControlStateNormal];
    [self.navView addSubview:clearBtn];

    self.cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.cancelBtn.titleLabel.font = viewBtnFont;
    [self.cancelBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.navView addSubview:self.cancelBtn];
    
    self.btn3 = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btn3 setTitle:@"提交" forState:UIControlStateNormal];
    [self.btn3 setTitleColor:kRGBAColor(255, 255, 255, 0.5) forState:UIControlStateNormal];
    self.btn3.titleLabel.font = viewBtnFont;
    self.btn3.backgroundColor = self.navColor ? self.navColor : kRandomColor;
    [self.btn3 addTarget:self action:@selector(okAction) forControlEvents:UIControlEventTouchUpInside];
    [self.backGroundView addSubview:self.btn3];
    
    [self layoutIfNeeded];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.maskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(self);
    }];
    
    CGFloat navSpace = 10;
    NSString *cleanString = @"清除";
    UIFont *viewBtnFont = kDEFAULT_FONT(self.fontName ? self.fontName : kDevLikeFont, 16);

    UIDevice *device = [UIDevice currentDevice];
    if (device.orientation == UIDeviceOrientationLandscapeLeft || device.orientation ==  UIDeviceOrientationLandscapeRight)
    {
        [self.backGroundView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.bottom.equalTo(self.maskView);
        }];
        
        [self.btn3 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.backGroundView);
            make.bottom.equalTo(self.backGroundView).offset(isIPhoneXSeries() ? -20 : 0);
            make.height.offset(HEIGHT_BUTTON);
        }];
        
        [self.navView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.equalTo(self.backGroundView);
            make.height.offset(HEIGHT_BUTTON);
        }];
        
        [self.signatureView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.backGroundView);
            make.bottom.equalTo(self.btn3.mas_top);
            make.top.equalTo(self.navView.mas_bottom);
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
        
        [self.cancelBtn setTitle:@"返回" forState:UIControlStateNormal];
        [self.cancelBtn addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        [self.cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.navView).offset(navSpace);
            make.top.bottom.equalTo(self.navView);
            make.width.offset(cleanString.length*viewBtnFont.pointSize+10);
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
            make.bottom.equalTo(self.backGroundView).offset(isIPhoneXSeries() ? (-HEIGHT_TABBAR_SAFEAREA) : 0);
            make.height.offset(HEIGHT_BUTTON);
        }];
        
        [self.signatureView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.backGroundView);
            make.height.offset(216);
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
        
        [self.cancelBtn setTitle:@"签名" forState:UIControlStateNormal];
        [self.cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.navView).offset(navSpace);
            make.top.bottom.equalTo(self.navView);
            make.width.offset(cleanString.length*viewBtnFont.pointSize+10);
        }];
    }
}

- (void)cancelAction
{
    [self hide];
}

- (void)show
{
    [kAppDelegateWindow addSubview:self];
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(kAppDelegateWindow);
    }];
    [self setupView];
}

- (void)onSignatureWriteAction
{
    [self.btn3 setTitleColor:kRGBAColor(255, 255, 255, 1) forState:UIControlStateNormal];
    switch ([UIApplication sharedApplication].statusBarOrientation) {
        case UIInterfaceOrientationLandscapeRight:
        {
            [clearBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:
        {
            [clearBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
            break;
        default:
        {
            [clearBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
            break;
    }
    navTitle.hidden = NO;
}

- (void)hide
{
    if (self.cancelBlock) {
        self.cancelBlock(self);
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

- (void)onTapMaskView:(id)sender
{
    [self hide];
}

//清除
- (void)onClear
{
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
        if (self.doneBlock)
        {
            self.doneBlock(self, self.signatureView.SignatureImg);
        }
    }
    else
    {
        PNSLog(@"NoImage");
    }
}


@end
