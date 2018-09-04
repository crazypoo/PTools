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
@end


@implementation ALActionSheetView

- (void)dealloc
{
    self.title= nil;
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

- (instancetype)initWithTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSArray *)otherButtonTitles buttonFontName:(NSString *)bfName handler:(ALActionSheetViewDidSelectButtonBlock)block;
{
    self = [self init];
    
    if (self)
    {
        _title = title;
        _cancelButtonTitle = cancelButtonTitle;
        _destructiveButtonTitle = destructiveButtonTitle;
        _otherButtonTitles = otherButtonTitles;
        _selectRowBlock = block;
        self.btnFontName = bfName ? bfName : @"HelveticaNeue-Light";
    }
    
    return self;
}

-(void)loadView
{
    _backView = [UIView new];
    _backView.backgroundColor = kRGBAColorDecimals(0, 0, 0, 0.2);
    _backView.alpha = 0.0f;
    [self addSubview:_backView];
    
    self.actionSheetView = [UIView new];
    self.actionSheetView.backgroundColor = kRGBAColor(230, 230, 230, 1);
    [self addSubview:self.actionSheetView];
    
    UIImage *normalImage = [Utils createImageWithColor:[UIColor whiteColor]];
    UIImage *highlightedImage = [Utils createImageWithColor:kRGBAColor(242, 242, 242, 1)];
    
    self.actionSheetScroll = [UIScrollView new];
    [self.actionSheetView addSubview:self.actionSheetScroll];

    if (_title && _title.length>0)
    {
        self.titleLabel = [UILabel new];
        self.titleLabel.backgroundColor = [UIColor whiteColor];
        self.titleLabel.textColor = kRGBAColor(111, 111, 111, 1);
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = kDEFAULT_FONT(self.btnFontName, kTitleFontSize);
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.text = _title;
        [self.actionSheetView addSubview:self.titleLabel];
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(self.actionSheetView);
            make.height.offset([self titleHeight]);
        }];
        
        if (_destructiveButtonTitle && _destructiveButtonTitle.length>0)
        {
            [self.actionSheetScroll mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.equalTo(self.actionSheetView);
                make.height.offset([self scrollH]);
                make.bottom.equalTo(self.actionSheetView).offset(-(kRowHeight*2)-kSeparatorHeight);
            }];
        }
        else
        {
            [self.actionSheetScroll mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.equalTo(self.actionSheetView);
                make.height.offset([self scrollH]);
                make.bottom.equalTo(self.actionSheetView).offset(-kRowHeight-kSeparatorHeight);
            }];
        }
    }
    else
    {
        if (_destructiveButtonTitle && _destructiveButtonTitle.length>0)
        {
            [self.actionSheetScroll mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.top.right.equalTo(self.actionSheetView);
                make.height.offset([self scrollH]);
                make.bottom.equalTo(self.actionSheetView).offset(-(kRowHeight*2)-kSeparatorHeight);
            }];
        }
        else
        {
            [self.actionSheetScroll mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.top.right.equalTo(self.actionSheetView);
                make.height.offset([self scrollH]);
                make.bottom.equalTo(self.actionSheetView).offset(-kRowHeight-kSeparatorHeight);
            }];
        }
    }
    
    self.actionSheetScroll.contentSize = CGSizeMake(kSCREEN_WIDTH, [self scrollContentH]);
    self.actionSheetScroll.showsVerticalScrollIndicator = NO;
    if ([self actionSheetRealHeight] >= kSCREEN_HEIGHT)
    {
        self.actionSheetScroll.scrollEnabled = YES;
    }
    else
    {
        self.actionSheetScroll.scrollEnabled = NO;
    }
    
    if ([_otherButtonTitles count] > 0)
    {
        for (int i = 0; i < _otherButtonTitles.count; i++)
        {
            UIButton *btn = [[UIButton alloc] init];
            btn.frame = CGRectMake(0, kRowHeight*i+kRowLineHeight*i, kSCREEN_WIDTH, kRowHeight);
            btn.tag = i+100;
            btn.backgroundColor = [UIColor whiteColor];
            btn.titleLabel.font = kDEFAULT_FONT(self.btnFontName, kButtonTitleFontSize);
            [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [btn setTitle:_otherButtonTitles[i] forState:UIControlStateNormal];
            [btn setBackgroundImage:normalImage forState:UIControlStateNormal];
            [btn setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
            [btn addTarget:self action:@selector(didSelectAction:) forControlEvents:UIControlEventTouchUpInside];
            [self.actionSheetScroll addSubview:btn];
        }
    }
    
    if (_destructiveButtonTitle && _destructiveButtonTitle.length>0)
    {
        self.destructiveButton = [UIButton new];
        self.destructiveButton.tag = [_otherButtonTitles count] ?: 0;
        self.destructiveButton.backgroundColor = [UIColor whiteColor];
        self.destructiveButton.titleLabel.font = kDEFAULT_FONT(self.btnFontName, kButtonTitleFontSize);
        [self.destructiveButton setTitleColor:kRGBAColor(255, 10, 10, 1) forState:UIControlStateNormal];
        [self.destructiveButton setTitle:_destructiveButtonTitle forState:UIControlStateNormal];
        [self.destructiveButton setBackgroundImage:normalImage forState:UIControlStateNormal];
        [self.destructiveButton setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
        [self.destructiveButton addTarget:self action:@selector(didSelectAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.actionSheetView addSubview:self.destructiveButton];
        [self.destructiveButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.actionSheetView);
            make.bottom.equalTo(self.actionSheetView).offset(-kRowHeight-kSeparatorHeight);
            make.height.offset(kRowHeight);
        }];
    }
 
    self.separatorView = [UIView new];
    self.separatorView.backgroundColor = kRGBAColor(238, 238, 238, 1);
    [self.actionSheetView addSubview:self.separatorView];
    [self.separatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.actionSheetView);
        make.bottom.equalTo(self.actionSheetView).offset(-(kRowHeight));
        make.height.offset(kSeparatorHeight);
    }];
    
    self.cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.cancelBtn.tag = kCancelBtnTag;
    self.cancelBtn.backgroundColor = [UIColor whiteColor];
    self.cancelBtn.titleLabel.font = kDEFAULT_FONT(self.btnFontName, kButtonTitleFontSize);
    [self.cancelBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.cancelBtn setTitle:_cancelButtonTitle ?: @"取消" forState:UIControlStateNormal];
    [self.cancelBtn setBackgroundImage:normalImage forState:UIControlStateNormal];
    [self.cancelBtn setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
    [self.cancelBtn addTarget:self action:@selector(didSelectAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.actionSheetView addSubview:self.cancelBtn];
    [self.cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.actionSheetView);
        make.height.offset(kRowHeight);
    }];
}

