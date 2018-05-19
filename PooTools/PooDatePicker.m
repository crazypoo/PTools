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

@interface PooDatePicker ()<UITextFieldDelegate,UIPickerViewDataSource,UIPickerViewDelegate>
{
    UIView *topV;
}
@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) NSMutableArray *yearArray;
@property (nonatomic, strong) NSMutableArray *monthArray;
@property (nonatomic, strong) NSMutableArray *dayArray;
@property (nonatomic, strong) UIFont *pickerFonts;
@property (nonatomic, assign) NSInteger yearIndex;
@property (nonatomic, assign) NSInteger monthIndex;
@property (nonatomic, assign) NSInteger dayIndex;
@end

@implementation PooDatePicker
- (NSMutableArray *)yearArray {
    
    if (_yearArray == nil) {
        
        _yearArray = [NSMutableArray array];
        
        for (int year = 2000; year < 2050; year++) {
            
            NSString *str = [NSString stringWithFormat:@"%d年", year];
            
            [_yearArray addObject:str];
        }
    }
    
    return _yearArray;
}

- (NSMutableArray *)monthArray {
    
    if (_monthArray == nil) {
        
        _monthArray = [NSMutableArray array];
        
        for (int month = 1; month <= 12; month++) {
            
            NSString *str = [NSString stringWithFormat:@"%02d月", month];
            
            [_monthArray addObject:str];
        }
    }
    
    return _monthArray;
}

- (NSMutableArray *)dayArray {
    
    if (_dayArray == nil) {
        
        _dayArray = [NSMutableArray array];
        
        for (int day = 1; day <= 31; day++) {
            
            NSString *str = [NSString stringWithFormat:@"%02d日", day];
            
            [_dayArray addObject:str];
        }
    }
    
    return _dayArray;
}


