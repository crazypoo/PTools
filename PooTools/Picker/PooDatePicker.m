//
//  PooDatePicker.m
//  LandloardTool
//
//  Created by mouth on 2018/5/8.
//  Copyright © 2018年 邓杰豪. All rights reserved.
//

#import "PooDatePicker.h"
#import "UIButton+Block.h"
#import "PMacros.h"
#import <Masonry/Masonry.h>
#import "Utils.h"
#import <pop/POP.h>
#import "UIView+ViewRectCorner.h"

#pragma mark ------> DatePicker
@interface PooDatePicker ()<UITextFieldDelegate,UIPickerViewDataSource,UIPickerViewDelegate>

@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) NSMutableArray *yearArray;
@property (nonatomic, strong) NSMutableArray *monthArray;
@property (nonatomic, strong) NSMutableArray *dayArray;
@property (nonatomic, strong) UIFont *pickerFonts;
@property (nonatomic, assign) NSInteger yearIndex;
@property (nonatomic, assign) NSInteger monthIndex;
@property (nonatomic, assign) NSInteger dayIndex;
@property (nonatomic, strong) UIView *topV;
@property (nonatomic, assign) PPickerType pickerType;
@property (nonatomic,strong) UIView *pickerBackground;
@property (nonatomic,strong) UILabel *nameTitle;
@property (nonatomic,strong) UIButton *cancelBtn;
@property (nonatomic,strong) UIButton *yesBtn;
@property (nonatomic, strong) UIFont *labelFont;
@property (nonatomic, strong) UIColor *pickerBackgroundColor;
@property (nonatomic, strong) UIColor *pickerFontColor;

@end

@implementation PooDatePicker
- (NSMutableArray *)yearArray
{
    if (_yearArray == nil)
    {
        _yearArray = [NSMutableArray array];
        for (int year = 1950; year < 2050; year++)
        {
            NSString *str = [NSString stringWithFormat:@"%d年", year];
            [_yearArray addObject:str];
        }
    }
    return _yearArray;
}

- (NSMutableArray *)monthArray
{
    if (_monthArray == nil)
    {
        _monthArray = [NSMutableArray array];
        for (int month = 1; month <= 12; month++)
        {
            NSString *str = [NSString stringWithFormat:@"%02d月", month];
            [_monthArray addObject:str];
        }
    }
    return _monthArray;
}

- (NSMutableArray *)dayArray
{
    if (_dayArray == nil)
    {
        _dayArray = [NSMutableArray array];
        for (int day = 1; day <= 31; day++)
        {
            NSString *str = [NSString stringWithFormat:@"%02d日", day];
            [_dayArray addObject:str];
        }
    }
    return _dayArray;
}

