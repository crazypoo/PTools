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
@end

@implementation PooDatePicker
- (NSMutableArray *)yearArray
{
    if (_yearArray == nil)
    {
        _yearArray = [NSMutableArray array];
        for (int year = 2000; year < 2050; year++)
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

- (instancetype)initWithTitle:(NSString *)title toolBarBackgroundColor:(UIColor *)tbbc labelFont:(UIFont *)font toolBarTitleColor:(UIColor *)tbtc pickerFont:(UIFont *)pf pickerType:(PPickerType)pT
{
    self = [super init];
    if (self)
    {
        self.pickerFonts = pf;
        self.pickerType = pT;
        self.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.5];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideViewAction:)];
        tapGesture.numberOfTapsRequired = 1;
        [self addGestureRecognizer:tapGesture];
        
        self.topV = [UIView new];
        self.topV.backgroundColor = tbbc;
        [self addSubview:self.topV];
        [self.topV mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self);
            make.height.offset(44);
            make.top.equalTo(self.mas_bottom).offset(-44-216);
        }];
        
        UILabel *nameTitle = [UILabel new];
        nameTitle.textAlignment = NSTextAlignmentCenter;
        nameTitle.textColor = tbtc;
        nameTitle.font = font;
        nameTitle.text = title;
        [self.topV addSubview:nameTitle];
        
        UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [cancelBtn.titleLabel setFont:font];
        [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        [cancelBtn setTitleColor:tbtc forState:UIControlStateNormal];
        [self.topV addSubview:cancelBtn];
        [cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.topV).offset(10);
            make.top.bottom.equalTo(self.topV);
            make.width.offset(font.pointSize*cancelBtn.titleLabel.text.length+5*2);
        }];
        
        UIButton *yesBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [yesBtn.titleLabel setFont:font];
        [yesBtn setTitle:@"完成" forState:UIControlStateNormal];
        [yesBtn setTitleColor:tbtc forState:UIControlStateNormal];
        [self.topV addSubview:yesBtn];
        [yesBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.topV).offset(-10);
            make.top.bottom.equalTo(self.topV);
            make.width.offset(font.pointSize*cancelBtn.titleLabel.text.length+5*2);
        }];
        
        [nameTitle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self.topV);
            make.centerX.equalTo(self.topV.mas_centerX);
            make.left.equalTo(cancelBtn.mas_right);
            make.right.equalTo(yesBtn.mas_left);
        }];
        
        [cancelBtn addActionHandler:^(UIButton *sender) {
            if (self.block)
            {
                self.block(nil);
            }
            [self remove];
        }];
        
        [yesBtn addActionHandler:^(UIButton *sender) {
            if (self.block)
            {
                switch (self.pickerType)
                {
                    case PPickerTypeYMD:
                    {
                        NSString *timeStr = [NSString stringWithFormat:@"%@%@%@",((UILabel *)[self.pickerView viewForRow:self.yearIndex forComponent:0]).text, ((UILabel *)[self.pickerView viewForRow:self.monthIndex forComponent:1]).text, ((UILabel *)[self.pickerView viewForRow:self.dayIndex forComponent:2]).text];
                        
                        timeStr = [timeStr stringByReplacingOccurrencesOfString:@"年" withString:@"-"];
                        timeStr = [timeStr stringByReplacingOccurrencesOfString:@"月" withString:@"-"];
                        timeStr = [timeStr stringByReplacingOccurrencesOfString:@"日" withString:@""];
                        
                        self.block(timeStr);
                    }
                        break;
                    case PPickerTypeYM:
                    {
                        NSString *timeStr = [NSString stringWithFormat:@"%@%@",((UILabel *)[self.pickerView viewForRow:self.yearIndex forComponent:0]).text, ((UILabel *)[self.pickerView viewForRow:self.monthIndex forComponent:1]).text];
                        
                        timeStr = [timeStr stringByReplacingOccurrencesOfString:@"年" withString:@"-"];
                        timeStr = [timeStr stringByReplacingOccurrencesOfString:@"月" withString:@"-"];
                        
                        NSString *newTime = [timeStr substringToIndex:timeStr.length-1];
                        
                        self.block(newTime);
                    }
                        break;
                    default:
                    {
                        NSString *timeStr = [NSString stringWithFormat:@"%@",((UILabel *)[self.pickerView viewForRow:self.yearIndex forComponent:0]).text];
                        
                        timeStr = [timeStr stringByReplacingOccurrencesOfString:@"年" withString:@"-"];
                        
                        NSString *newTime = [timeStr substringToIndex:timeStr.length-1];
                        
                        self.block(newTime);
                    }
                        break;
                }
            }
            [self remove];
        }];
        
        _pickerView = [UIPickerView new];
        _pickerView.dataSource = self;
        _pickerView.delegate = self;
        _pickerView.backgroundColor = [UIColor whiteColor];
        [self addSubview:_pickerView];
        [_pickerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self);
            make.height.offset(216);
            make.bottom.equalTo(self);
        }];
        
        NSCalendar *calendar = [[NSCalendar alloc]
                                initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        // 定义一个时间字段的旗标，指定将会获取指定年、月、日、时、分、秒的信息
        unsigned unitFlags = NSCalendarUnitYear |
        NSCalendarUnitMonth |  NSCalendarUnitDay |
        NSCalendarUnitHour |  NSCalendarUnitMinute |
        NSCalendarUnitSecond | NSCalendarUnitWeekday;
        // 获取不同时间字段的信息
        NSDateComponents *comp = [calendar components: unitFlags fromDate:[NSDate date]];
        
        switch (self.pickerType)
        {
            case PPickerTypeYMD:
            {
                self.yearIndex = [self.yearArray indexOfObject:[NSString stringWithFormat:@"%ld年", (long)comp.year]];
                self.monthIndex = [self.monthArray indexOfObject:[NSString stringWithFormat:@"%02ld月", (long)comp.month]];
                self.dayIndex = [self.dayArray indexOfObject:[NSString stringWithFormat:@"%02ld日", (long)comp.day]];
                
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
                self.yearIndex = [self.yearArray indexOfObject:[NSString stringWithFormat:@"%ld年", (long)comp.year]];
                self.monthIndex = [self.monthArray indexOfObject:[NSString stringWithFormat:@"%02ld月", (long)comp.month]];
                
                [self.pickerView selectRow:self.yearIndex inComponent:0 animated:YES];
                [self.pickerView selectRow:self.monthIndex inComponent:1 animated:YES];
                
                [self pickerView:self.pickerView didSelectRow:self.yearIndex inComponent:0];
                [self pickerView:self.pickerView didSelectRow:self.monthIndex inComponent:1];
            }
                break;
            default:
            {
                self.yearIndex = [self.yearArray indexOfObject:[NSString stringWithFormat:@"%ld年", (long)comp.year]];
                
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
    [UIView animateWithDuration:0.25 animations:^{
        
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
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
            label.textColor = [UIColor blackColor];
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
                label.textColor = [UIColor blackColor];
                label.font = self.pickerFonts;
                
                if (self.pickerType == PPickerTypeYMD)
                {
                    label = (UILabel *)[pickerView viewForRow:self.dayIndex forComponent:2];
                    label.textColor = [UIColor blackColor];
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
                label.textColor = [UIColor blackColor];
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
    genderLabel.textColor = [UIColor blackColor];
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

- (instancetype)initWithTitle:(NSString *)title toolBarBackgroundColor:(UIColor *)tbbc labelFont:(UIFont *)font toolBarTitleColor:(UIColor *)tbtc pickerFont:(UIFont *)pf
{
    self = [super init];
    if (self)
    {
        self.pickerFonts = pf;
        self.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.5];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideViewAction:)];
        tapGesture.numberOfTapsRequired = 1;
        [self addGestureRecognizer:tapGesture];
        
        self.topV = [UIView new];
        self.topV.backgroundColor = tbbc;
        [self addSubview:self.topV];
        [self.topV mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self);
            make.height.offset(44);
            make.top.equalTo(self.mas_bottom).offset(-44-216);
        }];
        
        UILabel *nameTitle = [UILabel new];
        nameTitle.textAlignment = NSTextAlignmentCenter;
        nameTitle.textColor = tbtc;
        nameTitle.font = font;
        nameTitle.text = title;
        [self.topV addSubview:nameTitle];
        
        UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [cancelBtn.titleLabel setFont:font];
        [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        [cancelBtn setTitleColor:tbtc forState:UIControlStateNormal];
        [self.topV addSubview:cancelBtn];
        [cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.topV).offset(10);
            make.top.bottom.equalTo(self.topV);
            make.width.offset(font.pointSize*cancelBtn.titleLabel.text.length+5*2);
        }];
        
        UIButton *yesBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [yesBtn.titleLabel setFont:font];
        [yesBtn setTitle:@"完成" forState:UIControlStateNormal];
        [yesBtn setTitleColor:tbtc forState:UIControlStateNormal];
        [self.topV addSubview:yesBtn];
        [yesBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.topV).offset(-10);
            make.top.bottom.equalTo(self.topV);
            make.width.offset(font.pointSize*cancelBtn.titleLabel.text.length+5*2);
        }];
        
        [nameTitle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self.topV);
            make.centerX.equalTo(self.topV.mas_centerX);
            make.left.equalTo(cancelBtn.mas_right);
            make.right.equalTo(yesBtn.mas_left);
        }];
        
        [cancelBtn addActionHandler:^(UIButton *sender) {
            [self remove];
        }];
        
        [yesBtn addActionHandler:^(UIButton *sender) {
            UIView *pickerViewCom0 = (UIView *)[self.pickerView viewForRow:self.hourIndex forComponent:0];
            UILabel *pickerLabel0 = (UILabel *)[pickerViewCom0 subviews].lastObject;
            
            UIView *pickerViewCom1 = (UIView *)[self.pickerView viewForRow:self.minuteIndex forComponent:1];
            UILabel *pickerLabel1 = (UILabel *)[pickerViewCom1 subviews].lastObject;
            
            NSString *timeStr = [NSString stringWithFormat:@"%@:%@",pickerLabel0.text, pickerLabel1.text];
            
            if (self.block)
            {
                
                self.block(timeStr);
            }
            
            if ([self.delegate respondsToSelector:@selector(timePickerReturnStr:timePicker:)]) {
                [self.delegate timePickerReturnStr:timeStr timePicker:self];
            }
            
            [self remove];
        }];
        
        _pickerView = [UIPickerView new];
        _pickerView.dataSource = self;
        _pickerView.delegate = self;
        _pickerView.backgroundColor = [UIColor whiteColor];
        [self addSubview:_pickerView];
        [_pickerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self);
            make.height.offset(216);
            make.bottom.equalTo(self);
        }];
    }
    return self;
}