+ (ALActionSheetView *)showActionSheetWithTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSArray *)otherButtonTitles buttonFontName:(NSString *)bfName handler:(ALActionSheetViewDidSelectButtonBlock)block;
{
    ALActionSheetView *actionSheetView = [[ALActionSheetView alloc] initWithTitle:title cancelButtonTitle:cancelButtonTitle destructiveButtonTitle:destructiveButtonTitle otherButtonTitles:otherButtonTitles buttonFontName:bfName handler:block];
    
    return actionSheetView;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    [_backView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(kAppDelegateWindow);
    }];
    
    [self.actionSheetView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.backView);
        make.top.offset(kSCREEN_HEIGHT-[self actionSheetHeight]);
        make.height.offset([self actionSheetHeight]);
    }];
    
    if (_title && _title.length>0)
    {
        [self.titleLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(self.actionSheetView);
            make.height.offset([self titleHeight]);
        }];
        
        if (_destructiveButtonTitle && _destructiveButtonTitle.length>0)
        {
            [self.actionSheetScroll mas_updateConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.titleLabel.mas_bottom).offset(kRowLineHeight);
                make.height.offset([self scrollH]);
                make.bottom.equalTo(self.actionSheetView).offset(-(kRowHeight*2)-kSeparatorHeight);
            }];
        }
        else
        {
            [self.actionSheetScroll mas_updateConstraints:^(MASConstraintMaker *make) {
                make.left.right.equalTo(self.actionSheetView);
                make.height.offset([self scrollH]);
                make.bottom.equalTo(self.actionSheetView).offset(-kRowHeight-kSeparatorHeight);
            }];
        }
    }
    else
    {
        if (_destructiveButtonTitle && _destructiveButtonTitle.length>0)
        {
            [self.actionSheetScroll mas_updateConstraints:^(MASConstraintMaker *make) {
                make.left.top.right.equalTo(self.actionSheetView);
                make.height.offset([self scrollH]);
                make.bottom.equalTo(self.actionSheetView).offset(-(kRowHeight*2)-kSeparatorHeight);
            }];
        }
        else
        {
            [self.actionSheetScroll mas_updateConstraints:^(MASConstraintMaker *make) {
                make.left.top.right.equalTo(self.actionSheetView);
                make.height.offset([self scrollH]);
                make.bottom.equalTo(self.actionSheetView).offset(-kRowHeight-kSeparatorHeight);
            }];
        }
    }
    
    self.actionSheetScroll.contentSize = CGSizeMake(kSCREEN_WIDTH, [self scrollContentH]);
    
    if ([self.otherButtonTitles count] > 0)
    {
        for (int i = 0; i < self.otherButtonTitles.count; i++)
        {
            UIButton *btn = [self.actionSheetScroll viewWithTag:i+100];
            [btn mas_updateConstraints:^(MASConstraintMaker *make) {
                make.left.right.equalTo(self.actionSheetView);
                make.top.offset(kRowHeight*i+kRowLineHeight*i);
                make.height.offset(kRowHeight);
            }];
        }
    }
    
    if (_destructiveButtonTitle && _destructiveButtonTitle.length>0)
    {
        [self.destructiveButton mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.actionSheetView);
            make.bottom.equalTo(self.actionSheetView).offset(-kRowHeight-kSeparatorHeight);
            make.height.offset(kRowHeight);
        }];
    }
    
    [self.separatorView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.actionSheetView);
        make.bottom.equalTo(self.actionSheetView).offset(-(kRowHeight));
        make.height.offset(kSeparatorHeight);
    }];
    
    [self.cancelBtn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.actionSheetView);
        make.height.offset(kRowHeight);
    }];
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
    return [self scrollContentH] + ([self titleHeight] + kRowLineHeight) +(kSeparatorHeight + kRowHeight) + [self destRowH] + [self destLineH];
}