- (instancetype)initWithTitle:(NSString *)title
       toolBarBackgroundColor:(UIColor *)tbbc
                    labelFont:(UIFont *)font
            toolBarTitleColor:(UIColor *)tbtc
                   pickerFont:(UIFont *)pf
                   pickerType:(PPickerType)pT
        pickerBackgroundColor:(UIColor *)pBGColor
              pickerFontColor:(UIColor *)pfColor
              inPutDataString:(NSString *)ipds
{
    self = [super init];
    if (self)
    {
        self.pickerFonts = pf;
        self.pickerType = pT;
        self.labelFont = font;
        self.pickerBackgroundColor = pBGColor ? pBGColor : [UIColor whiteColor];
        self.pickerFontColor = pfColor ? pfColor : [UIColor blackColor];
        
        self.pickerBackground = [UIView new];
        self.pickerBackground.backgroundColor    = kDevMaskBackgroundColor;
        [self addSubview:self.pickerBackground];

        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideViewAction:)];
        tapGesture.numberOfTapsRequired = 1;
        [self.pickerBackground addGestureRecognizer:tapGesture];
        
        self.topV = [UIView new];
        self.topV.backgroundColor = tbbc;
        [self.pickerBackground addSubview:self.topV];
        
        self.nameTitle = [UILabel new];
        self.nameTitle.textAlignment = NSTextAlignmentCenter;
        self.nameTitle.textColor = tbtc;
        self.nameTitle.font = font;
        self.nameTitle.numberOfLines = 0;
        self.nameTitle.lineBreakMode = NSLineBreakByCharWrapping;
        self.nameTitle.text = title;
        [self.topV addSubview:self.nameTitle];
        
        self.cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.cancelBtn.titleLabel setFont:font];
        [self.cancelBtn setBackgroundImage:[Utils createImageWithColor:kDevButtonHighlightedColor] forState:UIControlStateHighlighted];
        [self.cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        [self.cancelBtn setTitleColor:tbtc forState:UIControlStateNormal];
        [self.topV addSubview:self.cancelBtn];
        kViewBorderRadius(self.cancelBtn, 5, 0, kClearColor);

        self.yesBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.yesBtn setBackgroundImage:[Utils createImageWithColor:kDevButtonHighlightedColor] forState:UIControlStateHighlighted];
        [self.yesBtn.titleLabel setFont:font];
        [self.yesBtn setTitle:@"完成" forState:UIControlStateNormal];
        [self.yesBtn setTitleColor:tbtc forState:UIControlStateNormal];
        [self.topV addSubview:self.yesBtn];
        kViewBorderRadius(self.yesBtn, 5, 0, kClearColor);

        kWeakSelf(self);

        [self.cancelBtn addActionHandler:^(UIButton *sender) {
            if (weakself.block)
            {
                weakself.block(nil);
            }
            [weakself remove];
        }];
        
        [self.yesBtn addActionHandler:^(UIButton *sender) {
            
            if ([Utils isRolling:weakself.pickerView])
            {
                return;
            }
            
            if (weakself.block)
            {
                switch (weakself.pickerType)
                {
                    case PPickerTypeYMD:
                    {
                        NSString *timeStr = [NSString stringWithFormat:@"%@%@%@",((UILabel *)[weakself.pickerView viewForRow:weakself.yearIndex forComponent:0]).text, ((UILabel *)[weakself.pickerView viewForRow:weakself.monthIndex forComponent:1]).text, ((UILabel *)[weakself.pickerView viewForRow:weakself.dayIndex forComponent:2]).text];
                        
                        timeStr = [timeStr stringByReplacingOccurrencesOfString:@"年" withString:@"-"];
                        timeStr = [timeStr stringByReplacingOccurrencesOfString:@"月" withString:@"-"];
                        timeStr = [timeStr stringByReplacingOccurrencesOfString:@"日" withString:@""];
                        
                        weakself.block(timeStr);
                    }
                        break;
                    case PPickerTypeYM:
                    {
                        NSString *timeStr = [NSString stringWithFormat:@"%@%@",((UILabel *)[weakself.pickerView viewForRow:weakself.yearIndex forComponent:0]).text, ((UILabel *)[weakself.pickerView viewForRow:weakself.monthIndex forComponent:1]).text];
                        
                        timeStr = [timeStr stringByReplacingOccurrencesOfString:@"年" withString:@"-"];
                        timeStr = [timeStr stringByReplacingOccurrencesOfString:@"月" withString:@"-"];
                        
                        NSString *newTime = [timeStr substringToIndex:timeStr.length-1];
                        
                        weakself.block(newTime);
                    }
                        break;
                    default:
                    {
                        NSString *timeStr = [NSString stringWithFormat:@"%@",((UILabel *)[weakself.pickerView viewForRow:weakself.yearIndex forComponent:0]).text];
                        
                        timeStr = [timeStr stringByReplacingOccurrencesOfString:@"年" withString:@"-"];
                        
                        NSString *newTime = [timeStr substringToIndex:timeStr.length-1];
                        
                        weakself.block(newTime);
                    }
                        break;
                }
            }
            [weakself remove];
        }];
        
        _pickerView = [UIPickerView new];
        _pickerView.dataSource = self;
        _pickerView.delegate = self;
        _pickerView.backgroundColor = self.pickerBackgroundColor;
        [self.pickerBackground addSubview:_pickerView];
        
        NSString *yearStr;
        NSString *monthStr;
        NSString *dayStr;
        if (kStringIsEmpty(ipds)) {
            NSCalendar *calendar = [[NSCalendar alloc]
                                    initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            // 定义一个时间字段的旗标，指定将会获取指定年、月、日、时、分、秒的信息
            unsigned unitFlags = NSCalendarUnitYear |
            NSCalendarUnitMonth |  NSCalendarUnitDay |
            NSCalendarUnitHour |  NSCalendarUnitMinute |
            NSCalendarUnitSecond | NSCalendarUnitWeekday;
            // 获取不同时间字段的信息
            NSDateComponents *comp = [calendar components: unitFlags fromDate:[NSDate date]];
            
            yearStr  = [NSString stringWithFormat:@"%ld", (long)comp.year];
            monthStr = [NSString stringWithFormat:@"%02ld", (long)comp.month];
            dayStr   = [NSString stringWithFormat:@"%02ld", (long)comp.day];
        }
        else
        {
            NSDateFormatter *formatter1 = [[NSDateFormatter alloc] init];
            [formatter1 setDateFormat:@"yyyy-MM-dd"];
            NSDate *date =[formatter1 dateFromString:ipds];
            NSDateFormatter *formatter2 = [[NSDateFormatter alloc] init];
            [formatter2 setDateFormat:@"yyyyMMdd"];
            NSString *dateString2 = [formatter2 stringFromDate:date ];

            yearStr  = [dateString2 substringToIndex:4];
            monthStr = [dateString2 substringWithRange:NSMakeRange(4,2)];
            dayStr   = [dateString2 substringFromIndex:6];
        }
        
        switch (self.pickerType)
        {
            case PPickerTypeYMD:
            {
                self.yearIndex = [self.yearArray indexOfObject:[NSString stringWithFormat:@"%@年", yearStr]];
                self.monthIndex = [self.monthArray indexOfObject:[NSString stringWithFormat:@"%@月", monthStr]];
                self.dayIndex = [self.dayArray indexOfObject:[NSString stringWithFormat:@"%@日", dayStr]];
                
                [self.pickerView selectRow:self.yearIndex inComponent:0 animated:YES];
                [self.pickerView selectRow:self.monthIndex inComponent:1 animated:YES];
                [self.pickerView selectRow:self.dayIndex inComponent:2 animated:YES];
                
                [self pickerView:self.pickerView didSelectRow:self.yearIndex inComponent:0];
                [self pickerView:self.pickerView didSelectRow:self.monthIndex inComponent:1];
                [self pickerView:self.pickerView didSelectRow:self.dayIndex inComponent:2];
            }
                break;
            case PPickerTypeYM:
            {
                self.yearIndex = [self.yearArray indexOfObject:[NSString stringWithFormat:@"%@年", yearStr]];
                self.monthIndex = [self.monthArray indexOfObject:[NSString stringWithFormat:@"%@月", monthStr]];
                
                [self.pickerView selectRow:self.yearIndex inComponent:0 animated:YES];
                [self.pickerView selectRow:self.monthIndex inComponent:1 animated:YES];
                
                [self pickerView:self.pickerView didSelectRow:self.yearIndex inComponent:0];
                [self pickerView:self.pickerView didSelectRow:self.monthIndex inComponent:1];
            }
                break;
            default:
            {
                self.yearIndex = [self.yearArray indexOfObject:[NSString stringWithFormat:@"%@年", yearStr]];
                
                [self.pickerView selectRow:self.yearIndex inComponent:0 animated:YES];
                
                [self pickerView:self.pickerView didSelectRow:self.yearIndex inComponent:0];
            }
                break;
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            switch (self.pickerType)
            {
                case PPickerTypeYMD:
                {
                    UILabel *label = (UILabel *)[self.pickerView viewForRow:self.yearIndex forComponent:0];
                    label.textColor = [UIColor blackColor];
                    label.font = font;
                    
                    label = (UILabel *)[self.pickerView viewForRow:self.monthIndex forComponent:1];
                    label.textColor = [UIColor blackColor];
                    label.font = font;
                    
                    label = (UILabel *)[self.pickerView viewForRow:self.dayIndex forComponent:2];
                    label.textColor = [UIColor blackColor];
                    label.font = font;
                }
                    break;
                case PPickerTypeYM:
                {
                    UILabel *label = (UILabel *)[self.pickerView viewForRow:self.yearIndex forComponent:0];
                    label.textColor = [UIColor blackColor];
                    label.font = font;
                    
                    label = (UILabel *)[self.pickerView viewForRow:self.monthIndex forComponent:1];
                    label.textColor = [UIColor blackColor];
                    label.font = font;
                }
                    break;
                default:
                {
                    UILabel *label = (UILabel *)[self.pickerView viewForRow:self.yearIndex forComponent:0];
                    label.textColor = [UIColor blackColor];
                    label.font = font;
                }
                    break;
            }
        });
    }
    return self;
}

