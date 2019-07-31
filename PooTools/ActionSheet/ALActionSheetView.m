//
//  ALActionSheetView.m
//  ALActionSheetView
//
//  Created by WangQi on 7/4/15.
//  Copyright (c) 2015 WangQi. All rights reserved.
//

#import "ALActionSheetView.h"
#import "PMacros.h"
#import <Masonry/Masonry.h>
#import "Utils.h"
#import <pop/POP.h>

#define kRowHeight 44.0f
#define kRowLineHeight 0.5f
#define kSeparatorHeight 5.0f

#define kTitleFontSize 13.0f
#define kButtonTitleFontSize 17.0f

@interface ALActionSheetView ()
{
    BOOL        _isShow;
}

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *titleMessage;
@property (nonatomic, copy) NSString *cancelButtonTitle;
@property (nonatomic, copy) NSString *destructiveButtonTitle;
@property (nonatomic, copy) NSArray *otherButtonTitles;
@property (nonatomic, copy) ALActionSheetViewDidSelectButtonBlock selectRowBlock;
@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) UIView *actionSheetView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, copy) NSString *btnFontName;
@property (nonatomic, strong) UIScrollView *actionSheetScroll;
@property (nonatomic, strong) UIButton *destructiveButton;
@property (nonatomic, strong) UIView *separatorView;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIColor *singleCellBGColor;
@property (nonatomic, strong) UIColor *normalTitleColor;
@property (nonatomic, strong) UIColor *destructiveTitleColor;
@property (nonatomic, strong) UIColor *titleCellTitleColor;
@property (nonatomic, strong) UIColor *separatorColor;
@property (nonatomic, strong) UIColor *heightlightColor;
@end


@implementation ALActionSheetView

- (void)dealloc
{
    self.title= nil;
    self.titleMessage = nil;
    self.cancelButtonTitle = nil;
    self.destructiveButtonTitle = nil;
    self.otherButtonTitles = nil;
    self.selectRowBlock = nil;
    self.actionSheetView = nil;
    self.backView = nil;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        CGRect frame = [UIScreen mainScreen].bounds;
        self.frame = frame;
    }
    
    return self;
}

- (instancetype)initWithTitle:(NSString *)title
                 titleMessage:(NSString *)titleMessage
            cancelButtonTitle:(NSString *)cancelButtonTitle
       destructiveButtonTitle:(NSString *)destructiveButtonTitle
            otherButtonTitles:(NSArray *)otherButtonTitles
               buttonFontName:(NSString *)bfName
    singleCellBackgroundColor:(UIColor *)cellBGColor
         normalCellTitleColor:(UIColor *)normalTitleColor
    destructiveCellTitleColor:(UIColor *)destructiveTitleColor
          titleCellTitleColor:(UIColor *)titleCellTitleColor
               separatorColor:(UIColor *)separatorColor
             heightlightColor:(UIColor *)heightlightColor
                      handler:(ALActionSheetViewDidSelectButtonBlock)block;
{
    self = [self init];
    
    if (self)
    {
        _title = title;
        self.titleMessage = titleMessage;
        _cancelButtonTitle = cancelButtonTitle;
        _destructiveButtonTitle = destructiveButtonTitle;
        _otherButtonTitles = otherButtonTitles;
        _selectRowBlock = block;
        self.btnFontName = bfName ? bfName : kDevLikeFont;
        self.singleCellBGColor = cellBGColor ? cellBGColor : kRandomColor;
        self.normalTitleColor = normalTitleColor ? normalTitleColor : kRandomColor;
        self.destructiveTitleColor = destructiveTitleColor ? destructiveTitleColor : kRGBAColor(255, 10, 10, 1);
        self.titleCellTitleColor = titleCellTitleColor ? titleCellTitleColor : kRGBAColor(111, 111, 111, 1);
        self.separatorColor = separatorColor ? separatorColor : kRGBAColor(230, 230, 230, 1);
        self.heightlightColor = heightlightColor ? heightlightColor : kDevButtonHighlightedColor;
        
        if (@available(iOS 13.0, *))
        {
            [Utils alertVCWithTitle:title message:titleMessage cancelTitle:cancelButtonTitle okTitle:nil destructiveTitle:destructiveButtonTitle otherButtonArray:otherButtonTitles shouIn:kAppDelegateWindow.rootViewController alertStyle:UIAlertControllerStyleActionSheet okAction:^{
                
            } cancelAction:^{
                self.selectRowBlock(self, -1);
            } destructiveAction:^{
                
                if (!kStringIsEmpty(destructiveButtonTitle))
                {
                    self.selectRowBlock(self, 0);
                }
                
            } otherButtonAction:^(NSInteger index) {
                if (!kStringIsEmpty(destructiveButtonTitle))
                {
                    self.selectRowBlock(self, index+1);
                }
                else
                {
                    self.selectRowBlock(self, index);
                }
            }];
        }
        else
        {
            [self createView];
        }
    }
    
    return self;
}

