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
        UIDevice *device = [UIDevice currentDevice]; //Get the device object
        [device beginGeneratingDeviceOrientationNotifications]; //Tell it to start monitoring the accelerometer for orientation
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter]; //Get the notification centre for the app
        [nc addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification  object:device];

        _title = title;
        _cancelButtonTitle = cancelButtonTitle;
        _destructiveButtonTitle = destructiveButtonTitle;
        _otherButtonTitles = otherButtonTitles;
        _selectRowBlock = block;
        self.btnFontName = bfName;
    }
    
    return self;
}

-(void)loadView
{
    _backView = [UIView new];
    _backView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2];
    _backView.alpha = 0.0f;
    [self addSubview:_backView];
    
    self.actionSheetView = [UIView new];
    self.actionSheetView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:230.0f/255.0f blue:230.0f/255.0f alpha:1.0f];
    [self addSubview:self.actionSheetView];
    
    UIImage *normalImage = [self imageWithColor:[UIColor whiteColor]];
    UIImage *highlightedImage = [self imageWithColor:[UIColor colorWithRed:242.0f/255.0f green:242.0f/255.0f blue:242.0f/255.0f alpha:1.0f]];
    
    if (_title && _title.length>0)
    {
        self.titleLabel = [UILabel new];
        self.titleLabel.backgroundColor = [UIColor whiteColor];
        self.titleLabel.textColor = [UIColor colorWithRed:111.0f/255.0f green:111.0f/255.0f blue:111.0f/255.0f alpha:1.0f];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = kDEFAULT_FONT(self.btnFontName, kTitleFontSize);
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.text = _title;
        [self.actionSheetView addSubview:self.titleLabel];
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(self.actionSheetView);
            make.height.offset([self titleHeight]);
        }];
    }
    
    self.actionSheetScroll = [UIScrollView new];
    [self.actionSheetView addSubview:self.actionSheetScroll];
    [self.actionSheetScroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.actionSheetView);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(kRowLineHeight);
        make.height.offset([self scrollH]);
    }];
    self.actionSheetScroll.contentSize = CGSizeMake(kSCREEN_WIDTH, [self scrollContentH]);
    self.actionSheetScroll.showsVerticalScrollIndicator = NO;
    if ([self actionSheetRealHeight] >= kSCREEN_HEIGHT) {
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
        [self.destructiveButton setTitleColor:[UIColor colorWithRed:255.0f/255.0f green:10.0f/255.0f blue:10.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
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
    self.separatorView.backgroundColor = [UIColor colorWithRed:238.0f/255.0f green:238.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
    [self.actionSheetView addSubview:self.separatorView];
    [self.separatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.actionSheetView);
        make.bottom.equalTo(self.actionSheetView).offset(-(kRowHeight));
        make.height.offset(kSeparatorHeight);
    }];
    
    self.cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.cancelBtn.tag = -1;
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

- (void)orientationChanged:(NSNotification *)note
{
    [_backView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo([[[UIApplication sharedApplication] delegate] window]);
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"0.1秒后获取frame：%@", self);
        [self.actionSheetView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.backView);
            make.top.offset(kSCREEN_HEIGHT-[self actionSheetHeight]);
            make.height.offset([self actionSheetHeight]);
        }];
        
        [self.titleLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(self.actionSheetView);
            make.height.offset([self titleHeight]);
        }];
        
        [self.actionSheetScroll mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.actionSheetView);
            make.top.equalTo(self.titleLabel.mas_bottom).offset(kRowLineHeight);
            make.height.offset([self scrollH]);
        }];
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

        [self.destructiveButton mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.actionSheetView);
            make.bottom.equalTo(self.actionSheetView).offset(-kRowHeight-kSeparatorHeight);
            make.height.offset(kRowHeight);
        }];
        
        [self.separatorView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.actionSheetView);
            make.bottom.equalTo(self.actionSheetView).offset(-(kRowHeight));
            make.height.offset(kSeparatorHeight);
        }];
        
        [self.cancelBtn mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self.actionSheetView);
            make.height.offset(kRowHeight);
        }];
    });
}

-(CGFloat)titleHeight
{
    CGFloat spacing = 15.0f;
    return ceil([self.title boundingRectWithSize:CGSizeMake(kSCREEN_WIDTH, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:kDEFAULT_FONT(self.btnFontName, kTitleFontSize)} context:nil].size.height) + spacing*2;
}

-(CGFloat)actionSheetRealHeight
{
    return [self scrollContentH] + ([self titleHeight] + kRowLineHeight) +(kSeparatorHeight + kRowHeight) + [self destRowH] + [self destLineH];
}

-(CGFloat)actionSheetHeight
{
    CGFloat realH = [self actionSheetRealHeight];
    if ([self actionSheetRealHeight] >= kSCREEN_HEIGHT) {
        return kSCREEN_HEIGHT-kScreenStatusBottom;
    }
    else
    {
        return realH;
    }
}

-(CGFloat)scrollContentH
{
    CGFloat realH = self.otherButtonTitles.count*kRowHeight + kRowLineHeight*(self.otherButtonTitles.count-1);
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

- (UIImage *)imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


#pragma mark - public

- (void)show
{
    if(_isShow) return;
    
    _isShow = YES;
    
    [self loadView];

    [UIView animateWithDuration:0.35f delay:0 usingSpringWithDamping:0.9f initialSpringVelocity:0.7f options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionLayoutSubviews animations:^{
        
        [[[[UIApplication sharedApplication] delegate] window] addSubview:self];
        
        [self.backView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.bottom.equalTo([[[UIApplication sharedApplication] delegate] window]);
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
