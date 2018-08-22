//
//  YXCustomAlertView.m
//  YXCustomAlertView
//
//  Created by Houhua Yan on 16/7/12.
//  Copyright © 2016年 YanHouhua. All rights reserved.

//

#import "YXCustomAlertView.h"
#import "PMacros.h"
#import <Masonry/Masonry.h>

@interface YXCustomAlertView()
{
    UIColor *alertTitleColor;
}

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, copy) YXCustomAlertViewSetCustomViewBlock setBlock;
@property (nonatomic, copy) YXCustomAlertViewClickBlock clickBlock;
@property (nonatomic, copy) YXCustomAlertViewDidDismissBlock didDismissBlock;
@property (nonatomic, strong) UIView *superViews;
@property (nonatomic, strong) UIColor *alertBottomButtonColor;
@property (nonatomic, strong) UIFont *viewFont;
@property (nonatomic, strong) UIColor *verLineColor;
@property (nonatomic, strong) NSMutableArray *bottomBtnArr;
@property (nonatomic, strong) NSString *titleStr;
@end


@implementation YXCustomAlertView

+(CGFloat)titleAndBottomViewNormalH
{
    return TitleViewH + BottomButtonH;
}

- (instancetype) initAlertViewWithSuperView:(UIView *)superView alertTitle:(NSString *)title withButtonAndTitleFont:(UIFont *)btFont titleColor:(UIColor * _Nonnull)tColor bottomButtonTitleColor:(UIColor * _Nullable )bbtColor verLineColor:(UIColor * _Nullable )vlColor moreButtonTitleArray:(NSArray * _Nonnull)mbtArray viewTag:(NSInteger)tag setCustomView:(YXCustomAlertViewSetCustomViewBlock)setViewBlock clickAction:(YXCustomAlertViewClickBlock)clickBlock didDismissBlock:(YXCustomAlertViewDidDismissBlock)didDismissBlock
{
    self = [super init];
    
    if (self) {
        
        self.bottomBtnArr = [NSMutableArray array];
        [self.bottomBtnArr addObjectsFromArray:mbtArray];
        
        self.clickBlock = clickBlock;
        self.didDismissBlock = didDismissBlock;
        self.superViews = superView;
        self.setBlock = setViewBlock;
        
        self.middleView.frame = superView.frame;
        [superView addSubview:_middleView];
        [_middleView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.bottom.equalTo(superView);
        }];
        
        self.viewFont = btFont;
        alertTitleColor = tColor;
        self.alertBottomButtonColor = bbtColor;
        self.verLineColor = vlColor;
        self.tag = tag;
        self.titleStr = title;
        
        UITapGestureRecognizer *tapBackgroundView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dissMiss)];
        tapBackgroundView.numberOfTouchesRequired = 1;
        tapBackgroundView.numberOfTapsRequired = 1;
        [_middleView addGestureRecognizer:tapBackgroundView];

        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 8;
        
        [self.superViews addSubview:self];

        self.titleLabel.text = title;
        [self addSubview:_titleLabel];

        self.customView = [UIView new];
        [self addSubview:self.customView];

        if (btFont.pointSize*title.length > self.frame.size.width) {
            [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.height.offset(TitleViewH*2);
                make.top.left.right.equalTo(self);
            }];
            [self.customView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.titleLabel.mas_bottom);
                make.bottom.equalTo(self).offset(-BottomButtonH);
                make.left.right.equalTo(self);
            }];
            
        }
        else{
            [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.height.offset(TitleViewH);
                make.left.top.right.equalTo(self);
            }];
            [self.customView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.titleLabel.mas_bottom);
                make.bottom.equalTo(self).offset(-BottomButtonH);
                make.left.right.equalTo(self);
            }];
        }

        
        if (self.setBlock) {
            self.setBlock(self);
        }
        [self setBottomView];
    }
    
    return self;
}

