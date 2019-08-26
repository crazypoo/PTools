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
#import <pop/POP.h>
#import "UIView+ViewRectCorner.h"

#define AlertRadius 8
#define AlertLine 0.5

@interface YXCustomAlertView()
{
    UIColor *alertTitleColor;
}

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, copy) YXCustomAlertViewSetCustomViewBlock setBlock;
@property (nonatomic, copy) YXCustomAlertViewClickBlock clickBlock;
@property (nonatomic, copy) YXCustomAlertViewDidDismissBlock didDismissBlock;
@property (nonatomic, strong) UIView *superViews;
@property (nonatomic, strong) NSMutableArray *alertBottomButtonColor;
@property (nonatomic, strong) UIFont *viewFont;
@property (nonatomic, strong) UIColor *verLineColor;
@property (nonatomic, strong) NSMutableArray *bottomBtnArr;
@property (nonatomic, strong) NSString *titleStr;
@property (nonatomic, assign) AlertAnimationType viewAnimationType;
@property (nonatomic, strong) UIColor *alertViewBackgroundColor;
@property (nonatomic, strong) UIColor *heightlightedColorColor;
@end


@implementation YXCustomAlertView

+(CGFloat)titleAndBottomViewNormalHeighEXAlertW:(CGFloat)w
                                      withTitle:(NSString * _Nonnull)title
                                  withTitleFont:(UIFont *)tf
                                  withButtonArr:(NSArray *)btns
{
    
    UIFont *titleAndBottomFont = tf ? tf : kDEFAULT_FONT(kDevLikeFont, 18);
    
    CGFloat titleH = 0.0f;
    if (titleAndBottomFont.pointSize*title.length > w)
    {
        titleH = [Utils sizeForString:title font:titleAndBottomFont andHeigh:CGFLOAT_MAX andWidth:w].height;
    }
    else
    {
        titleH = TitleViewH;
    }
    
    CGFloat btnW = (w - (btns.count-1)*AlertLine)/btns.count;
    BOOL isEX = NO;
    for (NSString *string in btns) {
        if ((tf.pointSize*string.length+10) > btnW) {
            isEX = YES;
            break;
        }
        else
        {
            isEX = NO;
        }
    }
    return isEX ? (titleH + BottomButtonH * btns.count + AlertLine * btns.count) : (titleH + BottomButtonH + AlertLine);
}

