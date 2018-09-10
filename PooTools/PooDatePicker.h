//
//  PooDatePicker.h
//  LandloardTool
//
//  Created by mouth on 2018/5/8.
//  Copyright © 2018年 邓杰豪. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,PPickerType){
    PPickerTypeYMD = 0,
    PPickerTypeYM,
    PPickerTypeY
};

@interface PooDatePicker : UIView

/*! @brief 日期Picker初始化
 * @param title 标题
 * @param tbbc tabbar的背景颜色
 * @param font 字体
 * @param tbtc tabbar上的字体颜色
 * @param pf picker的字体
 * @param pT picker显示类型 (年月日/年月/年)
 */
- (instancetype)initWithTitle:(NSString *)title
       toolBarBackgroundColor:(UIColor *)tbbc
                    labelFont:(UIFont *)font
            toolBarTitleColor:(UIColor *)tbtc
                   pickerFont:(UIFont *)pf
                   pickerType:(PPickerType)pT;

/*! @brief 选取回调
 */
@property (nonatomic, copy) void (^block)(NSString *dateString);
@end

@class PooTimePicker;

@protocol PooTimePickerDelegate <NSObject>
-(void)timePickerReturnStr:(NSString *)timeStr timePicker:(PooTimePicker *)timePicker;
-(void)timePickerDismiss:(PooTimePicker *)timePicker;
@end

@interface PooTimePicker : UIView
/*! @brief 时间Picker初始化
 * @param title 标题
 * @param tbbc tabbar的背景颜色
 * @param font 字体
 * @param tbtc tabbar上的字体颜色
 * @param pf picker的字体
 */
- (instancetype)initWithTitle:(NSString *)title
       toolBarBackgroundColor:(UIColor *)tbbc
                    labelFont:(UIFont *)font
            toolBarTitleColor:(UIColor *)tbtc
                   pickerFont:(UIFont *)pf;

@property (nonatomic, copy) void (^block)(NSString *timeString);
@property (nonatomic, copy) void (^dismissBlock)(PooTimePicker *timePicker);
@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, weak) id<PooTimePickerDelegate>delegate;

- (void)customSelectRow:(NSInteger)row
            inComponent:(NSInteger)component
               animated:(BOOL)animated;
- (void)customPickerView:(UIPickerView *)pickerView
            didSelectRow:(NSInteger)row
             inComponent:(NSInteger)component;

+(NSMutableArray *)hourArray;
+(NSMutableArray *)minuteArray;

+(NSInteger)getEditHourIndexWithTimeString:(NSString*)str;
+(NSInteger)getEditMinuteIndexWithTimeString:(NSString*)str;
@end