-(void)setBottomView
{
    CGFloat btnW = (self.frame.size.width - (self.bottomBtnArr.count-1)*0.5)/self.bottomBtnArr.count;
    for (int i = 0 ; i < self.bottomBtnArr.count; i++) {
        UIButton *cancelBtn =  [UIButton buttonWithType:UIButtonTypeCustom];
        [cancelBtn setTitleColor:self.alertBottomButtonColor ? self.alertBottomButtonColor : kRGBColor(0 , 84, 166) forState:UIControlStateNormal];
        [cancelBtn setTitle:self.bottomBtnArr[i] forState:UIControlStateNormal];
        cancelBtn.titleLabel.font = self.viewFont;
        cancelBtn.tag = 100+i;
        [cancelBtn addTarget:self action:@selector(confirmBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:cancelBtn];
        [cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.offset(btnW);
            make.top.equalTo(self.customView.mas_bottom);
            make.bottom.equalTo(self);
            make.left.offset(btnW*i+1*i);
        }];
    }
    
    if (self.bottomBtnArr.count != 1) {
        for (int j = 0; j < (self.bottomBtnArr.count-1); j++) {
            UIView *verLine = [UIView new];
            verLine.backgroundColor = self.verLineColor ? self.verLineColor : kRGBColor(213, 213, 215);
            verLine.tag = 200 + j;
            [self addSubview:verLine];
            [verLine mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.offset(btnW+0.5*j+btnW*j);
                make.top.equalTo(self.customView.mas_bottom);
                make.bottom.equalTo(self);
                make.width.offset(0.5);
            }];
        }
    }

    
    UIView *horLine = [UIView new];
    horLine.backgroundColor = self.verLineColor ? self.verLineColor : kRGBColor(213, 213, 215);
    horLine.tag = 1000;
    [self addSubview:horLine];
    [horLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self);
        make.top.equalTo(self.customView.mas_bottom);
        make.height.offset(0.5);
    }];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat textH;
    UIDeviceOrientation o = [[UIDevice currentDevice] orientation];
    switch (o) {
        case UIDeviceOrientationLandscapeLeft:      // Device oriented horizontally, home button on the right
        {
            textH = TitleViewH;
        }
            break;
        case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
        {
            textH = TitleViewH;
        }
            break;
        default:
        {
            if (self.viewFont.pointSize*self.titleLabel.text.length > self.frame.size.width) {
                textH = TitleViewH*2;
            }
            else
            {
                textH = TitleViewH;
            }
        }
            break;
    }
    [self.titleLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.offset(textH);
        make.top.left.right.equalTo(self);
    }];
    [self.customView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom);
        make.bottom.equalTo(self).offset(-BottomButtonH);
        make.left.right.equalTo(self);
    }];
    CGFloat btnW = (self.frame.size.width - (self.bottomBtnArr.count-1)*0.5)/self.bottomBtnArr.count;
    for (int i = 0; i < self.bottomBtnArr.count; i++) {
        UIButton *cancelBtn =  (UIButton *)[self viewWithTag:100+i];
        [cancelBtn mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.offset(btnW);
            make.top.equalTo(self.customView.mas_bottom);
            make.bottom.equalTo(self);
            make.left.offset(btnW*i+1*i);
        }];
    }
    
    for (int j = 0; j < (self.bottomBtnArr.count-1); j++)
    {
        UIView *verLine =  (UIView *)[self viewWithTag:200+j];
        [verLine mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.offset(btnW+0.5*j+btnW*j);
            make.top.equalTo(self.customView.mas_bottom);
            make.bottom.equalTo(self);
            make.width.offset(0.5);
        }];
    }
    
    UIView *horLine = (UIView *)[self viewWithTag:1000];
    [horLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self);
        make.top.equalTo(self.customView.mas_bottom);
        make.height.offset(0.5);
    }];
}

#pragma mark - Action
- (void)confirmBtnClick:(UIButton *)sender
{
    if (self.clickBlock) {
        self.clickBlock(self, sender.tag-100);
    }
}

-(void)showView
{
    [self.superViews addSubview:self];
}

#pragma mark - 注销视图
- (void) dissMiss
{
    
    if (self.didDismissBlock) {
        self.didDismissBlock(self);
    }
    
    if (_middleView) {
        [_middleView removeFromSuperview];
        _middleView = nil;
    }
    
    [self removeFromSuperview];
}

#pragma mark - getter And setter

- (UIView *) middleView
{
    if (_middleView == nil) {
        _middleView = [[UIView alloc] init];
        _middleView.backgroundColor = [UIColor blackColor];
        _middleView.alpha = 0.65;
    }
    
    return _middleView;
}

- (UILabel *) titleLabel{
    
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = self.viewFont;
        _titleLabel.textColor = alertTitleColor ? alertTitleColor : kRGBColor(0 , 84, 166);
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _titleLabel.numberOfLines = 0;
        _titleLabel.backgroundColor = kClearColor;
    }
    
    return _titleLabel;
}
@end