- (instancetype _Nonnull ) initAlertViewWithSuperView:(UIView * _Nonnull)superView
                                           alertTitle:(NSString * _Nullable)title
                               withButtonAndTitleFont:(UIFont * _Nullable)btFont
                                           titleColor:(UIColor * _Nullable)tColor
                               bottomButtonTitleColor:(NSArray <UIColor *>* _Nullable)bbtColor
                                         verLineColor:(UIColor * _Nullable)vlColor
                             alertViewBackgroundColor:(UIColor * _Nullable)aBGColor
                                   heightlightedColor:(UIColor * _Nullable)heightlightedColorColor
                                 moreButtonTitleArray:(NSArray * _Nonnull)mbtArray
                                              viewTag:(NSInteger)tag
                                        viewAnimation:(AlertAnimationType)animationType
                                      touchBackGround:(BOOL)canTouch
                                        setCustomView:(YXCustomAlertViewSetCustomViewBlock _Nonnull )setViewBlock
                                          clickAction:(YXCustomAlertViewClickBlock _Nonnull )clickBlock
                                      didDismissBlock:(YXCustomAlertViewDidDismissBlock _Nonnull )didDismissBlock
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
        [superView addSubview:self.middleView];
        [self.middleView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.bottom.equalTo(superView);
        }];
        
        self.viewFont = btFont ? btFont : kDEFAULT_FONT(kDevLikeFont, 18);
        alertTitleColor = tColor ? tColor : kRGBColor(0 , 84, 166);
        
        self.alertBottomButtonColor = [NSMutableArray array];
        
        if (kArrayIsEmpty(bbtColor)) {
            for (int i = 0; i < mbtArray.count; i++) {
                [self.alertBottomButtonColor addObject:kRGBColor(0 , 84, 166)];
            }
        }
        else if (bbtColor.count == 1)
        {
            for (int i = 0; i < mbtArray.count; i++) {
                [self.alertBottomButtonColor addObject:bbtColor[0]];
            }
        }
        else
        {
            for (int i = 0; i < mbtArray.count; i++) {
                [self.alertBottomButtonColor addObject:bbtColor[i]];
            }
        }
        self.verLineColor = vlColor ? vlColor : kRGBColor(213, 213, 215);
        self.tag = tag;
        self.titleStr = title;
        self.alertViewBackgroundColor = aBGColor ? aBGColor : [UIColor whiteColor];
        self.heightlightedColorColor = heightlightedColorColor ? heightlightedColorColor : kDevButtonHighlightedColor;
        
        if (canTouch)
        {
            UITapGestureRecognizer *tapBackgroundView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dissMiss)];
            tapBackgroundView.numberOfTouchesRequired = 1;
            tapBackgroundView.numberOfTapsRequired = 1;
            [self.middleView addGestureRecognizer:tapBackgroundView];
        }
        
        self.backgroundColor = self.alertViewBackgroundColor;
        self.layer.cornerRadius = AlertRadius;
        
        [self.superViews addSubview:self];
        
        self.viewAnimationType = animationType;
        
        NSString *propertyNamed;
        CATransform3D transform = CATransform3DMakeTranslation(0, 0, 0);
        switch (animationType) {
            case AlertAnimationTypeTop:
            {
                propertyNamed = kPOPLayerTranslationY;
                transform = CATransform3DMakeTranslation(0, -(kSCREEN_HEIGHT/2), 0);
            }
                break;
            case AlertAnimationTypeBottom:
            {
                propertyNamed = kPOPLayerTranslationY;
                transform = CATransform3DMakeTranslation(0, kSCREEN_HEIGHT/2, 0);
            }
                break;
            case AlertAnimationTypeLeft:
            {
                propertyNamed = kPOPLayerTranslationX;
                transform = CATransform3DMakeTranslation(-(kSCREEN_WIDTH/2), 0, 0);
            }
                break;
            case AlertAnimationTypeRight:
            {
                propertyNamed = kPOPLayerTranslationX;
                transform = CATransform3DMakeTranslation((kSCREEN_WIDTH/2), 0, 0);
            }
                break;
            default:
            {
                propertyNamed = kPOPLayerTranslationX;
                transform = CATransform3DMakeTranslation(0, 0, 0);
            }
                break;
        }
        
        POPSpringAnimation *animation = [POPSpringAnimation animationWithPropertyNamed:propertyNamed];
        self.layer.transform = transform;
        animation.toValue = @(0);
        animation.springBounciness = 1.0f;
        [self.layer pop_addAnimation:animation forKey:@"AlertAnimation"];


        self.titleLabel.text = title;
        [self addSubview:self.titleLabel];
        
        self.customView = [UIView new];
        [self addSubview:self.customView];
        
        if (self.setBlock) {
            self.setBlock(self);
        }
    }
    
    return self;
}