-(void)pickerShow
{
    [kAppDelegateWindow addSubview:self];
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(kAppDelegateWindow);
    }];
    
    POPSpringAnimation *animation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerTranslationY];
    self.pickerView.layer.transform = CATransform3DMakeTranslation(0, HEIGHT_PICKER, 0);
    self.topV.layer.transform = CATransform3DMakeTranslation(0, HEIGHT_BUTTON, 0);
    animation.toValue = @(0);
    animation.springBounciness = 1.0f;
    [self.pickerView.layer pop_addAnimation:animation forKey:@"PickerAnimation"];
    [self.topV.layer pop_addAnimation:animation forKey:@"PickerAnimation"];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.pickerBackground mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(self);
    }];
    
    UIDevice *device = [UIDevice currentDevice];

    [self.pickerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.pickerBackground);
        if (device.orientation == UIDeviceOrientationLandscapeRight || device.orientation == UIDeviceOrientationLandscapeLeft)
        {
            make.width.offset(kSCREEN_HEIGHT);
        }
        else
        {
            make.width.offset(kSCREEN_WIDTH);
        }
        make.bottom.equalTo(self.pickerBackground);
        make.height.offset(HEIGHT_PICKER);
    }];
    
    [self.topV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.pickerView);
        make.height.offset(HEIGHT_BUTTON);
        make.bottom.equalTo(self.pickerView.mas_top);
    }];

    if (device.orientation == UIDeviceOrientationLandscapeRight || device.orientation == UIDeviceOrientationLandscapeLeft)
    {
        self.topV.viewUI_rectCorner = UIRectCornerTopLeft | UIRectCornerTopRight;
        self.pickerView.viewUI_rectCorner = UIRectCornerBottomRight | UIRectCornerBottomLeft;
    }
    
    [self.cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.topV).offset(10);
        make.bottom.equalTo(self.topV).offset(-5);
        make.top.equalTo(self.topV).offset(5);
        make.width.offset(self.labelFont.pointSize*self.cancelBtn.titleLabel.text.length+5*2);
    }];
    
    [self.yesBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.topV).offset(-10);
        make.bottom.equalTo(self.topV).offset(-5);
        make.top.equalTo(self.topV).offset(5);
        make.width.offset(self.labelFont.pointSize*self.cancelBtn.titleLabel.text.length+5*2);
    }];
    
    [self.nameTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self.topV);
        make.centerX.equalTo(self.topV.mas_centerX);
        make.left.equalTo(self.cancelBtn.mas_right).offset(5);
        make.right.equalTo(self.yesBtn.mas_left).offset(-5);
    }];
}