-(void)createView
{
    [kAppDelegateWindow addSubview:self];
    
    _backView = [UIView new];
    _backView.backgroundColor = kDevMaskBackgroundColor;
    [self addSubview:_backView];

    self.actionSheetView = [UIView new];
    self.actionSheetView.backgroundColor = self.separatorColor;
    [self addSubview:self.actionSheetView];
    
    self.actionSheetScroll = [UIScrollView new];
    [self.actionSheetView addSubview:self.actionSheetScroll];

    if (_title && _title.length>0)
    {
        self.titleLabel = [UILabel new];
        self.titleLabel.backgroundColor = self.singleCellBGColor;
        self.titleLabel.textColor = self.titleCellTitleColor;
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = kDEFAULT_FONT(self.btnFontName, kTitleFontSize);
        self.titleLabel.numberOfLines = 0;
        if (kStringIsEmpty(self.titleMessage))
        {
            self.titleLabel.text = [NSString stringWithFormat:@"%@",_title];
        }
        else
        {
            self.titleLabel.text = [NSString stringWithFormat:@"%@\n%@",_title,self.titleMessage];
        }
        [self.actionSheetView addSubview:self.titleLabel];
    }
    
    UIImage *normalImage = [Utils createImageWithColor:self.singleCellBGColor];
    UIImage *highlightedImage = [Utils createImageWithColor:self.heightlightColor];

    if (_destructiveButtonTitle && _destructiveButtonTitle.length>0)
    {
        self.destructiveButton = [UIButton new];
        self.destructiveButton.tag = [_otherButtonTitles count] ?: 0;
        self.destructiveButton.backgroundColor = self.singleCellBGColor;
        self.destructiveButton.titleLabel.font = kDEFAULT_FONT(self.btnFontName, kButtonTitleFontSize);
        [self.destructiveButton setTitleColor:self.destructiveTitleColor forState:UIControlStateNormal];
        [self.destructiveButton setTitle:_destructiveButtonTitle forState:UIControlStateNormal];
        [self.destructiveButton setBackgroundImage:normalImage forState:UIControlStateNormal];
        [self.destructiveButton setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
        [self.destructiveButton addTarget:self action:@selector(didSelectAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.actionSheetView addSubview:self.destructiveButton];
    }
    
    self.separatorView = [UIView new];
    self.separatorView.backgroundColor = self.separatorColor;
    [self.actionSheetView addSubview:self.separatorView];

    self.cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.cancelBtn.tag = kCancelBtnTag;
    self.cancelBtn.backgroundColor = self.singleCellBGColor;
    self.cancelBtn.titleLabel.font = kDEFAULT_FONT(self.btnFontName, kButtonTitleFontSize);
    [self.cancelBtn setTitleColor:self.normalTitleColor forState:UIControlStateNormal];
    [self.cancelBtn setTitle:_cancelButtonTitle ?: @"取消" forState:UIControlStateNormal];
    [self.cancelBtn setBackgroundImage:normalImage forState:UIControlStateNormal];
    [self.cancelBtn setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
    [self.cancelBtn addTarget:self action:@selector(didSelectAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.actionSheetView addSubview:self.cancelBtn];

}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    
    [self.backView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(kAppDelegateWindow);
    }];

    UIDevice *device = [UIDevice currentDevice];

    [self.actionSheetView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.backView);
        if (device.orientation == UIDeviceOrientationLandscapeRight || device.orientation == UIDeviceOrientationLandscapeLeft)
        {
            make.width.offset(kSCREEN_HEIGHT);
        }
        else
        {
            make.width.offset(kSCREEN_WIDTH);
        }
        make.bottom.equalTo(self.backView).offset(-HEIGHT_TABBAR_SAFEAREA);
        make.height.offset([self actionSheetHeight:device.orientation]);
    }];
    
    if (device.orientation == UIDeviceOrientationLandscapeRight || device.orientation == UIDeviceOrientationLandscapeLeft)
    {
        kViewBorderRadius(self.actionSheetView, 5, 0, kClearColor);
    }

    if (_title && _title.length>0)
    {
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(self.actionSheetView);
            make.height.offset([self titleHeight]);
        }];

        if (_destructiveButtonTitle && _destructiveButtonTitle.length>0)
        {
            [self.actionSheetScroll mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.equalTo(self.actionSheetView);
                make.height.offset([self scrollH:device.orientation]);
                make.bottom.equalTo(self.actionSheetView).offset(-(kRowHeight*2)-kSeparatorHeight-kRowLineHeight);
            }];
        }
        else
        {
            [self.actionSheetScroll mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.equalTo(self.actionSheetView);
                make.height.offset([self scrollH:device.orientation]);
                make.bottom.equalTo(self.actionSheetView).offset(-kRowHeight-kSeparatorHeight-kRowLineHeight);
            }];
        }
    }
    else
    {
        if (_destructiveButtonTitle && _destructiveButtonTitle.length>0)
        {
            [self.actionSheetScroll mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.top.right.equalTo(self.actionSheetView);
                make.height.offset([self scrollH:device.orientation]);
                make.bottom.equalTo(self.actionSheetView).offset(-(kRowHeight*2)-kSeparatorHeight-kRowLineHeight);
            }];
        }
        else
        {
            [self.actionSheetScroll mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.top.right.equalTo(self.actionSheetView);
                make.height.offset([self scrollH:device.orientation]);
                make.bottom.equalTo(self.actionSheetView).offset(-kRowHeight-kSeparatorHeight-kRowLineHeight);
            }];
        }
    }

    CGFloat contentW;
    if (device.orientation == UIDeviceOrientationLandscapeRight || device.orientation == UIDeviceOrientationLandscapeLeft)
    {
        contentW = kSCREEN_HEIGHT;
    }
    else
    {
        contentW = kSCREEN_WIDTH;
    }
    self.actionSheetScroll.contentSize = CGSizeMake(contentW, [self scrollContentH]);
    self.actionSheetScroll.showsVerticalScrollIndicator = NO;
    if ([self actionSheetRealHeight] >= kSCREEN_HEIGHT)
    {
        self.actionSheetScroll.scrollEnabled = YES;
    }
    else
    {
        self.actionSheetScroll.scrollEnabled = NO;
    }

    UIImage *normalImage = [Utils createImageWithColor:self.singleCellBGColor];
    UIImage *highlightedImage = [Utils createImageWithColor:self.heightlightColor];

    if ([_otherButtonTitles count] > 0)
    {
        for (int i = 0; i < _otherButtonTitles.count; i++)
        {
            UIButton *btn = [[UIButton alloc] init];
            btn.tag = i+100;
            btn.backgroundColor = self.singleCellBGColor;
            btn.titleLabel.font = kDEFAULT_FONT(self.btnFontName, kButtonTitleFontSize);
            [btn setTitleColor:self.normalTitleColor forState:UIControlStateNormal];
            [btn setTitle:_otherButtonTitles[i] forState:UIControlStateNormal];
            [btn setBackgroundImage:normalImage forState:UIControlStateNormal];
            [btn setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
            [btn addTarget:self action:@selector(didSelectAction:) forControlEvents:UIControlEventTouchUpInside];
            [self.actionSheetScroll addSubview:btn];
            [btn mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerX.equalTo(self.actionSheetScroll);
                if (device.orientation == UIDeviceOrientationLandscapeRight || device.orientation == UIDeviceOrientationLandscapeLeft)
                {
                    make.width.offset(kSCREEN_HEIGHT);
                }
                else
                {
                    make.width.offset(kSCREEN_WIDTH);
                }
                make.top.offset(kRowHeight*i+kRowLineHeight*i);
                make.height.offset(kRowHeight);
            }];
        }
    }

    if (_destructiveButtonTitle && _destructiveButtonTitle.length>0)
    {
        [self.destructiveButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.actionSheetView);
            make.bottom.equalTo(self.actionSheetView).offset(-kRowHeight-kSeparatorHeight);
            make.height.offset(kRowHeight);
        }];
    }

    [self.separatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.actionSheetView);
        make.bottom.equalTo(self.actionSheetView).offset(-(kRowHeight));
        make.height.offset(kSeparatorHeight);
    }];

    [self.cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.actionSheetView);
        make.height.offset(kRowHeight);
    }];
}