- (instancetype)initWithTitle:(NSString *)title toolBarBackgroundColor:(UIColor *)tbbc labelFont:(UIFont *)font toolBarTitleColor:(UIColor *)tbtc pickerFont:(UIFont *)pf
{
    self = [super initWithFrame:[UIApplication sharedApplication].keyWindow.frame];
    if (self) {
        self.pickerFonts = pf;
        self.backgroundColor    = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.5];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideViewAction:)];
        tapGesture.numberOfTapsRequired    = 1;
        [self addGestureRecognizer:tapGesture];
        
        topV = [[UIView alloc] initWithFrame:CGRectMake(0, kSCREEN_HEIGHT-44-216, kSCREEN_WIDTH, 44)];
        topV.backgroundColor = tbbc;
        [self addSubview:topV];
        
        UILabel *nameTitle = [[UILabel alloc] initWithFrame:topV.bounds];
        nameTitle.textAlignment = NSTextAlignmentCenter;
        nameTitle.textColor = tbtc;
        nameTitle.font = font;
        nameTitle.text = title;
        [topV addSubview:nameTitle];

        UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        cancelBtn.frame = CGRectMake(10, 0, 50, 44);
        [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        [cancelBtn setTitleColor:tbtc forState:UIControlStateNormal];
        [cancelBtn.titleLabel setFont:font];
        [topV addSubview:cancelBtn];
        
        UIButton *yesBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        yesBtn.frame = CGRectMake(kSCREEN_WIDTH-60, 0, 50, 44);
        [yesBtn setTitle:@"完成" forState:UIControlStateNormal];
        [yesBtn setTitleColor:tbtc forState:UIControlStateNormal];
        [yesBtn.titleLabel setFont:font];
        [topV addSubview:yesBtn];
        
        [cancelBtn addActionHandler:^(NSInteger tag) {
            if (self.block) {
                self.block(nil);
            }
            
            [self remove];
        }];
        
        [yesBtn addActionHandler:^(NSInteger tag) {
            if (self.block) {
                
                NSString *timeStr = [NSString stringWithFormat:@"%@%@%@",((UILabel *)[self.pickerView viewForRow:self.yearIndex forComponent:0]).text, ((UILabel *)[self.pickerView viewForRow:self.monthIndex forComponent:1]).text, ((UILabel *)[self.pickerView viewForRow:self.dayIndex forComponent:2]).text];
                
                
                timeStr = [timeStr stringByReplacingOccurrencesOfString:@"年" withString:@"-"];
                
                timeStr = [timeStr stringByReplacingOccurrencesOfString:@"月" withString:@"-"];
                
                timeStr = [timeStr stringByReplacingOccurrencesOfString:@"日" withString:@""];
                
                self.block(timeStr);
                
            }
            [self remove];
        }];
        
        _pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, kSCREEN_HEIGHT-216, kSCREEN_WIDTH, 216)];
        _pickerView.dataSource = self;
        _pickerView.delegate = self;
        _pickerView.backgroundColor = [UIColor whiteColor];
        [self addSubview:_pickerView];
        
        NSCalendar *calendar = [[NSCalendar alloc]
                                initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        // 定义一个时间字段的旗标，指定将会获取指定年、月、日、时、分、秒的信息
        unsigned unitFlags = NSCalendarUnitYear |
        NSCalendarUnitMonth |  NSCalendarUnitDay |
        NSCalendarUnitHour |  NSCalendarUnitMinute |
        NSCalendarUnitSecond | NSCalendarUnitWeekday;
        // 获取不同时间字段的信息
        NSDateComponents *comp = [calendar components: unitFlags fromDate:[NSDate date]];
        
        self.yearIndex = [self.yearArray indexOfObject:[NSString stringWithFormat:@"%ld年", comp.year]];
        self.monthIndex = [self.monthArray indexOfObject:[NSString stringWithFormat:@"%02ld月", comp.month]];
        self.dayIndex = [self.dayArray indexOfObject:[NSString stringWithFormat:@"%02ld日", comp.day]];
        
        [self.pickerView selectRow:self.yearIndex inComponent:0 animated:YES];
        [self.pickerView selectRow:self.monthIndex inComponent:1 animated:YES];
        [self.pickerView selectRow:self.dayIndex inComponent:2 animated:YES];
        
        [self pickerView:self.pickerView didSelectRow:self.yearIndex inComponent:0];
        [self pickerView:self.pickerView didSelectRow:self.monthIndex inComponent:1];
        [self pickerView:self.pickerView didSelectRow:self.dayIndex inComponent:2];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            UILabel *label = (UILabel *)[self.pickerView viewForRow:self.yearIndex forComponent:0];
            label.textColor = [UIColor blackColor];
            label.font = font;
            
            label = (UILabel *)[self.pickerView viewForRow:self.monthIndex forComponent:1];
            label.textColor = [UIColor blackColor];
            label.font = font;
            
            label = (UILabel *)[self.pickerView viewForRow:self.dayIndex forComponent:2];
            label.textColor = [UIColor blackColor];
            label.font = font;
            
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
    return 3;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (component == 0) {
        return self.yearArray.count;
        
    }else if(component == 1) {
        
        return self.monthArray.count;
        
    }else {
        
        switch (self.monthIndex + 1) {
                
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


- (void)remove {
    
    [UIView animateWithDuration:0.25 animations:^{
        
    } completion:^(BOOL finished) {
        
        [self removeFromSuperview];
    }];
    
}
#pragma mark -UIPickerView的代理

// 滚动UIPickerView就会调用
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (component == 0) {
        
        self.yearIndex = row;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            UILabel *label = (UILabel *)[pickerView viewForRow:row forComponent:component];
            label.textColor = [UIColor blackColor];
            label.font = self.pickerFonts;
            
        });
        
    }else if (component == 1) {
        
        self.monthIndex = row;
        
        [pickerView reloadComponent:2];
        
        
        if (self.monthIndex + 1 == 4 || self.monthIndex + 1 == 6 || self.monthIndex + 1 == 9 || self.monthIndex + 1 == 11) {
            
            if (self.dayIndex + 1 == 31) {
                
                self.dayIndex--;
            }
        }else if (self.monthIndex + 1 == 2) {
            
            if (self.dayIndex + 1 > 28) {
                self.dayIndex = 27;
            }
        }
        [pickerView selectRow:self.dayIndex inComponent:2 animated:YES];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            UILabel *label = (UILabel *)[pickerView viewForRow:row forComponent:component];
            label.textColor = [UIColor blackColor];
            label.font = self.pickerFonts;
            
            label = (UILabel *)[pickerView viewForRow:self.dayIndex forComponent:2];
            label.textColor = [UIColor blackColor];
            label.font = self.pickerFonts;
            
        });
    }else {
        
        self.dayIndex = row;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            UILabel *label = (UILabel *)[pickerView viewForRow:row forComponent:component];
            label.textColor = [UIColor blackColor];
            label.font = self.pickerFonts;
            
        });
    }
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    //    //设置分割线的颜色
    //    for(UIView *singleLine in pickerView.subviews)
    //    {
    //        if (singleLine.frame.size.height < 1)
    //        {
    //            singleLine.backgroundColor = kSingleLineColor;
    //        }
    //    }
    
    //设置文字的属性
    UILabel *genderLabel = [[UILabel alloc] init];
    genderLabel.textAlignment = NSTextAlignmentCenter;
    genderLabel.textColor = [UIColor blackColor];
    genderLabel.font = self.pickerFonts;
    if (component == 0) {
        
        genderLabel.text = self.yearArray[row];
        
    }else if (component == 1) {
        
        genderLabel.text = self.monthArray[row];
        
    }else {
        
        genderLabel.text = self.dayArray[row];
    }
    
    return genderLabel;
}

@end
