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
    UIFont *viewFont;
    UIColor *alertTitleColor;
    UIColor *alertBottomButtonColor;
    UIColor *verLineColor;
    UIView *verLine;
}

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, copy) YXCustomAlertViewSetCustomViewBlock setBlock;
@property (nonatomic, copy) YXCustomAlertViewClickBlock clickBlock;
@property (nonatomic, copy) YXCustomAlertViewDidDismissBlock didDismissBlock;
@property (nonatomic, strong) UIView *superViews;
@end


@implementation YXCustomAlertView


- (instancetype) initAlertViewWithFrame:(CGRect)frame andSuperView:(UIView *)superView alertTitle:(NSString *)title withButtonAndTitleFont:(UIFont *)btFont titleColor:(UIColor * _Nonnull)tColor bottomButtonTitleColor:(UIColor * _Nullable )bbtColor verLineColor:(UIColor * _Nullable )vlColor moreButtonTitleArray:(NSArray * _Nonnull)mbtArray viewTag:(NSInteger)tag setCustomView:(YXCustomAlertViewSetCustomViewBlock)setViewBlock clickAction:(YXCustomAlertViewClickBlock)clickBlock didDismissBlock:(YXCustomAlertViewDidDismissBlock)didDismissBlock
{
    self = [super init];
    
    if (self) {
        self.clickBlock = clickBlock;
        self.didDismissBlock = didDismissBlock;
        self.superViews = superView;
        self.setBlock = setViewBlock;
        
        self.middleView.frame = superView.frame;
        [superView addSubview:_middleView];
        viewFont = btFont;
        alertTitleColor = tColor;
        alertBottomButtonColor = bbtColor;
        verLineColor = vlColor;
        self.tag = tag;
        
        UITapGestureRecognizer *tapBackgroundView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dissMiss)];
        tapBackgroundView.numberOfTouchesRequired = 1;
        tapBackgroundView.numberOfTapsRequired = 1;
        [_middleView addGestureRecognizer:tapBackgroundView];

        
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 8;
        
        self.titleLabel.text = title;
        [self addSubview:_titleLabel];

        self.customView = [UIView new];
        [self addSubview:self.customView];
        
        if (btFont.pointSize*title.length > frame.size.width) {
            self.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height+TitleViewH);
            [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.offset(frame.size.width);
                make.height.offset(TitleViewH*2);
                make.top.equalTo(self);
                make.left.equalTo(self);
            }];
            [self.customView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.offset(frame.size.width);
                make.top.equalTo(self.titleLabel.mas_bottom);
                make.bottom.equalTo(self).offset(-BottomButtonH);
                make.left.equalTo(self);
            }];

        }
        else{
            self.frame = frame;
            [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.offset(frame.size.width);
                make.height.offset(TitleViewH);
                make.top.equalTo(self);
                make.left.equalTo(self);
            }];
            [self.customView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.offset(frame.size.width);
                make.top.equalTo(self.titleLabel.mas_bottom);
                make.bottom.equalTo(self).offset(-BottomButtonH);
                make.left.equalTo(self);
            }];
        }
        self.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2, superView.frame.size.height/2);

        
        if (self.setBlock) {
            self.setBlock(self);
        }
        
        CGFloat btnW = (frame.size.width - (mbtArray.count-1)*0.5)/mbtArray.count;
        for (int i = 0 ; i < mbtArray.count; i++) {
            UIButton *cancelBtn =  [UIButton buttonWithType:UIButtonTypeCustom];
            cancelBtn.frame = frame;
            if (alertBottomButtonColor == nil) {
                [cancelBtn setTitleColor:kRGBColor(0 , 84, 166) forState:UIControlStateNormal];
            }
            else
            {
                [cancelBtn setTitleColor:alertBottomButtonColor forState:UIControlStateNormal];
            }
            [cancelBtn setTitle:mbtArray[i] forState:UIControlStateNormal];
            cancelBtn.titleLabel.font = viewFont;
            cancelBtn.tag = i;
            [cancelBtn addTarget:self action:@selector(confirmBtnClick:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:cancelBtn];
            [cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.offset(btnW);
                make.top.equalTo(self.customView.mas_bottom);
                make.bottom.equalTo(self);
                make.left.offset(btnW*i+1*i);
            }];
            
        }
        
        if (mbtArray.count != 1) {
            for (int j = 0; j < (mbtArray.count-1); j++) {
                verLine = [UIView new];
                if (verLineColor == nil) {
                    verLine.backgroundColor = kRGBColor(213, 213, 215);
                }
                else
                {
                    verLine.backgroundColor = verLineColor;
                }
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
        horLine.backgroundColor = verLine.backgroundColor;
        [self addSubview:horLine];
        [horLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self);
            make.top.equalTo(self.customView.mas_bottom);
            make.height.offset(0.5);
        }];

    }
    
    return self;
    
}

#pragma mark - Action
- (void)confirmBtnClick:(UIButton *)sender
{
    if (self.clickBlock) {
        self.clickBlock(self, sender.tag);
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
        _titleLabel.font = viewFont;
        _titleLabel.textColor = alertTitleColor;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _titleLabel.numberOfLines = 0;
        _titleLabel.backgroundColor = [UIColor clearColor];
    }
    
    return _titleLabel;
}


@end