+ (ALActionSheetView *)showActionSheetWithTitle:(NSString *)title
                                   titleMessage:(NSString *)titleMessage
                              cancelButtonTitle:(NSString *)cancelButtonTitle
                         destructiveButtonTitle:(NSString *)destructiveButtonTitle
                              otherButtonTitles:(NSArray *)otherButtonTitles
                                 buttonFontName:(NSString *)bfName
                      singleCellBackgroundColor:(UIColor *)cellBGColor
                           normalCellTitleColor:(UIColor *)normalTitleColor
                      destructiveCellTitleColor:(UIColor *)destructiveTitleColor
                            titleCellTitleColor:(UIColor *)titleCellTitleColor
                                 separatorColor:(UIColor *)separatorColor
                               heightlightColor:(UIColor *)heightlightColor
                                        handler:(ALActionSheetViewDidSelectButtonBlock)block;
{
    ALActionSheetView *actionSheetView = [[ALActionSheetView alloc] initWithTitle:title titleMessage:titleMessage  cancelButtonTitle:cancelButtonTitle destructiveButtonTitle:destructiveButtonTitle otherButtonTitles:otherButtonTitles buttonFontName:bfName                       singleCellBackgroundColor:cellBGColor normalCellTitleColor:normalTitleColor destructiveCellTitleColor:destructiveTitleColor titleCellTitleColor:titleCellTitleColor separatorColor:separatorColor heightlightColor:heightlightColor handler:block];
    
    return actionSheetView;
}