- (void)hideViewAction:(UITapGestureRecognizer *)gesture {
    [self remove];
}

- (void)remove
{
    [UIView animateWithDuration:0.25 animations:^{
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        if (self.dismissBlock) {
            self.dismissBlock(self);
        }
        
        if ([self.delegate respondsToSelector:@selector(timePickerDismiss:)]) {
            [self.delegate timePickerDismiss:self];
        }
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
    if (!view)
    {
        view = [[UIView alloc]init];
    }
    
    UILabel *text = [UILabel new];
    text.textColor = [UIColor blackColor];
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
    [view addSubview:text];
    [text mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.height.equalTo(view);
    }];
    
    return view;
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    switch (component) {
        case 0:
        {
            self.hourIndex = row;
            UIView *pickerViews = (UIView *)[pickerView viewForRow:row forComponent:component];
            UILabel *pickerLabel = (UILabel *)[pickerViews subviews].lastObject;
            pickerLabel.textColor = [UIColor blackColor];
            pickerLabel.font = self.pickerFonts;
        }
            break;
        case 1:
        {
            self.minuteIndex = row;
            UIView *pickerViews = (UIView *)[pickerView viewForRow:row forComponent:component];
            UILabel *pickerLabel = (UILabel *)[pickerViews subviews].lastObject;
            pickerLabel.textColor = [UIColor blackColor];
            pickerLabel.font = self.pickerFonts;
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