-(void)setBottomView
{
    CGFloat btnW = (self.frame.size.width - (self.bottomBtnArr.count-1)*AlertLine)/self.bottomBtnArr.count;
    BOOL isEX = NO;
    for (NSString *string in self.bottomBtnArr) {
        if ((self.viewFont.pointSize*string.length+10) > btnW) {
            isEX = YES;
            break;
        }
        else
        {
            isEX = NO;
        }
    }
    
    UIView *btnView = [UIView new];
    btnView.backgroundColor = self.verLineColor;
    [self addSubview:btnView];
    [btnView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.top.equalTo(self.customView.mas_bottom);
    }];
    kViewBorderRadius(btnView, AlertRadius, 0, kClearColor);

    for (int i = 0 ; i < self.bottomBtnArr.count; i++) {
        UIButton *cancelBtn =  [UIButton buttonWithType:UIButtonTypeCustom];
        [cancelBtn setBackgroundImage:[Utils createImageWithColor:self.alertViewBackgroundColor] forState:UIControlStateNormal];
        [cancelBtn setBackgroundImage:[Utils createImageWithColor:self.heightlightedColorColor] forState:UIControlStateHighlighted];
        [cancelBtn setTitleColor:self.alertBottomButtonColor[i] forState:UIControlStateNormal];
        [cancelBtn setTitle:self.bottomBtnArr[i] forState:UIControlStateNormal];
        cancelBtn.titleLabel.font = self.viewFont;
        cancelBtn.tag = 100+i;
        [cancelBtn addTarget:self action:@selector(confirmBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        [btnView addSubview:cancelBtn];
        [cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            if (isEX)
            {
                make.left.right.equalTo(btnView);
                make.top.equalTo(btnView).offset(HEIGHT_BUTTON*i+AlertLine*i+AlertLine);
                make.height.offset(HEIGHT_BUTTON);
            }
            else
            {
                make.width.offset(btnW);
                make.top.equalTo(btnView).offset(AlertLine);
                make.bottom.equalTo(btnView);
                make.left.offset(btnW*i+AlertLine*i);
            }
        }];
    }
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat textH;
    if (self.viewFont.pointSize*self.titleLabel.text.length > self.frame.size.width)
    {
        textH = [Utils sizeForString:self.titleLabel.text font:self.viewFont andHeigh:CGFLOAT_MAX andWidth:self.frame.size.width].height;
    }
    else
    {
        textH = TitleViewH;
    }

    [self.titleLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.offset(textH);
        make.top.left.right.equalTo(self);
    }];
    
    CGFloat btnW = (self.frame.size.width - (self.bottomBtnArr.count-1)*AlertLine)/self.bottomBtnArr.count;
    BOOL isEX = NO;
    for (NSString *string in self.bottomBtnArr) {
        if ((self.viewFont.pointSize*string.length+10) > btnW) {
            isEX = YES;
            break;
        }
        else
        {
            isEX = NO;
        }
    }
    
    CGFloat bottomH = isEX ? BottomButtonH * self.bottomBtnArr.count + AlertLine * self.bottomBtnArr.count: BottomButtonH + AlertLine;
    
    [self.customView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom);
        make.bottom.equalTo(self).offset(-bottomH);
        make.left.right.equalTo(self);
    }];
    
    [self setBottomView];
}

#pragma mark - Action
- (void)confirmBtnClick:(UIButton *)sender
{
    if (self.clickBlock) {
        self.clickBlock(self, sender.tag-100);
    }
}

#pragma mark - 注销视图
- (void) dissMiss
{
    if (self.didDismissBlock) {
        self.didDismissBlock(self);
    }
    
    NSString *propertyNamed;
    CGFloat offsetValue = 0.0f;
    switch (self.viewAnimationType) {
        case AlertAnimationTypeTop:
        {
            propertyNamed = kPOPLayerTranslationY;
            offsetValue = -self.layer.position.y;
        }
            break;
        case AlertAnimationTypeBottom:
        {
            propertyNamed = kPOPLayerTranslationY;
            offsetValue = self.layer.position.y;
        }
            break;
        case AlertAnimationTypeLeft:
        {
            propertyNamed = kPOPLayerTranslationX;
            offsetValue = -self.layer.position.x-self.frame.size.width/2;
        }
            break;
        case AlertAnimationTypeRight:
        {
            propertyNamed = kPOPLayerTranslationX;
            offsetValue = self.layer.position.x+self.frame.size.width/2;
        }
            break;
        default:
        {
            propertyNamed = kPOPLayerTranslationX;
            offsetValue = -self.layer.position.x;
        }
            break;
    }

    POPBasicAnimation *offscreenAnimation = [POPBasicAnimation easeOutAnimation];
    offscreenAnimation.property = [POPAnimatableProperty propertyWithName:propertyNamed];
    offscreenAnimation.toValue = @(offsetValue);
    offscreenAnimation.duration = 0.35f;
    [offscreenAnimation setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        [UIView animateWithDuration:0.35f delay:0 usingSpringWithDamping:0.9f initialSpringVelocity:0.7f options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionLayoutSubviews animations:^{
            self.middleView.alpha = 0;
            self.alpha = 0;
        } completion:^(BOOL finished) {
            if (self.middleView) {
                [self.middleView removeFromSuperview];
                self.middleView = nil;
            }
            [self removeFromSuperview];
        }];
    }];
    [self.layer pop_addAnimation:offscreenAnimation forKey:@"offscreenAnimation"];
}

#pragma mark - getter And setter

- (UIView *) middleView
{
    if (_middleView == nil) {
        _middleView = [[UIView alloc] init];
        _middleView.backgroundColor = kDevMaskBackgroundColor;
    }
    
    return _middleView;
}

- (UILabel *) titleLabel{
    
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = self.viewFont;
        _titleLabel.textColor = alertTitleColor;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _titleLabel.numberOfLines = 0;
        _titleLabel.backgroundColor = kClearColor;
    }
    
    return _titleLabel;
}
@end