- (void)hideViewAction:(UITapGestureRecognizer *)gesture {
    [self remove];
}

#pragma mark -UIPickerView
#pragma mark UIPickerView的数据源
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    switch (self.pickerType)
    {
        case PPickerTypeYMD:
        {
            return 3;
        }
            break;
        case PPickerTypeYM:
        {
            return 2;
        }
        default:
        {
            return 1;
        }
            break;
    }
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (component == 0)
    {
        return self.yearArray.count;
    }
    else if(component == 1)
    {
        if (self.pickerType == PPickerTypeYMD || self.pickerType == PPickerTypeYM)
        {
            return self.monthArray.count;
        }
    }
    else
    {
        if (self.pickerType == PPickerTypeYMD)
        {
            switch (self.monthIndex + 1)
            {
                case 1:
                case 3:
                case 5:
                case 7:
                case 8:
                case 10:
                case 12: return 31;
                    
                case 4:
                case 6:
                case 9:
                case 11: return 30;
                    
                default: return 28;
            }
        }
    }
    return 0;
}

- (void)remove
{
    POPBasicAnimation *offscreenAnimation = [POPBasicAnimation easeOutAnimation];
    offscreenAnimation.property = [POPAnimatableProperty propertyWithName:kPOPLayerTranslationY];
    offscreenAnimation.toValue = @(HEIGHT_PICKER);
    offscreenAnimation.duration = 0.35f;
    [offscreenAnimation setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        [UIView animateWithDuration:0.35f delay:0 usingSpringWithDamping:0.9f initialSpringVelocity:0.7f options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionLayoutSubviews animations:^{
            self.pickerBackground.alpha = 0.0;
        } completion:^(BOOL finished) {

            [self removeFromSuperview];
        }];
    }];
    [self.pickerView.layer pop_addAnimation:offscreenAnimation forKey:@"offscreenAnimation"];
    [self.topV.layer pop_addAnimation:offscreenAnimation forKey:@"offscreenAnimation"];
}