-(CGFloat)actionSheetHeight
{
    CGFloat realH = [self actionSheetRealHeight];
    if ([self actionSheetRealHeight] >= kSCREEN_HEIGHT)
    {
        return kSCREEN_HEIGHT-kScreenStatusBottom;
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

-(CGFloat)scrollH
{
    int a = [self actionSheetHeight];
    int b = kSCREEN_HEIGHT;
    if (a - b <= 0) {
        return [self actionSheetHeight] - ([self titleHeight] + kRowLineHeight) - (kSeparatorHeight + kRowHeight) - ([self destRowH] + [self destLineH]);
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
    
    [self loadView];

    [UIView animateWithDuration:0.35f delay:0 usingSpringWithDamping:0.9f initialSpringVelocity:0.7f options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionLayoutSubviews animations:^{
        
        [kAppDelegateWindow addSubview:self];
        
        [self.backView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.bottom.equalTo(kAppDelegateWindow);
        }];
        
        [self.actionSheetView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self);
            make.top.offset(kSCREEN_HEIGHT-self.actionSheetHeight);
            make.height.offset(self.actionSheetHeight);
        }];
        
        self.backView.alpha = 1.0;
        
    } completion:NULL];
}

- (void)dismiss
{
    _isShow = NO;
    
    [UIView animateWithDuration:0.35f delay:0 usingSpringWithDamping:0.9f initialSpringVelocity:0.7f options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionLayoutSubviews animations:^{
        
        self.backView.alpha = 0.0;
        [self removeFromSuperview];

    } completion:^(BOOL finished) {
    }];
}

@end