#pragma mark ------> SubViewHeight
-(CGFloat)titleHeight
{
    CGFloat spacing;
    if (_title && _title.length>0)
    {
        spacing = 15.0f;
    }
    else
    {
        spacing = 0.0f;
    }
    return ceil([self.title boundingRectWithSize:CGSizeMake(kSCREEN_WIDTH, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:kDEFAULT_FONT(self.btnFontName, kTitleFontSize)} context:nil].size.height) + spacing*2;
}

-(CGFloat)actionSheetRealHeight
{
    return [self scrollContentH] + ([self titleHeight] + kRowLineHeight) +(kSeparatorHeight + kRowHeight) + [self destRowH] + [self destLineH]+kRowLineHeight;
}

-(CGFloat)actionSheetHeight:(UIDeviceOrientation)orientation
{
    CGFloat realH = [self actionSheetRealHeight];
    
    CGFloat viewH;
    if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight)
    {
        viewH = kSCREEN_HEIGHT;
    }
    else
    {
        viewH = kSCREEN_HEIGHT;
    }
    
    if ([self actionSheetRealHeight] >= kSCREEN_HEIGHT)
    {
        return viewH-kScreenStatusBottom-HEIGHT_TABBAR_SAFEAREA;
    }
    else
    {
        return realH;
    }
}

-(CGFloat)scrollContentH
{
    CGFloat realH = self.otherButtonTitles.count * kRowHeight + kRowLineHeight * (self.otherButtonTitles.count-1);
    return realH;
}

-(CGFloat)scrollH:(UIDeviceOrientation)orientation
{
    int a = [self actionSheetHeight:orientation];
    int b ;
    if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight)
    {
        b = kSCREEN_HEIGHT;
    }
    else
    {
        b = kSCREEN_HEIGHT;
    }
    if (a - b <= 0) {
        return [self actionSheetHeight:orientation] - ([self titleHeight] + kRowLineHeight) - (kSeparatorHeight + kRowHeight) - ([self destRowH] + [self destLineH]);
    }
    else
    {
        return [self scrollContentH];
    }
}

-(CGFloat)destRowH
{
    if (self.destructiveButtonTitle && self.destructiveButtonTitle.length>0)
    {
        return kRowHeight;
    }
    else
    {
        return 0;
    }
}

-(CGFloat)destLineH
{
    if (self.destructiveButtonTitle && self.destructiveButtonTitle.length>0)
    {
        return kRowLineHeight;
    }
    else
    {
        return 0;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:_backView];
    if (!CGRectContainsPoint([self.actionSheetView frame], point))
    {
        [self dismiss];
    }
}

- (void)didSelectAction:(UIButton *)button
{
    if (_selectRowBlock)
    {
        NSInteger index = button.tag-100;
        
        _selectRowBlock(self, index);
    }
    
    [self dismiss];
}

#pragma mark - public
- (void)show
{
    if(_isShow) return;
    
    _isShow = YES;
    
    POPSpringAnimation *animation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerTranslationY];
    self.actionSheetView.layer.transform = CATransform3DMakeTranslation(0, [self actionSheetRealHeight], 0);
    animation.toValue = @(0);
    animation.springBounciness = 1.0f;
    [self.actionSheetView.layer pop_addAnimation:animation forKey:@"ActionSheetAnimation"];

}

- (void)dismiss
{
    _isShow = NO;
    
    POPBasicAnimation *offscreenAnimation = [POPBasicAnimation easeOutAnimation];
    offscreenAnimation.property = [POPAnimatableProperty propertyWithName:kPOPLayerTranslationY];
    offscreenAnimation.toValue = @([self actionSheetRealHeight]);
    offscreenAnimation.duration = 0.35f;
    [offscreenAnimation setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        [UIView animateWithDuration:0.35f delay:0 usingSpringWithDamping:0.9f initialSpringVelocity:0.7f options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionLayoutSubviews animations:^{
            self.backView.alpha = 0.0;
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    }];
    [self.actionSheetView.layer pop_addAnimation:offscreenAnimation forKey:@"offscreenAnimation"];
}

@end