#pragma mark -UIPickerView的代理

// 滚动UIPickerView就会调用
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (component == 0)
    {
        self.yearIndex = row;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UILabel *label = (UILabel *)[pickerView viewForRow:row forComponent:component];
            label.textColor = self.pickerFontColor;
            label.font = self.pickerFonts;
        });
    }
    else if (component == 1)
    {
        if (self.pickerType == PPickerTypeYMD || self.pickerType == PPickerTypeYM)
        {
            self.monthIndex = row;
            if (self.pickerType == PPickerTypeYMD)
            {
                [pickerView reloadComponent:2];
            }
            
            if (self.monthIndex + 1 == 4 || self.monthIndex + 1 == 6 || self.monthIndex + 1 == 9 || self.monthIndex + 1 == 11)
            {
                if (self.pickerType == PPickerTypeYMD)
                {
                    if (self.dayIndex + 1 == 31)
                    {
                        self.dayIndex--;
                    }
                }
            }
            else if (self.monthIndex + 1 == 2)
            {
                if (self.pickerType == PPickerTypeYMD)
                {
                    if (self.dayIndex + 1 > 28)
                    {
                        self.dayIndex = 27;
                    }
                }
            }
            if (self.pickerType == PPickerTypeYMD)
            {
                [pickerView selectRow:self.dayIndex inComponent:2 animated:YES];
            }
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                UILabel *label = (UILabel *)[pickerView viewForRow:row forComponent:component];
                label.textColor = self.pickerFontColor;
                label.font = self.pickerFonts;
                
                if (self.pickerType == PPickerTypeYMD)
                {
                    label = (UILabel *)[pickerView viewForRow:self.dayIndex forComponent:2];
                    label.textColor = self.pickerFontColor;
                    label.font = self.pickerFonts;
                }
            });
        }
    }
    else
    {
        if (self.pickerType == PPickerTypeYMD)
        {
            self.dayIndex = row;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                UILabel *label = (UILabel *)[pickerView viewForRow:row forComponent:component];
                label.textColor = self.pickerFontColor;
                label.font = self.pickerFonts;
            });
        }
    }
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    //设置文字的属性
    UILabel *genderLabel = [[UILabel alloc] init];
    genderLabel.textAlignment = NSTextAlignmentCenter;
    genderLabel.textColor = self.pickerFontColor;
    genderLabel.font = self.pickerFonts;
    if (component == 0)
    {
        genderLabel.text = self.yearArray[row];
    }
    else if (component == 1)
    {
        if (self.pickerType == PPickerTypeYMD || self.pickerType == PPickerTypeYM)
        {
            genderLabel.text = self.monthArray[row];
        }
    }
    else
    {
        if (self.pickerType == PPickerTypeYMD)
        {
            genderLabel.text = self.dayArray[row];
        }
    }
    return genderLabel;
}
@end

#pragma mark ------> TimePicker
@interface PooTimePicker()<UIPickerViewDataSource,UIPickerViewDelegate>
@property (nonatomic, strong) UIView *topV;
@property (nonatomic, strong) UIFont *pickerFonts;
@property (nonatomic, assign) NSInteger hourIndex;
@property (nonatomic, assign) NSInteger minuteIndex;
@property (nonatomic,strong) UIView *pickerBackground;
@property (nonatomic,strong) UILabel *nameTitle;
@property (nonatomic,strong) UIButton *cancelBtn;
@property (nonatomic,strong) UIButton *yesBtn;
@property (nonatomic, strong) UIFont *labelFont;
@property (nonatomic, strong) UIColor *pickerBackgroundColor;
@property (nonatomic, strong) UIColor *pickerFontColor;
@end

@implementation PooTimePicker

+(NSInteger)getEditHourIndexWithTimeString:(NSString*)str
{
    NSString *hourStr = [str substringToIndex:2];
    NSInteger hourIndex  = [[PooTimePicker hourArray] indexOfObject:hourStr];
    
    return hourIndex;
}

+(NSInteger)getEditMinuteIndexWithTimeString:(NSString*)str
{
    NSString *minuteStr = [str substringFromIndex:3];
    NSInteger minuteIndex  = [[PooTimePicker minuteArray] indexOfObject:minuteStr];
    
    return minuteIndex;
}

+(NSMutableArray *)hourArray
{
    NSMutableArray *hour = [[NSMutableArray alloc] init];
    for (int i = 0; i <= 23; i++) {
        
        NSString *str = [NSString stringWithFormat:@"%02d", i];
        
        [hour addObject:str];
    }
    return hour;
}

+(NSMutableArray *)minuteArray
{
    NSMutableArray *minute = [[NSMutableArray alloc] init];
    for (int i = 0; i <= 59; i++) {
        
        NSString *str = [NSString stringWithFormat:@"%02d", i];
        
        [minute addObject:str];
    }
    return minute;
}

- (instancetype)initWithTitle:(NSString *)title
       toolBarBackgroundColor:(UIColor *)tbbc
                    labelFont:(UIFont *)font
            toolBarTitleColor:(UIColor *)tbtc
                   pickerFont:(UIFont *)pf
        pickerBackgroundColor:(UIColor *)pBGColor
              pickerFontColor:(UIColor *)pfColor
{
    self = [super init];
    if (self)
    {
        self.pickerFonts = pf;
        self.labelFont = font;
        self.pickerBackgroundColor = pBGColor ? pBGColor : [UIColor whiteColor];
        self.pickerFontColor = pfColor ? pfColor : [UIColor blackColor];
        
        self.pickerBackground = [UIView new];
        self.pickerBackground.backgroundColor    = kDevMaskBackgroundColor;
        [self addSubview:self.pickerBackground];

        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideViewAction:)];
        tapGesture.numberOfTapsRequired = 1;
        [self.pickerBackground addGestureRecognizer:tapGesture];
        
        self.topV = [UIView new];
        self.topV.backgroundColor = tbbc;
        [self.pickerBackground addSubview:self.topV];
        
        self.nameTitle = [UILabel new];
        self.nameTitle.textAlignment = NSTextAlignmentCenter;
        self.nameTitle.textColor = tbtc;
        self.nameTitle.font = font;
        self.nameTitle.numberOfLines = 0;
        self.nameTitle.lineBreakMode = NSLineBreakByCharWrapping;
        self.nameTitle.text = title;
        [self.topV addSubview:self.nameTitle];
        
        self.cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.cancelBtn.titleLabel setFont:font];
        [self.cancelBtn setBackgroundImage:[Utils createImageWithColor:kDevButtonHighlightedColor] forState:UIControlStateHighlighted];
        [self.cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        [self.cancelBtn setTitleColor:tbtc forState:UIControlStateNormal];
        [self.topV addSubview:self.cancelBtn];
        kViewBorderRadius(self.cancelBtn, 5, 0, kClearColor);

        self.yesBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.yesBtn.titleLabel setFont:font];
        [self.yesBtn setBackgroundImage:[Utils createImageWithColor:kDevButtonHighlightedColor] forState:UIControlStateHighlighted];
        [self.yesBtn setTitle:@"完成" forState:UIControlStateNormal];
        [self.yesBtn setTitleColor:tbtc forState:UIControlStateNormal];
        [self.topV addSubview:self.yesBtn];
        kViewBorderRadius(self.yesBtn, 5, 0, kClearColor);

        kWeakSelf(self);
        
        [self.cancelBtn addActionHandler:^(UIButton *sender) {
            [weakself remove];
        }];
        
        [self.yesBtn addActionHandler:^(UIButton *sender) {
            if ([Utils isRolling:weakself.pickerView])
            {
                return;
            }
            UILabel *pickerViewCom0 = (UILabel *)[weakself.pickerView viewForRow:weakself.hourIndex forComponent:0];
            
            UILabel *pickerViewCom1 = (UILabel *)[weakself.pickerView viewForRow:weakself.minuteIndex forComponent:1];
            
            NSString *timeStr = [NSString stringWithFormat:@"%@:%@",pickerViewCom0.text, pickerViewCom1.text];
            
            if (weakself.block)
            {
                
                weakself.block(timeStr);
            }
            
            if ([weakself.delegate respondsToSelector:@selector(timePickerReturnStr:timePicker:)]) {
                [weakself.delegate timePickerReturnStr:timeStr timePicker:weakself];
            }
            
            [weakself remove];
        }];
        
        _pickerView = [UIPickerView new];
        _pickerView.dataSource = self;
        _pickerView.delegate = self;
        _pickerView.backgroundColor = self.pickerBackgroundColor;
        [self.pickerBackground addSubview:_pickerView];
  
    }
    return self;
}

- (void)hideViewAction:(UITapGestureRecognizer *)gesture {
    [self remove];
}

- (void)remove
{
    [self pickerHide];
}

-(void)pickerHide
{
    POPBasicAnimation *offscreenAnimation = [POPBasicAnimation easeOutAnimation];
    offscreenAnimation.property = [POPAnimatableProperty propertyWithName:kPOPLayerTranslationY];
    offscreenAnimation.toValue = @(HEIGHT_PICKER);
    offscreenAnimation.duration = 0.35f;
    [offscreenAnimation setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        [UIView animateWithDuration:0.35f delay:0 usingSpringWithDamping:0.9f initialSpringVelocity:0.7f options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionLayoutSubviews animations:^{
            self.pickerBackground.alpha = 0.0;
        } completion:^(BOOL finished) {
            if (self.dismissBlock) {
                self.dismissBlock(self);
            }
            
            if ([self.delegate respondsToSelector:@selector(timePickerDismiss:)]) {
                [self.delegate timePickerDismiss:self];
            }
            [self removeFromSuperview];
        }];
    }];
    [self.pickerView.layer pop_addAnimation:offscreenAnimation forKey:@"offscreenAnimation"];
    [self.topV.layer pop_addAnimation:offscreenAnimation forKey:@"offscreenAnimation"];
}

-(void)pickerShow
{
    [kAppDelegateWindow addSubview:self];
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(kAppDelegateWindow);
    }];
    POPSpringAnimation *animation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerTranslationY];
    self.pickerView.layer.transform = CATransform3DMakeTranslation(0, HEIGHT_PICKER, 0);
    self.topV.layer.transform = CATransform3DMakeTranslation(0, HEIGHT_BUTTON, 0);
    animation.toValue = @(0);
    animation.springBounciness = 1.0f;
    [self.pickerView.layer pop_addAnimation:animation forKey:@"PickerAnimation"];
    [self.topV.layer pop_addAnimation:animation forKey:@"PickerAnimation"];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.pickerBackground mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(self);
    }];
    
    UIDevice *device = [UIDevice currentDevice];
    [self.pickerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.pickerBackground);
        if (device.orientation == UIDeviceOrientationLandscapeRight || device.orientation == UIDeviceOrientationLandscapeLeft)
        {
            make.width.offset(kSCREEN_HEIGHT);
        }
        else
        {
            make.width.offset(kSCREEN_WIDTH);
        }
        make.bottom.equalTo(self.pickerBackground);
        make.height.offset(HEIGHT_PICKER);
    }];
    
    [self.topV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.pickerView);
        make.height.offset(HEIGHT_BUTTON);
        make.bottom.equalTo(self.pickerView.mas_top);
    }];
    
    if (device.orientation == UIDeviceOrientationLandscapeRight || device.orientation == UIDeviceOrientationLandscapeLeft)
    {
        self.topV.viewUI_rectCorner = UIRectCornerTopLeft | UIRectCornerTopRight;
        self.pickerView.viewUI_rectCorner = UIRectCornerBottomRight | UIRectCornerBottomLeft;
    }
    
    [self.cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.topV).offset(10);
        make.bottom.equalTo(self.topV).offset(-5);
        make.top.equalTo(self.topV).offset(5);
        make.width.offset(self.labelFont.pointSize*self.cancelBtn.titleLabel.text.length+5*2);
    }];
    
    [self.yesBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.topV).offset(-10);
        make.bottom.equalTo(self.topV).offset(-5);
        make.top.equalTo(self.topV).offset(5);
        make.width.offset(self.labelFont.pointSize*self.cancelBtn.titleLabel.text.length+5*2);
    }];
    
    [self.nameTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self.topV);
        make.centerX.equalTo(self.topV.mas_centerX);
        make.left.equalTo(self.cancelBtn.mas_right).offset(5);
        make.right.equalTo(self.yesBtn.mas_left).offset(-5);
    }];
}

#pragma mark ------> UIPickerViewDataSource
//返回有几列
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView

{
    return 2;
}

//返回指定列的行数
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component

{
    if (component == 0)
    {
        return  [PooTimePicker hourArray].count;
    }
    else if(component == 1)
    {
        return  [PooTimePicker minuteArray].count;
    }
    return 0;
}

// 自定义指定列的每行的视图，即指定列的每行的视图行为一致
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *text = [[UILabel alloc] init];
    text.textColor = self.pickerFontColor;
    text.textAlignment = NSTextAlignmentCenter;
    text.font = self.pickerFonts;
    
    switch (component)
    {
        case 0:
        {
            text.text = [PooTimePicker hourArray][row];
        }
            break;
        case 1:
        {
            text.text = [PooTimePicker minuteArray][row];
        }
            break;
        default:
            break;
    }
    return text;
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    switch (component) {
        case 0:
        {
            self.hourIndex = row;
            UILabel *pickerViews = (UILabel *)[pickerView viewForRow:row forComponent:component];
            pickerViews.textColor = self.pickerFontColor;
            pickerViews.font = self.pickerFonts;
        }
            break;
        case 1:
        {
            self.minuteIndex = row;
            UILabel *pickerViews = (UILabel *)[pickerView viewForRow:row forComponent:component];
            pickerViews.textColor = self.pickerFontColor;
            pickerViews.font = self.pickerFonts;
        }
            break;
        default:
            break;
    }
}

-(void)customSelectRow:(NSInteger)row inComponent:(NSInteger)component animated:(BOOL)animated
{
    [self.pickerView selectRow:row inComponent:component animated:YES];
}

-(void)customPickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [self pickerView:pickerView didSelectRow:row inComponent:component];
}
@end
